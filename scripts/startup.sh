#!/bin/bash
touch /tmp/hello
BASE="/home/pi/Video_Streaming"

rfkill unblock all

# Startup python backend and websockets
cd $BASE/backend
python server.py 

