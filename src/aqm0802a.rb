class AQM0802A
  
  def initialize(i2c)
    @i2c = i2c
    sleep(0.1)
    lcd_write(0x00, [0x38, 0x39, 0x14, 0x70, 0x56, 0x6c])
    sleep(1)
    lcd_write(0x00, [0x38, 0x0c, 0x01])
  end

  def lcd_write(opcode, data)
    n = 0
    while n < data.length
      @i2c.write(0x3e, [opcode, data[n]])
      n += 1
    end
  end

  def clear
    lcd_write(0x00, [0x01])
  end

  def cursor(x, y)
    lcd_write(0x00, [0x80 + (0x40 * y + x)])
  end

  def print(s)
    a = Array.new
    s.length.times do |n|
      a.push(s[n].ord)
    end
    lcd_write(0x40, a)
  end

end

=begin
#I2C 初期化
i2c = I2C.new()

# LCD 初期化
lcd = AQM0802A.new(i2c)

# LCD に "Hello World" 表示
lcd.clear          #初期化
str = "ESP"        #変数に値を代入
lcd.cursor(0, 0)   
lcd.print("Hello?!")
lcd.cursor(0, 1)
lcd.print("from #{str}") #変数の埋め込み
=end
