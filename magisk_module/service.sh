#!/system/bin/sh
# ==============================================================================
# Cloud SSD: 100% HyperOS / MIUI Certified Zero-Bootloop Service (v1.1.0)
# Strictly Non-Blocking, AI Dynamic On-Demand Engine, Global Mount Propagation
# ==============================================================================

MODDIR="${0%/*}"

# HYPEROS SAFETY RULE #1: NEVER BLOCK THE MAIN PROCESS!
# The script immediately forks the background subshell and exits 0.
(
    LOGFILE="/data/local/tmp/cloud_ssd.log"
    log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
    }

    log "=== Cloud SSD HyperOS Safe Service Started ==="

    # Wait up to 180 seconds for Android boot completion
    count=0
    while [ "$(getprop sys.boot_completed)" != "1" ] && [ $count -lt 36 ]; do
        sleep 5
        count=$((count + 1))
    done

    # Additional grace period for SurfaceFlinger, Vold, and MediaProvider to settle
    sleep 15
    log "Boot complete detected. Initializing Cloud SSD Engine..."

    # 1. Copy WebUI Dashboard to /sdcard
    if [ -d "/sdcard" ]; then
        cp -f "$MODDIR/webroot/index.html" "/sdcard/CloudSSD-Manager.html" 2>/dev/null || true
    fi

    # 2. Locate Binaries
    ALIST_BIN="$MODDIR/bin/alist"
    RCLONE_BIN="$MODDIR/bin/rclone"

    [ ! -x "$ALIST_BIN" ] && ALIST_BIN="$(command -v alist 2>/dev/null)"
    [ ! -x "$RCLONE_BIN" ] && RCLONE_BIN="$(command -v rclone 2>/dev/null)"

    if [ ! -x "$RCLONE_BIN" ]; then
        log "Warning: rclone binary not available yet."
        exit 0
    fi

    # 3. Start AList Daemon safely in background if alist exists
    ALIST_DATA="/data/adb/cloud_ssd/alist_data"
    mkdir -p "$ALIST_DATA"

    if [ -x "$ALIST_BIN" ] && ! pgrep -f "$ALIST_BIN server" >/dev/null 2>&1; then
        log "Starting AList on port 5244..."
        "$ALIST_BIN" admin set admin123 --data "$ALIST_DATA" >/dev/null 2>&1 || true
        nohup "$ALIST_BIN" server --data "$ALIST_DATA" > "$ALIST_DATA/alist.log" 2>&1 &
        log "AList daemon running."
        sleep 2
    fi

    # 4. Generate Default Rclone Config for WebDAV if not exists
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
        chmod 600 "$RCLONE_CONF"
    fi

    # 5. Create Standalone On-Demand Mount & Unmount Commands
    cat <<'EOF' > /data/adb/cloud_ssd/mount.sh
#!/system/bin/sh
# Elevate to PID 1 Global Mount Namespace
if [ -f "/proc/1/ns/mnt" ] && [ -f "/proc/self/ns/mnt" ]; then
    if [ "$(readlink /proc/1/ns/mnt 2>/dev/null)" != "$(readlink /proc/self/ns/mnt 2>/dev/null)" ]; then
        if command -v nsenter >/dev/null 2>&1; then
            exec nsenter -t 1 -m -- "$0" "$@"
        fi
    fi
fi

REMOTE="${1:-terabox}"
if [ "$REMOTE" = "terabox" ]; then
    FOLDER_NAME="TeraBox-CloudSSD"
elif [ "$REMOTE" = "gdrive" ]; then
    FOLDER_NAME="GoogleDrive-CloudSSD"
else
    FOLDER_NAME="${REMOTE}-CloudSSD"
fi

BASE_MOUNT="/mnt/cloud/$REMOTE"
PRIMARY_STORAGE="/storage/emulated/0/$FOLDER_NAME"
SDCARD_ALIAS="/sdcard/$FOLDER_NAME"
DATA_MEDIA_PATH="/data/media/0/$FOLDER_NAME"
EXT_STORAGE="/storage/$FOLDER_NAME"

RCLONE_BIN=""
for p in /data/adb/modules/cloud_ssd_terabox/bin/rclone /data/cloudssd/bin/rclone /system/bin/rclone /data/local/tmp/rclone; do
    [ -x "$p" ] && RCLONE_BIN="$p" && break
done

[ -z "$RCLONE_BIN" ] && exit 1

if mount | grep -q "$BASE_MOUNT"; then
    echo "Already mounted at $BASE_MOUNT"
    exit 0
fi

# AI Storage Sentinel: Dynamic Cache Mode
DATA_FREE_KB=$(df -k /data 2>/dev/null | awk 'NR==2 {print $4}' || echo "10485760")
DATA_FREE_MB=$((DATA_FREE_KB / 1024))
if [ "$DATA_FREE_MB" -gt 10240 ]; then
    C_MODE="full"; C_SIZE="1G"; C_AGE="10m"
elif [ "$DATA_FREE_MB" -gt 3072 ]; then
    C_MODE="full"; C_SIZE="300M"; C_AGE="5m"
