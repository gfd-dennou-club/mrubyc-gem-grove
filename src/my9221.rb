class MY9221
  def initialize(date_pin: 21, clk_pin: 22)
    @d = data_pin
    @c = clk_pin

    GPIO.new(@d, GPIO::OUT) 
    GPIO.new(@c, GPIO::OUT) 
    @leds = Array.new(24, 0)
  end

  def show
    my9221_transmit(@d, @c, @leds)
  end

  def on(id: 0, brightness: 40)
    if id >= 0 && id < 24
      @leds[id] = brightness
      show
    end
  end

  def clear
    i = 0
    while i < 24
      @leds[i] = 0
      i += 1
    end
  end

  def all_on(brightness: 40)
    i = 0
    while i < 24
      @leds[i] = brightness
      i += 1
    end
    show
  end
end

=begin

# --- メイン処理 ---
led = MY9221.new(date_pin: 21, clk_pin: 22)

led.all_on(brightness: 40) 

sleep 2

loop do
  24.times do |i|
    led.clear
    led.on(id: i, brightness: 120)
    sleep 0.05
  end
end
=end
