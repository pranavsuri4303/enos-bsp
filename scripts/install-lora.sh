#!/bin/bash
# Install ENOS LoRa overlay (overlay-only SPI0 config)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BSP_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$BSP_DIR/build"
UDEV_RULES_SRC="$BSP_DIR/config/99-enos-lora.rules"
UDEV_RULES_DST="/etc/udev/rules.d/99-enos-lora.rules"
source "$SCRIPT_DIR/common.sh"

DTS_NAME="enos-lora"
DTBO_SRC="$BUILD_DIR/$DTS_NAME.dtbo"

echo "=== ENOS LoRa Install ==="

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)"
    exit 1
fi

if ! detect_boot_layout; then
    exit 1
fi

echo "  Target: $(print_model)"
echo "  Config: $CONFIG_FILE"

# Ensure overlay is built
if [[ ! -f "$DTBO_SRC" ]]; then
    echo "  Overlay $DTBO_SRC not found, building..."
    bash "$SCRIPT_DIR/build.sh"
fi

if [[ ! -f "$DTBO_SRC" ]]; then
    echo "ERROR: Overlay $DTBO_SRC not found after build"
    exit 1
fi

mkdir -p "$OVERLAY_DIR"
cp "$DTBO_SRC" "$OVERLAY_DIR/$DTS_NAME.dtbo"
echo "  Installed overlay: $OVERLAY_DIR/$DTS_NAME.dtbo"

# Ensure dtoverlay=enos-lora is present for overlay-only SPI0 configuration
if ! grep -q '^dtoverlay=enos-lora$' "$CONFIG_FILE"; then
    echo "# ENOS LORA \\u2014 Explicit SPI0 mapping (CS0=GPIO8 RX, CS1=GPIO7 TX)" >> "$CONFIG_FILE"
    echo "dtoverlay=enos-lora" >> "$CONFIG_FILE"
    echo "  Added: dtoverlay=enos-lora"
else
    echo "  Already present: dtoverlay=enos-lora"
fi

# Install stable LoRa udev aliases
cp "$UDEV_RULES_SRC" "$UDEV_RULES_DST"
if command -v udevadm &>/dev/null; then
    udevadm control --reload-rules
    udevadm trigger --subsystem-match=spidev || true
fi
echo "  Installed udev aliases: /dev/lora-rx and /dev/lora-tx"

echo "=== LoRa install complete ==="
