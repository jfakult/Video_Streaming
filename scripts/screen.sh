#!/bin/sh

pkill -f mediamtx
pkill -f  rtspss
pkill -g gst-launch
gst-launch-1.0 -v libcamerasrc ! videoconvert ! videoscale ! "video/x-raw,width=320,height=240" ! videoconvert ! fbdevsink