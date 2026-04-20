# Morse Micro Wi-Fi HaLow Driver 8108 Integration Guide (RPi5 CM5)
This guide details how to build the Morse Micro Wi-Fi HaLow driver "in-tree" for the Raspberry Pi Compute Module 5 (BCM2712).

* Distro: Debian 12
* Target Hardware: Raspberry Pi 5 / CM5
* Target Device: USB Wi-Fi HaLow Adapter (Morse Micro MM8108)
* Kernel Branch: mm/rpi-6.6.31/1.15.x

## 1. Install Prerequisites
Update your system and install the required build tools.
```
sudo apt update && sudo apt upgrade
sudo apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev
```
This repository provides support for the Morse Micro MM8108 Wi-Fi HaLow module on the Raspberry Pi 5 and Compute Module 5 (CM5).

## 2. Installation

The kernel and firmware installation is now managed using a YAML-based install tool. This ensures the correct driver versions and Board Configuration Files (BCFs) are deployed.

To install the kernel and the specific Morse Micro firmware defined in the configuration:

1. Clone this repository:
   ```bash
   git clone https://github.com/bsantunes/MM8108_RPi5_CM5.git
   cd MM8108_RPi5_CM5/
   ansible-playbook  build_morse_8108.yml
