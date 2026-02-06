import vitis
import os
import sys
import shutil

# ==============================================================================
# Configuration
# ==============================================================================
ROOT_DIR = os.getcwd()
PLATFORM_NAME = "xcvp1552_custom_flx"
WORKSPACE_DIR = os.path.join(ROOT_DIR, "my_workspace")

# Input XSA Files (Ensure these are exported with Emulation enabled in Vivado!)
HW_XSA  = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")
EMU_XSA = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")

# Software Components (Linux Common Image or PetaLinux output)
# Note: For Versal, Vitis extracts PLM/Bootloaders from the XSA usually.
# You only strictly need the OS components here.
BOOT_DIR = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/boot")
SD_DIR   = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/sd_dir")

# ==============================================================================
# 1. Clean Workspace
# ==============================================================================
if os.path.exists(WORKSPACE_DIR):
    print(f"[INFO] Cleaning workspace: {WORKSPACE_DIR}")
    # Optional: Backup instead of delete if you prefer
    # shutil.rmtree(WORKSPACE_DIR) 

print(f"[INFO] Initializing Vitis in: {WORKSPACE_DIR}")
client = vitis.create_client()
client.set_workspace(path=WORKSPACE_DIR)

try:
    client.delete_component(name=PLATFORM_NAME)
    print(f"[INFO] Deleted existing component: {PLATFORM_NAME}")
except:
    pass

# ==============================================================================
# 2. Create Platform Component (The Fix)
# ==============================================================================
print(f"[INFO] Creating Platform Component...")

# CRITICAL CHANGE: generate_dtb=True
# Vitis will parse the XSA and create a 'system.dtb' that includes your
# custom IP addresses and the ZOCL driver node required for XRT.
platform = client.create_platform_component(
    name=PLATFORM_NAME,
    hw_design=HW_XSA,
    emu_design=EMU_XSA,   
    os="linux",
    cpu="psv_cortexa72",
    domain_name="linux_psv_cortexa72",
    generate_dtb=True,  # <--- THIS IS KEY for Custom Boards
    advanced_options=client.create_advanced_options_dict(
        dt_zocl="1",    # Generate Device Tree node for XRT
        dt_overlay="0"  # 0 = Flat tree (simpler for QEMU), 1 = Overlay
    )
)

domain = platform.get_domain(name="linux_psv_cortexa72")

# ==============================================================================
# 3. Configure Domain
# ==============================================================================
print("[INFO] Configuring Linux Domain...")

# Set the software artifacts
domain.set_boot_dir(path=BOOT_DIR)
if os.path.exists(SD_DIR) and os.listdir(SD_DIR):
    domain.set_sd_dir(path=SD_DIR)

# DO NOT manually set set_qemu_args unless you have a very specific non-standard requirement.
# Vitis will auto-generate qemu_args.txt pointing to the correct dtb and boot mode.

print("[INFO] Generating BIF...")
domain.generate_bif()

print("[INFO] Building Platform...")
platform.build()

print(f"[SUCCESS] Platform built at: {WORKSPACE_DIR}/{PLATFORM_NAME}/export/{PLATFORM_NAME}")
print("----------------------------------------------------------------")
print("NEXT STEPS FOR HW_EMU:")
print("1. Do NOT rely on the script for the '/tmp' socket fix.")
print("2. Instead, before running 'vitis' or 'launch_hw_emu', run this in your terminal:")
print("   export TMPDIR=/tmp")
print("   (This shortens the socket paths without breaking the generated QEMU args)")
print("----------------------------------------------------------------")


