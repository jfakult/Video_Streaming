#!/bin/sh

echo "Killing old streaming services"
#pkill -f libcamera
#pkill -f rpicam

bitrate=$1
keyframe_interval=$2
width=$3
height=$4
fps=$5

echo "Starting rpicam-vid"
echo bitrate: $bitrate, keyframe interval: $keyframe_interval, width: $width, height: $height, fps: $fps
rpicam-vid --width $3 --height $4 --bitrate $bitrate --intra $keyframe_interval \
    --autofocus-mode continuous \
    --codec yuv420 --profile main --denoise cdn_fast \
    --libav-video-codec-opts "preset=ultrafast;profile=high;tune=zerolatency" --flush 1 \
    --no-raw 1 --framerate $fps --timeout 0 \
    --nopreview --inline --listen -o udp://0.0.0.0:5000

#  --codec h264 --level 4.2
