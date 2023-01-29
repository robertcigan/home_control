## Home Control 3.0 (2023-01) ##
  * Rails 7.x
  * Ruby 3.1
  * Updated bundle
  * Fixed missing Last Change update for some device types
  * Added device log compression type "Max Value" - compress logs using maximum value during the selected timeframe

## Home Control 2.5 (2022-07) ##
  * Button implementation bugfix
  * Widget name override
  * All panels will now be 12x12 by default without an option to change it
  * Updated time in the widget is optional
  * Small UI changes in widgets

## Home Control 2.4 (2022-05) ##
  * Panel public access option (no password)

## Home Control 2.3 (2022-04) ##
  * Board connection log improved chart
  * Compression log bugfix
  * PWM device indication bugfix

## Home Control 2.2 (2022-03) ##
  * Relay inverted option support
  * Programs form and details refactored, UI changes

## Home Control 2.1 (2022-01) ##
  * Log compression with interval 10 minutes, 1 hour, 1 day

## Home Control 2.0 (2021-12) ##
  * Added support for ModBus TCP reading holding registers
  * Added Unit for devices to add as a suffix when showing the value (ie. 15V, 200cm etc)
  * Improved device history charts
  * ESP8266 and ESP32 single WiFi config mode only, bug fixes

## Home Control 1.6 (2021-06) ##
  * Input devices poll time is configured in device settings
  * Button and Switch input logic can be inverted in device settings

## Home Control 1.5 (2021-05) ##
  * Added support for WiFi capable boards (ESP8266 etc) for signal strength, SSID and board FW version

## Home Control 1.4 (2021-05) ##
  * Added support for EPS8266 DS18B20 temperature sensor (one sensor per pin)

## Home Control 1.3 (2021-04) ##
  * Added support for MEGA2560 DS18B20 temperature sensor (one sensor per pin)

## Home Control 1.2 (2021-04) ##
  * Added board connection log timeline chart in board detail
  * Added devices timeline charts in device detail
  * Default board and device log sorting created_at desc

## Home Control 1.1 (2021-03) ##
  * Added sorting, searching and pagination
  * Added AnalogInput device - AD converter
  * Do not reset pins on connection, wait for "send_devices" command to reset and send pins configuration
  * Added "send_devices" input command
  * Refactorized ArduinoServer and ArduinoMessenger
  * Handle prolonged commands - parse multiple commands per eventmachine send_data cycle, leave unterminated command buffer for next cycle
  * Max TCP buffer size increased significatnly to handle prolonged data
* Instead of EM stop, reconnect to websockets automatically

## Home Control 1.0 (2021-02) ##
* Upgraded to Rails 6.x, Bootstrap 4