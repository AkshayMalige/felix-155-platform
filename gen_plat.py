import vitis
import os
import shutil

# --- Configuration ---
ROOT_DIR = os.path.abspath(os.getcwd())
PLATFORM_NAME = "xcvp1552_custom_felix"
WORKSPACE_DIR = os.path.join(ROOT_DIR, "my_workspace")

# Points to the XSA (Hardware Export)
HW_XSA = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")

# Points to the 'sw' folder created by the shell script
# IMPORTANT: Ensure 'system.dtb' is physically present in this directory!
BOOT_DIR = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/boot")
IMAGE_DIR = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/image")

# Clean previous workspace
if os.path.exists(WORKSPACE_DIR):
    shutil.rmtree(WORKSPACE_DIR)

client = vitis.create_client()
client.set_workspace(path=WORKSPACE_DIR)

# --- Create Platform Component ---
platform = client.create_platform_component(
    name=PLATFORM_NAME,
    hw_design=HW_XSA,
    os="linux",
    cpu="psv_cortexa72",
    domain_name="xrt_linux",
    generate_dtb=True, 
    advanced_options=client.create_advanced_options_dict(dt_zocl="1")
)

domain = platform.get_domain(name="xrt_linux")

# --- Set Artifact Directories ---
domain.set_boot_dir(path=BOOT_DIR)
domain.set_sd_dir(path=IMAGE_DIR)

# =============================================================================
# CRITICAL FIX START: Split QEMU Arguments for Versal Multi-Arch Emulation
# =============================================================================

# 1. Generate pmc_args.txt (Targeting MicroBlaze PMC)
# This fixes the "Boot Hang". We move all PMC/MicroBlaze binaries here.
pmc_args_content = f"""-M microblaze-fdt 
-device loader,file={BOOT_DIR}/plm.elf,cpu-num=0 
-device loader,file={BOOT_DIR}/psmfw.elf,cpu-num=0 
-device loader,file={BOOT_DIR}/pmc_cdo.bin,cpu-num=0 
-dtb {BOOT_DIR}/versal-qemu-multiarch-pmc.dtb 
"""

pmc_args_path = os.path.join(BOOT_DIR, "pmc_args.txt")
print(f"Writing PMC arguments to: {pmc_args_path}")
with open(pmc_args_path, "w") as f:
    f.write(pmc_args_content.replace('\n', ' '))

# 2. Generate qemu_args.txt (Targeting ARM Cortex-A72 PS)
# This fixes the "Missing ZOCL". We point to system.dtb instead of the generic one.
# We also use the correct machine type '-M xlnx-versal-virt' for ARM.
qemu_args_content = f"""-M xlnx-versal-virt 
-device loader,file={BOOT_DIR}/bl31.elf,cpu-num=0 
-device loader,file={BOOT_DIR}/u-boot.elf 
-device loader,file={IMAGE_DIR}/boot.scr,addr=0x20000000 
-dtb {BOOT_DIR}/system.dtb 
"""

qemu_args_path = os.path.join(BOOT_DIR, "qemu_args.txt")
print(f"Writing PS QEMU arguments to: {qemu_args_path}")
with open(qemu_args_path, "w") as f:
    f.write(qemu_args_content.replace('\n', ' '))

# =============================================================================
# CRITICAL FIX END
# =============================================================================

# --- Build ---
print("Building platform...")
platform.build()

print(f" Platform Generated at: {WORKSPACE_DIR}/{PLATFORM_NAME}/export/{PLATFORM_NAME}")
vitis.dispose()