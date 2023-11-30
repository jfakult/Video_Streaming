#!/bin/bash

BASE="/home/pi/Video_Streaming"

rfkill unblock all

# Startup python backend and websockets
cd $BASE/backend
nohup python server.py &

cd $BASE/scripts
nohup ./stream.sh &
nohup ./logo.sh &
