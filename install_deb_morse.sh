#!/bin/bash
set -e

# Create a working directory
WORKDIR="MM"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Download .deb packages
echo "Downloading Morse Micro packages..."
curl -L https://github.com/bsantunes/MM6108_RPi5_CM5/raw/refs/heads/main/mm-hostapd_1.12.4-1.deb -o mm-hostapd_1.12.4-1.deb
curl -L https://github.com/bsantunes/MM6108_RPi5_CM5/raw/refs/heads/main/mm-wpa-supp_1.12.4-1.deb -o mm-wpa-supp_1.12.4-1.deb
curl -L https://github.com/bsantunes/MM6108_RPi5_CM5/raw/refs/heads/main/mm-morsecli_1.12.4-1.deb -o mm-morsecli_1.12.4-1.deb

# Install all .deb packages
echo "Installing dependencies"
sudo apt install libnl-3-dev libnl-genl-3-dev libnl-route-3-dev -y 

echo "Installing packages..."
sudo dpkg -i mm-hostapd_1.12.4-1.deb
sudo dpkg -i mm-wpa-supp_1.12.4-1.deb
sudo dpkg -i mm-morsecli_1.12.4-1.deb

echo "Installation complete."
echo "Reboot the device"
