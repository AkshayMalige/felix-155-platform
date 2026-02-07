#!/bin/bash

# ==============================================================================
# Versal Linux Builder Script
# Automated PetaLinux 2025.2 flow for Custom Versal Platforms
# ==============================================================================

# Stop on error
set -e

# ================= Configuration =================
# Default values (can be overridden by arguments)
PROJECT_NAME=""
XSA_PATH=""
SKIP_BUILD=0

# Helper script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CFG_TOOL="${SCRIPT_DIR}/config"

# ================= Usage Function =================
usage() {
    echo "Usage: $0 -n <project_name> -x <xsa_path> [options]"
    echo ""
    echo "Required:"
    echo "  -n <name>      Name of the PetaLinux project to create"
    echo "  -x <path>      Absolute path to the hardware XSA file"
    echo ""
    echo "Options:"
    echo "  --skip-build   Configure project but skip build steps"
    echo "  -h             Show this help message"
    echo ""
    exit 1
}

# ================= Parse Arguments =================
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--name) PROJECT_NAME="$2"; shift ;;
        -x|--xsa) XSA_PATH=$(readlink -f "$2"); shift ;;
        --skip-build) SKIP_BUILD=1 ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

if [ -z "$PROJECT_NAME" ] || [ -z "$XSA_PATH" ]; then
    echo "Error: Project Name and XSA Path are required."
    usage
fi

if [ ! -f "$XSA_PATH" ]; then
    echo "Error: XSA file not found at $XSA_PATH"
    exit 1
fi

if [ ! -x "$CFG_TOOL" ]; then
    echo "Error: Config helper tool not found or not executable at $CFG_TOOL"
    exit 1
fi

echo "=========================================="
echo " Starting Versal Linux Build"
echo " Project: $PROJECT_NAME"
echo " XSA:     $XSA_PATH"
echo "=========================================="

# ================= 1. Create Project =================
if [ -d "$PROJECT_NAME" ]; then
    echo "Warning: Directory $PROJECT_NAME already exists."
    read -p "Do you want to delete it and start over? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 1
    fi
    rm -rf "$PROJECT_NAME"
fi

echo "[1/6] Creating PetaLinux Project..."
petalinux-create --type project --template versal --name "$PROJECT_NAME"
cd "$PROJECT_NAME"

# ================= 2. Import Hardware =================
echo "[2/6] Importing Hardware Configuration..."
petalinux-config --get-hw-description="$XSA_PATH" --silentconfig

# ================= 3. Configure Project =================
echo "[3/6] Applying Vitis/XRT configurations..."

ROOTFS_CFG="project-spec/configs/rootfs_config"
MAIN_CFG="project-spec/configs/config"

# --- RootFS: Enable XRT & ZOCL ---
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable xrt
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable xrt-dev
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable packagegroup-petalinux-openamp

# --- RootFS: Enable AI Engine Drivers ---
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable ai-engine-driver
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable ai-engine-driver-dev

# --- RootFS: System Utilities ---
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable dnf
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable libsysfs
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable sysfsutils-dev

# --- RootFS: SSH/Networking ---
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable openssh
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable openssh-ssh
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable openssh-sshd
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable openssh-sftp-server

# --- RootFS: Disable Dropbear ---
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --disable dropbear
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --disable packagegroup-core-ssh-dropbear

# --- Main Config: Boot & RootFS Settings ---
# 1. Image Packaging Configuration
"$CFG_TOOL" --file "$MAIN_CFG" --keep-case --disable CONFIG_SUBSYSTEM_ROOTFS_INITRAMFS
"$CFG_TOOL" --file "$MAIN_CFG" --keep-case --enable CONFIG_SUBSYSTEM_ROOTFS_EXT4
"$CFG_TOOL" --file "$MAIN_CFG" --set-str CONFIG_SUBSYSTEM_RFS_FORMATS "ext4 tar.gz"
"$CFG_TOOL" --file "$MAIN_CFG" --set-str CONFIG_SUBSYSTEM_SDROOT_DEV "/dev/mmcblk0p2"

# 2. DTG Settings > Kernel Bootargs
"$CFG_TOOL" --file "$MAIN_CFG" --keep-case --disable CONFIG_SUBSYSTEM_BOOTARGS_AUTO
"$CFG_TOOL" --file "$MAIN_CFG" --set-str CONFIG_SUBSYSTEM_USER_CMDLINE "console=ttyAMA0 earlycon=pl011,mmio32,0xFF010000,115200n8 clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait cma=512M cpuidle.off=1"
# --- Main Config: General ---
"$CFG_TOOL" --file "$MAIN_CFG" --keep-case --enable CONFIG_YOCTO_BUILDTOOLS_EXTENDED

