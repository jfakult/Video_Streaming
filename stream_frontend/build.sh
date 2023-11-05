#!/bin/bash

#cp /etc/nginx/nginx.conf ..
#cp /etc/dnsmasq.conf ..

npm run build && \
cp -r dist/spa/* /usr/share/nginx/html/stream/

