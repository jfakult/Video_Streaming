#!/bin/bash

#cp /etc/nginx/nginx.conf ..
#cp /etc/dnsmasq.conf ..

npx quasar build && \
cp -r dist/spa/* /usr/share/nginx/html/stream/

