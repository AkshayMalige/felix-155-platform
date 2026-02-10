import vitis
import os
import shutil

# --- Configuration ---
ROOT_DIR = os.path.abspath(os.getcwd())
PLATFORM_NAME = "xcvp1552_custom_felix"
WORKSPACE_DIR = os.path.join(ROOT_DIR, "my_workspace")

# Separate HW and HW-EMU XSAs (required for co-simulation to work)
HW_XSA = os.path.join(ROOT_DIR, "base_platform/top_hw.xsa")
EMU_XSA = os.path.join(ROOT_DIR, "base_platform/top_hwemu.xsa")

# PetaLinux output directories
BOOT_DIR = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/boot")
IMAGE_DIR = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/image")
PETALNX_IMAGES = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/images/linux")

# Clean previous workspace
if os.path.exists(WORKSPACE_DIR):
    shutil.rmtree(WORKSPACE_DIR)

client = vitis.create_client()
client.set_workspace(path=WORKSPACE_DIR)

# --- Create Platform Component ---
# Provide both hw_design and emu_design for proper co-simulation support
advanced_options = client.create_advanced_options_dict(dt_zocl="1", dt_overlay="0")

platform = client.create_platform_component(
    name=PLATFORM_NAME,
    hw_design=HW_XSA,
    emu_design=EMU_XSA,
    os="linux",
    cpu="psv_cortexa72",
    domain_name="xrt_linux",
    generate_dtb=True,
    advanced_options=advanced_options
)

domain = platform.get_domain(name="xrt_linux")

# --- generate_bif() MUST be called before set_boot_dir() ---
# This generates the linux.bif template with correct boot/ prefix paths
domain.generate_bif()

# --- Set Artifact Directories ---
domain.set_boot_dir(path=BOOT_DIR)
domain.set_sd_dir(path=IMAGE_DIR)

# --- Build ---
print("Building platform...")
platform.build()

# =============================================================================
# POST-BUILD: Ensure boot ELFs are in the exported platform tree
# =============================================================================
EXPORT_DIR = os.path.join(
    WORKSPACE_DIR, PLATFORM_NAME, "export", PLATFORM_NAME
)
PLAT_BOOT = os.path.join(EXPORT_DIR, "sw", "boot")
PLAT_SW = os.path.join(EXPORT_DIR, "sw")

# Copy boot ELFs to sw/boot/ (set_boot_dir only references, doesn't copy)
boot_files = ["bl31.elf", "u-boot.elf"]
for fname in boot_files:
    src = os.path.join(BOOT_DIR, fname)
    dst = os.path.join(PLAT_BOOT, fname)
    if os.path.isfile(src) and not os.path.isfile(dst):
        shutil.copy2(src, dst)
        print(f"[patch] Copied {fname} -> sw/boot/")

# Also copy to sw/ root (v++ resolves some paths against sw/ directly)
for fname in ["system.dtb", "bl31.elf", "u-boot.elf", "plm.elf", "psmfw.elf", "pmc_cdo.bin"]:
    src = os.path.join(PLAT_BOOT, fname)
    if not os.path.isfile(src):
        src = os.path.join(BOOT_DIR, fname)
    dst = os.path.join(PLAT_SW, fname)
    if os.path.isfile(src) and not os.path.isfile(dst):
        shutil.copy2(src, dst)
        print(f"[patch] Copied {fname} -> sw/")

print(f"\nPlatform generated at: {EXPORT_DIR}")
vitis.dispose()
