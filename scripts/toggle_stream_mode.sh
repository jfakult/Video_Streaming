#!/bin/bash

BASE="/home/pi/Video_Streaming"

# If mediamtx is currently running, then run screen.sh, else run stream
media_process=$(ps aux | grep mediamtx | grep -v "grep")

if [ -n "$media_process" ]
then
    echo "Switching to screen mode"
    $BASE/scripts/screen.sh
else
    echo "Switching to stream mode"
    $BASE/scripts/stream.sh
fi
