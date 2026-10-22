#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Magisk / KernelSU / APatch Late-Start Service
# Injects TeraBox Cloud SSD mount on boot after network connection is up
# ==============================================================================

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/cloud_ssd_boot.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

log "Cloud SSD Service starting up..."

# 1. Wait until boot is completed
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done
log "Boot completed detected."

# 2. Wait for internet connection (Wi-Fi or Mobile Data)
CONNECTED=0
RETRIES=0
MAX_RETRIES=40

while [ $RETRIES -lt $MAX_RETRIES ]; do
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        CONNECTED=1
        log "Internet connectivity established."
        break
    fi
    RETRIES=$((RETRIES + 1))
    sleep 3
done

if [ $CONNECTED -eq 0 ]; then
    log "Warning: Network timeout reached. Proceeding anyway..."
fi

# 3. Locate binaries
ALIST_BIN=""
RCLONE_BIN=""

for path in /data/adb/modules/cloud_ssd_terabox/bin/alist \
            /data/data/com.termux/files/usr/bin/alist \
            /system/bin/alist \
            /data/local/tmp/alist; do
    if [ -x "$path" ]; then
        ALIST_BIN="$path"
        break
    fi
done

for path in /data/adb/modules/cloud_ssd_terabox/bin/rclone \
            /data/data/com.termux/files/usr/bin/rclone \
            /system/bin/rclone \
            /data/local/tmp/rclone; do
    if [ -x "$path" ]; then
        RCLONE_BIN="$path"
        break
    fi
done

log "AList binary: $ALIST_BIN"
log "Rclone binary: $RCLONE_BIN"

# 4. Start AList if binary exists and not already running
ALIST_DATA="/data/adb/cloud_ssd/alist_data"
mkdir -p "$ALIST_DATA"

if [ -n "$ALIST_BIN" ]; then
    if ! pgrep -x "alist" >/dev/null; then
        log "Starting AList daemon..."
        nohup "$ALIST_BIN" server --data "$ALIST_DATA" > "$ALIST_DATA/alist.log" 2>&1 &
        sleep 3
    else
        log "AList is already running."
    fi
fi

# 5. Mount Cloud SSD into Global Namespace
MOUNT_POINT="/sdcard/TeraBox-CloudSSD"
mkdir -p "$MOUNT_POINT"

RCLONE_CONF="/data/adb/cloud_ssd/rclone.conf"
if [ ! -f "$RCLONE_CONF" ]; then
    # Fallback to Termux config if exists
    if [ -f "/data/data/com.termux/files/home/.config/rclone/rclone.conf" ]; then
        RCLONE_CONF="/data/data/com.termux/files/home/.config/rclone/rclone.conf"
    fi
fi

if [ -n "$RCLONE_BIN" ] && [ -f "$RCLONE_CONF" ]; then
    log "Mounting TeraBox via Rclone into Global Namespace..."
    
    # Inject into PID 1 Init namespace so all apps can access the mount
    nsenter -t 1 -m -- "$RCLONE_BIN" mount terabox: "$MOUNT_POINT" \
        --config "$RCLONE_CONF" \
        --allow-other \
        --dir-cache-time 24h \
        --attr-timeout 1h \
        --vfs-cache-mode off \
        --buffer-size 16M \
        --vfs-read-chunk-size 4M \
        --vfs-read-chunk-size-limit 64M \
        --no-modtime \
        --daemon \
        --log-file "/data/local/tmp/rclone_boot_mount.log" \
        --log-level NOTICE

    log "Mount executed. Checking status..."
    sleep 2
    if mount | grep -q "$MOUNT_POINT"; then
        log "Cloud SSD mounted successfully at $MOUNT_POINT"
    else
        log "Mount verification failed. Check /data/local/tmp/rclone_boot_mount.log"
    fi
else
    log "Error: Missing Rclone binary or rclone.conf"
fi
