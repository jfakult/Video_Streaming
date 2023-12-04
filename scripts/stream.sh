#!/bin/sh

pkill -f gst-launch-1.0
pkill -f mediamtx
pkill -f  rtspss
sh /home/pi/Video_Streaming/scripts/logo.sh &
mediamtx /home/pi/Video_Streaming/mediamtx.yml > /tmp/mediamtx.log 2>&1 & 
