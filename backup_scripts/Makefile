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
	cd /home/synthara/VersalPrjs/felix/AM_felix2101/felix-155-xpfm/felix-155-platform/vadd_project/vadd/build/hw_emu/package/package/sim/behav_waveform/xsim/ && ./simulate.sh
kill_qemu:
	ps -aef | grep qemu | grep -v grep | awk '{ print $$2 }' | xargs -r kill -9 || true