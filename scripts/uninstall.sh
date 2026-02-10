#!/bin/bash
# Uninstall ENOS BSP from Raspberry Pi 5
set -euo pipefail

BOOT_DIR="/boot/firmware"
OVERLAY_DIR="$BOOT_DIR/overlays"
CONFIG_FILE="$BOOT_DIR/config.txt"

echo "=== ENOS BSP Uninstall ==="

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)"
    exit 1
fi

# Remove overlay
if [[ -f "$OVERLAY_DIR/enos-can.dtbo" ]]; then
    rm "$OVERLAY_DIR/enos-can.dtbo"
    echo "Removed: $OVERLAY_DIR/enos-can.dtbo"
fi

# Remove config.txt entries
if [[ -f "$CONFIG_FILE" ]]; then
    sed -i '/# ENOS BSP/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=enos-can/d' "$CONFIG_FILE"
    # Only remove spi=on if we added it (don't remove if user had it before)
    echo "Removed ENOS entries from $CONFIG_FILE"
    echo "NOTE: dtparam=spi=on left in place — remove manually if not needed"
fi

# Remove CAN network config
if [[ -f /etc/systemd/network/80-can0.network ]]; then
    rm /etc/systemd/network/80-can0.network
    echo "Removed: CAN network config"
fi

echo ""
echo "=== Uninstall complete ==="
echo "Reboot to apply: sudo reboot"
