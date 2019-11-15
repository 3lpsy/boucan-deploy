#!/bin/bash

set -e;
export DEBIAN_FRONTEND=noninteractive;

echo "Provisioning: BDNS Download - Start"
echo "Provisioning: BDNS Download - Cloning Boucan to /opt/boucan"


sudo git clone https://github.com/3lpsy/boucan-compose.git /opt/boucan/boucan-compose;
cd /opt/boucan/boucan-compose;
sudo REPO_BASE_URL=https://github.com/3lpsy ./setup.sh;

echo "Provisioning: BDNS Download - Complete"