SHELL := /bin/bash
VERSION ?= 2025.2
export COSIM_MACHINE_PATH=unix:/tmp/tmp_dir/qemu-rport-_amba@0_cosim@0

.PHONY: run_qemu

run_qemu:
	$(RM) -rf /tmp/tmp_dir; \
	mkdir /tmp/tmp_dir; \
	./run_qemu.sh; \
	sleep 5; \
	export LD_LIBRARY_PATH=$${LD_LIBRARY_PATH:-}; \
	cd /home/synthara/VersalPrjs/felix/AM_felix0602/felix-155-platform/base_platform/project_build/flx_base_platform.sim/sim_1/behav/xsim && ./simulate.sh
kill_qemu:
	ps -aef | grep qemu | grep -v grep | awk '{ print $$2 }' | xargs -r kill -9 || true