class MPR121
  ADDR = 0x5B

  # レジスタアドレス
  ELE_STATUS_LSB = 0x00
  ELE_CFG        = 0x5E # ECR
  SOFT_RESET     = 0x80
  TOUCH_TH_BASE   = 0x41
  RELEASE_TH_BASE = 0x42

  # 感度設定の定義 (しきい値が小さいほど敏感)
  # [Touch Threshold, Release Threshold]
  SENSITIVITY = {
    :high   => [0x08, 0x04],
    :medium => [0x0C, 0x06], # デフォルト
    :low    => [0x1E, 0x0F]
  }

  attr_reader :touched_mask

  def initialize(i2c, address: ADDR, touch_level: :medium, release_level: :medium)
    @i2c = i2c
    @address = address
    @touched_mask = 0

    # シンボルからしきい値を取得
    t_cfg = SENSITIVITY[touch_level] || SENSITIVITY[:medium]
    r_cfg = SENSITIVITY[release_level] || SENSITIVITY[:medium]
    
    t_th = t_cfg[0] # Touch は配列の0番目
    r_th = r_cfg[1] # Release は配列の1番目

    # ソフトリセット
    @i2c.write(@address, SOFT_RESET, 0x63)
    sleep 0.01

    # ストップモードへ (設定変更のため)
    @i2c.write(@address, ELE_CFG, 0x00)

    # フィルタ・ベースライン等のデフォルト設定
    setup_default_filters

    # 全電極(0-11)のしきい値を設定
    12.times do |i|
      @i2c.write(@address, TOUCH_TH_BASE + i * 2, t_th)
      @i2c.write(@address, RELEASE_TH_BASE + i * 2, r_th)
    end

    # ランモードへ移行 (ELE0-11有効)
    @i2c.write(@address, ELE_CFG, 0x8F)
  end

  def read
    # 状態の読み取りには微小な待ち時間(1ms程度)を設ける
    sleep 0.001
    
    res = @i2c.read(@address, 2, ELE_STATUS_LSB)
    return false if res.nil?

    @touched_mask = (res.getbyte(1) << 8) | res.getbyte(0)
    true
  end

  def touched?(pin)
    (@touched_mask & (1 << pin)) != 0
  end

  private

  def setup_default_filters
    # データシート推奨のフィルタ設定値
    [[0x2B, 0x01], [0x2C, 0x01], [0x2D, 0x00], [0x2E, 0x00],
     [0x2F, 0x01], [0x30, 0x01], [0x31, 0xFF], [0x32, 0x02],
     [0x33, 0x00], [0x34, 0x00], [0x35, 0x00],
     [0x5B, 0x00], [0x5C, 0x10], [0x5D, 0x24]].each do |reg, val|
      @i2c.write(@address, reg, val)
    end
  end
end


=begin
i2c = I2C.new()

# 感度を高めに設定して初期化
mpr = MPR121.new(i2c, touch_level: :high, release_level: :high)

loop do
  if mpr.read

    # 全体のビットマスクを表示
    # puts "Touched mask: #{mpr.touched_mask.to_s(2)}"

    [0, 1, 2, 3, 8, 9, 10, 11].each do |i|
      if mpr.touched?(i)
        puts "Pin #{i} is Touched!"
      end
    end

  end
  sleep 0.1
end

=end
