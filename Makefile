# ENOS BSP — Makefile
# Raspberry Pi 5 / RP1 — SPI0 Bus (2x LoRa + MCP2518FD CAN)

.PHONY: build install uninstall verify test clean help

help:
	@echo "ENOS BSP — Available targets:"
	@echo ""
	@echo "  make build      Compile device tree overlay"
	@echo "  make install    Install overlay + config (requires sudo)"
	@echo "  make uninstall  Remove overlay + config (requires sudo)"
	@echo "  make verify     Check all devices loaded after reboot"
	@echo "  make test       Run hardware smoke tests (requires sudo)"
	@echo "  make clean      Remove build artifacts"
	@echo ""

build:
	@bash scripts/build.sh

install: build
	@sudo bash scripts/install.sh

uninstall:
	@sudo bash scripts/uninstall.sh

verify:
	@sudo bash scripts/verify.sh

test:
	@echo "=== Running LoRa SPI test ==="
	@sudo /usr/bin/python3 userspace/lora_test.py
	@echo ""
	@echo "=== Running CAN loopback test ==="
	@sudo bash userspace/can_test.sh

clean:
	rm -rf build/
EOF