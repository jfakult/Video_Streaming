#!/bin/sh
gst-launch-1.0 filesrc location=/home/pi/wildstream-240px.png ! pngdec ! videoconvert ! fbdevsink 

