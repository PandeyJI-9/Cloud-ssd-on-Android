#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Google Drive AI Smart Clean Unmount Engine
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REMOTE_NAME="${1:-gdrive}"
FOLDER_NAME="GoogleDrive-CloudSSD"

# 1. Elevate to root & PID 1 Global Mount Namespace
if [ "$(id -u)" -ne 0 ]; then
    if command -v su >/dev/null 2>&1; then
        exec su -c "$0" "$@"
    fi
fi

if [ -f "/proc/1/ns/mnt" ] && [ -f "/proc/self/ns/mnt" ]; then
    INIT_NS=$(readlink /proc/1/ns/mnt 2>/dev/null || echo "1")
    SELF_NS=$(readlink /proc/self/ns/mnt 2>/dev/null || echo "2")
    if [ "$INIT_NS" != "$SELF_NS" ]; then
        if command -v nsenter >/dev/null 2>&1; then
            exec nsenter -t 1 -m -- "$0" "$@"
        fi
    fi
fi

echo -e "${YELLOW}[*] Safely unmounting Google Drive Cloud SSD...${NC}"

TARGET_POINTS=(
    "/mnt/runtime/default/emulated/0/$FOLDER_NAME"
    "/mnt/runtime/read/emulated/0/$FOLDER_NAME"
    "/mnt/runtime/write/emulated/0/$FOLDER_NAME"
    "/mnt/pass_through/0/emulated/0/$FOLDER_NAME"
    "/data/media/0/$FOLDER_NAME"
    "/storage/emulated/0/$FOLDER_NAME"
    "/sdcard/$FOLDER_NAME"
    "/storage/$FOLDER_NAME"
    "/mnt/cloud/$REMOTE_NAME"
)

# Unmount all runtime targets lazily
for target in "${TARGET_POINTS[@]}"; do
    if mount | grep -q "$target"; then
        umount -l "$target" 2>/dev/null || true
    fi
done

# Check external volume paths
for p in /storage/*; do
    if [ "$p" != "/storage/emulated" ] && [ "$p" != "/storage/self" ] && [ -d "$p" ]; then
        umount -l "$p" 2>/dev/null || true
    fi
done

# Terminate rclone process for this remote
pkill -9 -f "rclone mount.*$REMOTE_NAME:" 2>/dev/null || true
sleep 1

# Purge transient temp cache
rm -rf /data/local/tmp/cloudssd_cache/* 2>/dev/null || true

# Refresh file managers
for pkg in ru.zdevs.zarchiver \
           com.mi.android.globalFileexplorer \
           com.android.fileexplorer \
           com.google.android.apps.nbu.files; do
    am force-stop "$pkg" 2>/dev/null || true
done

# Verify
if mount | grep -q "$FOLDER_NAME"; then
    echo -e "${RED}[X] Warning: Some mount points could not be unmounted.${NC}"
    exit 1
else
    echo -e "${GREEN}[✓] Google Drive Cloud SSD successfully unmounted and cache purged.${NC}"
fi
