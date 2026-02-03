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

# --- RootFS: SSH/Networking (Standard for Vitis) ---
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable openssh
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable openssh-ssh
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable openssh-sshd
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --enable openssh-sftp-server

# --- RootFS: Disable Dropbear (Conflict with OpenSSH) ---
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --disable dropbear
"$CFG_TOOL" --file "$ROOTFS_CFG" --keep-case --disable packagegroup-core-ssh-dropbear

# --- Main Config: Boot & RootFS Settings (User Requested) ---
# 1. Image Packaging Configuration
"$CFG_TOOL" --file "$MAIN_CFG" --keep-case --disable CONFIG_SUBSYSTEM_ROOTFS_INITRAMFS
"$CFG_TOOL" --file "$MAIN_CFG" --keep-case --enable CONFIG_SUBSYSTEM_ROOTFS_EXT4
"$CFG_TOOL" --file "$MAIN_CFG" --set-str CONFIG_SUBSYSTEM_RFS_FORMATS "ext4 tar.gz"
"$CFG_TOOL" --file "$MAIN_CFG" --set-str CONFIG_SUBSYSTEM_SDROOT_DEV "/dev/mmcblk1p2"

# 2. DTG Settings > Kernel Bootargs
"$CFG_TOOL" --file "$MAIN_CFG" --keep-case --disable CONFIG_SUBSYSTEM_BOOTARGS_AUTO
"$CFG_TOOL" --file "$MAIN_CFG" --set-str CONFIG_SUBSYSTEM_USER_CMDLINE "console=ttyAMA0 earlycon=pl011,mmio32,0xFF010000,115200n8 clk_ignore_unused root=/dev/mmcblk1p2 rw rootwait cma=512M"

# --- Main Config: General ---
"$CFG_TOOL" --file "$MAIN_CFG" --keep-case --enable CONFIG_YOCTO_BUILDTOOLS_EXTENDED

# Apply changes
echo "Applying configurations (silentconfig)..."
petalinux-config --silentconfig
petalinux-config -c rootfs --silentconfig

if [ "$SKIP_BUILD" -eq 1 ]; then
    echo "Configuration complete. Skipping build as requested."
    echo "You can now run 'petalinux-build' manually inside $PROJECT_NAME"
    exit 0
fi

# # ================= 4. Build System =================
# echo "[4/6] Building PetaLinux System (Kernel, RootFS, Bootloader)..."
# petalinux-build

# # ================= 5. Build SDK (Sysroot) =================
# echo "[5/6] Building SDK (Sysroot) for Host App Compilation..."
# petalinux-build --sdk
# petalinux-package --sysroot

# # ================= 6. Package Boot Image =================
# echo "[6/6] Packaging BOOT.BIN..."
# petalinux-package --boot --plm --psmfw --u-boot --dtb --force

# # ================= 7. Organize Artifacts =================
# echo "[7/7] Organizing Artifacts into 'sw' directory..."
# SW_DIR="$PWD/sw"
# mkdir -p "$SW_DIR/boot"
# mkdir -p "$SW_DIR/sd_dir"
# mkdir -p "$SW_DIR/sw_comp"

# echo "Copying boot files..."
# # sw/boot: Copy all .elf, .img, .dtb files
# find images/linux/ -maxdepth 1 -name "*.elf" -exec cp {} "$SW_DIR/boot/" \;
# find images/linux/ -maxdepth 1 -name "*.img" -exec cp {} "$SW_DIR/boot/" \;
# find images/linux/ -maxdepth 1 -name "*.dtb" -exec cp {} "$SW_DIR/boot/" \;

# echo "Copying SD directory files..."
# # sw/sd_dir: Copy boot.scr
# if [ -f "images/linux/boot.scr" ]; then
#     cp images/linux/boot.scr "$SW_DIR/sd_dir/"
# fi

# echo "Copying SW components..."
# # sw/sw_comp: Copy 'Image', 'rootfs.ext4'
# if [ -f "images/linux/Image" ]; then
#     cp images/linux/Image "$SW_DIR/sw_comp/"
# fi
# if [ -f "images/linux/rootfs.ext4" ]; then
#     cp images/linux/rootfs.ext4 "$SW_DIR/sw_comp/"
# fi

# # sw/sw_comp: Copy environment-setup-*, version-*, and install sysroot
# if [ -d "images/linux/sdk" ]; then
#     find images/linux/sdk/ -maxdepth 1 -name "environment-setup-*" -exec cp {} "$SW_DIR/sw_comp/" \;
#     find images/linux/sdk/ -maxdepth 1 -name "version-*" -exec cp {} "$SW_DIR/sw_comp/" \;
    
#     if [ -d "images/linux/sdk/sysroots" ]; then
#         echo "Installing sysroot to $SW_DIR/sw_comp/sysroots..."
#         cp -r images/linux/sdk/sysroots "$SW_DIR/sw_comp/"
#     fi
# fi

# echo "=========================================="
# echo " Build Success!"
# echo "=========================================="
# echo "Artifacts organized in: $SW_DIR"
# echo "  - Boot:        $SW_DIR/boot"
# echo "  - SD Dir:      $SW_DIR/sd_dir"
# echo "  - SW Comp:     $SW_DIR/sw_comp"
# echo "=========================================="
