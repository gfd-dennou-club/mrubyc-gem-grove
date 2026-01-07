class VL53L0X
  ADDRESS = 0b0101001
  START_OVERHEAD = 1910
  END_OVERHEAD = 960
  MSRC_OVERHEAD = 660
  TCC_OVERHEAD = 590
  DSS_OVERHEAD = 690
  PRE_RANGE_OVERHEAD = 660
  FINAL_RANGE_OVERHEAD = 550
  MIN_TIMING_BUDGET = 20_000

  attr_reader :distance

  # ---------------------------------------------------------
  # ミリ秒取得関数
  # ---------------------------------------------------------
  def millis
    # C 側で定義した関数がない場合は 0 を返す
    #  -> タイムアウト処理がスキップ
    0 
  end

  def initialize(i2c, timeout_ms: 500, continuous: nil)
    @i2c = i2c
    @address = ADDRESS
    @io_timeout = timeout_ms
    @did_timeout = false
    @distance = 0
    @continuous_mode = !continuous.nil?

    # センサーの存在確認
    raise "VL53L0X not found" if read_reg(0xc0) != 0xee

    # 初期化シーケンス
    write_reg(0x89, read_reg(0x89) | 0x01)
    write_reg(0x88, 0x00)
    write_reg(0x80, 0x01)
    write_reg(0xff, 0x01)
    write_reg(0x00, 0x00)
    @stop_variable = read_reg(0x91)
    write_reg(0x00, 0x01)
    write_reg(0xff, 0x00)
    write_reg(0x80, 0x00)

    write_reg(0x60, read_reg(0x60) | 0x12)
    set_signal_rate_limit(0.25)
    write_reg(0x01, 0xff)

    info, spad_count, spad_type_is_aperture = get_spad_info
    ref_spad_map = read_multi(0xb0, 6)

    write_reg(0xff, 0x01)
    write_reg(0x4f, 0x00)
    write_reg(0x4e, 0x2c)
    write_reg(0xff, 0x00)
    write_reg(0xb6, 0xb4)

    first_spad_to_enable = spad_type_is_aperture ? 12 : 0
    spads_enabled = 0
    (0...48).each do |i|
      if i < first_spad_to_enable || spads_enabled == spad_count
        ref_spad_map[i / 8] &= ~(1 << (i % 8))
      elsif ((ref_spad_map[i / 8] >> (i % 8)) & 0x1) != 0
        spads_enabled += 1
      end
    end
    write_multi(0xb0, ref_spad_map)

    load_default_tuning_settings
    
    write_reg(0x0a, 0x04)
    write_reg(0x84, read_reg(0x84) & ~0x10)
    write_reg(0x0b, 0x01)

    @measurement_timing_budget_us = get_measurement_timing_budget
    write_reg(0x01, 0xe8)
    set_measurement_timing_budget(@measurement_timing_budget_us)
    write_reg(0x01, 0x01)
    perform_single_ref_calibration(0x40)
    write_reg(0x01, 0x02)
    perform_single_ref_calibration(0x00)
    write_reg(0x01, 0xe8)

    start_continuous(continuous) if @continuous_mode
  end

  def read
    val = @continuous_mode ? read_range_continuous_millimeters : read_range_single_millimeters
    if val >= 65535 || @did_timeout
      @did_timeout = false
      return false
    else
      @distance = val
      return true
    end
  end

  def read_reg(reg); @i2c.read(@address, 1, reg).bytes[0]; end
  def read_reg_16bit(reg)
    d = @i2c.read(@address, 2, reg).bytes
    (d[0] << 8) | d[1]
  end
  def read_multi(reg, cnt); @i2c.read(@address, cnt, reg).bytes; end

  def write_reg(reg, val); @i2c.write(@address, [reg, val]); end
  def write_reg_16bit(reg, val); @i2c.write(@address, [reg, (val >> 8) & 0xff, val & 0xff]); end
  def write_reg_32bit(reg, val)
    @i2c.write(@address, [reg, (val >> 24) & 0xff, (val >> 16) & 0xff, (val >> 8) & 0xff, val & 0xff])
  end
  def write_multi(reg, src)
    buf = [reg]
    src.each { |v| buf << v }
    @i2c.write(@address, buf)
  end

  private

  def load_default_tuning_settings
    # センサー安定動作のための定数書き込み
    [[0xff, 0x01], [0x00, 0x00], [0xff, 0x00], [0x09, 0x00], [0x10, 0x00], [0x11, 0x00],
     [0x24, 0x01], [0x25, 0xff], [0x75, 0x00], [0xff, 0x01], [0x4e, 0x2c], [0x48, 0x00],
     [0x30, 0x20], [0xff, 0x00], [0x30, 0x09], [0x54, 0x00], [0x31, 0x04], [0x32, 0x03],
     [0x40, 0x83], [0x46, 0x25], [0x60, 0x00], [0x27, 0x00], [0x50, 0x06], [0x51, 0x00],
     [0x52, 0x96], [0x56, 0x08], [0x57, 0x30], [0x61, 0x00], [0x62, 0x00], [0x64, 0x00],
     [0x65, 0x00], [0x66, 0xa0], [0xff, 0x01], [0x22, 0x32], [0x47, 0x14], [0x49, 0xff],
     [0x4a, 0x00], [0xff, 0x00], [0x7a, 0x0a], [0x7b, 0x00], [0x78, 0x21], [0xff, 0x01],
     [0x23, 0x34], [0x42, 0x00], [0x44, 0xff], [0x45, 0x26], [0x46, 0x05], [0x40, 0x40],
     [0x0e, 0x06], [0x20, 0x1a], [0x43, 0x40], [0xff, 0x00], [0x34, 0x03], [0x35, 0x44],
     [0xff, 0x01], [0x31, 0x04], [0x4b, 0x09], [0x4c, 0x05], [0x4d, 0x04], [0xff, 0x00],
     [0x44, 0x00], [0x45, 0x20], [0x47, 0x08], [0x48, 0x28], [0x67, 0x00], [0x70, 0x04],
     [0x71, 0x01], [0x72, 0xfe], [0x76, 0x00], [0x77, 0x00], [0xff, 0x01], [0x0d, 0x01],
     [0xff, 0x00], [0x80, 0x01], [0x01, 0xf8], [0xff, 0x01], [0x8e, 0x01], [0x00, 0x01],
     [0xff, 0x00], [0x80, 0x00]].each { |reg, val| write_reg(reg, val) }
  end

  def set_signal_rate_limit(limit_mcps)
    write_reg_16bit(0x44, (limit_mcps * 128).to_i)
  end

  def get_measurement_timing_budget
    budget_us = START_OVERHEAD + END_OVERHEAD
    init_sequence_step_enables
    init_sequence_step_timeouts
    budget_us += (@msrc_dss_tcc_us + TCC_OVERHEAD) if @tcc
    budget_us += 2 * (@msrc_dss_tcc_us + DSS_OVERHEAD) if @dss
    budget_us += (@msrc_dss_tcc_us + MSRC_OVERHEAD) if !@dss && @msrc
    budget_us += (@pre_range_us + PRE_RANGE_OVERHEAD) if @pre_range
    budget_us += (@final_range_us + FINAL_RANGE_OVERHEAD) if @final_range
    budget_us
  end

  def set_measurement_timing_budget(budget_us)
    used_budget_us = START_OVERHEAD + END_OVERHEAD
    init_sequence_step_enables
    init_sequence_step_timeouts
    used_budget_us += (@msrc_dss_tcc_us + TCC_OVERHEAD) if @tcc
    used_budget_us += 2 * (@msrc_dss_tcc_us + DSS_OVERHEAD) if @dss
    used_budget_us += (@msrc_dss_tcc_us + MSRC_OVERHEAD) if !@dss && @msrc
    used_budget_us += (@pre_range_us + PRE_RANGE_OVERHEAD) if @pre_range
    if @final_range
      used_budget_us += FINAL_RANGE_OVERHEAD
      final_range_timeout_us = budget_us - used_budget_us
      final_range_timeout_mclks = timeout_microseconds_to_mclks(final_range_timeout_us, @final_range_vcsel_period_pclks)
      final_range_timeout_mclks += @pre_range_mclks if @pre_range
      write_reg_16bit(0x71, encode_timeout(final_range_timeout_mclks))
    end
  end

  def start_continuous(period_ms = 0)
    write_reg(0x80, 0x01); write_reg(0xff, 0x01); write_reg(0x00, 0x00)
    write_reg(0x91, @stop_variable)
    write_reg(0x00, 0x01); write_reg(0xff, 0x00); write_reg(0x80, 0x00)
    if period_ms != 0
      osc_calibrate_val = read_reg_16bit(0xf8)
      period_ms *= osc_calibrate_val if osc_calibrate_val != 0
      write_reg_32bit(0x04, period_ms)
      write_reg(0x00, 0x04)
    else
      write_reg(0x00, 0x02)
    end
  end

  def read_range_continuous_millimeters
    start_t = millis
    while (read_reg(0x13) & 0x07) == 0
      if @io_timeout > 0 && (millis - start_t > @io_timeout); @did_timeout = true; return 65535; end
    end
    range = read_reg_16bit(0x14 + 10)
    write_reg(0x0b, 0x01)
    range
  end

  def read_range_single_millimeters
    write_reg(0x80, 0x01); write_reg(0xff, 0x01); write_reg(0x00, 0x00)
    write_reg(0x91, @stop_variable); write_reg(0x00, 0x01); write_reg(0xff, 0x00); write_reg(0x80, 0x00)
    write_reg(0x00, 0x01)
    start_t = millis
    while (read_reg(0x00) & 0x01) != 0
      if @io_timeout > 0 && (millis - start_t > @io_timeout); @did_timeout = true; return 65535; end
    end
    read_range_continuous_millimeters
  end

  def get_spad_info
    write_reg(0x80, 0x01); write_reg(0xff, 0x01); write_reg(0x00, 0x00)
    write_reg(0xff, 0x06); write_reg(0x83, read_reg(0x83) | 0x04)
    write_reg(0xff, 0x07); write_reg(0x81, 0x01); write_reg(0x80, 0x01)
    write_reg(0x94, 0x6b); write_reg(0x83, 0x00)
    start_t = millis
    while read_reg(0x83) == 0x00
      return [false, 0, false] if @io_timeout > 0 && (millis - start_t > @io_timeout)
    end
    write_reg(0x83, 0x01)
    tmp = read_reg(0x92)
    write_reg(0x81, 0x00); write_reg(0xff, 0x06); write_reg(0x83, read_reg(0x83) & ~0x04)
    write_reg(0xff, 0x01); write_reg(0x00, 0x01); write_reg(0xff, 0x00); write_reg(0x80, 0x00)
    [true, tmp & 0x7f, (tmp >> 7) & 0x01 != 0]
  end

  def init_sequence_step_enables
    cfg = read_reg(0x01)
    @tcc = (cfg >> 4) & 0x01 != 0; @dss = (cfg >> 3) & 0x01 != 0
    @msrc = (cfg >> 2) & 0x01 != 0; @pre_range = (cfg >> 6) & 0x01 != 0
    @final_range = (cfg >> 7) & 0x01 != 0
  end

  def init_sequence_step_timeouts
    @pre_range_vcsel_period_pclks = (read_reg(0x50) + 1) << 1
    m_mclks = read_reg(0x46) + 1
    @msrc_dss_tcc_us = timeout_mclks_to_microseconds(m_mclks, @pre_range_vcsel_period_pclks)
    @pre_range_mclks = decode_timeout(read_reg_16bit(0x51))
    @pre_range_us = timeout_mclks_to_microseconds(@pre_range_mclks, @pre_range_vcsel_period_pclks)
    @final_range_vcsel_period_pclks = (read_reg(0x70) + 1) << 1
    f_mclks = decode_timeout(read_reg_16bit(0x71))
    f_mclks -= @pre_range_mclks if @pre_range
    @final_range_us = timeout_mclks_to_microseconds(f_mclks, @final_range_vcsel_period_pclks)
  end

  def decode_timeout(reg_val); ((reg_val & 0xff) << ((reg_val & 0xff00) >> 8)) + 1; end
  def encode_timeout(mclks)
    return 0 if mclks <= 0
    lsb = mclks - 1; msb = 0
    while (lsb & 0xff00) > 0; lsb >>= 1; msb += 1; end
    (msb << 8) | (lsb & 0xff)
  end

  def timeout_mclks_to_microseconds(mclks, pclks)
    macro = ((2304 * pclks * 1655) + 500) / 1000
    ((mclks * macro) + 500) / 1000
  end

  def timeout_microseconds_to_mclks(us, pclks)
    macro = ((2304 * pclks * 1655) + 500) / 1000
    ((us * 1000) + (macro / 2)) / macro
  end

  def perform_single_ref_calibration(vhv_byte)
    write_reg(0x00, 0x01 | vhv_byte)
    start_t = millis
    while read_reg(0x13) & 0x07 == 0
      return false if @io_timeout > 0 && (millis - start_t > @io_timeout)
    end
    write_reg(0x0b, 0x01); write_reg(0x00, 0x00)
    true
  end
end

=begin
i2c = I2C.new()
# 100ms間隔の連続計測モードで初期化
vl53l0x = VL53L0X.new(i2c, continuous: 100)

loop do
  if vl53l0x.read
    # 計測成功時
    puts "Distance: #{vl53l0x.distance} mm"
  else
    # タイムアウト等の失敗時
    puts "Measurement failed"
  end
  # 必要に応じてスリープ
  sleep 1 
end
=end
