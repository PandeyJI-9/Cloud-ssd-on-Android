#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Build Ultra-Lightweight Magisk Module ZIP (< 50 KB)
# Solves Exit 137 OOM on low-memory devices
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build_lite"
OUTPUT_ZIP="$ROOT_DIR/CloudSSD-TeraBox-v1.0.1-Lite.zip"

rm -rf "$BUILD_DIR" "$OUTPUT_ZIP"
mkdir -p "$BUILD_DIR/scripts"
mkdir -p "$BUILD_DIR/webroot"
mkdir -p "$BUILD_DIR/META-INF/com/google/android"

# 1. Copy manifests and scripts
cp -f "$ROOT_DIR/magisk_module/module.prop" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/service.sh" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/customize.sh" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/uninstall.sh" "$BUILD_DIR/"
cp -rf "$ROOT_DIR/magisk_module/webroot/"* "$BUILD_DIR/webroot/"
cp -f "$ROOT_DIR/scripts/mount_terabox.sh" "$BUILD_DIR/scripts/mount.sh"
cp -f "$ROOT_DIR/scripts/unmount_terabox.sh" "$BUILD_DIR/scripts/unmount.sh"

# 2. Setup META-INF
curl -sL --retry 3 --max-time 30 "https://cdn.jsdelivr.net/gh/topjohnwu/Magisk@master/scripts/module_installer.sh" \
    -o "$BUILD_DIR/META-INF/com/google/android/update-binary"
echo "#MAGISK" > "$BUILD_DIR/META-INF/com/google/android/updater-script"
chmod +x "$BUILD_DIR/META-INF/com/google/android/update-binary"

# 3. Zip up
cd "$BUILD_DIR"
find . -type f -name "*.sh" -exec chmod 755 {} \;
zip -r9 "$OUTPUT_ZIP" . >/dev/null

echo -e "${GREEN}[✓] Lightweight Flashable ZIP Created: $OUTPUT_ZIP${NC}"
echo -e "${BLUE}Size: $(du -h "$OUTPUT_ZIP" | cut -f1)${NC}"
