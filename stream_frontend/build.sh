#!/bin/bash

npm run build && \
cp -r dist/spa/* /usr/share/nginx/html/stream/
