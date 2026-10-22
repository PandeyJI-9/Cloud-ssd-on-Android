#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Automated Magisk / KernelSU Flashable ZIP Builder
# Bundles ARM64 AList, ARM64 Rclone, WebUI, and Magisk Metadata into Flashable ZIP
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}    Cloud SSD: Building Flashable Magisk Module      ${NC}"
echo -e "${GREEN}====================================================${NC}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build_magisk"
OUTPUT_ZIP="$ROOT_DIR/CloudSSD-TeraBox-v1.0.0.zip"

rm -rf "$BUILD_DIR" "$OUTPUT_ZIP"
mkdir -p "$BUILD_DIR/bin"
mkdir -p "$BUILD_DIR/scripts"
mkdir -p "$BUILD_DIR/webroot"
mkdir -p "$BUILD_DIR/META-INF/com/google/android"

# 1. Copy Module metadata and scripts
echo -e "${BLUE}[1/5] Copying module manifests and scripts...${NC}"
cp -f "$ROOT_DIR/magisk_module/module.prop" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/service.sh" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/customize.sh" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/uninstall.sh" "$BUILD_DIR/"
cp -rf "$ROOT_DIR/magisk_module/webroot/"* "$BUILD_DIR/webroot/"

# Helper scripts
cp -f "$ROOT_DIR/scripts/mount_terabox.sh" "$BUILD_DIR/scripts/mount.sh"
cp -f "$ROOT_DIR/scripts/unmount_terabox.sh" "$BUILD_DIR/scripts/unmount.sh"

# 2. Download Official Magisk update-binary and updater-script
echo -e "${BLUE}[2/5] Setting up Magisk META-INF installer...${NC}"
curl -sL --retry 3 --max-time 30 "https://cdn.jsdelivr.net/gh/topjohnwu/Magisk@master/scripts/module_installer.sh" \
    -o "$BUILD_DIR/META-INF/com/google/android/update-binary"

echo "#MAGISK" > "$BUILD_DIR/META-INF/com/google/android/updater-script"
chmod +x "$BUILD_DIR/META-INF/com/google/android/update-binary"

# 3. Download ARM64 AList Binary
echo -e "${BLUE}[3/5] Fetching official AList ARM64 static binary...${NC}"
TEMP_DL=$(mktemp -d)
curl -sL --retry 3 --max-time 120 -o "$TEMP_DL/alist.tar.gz" "https://github.com/AlistGo/alist/releases/latest/download/alist-linux-arm64.tar.gz"
tar -xzf "$TEMP_DL/alist.tar.gz" -C "$TEMP_DL"
mv "$TEMP_DL/alist" "$BUILD_DIR/bin/alist"
chmod 755 "$BUILD_DIR/bin/alist"

# 4. Download ARM64 Rclone Binary
echo -e "${BLUE}[4/5] Fetching official Rclone ARM64 static binary...${NC}"
curl -sL --retry 3 --max-time 120 -o "$TEMP_DL/rclone.zip" "https://downloads.rclone.org/rclone-current-linux-arm64.zip"
unzip -q "$TEMP_DL/rclone.zip" -d "$TEMP_DL"
find "$TEMP_DL" -type f -name rclone -exec mv {} "$BUILD_DIR/bin/rclone" \;
chmod 755 "$BUILD_DIR/bin/rclone"

rm -rf "$TEMP_DL"

# 5. Package into flashable ZIP
echo -e "${BLUE}[5/5] Packaging into flashable ZIP...${NC}"
cd "$BUILD_DIR"
find . -type f -name "*.sh" -exec chmod 755 {} \;
zip -r9 "$OUTPUT_ZIP" . >/dev/null

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}[✓] SUCCESS: Flashable Magisk Module Created!       ${NC}"
echo -e "Path: ${YELLOW}$OUTPUT_ZIP${NC}"
echo -e "Size: $(du -h "$OUTPUT_ZIP" | cut -f1)"
echo -e "${GREEN}====================================================${NC}"
