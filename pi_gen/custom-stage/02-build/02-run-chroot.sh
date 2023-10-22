#!/bin/bash -e
# This cleans up the boot config files

#remove any auto detect lines
sed -i '/camera_auto_detect/d' /boot/config.txt

#disable camera autodetect and add overlays for both the camera ande display
echo 'camera_auto_detect=0' >> /boot.config.txt
echo 'dtoverlay=imx708'>> /boot.config.txt
echo 'dtoverlay=gc9a01' >> /boot.config.txt
echo 'dtparam=spi=on' >> /boot.config.txt