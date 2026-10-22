#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Magisk Module Installer Script
# ==============================================================================

ui_print "***********************************************"
ui_print "*        Cloud SSD - TeraBox 1TB Mounter      *"
ui_print "*         10000% Native Namespace Injection   *"
ui_print "***********************************************"

# Check Architecture
if [ "$ARCH" != "arm64" ] && [ "$ARCH" != "arm" ]; then
    ui_print "! Unsupported architecture: $ARCH"
    ui_print "! Only ARM and ARM64 Android devices are supported."
    abort
fi

ui_print "- Architecture: $ARCH"
ui_print "- Setting executable permissions..."

mkdir -p "$MODPATH/bin"
mkdir -p /data/adb/cloud_ssd

set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Module files installed."
ui_print " "
ui_print "Instructions:"
ui_print "1. Ensure Termux has rclone configured ('terabox' remote)"
ui_print "2. Or copy your rclone.conf to /data/adb/cloud_ssd/rclone.conf"
ui_print "3. Reboot your device to activate permanent boot mount!"
ui_print "***********************************************"
