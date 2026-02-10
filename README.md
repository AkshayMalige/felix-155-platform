# Felix-155 Platform

Custom Vitis extensible platform for the Versal XCVP1552 (`xcvp1552-vsva3340-2MHP-e-S`) with hardware emulation support.

**Tools:** Vivado / Vitis / PetaLinux 2025.2

## Project Structure

```
felix-155-platform/
├── base_platform/          # Vivado hardware design and XSA exports
│   ├── src/                # Block design, constraints, IP cores
│   ├── top_hw_hwemu.xsa    # Combined HW + HW-emu XSA
│   └── recreate_project.tcl
├── versal_linux/           # PetaLinux build environment
│   ├── build_versal_linux.sh
│   └── my_foe_flx/        # PetaLinux project (generated)
│       └── sw/             # Organized boot/image artifacts
├── gen_plat.py             # Vitis platform generation script
├── my_workspace/           # Vitis workspace (generated)
│   └── xcvp1552_custom_felix/
│       └── export/         # Final .xpfm platform
├── vadd_test/              # Vector-add test application
│   ├── hls_src/            # HLS kernel (vadd_pl)
│   ├── host/               # XRT host application
│   ├── Makefile            # Full build: xo -> link -> package
│   └── package/            # v++ package output (launch_hw_emu.sh)
└── xcvp_qemu/              # Standalone QEMU launcher (for base XSA testing)
```

## Build Flow

The full flow has four stages. Each stage depends on the previous one.

### 1. Hardware (Vivado)

The base platform block design targets the XCVP1552 with CIPS, NOC, DDR4, clock wizard, and AXI interrupt controller. The XSA is exported with both hardware and hardware-emulation variants.

```bash
# To recreate the Vivado project from scratch:
cd base_platform
vivado -source recreate_project.tcl
```

Output: `base_platform/top_hw_hwemu.xsa`

### 2. Linux (PetaLinux)

Builds the kernel, rootfs, boot firmware, and QEMU DTBs from the hardware XSA.

```bash
cd versal_linux
./build_versal_linux.sh -n my_foe_flx -x ../base_platform/top_hw_hwemu.xsa
```

This script:
- Creates a PetaLinux project from the Versal template
- Imports the XSA hardware description
- Enables XRT, OpenAMP, and AI Engine drivers
- Configures ext4 rootfs with SD boot
- Builds the system, SDK, and sysroot
- Organizes artifacts into `my_foe_flx/sw/boot/` and `my_foe_flx/sw/image/`

Output: `versal_linux/my_foe_flx/sw/` (boot ELFs, DTBs, kernel, rootfs)

### 3. Platform (Vitis)

Generates the `.xpfm` extensible platform with XRT/ZOCL support and patches the export tree for hardware emulation.

```bash
cd /path/to/felix-155-platform
vitis -s gen_plat.py
```

The script:
- Creates the platform component with `generate_dtb=True` and `dt_zocl=1`
- Builds the platform
- **Post-build patches** the export directory:
  - Adds `linux.bif` template (required by v++ package for hw_emu)
  - Copies boot ELFs (`bl31.elf`, `u-boot.elf`, `plm.elf`, `psmfw.elf`, `pmc_cdo.bin`) to `sw/boot/`
  - Copies QEMU hardware DTBs and `BOOT_bh.bin` to `sw/qemu/`
  - Writes QEMU args with `-hw-dtb` enabled for the XCVP1552 memory layout

Output: `my_workspace/xcvp1552_custom_felix/export/xcvp1552_custom_felix/xcvp1552_custom_felix.xpfm`

After generation, verify the platform export has all required files:

```bash
ls my_workspace/xcvp1552_custom_felix/export/xcvp1552_custom_felix/sw/boot/
# linux.bif  system.dtb  bl31.elf  u-boot.elf  plm.elf  psmfw.elf  pmc_cdo.bin

ls my_workspace/xcvp1552_custom_felix/export/xcvp1552_custom_felix/sw/qemu/
# pmc_args.txt  qemu_args.txt  versal-qemu-multiarch-pmc.dtb  versal-qemu-multiarch-ps.dtb  BOOT_bh.bin
```

### 4. Application Build and HW Emulation

Builds the HLS kernel, links it against the platform, packages for emulation, and runs.

```bash
cd vadd_test

# Build everything (HLS kernel + host app + v++ link + v++ package)
make all

# Or run individual stages:
make xo        # HLS synthesis -> vadd_pl.xo
make link       # v++ link -> vadd.xsa
make host       # Cross-compile host application
make package    # v++ package -> package/launch_hw_emu.sh

# Run hardware emulation
cd package
./launch_hw_emu.sh
```

The test application (`vadd_pl`) performs a vector addition on 4096 elements via an AXI-connected HLS kernel at 300 MHz.

## Custom Board Notes

Since the XCVP1552 is not a standard evaluation board (VCK190/VEK280), several aspects require manual handling:

**BIF template:** The platform's `sw/boot/linux.bif` must use the Vitis `<tag,filename>` placeholder syntax for hw_emu boot image generation:
```
the_ROM_image:
{
  { load=0x1000, file=<dtb,system.dtb> }
  { core=a72-0, exception_level=el-3, trustzone, file=<atf,bl31.elf> }
  { core=a72-0, exception_level=el-2, load=0x8000000, file=<uboot,u-boot.elf> }
}
```

**QEMU hardware DTBs:** The `-hw-dtb` flag in the QEMU args files must be uncommented and point to the PetaLinux-generated DTBs (`versal-qemu-multiarch-pmc.dtb` / `versal-qemu-multiarch-ps.dtb`). Without this, QEMU defaults to VCK190 memory regions, which causes PMC boot hangs on the XCVP1552.

**Boot ELFs in platform export:** Vitis `set_boot_dir()` only references the source directory at build time; it does not copy ELF files into the platform export tree. The `gen_plat.py` post-build step handles this.

## Standalone QEMU Testing

To test the base XSA boot (without v++ / XRT) using the standalone QEMU launcher:

```bash
cd xcvp_qemu

# Ensure required files are present (copy from PetaLinux if needed):
#   versal-qemu-multiarch-ps.dtb, versal-qemu-multiarch-pmc.dtb,
#   qemu_boot.img, pmc_cdo.0.0.bin, BOOT_bh.bin, plm.elf

./run_qemu.sh
# Or: make run_qemu  (also connects to XSIM for co-simulation)
```

## Useful Commands

