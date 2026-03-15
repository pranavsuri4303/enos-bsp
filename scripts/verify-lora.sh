#!/bin/bash
# Verify only LoRa SPI path after boot
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

FAIL=0

check() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" >/dev/null 2>&1; then
        echo "  PASS: $desc"
    else
        echo "  FAIL: $desc"
        FAIL=1
    fi
}

echo "[LoRa Verify]"
if ! detect_boot_layout; then
    exit 1
fi
echo "  Target: $(print_model)"
echo "  Config: $CONFIG_FILE"
check "enos-lora overlay configured" "grep -q '^dtoverlay=enos-lora' '$CONFIG_FILE'"
check "enos-lora.dtbo installed" "test -e \"$OVERLAY_DIR/enos-lora.dtbo\""
check "spidev0.0 exists" "test -e /dev/spidev0.0"
check "spidev0.1 exists" "test -e /dev/spidev0.1"
check "lora-rx alias exists" "test -e /dev/lora-rx"
check "lora-tx alias exists" "test -e /dev/lora-tx"

if [[ $FAIL -eq 0 ]]; then
    echo "  Result: PASS"
else
    echo "  Result: FAIL"
    if [[ ! -e /dev/spidev0.0 && -e /dev/spidev0.1 ]]; then
        echo "  Hint: only CS1 is active. Check for conflicting SPI overlays in config.txt"
        grep -nE '^dtoverlay=spi0|^dtoverlay=.*spi|^dtparam=spi|^dtoverlay=enos-lora' "$CONFIG_FILE" || true
    fi
fi

exit $FAIL
