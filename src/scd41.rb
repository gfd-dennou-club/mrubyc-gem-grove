class SCD41
  I2C_ADDR = 0x62

  CMD_START_PERIODIC    = [0x21, 0xb1]
  CMD_READ_MEASURE      = [0xec, 0x05]
  CMD_STOP_PERIODIC     = [0x3f, 0x86]
  CMD_GET_DATA_READY    = [0xe4, 0xb8]
  CMD_SET_TEMP_OFFSET   = [0x24, 0x1d]
  CMD_SET_ALTITUDE      = [0x24, 0x27]
  CMD_SET_ASC           = [0x24, 0x16]

  def initialize(i2c, options = {})
    @i2c = i2c
    @co2, @temp, @humi = 0, 0.0, 0.0

    altitude    = options[:altitude]    || 0
    temp_offset = options[:temp_offset] || 4.0
    
    # ブール値は nil チェックで判定
    asc = options[:asc]
    asc = true if asc == nil # 指定がない場合のみデフォルトの true にする

    # 計測を一度止めて設定モードへ
    @i2c.write(I2C_ADDR, CMD_STOP_PERIODIC)
    sleep(0.5)

    # 高度設定
    set_config(CMD_SET_ALTITUDE, altitude) if altitude > 0
    
    # 温度オフセット設定
    t_off = (temp_offset * 65536 / 175).to_i
    set_config(CMD_SET_TEMP_OFFSET, t_off)

    # 自動自己校正 (ASC)
    set_config(CMD_SET_ASC, asc ? 1 : 0)

    # 計測開始
    @i2c.write(I2C_ADDR, CMD_START_PERIODIC)
  end

  # read 内でデータ準備を待つ
  def read(timeout_count = 20)
    count = 0
    until data_ready?
      count += 1
      return false if count > timeout_count
      sleep(0.5)
    end

    begin
      @i2c.write(I2C_ADDR, CMD_READ_MEASURE)
      sleep(0.01)
      res = @i2c.read(I2C_ADDR, 9).bytes

      # CRCチェック
      return false unless check_crc(res[0, 2], res[2])
      return false unless check_crc(res[3, 2], res[5])
      return false unless check_crc(res[6, 2], res[8])

      @co2  = (res[0] << 8) | res[1]
      @temp = -45.0 + (175.0 * ((res[3] << 8) | res[4]) / 65536.0)
      @humi = 100.0 * ((res[6] << 8) | res[7]) / 65536.0
      true
    rescue
      false
    end
  end

  def co2; @co2; end
  def temperature; ((@temp * 10).to_i / 10.0); end
  def humidity; ((@humi * 10).to_i / 10.0); end

  private

  def data_ready?
    @i2c.write(I2C_ADDR, CMD_GET_DATA_READY)
    sleep(0.01)
    res = @i2c.read(I2C_ADDR, 3).bytes
    ((res[0] & 0x07) << 8 | res[1]) > 0
  rescue
    false
  end

  def set_config(cmd, value)
    data = [value >> 8, value & 0xFF]
    crc = calculate_crc(data)
    @i2c.write(I2C_ADDR, cmd + data + [crc])
    sleep(0.01)
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
# スキャン実行
devices = i2c.scan

puts "I2C scan results:"
if devices.empty?
  puts "No devices found."
else
  devices.each do |addr|
    # to_s(16) で 16 進数の文字列に変換
    # "0x" を付けて、2桁で表示（大文字にしたい場合は upcase）
    puts "Device found at: 0x#{addr.to_s(16).upcase}"
  end
end
=end
=begin
i2c = I2C.new()

# オプションをシンボルで指定
options = {
  altitude: 0,        # 海抜0m
  temp_offset: 0.0,   # 温度オフセット 0度
  asc: false          # 自動校正オフ
}

scd = SCD40.new(i2c, options)

loop do
  if scd.measure
    puts "CO2: #{scd.co2} ppm"
  end
  sleep 1
end
=end
