#!/bin/bash
# Install only ENOS LoRa SPI path using explicit overlay
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BSP_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$BSP_DIR/build"
UDEV_RULES_SRC="$BSP_DIR/config/99-enos-lora.rules"
source "$SCRIPT_DIR/common.sh"

UDEV_RULES_DST="/etc/udev/rules.d/99-enos-lora.rules"

echo "=== ENOS LoRa Install ==="

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)"
    exit 1
fi

detect_boot_layout
echo "  Target: $(print_model)"
echo "  Config: $CONFIG_FILE"

if [[ ! -f "$BUILD_DIR/enos-lora.dtbo" ]]; then
    echo "ERROR: enos-lora.dtbo not found. Run build.sh first."
    exit 1
fi

cp "$BUILD_DIR/enos-lora.dtbo" "$OVERLAY_DIR/enos-lora.dtbo"
echo "  Installed overlay: $OVERLAY_DIR/enos-lora.dtbo"

cp "$UDEV_RULES_SRC" "$UDEV_RULES_DST"
if command -v udevadm &>/dev/null; then
    udevadm control --reload-rules
    udevadm trigger --subsystem-match=spidev || true
fi
echo "  Installed udev aliases: /dev/lora-rx and /dev/lora-tx"

if ! grep -q "^dtoverlay=enos-lora" "$CONFIG_FILE"; then
    echo "" >> "$CONFIG_FILE"
    echo "# ENOS LORA — Explicit SPI0 mapping (CS0=GPIO8 RX, CS1=GPIO7 TX)" >> "$CONFIG_FILE"
    echo "dtoverlay=enos-lora" >> "$CONFIG_FILE"
    echo "  Added: dtoverlay=enos-lora"
else
    echo "  Already present: dtoverlay=enos-lora"
fi

# Cleanup old ENOS-managed dtparam setup if present.
sed -i '/# ENOS LORA — Enable SPI0 userspace nodes/d' "$CONFIG_FILE"
if grep -q '^dtparam=spi=on$' "$CONFIG_FILE"; then
    echo "  NOTE: Existing dtparam=spi=on left as-is (harmless with explicit overlay)"
fi

echo "=== LoRa install complete ==="
