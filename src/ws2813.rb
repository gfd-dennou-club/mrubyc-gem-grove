class WS2813
  def initialize(gpio_pin, led_count: 1)
    @led_count = led_count
    # C言語の初期化関数を呼び出し、ハンドルを取得
    @handle = ws2813_init(gpio_pin, led_count)
  end

  # 1つ1つのLEDの色を変更するメソッド
  # indexを指定しない場合は、最初のLED（単体LEDの場合など）を対象にする
  def write(index: 0, r: 0, g: 0, b: 0)
    return if index >= @led_count || @handle.nil?
    
    # 色の設定
    ws2813_set_pixel(@handle, index, r, g, b)

    # 設定した色を実際にLEDへ送信する    
    ws2813_show(@handle) unless @handle.nil?
  end

  # 全てのLEDの色をキーワード引数で一括指定するメソッド
  def write_all(r: 0, g: 0, b: 0)
    return if @handle.nil?
    
    @led_count.times do |i|
      write(index: i, r: r, g: g, b: b)
    end

    # 設定した色を実際にLEDへ送信する    
    ws2813_show(@handle) unless @handle.nil?
  end

  # 全て消灯
  def clear
    write_all(r: 0, g: 0, b: 0)
  end
end

=begin
# 単体LED（1個）の場合
led = WS2813.new(18, led_count: 1)

led.write_all(r: 255, g: 255, b: 255)  #白色
sleep 3

# 1つ目のLEDの色を指定
loop do
  led.write(r: 255, g: 0, b: 0)
  sleep 1
  led.write(r: 0, g: 255, b: 0)
  sleep 1
  led.write(r: 0, g: 0, b: 255)
  sleep 1
  led.clear
end

## テープライト（例: 30個）の場合
#strip = WS2813.new(18, led_count: 30)

## 10番目のLEDだけ青くする
#strip.write(index: 10, r: 0, g: 0, b: 255)
#sleep 1

## 全てのLEDを一括でキーワード引数指定
#strip.write_all(r: 100, g: 255, b: 50)
=end

