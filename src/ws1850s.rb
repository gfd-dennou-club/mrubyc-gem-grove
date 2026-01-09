class WS1850S
  ADDR = 0x28

  def initialize(i2c, address: ADDR)
    @i2c = i2c
    @address = address
    @uid = [0,0,0,0]
    @authenticated_sector = nil # 現在認証済みのセクタを保持
    reset_chip
  end

  def uid
    @uid.map { |b| b.to_s(16).rjust(2, '0').upcase }.join
  end

  def reset_chip
    write_reg(0x01, 0x0F) # Reset
    sleep 0.1
    write_reg(0x2A, 0x8D); write_reg(0x2B, 0x3E)
    write_reg(0x2D, 30);   write_reg(0x2C, 0)
    write_reg(0x15, 0x40); write_reg(0x11, 0x3D)
    write_reg(0x26, 0x70); write_reg(0x14, 0x03)
    stop_crypto
  end

  def stop_crypto
    write_reg(0x08, 0x00)
    @authenticated_sector = nil # 暗号化を切ったら認証状態もリセット
  end

  def connected?
    stop_crypto # 新しいカードを探すときはリセット
    
    # REQA
    write_reg(0x01, 0x00); write_reg(0x0A, 0x80)
    write_reg(0x0D, 0x07); write_reg(0x09, 0x26)
    write_reg(0x01, 0x0C); write_reg(0x0D, 0x87)
    return false unless wait_fifo(1)

    # Anticollision
    write_reg(0x01, 0x00); write_reg(0x0A, 0x80); write_reg(0x0D, 0x00)
    write_reg(0x09, 0x93); write_reg(0x09, 0x20)
    write_reg(0x01, 0x0C); write_reg(0x0D, 0x80)
    return false unless wait_fifo(5)

    raw = @i2c.read(@address, 5, 0x09)
    return false if raw == nil

    @uid[0] = raw.getbyte(0); @uid[1] = raw.getbyte(1)
    @uid[2] = raw.getbyte(2); @uid[3] = raw.getbyte(3)

    # Select
    write_reg(0x12, 0x80); write_reg(0x13, 0x80)
    write_reg(0x01, 0x00); write_reg(0x0A, 0x80)
    write_reg(0x09, 0x93); write_reg(0x09, 0x70)
    @uid.each { |b| write_reg(0x09, b) }
    write_reg(0x09, raw.getbyte(4)) # BCC
    write_reg(0x01, 0x0C); write_reg(0x0D, 0x80)
    res = wait_fifo(1)
    write_reg(0x12, 0x00); write_reg(0x13, 0x00)
    res
  end

  def puts(msg, block: 4)
    validate_block!(block)
    return false unless authenticate(block)

    write_reg(0x12, 0x80); write_reg(0x13, 0x80)
    cmd_res = transceive_simple(0xA0, block, 1)
    unless cmd_res
      write_reg(0x12, 0x00); write_reg(0x13, 0x00); return false
    end

    bytes = msg.bytes
    write_reg(0x01, 0x00); write_reg(0x0A, 0x80)
    16.times do |i|
      write_reg(0x09, (i < bytes.length ? bytes[i] : 0))
    end
    write_reg(0x01, 0x0C); write_reg(0x0D, 0x80)
    sleep 0.02
    write_reg(0x12, 0x00); write_reg(0x13, 0x00)
    true
  end

  def gets(block: 4)
    validate_block!(block)
    return nil unless authenticate(block)

    write_reg(0x12, 0x80); write_reg(0x13, 0x80)
    cmd_res = transceive_simple(0x30, block, 16)
    unless cmd_res
      write_reg(0x12, 0x00); write_reg(0x13, 0x00); return nil
    end

    raw = @i2c.read(@address, 16, 0x09)
    write_reg(0x12, 0x00); write_reg(0x13, 0x00)
    return nil if raw == nil

    str = ""
    16.times do |i|
      b = raw.getbyte(i)
      str += b.chr if b > 31 && b < 127
    end
    str
  end

  private

  def validate_block!(block)
    unless [4, 5, 6].include?(block)
      raise RangeError, "Block #{block} is restricted. Use 4, 5, or 6."
    end
  end

  def authenticate(block)
    return false if block < 4 || block > 6
    target_sector = block / 4
    
    # すでにそのセクタが認証済みなら何もしない
    return true if @authenticated_sector == target_sector

    # セクタが変わる場合のみ一度暗号化を切って再認証
    stop_crypto if @authenticated_sector != nil

    write_reg(0x01, 0x00); write_reg(0x0A, 0x80)
    write_reg(0x09, 0x60); write_reg(0x09, block)
    6.times { write_reg(0x09, 0xFF) }
    @uid.each { |b| write_reg(0x09, b) }
    write_reg(0x01, 0x0E)

    success = false
    20.times do
      if (read_reg(0x08) & 0x08) != 0
        success = true
        @authenticated_sector = target_sector # 認証成功を記録
        break
      end
      sleep 0.005
    end
    success
  end

  def write_reg(reg, val); @i2c.write(@address, reg, val); end
  def read_reg(reg)
    res = @i2c.read(@address, 1, reg)
    (res && res.length > 0) ? res.getbyte(0) : 0
  end
  def wait_fifo(n)
    found = false
    30.times do
      if read_reg(0x0A) >= n; found = true; break; end
      sleep 0.002
    end
    found
  end
  def transceive_simple(c1, c2, n)
    write_reg(0x01, 0x00); write_reg(0x0A, 0x80)
    write_reg(0x09, c1); write_reg(0x09, c2)
    write_reg(0x01, 0x0C); write_reg(0x0D, 0x80)
    wait_fifo(n)
  end
end

=begin
i2c = I2C.new()
nfc = WS1850S.new(i2c)

loop do 
  if nfc.connected?
    msg = ["Hello mruby/c", "Hello Matsue", "Hello Shimane"]
    3.times do |i|
      if nfc.puts(msg[i], block: i+4) #ブロックは 4, 5, 6 が利用可
        puts "Write SUCCESS #{i+4}: #{msg[i]}"
      else
        puts "Write FAILED #{i+4}"
      end
    end
    break # 成功したら終了
  end
  sleep 0.2
end


loop do
  if nfc.connected?
    puts "--- Card Detected: #{nfc.uid} ---"

    [4, 5, 6].each do |b|
      msg = nfc.gets(block: b)
      if msg
        puts "Block #{b}: #{msg}"
      else
        puts "Block #{b}: Read Failed"
      end
    end
    puts "------------------------"
    sleep 1.0 
  end
  sleep 0.1
end
=end
