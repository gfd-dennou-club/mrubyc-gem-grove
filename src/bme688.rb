class BME688
  ADDR = 0x76

  # レジスタ
  REG_ID          = 0xD0
  REG_RESET       = 0xE0
  REG_CTRL_GAS_1  = 0x71
  REG_CTRL_GAS_0  = 0x70
  REG_CTRL_HUM    = 0x72
  REG_CTRL_MEAS   = 0x74
  REG_CONFIG      = 0x75
  REG_ADDR_PAGE   = 0x73

  # オーバーサンプリング設定マップ
  OSRS_MAP = { none: 0x00, x1: 0x01, x2: 0x02, x4: 0x03, x8: 0x04, x16: 0x05 }

  attr_reader :temperature, :humidity, :pressure, :gas_resistance, :gas_score

  def initialize(i2c, options = {})
    @i2c = i2c
    @address = options[:address] || ADDR
    @t_fine = 0.0
    @temperature = 0.0
    @humidity = 0.0
    @pressure = 0.0
    @gas_resistance = 0.0
    @gas_score = "Calibrating..."
    
    @gas_reference = 0.0
    @burn_in_count = 0

    # オプションからオーバーサンプリング設定を取得 (デフォルトは x1)
    os_t = options[:osr_t] || :x1
    os_p = options[:osr_p] || :x1
    os_h = options[:osr_h] || :x1

    @osrs_t = OSRS_MAP[os_t] || 0x01
    @osrs_p = OSRS_MAP[os_p] || 0x01
    @osrs_h = OSRS_MAP[os_h] || 0x01

    # ソフトリセット
    reset

    # チップIDの確認 (BME688のIDは 0x61)
    chip_id = read8(REG_ID)
    if chip_id != 0x61
      puts "BME688: Sensor not found (ID: 0x#{chip_id.to_s(16)})"
    end

    # 補正係数の読み込み
    read_coefficients
  end

  # --- 低レイヤ操作 ---
  def write8(reg, val); @i2c.write(@address, [reg, val]); end
  def read8(reg); @i2c.read(@address, 1, reg).bytes[0] rescue 0; end
  def read16(reg); b = @i2c.read(@address, 2, reg).bytes; (b[1] << 8) | b[0]; end

  def reset
    write8(REG_RESET, 0xB6)
    sleep 0.2
  end

  def set_page(page)
    curr = read8(REG_ADDR_PAGE)
    write8(REG_ADDR_PAGE, (page == 1) ? (curr | 0x10) : (curr & 0xEF))
  end

  def to_int8(n); n > 127 ? n - 256 : n; end
  def to_int16(n); n > 32767 ? n - 65536 : n; end

  def read_coefficients
    set_page(0)
    @t1 = read16(0xE9); @t2 = to_int16(read16(0x8A)); @t3 = to_int8(read8(0x8C))
    @p1 = read16(0x8E); @p2 = to_int16(read16(0x90)); @p3 = to_int8(read8(0x92))
    @p4 = to_int16(read16(0x94)); @p5 = to_int16(read16(0x96)); @p6 = to_int8(read8(0x99))
    @p7 = to_int8(read8(0x98)); @p8 = to_int16(read16(0x9C)); @p9 = to_int16(read16(0x9E)); @p10 = read8(0xA0)
    @h1 = (read8(0xE3) << 4) | (read8(0xE2) & 0x0F); @h2 = (read8(0xE1) << 4) | (read8(0xE2) >> 4)
    @h3 = to_int8(read8(0xE4)); @h4 = to_int8(read8(0xE5)); @h5 = to_int8(read8(0xE6)); @h6 = read8(0xE7); @h7 = to_int8(read8(0xE8))
    @gh1 = to_int8(read8(0xED)); @gh2 = to_int16(read16(0xEB)); @gh3 = to_int8(read8(0xEE))
    set_page(1); @res_heat_val = read8(0x00); @res_heat_range = (read8(0x02) & 0x30) >> 4; set_page(0)
  end

  # --- 補正計算 ---
  def compensate_t(raw)
    v1 = (raw / 16384.0 - @t1 / 1024.0) * @t2
    v2 = ((raw / 131072.0 - @t1 / 8192.0) * (raw / 131072.0 - @t1 / 8192.0)) * (@t3 * 16.0)
    @t_fine = v1 + v2
    @t_fine / 5120.0
  end

  def compensate_p(raw)
    v1 = (@t_fine / 2.0) - 64000.0
    v2 = v1 * v1 * (@p6 / 131072.0)
    v2 = v2 + (v1 * @p5 * 2.0)
    v2 = (v2 / 4.0) + (@p4 * 65536.0)
    v1 = (@p3 * v1 * v1 / 16384.0 + @p2 * v1) / 524288.0
    v1 = (1.0 + v1 / 32768.0) * @p1
    return 0 if v1 == 0
    p = 1048576.0 - raw; p = ((p - (v2 / 4096.0)) * 6250.0) / v1
    v1 = @p9 * p * p / 2147483648.0; v2 = p * (@p8 / 32768.0); v3 = (p / 256.0) * (p / 256.0) * (p / 256.0) * (@p10 / 131072.0)
    p = p + (v1 + v2 + v3 + (@p7 * 128.0)) / 16.0
    p / 100.0
  end

  def compensate_h(raw, temp)
    v1 = raw - (@h1 * 16.0 + (@h3 / 2.0) * temp)
    v2 = v1 * (@h2 / 262144.0 * (1.0 + (@h4 / 16384.0) * temp + (@h5 / 1048576.0) * temp * temp))
    h = v2 + (@h6 / 16384.0 + @h7 / 2097152.0 * temp) * v2 * v2
    h = 100.0 if h > 100.0; h = 0.0 if h < 0.0; h
  end

  def calc_res_heat(target)
    v1 = (@gh1 / 16.0) + 49.0; v2 = ((@gh2 / 32768.0) * 0.0005) + 0.00235; v3 = @gh3 / 1024.0
    v4 = v1 * (1.0 + (v2 * target)); v5 = v4 + (v3 * 25.0)
    res = (v5 * (4.0 / (4.0 + @res_heat_range)) * (1.0 / (1.0 + (@res_heat_val * 0.002)))).to_i
    res > 255 ? 255 : res
  end

  def compensate_gas(raw, range)
    return 0 if raw == 0
    lookup = [1.0, 1.0, 1.0, 1.0, 1.0, 0.99, 1.0, 0.992, 1.0, 1.0, 0.998, 0.995, 1.0, 0.99, 1.0, 1.0]
    var1 = (1340.0 + (5.0 * @res_heat_val)) * lookup[range]
    res = (var1 * 125.0) / (raw + 125.0)
    res * (1 << range)
  end

  def update_iaq_score(gas_res, humi)
    if @burn_in_count < 10
      @gas_reference = gas_res if gas_res > @gas_reference
      @burn_in_count += 1
      @gas_score = "Calibrating..."
      return
    end
    hum_ref = 40.0
    hum_diff = humi - hum_ref; hum_diff = -hum_diff if hum_diff < 0
    hum_score = 25.0 - (hum_diff * 0.5); hum_score = 0.0 if hum_score < 0.0
    gas_score_ratio = (gas_res / @gas_reference) * 75.0; gas_score_ratio = 75.0 if gas_score_ratio > 75.0
    total = gas_score_ratio + hum_score
    status = if total > 90; "Excellent"; elsif total > 75; "Good"; elsif total > 50; "Average"; else "Ventilate!"; end
    @gas_score = "#{total} [#{status}]"
  end

  # --- 測定メイン ---
  def read
    set_page(0)
    
    # 1. 湿度オーバーサンプリング設定
    write8(REG_CTRL_HUM, @osrs_h)

    # 2. ヒーター点火設定 (300度, 100ms)
    heat_val = calc_res_heat(300)
    (0x5A..0x63).each { |reg| write8(reg, heat_val) }
    (0x64..0x6D).each { |reg| write8(reg, 0x59) }
    
    # 3. ガス測定有効化
    write8(REG_CTRL_GAS_1, 0x30)
    write8(REG_CTRL_GAS_0, 0x00)

    # 4. 温度・気圧オーバーサンプリング設定 + Forced Mode 開始
    # REG_CTRL_MEAS(0x74): [7:5]osrs_t, [4:2]osrs_p, [1:0]mode
    ctrl_meas = (@osrs_t << 5) | (@osrs_p << 2) | 0x01
    write8(REG_CTRL_MEAS, ctrl_meas)

    # 5. データ完了待ち
    found = false
    100.times do
      if (read8(0x1D) & 0x80) != 0
        found = true; break
      end
      sleep 0.01
    end
    return false unless found

    # 6. データ取得と更新
    t_raw = (read8(0x22) << 12) | (read8(0x23) << 4) | (read8(0x24) >> 4)
    @temperature = compensate_t(t_raw)
    p_raw = (read8(0x1F) << 12) | (read8(0x20) << 4) | (read8(0x21) >> 4)
    @pressure = compensate_p(p_raw)
    h_raw = (read8(0x25) << 8) | read8(0x26)
    @humidity = compensate_h(h_raw, @temperature)
    
    g_msb = read8(0x2C); g_lsb = read8(0x2D)
    if (g_lsb & 0x20 != 0)
      @gas_resistance = compensate_gas((g_msb << 2) | (g_lsb >> 6), g_lsb & 0x0F)
      update_iaq_score(@gas_resistance, @humidity)
    end
    true
  end
end

=begin
i2c = I2C.new
bme = BME688.new(i2c)

loop do
  if bme.measure
    puts "--------------------------"
    puts "Temp: #{bme.temperature} C"
    puts "Humi: #{bme.humidity} %"
    puts "Pres: #{bme.pressure} hPa"
    puts "Gas : #{bme.gas_resistance} Ohm"
    puts "IAQ : #{bme.gas_score}"
  else
    puts "Measurement failed"
  end
  sleep 5
end
=end

