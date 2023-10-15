# Overview

### This Repository contains the following:

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