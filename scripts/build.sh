#!/bin/bash
# Build ENOS overlays from dts/*.dts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BSP_DIR="$(dirname "$SCRIPT_DIR")"
DTS_DIR="$BSP_DIR/dts"
BUILD_DIR="$BSP_DIR/build"

mkdir -p "$BUILD_DIR"

echo "=== ENOS BSP Build ==="

if ! command -v dtc &>/dev/null; then
    echo "ERROR: dtc (device tree compiler) not found"
    echo "Install with: sudo apt install device-tree-compiler"
    exit 1
fi

shopt -s nullglob
dts_files=("$DTS_DIR"/*.dts)
if [[ ${#dts_files[@]} -eq 0 ]]; then
    echo "ERROR: No .dts files found in $DTS_DIR"
    exit 1
fi

for dts_file in "${dts_files[@]}"; do
    base_name="$(basename "$dts_file" .dts)"
    out_file="$BUILD_DIR/$base_name.dtbo"
    echo "Compiling $(basename "$dts_file")..."
    dtc -@ -I dts -O dtb -W no-unit_address_vs_reg \
        -o "$out_file" \
        "$dts_file"
    echo "  Output: $out_file"
done

echo "=== Build complete ==="
