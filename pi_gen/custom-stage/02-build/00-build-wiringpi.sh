#!/bin/bash -e
mkdir -p /usr/local/src
cd /usr/local/src
git clone https://github.com/WiringPi/WiringPi
cd WiringPi
echo "Starting build of WiringPi..."
./build
echo "Build of WiringPi completed."
