#!/bin/bash

echo "04-chroot - GRABBING LATEST NODEJS"
# Grab a newer LTS version of node, apt keeps 12.x
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=16
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt-get install nodejs -y

# Prepare necessary nginx folders
mkdir -p /usr/share/nginx/html
chown -R pi:pi /usr/share/nginx/html

echo "04-chroot - DOWNLOADING GIT REPO"
cd /home/pi

git clone git@github.com:jfakult/Video_Streaming.git
chown -R pi:pi Video_Streaming

echo "04-chroot - INSTALLING FRONTEND DEPENDENCIES"
cd Video_Streaming/stream_frontend
sudo -u pi npm install
#npm install -g @quasar/cli

echo "04-chroot - RUNNING BOOTSTRAP"
cd /home/pi/Video_Streaming/scripts
./bootstrap.sh
