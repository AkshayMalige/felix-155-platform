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

HW_XSA  = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")
EMU_XSA = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")


BOOT_DIR = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/boot")
SD_DIR   = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/sd_dir")


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


print(f"[INFO] Creating Platform Component...")


platform = client.create_platform_component(
    name=PLATFORM_NAME,
    hw_design=HW_XSA,
    emu_design=EMU_XSA,   
    os="linux",
    cpu="psv_cortexa72",
    domain_name="linux_psv_cortexa72",
    generate_dtb=True,  
    advanced_options=client.create_advanced_options_dict(
        dt_zocl="1",   
        dt_overlay="0" 
    )
)

domain = platform.get_domain(name="linux_psv_cortexa72")


print("[INFO] Configuring Linux Domain...")

domain.set_boot_dir(path=BOOT_DIR)
if os.path.exists(SD_DIR) and os.listdir(SD_DIR):
    domain.set_sd_dir(path=SD_DIR)


print("[INFO] Generating BIF...")
domain.generate_bif()

print("[INFO] Building Platform...")
platform.build()

print(f"[SUCCESS] Platform built at: {WORKSPACE_DIR}/{PLATFORM_NAME}/export/{PLATFORM_NAME}")
print("   export TMPDIR=/tmp")
print("----------------------------------------------------------------")