# Apply changes
echo "Applying configurations (silentconfig)..."
petalinux-config --silentconfig
petalinux-config -c rootfs --silentconfig

if [ "$SKIP_BUILD" -eq 1 ]; then
    echo "Configuration complete. Skipping build as requested."
    exit 0
fi

# ================= 4. Build System =================
echo "[4/6] Building PetaLinux System (Kernel, RootFS, Bootloader)..."
petalinux-build

# ================= 5. Build SDK (Sysroot) =================
echo "[5/6] Building SDK (Sysroot) for Host App Compilation..."
petalinux-build --sdk
petalinux-package --sysroot

# ================= 6. Package Boot & SD Image =================
echo "[6/6] Packaging BOOT.BIN..."
petalinux-package --boot --plm --psmfw --u-boot --dtb --force

echo "[6b/6] Generating QEMU SD Card Image (WIC)..."


# 1. Generate the partitioned WIC image
petalinux-package --wic --bootfiles "BOOT.BIN boot.scr Image system.dtb" --rootfs-file images/linux/rootfs.ext4

WIC_FILE="images/linux/petalinux-sdimage.wic"
ROOTFS_FILE="images/linux/rootfs.ext4"
FINAL_QEMU_IMG="/home/synthara/VersalPrjs/felix/AM_felix0602/felix-155-platform/xcvp_qemu/qemu_boot.img"

# 2. Resize to 8GB (Next power of 2 for QEMU)
echo "Resizing image to 8GB..."
qemu-img resize "$WIC_FILE" 8G

# 3. FIX: Manually Inject RootFS (Solves "No Init Found" Kernel Panic)
echo "Injecting RootFS into Partition 2..."
# Detect offset of Partition 2 (usually p2 or wic2)
START_SECTOR=$(fdisk -l "$WIC_FILE" | grep -E "wic2|p2" | awk '{print $2}')
if [ -z "$START_SECTOR" ]; then
    START_SECTOR=4194312 # Fallback to standard Versal offset
fi
echo "Writing RootFS at sector $START_SECTOR..."
dd if="$ROOTFS_FILE" of="$WIC_FILE" bs=512 seek="$START_SECTOR" conv=notrunc status=none

# 4. Deploy to QEMU directory
echo "Deploying fixed image to $FINAL_QEMU_IMG..."
cp "$WIC_FILE" "$FINAL_QEMU_IMG"

# ================= 7. Organize Artifacts =================
echo "[7/7] Organizing Artifacts into 'sw' directory..."
SW_DIR="$PWD/sw"
mkdir -p "$SW_DIR/boot"
mkdir -p "$SW_DIR/sd_dir"
mkdir -p "$SW_DIR/sw_comp"

echo "Copying boot files..."
find images/linux/ -maxdepth 1 -name "*.elf" -exec cp {} "$SW_DIR/boot/" \;
find images/linux/ -maxdepth 1 -name "*.img" -exec cp {} "$SW_DIR/boot/" \;
find images/linux/ -maxdepth 1 -name "*.dtb" -exec cp {} "$SW_DIR/boot/" \;

echo "Copying SD directory files..."
if [ -f "images/linux/boot.scr" ]; then
    cp images/linux/boot.scr "$SW_DIR/sd_dir/"
fi
# Also copy our fixed image here for reference
cp "$WIC_FILE" "$SW_DIR/sd_dir/qemu_sd.img"

echo "Copying SW components..."
if [ -f "images/linux/Image" ]; then
    cp images/linux/Image "$SW_DIR/sw_comp/"
fi
if [ -f "images/linux/rootfs.ext4" ]; then
    cp images/linux/rootfs.ext4 "$SW_DIR/sw_comp/"
fi

if [ -d "images/linux/sdk" ]; then
    find images/linux/sdk/ -maxdepth 1 -name "environment-setup-*" -exec cp {} "$SW_DIR/sw_comp/" \;
    find images/linux/sdk/ -maxdepth 1 -name "version-*" -exec cp {} "$SW_DIR/sw_comp/" \;
    
    if [ -d "images/linux/sdk/sysroots" ]; then
        echo "Installing sysroot to $SW_DIR/sw_comp/sysroots..."
        cp -r images/linux/sdk/sysroots "$SW_DIR/sw_comp/"
    fi
fi

echo "=========================================="
echo " Build Success!"
echo " QEMU Image Ready: $FINAL_QEMU_IMG"
echo "=========================================="