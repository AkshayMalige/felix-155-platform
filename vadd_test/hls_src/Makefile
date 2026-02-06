# Makefile for Vitis HLS project management (Unified Vitis 2025.2)

# ===================================================================
# Configuration
# ===================================================================
XILINX_VITIS ?= /tools/Xilinx/2025.2/Vitis

# Use a wrapper to ensure environment is sourced if possible
# Or rely on the user having sourced it. 
# In this environment, we will try to use absolute paths.
VITIS_RUN    := $(XILINX_VITIS)/bin/vitis-run
VPP          := $(XILINX_VITIS)/bin/v++

# List of kernels
KERNELS ?= vadd

# Default target for simulation
TARGET ?= sw_emu

CONFIG_FILE := hls_config.cfg

# ===================================================================
# Rules
# ===================================================================
.PHONY: all kernels csim csynth cosim export_xo export_ip sim clean

all: kernels

# --- Build Rules ---
kernels: export_xo

# In 2025.2, csim is run via vitis-run. Requires --work_dir.
csim:
	@for KERNEL in $(KERNELS); do \
		echo "--- Running C-simulation for $$KERNEL ---"; \
		$(VITIS_RUN) --csim --config $(CONFIG_FILE) --work_dir $${KERNEL}_hls; \
	done

# csynth is part of the v++ --compile flow for HLS
csynth:
	@for KERNEL in $(KERNELS); do \
		echo "--- Running C-synthesis for $$KERNEL ---"; \
		$(VPP) -c --mode hls --config $(CONFIG_FILE) --work_dir $${KERNEL}_hls; \
	done

# cosim is run via vitis-run. Requires --work_dir AND synthesis first.
cosim:
	@for KERNEL in $(KERNELS); do \
		echo "--- Running Co-simulation for $$KERNEL ---"; \
		$(VPP) -c --mode hls --config $(CONFIG_FILE) --work_dir $${KERNEL}_hls; \
		$(VITIS_RUN) --cosim --config $(CONFIG_FILE) --work_dir $${KERNEL}_hls; \
	done

# Export XO is done via v++ --compile with package.output.format=xo in config
export_xo:
	@for KERNEL in $(KERNELS); do \
		echo "--- Exporting XO for $$KERNEL ---"; \
		$(VPP) -c --mode hls --config $(CONFIG_FILE) --work_dir $${KERNEL}_hls; \
		find $${KERNEL}_hls -name "*.xo" -exec cp {} ./$${KERNEL}.xo \; ; \
	done

# Export IP
export_ip:
	@for KERNEL in $(KERNELS); do \
		echo "--- Exporting IP for $$KERNEL ---"; \
		$(VITIS_RUN) --impl --config $(CONFIG_FILE) --work_dir $${KERNEL}_hls; \
	done

# --- Simulation Rule ---
sim:
ifeq ($(TARGET),sw_emu)
	$(MAKE) csim
else ifeq ($(TARGET),hw_emu)
	$(MAKE) cosim
else
	@echo "Error: TARGET must be sw_emu or hw_emu"
	@exit 1
endif

# --- Clean Rule ---
clean:
	@echo "--- Cleaning all generated files ---"
	for KERNEL in $(KERNELS); do \
		rm -rf "$${KERNEL}_hls" "$${KERNEL}.xo"; \
	done
	rm -rf .Xil vitis_hls.log *.log *.jou .vitis_hls_reports