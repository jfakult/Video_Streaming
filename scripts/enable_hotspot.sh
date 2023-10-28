#!/bin/bash

BASE="~/VideoStreaming/"

cp $BASE/config/dhcpcd_hotspot.conf /etc/dhcpcd
cp $BASE/config/10_interface_hotspot.conf /etc/network/interfaces.d/
sudo rm /etc/wpa_supplicant/wpa_supplicant.conf

systemctl start hostapd
