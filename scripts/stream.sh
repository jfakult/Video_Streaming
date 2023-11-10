#!/bin/sh

pkill -f gst-launch
pkill -f mediamtx
pkill -f  rtspss
sh ~/Video_Streaming/scripts/logo.sh &
mediamtx ~/Video_Streaming/mediamtx.yml &