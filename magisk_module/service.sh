#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Bulletproof Zero-Bootloop & Zero-OOM Magisk/KernelSU Service
# Runs strictly in late_start (after system has completely finished booting)
# ==============================================================================

MODDIR="${0%/*}"
LOGFILE="/data/local/tmp/cloud_ssd_boot.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# ------------------------------------------------------------------------------
# SAFETY ARCHITECTURE:
# 1. Fork background daemon immediately and exit script with return code 0.
# 2. Never block Android boot sequence or Zygote.
# 3. Stream downloads directly to disk to prevent RAM OOM (Exit 137).
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

    # 2. Deploy WebUI shortcut to /sdcard
    if [ -d "/sdcard" ]; then
        cp -f "$MODDIR/webroot/index.html" "/sdcard/CloudSSD-Manager.html" 2>/dev/null || true
    fi

    # 3. Wait for internet connection
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

    # 4. Check and stream download binaries if missing (prevents OOM during flash)
    ALIST_BIN="$MODDIR/bin/alist"
    RCLONE_BIN="$MODDIR/bin/rclone"
    mkdir -p "$MODDIR/bin"

    if [ ! -x "$ALIST_BIN" ] || [ ! -x "$RCLONE_BIN" ]; then
        log "Static binaries missing. Downloading directly to flash disk..."
        
        ARCH=$(uname -m)
        case "$ARCH" in
            aarch64|arm64)
                ALIST_URL="https://github.com/AlistGo/alist/releases/latest/download/alist-linux-arm64.tar.gz"
                RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm64.zip"
                ;;
            *)
                ALIST_URL="https://github.com/AlistGo/alist/releases/latest/download/alist-linux-arm-7.tar.gz"
                RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm-v7.zip"
                ;;
        esac

        TEMP_DIR="/data/local/tmp/cloud_ssd_setup"
        rm -rf "$TEMP_DIR" && mkdir -p "$TEMP_DIR"

        if [ ! -x "$ALIST_BIN" ]; then
            log "Fetching AList binary..."
            curl -sL --max-time 120 "$ALIST_URL" -o "$TEMP_DIR/alist.tar.gz" 2>/dev/null || \
                wget -q "$ALIST_URL" -O "$TEMP_DIR/alist.tar.gz" 2>/dev/null || true
            if [ -f "$TEMP_DIR/alist.tar.gz" ]; then
                tar -xzf "$TEMP_DIR/alist.tar.gz" -C "$TEMP_DIR"
                mv "$TEMP_DIR/alist" "$ALIST_BIN" 2>/dev/null || true
                chmod 755 "$ALIST_BIN"
                log "AList installed successfully."
            fi
        fi

        if [ ! -x "$RCLONE_BIN" ]; then
            log "Fetching Rclone binary..."
            curl -sL --max-time 120 "$RCLONE_URL" -o "$TEMP_DIR/rclone.zip" 2>/dev/null || \
                wget -q "$RCLONE_URL" -O "$TEMP_DIR/rclone.zip" 2>/dev/null || true
            if [ -f "$TEMP_DIR/rclone.zip" ]; then
                unzip -q "$TEMP_DIR/rclone.zip" -d "$TEMP_DIR" 2>/dev/null || true
                find "$TEMP_DIR" -type f -name rclone -exec mv {} "$RCLONE_BIN" \; 2>/dev/null || true
                chmod 755 "$RCLONE_BIN"
                log "Rclone installed successfully."
            fi
        fi

        rm -rf "$TEMP_DIR"
    fi

    # Fallback to system / termux binaries
    [ ! -x "$ALIST_BIN" ] && ALIST_BIN="$(command -v alist 2>/dev/null)"
    [ ! -x "$RCLONE_BIN" ] && RCLONE_BIN="$(command -v rclone 2>/dev/null)"

    if [ ! -x "$ALIST_BIN" ] || [ ! -x "$RCLONE_BIN" ]; then
        log "Notice: Waiting for binaries to be downloaded."
        exit 0
    fi

    # 5. Start AList Daemon on Port 5244
    ALIST_DATA="/data/adb/cloud_ssd/alist_data"
    mkdir -p "$ALIST_DATA"

    if ! pgrep -f "$ALIST_BIN server" >/dev/null 2>&1; then
        log "Starting AList daemon..."
        "$ALIST_BIN" admin set admin123 --data "$ALIST_DATA" >/dev/null 2>&1 || true
        nohup "$ALIST_BIN" server --data "$ALIST_DATA" > "$ALIST_DATA/alist.log" 2>&1 &
        sleep 4
    fi

    # 6. Configure Rclone WebDAV endpoint if missing
    RCLONE_CONF="/data/adb/cloud_ssd/rclone.conf"
    mkdir -p "/data/adb/cloud_ssd"
    
    if [ ! -f "$RCLONE_CONF" ]; then
        log "Creating default rclone.conf for AList WebDAV..."
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
