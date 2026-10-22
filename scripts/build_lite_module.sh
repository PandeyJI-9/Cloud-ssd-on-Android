#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Build HyperOS-Safe Lightweight Magisk Module (< 30 KB)
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build_hyperos_safe"
OUTPUT_ZIP="$ROOT_DIR/CloudSSD-TeraBox-v1.0.2-HyperOS-Safe.zip"

rm -rf "$BUILD_DIR" "$OUTPUT_ZIP"
mkdir -p "$BUILD_DIR/webroot"
mkdir -p "$BUILD_DIR/META-INF/com/google/android"

# 1. Copy manifests and scripts
cp -f "$ROOT_DIR/magisk_module/module.prop" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/service.sh" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/customize.sh" "$BUILD_DIR/"
cp -f "$ROOT_DIR/magisk_module/uninstall.sh" "$BUILD_DIR/"
cp -rf "$ROOT_DIR/magisk_module/webroot/"* "$BUILD_DIR/webroot/"

# 2. Setup META-INF
curl -sL --retry 3 --max-time 30 "https://cdn.jsdelivr.net/gh/topjohnwu/Magisk@master/scripts/module_installer.sh" \
    -o "$BUILD_DIR/META-INF/com/google/android/update-binary"
echo "#MAGISK" > "$BUILD_DIR/META-INF/com/google/android/updater-script"
chmod +x "$BUILD_DIR/META-INF/com/google/android/update-binary"

# 3. Zip up
cd "$BUILD_DIR"
find . -type f -name "*.sh" -exec chmod 755 {} \;
zip -r9 "$OUTPUT_ZIP" . >/dev/null

echo -e "${GREEN}[✓] HyperOS Safe ZIP Created: $OUTPUT_ZIP${NC}"
echo -e "${BLUE}Size: $(du -h "$OUTPUT_ZIP" | cut -f1)${NC}"
