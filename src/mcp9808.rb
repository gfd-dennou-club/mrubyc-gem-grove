class MCP9808
  REG_MANUF_ID = 0x06
  REG_DEVICE_ID = 0x07
  REG_CONFIG = 0x01
  REG_CONFIG_SHUTDOWN = 0x0100
  REG_AMBIENT_TEMP = 0x05
  REG_RESOLUTION = 0x08
  I2CADDR_DEFAULT = 0x18

  RESOLUTIONS = {
    low:    0x00,
    medium: 0x01,
    high:   0x02,
    ultra:  0x03
  }

  attr_reader :temperature

  def initialize(i2c, resolution: :ultra)
    @i2c = i2c
    @temperature = nil

    # デバイスの確認
    unless read16(REG_MANUF_ID) == 0x0054 && read16(REG_DEVICE_ID) == 0x0400
      puts "Warning: MCP9808 not found or ID mismatch."
    end

    # スリープ解除
    wake

    # 解像度の設定
    set_resolution(resolution)
  end

  def read
    @temperature = read_temp_c
  end

  def wake
    conf_register = read16(REG_CONFIG)
    conf_wake = conf_register & ~REG_CONFIG_SHUTDOWN
    write16(REG_CONFIG, conf_wake)
    sleep 0.26
  end

  def shutdown
    conf_register = read16(REG_CONFIG)
    conf_shutdown = conf_register | REG_CONFIG_SHUTDOWN
    write16(REG_CONFIG, conf_shutdown)
  end

  private

  def set_resolution(type)
    val = RESOLUTIONS[type] || RESOLUTIONS[:ultra]
    write8(REG_RESOLUTION, val)
  end

  def read_temp_c
    t = read16(REG_AMBIENT_TEMP)
    return nil if t == 0xFFFF

    # 温度データの計算
    temp = t & 0x0FFF
    temp /= 16.0
    temp -= 256 if (t & 0x1000) != 0
    temp
  end

  def read8(reg)
    @i2c.write(I2CADDR_DEFAULT, reg)
    @i2c.readfrom(I2CADDR_DEFAULT, 1)[0]
  end

  def read16(reg)
    @i2c.write(I2CADDR_DEFAULT, reg)
    data = @i2c.readfrom(I2CADDR_DEFAULT, 2)
    (data[0] << 8) | data[1]
  end

  def write8(reg, value)
    @i2c.write(I2CADDR_DEFAULT, [reg, value])
  end

  def write16(reg, value)
    @i2c.write(I2CADDR_DEFAULT, [reg, (value >> 8) & 0xFF, value & 0xFF])
  end
end

=begin
i2c = I2C.new()

# 解像度を指定して初期化 (:low, :medium, :high, :ultra) 
#mcp9808 = MCP9808.new(i2c, resolution: :high)
mcp9808 = MCP9808.new(i2c) #デフォルトは :ultra

loop do 
   mcp9808.measure
   puts "温度: #{mcp9808.temperature} C"
   sleep 1
end
=end
