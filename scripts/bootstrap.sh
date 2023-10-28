#!/bin/bash

BASE="~/VideoStreaming/"

echo "export PATH=\"/home/pi/Video_Streaming/scripts:$PATH\"" >> ~/.bashrc
source ~/.bashrc

cp $BASE/config/nginx.conf /etc/nginx
cp $BASE/config/dnsmasq.conf /etc/dnsmasq.conf
cp $BASE/config/startup_camera.service /lib/systemd/system
mkdir -p /etc/hostapd
cp $BASE/config/hostapd.conf /etc/hostapd.conf
cp $BASE/config/hostapd_default.conf /etc/default/hostapd.conf
cp $BASE/config/10_interface_hotspot.conf /etc/network/interfaces.d/
cp $BASE/config/20_interface_wifi.conf /etc/network/interfaces.d/

./$BASE/scriptsl/enable_hotspot.sh

systemctl daemon-reload && systemctl enable startup_camera.service
