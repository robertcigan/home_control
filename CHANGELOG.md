# Changelog

[Home Control](README.md) | [How to Install](INSTALL.md) | [Docker build manual](BUILD.md) | [Changelog](CHANGELOG.md)

## Home Control 3.4.1 (2025-01-03)
  * Rails 7.1.5.1
  * Ruby 3.3.6
  * Updated bundle

## Home Control 3.4 (2024-01)
  * Optional widget labels
  * Optional device log
  * Refactorised widgets switch and button interactions with backend

## Home Control 3.3 (2024-01)
  * Widget Type Button added to run assigned program
  * Automatic board and device log clearing after specified set of days (setting per board/device)

## Home Control 3.2 (2024-01)
  * Blinds/Shutter/Curtain implemented (2 pin control) - requires V9 FW version

## Home Control 3.1 (2023-07)
  * Automatic WS device value push for stale devices (> 60s)
  * Fixing ModbusTCP bug crash when connection refused
  * Prevent overlapping EM timers
  * DB indexes tuning

## Home Control 3.0 (2023-01)
  * Rails 7.x
  * Ruby 3.1
  * Updated bundle
  * Fixed missing Last Change update for some device types
  * Added device log compression type "Max Value" - compress logs using maximum value during the selected timeframe

## Home Control 2.5 (2022-07)
  * Button implementation bugfix
  * Widget name override
  * All panels will now be 12x12 by default without an option to change it
  * Updated time in the widget is optional
  * Small UI changes in widgets

## Home Control 2.4 (2022-05)
  * Panel public access option (no password)

## Home Control 2.3 (2022-04)
  * Board connection log improved chart
  * Compression log bugfix
  * PWM device indication bugfix

## Home Control 2.2 (2022-03)
  * Relay inverted option support
  * Programs form and details refactored, UI changes

## Home Control 2.1 (2022-01)
  * Log compression with interval 10 minutes, 1 hour, 1 day

## Home Control 2.0 (2021-12)
  * Added support for ModBus TCP reading holding registers
  * Added Unit for devices to add as a suffix when showing the value (ie. 15V, 200cm etc)
  * Improved device history charts
  * ESP8266 and ESP32 single WiFi config mode only, bug fixes

## Home Control 1.6 (2021-06)
  * Input devices poll time is configured in device settings
  * Button and Switch input logic can be inverted in device settings

## Home Control 1.5 (2021-05)
  * Added support for WiFi capable boards (ESP8266 etc) for signal strength, SSID and board FW version

## Home Control 1.4 (2021-05)
  * Added support for EPS8266 DS18B20 temperature sensor (one sensor per pin)

## Home Control 1.3 (2021-04)
  * Added support for MEGA2560 DS18B20 temperature sensor (one sensor per pin)

## Home Control 1.2 (2021-04)
  * Added board connection log timeline chart in board detail
  * Added devices timeline charts in device detail
  * Default board and device log sorting created_at desc

## Home Control 1.1 (2021-03)
  * Added sorting, searching and pagination
  * Added AnalogInput device - AD converter
  * Do not reset pins on connection, wait for "send_devices" command to reset and send pins configuration
  * Added "send_devices" input command
  * Refactorized ArduinoServer and ArduinoMessenger
  * Handle prolonged commands - parse multiple commands per eventmachine send_data cycle, leave unterminated command buffer for next cycle
  * Max TCP buffer size increased significatnly to handle prolonged data
* Instead of EM stop, reconnect to websockets automatically

## Home Control 1.0 (2021-02)
* Upgraded to Rails 6.x, Bootstrap 4
