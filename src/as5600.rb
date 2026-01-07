class AS5600
  I2C_ADDR = 0x36

  # レジスタ定義
  REG_STATUS    = 0x0B
  REG_RAW_ANGLE = 0x0C # 書き込み不可、フィルタ前
  REG_ANGLE     = 0x0E # フィルタ・ヒステリシス適用後
  REG_MAGNITUDE = 0x1B # 磁石の強さ

  def initialize(i2c)
    @i2c = i2c
    @raw_value = 0
    
    # 接続確認用のステータスチェック
    status = @i2c.read(I2C_ADDR, 1, REG_STATUS).bytes[0]
  end

  # 計測実行
  def read
    begin
      # 12ビットデータを読み出し (高位・低位の2バイト)
      # AS5600はビッグエンディアン (MSBが先)
      data = @i2c.read(I2C_ADDR, 2, REG_ANGLE).bytes
      
      # 12ビットとして結合 (上位4ビット + 下位8ビット)
      @raw_value = ((data[0] & 0x0F) << 8) | data[1]
      true
    rescue => e
      warn "AS5600 Read Error: #{e.message}"
      false
    end
  end

  # 角度 (0.0 〜 359.9度) を返す
  def angle
    # 360度 / 4096ステップ
    deg = (@raw_value * 360.0) / 4096.0
    
    # 小数点第1位で擬似四捨五入
    ((deg * 10) + 0.5).to_i / 10.0
  end

  # 生のカウント値 (0 〜 4095) を返す
  def angle_raw
    @raw_value
  end

  # 磁石の状態を確認する
  def magnet_status
    status = @i2c.read(I2C_ADDR, 1, REG_STATUS).bytes[0]
    
    if (status & 0x20) != 0 # MD bit
      "OK"
    elsif (status & 0x10) != 0 # ML bit (Too Weak)
      "Too Far"
    elsif (status & 0x08) != 0 # MH bit (Too Strong)
      "Too Close"
    else
      "Not Found"
    end
  end
end

=begin
i2c = I2C.new()
encoder = AS5600.new(i2c)

puts "Searching for magnetic field..."

loop do
  if encoder.read
    puts "--- Rotary Sensor ---"
    puts "Angle:  #{encoder.angle}°"
    puts "Raw:    #{encoder.raw}"
    puts "Magnet: #{encoder.magnet_status}"
    
    # 磁石の強さステータスを取得
    status = encoder.magnet_status
    
    # 磁石が検知されていれば値を表示
    if status == "OK"
      puts "Found! Angle: #{encoder.angle}° (Raw: #{encoder.raw})"
    else
      # 磁石がない、または遠い場合はステータスを表示
      puts "Status: #{status} (Check your magnet!)"
    end
  end
  sleep 0.2
end
=end
