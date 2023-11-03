#!/bin/bash

BASE="/home/pi/Video_Streaming/"

sudo -u pi echo "export PATH=\"/home/pi/Video_Streaming/scripts:$PATH\"" >> ~/.bashrc
source ~/.bashrc

cp $BASE/config/nginx.conf /etc/nginx
cp $BASE/config/dnsmasq.conf /etc/dnsmasq.conf
cp $BASE/config/startup_camera.service /lib/systemd/system
cp $BASE/config/10_interface_hotspot.conf /etc/network/interfaces.d/
cp $BASE/config/20_interface_wifi.conf /etc/network/interfaces.d/

./$BASE/scripts/enable_hotspot.sh

systemctl daemon-reload && \
systemctl enable startup_camera.service && \
systemctl enable nginx && \
systemctl enable dnsmasq && \
systemctl enable hostapd && \
