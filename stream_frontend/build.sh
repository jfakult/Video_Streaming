#!/bin/bash

mkdir -p /usr/share/nginx/html

rm -rf /usr/share/nginx/html/*

npm run build && \
cp -r dist/spa/* /usr/share/nginx/html/
#cp -r dist/spa/* /usr/share/nginx/html/wildstream/

chown pi:pi /usr/share/nginx/html -R
