# Diagram

![An image of what's happening here](software_diagram.png)

# Overview

### This Repository contains the following:

- a diagram (["software_diagram.png"](https://github.com/jfakult/Video_Streaming/blob/main/software_diagram.png)), also found in [FigmaJam](https://www.figma.com/file/fGmlJz6MOEMSTQu3Qgcmxb/ATLS-5240-Brainstroming?type=whiteboard&node-id=120-571&t=0YDS4JY2bHAS9YUE-0)
- a frontend (vuejs + quasarjs)
- a backend (python + websockets)
- some configs (nginx, dnsmasq)

# Installing

Install nginx, dnsmasq, npm, python3

    npm install
    pip install websockets

Add the .conf files to their correct places

(haven't tested this but the deps are that complicated here)

# Running

    systemctl restart nginx

    # (may have to "systemctl stop systemd-resolved && pkill -f systemd-resolved")
    # lsof -i:53 to check for services bound to DNS
    systemctl restart dnsmask

    cd backend && python server.py

    # Then

    cd stream_frontend && ./build.sh

# How it works (roughly)

See diagram ["software_diagram.png"](https://github.com/jfakult/Video_Streaming/blob/main/software_diagram.png) for visuals

### DNS

The DNSMASQ service (see config at ./dnsmask.conf) is a DNS server that translates domain names to IP addresses.

In the config file you can see the single relevant command:

    address=/stream.me/127.0.0.1

This tells the web browser that the website "stream.me" should automatically redirect them to 127.0.0.1 (which is the address of the "raspberry pi", though this will change eventually)

### NGINX

This is the "web server" running on the raspberry pi which listens for all incoming requests. (See ./nginx.conf -- specifically the "location" blocks towards the bottom of the file)

It essentially acts as a middleman between the browser and the backend services running on the Pi.

So when the browser goes to stream.me, it will return a webpage for them.

When the joystick controller wants to send position data, it will send it to stream.me/control, and nginx will automatically know to redirect that to the backend.

To pull the video data, it will request "stream.me/live", which nginx will automatically redirect it to the live video feed

### Backend

The backend is a single python script (found in ./backend/server.py). This would be running on the Raspberry Pi

This brings up a server on port 9000 that listens for websocket connections.

The web page (where a viewer is watching the video stream) would send a websocket connection to this backend in order to establish communication (for example to send position commands to the Pi to move the camera).

### Frontend

The frontend is essentially the webpage files that are sent to the viewer.

It contains the video container, joystick, battery icons, etc, and all the logic associated with those.

When loaded it will open a connection to the backend to enable two-way communication