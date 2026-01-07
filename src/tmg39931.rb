class TMG39931
  REG = {
    ENABLE: 0x80, ATIME: 0x81, CONTROL: 0x8F,
    ID: 0x92, STATUS: 0x93, CDATAL: 0x94, PDATA: 0x9C
  }

  attr_reader :lux, :color, :color_raw, :proximity

  # ガンマ補正テーブル (0-15のインデックスを 0-255 の出力に変換)
  GAMMA_TABLE = [0, 48, 76, 99, 119, 136, 152, 167, 181, 194, 206, 218, 229, 239, 249, 255]

  def initialize(i2c, address = 0x39)
    @i2c, @address = i2c, address
    @lux, @proximity = 0, 0
    # 8bit カラー格納用
    @color = { r: 0, g: 0, b: 0 }
    # 16bit 生データ格納用
    @color_raw = { r: 0, g: 0, b: 0, c: 0 }

    id_data = @i2c.read(@address, 1, REG[:ID]).bytes[0]
    raise "TMG39931 not found" if (id_data >> 2) != 0x2a

    @atime, @again = 0x00, 64
    write_reg(REG[:ATIME], @atime)
    write_reg(REG[:CONTROL], 0x03) # 64x Gain
    write_reg(REG[:ENABLE], 0x07)
    sleep 0.8
  end

  def read
    # 計測完了待ち
    sleep((256 - @atime) * 0.00278 + 0.05)
    
    status = @i2c.read(@address, 1, REG[:STATUS]).bytes[0]
    return false unless (status & 0x03) == 0x03

    # 16bit 生データを読み取って @color_raw に格納
    raw = @i2c.read(@address, 8, REG[:CDATAL]).bytes
    @color_raw[:c] = raw[1] << 8 | raw[0]
    @color_raw[:r] = raw[3] << 8 | raw[2]
    @color_raw[:g] = raw[5] << 8 | raw[4]
    @color_raw[:b] = raw[7] << 8 | raw[6]
    
    # 近接データの更新
    @proximity = @i2c.read(@address, 1, REG[:PDATA]).bytes[0]
    
    # 8bit 変換を実行して @color を更新
    update_8bit_color
    
    # 照度計算
    @lux = calculate_lux(@color_raw)
    
    true
  end

  private

  # 16bit -> 8bit 変換 (色彩強調ロジック込み)
  def update_8bit_color
    # 一番小さい値を底引きして色の差（鮮やかさ）を強調
    min_val = [@color_raw[:r], @color_raw[:g], @color_raw[:b]].min
    
    [:r, :g, :b].each do |k|
      diff = @color_raw[k] - min_val
      # 差分を 0-15 のインデックスに変換 (>> 9)
      index = diff >> 9
      index = 15 if index > 15
      @color[k] = GAMMA_TABLE[index]
    end
  end

  def calculate_lux(rgbc)
    ir = (rgbc[:r] + rgbc[:g] + rgbc[:b] - rgbc[:c]) / 2
    ir = 0 if ir < 0
    # 視感度補正 y = 0.362R + 1.0G + 0.136B (整数計算用に1000倍)
    y = (362 * (rgbc[:r] - ir)) + (1000 * (rgbc[:g] - ir)) + (136 * (rgbc[:b] - ir))
    return 0 if y <= 0
    # 110500 は ATIME=0, AGAIN=64 の時の CPL(約110.5) を1000倍したもの
    (y / 110500).to_i
  end

  def write_reg(reg, val)
    @i2c.write(@address, [reg, val])
  end
end

=begin
# メインプログラム
i2c = I2C.new()
scd = TMG39931.new(i2c)

puts "Sensor initialized. Monitoring starts..."

loop do
  if scd.read
    # 8bit カラー (0-255)
    c8 = scd.color
    puts "8bit Color: R:#{c8[:r]} G:#{c8[:g]} B:#{c8[:b]}"

    # 16bit 生データ
    raw = scd.color_raw
    puts "Raw Data  : R:#{raw[:r]} G:#{raw[:g]} B:#{raw[:b]} C:#{raw[:c]}"

    puts "Lux: #{scd.lux} lx, Proximity: #{scd.proximity}"
    puts "------------------------"
  else
    puts "Data not valid yet."
  end

  # メインループの待機
  sleep 10
end
=end
