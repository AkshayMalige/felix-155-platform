# Felix-155 Platform Generation

This project provides the infrastructure to generate a custom XPFM platform for the Versal XCVP1552 FPGA.

## Base Platform
The hardware XSA for this platform is defined by the `base_platform/top_hw_hwemu.xsa` file.

## Linux Image Generation
To build the Linux components, navigate to the `versal_linux` directory and run:
```bash
./build_versal_linux.sh -n my_foe_flx -x ../base_platform/top_hw_hwemu.xsa
```

## Software Components
After building Linux, the resulting files are organized in the `versal_linux/my_foe_flx/sw` folder.

## Platform Generation (XPFM)
To generate the final `.xpfm` platform file, use the provided Python script with Vitis:
```bash
vitis -s gen_plat.py
```

## Required Files for QEMU and XPFM
To run the QEMU simulation and build the XPFM platform, the following files are required:

- `../base_platform/top_hw_hw_emu_presynth.pdi`
- `BOOT.BIN`
- `versal-qemu-multiarch-ps.dtb`
- `versal-qemu-multiarch-pmc.dtb`
- `qemu_sd.img`
- `pmc_cdo.0.0.bin`
- `BOOT_bh.bin`
- `plm.elf`

These files can be obtained in two ways:
1.  **Copy from build directory**: Copy them from the Petalinux image directory: `versal_linux/my_foe_flx/images/linux/`
2.  **Generate with Vivado**: Generate them using Vivado with the base XSA.

## Extracting PDI Components
You can also extract the necessary binary components from the base XSA:
```bash
cd xcvp_qemu
mkdir -p pdi_files
vivado -mode tcl
# Within the Vivado TCL shell:
hsi::open_hw_design ../base_platform/top_hw_hwemu.xsa
bootgen -arch versal -dump base_platform/top_hw_hw_emu_presynth.pdi -dump_dir pdi_files
bootgen -arch versal -image bootgen.bif -w -o BOOT.BIN
cp pdi_files/* .
cp ../base_platform/extracted/ext_platform_part_wrapper_0/pdi_files/gen_files/plm.elf .
```

## Running QEMU Simulation
Follow these steps to perform a hardware/software co-simulation:

1.  **Prepare the Emulation Environment**:
    Navigate to the `xcvp_qemu` directory and ensure all files listed in the [Required Files for QEMU and XPFM](#required-files-for-qemu-and-xpfm) section are present. 

2.  **Execute Simulation**:
    ```bash
    cd xcvp_qemu
    make run_qemu
    ```

The `make run_qemu` command automates the startup of the PMC and PS QEMU instances and synchronizes them with the XSIM hardware simulation.


add_force {/ext_platform_part_wrapper_sim_wrapper/sys_clk0_0_clk_p} -radix hex {0 0ns} {1 2500ps} -repeat_every 5000ps

add_force {/ext_platform_part_wrapper_sim_wrapper/sys_clk0_0_clk_n} -radix hex {1 0ns} {0 2500ps} -repeat_every 5000ps

qemu-img resize qemu_sd.img 8G

