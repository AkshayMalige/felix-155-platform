#!/bin/bash

# ==============================================================================
# 1. Define your specific file names here
# ==============================================================================
PS_DTB="versal-qemu-multiarch-ps.dtb"
PMC_DTB="versal-qemu-multiarch-pmc.dtb"
SD_IMG="qemu_sd.img"
PMC_CDO="pmc_cdo.0.0.bin"
BOOT_BH="BOOT_bh.bin"
PLM="plm.elf"

# ==============================================================================
# 2. Check if files exist before running (Prevents confusing errors)
# ==============================================================================
for file in "$PS_DTB" "$PMC_DTB" "$SD_IMG" "$PMC_CDO" "$BOOT_BH" "$PLM"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Missing file '$file'. Please ensure it is in this directory."
        exit 1
    fi
done

# Create the socket directory if it doesn't exist
mkdir -p /tmp/tmp_dir

echo "INFO: Starting MicroBlaze (PMC) QEMU..."
# Launch MicroBlaze (PMC) QEMU in the background
qemu-system-microblazeel -M microblaze-fdt -serial mon:stdio -display none \
  -device loader,addr=0xf0000000,data=0xba020004,data-len=4 \
  -device loader,addr=0xf0000004,data=0xb800fffc,data-len=4 \
  -device loader,file=$PMC_CDO,addr=0xf2000000 \
  -device loader,file=$BOOT_BH,addr=0xf201e000,force-raw=on \
  -device loader,file=$PLM \
  -hw-dtb $PMC_DTB \
  -machine-path /tmp/tmp_dir \
  -device loader,addr=0xF1110624,data=0x0,data-len=4 \
  -device loader,addr=0xF1110620,data=0x1,data-len=4 &

echo "INFO: Starting AArch64 (PS) QEMU..."
# Launch Aarch64 (PS) QEMU in the background
qemu-system-aarch64 -nographic -M arm-generic-fdt -serial null -serial null \
  -serial mon:stdio -serial null -display none -boot mode=5 \
  -drive if=sd,index=1,file=$SD_IMG,format=raw \
  -machine-path /tmp/tmp_dir -sync-quantum 1000000 \
  -hw-dtb $PS_DTB \
  -m 8G -display none -gdb tcp::9000 \
  -net nic,netdev=eth0 -netdev user,id=eth0,tftp=/tftpboot -net nic &

echo "INFO: QEMU started. Connect your XSIM now."