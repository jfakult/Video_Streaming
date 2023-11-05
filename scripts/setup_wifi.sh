#!/bin/bash

echo "Enter credentials to connect to a local WiFi network"

BASE="/home/pi/Video_Streaming"

# Prompt for SSID and password
read -p "Enter SSID: " SSID
read -p "Enter Password: " PASSWORD

# Write to wpa_supplicant.conf
{
    echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev"
    echo "update_config=1"

    echo "network={"
    echo "    ssid=\"$SSID\""
    echo "    psk=\"$PASSWORD\""
    echo "}"
} >> /etc/wpa_supplicant/wpa_supplicant.conf

$BASE/scripts/disable_hotspot.sh

# Provide feedback to the user
echo "WiFi settings saved. You might want to restart your network or device for changes to take effect."
