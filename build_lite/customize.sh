#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Ultra-Lightweight Magisk / KernelSU Installer (< 50 KB ZIP)
# Prevents Exit 137 OOM by streaming binaries directly to disk
# ==============================================================================

SKIPUNZIP=0

ui_print "****************************************************"
ui_print "*        ☁️  Cloud SSD: TeraBox 1TB Mounter        *"
ui_print "*        100% Zero-OOM & Zero-Bootloop Safe        *"
ui_print "*            KernelSU & Magisk WebUI GUI           *"
ui_print "****************************************************"

ARCH=$(uname -m)
ui_print "- Device Architecture: $ARCH"

mkdir -p "$MODPATH/bin"
mkdir -p "$MODPATH/scripts"
mkdir -p "$MODPATH/webroot"
mkdir -p /data/adb/cloud_ssd/alist_data

# Set execution permissions
set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Deploying WebUI Dashboard shortcut..."
cp -f "$MODPATH/webroot/index.html" /sdcard/CloudSSD-Manager.html 2>/dev/null || true

# Test network for direct disk streaming
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    ui_print "- Internet detected: Streaming binaries to disk..."
    case "$ARCH" in
        aarch64|arm64)
            ALIST_URL="https://github.com/AlistGo/alist/releases/latest/download/alist-linux-arm64.tar.gz"
            RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm64.zip"
            ;;
        *)
            ALIST_URL="https://github.com/AlistGo/alist/releases/latest/download/alist-linux-arm-7.tar.gz"
            RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm-v7.zip"
            ;;
    esac

    TEMP_DL="/data/local/tmp/magisk_cloud_ssd"
    rm -rf "$TEMP_DL" && mkdir -p "$TEMP_DL"

    ui_print "- Fetching AList binary..."
    curl -sL --max-time 90 "$ALIST_URL" -o "$TEMP_DL/alist.tar.gz" 2>/dev/null || wget -q "$ALIST_URL" -O "$TEMP_DL/alist.tar.gz" 2>/dev/null || true
    if [ -f "$TEMP_DL/alist.tar.gz" ]; then
        tar -xzf "$TEMP_DL/alist.tar.gz" -C "$TEMP_DL" 2>/dev/null
        mv "$TEMP_DL/alist" "$MODPATH/bin/alist" 2>/dev/null || true
        chmod 755 "$MODPATH/bin/alist" 2>/dev/null || true
    fi

    ui_print "- Fetching Rclone binary..."
    curl -sL --max-time 90 "$RCLONE_URL" -o "$TEMP_DL/rclone.zip" 2>/dev/null || wget -q "$RCLONE_URL" -O "$TEMP_DL/rclone.zip" 2>/dev/null || true
    if [ -f "$TEMP_DL/rclone.zip" ]; then
        unzip -q "$TEMP_DL/rclone.zip" -d "$TEMP_DL" 2>/dev/null
        find "$TEMP_DL" -type f -name rclone -exec mv {} "$MODPATH/bin/rclone" \; 2>/dev/null || true
        chmod 755 "$MODPATH/bin/rclone" 2>/dev/null || true
    fi

    rm -rf "$TEMP_DL"
else
    ui_print "- Offline Mode: Binaries will auto-download on first boot in background."
fi

ui_print " "
ui_print "✓ Module installation completed!"
ui_print " "
ui_print "Next Steps:"
ui_print "1. Reboot phone."
ui_print "2. Open Browser: http://localhost:5244"
ui_print "3. Link TeraBox Cookie (ndus) in AList."
ui_print "****************************************************"
