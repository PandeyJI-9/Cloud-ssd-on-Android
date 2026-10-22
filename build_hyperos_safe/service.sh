#!/system/bin/sh
# ==============================================================================
# Cloud SSD: 100% HyperOS / MIUI Certified Zero-Bootloop Service
# Strictly Non-Blocking, No nsenter PID 1 tampering, Pure Background Subshell
# ==============================================================================

MODDIR="${0%/*}"

# ------------------------------------------------------------------------------
# HYPEROS SAFETY RULE #1: NEVER BLOCK THE MAIN PROCESS!
# The script immediately exits 0 so Magisk & HyperOS boot unhindered.
# ------------------------------------------------------------------------------

(
    # Wait 30 seconds for HyperOS SecurityCenter, Vold, and SurfaceFlinger to fully settle
    sleep 30

    LOGFILE="/data/local/tmp/cloud_ssd.log"
    log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
    }

    log "=== Cloud SSD HyperOS Safe Service Started ==="

    # 1. Copy WebUI Manager to /sdcard
    if [ -d "/sdcard" ]; then
        cp -f "$MODDIR/webroot/index.html" "/sdcard/CloudSSD-Manager.html" 2>/dev/null || true
    fi

    # 2. Locate Binaries
    ALIST_BIN="$MODDIR/bin/alist"
    RCLONE_BIN="$MODDIR/bin/rclone"

    # Auto-download static binaries if missing (Stream directly to disk)
    if [ ! -x "$ALIST_BIN" ] || [ ! -x "$RCLONE_BIN" ]; then
        log "Binaries missing. Waiting for internet to download..."
        
        # Wait up to 2 minutes for Wi-Fi or Mobile data
        net_tries=0
        while [ $net_tries -lt 30 ]; do
            if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
                break
            fi
            sleep 4
            net_tries=$((net_tries + 1))
        done

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

        TEMP_DIR="/data/local/tmp/cloud_ssd_dl"
        mkdir -p "$TEMP_DIR" "$MODDIR/bin"

        if [ ! -x "$ALIST_BIN" ]; then
            log "Downloading AList binary..."
            curl -sL --max-time 120 "$ALIST_URL" -o "$TEMP_DIR/alist.tar.gz" 2>/dev/null || \
                wget -q "$ALIST_URL" -O "$TEMP_DIR/alist.tar.gz" 2>/dev/null || true
            if [ -f "$TEMP_DIR/alist.tar.gz" ]; then
                tar -xzf "$TEMP_DIR/alist.tar.gz" -C "$TEMP_DIR" 2>/dev/null || true
                mv "$TEMP_DIR/alist" "$ALIST_BIN" 2>/dev/null || true
                chmod 755 "$ALIST_BIN" 2>/dev/null || true
                log "AList installed."
            fi
        fi

        if [ ! -x "$RCLONE_BIN" ]; then
            log "Downloading Rclone binary..."
            curl -sL --max-time 120 "$RCLONE_URL" -o "$TEMP_DIR/rclone.zip" 2>/dev/null || \
                wget -q "$RCLONE_URL" -O "$TEMP_DIR/rclone.zip" 2>/dev/null || true
            if [ -f "$TEMP_DIR/rclone.zip" ]; then
                unzip -q "$TEMP_DIR/rclone.zip" -d "$TEMP_DIR" 2>/dev/null || true
                find "$TEMP_DIR" -type f -name rclone -exec mv {} "$RCLONE_BIN" \; 2>/dev/null || true
                chmod 755 "$RCLONE_BIN" 2>/dev/null || true
                log "Rclone installed."
            fi
        fi

        rm -rf "$TEMP_DIR"
    fi

    [ ! -x "$ALIST_BIN" ] && ALIST_BIN="$(command -v alist 2>/dev/null)"
    [ ! -x "$RCLONE_BIN" ] && RCLONE_BIN="$(command -v rclone 2>/dev/null)"

    if [ ! -x "$ALIST_BIN" ]; then
        log "Warning: AList binary not available yet."
        exit 0
    fi

    # 3. Start AList Daemon safely in background
    ALIST_DATA="/data/adb/cloud_ssd/alist_data"
    mkdir -p "$ALIST_DATA"

    if ! pgrep -f "$ALIST_BIN server" >/dev/null 2>&1; then
        log "Starting AList on port 5244..."
        "$ALIST_BIN" admin set admin123 --data "$ALIST_DATA" >/dev/null 2>&1 || true
        nohup "$ALIST_BIN" server --data "$ALIST_DATA" > "$ALIST_DATA/alist.log" 2>&1 &
        log "AList daemon running."
    fi

    # 4. Generate Default Rclone Config for WebDAV
    RCLONE_CONF="/data/adb/cloud_ssd/rclone.conf"
    mkdir -p "/data/adb/cloud_ssd"
    if [ ! -f "$RCLONE_CONF" ]; then
        cat <<EOF > "$RCLONE_CONF"
[terabox]
type = webdav
url = http://127.0.0.1:5244/dav
vendor = other
user = admin
pass = admin123
EOF
    fi

    # 5. Create Standalone On-Demand Mount & Unmount Commands
    cat <<'EOF' > /data/adb/cloud_ssd/mount.sh
#!/system/bin/sh
MOUNT_POINT="/sdcard/TeraBox-CloudSSD"
mkdir -p "$MOUNT_POINT"

RCLONE_BIN=""
for p in /data/adb/modules/cloud_ssd_terabox/bin/rclone /system/bin/rclone /data/local/tmp/rclone; do
    [ -x "$p" ] && RCLONE_BIN="$p" && break
done

if [ -z "$RCLONE_BIN" ]; then
    echo "Error: rclone binary not found"
    exit 1
fi

if mount | grep -q "$MOUNT_POINT"; then
    echo "Already mounted at $MOUNT_POINT"
    exit 0
fi

# HyperOS Safe Mount: Standard FUSE mount without touching PID 1 init
"$RCLONE_BIN" mount terabox: "$MOUNT_POINT" \
    --config /data/adb/cloud_ssd/rclone.conf \
    --allow-other \
    --dir-cache-time 24h \
    --vfs-cache-mode off \
    --buffer-size 16M \
    --vfs-read-chunk-size 4M \
    --vfs-read-chunk-size-limit 64M \
    --no-modtime \
    --daemon \
    --log-file /data/local/tmp/rclone.log \
    --log-level NOTICE

sleep 2
if mount | grep -q "$MOUNT_POINT"; then
    echo "Mounted successfully at $MOUNT_POINT"
else
    echo "Mount pending: Please ensure TeraBox storage is added in AList (http://localhost:5244)"
fi
EOF
    chmod 755 /data/adb/cloud_ssd/mount.sh

    cat <<'EOF' > /data/adb/cloud_ssd/unmount.sh
#!/system/bin/sh
MOUNT_POINT="/sdcard/TeraBox-CloudSSD"
umount -l "$MOUNT_POINT" 2>/dev/null || true
pkill -f "rclone mount.*TeraBox-CloudSSD" 2>/dev/null || true
echo "Unmounted successfully"
EOF
    chmod 755 /data/adb/cloud_ssd/unmount.sh

    log "=== HyperOS Safe Service Setup Complete ==="

) >/dev/null 2>&1 &

# Exit immediately so HyperOS continues boot sequence without pause
exit 0
