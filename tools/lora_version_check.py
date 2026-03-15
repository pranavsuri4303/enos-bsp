#!/usr/bin/env python3
"""
ENOS LoRa bring-up tool:
- Reset RX and TX modules
- Wait for BUSY to deassert
- Read SX1280 firmware version register (0x0153)

No payload write and no on-air TX/RX.
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path

try:
    import spidev
except ImportError:
    print("ERROR: python spidev not installed")
    print("Install with: pip install spidev --break-system-packages")
    sys.exit(1)


SX1280_REG_FIRMWARE_VERSION = 0x0153
SX1280_CMD_READ_REGISTER = 0x1D
SX1280_EXPECTED_VERSION = 0xA9


def parse_spidev_path(device_path: str) -> tuple[int, int]:
    real = os.path.realpath(device_path)
    name = os.path.basename(real)
    if not name.startswith("spidev") or "." not in name:
        raise ValueError(f"{device_path} does not resolve to a spidev node")
    bus_str, dev_str = name.replace("spidev", "").split(".", 1)
    return int(bus_str), int(dev_str)


def write_file(path: Path, value: str) -> None:
    path.write_text(value)


def export_gpio(gpio: int) -> Path:
    gpio_dir = Path(f"/sys/class/gpio/gpio{gpio}")
    if gpio_dir.exists():
        return gpio_dir

    export_path = Path("/sys/class/gpio/export")
    if not export_path.exists():
        raise RuntimeError("sysfs GPIO not available on this system")

    write_file(export_path, str(gpio))
    deadline = time.time() + 1.0
    while time.time() < deadline:
        if gpio_dir.exists():
            return gpio_dir
        time.sleep(0.01)

    raise RuntimeError(f"failed to export GPIO {gpio}")


def set_gpio_output(gpio: int, level: int) -> None:
    gpio_dir = export_gpio(gpio)
    write_file(gpio_dir / "direction", "out")
    write_file(gpio_dir / "value", "1" if level else "0")


def read_gpio_input(gpio: int) -> int:
    gpio_dir = export_gpio(gpio)
    write_file(gpio_dir / "direction", "in")
    return int((gpio_dir / "value").read_text().strip())


def pulse_reset(reset_gpio: int, reset_low_ms: int, settle_ms: int) -> None:
    # SX1280 reset is active-low.
    set_gpio_output(reset_gpio, 1)
    time.sleep(0.002)
    set_gpio_output(reset_gpio, 0)
    time.sleep(reset_low_ms / 1000.0)
    set_gpio_output(reset_gpio, 1)
    time.sleep(settle_ms / 1000.0)


def wait_busy_low(busy_gpio: int, timeout_ms: int) -> bool:
    deadline = time.time() + (timeout_ms / 1000.0)
    while time.time() < deadline:
        if read_gpio_input(busy_gpio) == 0:
            return True
        time.sleep(0.001)
    return False


def read_register(spi: spidev.SpiDev, reg: int) -> int:
    hi = (reg >> 8) & 0xFF
    lo = reg & 0xFF
    rx = spi.xfer2([SX1280_CMD_READ_REGISTER, hi, lo, 0x00, 0x00])
    return rx[4]


def check_module(name: str, device_path: str, reset_gpio: int, busy_gpio: int, speed: int, reset_low_ms: int, settle_ms: int, busy_timeout_ms: int) -> bool:
    print(f"\n[{name}] {device_path}")
    try:
        bus, dev = parse_spidev_path(device_path)
    except Exception as exc:
        print(f"  FAIL: {exc}")
        return False

    try:
        pulse_reset(reset_gpio, reset_low_ms, settle_ms)
        print(f"  Reset pulse on GPIO{reset_gpio}")
    except Exception as exc:
        print(f"  FAIL: reset GPIO{reset_gpio} error: {exc}")
        return False

    try:
        if wait_busy_low(busy_gpio, busy_timeout_ms):
            print(f"  BUSY GPIO{busy_gpio}: LOW (ready)")
        else:
            print(f"  FAIL: BUSY GPIO{busy_gpio} stayed HIGH")
            return False
    except Exception as exc:
        print(f"  FAIL: BUSY GPIO{busy_gpio} read error: {exc}")
        return False

    spi = spidev.SpiDev()
    try:
        spi.open(bus, dev)
        spi.max_speed_hz = speed
        spi.mode = 0
        version = read_register(spi, SX1280_REG_FIRMWARE_VERSION)
    except Exception as exc:
        print(f"  FAIL: SPI read error: {exc}")
        return False
    finally:
        spi.close()

    print(f"  Version reg 0x0153: 0x{version:02X}")
    if version == SX1280_EXPECTED_VERSION:
        print("  PASS: version matches expected SX1280 value")
        return True

    print("  WARN: version differs from expected 0xA9")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Reset RX/TX LoRa modules and read version register")
    parser.add_argument("--rx-device", default="/dev/lora-rx", help="RX SPI device path")
    parser.add_argument("--tx-device", default="/dev/lora-tx", help="TX SPI device path")
    parser.add_argument("--rx-reset-gpio", type=int, default=22, help="RX reset GPIO (default: 22)")
    parser.add_argument("--tx-reset-gpio", type=int, default=5, help="TX reset GPIO (default: 5)")
    parser.add_argument("--rx-busy-gpio", type=int, default=23, help="RX busy GPIO (default: 23)")
    parser.add_argument("--tx-busy-gpio", type=int, default=6, help="TX busy GPIO (default: 6)")
    parser.add_argument("--speed", type=int, default=1_000_000, help="SPI speed in Hz")
    parser.add_argument("--reset-low-ms", type=int, default=10, help="Reset low pulse width in ms")
    parser.add_argument("--settle-ms", type=int, default=20, help="Settle delay after reset in ms")
    parser.add_argument("--busy-timeout-ms", type=int, default=500, help="BUSY wait timeout in ms")
    args = parser.parse_args()

    print("=== ENOS LoRa Version Check ===")
    print("Flow: reset -> wait BUSY low -> read version register")

    ok_rx = check_module(
        name="RX",
        device_path=args.rx_device,
        reset_gpio=args.rx_reset_gpio,
        busy_gpio=args.rx_busy_gpio,
        speed=args.speed,
        reset_low_ms=args.reset_low_ms,
        settle_ms=args.settle_ms,
        busy_timeout_ms=args.busy_timeout_ms,
    )

    ok_tx = check_module(
        name="TX",
        device_path=args.tx_device,
        reset_gpio=args.tx_reset_gpio,
        busy_gpio=args.tx_busy_gpio,
        speed=args.speed,
        reset_low_ms=args.reset_low_ms,
        settle_ms=args.settle_ms,
        busy_timeout_ms=args.busy_timeout_ms,
    )

    print("\n--- Summary ---")
    print(f"RX: {'PASS' if ok_rx else 'FAIL'}")
    print(f"TX: {'PASS' if ok_tx else 'FAIL'}")

    return 0 if (ok_rx and ok_tx) else 1


if __name__ == "__main__":
    sys.exit(main())
