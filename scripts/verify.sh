
#!/bin/bash
# Verify ENOS BSP loaded correctly after reboot
set -uo pipefail

PASS=0
FAIL=0
WARN=0

check() {
    local desc="$1"
    local cmd="$2"
    local result
    result=$(eval "$cmd" 2>/dev/null)
    if [[ -n "$result" ]]; then
        echo "  ✓ $desc"
        ((PASS++))
        return 0
    else
        echo "  ✗ $desc"
        ((FAIL++))
        return 1
    fi
}

warn() {
    local desc="$1"
    echo "  ⚠ $desc"
    ((WARN++))
}

echo "=== ENOS BSP Verification ==="
echo ""

# --- SPI Bus ---
echo "[SPI0 Bus]"
check "SPI0 enabled in config" "grep -q '^dtparam=spi=on' /boot/firmware/config.txt && echo yes"
check "LoRa #1: /dev/spidev0.0 exists" "ls /dev/spidev0.0"
check "LoRa #2: /dev/spidev0.1 exists" "ls /dev/spidev0.1"
echo ""

# --- CAN Controller ---
echo "[MCP2518FD CAN]"
check "enos-can overlay in config" "grep -q '^dtoverlay=enos-can' /boot/firmware/config.txt && echo yes"
check "enos-can.dtbo installed" "ls /boot/firmware/overlays/enos-can.dtbo"
check "can0 interface exists" "ls /sys/class/net/can0"
check "mcp251xfd driver loaded" "dmesg | grep -i 'mcp251xfd.*spi' | head -1"
echo ""

# --- SPI Errors ---
echo "[SPI Health]"
SPI_ERRORS=$(dmesg | grep -i 'spi.*error\|spi.*fail\|spi.*timeout' 2>/dev/null)
if [[ -z "$SPI_ERRORS" ]]; then
    echo "  ✓ No SPI errors in dmesg"
    ((PASS++))
else
    echo "  ✗ SPI errors detected:"
    echo "$SPI_ERRORS" | sed 's/^/      /'
    ((FAIL++))
fi

CAN_ERRORS=$(dmesg | grep -i 'mcp251.*error\|mcp251.*fail\|can.*error' 2>/dev/null)
if [[ -z "$CAN_ERRORS" ]]; then
    echo "  ✓ No CAN/MCP errors in dmesg"
    ((PASS++))
else
    echo "  ✗ CAN/MCP errors detected:"
    echo "$CAN_ERRORS" | sed 's/^/      /'
    ((FAIL++))
fi
echo ""

# --- GPIO ---
echo "[GPIO Pins]"
GPIO_DUMP=$(cat /sys/kernel/debug/gpio 2>/dev/null)
if [[ -n "$GPIO_DUMP" ]]; then
    GPIO21=$(echo "$GPIO_DUMP" | grep "gpio-21")
    GPIO26=$(echo "$GPIO_DUMP" | grep "gpio-26")
    if [[ -n "$GPIO21" ]]; then
        echo "  ✓ GPIO 21 (CS2): $GPIO21"
        ((PASS++))
    else
        warn "GPIO 21 not found in gpio debug"
    fi
    if [[ -n "$GPIO26" ]]; then
        echo "  ✓ GPIO 26 (INT): $GPIO26"
        ((PASS++))
    else
        warn "GPIO 26 not found in gpio debug"
    fi
else
    warn "Could not read GPIO debug info"
fi
echo ""

# --- CAN Bus Status ---
echo "[CAN Bus Status]"
if command -v ip &>/dev/null && [[ -d /sys/class/net/can0 ]]; then
    CAN_STATE=$(ip -details link show can0 2>/dev/null | grep "state" | head -1)
    if [[ -n "$CAN_STATE" ]]; then
        echo "  ℹ $CAN_STATE"
    fi
    check "CAN network config installed" "ls /etc/systemd/network/80-can0.network"
fi
echo ""

# --- Summary ---
echo "=== Results: $PASS passed, $FAIL failed, $WARN warnings ==="
if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Troubleshooting tips:"
    echo "  - Check dmesg output:  dmesg | grep -iE 'spi|can|mcp'"
    echo "  - Check config.txt:    cat /boot/firmware/config.txt"
    echo "  - Check GPIO conflicts: sudo cat /sys/kernel/debug/gpio"
    echo "  - Check overlay loaded: sudo vcgencmd list_overlays 2>/dev/null || dtoverlay -l"
    exit 1
fi