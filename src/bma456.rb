class BMA456
  ADDR = 0x19

  REG = {
    CHIP_ID:   0x00,
    ACC_DATA:  0x12,
    STEP_CNT:  0x1E,
    TEMP_DATA: 0x22,
    ACC_CONF:  0x40,
    ACC_RANGE: 0x41,
    PWR_CONF:  0x7C,
    PWR_CTRL:  0x7D,
    CMD:       0x7E
  }

  RANGE_MAP = { "g2" => 0, "g4" => 1, "g8" => 2, "g16" => 3 }
  LSB_MAP   = { "g2" => 16384.0, "g4" => 8192.0, "g8" => 4096.0, "g16" => 2048.0 }

  attr_reader :accel, :accel_raw, :temperature, :sw_steps, :hw_steps, :tilt

  def initialize(i2c, range: :g4)
    @i2c = i2c
    @accel = { x: 0.0, y: 0.0, z: 0.0 }
    @accel_raw = { x: 0, y: 0, z: 0 }
    @temperature = 0
    @tilt = "Unknown"
    
    @hw_steps = 0
    @sw_steps = 0
    @step_flag = false

    r_str = range.to_s
    range_val = RANGE_MAP[r_str] || 1
    @lsb_per_g = LSB_MAP[r_str] || 8192.0

    res = @i2c.read(ADDR, 1, REG[:CHIP_ID])
    if !res || res[0].ord != 0x16
      puts "BMA456 not found"
      return
    end

    write_reg(REG[:CMD], 0xB6)
    sleep 0.05
    write_reg(REG[:PWR_CONF], 0x00)
    sleep 0.02
    write_reg(REG[:ACC_CONF], 0xA8) 
    write_reg(REG[:ACC_RANGE], range_val)
    write_reg(REG[:PWR_CTRL], 0x05) 
    sleep 0.05
  end

  def read
    data_raw = @i2c.read(ADDR, 6, REG[:ACC_DATA])
    return false if !data_raw || data_raw.length < 6

    @accel_raw[:x] = decode_s16(data_raw[0].ord, data_raw[1].ord)
    @accel_raw[:y] = decode_s16(data_raw[2].ord, data_raw[3].ord)
    @accel_raw[:z] = decode_s16(data_raw[4].ord, data_raw[5].ord)

    @accel[:x] = @accel_raw[:x] / @lsb_per_g
    @accel[:y] = @accel_raw[:y] / @lsb_per_g
    @accel[:z] = @accel_raw[:z] / @lsb_per_g

    update_tilt
    update_sw_pedometer

    # ハードウェア歩数計
    s_raw = @i2c.read(ADDR, 3, REG[:STEP_CNT])
    if s_raw && s_raw.length >= 3
      @hw_steps = s_raw[0].ord | (s_raw[1].ord << 8) | (s_raw[2].ord << 16)
    end

    t_raw = @i2c.read(ADDR, 1, REG[:TEMP_DATA])
    if t_raw
      t_int = t_raw[0].ord
      t_int -= 256 if t_int > 127
      @temperature = t_int + 23
    end

    true
  end

  private

  def update_tilt
    # .abs の代わりに三項演算子で絶対値を取得
    ax = @accel[:x] < 0 ? -@accel[:x] : @accel[:x]
    ay = @accel[:y] < 0 ? -@accel[:y] : @accel[:y]
    az = @accel[:z] < 0 ? -@accel[:z] : @accel[:z]

    if az > ax && az > ay
      @tilt = @accel[:z] > 0 ? "Flat (Face Up)" : "Flat (Face Down)"
    elsif ax > ay && ax > az
      @tilt = @accel[:x] > 0 ? "Landscape (Right)" : "Landscape (Left)"
    else
      @tilt = @accel[:y] > 0 ? "Portrait (Down)" : "Portrait (Up)"
    end
  end

  def update_sw_pedometer
    x = @accel[:x]
    y = @accel[:y]
    z = @accel[:z]
    mag_sq = (x * x) + (y * y) + (z * z)
    
    # 閾値判定 (1.2Gの自乗 = 1.44)
    if mag_sq > 1.44 && !@step_flag
      @sw_steps += 1
      @step_flag = true
    elsif mag_sq < 1.1 && @step_flag
      @step_flag = false
    end
  end

  def decode_s16(low, high)
    val = (high << 8) | low
    val > 32767 ? val - 65536 : val
  end

  def write_reg(reg, val)
    @i2c.write(ADDR, [reg, val])
  end
end

=begin
i2c = I2C.new() 

# キーワード引数で初期化 (アドレス 0x19)
bma = BMA456.new(i2c, range: :g4)

loop do
  if bma.read
    puts "傾き: #{bma.tilt}"
    puts "歩数: #{bma.sw_steps} steps (SW)"
    puts "Accel: #{bma.accel[:x]}, #{bma.accel[:y]}, #{bma.accel[:z]}"
    puts "Accel_raw: #{bma.accel_raw[:x]}, #{bma.accel_raw[:y]}, #{bma.accel_raw[:z]}"
    puts "Temp:  #{bma.temperature}"
  else
    puts "Measure failed"
  end
  sleep 0.1
end
=end
