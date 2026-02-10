#!/bin/bash
# ENOS BSP — CAN Bus Smoke Test
#
# Tests that the MCP2518FD is communicating and can0 is functional.
# Does NOT require another CAN node on the bus (uses loopback mode).
#
# Usage:
#   sudo ./can_test.sh
set -euo pipefail

echo "=== ENOS CAN Bus Test ==="

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)"
    exit 1
fi

# Check can-utils
if ! command -v candump &>/dev/null; then
    echo "ERROR: can-utils not installed"
    echo "Install with: sudo apt install can-utils"
    exit 1
fi

# Check interface exists
if [[ ! -d /sys/class/net/can0 ]]; then
    echo "FAIL: can0 interface does not exist"
    echo "Check: dmesg | grep -i mcp"
    exit 1
fi
echo "✓ can0 interface exists"

# Bring down if already up
ip link set can0 down 2>/dev/null || true

# Configure in loopback mode for self-test (no external CAN node needed)
echo "Configuring can0 in loopback mode (250 kbps)..."
ip link set can0 type can bitrate 250000 loopback on
ip link set can0 up
echo "✓ can0 is up in loopback mode"

# Start candump in background — give it time to bind the socket
TMPFILE=$(mktemp)
candump can0 -n 1 -T 3000 > "$TMPFILE" 2>/dev/null &
DUMP_PID=$!
sleep 0.5

# Send test frame
echo "Sending test frame: 0x123#DEADBEEF..."
cansend can0 123#DEADBEEF

# Wait for candump to receive (with timeout)
sleep 0.5
kill $DUMP_PID 2>/dev/null
wait $DUMP_PID 2>/dev/null || true

# Check result
if grep -q "DEADBEEF" "$TMPFILE"; then
    echo "✓ Loopback test PASSED — frame received"
    cat "$TMPFILE" | sed 's/^/  /'
else
    echo "✗ Loopback test FAILED — no frame received"
    echo "  Check: dmesg | grep -i mcp"
    echo "  Check: oscillator running at correct frequency"
fi

rm -f "$TMPFILE"

# Switch to normal mode for actual use
echo ""
echo "Switching to normal mode (250 kbps)..."
ip link set can0 down
ip link set can0 type can bitrate 250000 loopback off
ip link set can0 up
echo "✓ can0 ready for normal operation"

# Show interface status
echo ""
echo "Interface status:"
ip -details link show can0 | head -5 | sed 's/^/  /'

echo ""
echo "=== CAN test complete ==="
echo "Monitor traffic: candump can0"
echo "Send a frame:    cansend can0 123#AABBCCDD"