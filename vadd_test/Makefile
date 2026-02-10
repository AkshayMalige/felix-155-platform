############################################################################
#  Top-level Makefile for Vitis Project (Unified Flow 2025.2)
#  TARGET = sw_emu | hw_emu | hw
############################################################################
SHELL := /bin/bash

# --- Xilinx Tools ---
XILINX_VITIS ?= /tools/Xilinx/2025.2/Vitis
TARGET       ?= sw_emu

# --- Project Settings ---
HLS_KERNELS := vadd
HLS_DIR     := hls_src
HOST_DIR    := host

# --- Inputs ---
# PLATFORM    ?= ../my_workspace/xcvp1552_custom_felix/export/xcvp1552_custom_felix/xcvp1552_custom_felix.xpfm
# PLATFORM    ?= /home/synthara/VersalPrjs/tmp/package/platform/export/platform/platform.xpfm
PLATFORM    ?= /home/synthara/VersalPrjs/felix/AM_felix0902/felix-155-platform/my_workspace/xcvp1552_custom_felix/export/xcvp1552_custom_felix/xcvp1552_custom_felix.xpfm

# --- Artifacts ---
LINK_CFG    := link.cfg
# Vitis Link produces an XSA (Fixed XSA). We will copy this to .xclbin for the host.
LINKED_XSA  := vadd.xsa
XCLBIN      := vadd.xclbin
PACKAGE_DIR := package

# --- Software Components ---
SW_DIR      := ../versal_linux/my_foe_flx/sw
ROOTFS      := $(SW_DIR)/image/rootfs.ext4
IMAGE       := $(SW_DIR)/image/Image
SYSROOT_SCRIPT := ../versal_linux/my_foe_flx/images/linux/sdk/environment-setup-cortexa72-cortexa53-amd-linux
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
# FIX: Linking creates the .xsa. We then copy it to .xclbin so the host can find it.
$(LINKED_XSA): xo
	@echo "--- Linking Kernel (Creates .xsa) ---"
	v++ -l -t $(TARGET) \
		--platform $(PLATFORM) \
		--config $(LINK_CFG) \
		hls_src/vadd.xo \
		-o $(LINKED_XSA)
	@echo "--- Creating XCLBIN from Linked XSA ---"
	cp $(LINKED_XSA) $(XCLBIN)

link: $(LINKED_XSA)

# --- 4. V++ Package ---
# FIX: Removed invalid '-o $(XCLBIN)'.
# FIX: Added '--package.sd_file $(XCLBIN)' to ensure hardware binary is on the SD card.
# package: link host
# 	@echo "--- Packaging Emulation Image ---"
# 	v++ -p -t $(TARGET) \
# 		--platform $(PLATFORM) \
# 		$(LINKED_XSA) \
# 		--package.out_dir $(PACKAGE_DIR) \
# 		--package.rootfs $(ROOTFS) \
# 		--package.kernel_image $(IMAGE) \
# 		--package.sd_file $(HOST_DIR)/host_app \
# 		--package.sd_file $(XCLBIN)

# --- V++ Package ---
package: link host
	@echo "--- Packaging Emulation Image ---"
	v++ -p -t $(TARGET) \
		--platform $(PLATFORM) \
		$(LINKED_XSA) \
		--package.out_dir $(PACKAGE_DIR) \
		--package.rootfs $(ROOTFS) \
		--package.kernel_image $(IMAGE) \
		--package.sd_file $(HOST_DIR)/host_app \
		--package.sd_file $(XCLBIN) \
		--package.image_format ext4 \
		--package.ext4_fat32_size 1024

# --- Clean ---
clean:
	$(MAKE) -C $(HLS_DIR) clean
	$(MAKE) -C $(HOST_DIR) clean
	rm -rf _x .Xil *.log *.jou $(LINKED_XSA) $(XCLBIN) $(PACKAGE_DIR)