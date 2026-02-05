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
vitis -s generate_platform.py
```

## Usage
Once the XPFM is generated, you can build applications, such as a `vadd` template project, targeting this platform.



export COSIM_MACHINE_PATH=unix:/tmp/tmp_dir/qemu-rport-_amba@0_cosim@0

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
