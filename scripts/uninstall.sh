#!/bin/bash
# Uninstall ENOS BSP (LoRa-only for now)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== ENOS BSP Uninstall (LoRa-only) ==="
bash "$SCRIPT_DIR/uninstall-lora.sh"
echo ""
echo "=== Uninstall complete ==="
echo "Reboot to apply: sudo reboot"
