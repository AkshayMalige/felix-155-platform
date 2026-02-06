############################################################################
#  Top-level Makefile for Vitis Project (Unified Flow 2025.2)
#  TARGET = sw_emu | hw_emu | hw
############################################################################

# --- Xilinx Tools ---
XILINX_VITIS ?= /tools/Xilinx/2025.2/Vitis

TARGET ?= sw_emu

HLS_KERNELS := vadd
HLS_DIR     := hls_src

.PHONY: all sim xo clean help

all: xo

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
