#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Bulletproof Zero-Bootloop Magisk/KernelSU Service
# Runs strictly in late_start (after system has completely finished booting)
# ==============================================================================

MODDIR="${0%/*}"
LOGFILE="/data/local/tmp/cloud_ssd_boot.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# ------------------------------------------------------------------------------
# SAFETY ARCHITECTURE (Guaranteed Zero-Bootloop):
# 1. Fork background daemon immediately and exit script with return code 0.
# 2. Never block Android boot sequence or Zygote.
# ------------------------------------------------------------------------------

run_cloud_ssd_daemon() {
    log "=== Cloud SSD Boot Service Initialized ==="

    # 1. Wait until Android OS has completely loaded launcher & lockscreen
    local boot_count=0
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 2
        boot_count=$((boot_count + 1))
        if [ $boot_count -gt 60 ]; then
            log "Timeout waiting for boot_completed, proceeding with safety checks..."
            break
        fi
    done
    log "Android OS boot completed confirmed."

    # 2. Deploy WebUI shortcut to /sdcard for standard Magisk & browser users
    if [ -d "/sdcard" ]; then
        cp -f "$MODDIR/webroot/index.html" "/sdcard/CloudSSD-Manager.html" 2>/dev/null || true
    fi

    # 3. Locate standalone binaries (Embedded inside module)
    ALIST_BIN="$MODDIR/bin/alist"
    RCLONE_BIN="$MODDIR/bin/rclone"

    # Fallbacks if module bin is customized
    [ ! -x "$ALIST_BIN" ] && ALIST_BIN="$(command -v alist 2>/dev/null)"
    [ ! -x "$RCLONE_BIN" ] && RCLONE_BIN="$(command -v rclone 2>/dev/null)"

    if [ ! -x "$ALIST_BIN" ] || [ ! -x "$RCLONE_BIN" ]; then
        log "Error: Required binaries (alist/rclone) not executable. Aborting safely."
        exit 0
    fi

    # 4. Wait for internet connection (Wi-Fi or Mobile Data)
    local net_retries=0
    local has_internet=0
    while [ $net_retries -lt 30 ]; do
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
            has_internet=1
            log "Internet connection detected."
            break
        fi
        net_retries=$((net_retries + 1))
        sleep 4
    done

    # 5. Start AList Daemon on Port 5244
    ALIST_DATA="/data/adb/cloud_ssd/alist_data"
    mkdir -p "$ALIST_DATA"

    if ! pgrep -f "$ALIST_BIN server" >/dev/null 2>&1; then
        log "Starting embedded AList daemon..."
        "$ALIST_BIN" admin set admin123 --data "$ALIST_DATA" >/dev/null 2>&1 || true
        nohup "$ALIST_BIN" server --data "$ALIST_DATA" > "$ALIST_DATA/alist.log" 2>&1 &
        sleep 4
    fi

    # 6. Check if default rclone config exists
    RCLONE_CONF="/data/adb/cloud_ssd/rclone.conf"
    mkdir -p "/data/adb/cloud_ssd"
    
    # Auto-generate rclone WebDAV config for AList if missing
    if [ ! -f "$RCLONE_CONF" ]; then
        log "Creating default rclone.conf for AList WebDAV loopback..."
        cat <<EOF > "$RCLONE_CONF"
[terabox]
type = webdav
url = http://127.0.0.1:5244/dav
vendor = other
user = admin
pass = admin123
EOF
    fi

    # 7. Mount Cloud SSD into Android Global PID 1 Init Namespace
    MOUNT_POINT="/sdcard/TeraBox-CloudSSD"
    mkdir -p "$MOUNT_POINT"

    if ! mount | grep -q "$MOUNT_POINT"; then
        log "Injecting Rclone FUSE mount into Global Mount Namespace..."
        
        # Zero internal storage cache policy: --vfs-cache-mode off
        if command -v nsenter >/dev/null 2>&1; then
            nsenter -t 1 -m -- "$RCLONE_BIN" mount terabox: "$MOUNT_POINT" \
                --config "$RCLONE_CONF" \
                --allow-other \
                --dir-cache-time 24h \
                --vfs-cache-mode off \
                --buffer-size 16M \
                --vfs-read-chunk-size 4M \
                --vfs-read-chunk-size-limit 64M \
                --no-modtime \
                --daemon \
                --log-file "/data/local/tmp/rclone_boot.log" \
                --log-level NOTICE
        fi
    fi

    sleep 3
    if mount | grep -q "$MOUNT_POINT"; then
        log "✓ Cloud SSD successfully mounted at $MOUNT_POINT"
    else
        log "Notice: Mount waiting for TeraBox configuration in AList dashboard."
    fi

    log "=== Cloud SSD Service Startup Completed ==="
}

# Run completely detached in background
run_cloud_ssd_daemon >/dev/null 2>&1 &
exit 0
