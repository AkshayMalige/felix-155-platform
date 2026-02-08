############################################################################
#  Top-level Makefile for Vitis Project (Unified Flow 2025.2)
#  TARGET = sw_emu | hw_emu | hw
############################################################################
SHELL := /bin/bash

# --- Xilinx Tools ---
XILINX_VITIS ?= /tools/Xilinx/2025.2/Vitis

TARGET ?= sw_emu

HLS_KERNELS := vadd
HLS_DIR     := hls_src
HOST_DIR    := host

# --- Cross-compilation settings ---
SYSROOT_SCRIPT := /home/synthara/versal_common/2025_sysroot/environment-setup-cortexa72-cortexa53-amd-linux
GCC_COMPILER   := aarch64-amd-linux-g++

# --- V++ Link/Package settings ---
PLATFORM    ?= ../vitis_workspace2/xcvp1552_custom_flx/export/xcvp1552_custom_flx/xcvp1552_custom_flx.xpfm
LINK_CFG    := link.cfg
FIXED_XSA   := vadd.xsa
XCLBIN      := vadd.xclbin
PACKAGE_DIR := package

# --- Software Components for Packaging ---
ROOTFS      := ../versal_linux/my_foe_flx/images/linux/rootfs.ext4
IMAGE       := ../versal_linux/my_foe_flx/images/linux/Image

.PHONY: all sim xo host link package clean help

all: xo host link package

# --- Host Application ---
host:
	@echo "--- Building Host Application ---"
	unset LD_LIBRARY_PATH && \
	source $(SYSROOT_SCRIPT) && \
	$(MAKE) -C $(HOST_DIR) GCC=$(GCC_COMPILER) SYSROOT=$$SDKTARGETSYSROOT

# --- V++ Link ---
link: xo
	@echo "--- Linking Kernel into Fixed XSA ---"
	v++ -l -t $(TARGET) --platform $(PLATFORM) --config $(LINK_CFG) hls_src/vadd.xo -o $(FIXED_XSA)

# --- V++ Package ---
package: link host
	@echo "--- Packaging Emulation Image ---"
	v++ -p -t $(TARGET) --platform $(PLATFORM) $(FIXED_XSA) \
		--package.out_dir $(PACKAGE_DIR) \
		--package.rootfs $(ROOTFS) \
		--package.kernel_image $(IMAGE) \
		--package.sd_file $(HOST_DIR)/host_app \
		-o $(XCLBIN)

# --- PL Kernel (HLS) ---
.PHONY: pl
pl:
	$(MAKE) -C $(HLS_DIR) export_xo KERNELS="$(HLS_KERNELS)" XILINX_VITIS=$(XILINX_VITIS)

# --- Simulation ---
# make sim TARGET=sw_emu (runs csim)
# make sim TARGET=hw_emu (runs cosim)
sim:
	$(MAKE) -C $(HLS_DIR) sim TARGET=$(TARGET) KERNELS="$(HLS_KERNELS)" XILINX_VITIS=$(XILINX_VITIS)

# --- Export XO ---
xo:
	$(MAKE) -C $(HLS_DIR) export_xo KERNELS="$(HLS_KERNELS)" XILINX_VITIS=$(XILINX_VITIS)

# --- Clean ---
clean:
	$(MAKE) -C $(HLS_DIR) clean KERNELS="$(HLS_KERNELS)"
	rm -rf _x .Xil *.log *.jou

help:
	@echo "Usage:"
	@echo "  make sim TARGET=sw_emu   # Run HLS C-simulation (vitis-run --csim)"
	@echo "  make sim TARGET=hw_emu   # Run HLS Co-simulation (vitis-run --cosim)"
	@echo "  make xo                  # Synthesize and export XO file (v++ -c --mode hls)"
	@echo "  make clean               # Remove generated files"
