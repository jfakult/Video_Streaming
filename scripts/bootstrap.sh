#!/bin/bash

echo "ENTERING BOOTSTRAP.sh"

BASE="/home/pi/Video_Streaming"

sudo -u pi echo "export PATH=\"/home/pi/Video_Streaming/scripts:$PATH\"" >> ~/.bashrc
source ~/.bashrc

cp $BASE/config/nginx.conf /etc/nginx
cp $BASE/config/dnsmasq.conf /etc/dnsmasq.conf
cp $BASE/config/startup_camera.service /lib/systemd/system
cp $BASE/config/10_interface_hotspot.conf /etc/network/interfaces.d/
cp $BASE/config/20_interface_wifi.conf /etc/network/interfaces.d/

systemctl daemon-reload && \
systemctl enable startup_camera.service && \
systemctl enable nginx && \
systemctl enable dnsmasq && \
systemctl unmask hostapd && \

$BASE/scripts/enable_hotspot.sh

# Make sure to rebuild the latest frontend source
cd $BASE/stream_frontend
sudo -u pi ./build.sh
