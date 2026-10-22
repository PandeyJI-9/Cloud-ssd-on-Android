#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Clean Unmount Engine (With Actual Status Verification)
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MOUNT_PATH="${1:-/sdcard/TeraBox-CloudSSD}"

echo -e "${YELLOW}[*] Unmounting Cloud SSD from $MOUNT_PATH...${NC}"

# Check if actually mounted first
if ! mount | grep -q "$MOUNT_PATH" && ! (su -c "mount" 2>/dev/null | grep -q "$MOUNT_PATH"); then
    echo -e "${GREEN}[✓] Notice: $MOUNT_PATH is already unmounted.${NC}"
    exit 0
fi

# Attempt standard FUSE unmount
if command -v fusermount3 >/dev/null 2>&1; then
    fusermount3 -u "$MOUNT_PATH" 2>/dev/null || su -c "fusermount3 -u '$MOUNT_PATH'" 2>/dev/null || true
elif command -v fusermount >/dev/null 2>&1; then
    fusermount -u "$MOUNT_PATH" 2>/dev/null || su -c "fusermount -u '$MOUNT_PATH'" 2>/dev/null || true
fi

# Fallback to umount lazy
su -c "umount -l '$MOUNT_PATH'" 2>/dev/null || umount -l "$MOUNT_PATH" 2>/dev/null || true

# Kill associated rclone mount process if still running
pkill -f "rclone mount.*$MOUNT_PATH" 2>/dev/null || su -c "pkill -f 'rclone mount.*$MOUNT_PATH'" 2>/dev/null || true

sleep 1

# Explicit Verification of Mount State (Fixes Bug 4)
if mount | grep -q "$MOUNT_PATH" || (su -c "mount" 2>/dev/null | grep -q "$MOUNT_PATH"); then
    echo -e "${RED}[X] Error: Failed to unmount $MOUNT_PATH! Mount point is still busy or in use.${NC}"
    exit 1
else
    echo -e "${GREEN}[✓] Unmount completed and verified successfully.${NC}"
    exit 0
fi
