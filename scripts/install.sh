#!/bin/bash
# Install ENOS BSP (LoRa-only for now)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== ENOS BSP Install (LoRa-only) ==="
bash "$SCRIPT_DIR/install-lora.sh"
echo ""
echo "=== Install complete ==="
echo "Reboot to apply: sudo reboot"
