# Morse Micro 8108
Compiling instructions for kernel, MM8108 driver and patches with CM5 or RPi5

## Phase 1: Prepare the Build Environment
First, update your system and install the tools required to build the Linux kernel.
```
sudo apt update && sudo apt upgrade -y
sudo apt install -y git bc build-essential libncurses5-dev bison flex libssl-dev libelf-dev
```

## Phase 2: Get the Patched Kernel Source
Morse Micro maintains a fork of the Raspberry Pi Linux kernel that already includes the necessary mac80211 patches for HaLow support. This is much easier than manually patching the official kernel.
1. Clone the Morse Micro Kernel Fork: You need the branch specifically for kernel 6.6 (rpi-6.6.y). Note: This download is large (over 1GB).
```
mkdir -p ~/morse-build
cd ~/morse-build
git clone --depth 1 --branch rpi-6.6.y https://github.com/MorseMicro/rpi-linux.git linux
```

2. Prepare the Kernel Configuration: Use your current running configuration as a base to ensure all your CM5 hardware works.
```
cd linux
# Load the default configuration for Pi 5 / CM5 (bcm2712)
KERNEL=kernel_2712
make bcm2712_defconfig
```

Tip: If you want to customize anything (optional), run make menuconfig now.

### Enable generic S1G support in the Wi-Fi stack
./scripts/config --enable CONFIG_IEEE80211_S1G
./scripts/config --enable CONFIG_MAC80211_S1G

## Phase 3: Compile and Install the New Kernel
Now you must build the kernel. This process replaces your standard kernel with the one capable of supporting the MM8108.

1. Build the Kernel, Modules, and Device Tree: The -j$(nproc) flag tells the compiler to use all CPU cores to speed this up.
```
make -j$(nproc) Image.gz modules dtbs
```

2. Install the Modules:
```
sudo make modules_install
```

3. Install the Kernel and Device Tree Blobs: Backup your old kernel and copy the new one to the boot partition.
```
sudo cp arch/arm64/boot/dts/broadcom/*.dtb /boot/firmware/
sudo cp arch/arm64/boot/dts/overlays/*.dtbo* /boot/firmware/overlays/
sudo cp arch/arm64/boot/Image.gz /boot/firmware/kernel_2712.img
```

(Note: On Pi 5/CM5, the 64-bit kernel image is usually named kernel_2712.img in /boot/firmware/. If your system uses a different naming convention, check /boot/firmware/config.txt to confirm).

4. Reboot: Reboot to load your newly compiled kernel.
```
sudo reboot
```

5. Verify Kernel Version: After rebooting, check that you are running your custom kernel (the date should match today):
```
uname -a
```

## Phase 4: Compile the MM8108 Driver
Now that you have the patched kernel running, you can build the actual driver.
1. Clone the Driver Source:
```
cd ~/morse-build
git clone https://github.com/MorseMicro/morse_driver.git
cd morse_driver
```

2. Compile the Driver: You must point the build to your kernel source directory.
```
make KERNEL_SRC=~/morse-build/linux
```

If successful, this will create morse.ko and mac80211.ko (or similar modules) in the directory.
3. Install the Driver Modules:

```
sudo make KERNEL_SRC=~/morse-build/linux modules_install
sudo depmod -a
```

## Phase 5: Install Firmware
The driver needs binary firmware to operate the chip.
1. Clone the Firmware Repo:
```
cd ~/morse-build
git clone https://github.com/MorseMicro/morse-firmware.git
```

2. Copy Firmware to System Path:
```
sudo mkdir -p /lib/firmware/morse
sudo cp morse-firmware/firmware/mm8108*.bin /lib/firmware/morse/
```

Note: Check the morse_driver readme or dmesg logs if it complains about a specific missing filename (e.g., mm8108-bd.bin), and rename/copy the closest matching firmware file from the repo if necessary.

## Phase 6: Load and Test
Load the Module:
```
sudo modprobe morse
```

2. Check dmesg: Look for success messages or errors.
```
dmesg | grep morse
```

3. Verify Network Interface: You should now see a new wireless interface (often wlan1 or similar).
```
ip link show
```

### Troubleshooting Common CM5 Issues
Missing mac80211 symbols: If modprobe fails complaining about "unknown symbols", it means you are likely still booted into the stock kernel, not your patched one. Ensure uname -a shows your custom build date.

Firmware Missing: If dmesg says "failed to load firmware", check the exact filename it is looking for and ensure that exact name exists in /lib/firmware/morse/.

Would you like me to explain how to configure the hostapd (Access Point mode) for this driver once you have it loaded?
