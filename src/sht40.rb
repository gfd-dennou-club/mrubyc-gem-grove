class SHT40
  ADDR = 0x44

  # 再現性設定 [コマンド, 待ち時間]
  SETTINGS = {
    high:   [0xfd, 0.01],
    medium: [0xf6, 0.005],
    low:    [0xe0, 0.002]
  }

  def initialize(i2c, repeatability: :high)
    @i2c = i2c
    
    config = SETTINGS[repeatability] || SETTINGS[:high]
    @cmd       = config[0]
    @wait_time = config[1]

    # ソフトリセット
    @i2c.write(ADDR, 0x94)
    sleep 0.001
  end

  def read
    # 計測コマンド送信
    @i2c.write(ADDR, @cmd)
    sleep @wait_time

    # 6バイト読み取り
    res = @i2c.read(ADDR, 6)
    return false if res.nil?

    # 温度計算
    if crc8(res[0, 2]) == res.getbyte(2)
      st = (res.getbyte(0) << 8 | res.getbyte(1)).to_f
      @temperature = -45 + 175 * st / 65535
    else
      @temperature = nil
    end

    # 湿度計算 (SHT4x 独自の計算式)
    if crc8(res[3, 2]) == res.getbyte(5)
      srh = (res.getbyte(3) << 8 | res.getbyte(4)).to_f
      val = -6 + 125 * srh / 65535
      # 0-100%の範囲に収める
      @humidity = val < 0 ? 0 : (val > 100 ? 100 : val)
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
sht = SHT40.new(i2c, repeatability: :high) #デフォルトは :high

loop do
  if sht.read
    puts "----"
    puts "temp: #{sht.temperature}"
    puts "humi: #{sht.humidity}"
  end
  sleep 1
end
=end
