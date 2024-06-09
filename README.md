# Home Control

Home Control is a Ruby on Rails based home automation DIY style system. It's targeted towards hobby tinkerer with a basic programming skills to write your own programs to control your devices. It uses Arduino on the HW side and supports currently AT Mega 2560 boards over ethernet,  ESP8266 and ESP32 boards over WiFi connection and ModBus TCP (read only).

## Stack

The app runs Ruby on Rails Puma server that also runs a Websocket server. Websockets are used to update values on the page without reloading or polling.
The main thread that does the "automation" and communication with devices is based on Ruby Event Machine and runs separately from the server. MySQL is used as a database. You can run the app on any Linux machine like Ubuntu 20/22, Raspbian on Raspberry Pi 3B and newer. I suggest Raspberry 4 with 2GB of memory or more. 

## How it works

Essentially you setup a board ( Arduino Mega/ ESP or TCP Modbus) and then add devices that are attached on that board with pin assigment or other settings. When you do that, the configuration is sent over to that board. THe only initial configuration in boards that must be done is a network setup (via USB serial terminal).You can have many devices like sensors or relays or similar attached to one board, the only limitation is number of pins that is available on each board. That's why I mostly use Arduino Mega. 

Once you have the HW setup with boards and devices configured, you can setup programs. Programs are a literally a pieces of code that is run when something happens like a temperature changes, button is pressed etc. Pograms can also be initiated periodically. Programs are written in Ruby and are evaluated on the program level, which is not a safe practice, but the ideais you should be the only one having access to the admin part of the app anyway. 

To be able to easily control and monitor your entire setup, you can create a panel. Panels are dashboards where you can assemble each dasboard individually and add sections to show values, add buttons or switches to be able to control your devices.

## Supported Boards

Server communicates with boards via TCP connection using easy to read/understand JSON forma. It does not use encryption of any kind and should be only used over secured network without public access. 

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

digital input

### Switch
digital input

### Distance
[Ultrasonic distance sensor](https://projecthub.arduino.cc/Isaac100/getting-started-with-the-hc-sr04-ultrasonic-sensor-7cabe1) 

### DS18B20 temperature sensor

### Analog input
Measuring voltage on analog input pins

### Relay
digital output

### PWM output
PWM output on PWM capable pins

### Sound
Playing MP3 files via UART controlled MP3 player module with SD card. Works with modules like (this)[https://www.aliexpress.com/i/32782440758.html]

### Blinds/Shutter/Curtain type device
Controlling via custom Arduino Nano module with 2 relays

## Communication protocol




Arduino protocol:
PC -> ARDUINO

Commands:
reset_devices: true

add:
  type: "switch" | "button"
  pin: 30
  id: 5

  
ARDUINO 
IP: prod/dev
server ip:  192, 168, 0, 2 /  192, 168, 0, 102
client ip: 192, 168, 0, 60+ / 192, 168, 0, 200+

Pins:

10 - Ethernet control
18,19 - Serial1 (sound module)

A0 - A15 assignable analog pins
