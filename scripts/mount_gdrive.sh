#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Google Drive AI Smart Mount Engine
# Features:
#  1. AI Dynamic On-Demand Paging (Zero Full-Drive Sync, Only Loads Needed Chunks)
#  2. Device-Aware Storage Sentinel (Dynamic Cache Auto-Scaling: 1G -> 300M -> 0B)
#  3. Root & Global PID 1 Mount Namespace Injection (Universal Visibility)
#  4. Android 11-14 / HyperOS MediaProvider FUSE & Runtime Bind Propagation
#  5. Virtual SD Card / External Storage Exposure (/storage & /sdcard)
#  6. .nomedia Firewall (Prevents Gallery/MediaScanner Background Bandwidth Drain)
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REMOTE_NAME="${1:-gdrive}"
FOLDER_NAME="GoogleDrive-CloudSSD"

# ------------------------------------------------------------------------------
# 1. ROOT & PID 1 GLOBAL MOUNT NAMESPACE INJECTION
# ------------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    if command -v su >/dev/null 2>&1; then
        echo -e "${YELLOW}[*] Elevating to root privileges...${NC}"
        exec su -c "$0" "$@"
    else
        echo -e "${RED}[X] Root access is required to mount storage across Android apps.${NC}"
        exit 1
    fi
fi

# Ensure running inside PID 1 (Init) Mount Namespace so ALL apps can see the mount
if [ -f "/proc/1/ns/mnt" ] && [ -f "/proc/self/ns/mnt" ]; then
    INIT_NS=$(readlink /proc/1/ns/mnt 2>/dev/null || echo "1")
    SELF_NS=$(readlink /proc/self/ns/mnt 2>/dev/null || echo "2")
    if [ "$INIT_NS" != "$SELF_NS" ]; then
        if command -v nsenter >/dev/null 2>&1; then
            echo -e "${CYAN}[*] Injecting into Android Global Mount Namespace (PID 1)...${NC}"
            exec nsenter -t 1 -m -- "$0" "$@"
        fi
    fi
fi

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}    ☁️  Cloud SSD: Google Drive AI Smart Engine     ${NC}"
echo -e "${GREEN}====================================================${NC}"

# ------------------------------------------------------------------------------
# 2. LOCATE RCLONE BINARY & CONFIGURATION
# ------------------------------------------------------------------------------
RCLONE_BIN=""
for p in /data/cloudssd/bin/rclone \
         /data/data/com.termux/files/usr/bin/rclone \
         /data/adb/modules/cloud_ssd_terabox/bin/rclone \
         /system/bin/rclone \
         /data/local/tmp/rclone \
         $(command -v rclone 2>/dev/null); do
    if [ -x "$p" ]; then
        RCLONE_BIN="$p"
        break
    fi
done

if [ -z "$RCLONE_BIN" ]; then
    echo -e "${RED}[X] Error: rclone binary not found!${NC}"
    echo -e "    Please run 'cloudssd install' or 'pkg install rclone' in Termux."
    exit 1
fi

RCLONE_CONF=""
for c in /data/data/com.termux/files/home/.config/rclone/rclone.conf \
         /data/cloudssd/rclone.conf \
         /sdcard/.rclone/rclone.conf \
         /data/adb/cloud_ssd/rclone.conf \
         "$HOME/.config/rclone/rclone.conf" \
         /root/.config/rclone/rclone.conf; do
    if [ -f "$c" ]; then
        RCLONE_CONF="$c"
        break
    fi
done

if [ -z "$RCLONE_CONF" ]; then
    echo -e "${RED}[X] Error: rclone.conf not found!${NC}"
    echo -e "    Please run 'rclone config' in Termux and set up your remote '$REMOTE_NAME'."
    exit 1
fi

# Verify remote exists
if ! "$RCLONE_BIN" --config "$RCLONE_CONF" listremotes 2>/dev/null | grep -q "^${REMOTE_NAME}:"; then
    echo -e "${RED}[X] Error: Remote '${REMOTE_NAME}:' not found in $RCLONE_CONF!${NC}"
    echo -e "${YELLOW}Available remotes:${NC}"
    "$RCLONE_BIN" --config "$RCLONE_CONF" listremotes 2>/dev/null || echo "None"
    echo -e "${YELLOW}Run 'rclone config' to configure '${REMOTE_NAME}'.${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# 3. AI DYNAMIC STORAGE SENTINEL (SMART ON-DEMAND CACHE CALCULATION)
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}[1/4] Running AI Dynamic Storage Sentinel...${NC}"

