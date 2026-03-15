#!/bin/bash
# Install only ENOS LoRa SPI path using the known-working dtparam flow
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

cp "$UDEV_RULES_SRC" "$UDEV_RULES_DST"
if command -v udevadm &>/dev/null; then
    udevadm control --reload-rules
    udevadm trigger --subsystem-match=spidev || true
fi
echo "  Installed udev aliases: /dev/lora-rx and /dev/lora-tx"

# Known-good baseline on Pi4/Pi5 for exposing /dev/spidev0.0 and /dev/spidev0.1
# is stock SPI enable with dtparam=spi=on.
if ! grep -q '^dtparam=spi=on$' "$CONFIG_FILE"; then
    echo "# ENOS LORA — Ensure SPI core enabled" >> "$CONFIG_FILE"
    echo "dtparam=spi=on" >> "$CONFIG_FILE"
    echo "  Added: dtparam=spi=on"
else
    echo "  Already present: dtparam=spi=on"
fi

# Keep SPI core enabled for compatibility on Pi4/Pi5 images where SPI node
# is not active unless dtparam=spi=on is present.
# Disable the custom overlay line if present from newer experiments.
sed -i '/# ENOS LORA — Explicit SPI0 mapping (CS0=GPIO8 RX, CS1=GPIO7 TX)/d' "$CONFIG_FILE"
sed -i '/^dtoverlay=enos-lora$/d' "$CONFIG_FILE"

echo "=== LoRa install complete ==="
