#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: TeraBox Mount Engine (Rclone + FUSE + Namespace Injection)
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

REMOTE_NAME="${1:-terabox}"
MOUNT_PATH="${2:-/sdcard/TeraBox-CloudSSD}"

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}          Cloud SSD: Mounting TeraBox Volume         ${NC}"
echo -e "${GREEN}====================================================${NC}"

# Check if rclone is installed
if ! command -v rclone >/dev/null 2>&1; then
    echo -e "${RED}[X] Error: rclone is not installed! Run scripts/install_dependencies_termux.sh first.${NC}"
    exit 1
fi

# Check if remote exists in rclone config
if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
    echo -e "${RED}[X] Error: Remote '${REMOTE_NAME}' not found in rclone configuration!${NC}"
    echo -e "${YELLOW}Please configure '${REMOTE_NAME}' first:${NC}"
    echo -e "Run: rclone config"
    echo -e "  - Name: $REMOTE_NAME"
    echo -e "  - Type: webdav"
    echo -e "  - URL: http://127.0.0.1:5244/dav"
    echo -e "  - Vendor: other"
    exit 1
fi

# Ensure mount directory exists
mkdir -p "$MOUNT_PATH" 2>/dev/null || su -c "mkdir -p '$MOUNT_PATH'"

# Check if already mounted
if mount | grep -q "$MOUNT_PATH"; then
    echo -e "${YELLOW}[!] Mount point $MOUNT_PATH is already mounted!${NC}"
    exit 0
fi

# Check if root is available for Global Mount Namespace injection
IS_ROOT=false
if [ "$(id -u)" -eq 0 ] || command -v su >/dev/null 2>&1; then
    IS_ROOT=true
fi

echo -e "${BLUE}[*] Remote:       ${REMOTE_NAME}:${NC}"
echo -e "${BLUE}[*] Mount Point:  ${MOUNT_PATH}${NC}"
echo -e "${BLUE}[*] Cache Policy: ZERO LOCAL DISK CACHE (--vfs-cache-mode off)${NC}"

# Optimized Rclone flags for zero internal storage waste:
RCLONE_FLAGS=(
    "mount"
    "${REMOTE_NAME}:"
    "$MOUNT_PATH"
    "--allow-other"
    "--dir-cache-time" "24h"
    "--attr-timeout" "1h"
    "--vfs-cache-mode" "off"          # Critical: ZERO GB internal storage consumed
    "--buffer-size" "16M"             # Pure RAM streaming buffer
    "--vfs-read-chunk-size" "4M"
    "--vfs-read-chunk-size-limit" "64M"
    "--no-modtime"
    "--daemon"
    "--log-file" "/data/local/tmp/rclone_cloudssd.log"
    "--log-level" "NOTICE"
)

if [ "$IS_ROOT" = true ]; then
    echo -e "${GREEN}[+] Root access detected. Injecting mount into Global Mount Namespace...${NC}"
    
    # Check if nsenter is available to target PID 1 (Android Init)
    if su -c "command -v nsenter" >/dev/null 2>&1; then
        su -c "nsenter -t 1 -m -- rclone ${RCLONE_FLAGS[*]}"
    else
        # Fallback to su -mm (Mount Master namespace)
        su -mm -c "rclone ${RCLONE_FLAGS[*]}"
    fi
else
    echo -e "${YELLOW}[!] Non-root user: Mounting inside current user namespace.${NC}"
    echo -e "${YELLOW}[!] Note: Other Android apps might not see this mount without root!${NC}"
    rclone "${RCLONE_FLAGS[@]}"
fi

sleep 2

# Verify mount
if mount | grep -q "$MOUNT_PATH" || su -c "mount | grep -q '$MOUNT_PATH'" 2>/dev/null; then
    echo -e "\n${GREEN}[✓] SUCCESS: TeraBox Cloud SSD mounted successfully at:${NC}"
    echo -e "    ${YELLOW}$MOUNT_PATH${NC}"
    echo -e "You can now open File Manager / ZArchiver / Emulators and browse your 1TB cloud storage!"
else
    echo -e "\n${RED}[X] Mount check failed. Inspect logs at /data/local/tmp/rclone_cloudssd.log${NC}"
    exit 1
fi
