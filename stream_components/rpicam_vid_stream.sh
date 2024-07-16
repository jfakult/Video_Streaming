#!/bin/bash

pkill -f libcamera-vid
pkill -f gst-launch

echo "Starting libcamera stream"
libcamera-vid --width 1920 --height 1080 --codec h264 --level 4.2 --bitrate 5000000 --intra 30 --framerate 30 --inline 1 --flush 1 --timeout 0 --nopreview 1 --inline --listen -o udp://0.0.0.0:5000
#libcamera-vid --width 1920 --height 1080 --codec h264 --level 4.2 --bitrate 2000000 --intra 120 --framerate 30 --inline 1 --flush 1 --timeout 0 --nopreview 1 --output -
#libcamera-vid --width 1920 --height 1080 --codec h264 --level 4.2 --bitrate 4000000 --framerate 30 --inline 1 --flush 1 --timeout 0 --nopreview 1 --output /tmp/video_output.h264
