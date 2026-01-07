class PCF85063
  def initialize(i2c)
    @i2c = i2c
    @address = 0x51
    # 制御レジスタの初期化 (STOPビットを0にする)
    @i2c.write(@address, [0x00, 0x00])
    sleep 0.1
  end

  # RTC からの読み込み. 戻り値は数字の配列 [年, 月, 日, 曜, 時, 分, 秒]
  def read()
    # 0x04番地から7バイト分読み込み (秒, 分, 時, 日, 曜, 月, 年)
    a = @i2c.read(@address, 7, 0x04).bytes

    @time = Array.new
    # インデックスと値の対応 (PCF85063):
    # a[0]:秒, a[1]:分, a[2]:時, a[3]:日, a[4]:曜, a[5]:月, a[6]:年
    
    # 変換して格納 [年, 月, 日, 曜, 時, 分, 秒]
    # 各レジスタの不要なビットをマスク (例: 秒のOSビットなど)
    raw_data = [a[6], a[5] & 0x1f, a[3] & 0x3f, a[4] & 0x07, a[2] & 0x3f, a[1] & 0x7f, a[0] & 0x7f]
    
    raw_data.each_with_index do |num, i|
      @time[i] = sprintf('%02x', num)
    end

    return @time.map { |t| t.to_i }
  end

  # RTC への書き込み．引数は数字の配列 [年, 月, 日, 曜, 時, 分, 秒]
  def write(idate)
    date = Array.new
    # BCD データへの変換
    idate.each do |num|
      date << ((num / 10) << 4 | (num % 10))
    end
    
    # PCF85063のレジスタ順(0x04〜)に合わせて書き込み
    # [0x04(先頭番地), 秒, 分, 時, 日, 曜, 月, 年]
    @i2c.write(@address, [0x04, date[6], date[5], date[4], date[2], date[3], date[1], date[0]])
    sleep 0.1
  end

  def datetime; read(); end

  def str_date();     sprintf("%02d-%02d-%02d", @time[0].to_i, @time[1].to_i, @time[2].to_i); end
  def str_time();     sprintf("%02d:%02d:%02d", @time[4].to_i, @time[5].to_i, @time[6].to_i); end
  def str_datetime(); sprintf("20%02d%02d%02d%02d%02d%02d", @time[0].to_i, @time[1].to_i, @time[2].to_i, @time[4].to_i, @time[5].to_i, @time[6].to_i); end

  def year()  ; @time[0].to_i + 2000 ; end
  def year2() ; @time[0].to_i ; end
  def mon()   ; @time[1].to_i ; end
  def mday()  ; @time[2].to_i ; end
  def wday()  ; @time[3].to_i ; end
  def hour()  ; @time[4].to_i ; end
  def min()   ; @time[5].to_i ; end
  def sec()   ; @time[6].to_i ; end
end


=begin
#I2C 初期化
i2c = I2C.new()

## RTC 初期化. 時刻設定
rtc = PCF85063.new(i2c)

# RTC に初期値書き込み
rtc.write([20, 3, 31, 1, 23, 59, 40]) #年(下2桁), 月, 日, 曜日, 時, 分, 秒

# 適当な時間を表示
while true
  rtc.read  #時刻の読み出し
  t0 = sprintf("%02d-%02d-%02d", rtc.year - 2000, rtc.mon, rtc.mday)
  t1 = sprintf("%02d:%02d:%02d", rtc.hour, rtc.min, rtc.sec)

  puts sprintf("#{t0} #{rtc.wday} #{t1}")
  sleep 1
end
=end
