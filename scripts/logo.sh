#!/bin/sh
pkill -f gst-launch-1.0
gst-launch-1.0 multifilesrc location=/home/pi/Video_Streaming/wildstream-240px.png loop=true caps="image/png,framerate=1/1" ! pngdec ! videoconvert ! fbdevsink

