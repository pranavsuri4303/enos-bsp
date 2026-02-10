#!/bin/bash
# Build ENOS device tree overlay
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BSP_DIR="$(dirname "$SCRIPT_DIR")"
DTS_DIR="$BSP_DIR/dts"
BUILD_DIR="$BSP_DIR/build"

mkdir -p "$BUILD_DIR"

echo "=== ENOS BSP Build ==="

# Check for device tree compiler
if ! command -v dtc &>/dev/null; then
    echo "ERROR: dtc (device tree compiler) not found"
    echo "Install with: sudo apt install device-tree-compiler"
    exit 1
fi

# Compile overlay
echo "Compiling enos-can.dts..."
dtc -@ -I dts -O dtb -W no-unit_address_vs_reg \
    -o "$BUILD_DIR/enos-can.dtbo" \
    "$DTS_DIR/enos-can.dts"

echo "Output: $BUILD_DIR/enos-can.dtbo"
echo "=== Build complete ==="
