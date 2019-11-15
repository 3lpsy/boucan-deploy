#!/bin/bash

set -e;
export DEBIAN_FRONTEND=noninteractive;

echo "Provisioning: BDNS Download - Start"
echo "Provisioning: BDNS Download - Cloning Boucan to /opt/boucan"

sudo git clone https://github.com/3lpsy/boucan.git /opt/boucan

echo "Provisioning: BDNS Download - Complete"