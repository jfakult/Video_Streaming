#!/bin/bash

BASE="/home/pi/Video_Streaming"

systemctl start nginx
systemctl start dnsmasq
systemctl start hostapd

# Startup python backend and websockets
cd $BASE/backend
nohup python server.py &

$BASE/logo.sh
