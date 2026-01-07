class SHT35
  ADDR = 0x45

  # 再現性設定 [MSB, LSB, 待ち時間]
  SETTINGS = {
    high:   [0x2c, 0x06, 0.015],
    medium: [0x2c, 0x0d, 0.006],
    low:    [0x2c, 0x10, 0.004]
  }

  def initialize(i2c, repeatability: :high)
    @i2c = i2c
    
    config = SETTINGS[repeatability] || SETTINGS[:high]
    @cmd_msb    = config[0]
    @cmd_lsb    = config[1]
    @wait_time  = config[2]

    # デバイスのリセット
    @i2c.write(ADDR, 0x30, 0xa2)
    sleep 0.01

    # 初期化時のステータス確認
    res = @i2c.read(ADDR, 3, 0xf3, 0x2d)
    if res.nil? || crc8(res[0, 2]) != res.getbyte(2)
      puts "SHT35 initialization failed"
    end
  end

  def read
    @i2c.write(ADDR, @cmd_msb, @cmd_lsb)
    sleep @wait_time
    
    res = @i2c.read(ADDR, 6)
    return false if res.nil?

    # 温度データのCRC確認と計算
    if crc8(res[0, 2]) == res.getbyte(2)
      st = (res.getbyte(0) << 8 | res.getbyte(1)).to_f
      @temperature = -45 + 175 * st / 65535
    else
      @temperature = nil
    end

    # 湿度データのCRC確認と計算
    if crc8(res[3, 2]) == res.getbyte(5)
      srh = (res.getbyte(3) << 8 | res.getbyte(4)).to_f
      @humidity = 100 * srh / 65535
    else
      @humidity = nil
    end

    !@temperature.nil? && !@humidity.nil?
  end

  def temperature
    @temperature
  end

  def humidity
    @humidity
  end

  private

  def crc8(data)
    crc = 0xff
    data.each_byte do |b|
      crc ^= b
      8.times do
        crc = (crc << 1) ^ (crc & 0x80 != 0 ? 0x31 : 0)
        crc &= 0xff
      end
    end
    crc
  end
end

=begin
i2c = I2C.new
sht = SHT35.new(i2c, repeatability: :high) #デフォルトは :high

loop do
  if sht.read
    puts "----"
    puts "temp: #{sht.temperature}"
    puts "humi: #{sht.humidity}"
  end
  sleep 1
end
=end
