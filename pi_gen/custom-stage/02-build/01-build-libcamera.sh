#!/bin/bash -e
# This builds a version that has the gstreamer capabilities built in because we have the libgstreamer-plugins-base1.0-dev package installed

cd /usr/local/src
git clone https://git.libcamera.org/libcamera/libcamera.git
cd libcamera
meson build
ninja -C build
ninja -C build install

cd src/gstreamer
meson build
ninja -C build
sudo ninja -C build install
