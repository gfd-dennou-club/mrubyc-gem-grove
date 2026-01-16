class BMP581
  ADDR          = 0x47
  REG_CHIP_ID   = 0x01
  REG_CMD       = 0x7E
  REG_STATUS    = 0x28
  REG_OSR_CONFIG = 0x36
  REG_ODR_CONFIG = 0x37
  REG_TEMP_DATA  = 0x1D
  REG_PRESS_DATA = 0x20

  OSR_MAP = { x1: 0, x2: 1, x4: 2, x8: 3, x16: 4, x32: 5, x64: 6, x128: 7 }

  def initialize(i2c, options = {})
    @i2c = i2c
    @address = options[:address] || ADDR
    @temperature = 0.0
    @pressure = 0.0

    os_t = options[:osr_t] || :x1
    os_p = options[:osr_p] || :x8

    # 1. ソフトリセット
    @i2c.write(@address, [REG_CMD, 0xB6])
    sleep 0.1

    # 2. チップID確認
    res = @i2c.read(@address, 1, REG_CHIP_ID)
    return if !res || res.bytes[0] != 0x50

    # 0x40 を足して「気圧計測スイッチ」をONにする
    ot = OSR_MAP[os_t] || 0
    op = OSR_MAP[os_p] || 3
    @i2c.write(@address, [REG_OSR_CONFIG, 0x40 | (ot << 3) | op])

    # 初期状態は待機モード(0x00)にしておく
    @i2c.write(@address, [REG_ODR_CONFIG, 0x00])
  end

  def read
    # Forced Mode
    @i2c.write(@address, [REG_ODR_CONFIG, 0x01])
    
    # 計測後のウェイト
    sleep 0.05

    # データの読み取り
    res = @i2c.read(@address, 6, REG_TEMP_DATA)
    return false if res == nil || res.length < 6
    
    data = res.bytes
    t_raw = (data[2] << 16) | (data[1] << 8) | data[0]
    p_raw = (data[5] << 16) | (data[4] << 8) | data[3]

    t_raw -= 16777216 if t_raw > 8388607
    p_raw -= 16777216 if p_raw > 8388607

    @temperature = t_raw / 65536.0
    @pressure = (p_raw / 64.0) / 100.0

    true
  end

  def temperature; @temperature; end
  def pressure; @pressure; end
end
