# Installing Talos Linux on Raspberry Pi 5

## Prerequisites

1. Raspberry Pi 5
2. microSD card (16GB minimum, 32GB+ recommended)
3. [Raspberry Pi Imager](https://www.raspberrypi.com/software/) or similar tool
4. Network access to the Pi

## Steps

### 1. Download Talos Image

Download the ARM64 image for Raspberry Pi:

```bash
curl -LO https://github.com/siderolabs/talos/releases/download/v1.8.0/metal-arm64.raw.xz
```

### 2. Flash the Image

#### Using Raspberry Pi Imager

1. Open Raspberry Pi Imager
2. Choose "Use custom" for OS
3. Select the downloaded `metal-arm64.raw.xz` file
4. Select your microSD card
5. Click "Write"

#### Using dd (macOS/Linux)

```bash
# Extract the image
xz -d metal-arm64.raw.xz

# Find your SD card device
diskutil list  # macOS
# or
lsblk          # Linux

# Flash the image (replace /dev/diskX with your SD card)
sudo dd if=metal-arm64.raw of=/dev/diskX bs=4M status=progress
sync
```

### 3. Boot the Raspberry Pi

1. Insert the microSD card into the Raspberry Pi 5
2. Connect network cable
3. Power on the device
4. Wait for it to boot (should get DHCP address initially)

### 4. Find the Node

If you don't know the IP yet:

```bash
# Scan your network
talosctl discover
```

Or use your router's admin interface to find the device.

### 5. Apply Initial Configuration

Once you know the IP, proceed with the main setup:

```bash
# Generate config with the actual node IP
make generate-config

# Apply configuration
make apply-config

# Bootstrap cluster
make bootstrap

# Get kubeconfig
make kubeconfig
```

## Troubleshooting

### Pi doesn't boot

- Ensure you flashed the correct ARM64 image
- Check the power supply (Pi 5 requires a good 5V/5A supply)
- Try reflashing the SD card

### Can't connect to the node

- Verify network connectivity
- Check if the node got a DHCP address initially
- Try using the serial console

### Installation fails

- Ensure `/dev/mmcblk0` is the correct device (check in patch.yaml)
- Verify SD card is working properly
- Check Talos logs: `talosctl --nodes <IP> logs`

## Notes

- The initial boot uses DHCP, then switches to static IP after configuration is applied
- Make sure your network allows the static IP 172.21.7.100
- The Pi 5 requires the ARM64 variant of Talos
