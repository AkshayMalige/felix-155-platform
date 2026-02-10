############################################################################
#  Top-level Makefile for Vitis Project (Unified Flow 2025.2)
############################################################################
SHELL := /bin/bash

# --- Xilinx Tools ---
XILINX_VITIS?= /tools/Xilinx/2025.2/Vitis
TARGET      ?= hw_emu

# --- Project Settings ---
# CRITICAL FIX 1: Match the kernel name to your hls_config.cfg (syn.top=vadd_pl)
HLS_KERNELS := vadd_pl
HLS_DIR     := hls_src
HOST_DIR    := host

# --- Inputs ---
PLATFORM   ?= /home/synthara/VersalPrjs/felix/AM_felix0902/felix-155-platform/my_workspace/xcvp1552_custom_felix/export/xcvp1552_custom_felix/xcvp1552_custom_felix.xpfm

# --- Artifacts ---
LINK_CFG    := link.cfg
LINKED_XSA  := vadd.xsa
XCLBIN      := vadd.xclbin
PACKAGE_DIR := package

# --- Software Components ---
SW_DIR      :=/home/synthara/VersalPrjs/felix/AM_felix0902/felix-155-platform/my_workspace/xcvp1552_custom_felix/export/xcvp1552_custom_felix/sw/xrt_linux
ROOTFS      := $(SW_DIR)/image/rootfs.ext4
IMAGE       := $(SW_DIR)/image/Image
SYSROOT_SCRIPT := /home/synthara/VersalPrjs/felix/AM_felix0902/felix-155-platform/versal_linux/my_foe_flx/images/linux/sdk/environment-setup-cortexa72-cortexa53-amd-linux
GCC_COMPILER   := aarch64-amd-linux-g++

.PHONY: all host link package clean

all: package

# --- 1. Host Application ---
host:
	@echo "--- Building Host Application ---"
	bash -c "source $(SYSROOT_SCRIPT) && $(MAKE) -C $(HOST_DIR) GCC=$(GCC_COMPILER) SYSROOT=\$$SDKTARGETSYSROOT"

# --- 2. HLS Kernel (XO) ---
xo:
	$(MAKE) -C $(HLS_DIR) export_xo KERNELS="$(HLS_KERNELS)" XILINX_VITIS=$(XILINX_VITIS)

# --- 3. V++ Link ---
$(LINKED_XSA): xo
	@echo "--- Linking Kernel ---"
	v++ -l -t $(TARGET) \
		--platform $(PLATFORM) \
		--config $(LINK_CFG) \
		hls_src/vadd.xo \
		-o $(LINKED_XSA)

link: $(LINKED_XSA)

package: link host
	v++ -p -t $(TARGET) \
        --platform $(PLATFORM) \
        $(LINKED_XSA) \
        --package.out_dir $(PACKAGE_DIR) \
        --package.rootfs $(ROOTFS) \
        --package.kernel_image $(IMAGE) \
        --package.sd_file $(HOST_DIR)/host_app \
        --package.sd_file $(LINK_CFG) \
        --package.boot_mode sd \
        --package.bif boot.bif \
		--package.image_format ext4 \
        --package.ext4_fat32_size 2048 \
        -o $(PACKAGE_DIR)/$(XCLBIN)

# CRITICAL FIX 2 (Above): Added --package.ext4_fat32_size 2048
# This sets the boot partition to 2GB, preventing the "size greater than FAT32" error.

# --- Clean ---
clean:
	$(MAKE) -C $(HLS_DIR) clean
	$(MAKE) -C $(HOST_DIR) clean
	rm -rf _x.Xil *.log *.jou $(LINKED_XSA) $(XCLBIN) $(PACKAGE_DIR)