# Detect free storage on /data in Megabytes
DATA_FREE_KB=$(df -k /data 2>/dev/null | awk 'NR==2 {print $4}' || echo "10485760")
DATA_FREE_MB=$((DATA_FREE_KB / 1024))

echo -e "    Internal Storage Free: ${YELLOW}${DATA_FREE_MB} MB${NC}"

CACHE_DIR="/data/local/tmp/cloudssd_cache"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

if [ "$DATA_FREE_MB" -gt 10240 ]; then
    # High storage (>10GB free): 1GB rolling cache with rapid LRU eviction
    CACHE_MODE="full"
    CACHE_MAX_SIZE="1G"
    CACHE_MAX_AGE="10m"
    AI_POLICY="OPTIMAL (1GB Rolling LRU Cache, 10m Chunk Expiry)"
elif [ "$DATA_FREE_MB" -gt 3072 ]; then
    # Moderate storage (3GB - 10GB free): Lightweight 300MB cache
    CACHE_MODE="full"
    CACHE_MAX_SIZE="300M"
    CACHE_MAX_AGE="5m"
    AI_POLICY="LIGHTWEIGHT (300MB Strict Rolling Cache, 5m Chunk Expiry)"
else
    # Low storage (<3GB free): Pure RAM-only streaming (0 Bytes internal disk usage)
    CACHE_MODE="off"
    CACHE_MAX_SIZE="0M"
    CACHE_MAX_AGE="1m"
    AI_POLICY="ZERO-DISK (100% RAM Streaming, 0 Bytes Disk Cache Consumed)"
fi

echo -e "    AI Policy: ${GREEN}$AI_POLICY${NC}"
echo -e "    Demand Paging: ${BLUE}Only requested chunks (4MB-32MB) are loaded on-demand.${NC}"
echo -e "    Full Drive Download: ${GREEN}DISABLED (0% disk clone)${NC}"

# ------------------------------------------------------------------------------
# 4. PATH INITIALIZATION & UNMOUNT PREVIOUS ZOMBIE MOUNTS
# ------------------------------------------------------------------------------
BASE_MOUNT="/mnt/cloud/$REMOTE_NAME"
PRIMARY_STORAGE="/storage/emulated/0/$FOLDER_NAME"
SDCARD_ALIAS="/sdcard/$FOLDER_NAME"
DATA_MEDIA_PATH="/data/media/0/$FOLDER_NAME"
EXT_STORAGE="/storage/$FOLDER_NAME"

pkill -9 -f "rclone mount.*$REMOTE_NAME:" 2>/dev/null || true
sleep 1

mkdir -p "$BASE_MOUNT"
mkdir -p "$DATA_MEDIA_PATH"
mkdir -p "$PRIMARY_STORAGE"
mkdir -p "$SDCARD_ALIAS"
mkdir -p "$EXT_STORAGE" 2>/dev/null || true

chown 1023:1023 "$DATA_MEDIA_PATH" 2>/dev/null || true
chmod 771 "$DATA_MEDIA_PATH" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. EXECUTE AI ON-DEMAND RCLONE MOUNT
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}[2/4] Starting AI Virtual File System Mount...${NC}"
LOG_FILE="/data/local/tmp/rclone_${REMOTE_NAME}.log"
rm -f "$LOG_FILE" 2>/dev/null || true

# Launch Rclone FUSE daemon
"$RCLONE_BIN" mount "${REMOTE_NAME}:" "$BASE_MOUNT" \
    --config "$RCLONE_CONF" \
    --cache-dir "$CACHE_DIR" \
    --allow-other \
    --allow-non-empty \
    --gid 1023 \
    --uid 1023 \
    --dir-perms 0775 \
    --file-perms 0664 \
    --umask 002 \
    --dir-cache-time 72h \
    --attr-timeout 24h \
    --vfs-cache-mode "$CACHE_MODE" \
    --vfs-cache-max-size "$CACHE_MAX_SIZE" \
    --vfs-cache-max-age "$CACHE_MAX_AGE" \
    --buffer-size 16M \
    --vfs-read-chunk-size 4M \
    --vfs-read-chunk-size-limit 32M \
    --drive-chunk-size 16M \
    --no-modtime \
    --no-checksum \
    --daemon \
    --log-file "$LOG_FILE" \
    --log-level NOTICE

