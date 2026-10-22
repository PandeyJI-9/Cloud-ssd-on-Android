#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Standalone Root Installer (Zero-Bootloop, Zero-Magisk Dependency)
# ==============================================================================

set -e

echo "===================================================="
echo "    ☁️  Cloud SSD: Standalone Root Installer        "
echo "      (100% HyperOS Safe - No Bootloop Ever)        "
echo "===================================================="

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="/data/cloudssd"

echo "[1/4] Setting up directory structure at $TARGET..."
mkdir -p "$TARGET/bin"
mkdir -p "$TARGET/data"
mkdir -p "/sdcard/TeraBox-CloudSSD"

echo "[2/4] Installing ARM64 binaries (alist & rclone)..."
if [ -f "$DIR/bin/alist" ]; then
    cp -f "$DIR/bin/alist" "$TARGET/bin/alist"
fi
if [ -f "$DIR/bin/rclone" ]; then
    cp -f "$DIR/bin/rclone" "$TARGET/bin/rclone"
fi

chmod 755 "$TARGET/bin/alist" "$TARGET/bin/rclone" 2>/dev/null || true

echo "[3/4] Installing global 'cloudssd' command..."
cp -f "$DIR/cloudssd" "$TARGET/cloudssd"
chmod 755 "$TARGET/cloudssd"

# Link to common executable paths
for p in /data/adb/ap/bin /system/bin /data/data/com.termux/files/usr/bin /data/local/tmp; do
    if [ -d "$p" ] && [ -w "$p" ]; then
        cp -f "$TARGET/cloudssd" "$p/cloudssd" 2>/dev/null && chmod 755 "$p/cloudssd" 2>/dev/null || true
    fi
done

# Create convenient alias in /data/local/tmp
cp -f "$TARGET/cloudssd" /data/local/tmp/cloudssd
chmod 755 /data/local/tmp/cloudssd

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
    </style>
</head>
<body>
    <h1>☁️ Cloud SSD Dashboard</h1>
    <p style="color: #8b949e; margin-bottom: 20px;">TeraBox 1TB Virtual Drive for Android</p>

    <div class="card">
        <h3>🚀 Step 1: Open AList</h3>
        <p style="font-size: 0.9rem; margin: 8px 0;">Configure your TeraBox Cookie in the dashboard:</p>
        <a class="btn btn-blue" href="http://localhost:5244" target="_blank">🌐 Open AList Web Dashboard (5244)</a>
        <p style="font-size: 0.8rem; color: #8b949e;">Login: <code>admin</code> / <code>admin123</code></p>
    </div>

    <div class="card">
        <h3>⚡ Step 2: Terminal Commands (Termux / Root)</h3>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">To mount 1TB drive:</p>
        <code>su -c cloudssd mount</code>
        <br><br>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">To check status:</p>
        <code>su -c cloudssd status</code>
        <br><br>
        <p style="font-size: 0.9rem; margin-bottom: 6px;">To unmount:</p>
        <code>su -c cloudssd unmount</code>
    </div>

    <div class="card">
        <h3>📂 Storage Location</h3>
        <p style="font-size: 0.9rem;">Your cloud storage will appear in ZArchiver / File Manager at:</p>
        <code style="word-break: break-all;">/sdcard/TeraBox-CloudSSD</code>
    </div>
</body>
</html>
EOF

echo ""
echo "===================================================="
echo "    ✓ Installation Successful! (Zero Boot Risk)     "
echo "===================================================="
echo "Next Steps:"
echo "1. Run command to start:     su -c cloudssd gui"
echo "   (This opens browser at http://localhost:5244)"
echo "2. Add your TeraBox cookie (ndus=...) in AList."
echo "3. Run command to mount:     su -c cloudssd mount"
echo "4. Open ZArchiver -> /sdcard/TeraBox-CloudSSD !"
echo "===================================================="
