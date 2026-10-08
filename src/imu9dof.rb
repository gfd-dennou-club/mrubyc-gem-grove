# Grove - IMU 9DOF センサー読み取りドライバ
# ICM20600 + AK09918
#
# センサーの生データを読み取り、加速度(g)、角速度(dps)、地磁気(µT)、温度(℃)へ換算する。
# オフセット補正、角度・クォータニオンの計算、センサーフュージョンは行わない。

class IMU9DOF
  # 加速度・ジャイロと地磁気センサーのI2Cアドレス
  ICM20600_ADDR = 0x69
  AK09918_ADDR = 0x0c

  # ICM20600：識別、電源、測定設定、データ読み取り用レジスター
  ICM_WHO_AM_I = 0x75
  ICM_PWR_MGMT_1 = 0x6b
  ICM_PWR_MGMT_2 = 0x6c
  ICM_SMPLRT_DIV = 0x19
  ICM_CONFIG = 0x1a
  ICM_GYRO_CONFIG = 0x1b
  ICM_ACCEL_CONFIG = 0x1c
  ICM_ACCEL_CONFIG2 = 0x1d
  ICM_ACCEL_XOUT_H = 0x3b

  # AK09918：識別、測定状態、地磁気データ、動作設定用レジスター
  AK_WIA1 = 0x00
  AK_ST1 = 0x10
  AK_HXL = 0x11
  AK_ST2 = 0x18
  AK_CNTL2 = 0x31
  AK_CNTL3 = 0x32

  # 各軸の生データ (符号付き16ビット整数)
  attr_reader :raw_accel_x, :raw_accel_y, :raw_accel_z
  attr_reader :raw_gyro_x, :raw_gyro_y, :raw_gyro_z
  attr_reader :raw_magnet_x, :raw_magnet_y, :raw_magnet_z
  attr_reader :raw_temperature
  # 各軸の換算値：加速度(g)、角速度(度/秒)、地磁気(µT)、温度(℃)
  attr_reader :accel_x_g, :accel_y_g, :accel_z_g
  attr_reader :gyro_x_dps, :gyro_y_dps, :gyro_z_dps
  attr_reader :magnet_x_ut, :magnet_y_ut, :magnet_z_ut
  attr_reader :temperature_c

  # I2Cを受け取り、保持する値と2つのセンサーを初期化する
  def initialize(i2c)
    @i2c = i2c

    @raw_accel_x = 0
    @raw_accel_y = 0
    @raw_accel_z = 0
    @raw_gyro_x = 0
    @raw_gyro_y = 0
    @raw_gyro_z = 0
    @raw_magnet_x = 0
    @raw_magnet_y = 0
    @raw_magnet_z = 0
    @raw_temperature = 0
    @accel_x_g = 0.0
    @accel_y_g = 0.0
    @accel_z_g = 0.0
    @gyro_x_dps = 0.0
    @gyro_y_dps = 0.0
    @gyro_z_dps = 0.0
    @magnet_x_ut = 0.0
    @magnet_y_ut = 0.0
    @magnet_z_ut = 0.0
    @temperature_c = 0.0

    configure_icm20600
    configure_ak09918
  end

  # 加速度・角速度・温度を更新する (読み取り失敗時はfalse)
  # sample_periodは旧プログラムとの互換用で、計算には使用しない。
  def measure(sample_period = nil)
    return false unless read_icm20600

    # 地磁気がまだ更新されていない場合は、直前の値をそのまま使う。
    read_ak09918
    true
  end

  # measureと同じ測定処理を行う
  def read
    measure
  end

  private

  # 加速度・ジャイロをリセットし、測定レンジとフィルターを設定する
  def configure_icm20600
    @i2c.write(ICM20600_ADDR, ICM_PWR_MGMT_1, 0x80)
    sleep 0.1

    id = read_u8(ICM20600_ADDR, ICM_WHO_AM_I)
    raise "ICM20600 not found" if id.nil?

    # リセット完了後、クロックを選択して各軸の測定を有効にする
    @i2c.write(ICM20600_ADDR, ICM_PWR_MGMT_1, 0x01)
    sleep 0.01
    @i2c.write(ICM20600_ADDR, ICM_PWR_MGMT_2, 0x00)
    # サンプルレートの分周値とローパスフィルターを設定する
    @i2c.write(ICM20600_ADDR, ICM_SMPLRT_DIV, 9)
    @i2c.write(ICM20600_ADDR, ICM_CONFIG, 3)
    # 角速度の測定レンジは±250 dps、加速度は±2g
    @i2c.write(ICM20600_ADDR, ICM_GYRO_CONFIG, 0)
    @i2c.write(ICM20600_ADDR, ICM_ACCEL_CONFIG, 0)
    @i2c.write(ICM20600_ADDR, ICM_ACCEL_CONFIG2, 3)
  end

  # 地磁気センサーをリセットし、連続測定を開始する
  def configure_ak09918
    @i2c.write(AK09918_ADDR, AK_CNTL3, 0x01)
    sleep 0.01

    id = @i2c.read(AK09918_ADDR, 2, AK_WIA1)
    raise "AK09918 not found" if id.nil? || id.length < 2

    # 100Hzの連続測定モード
    @i2c.write(AK09918_ADDR, AK_CNTL2, 0x08)
    sleep 0.01
  end

  # 加速度3軸・温度・角速度3軸を14バイトでまとめて読み取る
  def read_icm20600
    data = @i2c.read(ICM20600_ADDR, 14, ICM_ACCEL_XOUT_H)
    return false if data.nil? || data.length < 14

    # 上位バイトが先に届くデータを、符号付き16ビット整数へ変換する
    @raw_accel_x = int16_be(data.getbyte(0), data.getbyte(1))
    @raw_accel_y = int16_be(data.getbyte(2), data.getbyte(3))
    @raw_accel_z = int16_be(data.getbyte(4), data.getbyte(5))
    @raw_temperature = int16_be(data.getbyte(6), data.getbyte(7))
    @raw_gyro_x = int16_be(data.getbyte(8), data.getbyte(9))
    @raw_gyro_y = int16_be(data.getbyte(10), data.getbyte(11))
    @raw_gyro_z = int16_be(data.getbyte(12), data.getbyte(13))

    # ±2gでは16384 LSB/g、±250 dpsでは131 LSB/(度/秒)
    # 生データを各感度で割り、物理単位へ換算する
    @accel_x_g = @raw_accel_x / 16384.0
    @accel_y_g = @raw_accel_y / 16384.0
    @accel_z_g = @raw_accel_z / 16384.0
    @gyro_x_dps = @raw_gyro_x / 131.0
    @gyro_y_dps = @raw_gyro_y / 131.0
    @gyro_z_dps = @raw_gyro_z / 131.0
    # 温度(℃) = 生データ / 326.8 + 25
    @temperature_c = @raw_temperature / 326.8 + 25.0
    true
  end

  # 新しい地磁気データがある場合だけ各軸を更新する
  def read_ak09918
    # ST1のビット0が1なら測定完了 (未完了・通信失敗時はfalse)
    status = read_u8(AK09918_ADDR, AK_ST1)
    return false if status.nil? || (status & 0x01) == 0

    # 地磁気6バイトからST2まで読み取り、測定データの読み出しを完了する
    data = @i2c.read(AK09918_ADDR, 8, AK_HXL)
    return false if data.nil? || data.length < 8
    # ST2のビット3が1ならオーバーフローのため、このデータは使わない
    return false if (data.getbyte(7) & 0x08) != 0

    # 地磁気は下位バイトが先に届くため、リトルエンディアンで変換する
    @raw_magnet_x = int16_le(data.getbyte(0), data.getbyte(1))
    @raw_magnet_y = int16_le(data.getbyte(2), data.getbyte(3))
    @raw_magnet_z = int16_le(data.getbyte(4), data.getbyte(5))
    # 地磁気の感度：0.15 µT/LSB
    @magnet_x_ut = @raw_magnet_x * 0.15
    @magnet_y_ut = @raw_magnet_y * 0.15
    @magnet_z_ut = @raw_magnet_z * 0.15
    true
  end

  # 指定レジスターから1バイト取得する (読み取り失敗時はnil)
  def read_u8(address, register)
    data = @i2c.read(address, 1, register)
    return nil if data.nil? || data.length < 1

    data.getbyte(0)
  end

  # 上位・下位バイトを結合し、2の補数の符号付き16ビット整数へ変換する
  def int16_be(msb, lsb)
    value = (msb << 8) | lsb
    value >= 0x8000 ? value - 0x10000 : value
  end

  # 下位・上位の順で受け取ったバイトを、符号付き16ビット整数へ変換する
  def int16_le(lsb, msb)
    value = (msb << 8) | lsb
    value >= 0x8000 ? value - 0x10000 : value
  end
end

=begin
# 使用例：I2C接続したIMUから各軸の値を読み取る
i2c = I2C.new
imu = IMU9DOF.new(i2c)

loop do
  if imu.read
    # 加速度 (g単位)
    puts "Accel: X=#{imu.accel_x_g}, Y=#{imu.accel_y_g}, Z=#{imu.accel_z_g} g"
    # 角速度 (度/秒)
    puts "Gyro: X=#{imu.gyro_x_dps}, Y=#{imu.gyro_y_dps}, Z=#{imu.gyro_z_dps} dps"
    # 地磁気 (µT単位、新しいデータがない場合は前回の値)
    puts "Magnet: X=#{imu.magnet_x_ut}, Y=#{imu.magnet_y_ut}, Z=#{imu.magnet_z_ut} µT"
    # 温度 (℃)
    puts "Temperature: #{imu.temperature_c} ℃"
  else
    puts "IMU read failed"
  end
  sleep 0.1
end
=end
