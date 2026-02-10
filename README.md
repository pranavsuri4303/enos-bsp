# enos-bsp

Board Support Package for the ENOS board on Raspberry Pi 5.

## Hardware

- **2x LoRa** (EByte E28-2G4M27SX / SX1280) — 2.4 GHz, SPI userspace
- **1x CAN** (MCP2518FD) — CAN FD, kernel socketCAN driver
- All three devices share **SPI0** with separate chip selects

## Quick Start

```bash
# 1. Clone
git clone <repo-url> enos-bsp
cd enos-bsp

# 2. Build + install (compiles overlay, updates config.txt)
make install

# 3. Reboot
sudo reboot

# 4. Verify
make verify

# 5. Test hardware
make test
```

## What Gets Installed

| File | Destination | Purpose |
|------|-------------|---------|
| `enos-can.dtbo` | `/boot/firmware/overlays/` | Device tree overlay for MCP2518FD on SPI0 CS2 |
| `dtparam=spi=on` | `/boot/firmware/config.txt` | Enables SPI0 with LoRa spidev nodes |
| `dtoverlay=enos-can` | `/boot/firmware/config.txt` | Loads CAN overlay |
| `80-can0.network` | `/etc/systemd/network/` | Auto-configures can0 at 250 kbps |

## After Reboot

```
/dev/spidev0.0    ← LoRa #1 (CS0, GPIO 8)
/dev/spidev0.1    ← LoRa #2 (CS1, GPIO 7)
can0              ← MCP2518FD (CS2, GPIO 21)
```

## Repo Structure

```
enos-bsp/
├── dts/
│   └── enos-can.dts           # Custom overlay (MCP2518FD on CS2)
├── scripts/
│   ├── build.sh               # Compile DTS → DTBO
│   ├── install.sh             # Deploy to Pi
│   ├── uninstall.sh           # Remove from Pi
│   └── verify.sh              # Post-reboot diagnostics
├── config/
│   ├── config.txt.fragment    # Lines added to config.txt
│   └── can0.network           # systemd CAN auto-config
├── userspace/
│   ├── lora_test.py           # SX1280 SPI read test
│   └── can_test.sh            # CAN loopback smoke test
├── docs/
│   ├── architecture.md        # Bus diagram, pin map
│   └── troubleshooting.md     # Error guide
├── Makefile
└── README.md
```

## Platform

- Raspberry Pi 5 (BCM2712 / RP1)
- Debian Trixie 13 (kernel 6.12+)
- Device tree compiler (`sudo apt install device-tree-compiler`)

## Development Notes

The oscillator is set to **20 MHz** (waveform generator) during development.
For production boards with a 40 MHz crystal, change `clock-frequency` in
`dts/enos-can.dts` to `<40000000>` and run `make install`.
