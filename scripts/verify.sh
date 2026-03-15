#!/bin/bash
# Verify ENOS BSP state (LoRa-only for now)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== ENOS BSP Verification (LoRa-only) ==="
echo ""

bash "$SCRIPT_DIR/verify-lora.sh"
echo ""
echo "=== Verification complete ==="