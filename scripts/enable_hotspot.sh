#!/bin/bash

BASE="/home/pi/Video_Streaming"

cp $BASE/config/dhcpcd_hotspot.conf /etc/dhcpcd
cp $BASE/config/10_interface_hotspot.conf /etc/network/interfaces.d/
#rm /etc/wpa_supplicant/wpa_supplicant.conf

mkdir -p /etc/hostapd
cp $BASE/config/hostapd.conf /etc/hostapd/hostapd.conf
cp $BASE/config/hostapd_default.conf /etc/default/hostapd.conf

systemctl start hostapd
systemctl disable wpa_supplicant
