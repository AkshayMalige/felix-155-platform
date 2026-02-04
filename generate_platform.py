import vitis
import os
import sys
import shutil


ROOT_DIR = os.getcwd()

HW_XSA  = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")
EMU_XSA = os.path.join(ROOT_DIR, "base_platform/top_hw_hwemu.xsa")

BOOT_DIR = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/boot")
SD_DIR   = os.path.join(ROOT_DIR, "versal_linux/my_foe_flx/sw/sd_dir")

WORKSPACE_DIR = os.path.join(ROOT_DIR, "vitis_workspace")

if not os.path.exists(HW_XSA):
    print(f"[ERROR] HW XSA not found: {HW_XSA}")
    sys.exit(1)
if not os.path.exists(EMU_XSA):
    print(f"[ERROR] EMU XSA not found: {EMU_XSA}")
    sys.exit(1)



qemu_args_path = os.path.join(ROOT_DIR, "fixed_qemu_args.txt")
qemu_args_content = """-M
arm-generic-fdt
-display
none
-serial
mon:stdio
-serial
null
-device
loader,file=bl31.elf,cpu-num=0
-device
loader,file=u-boot.elf
-boot
mode=5
"""
with open(qemu_args_path, "w") as f:
    f.write(qemu_args_content)

PLATFORM_NAME = "xcvp1552_custom_flx"

if not os.path.exists(WORKSPACE_DIR):
    os.makedirs(WORKSPACE_DIR)

print(f"[INFO] Initializing Vitis in: {WORKSPACE_DIR}")
client = vitis.create_client()
client.set_workspace(path=WORKSPACE_DIR)

try:
    client.delete_component(name=PLATFORM_NAME)
except:
    pass

print(f"[INFO] Creating Platform...")
# Use advanced options to enable ZOCL and set overlay to 0
adv_opts = client.create_advanced_options_dict(dt_zocl="1", dt_overlay="0")

# Create platform component with explicit domain name and DTB generation
platform = client.create_platform_component(
    name=PLATFORM_NAME,
    hw_design=HW_XSA,
    emu_design=EMU_XSA,   
    os="linux",
    cpu="psv_cortexa72",
    domain_name="linux_psv_cortexa72",
    generate_dtb=True,
    advanced_options=adv_opts
)

domain = platform.get_domain(name="linux_psv_cortexa72")

print("[INFO] Configuring Linux Domain...")
# Match the working manual platform's configuration steps
domain.set_boot_dir(path=BOOT_DIR)
domain.generate_bif()
domain.recompile_dtb()

# Set custom QEMU args using the correct method and option
domain.set_qemu_args(qemu_option="PS", path=qemu_args_path)

print("[INFO] Building Platform...")
platform.build()

print("="*60)
print(f"[SUCCESS] Platform built successfully!")
print(f"Location: {WORKSPACE_DIR}/{PLATFORM_NAME}/export/{PLATFORM_NAME}")
print("="*60)
