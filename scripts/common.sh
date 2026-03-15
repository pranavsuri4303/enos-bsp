#!/bin/bash
# Shared helpers for ENOS BSP scripts

detect_boot_layout() {
    if [[ -f "/boot/firmware/config.txt" ]]; then
        BOOT_DIR="/boot/firmware"
    elif [[ -f "/boot/config.txt" ]]; then
        BOOT_DIR="/boot"
    else
        echo "ERROR: Could not find config.txt in /boot/firmware or /boot"
        return 1
    fi

    OVERLAY_DIR="$BOOT_DIR/overlays"
    CONFIG_FILE="$BOOT_DIR/config.txt"
}

print_model() {
    if [[ -f "/proc/device-tree/model" ]]; then
        tr -d '\0' < /proc/device-tree/model
    else
        echo "Unknown model"
    fi
}
