#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Standalone Root Installer (Zero-Bootloop, AI Smart On-Demand Engine)
# ==============================================================================

set -e

echo "===================================================="
echo "    ☁️  Cloud SSD: Standalone Root Installer        "
echo "      (100% HyperOS Safe - AI Dynamic Engine)       "
echo "===================================================="

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="/data/cloudssd"

echo "[1/4] Setting up directory structure at $TARGET..."
mkdir -p "$TARGET/bin"
mkdir -p "$TARGET/data"
mkdir -p "/data/local/tmp/cloudssd_cache"
mkdir -p "/sdcard/TeraBox-CloudSSD"
mkdir -p "/sdcard/GoogleDrive-CloudSSD"

echo "[2/4] Installing ARM64 binaries (alist & rclone)..."
if [ -f "$DIR/bin/alist" ]; then
    cp -f "$DIR/bin/alist" "$TARGET/bin/alist"
fi
if [ -f "$DIR/bin/rclone" ]; then
    cp -f "$DIR/bin/rclone" "$TARGET/bin/rclone"
fi

chmod 755 "$TARGET/bin/alist" "$TARGET/bin/rclone" 2>/dev/null || true

echo "[3/4] Installing global 'cloudssd' CLI controller..."
cp -f "$DIR/cloudssd" "$TARGET/cloudssd"
chmod 755 "$TARGET/cloudssd"

# Install smart Termux wrapper (allows typing 'cloudssd' directly at ~ $)
TERMUX_BIN="/data/data/com.termux/files/usr/bin"
if [ -d "$TERMUX_BIN" ]; then
    cat <<'WRAPPER' > "$TERMUX_BIN/cloudssd"
#!/data/data/com.termux/files/usr/bin/sh
if [ "$(id -u)" -eq 0 ]; then
    exec /data/cloudssd/cloudssd "$@"
else
    exec su -c "/data/cloudssd/cloudssd \"$@\""
fi
WRAPPER
    chmod 755 "$TERMUX_BIN/cloudssd" 2>/dev/null || true
fi

# Link to all root PATH directories so 'su -c cloudssd' also works
for p in /data/adb/ap/bin /data/adb/magisk /data/adb/ksu/bin /sbin /data/local/tmp; do
    if [ -d "$p" ]; then
        cp -f "$TARGET/cloudssd" "$p/cloudssd" 2>/dev/null && chmod 755 "$p/cloudssd" 2>/dev/null || true
    fi
done

cp -f "$TARGET/cloudssd" /data/local/tmp/cloudssd
chmod 755 /data/local/tmp/cloudssd

# Add alias to Termux profile if exists
TERMUX_HOME="/data/data/com.termux/files/home"
if [ -d "$TERMUX_HOME" ]; then
    if ! grep -q "cloudssd" "$TERMUX_HOME/.bashrc" 2>/dev/null; then
        echo 'alias cloudssd="su -c /data/cloudssd/cloudssd"' >> "$TERMUX_HOME/.bashrc" 2>/dev/null || true
    fi
fi

echo "[4/4] Creating WebUI Dashboard shortcut..."
cat <<'EOF' > /sdcard/CloudSSD-Dashboard.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloud SSD Dashboard</title>
    <style>
        body { font-family: -apple-system, Roboto, sans-serif; background: #0d1117; color: #c9d1d9; padding: 20px; text-align: center; }
        .card { background: #161b22; border: 1px solid #30363d; border-radius: 12px; padding: 20px; margin-bottom: 20px; text-align: left; }
        h1 { color: #58a6ff; font-size: 1.4rem; margin-bottom: 10px; }
        .btn { display: block; width: 100%; padding: 14px; margin: 10px 0; background: #238636; color: #fff; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 1rem; border: none; cursor: pointer; text-align: center; box-sizing: border-box; }
        .btn-blue { background: #1f6feb; }
        code { background: #21262d; padding: 4px 8px; border-radius: 6px; font-family: monospace; color: #58a6ff; }
        .badge { background: #238636; color: white; padding: 2px 8px; border-radius: 10px; font-size: 0.8rem; }
    </style>
</head>
<body>
    <h1>☁️ Cloud SSD Dashboard</h1>
    <p style="color: #8b949e; margin-bottom: 20px;">Virtual SSD Engine for Android (Google Drive & TeraBox)</p>

    <div class="card">
        <h3>🧠 AI Dynamic On-Demand Loading <span class="badge">ACTIVE</span></h3>
        <p style="font-size: 0.9rem; color: #8b949e;">Your whole drive is <b>NEVER</b> downloaded to your phone. Only requested chunks (4MB-32MB) stream on-demand like Netflix/YouTube, leaving phone storage untouched.</p>
    </div>

    <div class="card">
        <h3>⚡ Terminal Commands (Termux / Root)</h3>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">Mount Google Drive:</p>
        <code>su -c cloudssd mount gdrive</code>
        <br><br>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">Mount TeraBox 1TB:</p>
        <code>su -c cloudssd mount terabox</code>
        <br><br>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">Enable Virtual SD Card Volume (Settings -> Storage):</p>
        <code>su -c cloudssd sdcard-mode on</code>
        <br><br>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">Check Live Status & AI Policy:</p>
        <code>su -c cloudssd status</code>
        <br><br>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">Run AI Storage Cleanup:</p>
        <code>su -c cloudssd ai-optimize</code>
        <br><br>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">Unmount safely:</p>
        <code>su -c cloudssd unmount</code>
    </div>

    <div class="card">
        <h3>📂 Storage Locations</h3>
        <p style="font-size: 0.9rem;">Internal Storage Path:</p>
        <code style="word-break: break-all;">/sdcard/GoogleDrive-CloudSSD</code><br><br>
        <code style="word-break: break-all;">/sdcard/TeraBox-CloudSSD</code>
    </div>
</body>
</html>
EOF

echo ""
echo "===================================================="
echo "    ✓ Cloud SSD Installation Complete!              "
echo "===================================================="
echo "Run: 'su -c cloudssd mount gdrive' or 'su -c cloudssd mount terabox'"
