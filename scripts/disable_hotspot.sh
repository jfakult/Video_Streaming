#!/bin/bash

BASE="/home/pi/Video_Streaming"

cp $BASE/config/dhcpcd_wifi.conf /etc/dhcpcd
rm /etc/network/interfaces.d/10_interface_hotspot.conf

rm /etc/hostapd.conf
rm /etc/default/hostapd.conf

systemctl enable wpa_supplicant

cp $BASE/config/wpa_supplicant_default.conf /etc/wpa_supplicant/wpa_supplicant.conf

systemctl stop hostapd