else
    C_MODE="off"; C_SIZE="0M"; C_AGE="1m"
fi

CACHE_DIR="/data/local/tmp/cloudssd_cache"
mkdir -p "$BASE_MOUNT" "$DATA_MEDIA_PATH" "$PRIMARY_STORAGE" "$SDCARD_ALIAS" "$EXT_STORAGE" "$CACHE_DIR" 2>/dev/null || true
chown 1023:1023 "$DATA_MEDIA_PATH" 2>/dev/null || true
chmod 771 "$DATA_MEDIA_PATH" 2>/dev/null || true

"$RCLONE_BIN" mount "${REMOTE}:" "$BASE_MOUNT" \
    --config /data/adb/cloud_ssd/rclone.conf \
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
    --vfs-cache-mode "$C_MODE" \
    --vfs-cache-max-size "$C_SIZE" \
    --vfs-cache-max-age "$C_AGE" \
    --buffer-size 16M \
    --vfs-read-chunk-size 4M \
    --vfs-read-chunk-size-limit 32M \
    --no-modtime \
    --no-checksum \
    --daemon \
    --log-file /data/local/tmp/rclone_${REMOTE}.log \
    --log-level NOTICE

sleep 2

if mount | grep -q "$BASE_MOUNT"; then
    # .nomedia Firewall
    touch "$BASE_MOUNT/.nomedia" 2>/dev/null || true
    chmod 644 "$BASE_MOUNT/.nomedia" 2>/dev/null || true
    touch "$DATA_MEDIA_PATH/.nomedia" 2>/dev/null || true

    # Propagate bind mounts into Android runtime namespaces
    for tgt in "$DATA_MEDIA_PATH" \
               "/mnt/runtime/default/emulated/0/$FOLDER_NAME" \
               "/mnt/runtime/read/emulated/0/$FOLDER_NAME" \
               "/mnt/runtime/write/emulated/0/$FOLDER_NAME" \
               "/mnt/pass_through/0/emulated/0/$FOLDER_NAME" \
               "$PRIMARY_STORAGE" \
               "$SDCARD_ALIAS" \
               "$EXT_STORAGE"; do
        mkdir -p "$tgt" 2>/dev/null || true
        mount -o bind "$BASE_MOUNT" "$tgt" 2>/dev/null || true
    done

    # Virtual SD Card Mode
    if command -v sm >/dev/null 2>&1; then
        sm set-virtual-disk true 2>/dev/null || true
        for p in /storage/*; do
            if [ "$p" != "/storage/emulated" ] && [ "$p" != "/storage/self" ] && [ -d "$p" ]; then
                mount -o bind "$BASE_MOUNT" "$p" 2>/dev/null || true
            fi
        done
    fi

    # Flush file manager apps
    for pkg in ru.zdevs.zarchiver com.mi.android.globalFileexplorer com.android.fileexplorer com.google.android.apps.nbu.files; do
        am force-stop "$pkg" 2>/dev/null || true
    done
    am broadcast -a android.intent.action.MEDIA_MOUNTED -d "file:///sdcard/$FOLDER_NAME" >/dev/null 2>&1 || true
    echo "Mounted successfully at $SDCARD_ALIAS"
else
    echo "Mount pending: Check /data/local/tmp/rclone_${REMOTE}.log"
fi
EOF
    chmod 755 /data/adb/cloud_ssd/mount.sh

    cat <<'EOF' > /data/adb/cloud_ssd/unmount.sh
#!/system/bin/sh
REMOTE="${1:-terabox}"
if [ "$REMOTE" = "terabox" ]; then
    FOLDER_NAME="TeraBox-CloudSSD"
elif [ "$REMOTE" = "gdrive" ]; then
    FOLDER_NAME="GoogleDrive-CloudSSD"
else
    FOLDER_NAME="${REMOTE}-CloudSSD"
fi

for tgt in "/mnt/runtime/default/emulated/0/$FOLDER_NAME" \
           "/mnt/runtime/read/emulated/0/$FOLDER_NAME" \
           "/mnt/runtime/write/emulated/0/$FOLDER_NAME" \
           "/mnt/pass_through/0/emulated/0/$FOLDER_NAME" \
           "/data/media/0/$FOLDER_NAME" \
           "/storage/emulated/0/$FOLDER_NAME" \
           "/sdcard/$FOLDER_NAME" \
           "/storage/$FOLDER_NAME" \
           "/mnt/cloud/$REMOTE"; do
    umount -l "$tgt" 2>/dev/null || true
done

pkill -9 -f "rclone mount.*$REMOTE:" 2>/dev/null || true
rm -rf /data/local/tmp/cloudssd_cache/* 2>/dev/null || true
echo "Unmounted successfully"
EOF
    chmod 755 /data/adb/cloud_ssd/unmount.sh

    # Auto-execute mount on boot!
    log "Triggering automatic boot mount..."
    /data/adb/cloud_ssd/mount.sh terabox >> "$LOGFILE" 2>&1 || true

    log "=== HyperOS Safe Service Setup Complete ==="

) >/dev/null 2>&1 &

exit 0