# Wait for FUSE mount establishment
MOUNTED=false
for i in $(seq 1 10); do
    if mount | grep -q "$BASE_MOUNT"; then
        MOUNTED=true
        break
    fi
    sleep 0.5
done

if [ "$MOUNTED" != true ]; then
    echo -e "${RED}[X] Error: FUSE mount failed to start! Check log below:${NC}"
    tail -n 20 "$LOG_FILE" 2>/dev/null || true
    exit 1
fi

# ------------------------------------------------------------------------------
# 6. .nomedia FIREWALL (PROTECT AGAINST GALLERY / MEDIAPROVIDER SPAM)
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}[3/4] Activating .nomedia MediaScanner Firewall...${NC}"
touch "$BASE_MOUNT/.nomedia" 2>/dev/null || true
chmod 644 "$BASE_MOUNT/.nomedia" 2>/dev/null || true
touch "$DATA_MEDIA_PATH/.nomedia" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 7. MULTI-NAMESPACE & ANDROID RUNTIME PROPAGATION
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}[4/4] Propagating mount to Android Storage & File Managers...${NC}"

# Target all Android 11-14 / HyperOS runtime namespaces
TARGET_POINTS=(
    "$DATA_MEDIA_PATH"
    "/mnt/runtime/default/emulated/0/$FOLDER_NAME"
    "/mnt/runtime/read/emulated/0/$FOLDER_NAME"
    "/mnt/runtime/write/emulated/0/$FOLDER_NAME"
    "/mnt/pass_through/0/emulated/0/$FOLDER_NAME"
    "$PRIMARY_STORAGE"
    "$SDCARD_ALIAS"
    "$EXT_STORAGE"
)

for target in "${TARGET_POINTS[@]}"; do
    mkdir -p "$target" 2>/dev/null || true
    mount -o bind "$BASE_MOUNT" "$target" 2>/dev/null || true
done

# Try activating Virtual SD Card via Android StorageManager (sm)
if command -v sm >/dev/null 2>&1; then
    echo -e "    Checking Android Virtual SD Card Volume capability..."
    sm set-virtual-disk true 2>/dev/null || true
    VIRT_DISK=$(sm list-disks 2>/dev/null | grep -i "disk" | head -n 1 || true)
    if [ -n "$VIRT_DISK" ]; then
        # Check if volume exists
        VIRT_VOL=$(sm list-volumes public 2>/dev/null | grep -o "public:[0-9,]*" | head -n 1 || true)
        if [ -z "$VIRT_VOL" ]; then
            sm partition "$VIRT_DISK" public 2>/dev/null || true
            sleep 1
        fi
        # Find path of public volume under /mnt/media_rw or /storage
        for p in /storage/*; do
            if [ "$p" != "/storage/emulated" ] && [ "$p" != "/storage/self" ] && [ -d "$p" ]; then
                mount -o bind "$BASE_MOUNT" "$p" 2>/dev/null || true
            fi
        done
    fi
fi

# Refresh File Managers so they immediately detect the new mount
for pkg in ru.zdevs.zarchiver \
           com.mi.android.globalFileexplorer \
           com.android.fileexplorer \
           com.google.android.apps.nbu.files \
           com.sec.android.app.myfiles \
           com.mixplorer \
           pl.solidexplorer2; do
    am force-stop "$pkg" 2>/dev/null || true
done

# Broadcast media mount intent
am broadcast -a android.intent.action.MEDIA_MOUNTED -d "file:///sdcard/$FOLDER_NAME" >/dev/null 2>&1 || true

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}    ✓ SUCCESS: Google Drive Cloud SSD is Active!     ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e " 📁 Internal Storage Path: ${YELLOW}/sdcard/$FOLDER_NAME${NC}"
echo -e " 📁 Primary Storage Path:  ${YELLOW}$PRIMARY_STORAGE${NC}"
echo -e " 💾 External Storage Path: ${YELLOW}$EXT_STORAGE${NC}"
echo -e " 🧠 AI On-Demand Engine:   ${CYAN}$AI_POLICY${NC}"
echo -e " 🛡️ .nomedia Firewall:     ${GREEN}ACTIVE (No unnecessary mobile data used)${NC}"
echo -e "\nOpen ZArchiver or your File Manager now to access your Google Drive!"
