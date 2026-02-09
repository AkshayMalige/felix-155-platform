import vitis
import os
import shutil

# --- Configuration ---
ROOT_DIR = os.path.abspath(os.getcwd())
PLATFORM_NAME = "xcvp1552_custom_flx"
WORKSPACE_DIR = os.path.join(ROOT_DIR, "my_workspace")

# Points to the XSA (Hardware Export)
HW_XSA = os.path.join(ROOT_DIR, "base_platform/project_build/top_hw_hw_emu.xsa")

# Points to the 'sw' folder created by the shell script
# Note: Ensure these paths match where build_versal_linux.sh saved them!
BOOT_DIR = os.path.join(ROOT_DIR, "petalinux_project_name/sw/boot")
IMAGE_DIR = os.path.join(ROOT_DIR, "petalinux_project_name/sw/image")

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
    generate_dtb=True, # Let Vitis generate the standard DTB flow if needed, or set False if using PetaLinux system.dtb exclusively
    advanced_options=client.create_advanced_options_dict(dt_zocl="1")
)

domain = platform.get_domain(name="xrt_linux")

# --- Set Artifact Directories ---
# Vitis picks up plm.elf, psmfw.elf, u-boot.elf, etc from here
domain.set_boot_dir(path=BOOT_DIR)
# Vitis picks up Image, rootfs.ext4, boot.scr from here
domain.set_sd_dir(path=IMAGE_DIR)

# --- CRITICAL: QEMU Arguments for Custom Boards ---
# We must explicitly tell QEMU where to find the bootloaders and DTBs
# because it doesn't know the memory map of your custom XCVP1552.
qemu_args = f"""
-M microblaze-fdt 
-device loader,file={BOOT_DIR}/plm.elf,cpu-num=0 
-device loader,file={BOOT_DIR}/psmfw.elf,cpu-num=0 
-device loader,file={BOOT_DIR}/pmc_cdo.bin,cpu-num=0 
-device loader,file={BOOT_DIR}/bl31.elf,cpu-num=0 
-device loader,file={BOOT_DIR}/u-boot.elf 
-device loader,file={IMAGE_DIR}/boot.scr,addr=0x20000000 
-dtb {BOOT_DIR}/versal-qemu-multiarch-pmc.dtb 
-dtb {BOOT_DIR}/versal-qemu-multiarch-ps.dtb 
"""

# Apply the arguments to the platform
status = platform.add_qemu_args(qemu_args)

# Build
print("Building platform...")
platform.build()

print(f"[SUCCESS] Platform Generated at: {WORKSPACE_DIR}/{PLATFORM_NAME}/export/{PLATFORM_NAME}")
vitis.dispose()