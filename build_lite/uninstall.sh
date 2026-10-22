#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Module Uninstaller Script
# ==============================================================================

# 1. Unmount storage cleanly
MOUNT_POINT="/sdcard/TeraBox-CloudSSD"
umount -l "$MOUNT_POINT" 2>/dev/null || true

# 2. Kill all background daemons
pkill -f "alist server" 2>/dev/null || true
pkill -f "rclone mount.*TeraBox-CloudSSD" 2>/dev/null || true

# 3. Clean runtime files
rm -f /sdcard/CloudSSD-Manager.html 2>/dev/null || true
rm -f /data/local/tmp/cloud_ssd_boot.log 2>/dev/null || true
rm -f /data/local/tmp/rclone_boot.log 2>/dev/null || true

exit 0
