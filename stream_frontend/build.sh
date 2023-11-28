#!/bin/bash

#EDIT AS NEEDED

npm run build && \
cp -r dist/spa/* /usr/share/nginx/html/stream/
#cp -r dist/spa/* /usr/share/nginx/html/wildstream/
