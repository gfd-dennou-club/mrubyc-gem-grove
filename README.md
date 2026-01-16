# mrubyc-gem-grove

GROVE 規格の周辺機器用の mruby/c クラスライブラリ．

## 利用方法

### GPIO 

GROVE コネクタには端子が 4 つあるが，回路としては SIG ピンで GPIO 信号を扱うように作られている． GROVE コネクタをジャンパケーブルへ変換するケーブルを用いて，黒ケーブル (GND) を GND 端子に，赤ケーブル (VCC) を 3.3 V 端子に， 黄色ケーブル (SIG) を適当な空いている GPIO 端子に接続すればよい． 

| 外観(リンク) | 機器名 | 動作方法 | ライブラリ |
| :---: | :--- | :--- | :--- |
| <a href="https://www.seeedstudio.com/Grove-LED-Pack-p-4364.html"><img src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/g/r/grove-led-pack-all-2.jpg" width=200></a>  | **LED** | [GPIO (OUT), PWM](../../wiki/GPIO_LED) | <a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Mini-Fan-v1-1.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedimg2016-06fplau7uf59lnoad5nqpjwxor.jpg"></a>| **miniファン** | [GPIO (OUT), PWM](../../wiki/GPIO_miniFan) |<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Relay.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-07bazaar881127_3.jpg"></a> | **リレー** | [GPIO (OUT)](../../wiki/GPIO_relay) |<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Button.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/p/e/perspectiive.jpg"></a>  | **タクトスイッチ** | [GPIO (IN)](../../wiki/GPIO_button)|<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-PIR-Motion-Sensor.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-07bazaar881121_3.jpg"></a>  | **モーションセンサ** | [GPIO (IN)](../../wiki/GPIO_pirMotion) |<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Touch-Sensor.html"> <img width="200" alt="image" src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-07bazaar881144_3.jpg" /> </a> | **タッチセンサー** | [GPIO (IN)](../../wiki/GPIO_TouchSensorV1.2)|<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |

### PWM

GROVE コネクタには端子が 4 つあるが，回路としては SIG ピンで PWM 信号を扱うように作られている．
GROVE コネクタをジャンパケーブルへ変換するケーブルを用いて，黒ケーブル (GND) を GND 端子に，赤ケーブル (VCC) を 3.3 V 端子に， 黄色ケーブル (SIG) を適当な空いている GPIO 端子に接続すればよい．


| 外観(リンク) | 機器名 | 動作方法 | ライブラリ |
| :---: | :--- | :--- | :--- |
| <a href="https://www.seeedstudio.com/Grove-LED-Pack-p-4364.html"><img src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/g/r/grove-led-pack-all-2.jpg" width=200></a>  | **LED** | [GPIO (OUT), PWM](../../wiki/GPIO_LED) |<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Mini-Fan-v1-1.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedimg2016-06fplau7uf59lnoad5nqpjwxor.jpg"></a>| **miniファン** | [GPIO (OUT), PWM](../../wiki/GPIO_miniFan) |<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Buzzer.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-08bazaar897328_1.jpg"></a>  | **ブザー** | [PWM](../../wiki/PWM_buzzer) |<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Servo.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedimg2016-06rjmxymiq9lqxkkxxwg6udxfm.jpg"></a>  | **サーボモータ** | [PWM](../../wiki/PWM_servoMotor)|<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |


### ADC 

GROVE コネクタには端子が 4 つあるが，回路としては SIG ピンで ADC 信号を扱うように作られている．
GROVE コネクタをジャンパケーブルへ変換するケーブルを用いて，黒ケーブル (GND) を GND 端子に，赤ケーブル (VCC) を 3.3 V 端子に， 黄色ケーブル (SIG) を適当な空いている GPIO 端子に接続すればよい．


| 外観(リンク) | 機器名 | 動作方法 | ライブラリ |
| :---: | :--- | :--- | :--- |
| <a href="https://www.seeedstudio.com/Grove-Rotary-Angle-Sensor.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-07bazaar881159_2.jpg"></a> | **回転角速度センサ** | [ADC](../../wiki/ADC_rotaryAngleSensor) |<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Sound-Sensor-Based-on-LM358-amplifier-Arduino-Compatible.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedimg2017-02fhpnt4qmmyzrtwvb40liimrw.jpg"></a> | **サウンドセンサ** | [ADC](../../wiki/ADC_soundSensor)|<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-Light-Sensor-v1-2-LS06-S-phototransistor.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedimg2016-10po8b7qd0xnlnchgogziq9g3d.jpg"></a>| **ライトセンサ** | [ADC](../../wiki/ADC_lightSensor) |<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://wiki.seeedstudio.com/ja/Grove-Temperature_Sensor_V1.2/"><img width=200 src="https://files.seeedstudio.com/wiki/Grove-Temperature_Sensor_V1.2/img/Grove_Temperature_Sensor_View.jpg"></a>| **温度センサ** | [ADC](../../wiki/ADC_TemperatureSensorV1.2)|<a href="https://github.com/mruby/microcontroller-peripheral-interface-guide">共通 I/O API ガイドライン</a> |
| <a href="https://www.seeedstudio.com/Grove-ADC-for-Load-Cell-HX711-p-4361.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/g/r/grove-adc-for-load-cell-hx711-preveiw.jpg"></a>  | **ロードセル(重量センサ)用ADC** | [HX711](../../wiki/ADC_LoadCell_HX711) |<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/hx711.rb">hx711.rb</a>|


