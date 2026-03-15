# enos-bsp

Board Support Package for the ENOS board on Raspberry Pi 5.

## Hardware

- **2x LoRa** (EByte E28-2G4M27SX / SX1280) — explicit SPI0 overlay
- CAN support is temporarily removed in this branch.

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
| `enos-lora.dtbo` | `/boot/firmware/overlays/` or `/boot/overlays/` | Explicit SPI0 overlay with fixed CS mapping |
| `dtoverlay=enos-lora` | `config.txt` (auto-detected) | Loads LoRa overlay and creates `spidev0.0` + `spidev0.1` |
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

## LoRa Reset Behavior

Practical guidance:

- Reset once before radio initialization (boot-time or app-start) is usually enough.
- Do **not** hardware-reset before every packet send; that can add latency and lose configured state.
- If you see garbage after faults, recover by re-initializing radio state (or one reset + full init), not per-message resets.

EN behavior for your wiring:

- RX_EN is hardware-tied high (always enabled).
- TX_EN should be asserted only during transmit windows.
- Keep TX_EN low during RX/idle to reduce self-interference.

Reset lines from your shared pinout:

- RX_RESET = GPIO22
- TX_RESET = GPIO5

Helper examples with your reset wiring:

- Run both RX and TX checks: `make version-check`
- Direct command: `sudo python3 tools/lora_version_check.py`

If your wiring exposes `NRST`/`BUSY`, add explicit init sequencing in your TX/RX application. This repo currently only validates low-level SPI reachability.
