class BMP280
  ADDR          = 0x76

  # レジスタ
  REG_ID        = 0xD0
  REG_RESET     = 0xE0
  REG_STATUS    = 0xF3
  REG_CTRL_MEAS = 0xF4
  REG_CONFIG    = 0xF5
  REG_CALIB     = 0x88

  OSRS_MAP = { none: 0x00, x1: 0x01, x2: 0x02, x4: 0x03, x8: 0x04, x16: 0x05 }

  def initialize(i2c, options = {})
    @i2c = i2c
    @address = options[:address] || ADDR
    @t_fine = 0.0
    @temperature = 0.0
    @pressure = 0.0

    os_t = options[:osr_t] || :x1
    os_p = options[:osr_p] || :x4

    # ソフトリセット
    begin
      @i2c.write(@address, [REG_RESET, 0xB6])
      sleep 0.2
    rescue
    end

    # チップIDの確認
    chip_id = 0
    5.times do
      res = @i2c.read(@address, 1, REG_ID)
      if res
        chip_id = res.bytes[0]
        break if chip_id == 0x58
      end
      sleep 0.1
    end

    if chip_id != 0x58
      puts "BMP280: Sensor not found"
      return
    end

    # 補正係数の読み込み
    read_coefficients

    # サンプリングレート設定
    ot = OSRS_MAP[os_t] || 0x01
    op = OSRS_MAP[os_p] || 0x03
    @base_ctrl = (ot << 5) | (op << 2)

    # 基本構成 (Filter OFF)
    @i2c.write(@address, [REG_CONFIG, 0x00])
  end

  def read
    return false if @base_ctrl.nil?
    
    # 測定開始の書き込み
    @i2c.write(@address, [REG_CTRL_MEAS, @base_ctrl | 0x01])
    
    # 測定完了（Busyビットが0になるの）を待機
    ready = false
    10.times do
      status_res = @i2c.read(@address, 1, REG_STATUS)
      # ステータスが取得でき、かつ測定完了ビット(0x08)が0になったか確認
      if status_res && (status_res.getbyte(0) & 0x08) == 0
        ready = true
        break
      end
      sleep 0.02
    end
    
    # 10回待っても準備ができなければ失敗として終了
    return false unless ready
    
    # データ読み出し
    res = @i2c.read(@address, 6, 0xf7)
    return false if res.nil? || res.length < 6
    
    data = res.bytes
    p_raw = (data[0] << 12) | (data[1] << 4) | (data[2] >> 4)
    t_raw = (data[3] << 12) | (data[4] << 4) | (data[5] >> 4)
    
    # 補正計算
    @temperature = compensate_temperature(t_raw)
    @pressure = compensate_pressure(p_raw)
    
    true
  end

  def temperature; @temperature; end
  def pressure; @pressure; end

  private

  def read_coefficients
    res = @i2c.read(@address, 24, REG_CALIB)
    return if res == nil || res.length < 24

    reg = res.bytes
    @dig_t1 = read16_le(reg, 0)
    @dig_t2 = to_int16(read16_le(reg, 2))
    @dig_t3 = to_int16(read16_le(reg, 4))
    @dig_p1 = read16_le(reg, 6)
    @dig_p2 = to_int16(read16_le(reg, 8))
    @dig_p3 = to_int16(read16_le(reg, 10))
    @dig_p4 = to_int16(read16_le(reg, 12))
    @dig_p5 = to_int16(read16_le(reg, 14))
    @dig_p6 = to_int16(read16_le(reg, 16))
    @dig_p7 = to_int16(read16_le(reg, 18))
    @dig_p8 = to_int16(read16_le(reg, 20))
    @dig_p9 = to_int16(read16_le(reg, 22))
  end

  def read16_le(data, offset)
    (data[offset + 1] << 8) | data[offset]
  end

  def to_int16(n)
    n > 32767 ? n - 65536 : n
  end

  def compensate_temperature(adc_t)
    v1 = (adc_t / 16384.0 - @dig_t1 / 1024.0) * @dig_t2
    
    v_tmp = (adc_t / 131072.0 - @dig_t1 / 8192.0)
    v2 = (v_tmp * v_tmp) * @dig_t3
    
    @t_fine = v1 + v2
    @t_fine / 5120.0
  end

  def compensate_pressure(adc_p)
    v1 = (@t_fine / 2.0) - 64000.0
    v2 = v1 * v1 * @dig_p6 / 32768.0
    v2 = v2 + v1 * @dig_p5 * 2.0
    v2 = (v2 / 4.0) + (@dig_p4 * 65536.0)
    v1 = (@dig_p3 * v1 * v1 / 524288.0 + @dig_p2 * v1) / 524288.0
    v1 = (1.0 + v1 / 32768.0) * @dig_p1
    return 0.0 if v1 == 0
    
    p = 1048576.0 - adc_p
    p = (p - (v2 / 4096.0)) * 6250.0 / v1
    v1 = @dig_p9 * p * p / 2147483648.0
    v2 = p * @dig_p8 / 32768.0
    p = p + (v1 + v2 + @dig_p7) / 16.0
    p / 100.0
  end
end

=begin
i2c = I2C.new
bmp = BMP280.new(i2c, osr_t: :x1, osr_p: :x4)

loop do
  if bmp.read
    puts "----"
    puts "temp: #{bmp.temperature}"
    puts "pres: #{bmp.pressure}"
  end
  sleep 1
end
=end
