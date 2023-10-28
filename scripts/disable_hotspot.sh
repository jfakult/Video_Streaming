#!/bin/bash

BASE="~/VideoStreaming/"

cp $BASE/config/dhcpcd_wifi.conf /etc/dhcpcd
rm /etc/network/interfaces.d/10_interface_hotspot.conf

cp $BASE/config/wpa_suppicant_default.conf /etc/wpa_supplicant/wpa_supplicant.conf

systemctl stop hostapd
