#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Extract TeraBox 'ndus' Cookie from Google Chrome (Root Mode)
# ==============================================================================

echo "===================================================="
echo "  🌐 Chrome TeraBox Cookie Extractor (Root Mode)    "
echo "===================================================="

# Check root
if [ "$(id -u)" != "0" ]; then
    echo "[!] Please run with root privileges (su)!"
    exit 1
fi

CHROME_PKGS="com.android.chrome com.chrome.beta com.chrome.canary com.chrome.dev com.google.android.apps.chrome"
FOUND_PKG=""

for pkg in $CHROME_PKGS; do
    if [ -d "/data/data/$pkg" ]; then
        FOUND_PKG="$pkg"
        break
    fi
done

if [ -z "$FOUND_PKG" ]; then
    echo "[X] Error: Google Chrome not found in /data/data/!"
    exit 1
fi

echo "[+] Found Chrome Package: $FOUND_PKG"
echo "[*] Closing Chrome cleanly to flush cookies to disk..."
am force-stop "$FOUND_PKG" 2>/dev/null
sleep 1

echo "[*] Searching Chrome storage for TeraBox 'ndus' cookie..."

COOKIE_VAL=""
TMP_DIR="/data/local/tmp/chrome_cookie_extract"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# 1. Search Chrome SQLite databases using sqlite3 if available
DB_FILES=$(find "/data/data/$FOUND_PKG/app_chrome" -name "Cookies" 2>/dev/null)

if command -v sqlite3 >/dev/null 2>&1; then
    for db in $DB_FILES; do
        db_dir=$(dirname "$db")
        # Copy db and WAL/SHM to tmp
        cp "$db"* "$TMP_DIR/" 2>/dev/null
        tmp_db="$TMP_DIR/Cookies"
        if [ -f "$tmp_db" ]; then
            VAL=$(sqlite3 "$tmp_db" "SELECT value FROM cookies WHERE (host_key LIKE '%terabox%' OR host_key LIKE '%1024tera%' OR host_key LIKE '%dubox%') AND name='ndus' LIMIT 1;" 2>/dev/null)
            if [ -n "$VAL" ] && [ ${#VAL} -gt 15 ]; then
                COOKIE_VAL="$VAL"
                break
            fi
        fi
        rm -rf "$TMP_DIR"/*
    done
fi

# 2. Targeted pattern scan on Cookies, WAL, and profile files
if [ -z "$COOKIE_VAL" ]; then
    for db in $DB_FILES; do
        db_dir=$(dirname "$db")
        # In SQLite, records store 'terabox.comndus' followed directly by the cookie value
        RAW=$(grep -srah -o -E "([a-zA-Z0-9_\-\.]*)(terabox|1024tera|dubox)\.comndus[a-zA-Z0-9_\-]+" "$db_dir" 2>/dev/null | head -n 1)
        if [ -n "$RAW" ]; then
            # Strip everything up to ndus
            COOKIE_VAL=$(echo "$RAW" | sed -E 's/.*ndus//')
            if [ -n "$COOKIE_VAL" ] && [ ${#COOKIE_VAL} -gt 15 ]; then
                break
            fi
        fi
    done
fi

# 3. Fallback: Search all Cookies* files across Chrome
if [ -z "$COOKIE_VAL" ]; then
    RAW=$(find "/data/data/$FOUND_PKG/app_chrome" -name "Cookies*" -exec grep -aoE "([a-zA-Z0-9_\-\.]*)(terabox|1024tera|dubox)\.comndus[a-zA-Z0-9_\-]+" {} + 2>/dev/null | head -n 1)
    if [ -n "$RAW" ]; then
        COOKIE_VAL=$(echo "$RAW" | sed -E 's/.*ndus//')
    fi
fi

# 4. Fallback: Search strings output for ndus key-value
if [ -z "$COOKIE_VAL" ]; then
    for db in $DB_FILES; do
        VAL=$(strings "$db" 2>/dev/null | grep -A 1 "^ndus$" | tail -n 1)
        if [ -n "$VAL" ] && [ ${#VAL} -gt 15 ]; then
            COOKIE_VAL="$VAL"
            break
        fi
    done
fi

# Clean up tmp
rm -rf "$TMP_DIR"

if [ -n "$COOKIE_VAL" ]; then
    FULL_COOKIE="ndus=$COOKIE_VAL"
    echo ""
    echo "===================================================="
    echo "  🎉 SUCCESS! TeraBox Cookie Found in Chrome:       "
    echo "===================================================="
    echo ""
    echo "$FULL_COOKIE"
    echo ""
    echo "===================================================="
    # Save to /sdcard
    echo "$FULL_COOKIE" > /sdcard/terabox_cookie.txt
    echo "✓ Saved to: /sdcard/terabox_cookie.txt"
    echo "  (Open /sdcard/terabox_cookie.txt to copy easily!)"
    echo "===================================================="
    echo ""
    echo "Next: Paste it into AList -> Storages -> TeraBox -> Cookie!"
    exit 0
else
    echo ""
    echo "[!] Could not automatically parse 'ndus' cookie."
    echo ""
    echo "[*] Diagnostic Check (What is inside Chrome Cookies for TeraBox?):"
    find "/data/data/$FOUND_PKG/app_chrome" -name "Cookies*" -exec strings {} + 2>/dev/null | grep -i -E "terabox|1024tera|dubox" | head -n 10
    echo ""
    echo "Tip: Make sure you are logged into https://www.terabox.com in Google Chrome (not incognito)!"
    exit 1
fi