### I2C

センサー系は基本的に以下のプログラム構造となるようメソッドを統一している
```ruby
i2c = I2C.new
sensor = SENSOR.new( i2c, options )
loop do
  sensor.read              #値の読み込み
  puts sensor.temperature  #温度の出力
  sleep 10                 #待ち
end
```

| 外観(リンク) | 機器名 | 動作方法 | クラスライブラリ |
| :---: | :--- | :--- | :--- |
|<a href="https://docs.m5stack.com/ja/unit/envII"><img width=200 src="https://static-cdn.m5stack.com/resource/docs/products/unit/envII/envII_02.webp"></a>| **UNIT ENV-II (温度・湿度・気圧)** | 温度・湿度 → [SHT30](../../wiki/I2C_SHT30) <br> 気圧 → [BMP280](../../wiki/I2C_BMP280) |<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/sht30.rb">sht30.rb</a><br><a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/bmp280.rb">bmp280.rb</a>|
|<a href="https://docs.m5stack.com/ja/unit/Unit_ENV-IV"><img width=200 src="https://static-cdn.m5stack.com/resource/docs/products/unit/ENV%E2%85%A3%20Unit/img-949651d3-241e-46c6-a355-833e97cecdb2.webp"></a>| **UNIT ENV-IV (温度・湿度・気圧)** |   温度・湿度 →[SHT40](../../wiki/I2C_SHT40) <br> 気圧 → [BMP280](../../wiki/I2C_BMP280) |<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/sht40.rb">sht40.rb</a><br><a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/bmp280.rb">bmp280.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-Gas-Sensor-BME688-p-5478.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/1/1/114992989-45-font.jpg"></a>| **IAQ(室内空気質)・温度・湿度・気圧)** |  [BME688](../../wiki/I2C_BME688)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/bme688.rb">bmpe688.rb</a>|
| | **気圧・温度** |  [BMP581](../../wiki/I2C_BMP581)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/bme581.rb">bmpe688.rb</a>|
|<a href="ttps://www.seeedstudio.com/Grove-CO2-Temperature-Humidity-Sensor-SCD41-p-5025.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/1/0/101020952_preview-07-min.png"></a>| **温度・湿度・CO2** | [SCD41](../../wiki/I2C_SCD41)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/scd41.rb">scd41.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-CO2-Temperature-Humidity-Sensor-SCD30-p-2911.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/p/r/preview_1_1.png"></a>| **温度・湿度・CO2** | [SCD30](../../wiki/I2C_SCD30)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/scd30.rb">scd30.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-I2C-High-Accuracy-Temp-Humi-Sensor-SHT35.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-10bazaar951701_11400x1050.jpg"></a>| **温度・湿度** |  [SHT35](../../wiki/I2C_SHT35) |<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/sht35.rb">sht35.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-I2C-High-Accuracy-Temperature-Sensor-MCP9808.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-08bazaar896473_img_0079a.jpg"></a>| **温度** |  [MCP9808](../../wiki/I2C_MCP9808) |<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/mcp9808.rb">mcp9808.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-High-Precision-Barometer-Sensor-DPS310-p-4397.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/g/r/grove-high-precision-barometer-sensor-dps310-preview.jpg"></a>| **気圧・温度** |  [DPS310](../../wiki/I2C_DPS310)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/dps310.rb">dps310.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-I2C-UV-Sensor-VEML6070.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-10bazaar969238_perspective.jpg"></a>| **紫外線** |  [VEML6070](../../wiki/I2C_VEML6070)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/veml6070.rb">veml6070.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-Light-Color-Proximity-Sensor-TMG39931-p-2879.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/p/e/perspective_3_4.jpg"></a>| **照度・カラー** |  [TMG39931](../../wiki/I2C_TMG39931)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/tmg39931.rb">tmg39931.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-12-bit-Magnetic-Rotary-Position-Sensor-AS5600-p-4192.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/g/r/grove-12-bit-magnetic-rotary-sensor-as5600-preview.jpg"></a>| **磁気式エンコーダ** | [AS5600](../../wiki/I2C_AS5600)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/as5600.rb">as5600.rb</a>|
|<a href="https://docs.m5stack.com/ja/unit/TOF"><img width=200 src="https://static-cdn.m5stack.com/resource/docs/products/unit/TOF/img-b7d05799-9772-4e4b-a8ef-8398360f57f1.webp"></a>| **距離 (Unit ToF)** |  [VL53L0X](../../wiki/I2C_VL53L0X)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/vl53l0x.rb">vl53l0x.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-3-Axis-Digital-Accelerometer-16g.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedimg2016-11gspzr5xrvqzue5sh4zoms1de.jpg"></a>| **3軸加速度** | [ADXL345](../../wiki/I2C_ADXL345)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/adxl345.rb">adxl345.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-12-Key-Capacitive-I2C-Touch-Sensor-V3-MPR121-p-4694.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/1/0/101020872_touch-sensor-v3.png"></a>| **タッチセンサ** | [MPR121](../../wiki/I2C_MPR121)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/mpr121.rb">mpr121.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-Step-Counter-BMA456.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-10bazaar962676_perspective.jpg"></a>| **ステップカウンター** |  [BMA456](../../wiki/I2C_BMA456)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/bma456.rb">bma456.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-16x2-LCD-White-on-Blue.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedfile2018-10bazaar969249_front.jpg"></a>| **16x2 LCD (White on Blue)** | [AQM0802A](../../wiki/I2C_AQM0802A)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/aqm0802a.rb">aqm0802a.rb</a>|
|<a href="https://www.seeedstudio.com/Grove-High-Precision-RTC.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comseeedimg2016-111gtdoessvtk0i3pa5jbxostb.jpg"></a>| **高精度リアルタイムクロック** | [PCF85063](../../wiki/I2C_PCF85063)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/pcf85063.rb">pcf85063.rb</a>|
|<a href="https://shop.m5stack.com/products/rfid-unit-2-ws1850s"><img width=200 src="https://shop.m5stack.com/cdn/shop/products/7_e26d64b1-70c0-4c86-a29f-650499c426a7_1200x1200.jpg?v=1635500588"></a>| **RFID** |[WS1850S](../../wiki/I2C_WS1850S)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/ws1850s.rb">ws1850s.rb</a>|

