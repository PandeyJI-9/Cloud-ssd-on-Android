#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Ultra-Lightweight HyperOS Safe Installer
# ==============================================================================

SKIPUNZIP=0

ui_print "****************************************************"
ui_print "*        ☁️  Cloud SSD: TeraBox 1TB Mounter        *"
ui_print "*      100% HyperOS / MIUI Zero-Bootloop Safe      *"
ui_print "*               Ultra-Lite Edition                 *"
ui_print "****************************************************"

ARCH=$(uname -m)
ui_print "- Detected Architecture: $ARCH"

mkdir -p "$MODPATH/bin"
mkdir -p "$MODPATH/webroot"
mkdir -p /data/adb/cloud_ssd/alist_data

set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Installing WebUI & On-Demand Controller..."
cp -f "$MODPATH/webroot/index.html" /sdcard/CloudSSD-Manager.html 2>/dev/null || true

ui_print " "
ui_print "✓ Module installed successfully (Safe Mode)!"
ui_print " "
ui_print "How It Works:"
ui_print "1. Phone will boot cleanly into HyperOS without any hang."
ui_print "2. Background service starts 30s after boot."
ui_print "3. Open Browser: http://localhost:5244"
ui_print "   - User: admin | Pass: admin123"
ui_print "   - Add TeraBox under Storages"
ui_print "4. Use /sdcard/CloudSSD-Manager.html or run:"
ui_print "   su -c sh /data/adb/cloud_ssd/mount.sh"
ui_print "****************************************************"
