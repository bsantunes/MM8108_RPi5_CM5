# Morse Micro Wi-Fi HaLow Driver 8108 Integration Guide (RPi5 CM5)
This guide details how to build the Morse Micro Wi-Fi HaLow driver "in-tree" for the Raspberry Pi Compute Module 5 (BCM2712).

Target Hardware: Raspberry Pi 5 / CM5 Target Device: USB Wi-Fi HaLow Adapter (Morse Micro MM8108) Kernel Branch: mm/rpi-6.6.31/1.15.x

## 1. Install Prerequisites
Update your system and install the required build tools.
```
sudo apt update
sudo apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev
```
## 2. Clone the Kernel and Driver
We must use the specific Morse Micro branch that contains the required S1G (Sub-1 GHz) stack patches.

### A. Clone the Kernel
```
# Clone the specific Morse Micro branch (approx. 300MB)
git clone --depth 1 -b mm/rpi-6.6.31/1.15.x https://github.com/MorseMicro/rpi-linux.git linux-morse

cd linux-morse
```
### B. Setup the Driver Directory
We will manually construct the driver directory inside the kernel tree to ensure all submodules are present.
```
# 1. Create the destination folder
mkdir -p drivers/net/wireless/morse

# 2. Clone the main driver source
# (Assuming you are still inside linux-morse/)
git clone https://github.com/MorseMicro/morse_driver.git temp_driver
cp -r temp_driver/* drivers/net/wireless/morse/
rm -rf temp_driver
```
## 3. Patch the Source Code
The current driver version has minor type mismatches (enum vs uint) that cause newer compilers (GCC 12+) to fail. Apply these patches to fix them.

```
# Fix 1: Type mismatch in debug.c
sed -i 's/enum morse_feature_id id/u32 id/' drivers/net/wireless/morse/debug.c

# Fix 2: Type mismatch in firmware.c
sed -i 's/enum morse_config_test_mode test_mode/uint test_mode/' drivers/net/wireless/morse/firmware.c
```
## 4. Register the Driver in Kernel Build System
We need to tell the kernel build system that the new driver exists.

### A. Edit drivers/net/wireless/Kconfig
Add the source line before the endmenu tag.

```
# Append the config source to the wireless Kconfig
sed -i '/endmenu/i source "drivers/net/wireless/morse/Kconfig"' drivers/net/wireless/Kconfig
```

### B. Edit drivers/net/wireless/Makefile
Add the object build instruction to the end of the file.

```
echo "obj-\$(CONFIG_WLAN_VENDOR_MORSE) += morse/" >> drivers/net/wireless/Makefile
```

## 5. Configure the Kernel (CM5 + S1G)
We will load the default Raspberry Pi 5 configuration and then forcefully enable the Wi-Fi HaLow features.

```
# 1. Clean and load CM5 defaults (bcm2712)
make mrproper
KERNEL=kernel_2712
make bcm2712_defconfig

# 2. Enable the Morse Micro Driver
./scripts/config --enable CONFIG_WLAN_VENDOR_MORSE
./scripts/config --set-str CONFIG_MORSE_COUNTRY "EU"  # Change to "US" or "JP" if needed

# 3. Update the configuration file
make olddefconfig
```
Verification: Run this to confirm the settings stuck:

```
grep -E "MORSE" .config
```
Output should show CONFIG_WLAN_VENDOR_MORSE=y (or m).

## 6. Build the Kernel
Compile the kernel image, modules, and device trees. This takes 10-20 minutes on a Pi 5.

```
make -j$(nproc) Image.gz modules dtbs
```
## 7. Install Kernel and Firmware
### A. Install Modules
```
sudo make modules_install
```
### B. Install Kernel Image & DTBs
We install the kernel as kernel_morse.img to avoid overwriting the stock kernel immediately.

```
# Install Kernel Image
sudo cp arch/arm64/boot/Image.gz /boot/firmware/kernel_morse.img

# Install Device Tree Blobs (DTBs)
sudo cp arch/arm64/boot/dts/broadcom/*.dtb /boot/firmware/
sudo cp arch/arm64/boot/dts/overlays/*.dtbo* /boot/firmware/overlays/
```

### C. Install Firmware (CRITICAL STEP)
The driver will register but fail to start the interface if these files are missing.

```
# Create firmware directory
sudo mkdir -p /lib/firmware/morse

# Copy firmware files from the driver source
sudo cp drivers/net/wireless/morse/firmware/*.bin /lib/firmware/morse/
```

## 8. Configure Boot and Reboot
Tell the Pi to boot your new kernel.

1. Open the config file:

```
sudo nano /boot/firmware/config.txt
```

2. Add or modify the kernel line under [all]:

```
[all]
kernel=kernel_morse.img
```
3. Reboot:

```
sudo reboot
```
## 9. Verification
After rebooting, verify the driver is working.

1. Check Kernel Version:

```
uname -r
# Should show the new version (e.g., 6.6.31-v8-16k+)
```
2. Check Driver Load:

```
dmesg | grep -i morse
# Should see "Morse Micro Dot11ah driver registration"
```

3. Check Interface:

```
ip link
# Look for a new interface (e.g., wlan1, wlan2)
```

4. Scan for Networks (Test):

```
sudo iw dev wlan1 scan | grep SSID
```
