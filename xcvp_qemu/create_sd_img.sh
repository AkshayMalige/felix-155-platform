#!/bin/bash

# ==============================================================================
# Script to Generate Virtual SD Card Image for Versal QEMU
# ==============================================================================


BOOT_BIN="BOOT.BIN"
IMG_NAME="qemu_sd.img"
BH_NAME="BOOT_bh.bin"

if [ ! -f "$BOOT_BIN" ]; then
    echo "Error: $BOOT_BIN not found in current directory."
    exit 1
fi

echo "INFO: Creating 256MB Virtual SD Image..."
dd if=/dev/zero of=$IMG_NAME bs=256M count=1 status=progress

echo "INFO: Formatting image as FAT32..."

mkfs.vfat -F 32 $IMG_NAME

echo "INFO: Copying BOOT.BIN into the SD image..."

mcopy -i $IMG_NAME $BOOT_BIN ::/

echo "INFO: Extracting Boot Header for QEMU PMC..."

dd if=$BOOT_BIN of=$BH_NAME bs=1 count=208 skip=16 status=none

echo "SUCCESS: Generated $IMG_NAME and $BH_NAME"