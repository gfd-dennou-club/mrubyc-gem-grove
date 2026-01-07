class VEML6070
  ADDR_WRITE  = 0x38
  ADDR_READ_L = 0x38
  ADDR_READ_H = 0x39

  IT_SETTINGS = {
    T1_2: { cmd: 0x00, multiplier: 0.5 },
    T1:   { cmd: 0x01, multiplier: 1.0 },
    T2:   { cmd: 0x02, multiplier: 2.0 },
    T4:   { cmd: 0x03, multiplier: 4.0 }
  }

  def initialize(i2c, it: :T1)
    @i2c = i2c
    @it_config = IT_SETTINGS[it] || IT_SETTINGS[:T1]
    @uv_raw = 0

    cmd = (@it_config[:cmd] << 2) | 0x02
    @i2c.write(ADDR_WRITE, [cmd])
  end

  def uv_raw
    @uv_raw
  end

  # UVインデックスを計算して返す
  def uv_index
    # 1T相当に正規化
    normalized = @uv_raw.to_f / @it_config[:multiplier]
    
    # 指数へ変換 (560で割る)
    idx = normalized / 560.0
    ((idx * 100) + 0.5).to_i / 100.0
  end

  def uv
    uv_index
  end

  def read
    sleep(0.125 * @it_config[:multiplier])

    begin
      data_l = @i2c.read(ADDR_READ_L, 1).bytes[0]
      data_h = @i2c.read(ADDR_READ_H, 1).bytes[0]

      @uv_raw = (data_h << 8) | data_l
      true
    rescue => e
      warn "VEML6070 Read Error: #{e.message}"
      false
    end
  end

  def uv_status
    idx = uv_index
    case idx
    when 0...3.0  then "Low"
    when 3.0...6.0 then "Moderate"
    when 6.0...8.0 then "High"
    when 8.0...11.0 then "Very High"
    else                 "Extreme"
    end
  end
end

=begin
i2c = I2C.new

# 室内など暗い場所なので感度を上げて計測
veml = VEML6070.new(i2c, it: :T4)

loop do
  if veml.read
    # uv は 4倍された大きな値が出るが、
    # uv_status はそれを 1/4 に補正して正しく判定する
    puts "RAW Count:  #{veml.uv_raw}"    # 生の数値
    puts "UV Index:   #{veml.uv_index}"  # 物理量 (uv メソッドでも可)
    puts "Status:     #{veml.uv_status}" # 判定結果
  end
  sleep 10
end
=end
