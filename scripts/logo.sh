#!/bin/sh
gst-launch-1.0 filesrc location=/home/pi/Video_Streaming/wildstream-240px.png ! pngdec ! videoconvert ! fbdevsink 

