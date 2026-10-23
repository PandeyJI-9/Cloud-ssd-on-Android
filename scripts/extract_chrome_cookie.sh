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

# 2. Pattern scan on Cookies, WAL, and profile files
if [ -z "$COOKIE_VAL" ]; then
    for db in $DB_FILES; do
        db_dir=$(dirname "$db")
        # In SQLite, records store 'ndus' followed directly by the cookie value
        RAW=$(grep -srah -o -E "ndus[a-zA-Z0-9_\-]{20,}" "$db_dir" 2>/dev/null | head -n 1)
        if [ -n "$RAW" ]; then
            # Strip the 'ndus' prefix
            COOKIE_VAL=$(echo "$RAW" | sed 's/^ndus//')
            if [ -n "$COOKIE_VAL" ] && [ ${#COOKIE_VAL} -gt 15 ]; then
                break
            fi
        fi
    done
fi

# 3. Fallback: Full scan of Chrome app directory for ndus pattern
if [ -z "$COOKIE_VAL" ]; then
    RAW=$(grep -srah -o -E "ndus[a-zA-Z0-9_\-]{20,}" "/data/data/$FOUND_PKG/app_chrome" 2>/dev/null | head -n 1)
    if [ -n "$RAW" ]; then
        COOKIE_VAL=$(echo "$RAW" | sed 's/^ndus//')
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
    echo "[!] Could not find 'ndus' cookie in Chrome data."
    echo ""
    echo "Dhyan dein:"
    echo "1. Kya Chrome me https://www.terabox.com ya https://www.1024tera.com logged in hai?"
    echo "   (Make sure incognito mode me nahi, normal Chrome tab me logged in ho)."
    echo "2. Chrome ko ek baar recent apps se swipe close karein taaki cookies disk par save ho jayein."
    echo "3. Phir ye command dobara chalayein!"
    exit 1
fi
