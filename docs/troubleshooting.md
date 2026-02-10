# ENOS Board — Troubleshooting

## Quick Diagnostics

```bash
# Run the automated check
make verify

# Manual checks
dmesg | grep -iE 'spi|can|mcp'     # Kernel messages
ls /dev/spidev0.*                    # LoRa spidev nodes
ls /sys/class/net/can0               # CAN interface
sudo cat /sys/kernel/debug/gpio      # GPIO allocations
```

## Common Problems

### No /dev/spidev0.0 or /dev/spidev0.1

**Cause:** SPI0 not enabled.

```bash
# Check config.txt has:
grep spi /boot/firmware/config.txt
# Should show: dtparam=spi=on

# If missing:
sudo nano /boot/firmware/config.txt
# Add under [all]: dtparam=spi=on
sudo reboot
```

### /dev/spidev0.0 exists but LoRa test returns 0x00 or 0xFF

**Cause:** SPI bus is communicating but LoRa module isn't responding. Bus stuck.

Check in order:
1. Module powered? (3.3V to VCC, GND connected)
2. MOSI/MISO not swapped? (MOSI=GPIO10=pin19, MISO=GPIO9=pin21)
3. SCLK connected? (GPIO11=pin23)
4. CS pin soldered to correct module?
5. Try lower SPI speed: edit `lora_test.py`, set `SPI_SPEED_HZ = 100_000`

### can0 interface does not exist

**Cause:** MCP2518FD driver failed to load.

```bash
# Check overlay loaded
dmesg | grep -i mcp

# Common errors and fixes:
```

**"MCP2518FD didn't enter Configuration Mode"**
- Oscillator not running or wrong frequency
- Check waveform generator: must be 20 MHz square wave, 3.3V levels
- Short leads to MCP2518FD OSC1 pin

**"spi0.2: setup failed"**
- CS2 (GPIO 21) conflict with another overlay
- Check: `sudo cat /sys/kernel/debug/gpio | grep gpio-21`
- Remove conflicting overlays from config.txt

**No MCP messages at all in dmesg**
- Overlay not loaded: check `grep enos-can /boot/firmware/config.txt`
- Overlay file missing: check `ls /boot/firmware/overlays/enos-can.dtbo`
- Rebuild and reinstall: `make install && sudo reboot`

### CAN loopback test fails (no frame received)

**Cause:** MCP2518FD loads but can't transmit.

1. Check interrupt pin: GPIO 26 must be wired to MCP2518FD INT pin
2. Check dmesg for interrupt errors: `dmesg | grep -i irq`
3. Verify oscillator frequency matches config (20 MHz dev / 40 MHz prod)

### SPI transfer errors in dmesg

**"spi_master spi0: failed to transfer one message"**
- Wiring issue on MISO/MOSI/SCLK
- Verify with multimeter: continuity from Pi header to each device
- Check for cold solder joints

**"spi0.X: SPI transfer timed out"**
- CS pin not toggling — check with oscilloscope or logic analyzer
- GPIO conflict — another driver has claimed the pin

## Switching to 40 MHz Production Oscillator

Edit `dts/enos-can.dts`:
```
clock-frequency = <40000000>;
```

Then:
```bash
make clean
make install
sudo reboot
```

## Useful Commands

```bash
# SPI
spi-pipe -d /dev/spidev0.0 -s 1000000    # Raw SPI tool
python3 -c "import spidev; print('spidev OK')"

# CAN
sudo ip link set can0 up type can bitrate 250000
candump can0                               # Monitor all traffic
candump can0,123:7FF                       # Filter by ID 0x123
cansend can0 123#AABBCCDD                  # Send a frame
ip -details -statistics link show can0     # Interface stats

# System
dtoverlay -l                               # List loaded overlays
sudo vcdbg log msg 2>&1 | grep -i overlay  # Overlay load log
cat /proc/interrupts | grep mcp            # Interrupt count
```
