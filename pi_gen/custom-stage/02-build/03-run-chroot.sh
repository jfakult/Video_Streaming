#!/bin/bash

# URL of the release tar.gz file
url="https://github.com/bluenviron/mediamtx/releases/download/v1.2.0/mediamtx_v1.2.0_linux_armv7.tar.gz"

# Temporary directory to store the downloaded tar.gz file
temp_dir=$(mktemp -d)

# Name of the tar.gz file
file_name=$(basename "$url")

# Download the tar.gz file
wget "$url" -O "$temp_dir/$file_name"

# Extract the mediamtx binary
tar -xzvf "$temp_dir/$file_name" -C "$temp_dir" 


# Commenting out a few steps so i can get a binary file out!
# Move the mediamtx binary to /usr/local/bin/
mv "$temp_dir/mediamtx" /usr/local/bin/

# Set execute permission
chmod +x /usr/local/bin/mediamtx

# Clean up the temporary directory
rm -r "$temp_dir"
