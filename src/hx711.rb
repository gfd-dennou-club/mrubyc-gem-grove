class HX711
  attr_reader :size, :offset
  attr_accessor :scale

  def initialize(dat_pin:, clk_pin:, size: 5, offset: -141153, scale: 420.5)
    @dat = dat_pin
    @clk = clk_pin
    @size = size     # size kg 用
    @offset = offset
    @scale = scale

    datpin = GPIO.new(@dat, GPIO::IN)
    clkpin = GPIO.new(@clk, GPIO::OUT)
    clkpin.write(0)
  end

  # データが準備できるまで待機して読み取る
  def read_raw
    val = nil
    while val.nil?
      val = hx711_read_raw(@dat, @clk)
      sleep 0.01 if val.nil? # 準備ができていなければ 10ms 休む
    end
    val
  end

  # ゼロ点調整
  def tare(times = 10)
    sum = 0
    times.times do
      sum += read_raw
      sleep 0.05
    end
    @offset = sum / times
  end

  # キャリブレーションメソッド
  def calibrate(weight_g, times = 10)
    return 1.0 if weight_g == 0
    
    sum = 0
    times.times do
      sum += read_raw
      sleep 0.05
    end
    average_raw = sum / times

    # スケールを計算: (計測値 - ゼロ点) / 重り(g)
    @scale = (average_raw - @offset).to_f / weight_g
    @scale
  end

  def read(times = 5)
    sum = 0
    times.times { sum += read_raw }
    avg = sum / times
    (avg - @offset) / @scale
  end
  
  def set_scale(scale); @scale = scale; end
  def get_scale; @scale; end
end

=begin
hx711 = HX711.new(dat_pin: 21, clk_pin: 22)

# 1. ゼロ点調整
#puts "Step 1: Taring... Keep the scale empty."
#hx711.tare
#puts "Offset: #{hx711.offset}"

# 2. キャリブレーション実行 
#puts "Step 2: Place 170g object and wait..."
#sleep 5 # 載せるための時間
#new_scale = hx711.calibrate(170.0)
#puts "Step 3: Calibration Done. New Scale: #{new_scale}"

# 以降、計測
loop do
  puts "Weight: #{hx711.read.to_i} g"
  sleep 0.5
end
=end
