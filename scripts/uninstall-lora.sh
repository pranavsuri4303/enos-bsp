#!/bin/bash
# Uninstall only ENOS LoRa SPI overlay path
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

UDEV_RULES_DST="/etc/udev/rules.d/99-enos-lora.rules"

echo "=== ENOS LoRa Uninstall ==="

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)"
    exit 1
fi

detect_boot_layout
echo "  Target: $(print_model)"
echo "  Config: $CONFIG_FILE"

if [[ -f "$OVERLAY_DIR/enos-lora.dtbo" ]]; then
    rm "$OVERLAY_DIR/enos-lora.dtbo"
    echo "  Removed: $OVERLAY_DIR/enos-lora.dtbo"
fi

if [[ -f "$UDEV_RULES_DST" ]]; then
    rm "$UDEV_RULES_DST"
    if command -v udevadm &>/dev/null; then
        udevadm control --reload-rules
        udevadm trigger --subsystem-match=spidev || true
    fi
    echo "  Removed udev aliases: /dev/lora-rx and /dev/lora-tx"
fi

if [[ -f "$CONFIG_FILE" ]]; then
    sed -i '/# ENOS LORA — Explicit SPI0 mapping (CS0=GPIO8 RX, CS1=GPIO7 TX)/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=enos-lora$/d' "$CONFIG_FILE"

    # Legacy cleanup from earlier LoRa-only install style.
    sed -i '/# ENOS LORA — Enable SPI0 userspace nodes/d' "$CONFIG_FILE"
    echo "  Removed ENOS-managed LoRa entries from $CONFIG_FILE"
fi

echo "=== LoRa uninstall complete ==="
