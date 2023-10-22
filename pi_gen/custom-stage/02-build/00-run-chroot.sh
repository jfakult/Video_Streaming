#!/bin/bash -e
mkdir -p /usr/local/src
cd /usr/local/src
git clone https://github.com/WiringPi/WiringPi
cd WiringPi
echo "Starting build of WiringPi..."
echo "Path is $PATH"
export WIRINGPI_SUDO="" && export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games" && ./build
echo "Build of WiringPi completed."
