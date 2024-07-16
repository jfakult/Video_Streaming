#!/bin/sh

echo "Killing old streaming services"
#pkill -f libcamera
#pkill -f rpicam

bitrate=$1
keyframe_interval=$2

echo "Starting rpicam-vid"
echo $bitrate , $keyframe_interval
rpicam-vid --width 1920 --height 1080 --bitrate $bitrate --intra $keyframe_interval --profile main --denoise cdn_hq --libav-video-codec-opts "preset=ultrafast;profile=high;tune=zerolatency" --flush 1 --no-raw 1 --framerate 40 --timeout 0 --nopreview --inline --listen -o udp://0.0.0.0:5000
#  --codec h264 --level 4.2