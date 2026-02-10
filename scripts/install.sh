#!/bin/bash
# Install ENOS BSP onto Raspberry Pi 5
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BSP_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$BSP_DIR/build"

BOOT_DIR="/boot/firmware"
OVERLAY_DIR="$BOOT_DIR/overlays"
CONFIG_FILE="$BOOT_DIR/config.txt"

echo "=== ENOS BSP Install ==="

# Must be root
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)"
    exit 1
fi

# Check build artifacts exist
if [[ ! -f "$BUILD_DIR/enos-can.dtbo" ]]; then
    echo "ERROR: enos-can.dtbo not found. Run build.sh first."
    exit 1
fi

# 1. Copy overlay
echo "Installing overlay to $OVERLAY_DIR..."
cp "$BUILD_DIR/enos-can.dtbo" "$OVERLAY_DIR/enos-can.dtbo"

# 2. Update config.txt
echo "Updating $CONFIG_FILE..."

# Add dtparam=spi=on if not already present
if ! grep -q "^dtparam=spi=on" "$CONFIG_FILE"; then
    echo "" >> "$CONFIG_FILE"
    echo "# ENOS BSP — Enable SPI0 for LoRa modules" >> "$CONFIG_FILE"
    echo "dtparam=spi=on" >> "$CONFIG_FILE"
    echo "  Added: dtparam=spi=on"
else
    echo "  Already present: dtparam=spi=on"
fi

# Add enos-can overlay if not already present
if ! grep -q "^dtoverlay=enos-can" "$CONFIG_FILE"; then
    echo "# ENOS BSP — MCP2518FD CAN on SPI0 CS2" >> "$CONFIG_FILE"
    echo "dtoverlay=enos-can" >> "$CONFIG_FILE"
    echo "  Added: dtoverlay=enos-can"
else
    echo "  Already present: dtoverlay=enos-can"
fi

# 3. Install CAN network config
echo "Installing CAN network config..."
cp "$BSP_DIR/config/can0.network" /etc/systemd/network/80-can0.network
systemctl enable systemd-networkd 2>/dev/null || true

# 4. Ensure can-utils is available
if ! command -v candump &>/dev/null; then
    echo "Installing can-utils..."
    apt-get install -y can-utils
fi

echo ""
echo "=== Install complete ==="
echo "Reboot to apply: sudo reboot"
echo ""
echo "After reboot, verify with: $(dirname "$0")/verify.sh"
