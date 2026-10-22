#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Clean Unmount Engine
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MOUNT_PATH="${1:-/sdcard/TeraBox-CloudSSD}"

echo -e "${YELLOW}[*] Unmounting Cloud SSD from $MOUNT_PATH...${NC}"

if command -v fusermount3 >/dev/null 2>&1; then
    fusermount3 -u "$MOUNT_PATH" 2>/dev/null || su -c "fusermount3 -u '$MOUNT_PATH'" 2>/dev/null || true
elif command -v fusermount >/dev/null 2>&1; then
    fusermount -u "$MOUNT_PATH" 2>/dev/null || su -c "fusermount -u '$MOUNT_PATH'" 2>/dev/null || true
fi

# Fallback to umount lazy
su -c "umount -l '$MOUNT_PATH'" 2>/dev/null || umount -l "$MOUNT_PATH" 2>/dev/null || true

# Kill associated rclone mount process if any
pkill -f "rclone mount.*$MOUNT_PATH" 2>/dev/null || su -c "pkill -f 'rclone mount.*$MOUNT_PATH'" 2>/dev/null || true

echo -e "${GREEN}[✓] Unmount completed successfully.${NC}"
