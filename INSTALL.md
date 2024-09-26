# Home Control install manual

[Home Control](README.md) | [How to Install](INSTALL.md) | [Docker build manual](BUILD.md) | [Changelog](CHANGELOG.md)

## Raspberry Pi 5

This is tested on installing on RPi 5 with latest 64bit Raspbian. You can install the app to older versions with 32 bit Raspbian with architecture armv7 and also to x86/amd64 architecture. Docker setup and installing the app will be very much the same. Docker image is build for linux/arm64, linux/arm and linux/amd64 platforms as described in [BUILD.md](BUILD.md)

### Prepare Raspbian instance with docker
1. Visit https://www.raspberrypi.com/software/ and install Raspbian or Ubuntu on the RPi. Best use SSD instead of SD card for longevity and reliability.
2. Setup your network on the Rpi with a static IP address. 
3. Install docker, best with the convenience script as described here https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
  `curl -fsSL https://get.docker.com -o get-docker.sh`
  `sudo sh ./get-docker.sh`
4. Run post-install commands to allow running docker as a non-root user.
https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user 
5. Configure docker to start on boot
https://docs.docker.com/engine/install/linux-postinstall/#configure-docker-to-start-on-boot-with-systemd

### Install and run  Home Control app

1. Create new folder in your home directory
  `mkdir home_control`
2. Download docker-compose.yml and .env file
  Rename .env.example to .env
  `wget https://raw.githubusercontent.com/robertcigan/home_control/refs/heads/master/docker-compose.yml`
  `wget https://raw.githubusercontent.com/robertcigan/home_control/refs/heads/master/.env.example`
  `mv .env.example .env`

3. Configure enviroment variables in .env file.
    * set IP address to your RPi static IP address.
    * choose port that the app will be running on (default 7080)
    * set username/password for admin access
    * change the secret key base to something else (best some random string)
4. Open terminal, change the current directory to the   app directory and run docker composer. This command will download HomeControl image, Redis and PostgreSQL images from Docker Hub and start all of them. 
  `cd ~/home_control`
  `docker compose up`

5. Access http://192.168.0.100:7080 (use whatever IP and port is set in the .env file) and verify the app is up and running.
  
6. CTRL+C and run the app in the background.
  `docker compose start`

7. Docker container is automatically set to be running after server start. Test that by rebooting the server.
  `sudo reboot`