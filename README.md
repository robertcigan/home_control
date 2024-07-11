# Home Control

Home Control is a Ruby on Rails based home automation DIY style system. It's targeted towards hobby tinkerer with a basic programming skills to write your own programs to control your devices. It uses Arduino on the HW side and supports currently AT Mega 2560 boards over ethernet,  ESP8266 and ESP32 boards over WiFi connection and ModBus TCP (read only).

## Stack

The app runs Ruby on Rails Puma server that also runs a Websocket server. Websockets are used to update values on the page without reloading or polling.
The main thread that does the "automation" and communication with devices is based on Ruby Event Machine and runs separately from the server. MySQL is used as a database. You can run the app on any Linux machine like Ubuntu 20/22, Raspbian on Raspberry Pi 3B and newer. I suggest Raspberry 4 with 2GB of memory or more. 

## How it works

Essentially you setup a board ( Arduino Mega/ ESP or TCP Modbus) and then add devices that are attached on that board with pin assigment or other settings. When you do that, the configuration is sent over to that board. The only initial configuration in boards that must be done is a network setup (via USB serial terminal).You can have many devices like sensors or relays or similar attached to one board, the only limitation is number of pins that is available on each board. That's why I mostly use Arduino Mega. 

Once you have the HW setup with boards and devices configured, you can setup programs. Programs are a pieces of ruby code that is run when something happens like a temperature changes, button is pressed etc. Pograms can also be initiated periodically. Programs are written in Ruby and are evaluated on the object `Program` level, which is not a safe practice, but the idea is that you should be the only one having access to the admin part of the app anyway.

To be able to easily control and monitor your entire setup, you can create a panel. Panels are dashboards where you can assemble each dasboard individually and add sections to show values, add buttons or switches to be able to control and monitor your devices.

## Supported Boards

Server communicates with boards via TCP connection using easy to read and understand JSON format. It does not use encryption of any kind and should be only used over secured network without public access. Both the server and boards verify and accept connection only from the opposite side based on checking the IP address.

### Arduino Mega 2560 with Ethernet Module W5100/5200/W5500
TODO

### ESP01 (ESP8266)
TODO

### ESP32
TODO

### Modbus TCP (read only)
TODO

## Supported Devices

### Button

`Digital Input` 
Scans for a signal change and reports to the server when the button was pressed. Server stores the latest time of the button press. 

### Switch

`Digital Input`
Scans for a signal change and reports to the server when theres any change HI -> LOW or LOW -> HI. 

### Distance
[Ultrasonic distance sensor](https://projecthub.arduino.cc/Isaac100/getting-started-with-the-hc-sr04-ultrasonic-sensor-7cabe1) 

Check peridically the distance and reports it to the server when changed. Distance value is in centimeters. Configuration pin is a trigger pin, echo pin is automatically used following one. If you set a Pin to ie. 10, then connect trigger pin  of the module to 10 and echo pin to 11. 

### DS18B20 temperature sensor

Periodically checks the temperature and repors it to the server when changed. Value is in Celsius degree.

### Analog input
`Analog Input`

Checks for a analog value and reports it when changed to the server. The measurement unit is V. Do not allow to pass more than the board Vcc to the anaglo input voltage, otherwise the board chip may be destroed. Use only analg input pins. To measure voltage on a pin A4, enter 4 as a pin number. 

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

#### Reset devices

`{ reset_devices: true }`

Clears/removes all the device settings from the board. Used before uploading a new set of devices with `add` command.

#### Add device

`{ 
  add:
  {
    type: "switch"
    pin: "30"
    id: "5"
  }
}`

Adds a device with a specific configuration. 

#### Ping

`{ ping: "true" }`

Pings a device to maintain a connection and expects the `pong` reponse. If the server does not receives a reponse within 25 seconds, it will consider the board to be offline.

## Board specific pins

#### Arduino Mega (2560)

10 - used by ethernet module
18,19 - Serial1 (MP3 Player module)
A0 - A15 assignable analog pins
