class DPS310
  attr_reader :temperature, :pressure

  # OSR設定マップ [レジスタ値, スケール係数, 数値]
  OSR_MAP = {
    x1:   [0, 524288, 1],
    x2:   [1, 1572864, 2],
    x4:   [2, 3670016, 4],
    x8:   [3, 7864320, 8],
    x16:  [4, 253952, 16],
    x32:  [5, 516096, 32],
    x64:  [6, 1040384, 64],
    x128: [7, 2088960, 128]
  }

  # 計測レートマップ [レジスタ値]
  RATE_MAP = {
    x1: 0, x2: 1, x4: 2, x8: 3, x16: 4, x32: 5, x64: 6, x128: 7
  }

  def initialize(i2c, options = {})
    @i2c  = i2c
    @addr = options[:addr] || 0x77
    @mode = options[:mode] || :command # :command or :background
    
    # シンボルから設定値を取得 (デフォルトは x64 / x1)
    osr_set  = OSR_MAP[options[:osr]]  || OSR_MAP[:x64]
    rate_set = RATE_MAP[options[:rate]] || RATE_MAP[:x1]

    osr_bits     = osr_set[0]
    @scale_factor = osr_set[1]
    @osr_val     = osr_set[2] # 待ち時間とシフト判定用
    rate_bits    = rate_set << 4

    # センサリセット
    write_u8(0x0C, 0x09)
    sleep 0.05
    correct_temperature_sensor

    # レジスタ設定 (PRS_CFG, TMP_CFG)
    write_u8(0x06, rate_bits | osr_bits)
    write_u8(0x07, 0x80 | rate_bits | osr_bits)

    # シフト設定 (OSR > 8 の場合に必要)
    cfg_val = 0x00
    cfg_val |= 0x04 if @osr_val > 8 # P_SHIFT
    cfg_val |= 0x08 if @osr_val > 8 # T_SHIFT
    write_u8(0x09, cfg_val)

    # キャリブレーション係数読み取り
    read_calibration_coefficients

    # バックグラウンドモード開始
    if @mode == :background
      write_u8(0x08, 0x07)
    end
    
    # 1項目あたりの計測待ち時間 (秒)
    @wait_time = (@osr_val * 1.5 / 1000.0) + 0.01
  end

  def read
    if @mode == :command
      # --- コマンドモード: その都度計測 ---
      write_u8(0x08, 0x02) # 温度
      sleep @wait_time
      raw_t = get_raw_value(0x03)
      
      write_u8(0x08, 0x01) # 気圧
      sleep @wait_time
      raw_p = get_raw_value(0x00)
    else
      # --- バックグラウンドモード: 準備完了確認 ---
      status = read_u8(0x08)
      return false if (status & 0x30) == 0
      
      raw_t = get_raw_value(0x03)
      raw_p = get_raw_value(0x00)
    end

    # 補正計算
    sc_t = raw_t.to_f / @scale_factor
    sc_p = raw_p.to_f / @scale_factor
    @temperature = @c0 * 0.5 + sc_t * @c1
    @pressure = @c00 + sc_p * (@c10 + sc_p * (@c20 + sc_p * @c30)) + 
                sc_t * @c01 + sc_t * sc_p * (@c11 + sc_p * @c21)
    true
  rescue
    false
  end

  private

  def correct_temperature_sensor
    write_u8(0x0E, 0xA5); write_u8(0x0F, 0x96)
    write_u8(0x62, 0x02)
    write_u8(0x0E, 0x00); write_u8(0x0F, 0x00)
  end

  def get_raw_value(reg)
    b = read_block(reg, 3)
    val = (b[0] << 16) | (b[1] << 8) | b[2]
    twos_complement(val, 24)
  end

  def read_calibration_coefficients
    b_t = read_block(0x10, 3)
    @c0 = twos_complement(((b_t[0] << 4) | (b_t[1] >> 4)), 12)
    @c1 = twos_complement((((b_t[1] & 0x0F) << 8) | b_t[2]), 12)
    b_p = read_block(0x13, 15)
    @c00 = twos_complement(((b_p[0] << 12) | (b_p[1] << 4) | (b_p[2] >> 4)), 20)
    @c10 = twos_complement((((b_p[2] & 0x0F) << 16) | (b_p[3] << 8) | b_p[4]), 20)
    @c01 = twos_complement(((b_p[5] << 8) | b_p[6]), 16)
    @c11 = twos_complement(((b_p[7] << 8) | b_p[8]), 16)
    @c20 = twos_complement(((b_p[9] << 8) | b_p[10]), 16)
    @c21 = twos_complement(((b_p[11] << 8) | b_p[12]), 16)
    @c30 = twos_complement(((b_p[13] << 8) | b_p[14]), 16)
  end

  def write_u8(reg, val); @i2c.write(@addr, [reg, val]); end
  def read_u8(reg); @i2c.write(@addr, [reg]); @i2c.read(@addr, 1).bytes[0]; end
  def read_block(reg, len); @i2c.write(@addr, [reg]); @i2c.read(@addr, len).bytes; end
  def twos_complement(val, bits)
    limit = 1 << (bits - 1)
    val >= limit ? val - (1 << bits) : val
  end
end

=begin
i2c = I2C.new()
dps310 = DPS310.new(i2c, osr: :x16 )

loop do
  if dps310.read
    puts "Temp: #{dps310.temperature} C"
    puts "Pres: #{dps310.pressure / 100.0} hPa"
  end
  sleep 5
end
=end
