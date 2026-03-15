# ENOS BSP — Makefile
# Raspberry Pi 5 / RP1 — LoRa-only workflow (CAN disabled for now)

SUDO := $(shell if [ "$$(id -u)" -eq 0 ]; then echo ""; else echo "sudo"; fi)

.PHONY: build install install-lora uninstall uninstall-lora verify verify-lora test clean help

help:
	@echo "ENOS BSP — Available targets:"
	@echo ""
	@echo "  make build        Compile enos-lora overlay"
	@echo "  make install      Install LoRa SPI path (requires sudo)"
	@echo "  make uninstall    Remove LoRa SPI config (requires sudo)"
	@echo "  make verify       Verify LoRa SPI path"
	@echo "  make test         Alias for verify"
	@echo "  make clean      Remove build artifacts"
	@echo ""

build:
	@bash scripts/build.sh

install: build
	@$(SUDO) bash scripts/install.sh

install-lora:
	@$(SUDO) bash scripts/install-lora.sh

uninstall:
	@$(SUDO) bash scripts/uninstall.sh

uninstall-lora:
	@$(SUDO) bash scripts/uninstall-lora.sh

verify:
	@$(SUDO) bash scripts/verify.sh

verify-lora:
	@$(SUDO) bash scripts/verify-lora.sh

test:
	@$(MAKE) verify

clean:
	rm -rf build/