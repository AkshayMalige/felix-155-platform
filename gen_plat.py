import vitis
import os
import sys
import shutil

# ==============================================================================
# Configuration
# ==============================================================================
ROOT_DIR = os.getcwd()
PLATFORM_NAME = "xcvp1552_custom_flx"
WORKSPACE_DIR = os.path.join(ROOT_DIR, "vitis_workspace")

# Input XSA Files
HW_XSA  = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")
EMU_XSA = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")

# Software Components
BOOT_DIR = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/boot")
SD_DIR   = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/sd_dir")

# Emulation Assets
QEMU_DATA_DIR = os.path.join(ROOT_DIR, "base_platform/qemu_data")

# Output Args Files (We will write these dynamically)
PS_ARGS_FILE  = os.path.join(ROOT_DIR, "ps_args.txt")
PMC_ARGS_FILE = os.path.join(ROOT_DIR, "pmc_args.txt")

# ==============================================================================
# Validation
# ==============================================================================
if not os.path.exists(QEMU_DATA_DIR):
    print(f"[ERROR] QEMU Data directory missing: {QEMU_DATA_DIR}")
    sys.exit(1)

# ==============================================================================
# Dynamic Args File Generation (THE FIX)
# 1. We embed the ABSOLUTE PATH to QEMU_DATA_DIR to avoid <qemu_data> errors.
# 2. We add -machine-path /tmp to fix the socket communication deadlock.
# ==============================================================================
print("[INFO] Generating QEMU Argument files with absolute paths...")

# 1. PS (AArch64) Arguments
ps_args_content = f"""-M
arm-generic-fdt
-display
none
-machine-path
/tmp
-serial
null
-serial
null
-serial
mon:stdio
-serial
null
-boot
mode=5
-hw-dtb
{os.path.join(QEMU_DATA_DIR, 'versal-qemu-multiarch-ps.dtb')}
"""

# 2. PMC (MicroBlaze) Arguments
pmc_args_content = f"""-M
microblaze-fdt
-display
none
-machine-path
/tmp
-device
loader,addr=0xf0000000,data=0xba020004,data-len=4
-device
loader,addr=0xf0000004,data=0xb800fffc,data-len=4
-device
loader,file={os.path.join(QEMU_DATA_DIR, 'pmc_cdo.0.0.bin')},addr=0xf2000000
-device
loader,file={os.path.join(QEMU_DATA_DIR, 'BOOT_bh.bin')},addr=0xf201e000,force-raw=on
-device
loader,file={os.path.join(QEMU_DATA_DIR, 'plm.elf')}
-hw-dtb
{os.path.join(QEMU_DATA_DIR, 'versal-qemu-multiarch-pmc.dtb')}
-device
loader,addr=0xF1110624,data=0x0,data-len=4
-device
loader,addr=0xF1110620,data=0x1,data-len=4
"""

# Write files to disk
with open(PS_ARGS_FILE, "w") as f:
    f.write(ps_args_content)

with open(PMC_ARGS_FILE, "w") as f:
    f.write(pmc_args_content)

# ==============================================================================
# Platform Creation
# ==============================================================================
print(f"[INFO] Initializing Vitis in: {WORKSPACE_DIR}")
client = vitis.create_client()
client.set_workspace(path=WORKSPACE_DIR)

try:
    client.delete_component(name=PLATFORM_NAME)
    print(f"[INFO] Deleted existing component: {PLATFORM_NAME}")
except:
    pass

print(f"[INFO] Creating Platform Component...")
# NOTE: Set generate_dtb=False because we are providing our own custom DTB via args
# If True, Vitis might override our PS DTB with a generic one.
platform = client.create_platform_component(
    name=PLATFORM_NAME,
    hw_design=HW_XSA,
    emu_design=EMU_XSA,   
    os="linux",
    cpu="psv_cortexa72",
    domain_name="linux_psv_cortexa72",
    generate_dtb=False, 
    advanced_options=client.create_advanced_options_dict(dt_zocl="1", dt_overlay="0")
)

domain = platform.get_domain(name="linux_psv_cortexa72")

print("[INFO] Configuring Linux Domain...")
domain.set_boot_dir(path=BOOT_DIR)
if os.path.exists(SD_DIR) and os.listdir(SD_DIR):
    domain.set_sd_dir(path=SD_DIR)

domain.generate_bif()

# Register files (still good practice for packaging)
domain.set_qemu_data(path=QEMU_DATA_DIR)

# Apply the files we just generated
domain.set_qemu_args(qemu_option="PS", path=PS_ARGS_FILE)
domain.set_qemu_args(qemu_option="PMU", path=PMC_ARGS_FILE)

print("[INFO] Building Platform...")
platform.build()
print(f"[SUCCESS] Platform built at: {WORKSPACE_DIR}/{PLATFORM_NAME}/export/{PLATFORM_NAME}")