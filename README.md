# enos-bsp

Board Support Package for the ENOS board on Raspberry Pi 5/4.

## Hardware

- **2x LoRa** (EByte E28-2G4M27SX / SX1280) — explicit SPI0 overlay
- CAN support is temporarily removed until hardware fixed.

## Quick Start

```bash
# 1. Clone
git clone <repo-url> enos-bsp
cd enos-bsp

# 2. Install LoRa SPI path
make install

# 3. Reboot
sudo reboot

# 4. Verify
make verify

# 5. Optional quick check (same as verify)
make test

# 6. Optional helper: reset RX/TX, wait BUSY, read version register
make version-check
```

## What Gets Installed

| File/Setting | Destination | Purpose |
|--------------|-------------|---------|
| `dtoverlay=enos-lora` | `config.txt` (auto-detected) | Enables explicit SPI0 overlay for deterministic `spidev0.0` + `spidev0.1` mapping |
| `99-enos-lora.rules` | `/etc/udev/rules.d/` | Creates stable aliases `/dev/lora-rx` and `/dev/lora-tx` |

## After Reboot

```
/dev/spidev0.0    ← LoRa #1 (CS0, GPIO 8)
/dev/spidev0.1    ← LoRa #2 (CS1, GPIO 7)
/dev/lora-rx      ← Alias for /dev/spidev0.0
/dev/lora-tx      ← Alias for /dev/spidev0.1
```

## Repo Structure

```
enos-bsp/
├── dts/
│   └── enos-lora.dts          # Explicit SPI0 CS mapping for LoRa (Pi4/Pi5)
├── scripts/
│   ├── build.sh               # Compile dts/enos-lora.dts
│   ├── common.sh              # Dynamic boot/config path helpers
│   ├── install.sh             # LoRa install wrapper
│   ├── install-lora.sh        # LoRa install
│   ├── uninstall.sh           # LoRa uninstall wrapper
│   ├── uninstall-lora.sh      # LoRa uninstall
│   ├── verify.sh              # LoRa verify wrapper
│   └── verify-lora.sh         # LoRa verify
├── config/
│   ├── config.txt.fragment    # LoRa config fragment
│   ├── config.lora.txt.fragment
│   └── 99-enos-lora.rules     # Stable device aliases
├── tools/
│   └── lora_version_check.py    # Reset + BUSY wait + version read helper
├── Makefile
└── README.md
```

## Platform

- Raspberry Pi 4 (BCM2711) and Raspberry Pi 5 (BCM2712 / RP1)
- Debian Trixie 13 (kernel 6.12+)
- Device tree compiler (`sudo apt install device-tree-compiler`)

## LoRa Reset & Bring-Up

What this BSP provides:

- Device tree overlay for SPI0 and stable aliases `/dev/lora-rx` and `/dev/lora-tx`.
- A helper tool `lora_version_check.py` that, for **each** radio:
	- Pulses reset (RX: GPIO22, TX: GPIO5).
	- Waits for BUSY to go low.
	- Reads register `0x0153` to confirm basic SPI communication.

How to use it:

- After `make install` + `sudo reboot`, run:
	- `make verify` to check nodes and aliases.
	- `make version-check` (or `sudo python3 tools/lora_version_check.py`) to sanity-check wiring and reset/BUSY behavior.

Production radio software should perform its own one-time reset + init on startup; this BSP focuses on wiring, overlay, and low-level SPI reachability rather than full SX128x configuration.
