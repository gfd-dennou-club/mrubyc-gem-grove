class ADXL345
  I2C_ADDR = 0x53

  REG_DEVID       = 0x00
  REG_POWER_CTL   = 0x2D
  REG_DATA_FORMAT = 0x31
  REG_DATA_BASE   = 0x32

  RANGE_SETTINGS = {
    G2:  0x00,
    G4:  0x01,
    G8:  0x02,
    G16: 0x03
  }

  def initialize(i2c, range: :G2)
    @i2c = i2c
    @range_val = RANGE_SETTINGS[range] || RANGE_SETTINGS[:G2]
    @x_raw = 0; @y_raw = 0; @z_raw = 0

    id = @i2c.read(I2C_ADDR, 1, REG_DEVID).bytes[0]
    raise "ADXL345 not found" if id != 0xE5

    @i2c.write(I2C_ADDR, [REG_DATA_FORMAT, 0x08 | @range_val])
    @i2c.write(I2C_ADDR, [REG_POWER_CTL, 0x08])
    sleep(0.1)
  end

  def read
    begin
      data = @i2c.read(I2C_ADDR, 6, REG_DATA_BASE).bytes
      @x_raw = decode_raw(data[1], data[0])
      @y_raw = decode_raw(data[3], data[2])
      @z_raw = decode_raw(data[5], data[4])
      true
    rescue => e
      false
    end
  end

  # 各軸の値を返す (g単位)
  def x; convert(@x_raw); end
  def y; convert(@y_raw); end
  def z; convert(@z_raw); end

  # 合成加速度 (x^2 + y^2 + z^2 の平方根)
  def magnitude
    vx = x
    vy = y
    vz = z
    msq = (vx * vx) + (vy * vy) + (vz * vz)
    res = Math.sqrt(msq)
    ((res * 1000) + 0.5).to_i / 1000.0
  rescue
    0.0
  end

  # 傾斜角：ロール
  def roll
    rad = Math.atan2(y, z)
    (rad * 180.0 / Math::PI).to_i
  rescue
    0
  end

  # 傾斜角：ピッチ
  def pitch
    vx = x
    vy = y
    vz = z
    rad = Math.atan2(-vx, Math.sqrt((vy * vy) + (vz * vz)))
    (rad * 180.0 / Math::PI).to_i
  rescue
    0
  end

  private

  def convert(raw)
    # 3.9mg/LSB = 0.0039g
    val = raw * 0.0039
    # 擬似 round (四捨五入して小数点第3位)
    ((val * 1000) + (val > 0 ? 0.5 : -0.5)).to_i / 1000.0
  end

  def decode_raw(msb, lsb)
    raw = (msb << 8) | lsb
    raw >= 32768 ? raw - 65536 : raw
  end
end


=begin
i2c = I2C.new()
accel = ADXL345.new(i2c, range: :G2)

loop do
  if accel.read
    puts "X: #{accel.x}, Y: #{accel.y}, Z: #{accel.z}"
    puts "Roll: #{accel.roll}°, Pitch: #{accel.pitch}°"

    # 強い衝撃を検知 (1.5gを超えたら)
    if accel.magnitude > 1.5
      puts "💥 衝撃を検知しました！"
    end
  end
  sleep 0.5
end
=end
