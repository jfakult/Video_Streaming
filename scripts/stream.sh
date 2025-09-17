#!/bin/sh

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
    --nopreview \
    --output - \
| \
gst-launch-1.0 fdsrc fd=0 ! \
  videoparse width=$width height=$height format=i420 framerate=$fps/1 ! \
  videoscale method=1 ! \
  video/x-raw,width=1920,height=1080 ! \
  x264enc tune=zerolatency bitrate=$bitrate speed-preset=superfast ! \
  rtph264pay config-interval=1 pt=96 ! \
  application/x-rtp,media=video,encoding-name=H264,payload=96 ! \
  webrtcsink run-signalling-server=true run-web-server=true

# udpsink host=127.0.0.1 port=5004 ! \
#\
#gst-launch-1.0 fdsrc ! \
#    videoparse width=$width height=$height format=i420 framerate=$fps/1 ! \
#    videoscale method=1 ! \
#    video/x-raw,width=1920,height=1080 ! \
#    x264enc tune=zerolatency bitrate=$bitrate speed-preset=superfast ! \
#    rtph264pay config-interval=1 pt=96 ! \
#    application/x-rtp,media=video,encoding-name=H264,payload=96 ! \
#    webrtcbin name=sendrecv