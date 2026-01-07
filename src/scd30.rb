class SCD30
  I2C_ADDR = 0x61

  # コマンド定義
  CMD_START_PERIODIC    = [0x00, 0x10]
  CMD_STOP_PERIODIC     = [0x01, 0x04]
  CMD_READ_MEASURE      = [0x03, 0x00]
  CMD_GET_DATA_READY    = [0x02, 0x02]
  CMD_SET_INTERVAL      = [0x46, 0x00]
  CMD_SET_ASC           = [0x53, 0x06]
  CMD_SET_ALTITUDE      = [0x51, 0x02]
  CMD_SET_TEMP_OFFSET   = [0x54, 0x03]

  def initialize(i2c, options = {})
    @i2c = i2c
    @co2, @temp, @humi = 0.0, 0.0, 0.0
    @options = options
    @initialized = false
  end

  def read
    unless @initialized
      setup_sensor
    end

    return false unless data_ready?

    begin
      @i2c.write(I2C_ADDR, CMD_READ_MEASURE)
      sleep(0.01) 
      
      buf = @i2c.read(I2C_ADDR, 18).bytes

      [0, 3, 6, 9, 12, 15].each do |i|
        return false unless check_crc([buf[i], buf[i+1]], buf[i+2])
      end

      # 数値変換
      @co2  = bytes_to_float(buf[0],  buf[1],  buf[3],  buf[4])
      @temp = bytes_to_float(buf[6],  buf[7],  buf[9],  buf[10])
      @humi = bytes_to_float(buf[12], buf[13], buf[15], buf[16])

      return true
    rescue
      return false
    end
  end

  def co2; ((@co2 * 10).to_i / 10.0); end
  def temperature; ((@temp * 10).to_i / 10.0); end
  def humidity; ((@humi * 10).to_i / 10.0); end

  private

  def setup_sensor
    # オプション取得
    interval    = @options[:interval]    || 2
    altitude    = @options[:altitude]    || 0
    temp_offset = @options[:temp_offset] || 0.0
    asc         = @options[:asc]
    asc         = true if asc == nil

    begin
      @i2c.write(I2C_ADDR, CMD_STOP_PERIODIC)
      sleep(0.1)

      # 設定送信
      sendCommand(CMD_SET_INTERVAL, interval)
      sendCommand(CMD_SET_ALTITUDE, altitude) if altitude > 0
      sendCommand(CMD_SET_TEMP_OFFSET, (temp_offset * 100).to_i) if temp_offset > 0
      sendCommand(CMD_SET_ASC, asc ? 1 : 0)

      # 計測開始
      @i2c.write(I2C_ADDR, CMD_START_PERIODIC + [0x00, 0x00, 0x81])
      sleep(0.1)
      
      @initialized = true
    rescue
      # 失敗しても measure でリトライされる
    end
  end

  def data_ready?
    begin
      @i2c.write(I2C_ADDR, CMD_GET_DATA_READY)
      sleep(0.01)
      res = @i2c.read(I2C_ADDR, 3).bytes
      # 上位バイトと下位バイトを合わせる (以前のコードのロジック)
      val = (res[0] << 8) | res[1]
      return val == 1
    rescue
      return false
    end
  end

  def bytes_to_float(b1, b2, b3, b4)
    # IEEE 754 単精度浮動小数点数のデコード
    s = (b1 & 0x80) == 0 ? 1 : -1
    e = ((b1 & 0x7F) << 1) | (b2 >> 7)
    m = ((b2 & 0x7F) << 16) | (b3 << 8) | b4
    
    return 0.0 if e == 0 && m == 0
    
    # 指数部
    power = e - 127
    exp = 1.0
    if power > 0
      power.times { exp *= 2.0 }
    elsif power < 0
      (-power).times { exp /= 2.0 }
    end
    
    return s * exp * (1.0 + (m.to_f / 8388608.0))
  end

  def sendCommand(cmd, arg)
    begin
      buf = [cmd[0], cmd[1], (arg >> 8) & 0xFF, arg & 0xFF]
      crc = calculate_crc([buf[2], buf[3]])
      @i2c.write(I2C_ADDR, buf + [crc])
      sleep(0.02)
    rescue
    end
  end

  def calculate_crc(data)
    crc = 0xFF
    data.each do |byte|
      crc ^= byte
      8.times do
        crc = (crc << 1) ^ ((crc & 0x80) != 0 ? 0x31 : 0)
        crc &= 0xFF
      end
    end
    crc
  end

  def check_crc(data, received_crc)
    calculate_crc(data) == received_crc
  end
end

=begin
i2c = I2C.new()

puts "SCD30 Power-on wait..."
sleep 3                         #SCD30 の起動時間はマイコンよりはるかに遅いので待ちを入れる

scd = SCD30.new(i2c, altitude: 10, temp_offset: 2, asc: true)

loop do
  if scd.read
    puts "Temp: #{scd.temperature} C"
    puts "Humi: #{scd.humidity} %"
    puts "CO2: #{scd.co2} ppm"
  end
  sleep 5
end
=end
