#!/system/bin/sh
# ==============================================================================
# Cloud SSD: MMKV Deep Scanner for TeraBox Tokens
# ==============================================================================

echo "===================================================="
echo "    🔍 Scanning TeraBox MMKV Storage for Cookie     "
echo "===================================================="

MMKV_FILE="/data/data/com.dubox.drive/shared_prefs/globalduboxdisk.mmkv"

if [ ! -f "$MMKV_FILE" ]; then
    # Search for all mmkv files
    MMKV_FILE=$(find /data/data/com.dubox.drive -name "*dubox*.mmkv" 2>/dev/null | head -n 1)
fi

echo "[+] Target file: $MMKV_FILE"

OUTFILE="/sdcard/terabox_keys.txt"
rm -f "$OUTFILE"

# Extract all readable strings of length >= 10
if command -v strings >/dev/null 2>&1; then
    strings "$MMKV_FILE" > "$OUTFILE"
else
    tr -cd '[:print:]\n' < "$MMKV_FILE" | grep -oE "[a-zA-Z0-9_\-\.]{8,}" > "$OUTFILE"
fi

echo "[*] Extracted strings saved to: $OUTFILE"
echo ""
echo "=== POTENTIAL TOKENS & COOKIES FOUND ==="

# 1. Search for ndus specifically
grep -i "ndus" "$OUTFILE" 2>/dev/null || true

# 2. Search for bdstoken
grep -i "bdstoken" "$OUTFILE" 2>/dev/null || true

# 3. Look for long auth hashes (32 to 128 chars)
echo ""
echo "=== Long Session Hashes (Copy the one starting with Y or matching your token) ==="
grep -E "^[a-zA-Z0-9_\-]{32,150}$" "$OUTFILE" | head -n 15

echo ""
echo "===================================================="
echo "Full dump is in /sdcard/terabox_keys.txt"
echo "===================================================="
