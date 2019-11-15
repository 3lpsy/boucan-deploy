#!/bin/bash

set -e;
export DEBIAN_FRONTEND=noninteractive;


echo "Provisioning: BDNS Build - Start"
echo "Provisioning: BDNS Build - Building Compose Project"

cd /opt/boucan;

echo "Provisioning: BDNS Build - Making /etc/boucan/env"
sudo mkdir -p /etc/boucan/env;
sudo touch /etc/boucan/env/{api,broadcast,db,dns,proxy}.prod.env

echo "Provisioning: BDNS Build - Making /etc/letsencrypt/live/boucan.proxy.docker"

sudo mkdir -p /etc/letsencrypt/live/boucan.proxy.docker;

echo "Provisioning: BDNS Build - Building Compose Project"
sudo /opt/boucan/compose.sh prod build;

echo "Provisioning: BDNS Build - Installing Service File"
sudo cp /opt/boucan/infra/deploy/services/boucan-compose.service /etc/systemd/system/boucan-compose.service;
echo "Provisioning: BDNS Build - Reloading Daemon"
sudo systemctl daemon-reload;

echo "Provisioning: BDNS Build - Complete"