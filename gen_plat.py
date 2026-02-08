import vitis
import os
import shutil

ROOT_DIR = os.path.abspath(os.getcwd())
PLATFORM_NAME = "xcvp1552_custom_flx"
WORKSPACE_DIR = os.path.join(ROOT_DIR, "vitis_workspace2")
HW_XSA  = os.path.join(ROOT_DIR, "base_platform/project_build/top_hw_hw_emu.xsa")
BOOT_DIR = os.path.join(ROOT_DIR, "vitis_sw_comp/boot")
IMAGE_DIR = os.path.join(ROOT_DIR, "vitis_sw_comp/image")

if os.path.exists(WORKSPACE_DIR):
    shutil.rmtree(WORKSPACE_DIR)

client = vitis.create_client()
client.set_workspace(path=WORKSPACE_DIR)

platform = client.create_platform_component(
    name=PLATFORM_NAME,
    hw_design=HW_XSA,
    os="linux",
    cpu="psv_cortexa72",
    domain_name="xrt_linux",
    generate_dtb=False,
    advanced_options=client.create_advanced_options_dict(dt_zocl="1")
)

domain = platform.get_domain(name="xrt_linux")
domain.set_boot_dir(path=BOOT_DIR)
domain.set_sd_dir(path=IMAGE_DIR)
domain.set_bif(path=os.path.join(BOOT_DIR, "linux.bif"))

platform.build()
print(f"[SUCCESS] Platform: {WORKSPACE_DIR}/{PLATFORM_NAME}/export/{PLATFORM_NAME}/{PLATFORM_NAME}.xpfm")
vitis.dispose()
