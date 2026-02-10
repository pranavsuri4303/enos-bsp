#!/usr/bin/env python3
"""
ENOS BSP — LoRa Module Test (E28-2G4M27SX / SX1280)

Reads the SX1280 chip firmware version register to verify SPI communication.
Expected response: 0xA9 (SX1280 silicon rev) from register 0x0153.

Usage:
    python3 lora_test.py          # Test both modules
    python3 lora_test.py 0        # Test LoRa #1 only (CS0)
    python3 lora_test.py 1        # Test LoRa #2 only (CS1)

Requirements:
    pip install spidev --break-system-packages
"""

import sys
import time

try:
    import spidev
except ImportError:
    print("ERROR: spidev not installed")
    print("Install with: pip install spidev --break-system-packages")
    sys.exit(1)


# SX1280 register: firmware version
# Read command format: [0x1D, addr_hi, addr_lo, 0x00 (NOP), read_byte]
SX1280_REG_FIRMWARE_VERSION = 0x0153
SX1280_EXPECTED_VERSION = 0xA9

SPI_BUS = 0
SPI_SPEED_HZ = 1_000_000  # 1 MHz — conservative for testing


def read_sx1280_version(bus: int, device: int) -> int | None:
    """Read firmware version register from SX1280 via SPI."""
    spi = spidev.SpiDev()
    try:
        spi.open(bus, device)
        spi.max_speed_hz = SPI_SPEED_HZ
        spi.mode = 0  # SX1280 uses SPI mode 0 (CPOL=0, CPHA=0)

        addr_hi = (SX1280_REG_FIRMWARE_VERSION >> 8) & 0xFF
        addr_lo = SX1280_REG_FIRMWARE_VERSION & 0xFF

        # SX1280 ReadRegister command: 0x1D, addr[15:8], addr[7:0], NOP, data
        tx = [0x1D, addr_hi, addr_lo, 0x00, 0x00]
        rx = spi.xfer2(tx)

        # Response byte is at index 4
        return rx[4]
    except Exception as e:
        print(f"  SPI error on spidev{bus}.{device}: {e}")
        return None
    finally:
        spi.close()


def test_module(device: int) -> bool:
    """Test a single LoRa module."""
    label = f"LoRa #{device + 1} (/dev/spidev{SPI_BUS}.{device})"
    print(f"\nTesting {label}...")

    version = read_sx1280_version(SPI_BUS, device)

    if version is None:
        print(f"  FAIL — Could not communicate over SPI")
        print(f"  Check: wiring, solder joints, module power")
        return False
    elif version == SX1280_EXPECTED_VERSION:
        print(f"  PASS — Firmware version: 0x{version:02X} (expected 0x{SX1280_EXPECTED_VERSION:02X})")
        return True
    elif version == 0x00 or version == 0xFF:
        print(f"  FAIL — Got 0x{version:02X} (bus stuck high/low)")
        print(f"  Check: MISO/MOSI wiring, CS pin, module power")
        return False
    else:
        print(f"  WARN — Firmware version: 0x{version:02X} (expected 0x{SX1280_EXPECTED_VERSION:02X})")
        print(f"  SPI communication works but unexpected version — may be different silicon rev")
        return True


def main():
    print("=== ENOS LoRa Module Test (SX1280) ===")

    # Determine which modules to test
    if len(sys.argv) > 1:
        devices = [int(sys.argv[1])]
    else:
        devices = [0, 1]

    results = {}
    for dev in devices:
        results[dev] = test_module(dev)

    # Summary
    print("\n--- Summary ---")
    for dev, passed in results.items():
        status = "PASS" if passed else "FAIL"
        print(f"  LoRa #{dev + 1} (CS{dev}): {status}")

    if all(results.values()):
        print("\nAll modules OK")
        return 0
    else:
        print("\nSome modules failed — see above for details")
        return 1


if __name__ == "__main__":
    sys.exit(main())
