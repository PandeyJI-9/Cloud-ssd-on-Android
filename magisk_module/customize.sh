#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Magisk / KernelSU / APatch Installer
# ==============================================================================

SKIPUNZIP=0

ui_print "****************************************************"
ui_print "*        ☁️  Cloud SSD: TeraBox 1TB Mounter        *"
ui_print "*         100% Zero-Bootloop Safe Architecture     *"
ui_print "*            KernelSU & Magisk WebUI GUI           *"
ui_print "****************************************************"

# Check Architecture
if [ "$ARCH" != "arm64" ] && [ "$ARCH" != "arm" ]; then
    ui_print "! [X] Unsupported CPU architecture: $ARCH"
    ui_print "! Only ARM and ARM64 Android devices are supported."
    abort
fi

ui_print "- Target Architecture: $ARCH"
ui_print "- Setting up execution permissions..."

mkdir -p "$MODPATH/bin"
mkdir -p "$MODPATH/scripts"
mkdir -p "$MODPATH/webroot"
mkdir -p /data/adb/cloud_ssd/alist_data

# Set strict permissions
set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755
[ -f "$MODPATH/bin/alist" ] && set_perm "$MODPATH/bin/alist" 0 0 0755
[ -f "$MODPATH/bin/rclone" ] && set_perm "$MODPATH/bin/rclone" 0 0 0755

ui_print "- Creating WebUI dashboard shortcuts..."
cp -f "$MODPATH/webroot/index.html" /sdcard/CloudSSD-Manager.html 2>/dev/null || true

ui_print " "
ui_print "✓ Module installation completed!"
ui_print " "
ui_print "Post-Install Steps:"
ui_print "1. Reboot phone to start the Cloud SSD background service."
ui_print "2. Open Browser: http://localhost:5244 (AList Dashboard)"
ui_print "   - User: admin  |  Pass: admin123"
ui_print "3. Add TeraBox under Storages -> Status: work"
ui_print "4. Drive will be mounted at: /sdcard/TeraBox-CloudSSD"
ui_print "****************************************************"