### その他

| 外観(リンク) | 機器名 | 動作方法 | ライブラリ |
| :---: | :--- | :--- | :--- |
| <a href="https://www.seeedstudio.com/Grove-RGB-LED-WS2813-Mini-p-4269.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/g/r/grove-rgb---led-ws2813-mini-wiki.jpg"></a>| **RGB LED** | [WS2813](../../wiki/LED_WS2813) |<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/ws2813.rb">ws2813.rb</a>|
| <a href="https://www.seeedstudio.com/Grove-Circular-LED.html"><img width=200 src="https://media-cdn.seeedstudio.com/media/catalog/product/cache/bb49d3ec4ee05b6f018e93f896b8a25d/h/t/httpsstatics3.seeedstudio.comimagesproductgrove20circular20led.jpg"></a>| **円形 LED** | [MY9221](../../wiki/circularLED_MY9221)|<a href="https://github.com/gfd-dennou-club/mrubyc-gem-grove/blob/main/src/my9221.rb">my9221.rb</a>|

## 補遺

これまでに作成してきた以下のリポジトリ・wiki 情報を統合し，かつ，[共通 I/O API ガイドライン](https://github.com/mruby/microcontroller-peripheral-interface-guide) に準拠しました．
+ https://github.com/gfd-dennou-club/mrubyc-esp32/wiki/sample_grovekit
+ https://github.com/gfd-dennou-club/mrubyc-esp32/wiki/sample_pirMotion
+ https://github.com/gfd-dennou-club/mrubyc-esp32/wiki/Sample_kanirobo
+ https://github.com/gfd-dennou-club/mrubyc-gem-sht35
+ https://github.com/gfd-dennou-club/mrubyc-gem-aqm0802a
+ https://github.com/gfd-dennou-club/mrubyc-gem-tmg39931
+ https://github.com/gfd-dennou-club/mrubyc-gem-scd30
+ https://github.com/gfd-dennou-club/mrubyc-gem-vl53l0x
+ https://github.com/gfd-dennou-club/mrubyc-gem-mcp9808
+ https://github.com/gfd-dennou-club/mrubyc-gem-veml6070
+ https://github.com/gfd-dennou-club/mrubyc-gem-bmp280
+ https://github.com/gfd-dennou-club/mrubyc-gem-sht3x
