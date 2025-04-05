# Home Control 3.4.2

[Home Control](README.md) | [How to Install](INSTALL.md) | [Docker build manual](BUILD.md) | [Changelog](CHANGELOG.md)

Home Control is a Ruby on Rails based home automation DIY style project. It's targeted towards hobby tinkerer with a basic programming skills to write your own programs to control your devices. It uses Arduino on the HW side and supports both Ethernet and WiFI boards. It also supports ModBus TCP.

It's designed to be effective in creating both simple and complex automation processes by directly writing Ruby code. The downside is no support for existing WiFi devices so it's indented for hobbyists with general Arduino and electronics knowledge.

## Stack

The app runs Ruby on Rails on Puma server that also runs a Websocket server. Websockets are used to update values without reloading or polling.
The process that does the "automation" and communication with devices is based on Ruby Event Machine and runs separately from the web server. Database backend is PostgreSQL or MySQL. You can run the app on any Linux machine like Ubuntu 22 and up, Raspbian on Raspberry Pi 3B and newer. I suggest at least Raspberry 4 with 2GB of memory or more.

## How it works

Essentially you setup a board ( Arduino Mega/ ESP or TCP Modbus) and then add devices that are attached on that board with pin assigment or other settings. When you do that, the configuration is sent over to that board. The only initial configuration in boards that must be done is a network setup (via USB serial terminal). You can have multiple devices like sensors or relays attached to one board, the only limitation is number of pins that are available on each board. That's why I mostly use Arduino Mega.

Once you have the HW setup with boards and devices configured, you can create Programs. Programs are a pieces of Ruby code that are run when something happens, like a temperature changes, button is pressed etc. Pograms can also be initiated periodically. Programs are written in Ruby and are evaluated on the object `Program` level, which is not a safe practice, but the idea is that you should be the only one having access to the admin part of the app anyway. The upside is, that you can literally do whatever you want and only your imagination and skills are the limits.

To be able to easily control and monitor your entire setup, you can create a panel. Panels are dashboards where you can create visual controls and add areas to show values, add buttons or switches to be able to control and monitor your devices.

## Supported HW
* [Arduino Mega](#arduino-mega-2560-with-ethernet-module-w51005200w5500)
* [ESP01](#esp01-esp8266)
* [ESP32](#esp32)
* [Modbus TCP](#modbus-tcp)

Server communicates with boards via TCP connection using easy to read and understand JSON format. It does not use encryption of any kind and should be only used over secured network without public access. Both the server and boards verify and accept connection only based on checking the IP address.

Board FW repository is https://github.com/robertcigan/home_control_arduino. Use VS Code Platformio plugin to compile & flash it.

### Arduino Mega 2560 with Ethernet Module W5100/5200/W5500

Arduino Mega does not come with any network connectivity by default so you need to use either a Ethernet Shield or a Ethernet module and wire it to the board. I use external [W5500 Ethernet Module](https://www.google.com/search?q=W5500+Ethernet+Network+Module&oq=W5500+Ethernet+Network+Module&gs_lcrp=EgZjaHJvbWUyCwgAEEUYExg5GIAEMgoIARAAGBMYFhgeMgoIAhAAGIAEGKIEMgoIAxAAGIAEGKIEMgoIBBAAGIAEGKIEMgoIBRAAGIAEGKIEMgYIBhBFGD3SAQczMTdqMGo0qAIAsAIB&sourceid=chrome&ie=UTF-8) and wire to to SPI header. The SPI Select pin is digital pin 10.

__Dedicated Pins__
10 - used by ethernet module
18,19 - Serial1 (MP3 Player module)
A0 - A15 assignable analog pins

### ESP01 (ESP8266)

### ESP32

### Modbus TCP
  Read- and write to registers over ethernet.

## Supported Devices

* [Button](#button)
* [Switch](#switch)
* [Distance Sensor](#distance-sensor)
* [DS18B20](#ds18b20-temperature-sensor)
* [Analog input](#analog-input)
* [Relay](#relay)
* [PWM output](#pwm-output)
* [Sound](#sound)
* [Blids/Shutters/Curtain](#blindsshuttercurtain-type-device)

### Button

`Digital Input`
Scans for a signal change and reports to the server when the button was pressed. Server stores the latest time of the button press.

### Switch

`Digital Input`
Scans for a signal change and reports to the server when theres any change HI -> LOW or LOW -> HI.

### Distance sensor
[Ultrasonic distance sensor](https://projecthub.arduino.cc/Isaac100/getting-started-with-the-hc-sr04-ultrasonic-sensor-7cabe1)

Check peridically the distance and reports it to the server when changed. Distance value is in centimeters. Configuration pin is a trigger pin, echo pin is automatically used following one. If you set a Pin to ie. 10, then connect trigger pin  of the module to 10 and echo pin to 11.

### DS18B20 temperature sensor

Periodically checks the temperature and repors it to the server when changed. Value is in Celsius degree.

### Analog input
`Analog Input`

Checks for a analog value and reports it when changed to the server. The measurement unit is V. Do not allow to pass more than the board Vcc to the analog input voltage, otherwise the board chip may be destroed. Use only analg input pins. To measure voltage on a pin A4, enter 4 as a pin number.

### Relay
`Digital Output`

This is a output device only that is controlled using LOW or HI state of the output pin.

### PWM output
`Analog Output`

Ouput a PWM signal on the PWM capable pins. The ouput value is 0-100% and the PWM frequency is the default frequency of the used board.

### Sound
`Serial1`

Playing MP3 files via UART controlled MP3 player module with SD card. Works with modules like (this)[https://www.aliexpress.com/i/32782440758.html]

Uses hardcoded Serial1 class to send commands to the player so connect it to Serial1 pins accordingly.

### Blinds/Shutter/Curtain type device
`Digital Output`

Controlling via custom Arduino Nano module with 2 relays that then control blinds/shutters/curtain where you can only allow power on one or the other signal wire. Requires you to use custom Arduino board with 2 relay module. Open pin is connected to the pin set in the device configuration and close pin is set to the following one.

## Communication protocol

Commands:

__Reset devices__

`{ reset_devices: true }`

Clears/removes all the device settings from the board. Used before uploading a new set of devices with `add` command.

__Add device__

`{
  add:
  {
    type: "switch"
    pin: "30"
    id: "5"
  }
}`

Adds a device with a specific configuration.

__Ping__

`{ ping: "true" }`

Pings a device to maintain a connection and expects the `pong` reponse. If the server does not receives a reponse within 25 seconds, it will consider the board to be offline.

## Installation

Follow [this link](/robertcigan/home_control_arduino) for how to flash and setup the board.

## Contributing

I encourage you to contribute to Home Control project. As I use this project personally, I intend to support it and continue developing new features and maintaining existing ones for a long time.

## License

Home Control is released under the [MIT License](https://opensource.org/licenses/MIT).
