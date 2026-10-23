#!/system/bin/sh
# ==============================================================================
# Cloud SSD: Extract TeraBox Cookie from Installed Android App (Root)
# ==============================================================================

echo "===================================================="
echo "    🔍 TeraBox Cookie Auto-Extractor (Root Mode)    "
echo "===================================================="

# Find package name
PKG=""
for p in com.dubox.drive com.flextech.terabox; do
    if [ -d "/data/data/$p" ]; then
        PKG="$p"
        break
    fi
done

if [ -z "$PKG" ]; then
    # Try pm list
    PKG=$(pm list packages 2>/dev/null | grep -E "dubox|terabox" | head -n 1 | cut -d: -f2)
fi

if [ -z "$PKG" ] || [ ! -d "/data/data/$PKG" ]; then
    echo "[X] Error: TeraBox App not found in /data/data/!"
    echo "    Make sure the official TeraBox App is installed and logged in."
    exit 1
fi

echo "[+] Found TeraBox App package: $PKG"
echo "[*] Searching app private data for 'ndus' cookie..."

COOKIE=""

# 1. Search SQLite WebView Cookies
for db in /data/data/$PKG/app_webview/Default/Cookies \
          /data/data/$PKG/app_webview/Cookies \
          /data/data/$PKG/databases/webview.db \
          /data/data/$PKG/databases/webviewCookiesChromium.db; do
    if [ -f "$db" ]; then
        # Try sqlite3 if available
        if command -v sqlite3 >/dev/null 2>&1; then
            VAL=$(sqlite3 "$db" "SELECT value FROM cookies WHERE name='ndus';" 2>/dev/null)
            if [ -n "$VAL" ]; then
                COOKIE="ndus=$VAL"
                break
            fi
        fi
        # Try strings extraction
        STR_VAL=$(strings "$db" 2>/dev/null | grep -A 1 "^ndus$" | tail -n 1)
        if [ -n "$STR_VAL" ] && [ ${#STR_VAL} -gt 15 ]; then
            COOKIE="ndus=$STR_VAL"
            break
        fi
    fi
done

# 2. Search shared_prefs XML
if [ -z "$COOKIE" ] && [ -d "/data/data/$PKG/shared_prefs" ]; then
    MATCH=$(grep -rhoE "ndus=[a-zA-Z0-9_\-]+" /data/data/$PKG/shared_prefs/ 2>/dev/null | head -n 1)
    if [ -n "$MATCH" ]; then
        COOKIE="$MATCH"
    fi
fi

# 3. Deep search all text/data in sandbox
if [ -z "$COOKIE" ]; then
    MATCH=$(grep -rhoE "ndus=[a-zA-Z0-9_\-]+" /data/data/$PKG/ 2>/dev/null | head -n 1)
    if [ -n "$MATCH" ]; then
        COOKIE="$MATCH"
    fi
fi

# 4. Search installed browsers (Kiwi, Chrome)
if [ -z "$COOKIE" ]; then
    for browser in com.kiwibrowser.browser com.android.chrome mark.via.gp; do
        if [ -d "/data/data/$browser" ]; then
            MATCH=$(grep -sraoE "ndus=[a-zA-Z0-9_\-]{15,}" "/data/data/$browser" 2>/dev/null | head -n 1 | cut -d: -f2-)
            if [ -n "$MATCH" ]; then
                COOKIE="$MATCH"
                break
            fi
        fi
    done
fi

if [ -n "$COOKIE" ]; then
    echo ""
    echo "===================================================="
    echo "  🎉 SUCCESS! TeraBox Cookie Found:                 "
    echo "===================================================="
    echo "$COOKIE"
    echo "===================================================="
    echo "Copy this value and paste it into AList -> Storages -> TeraBox -> Cookie!"
    
    # Save to /sdcard for easy copy
    echo "$COOKIE" > /sdcard/terabox_cookie.txt
    echo "(Also saved to /sdcard/terabox_cookie.txt for easy copy!)"
else
    echo "[!] 'ndus' cookie not found in mobile app data."
    echo "    (The native TeraBox app uses OAuth tokens, not browser session cookies)."
    echo ""
    echo "💡 HOW TO GET 'ndus' IN 2 MINUTES ON PHONE:"
    echo "1. Install 'Kiwi Browser' from Play Store."
    echo "2. Add 'Cookie-Editor' extension from Chrome Web Store."
    echo "3. Open https://www.terabox.com (or https://www.1024tera.com)."
    echo "4. Tap 3 dots -> Check 'Desktop site' -> Sign in with Google."
    echo "5. Tap 3 dots -> Cookie-Editor -> Copy 'ndus' value!"
fi
