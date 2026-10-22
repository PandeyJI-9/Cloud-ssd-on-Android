#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Publish Flashable Magisk Module to GitHub Releases (Python-powered)
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:-v1.0.1}"
ZIP_PATH="${2:-$ROOT_DIR/CloudSSD-TeraBox-v1.0.1-Lite.zip}"
GH_USER="PandeyJI-9"
GH_REPO="Cloud-ssd-on-Android"

# Fetch token
GH_TOKEN="${GITHUB_TOKEN:-}"
if [ -z "$GH_TOKEN" ] && [ -f "$HOME/.config/gh/hosts.yml" ]; then
    GH_TOKEN=$(grep -A 5 "github.com:" "$HOME/.config/gh/hosts.yml" | grep "oauth_token:" | head -n 1 | awk '{print $2}')
fi

if [ -z "$GH_TOKEN" ]; then
    echo -e "${RED}[X] Error: GITHUB_TOKEN not found!${NC}"
    exit 1
fi

if [ ! -f "$ZIP_PATH" ]; then
    echo -e "${RED}[X] Error: $ZIP_PATH not found! Run scripts/build_magisk_module.sh first.${NC}"
    exit 1
fi

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}   Publishing Magisk Module to GitHub Releases      ${NC}"
echo -e "${GREEN}====================================================${NC}"

# 1. Create Git Tag & Push
cd "$ROOT_DIR"
git tag -f "$TAG" 2>/dev/null || true
git push -f "https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git" "$TAG" 2>/dev/null || true

# 2. Check if Release already exists
EXISTING_RELEASE_INFO=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/${GH_USER}/${GH_REPO}/releases/tags/$TAG")

EXISTING_RELEASE_ID=$(python3 -c "import sys, json; data=json.loads(sys.stdin.read()); print(data.get('id', ''))" <<< "$EXISTING_RELEASE_INFO")

if [ -n "$EXISTING_RELEASE_ID" ] && [ "$EXISTING_RELEASE_ID" != "None" ]; then
    echo -e "${YELLOW}[!] Release $TAG exists (ID: $EXISTING_RELEASE_ID). Deleting old release...${NC}"
    curl -s -X DELETE -H "Authorization: token $GH_TOKEN" \
        "https://api.github.com/repos/${GH_USER}/${GH_REPO}/releases/$EXISTING_RELEASE_ID"
fi

# 3. Create New GitHub Release
echo -e "${BLUE}[*] Creating GitHub Release $TAG...${NC}"
RELEASE_BODY="### ☁️ Cloud SSD - TeraBox 1TB Virtual Drive for Android

#### ✨ Key Highlights:
- **Zero-Bootloop Guaranteed:** Runs strictly in late_start after system boot completion. Never blocks Zygote or Android UI.
- **Embedded ARM64 Static Binaries:** Built-in AList & Rclone binaries (No Termux or APT required!).
- **Built-in WebUI Manager:** Interactive control dashboard for KernelSU / APatch / MMRL and mobile Chrome.
- **Global Mount Namespace Injection:** Drive is visible in ZArchiver, MiXplorer, Solid Explorer, and Emulators!

#### 📲 How to Flash:
1. Download **CloudSSD-TeraBox-v1.0.0.zip** below.
2. Open **Magisk** or **KernelSU** App -> **Modules** -> **Install from storage**.
3. Select this ZIP file and reboot.
4. Open \`http://localhost:5244\` in browser to link your TeraBox account!
"

RELEASE_PAYLOAD=$(python3 -c "
import json, sys
print(json.dumps({
    'tag_name': sys.argv[1],
    'name': sys.argv[2],
    'body': sys.argv[3],
    'draft': False,
    'prerelease': False
}))
" "$TAG" "Cloud SSD Magisk Module v1.0.0 (Zero-Bootloop + WebUI)" "$RELEASE_BODY")

RELEASE_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $GH_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$RELEASE_PAYLOAD" \
    "https://api.github.com/repos/${GH_USER}/${GH_REPO}/releases")

UPLOAD_URL=$(python3 -c "import sys, json; data=json.loads(sys.stdin.read()); print(data.get('upload_url', '').split('{')[0])" <<< "$RELEASE_RESPONSE")
RELEASE_ID=$(python3 -c "import sys, json; data=json.loads(sys.stdin.read()); print(data.get('id', ''))" <<< "$RELEASE_RESPONSE")

if [ -z "$UPLOAD_URL" ] || [ "$UPLOAD_URL" = "None" ]; then
    echo -e "${RED}[X] Failed to create release. Response:${NC}"
    echo "$RELEASE_RESPONSE"
    exit 1
fi

echo -e "${GREEN}[✓] Release created! ID: $RELEASE_ID${NC}"

# 4. Upload Flashable ZIP Asset
echo -e "${BLUE}[*] Uploading CloudSSD-TeraBox-v1.0.0.zip ($(du -h "$ZIP_PATH" | cut -f1)) to GitHub Release...${NC}"
UPLOAD_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $GH_TOKEN" \
    -H "Content-Type: application/zip" \
    --data-binary @"$ZIP_PATH" \
    "${UPLOAD_URL}?name=CloudSSD-TeraBox-v1.0.0.zip")

BROWSER_DOWNLOAD_URL=$(python3 -c "import sys, json; data=json.loads(sys.stdin.read()); print(data.get('browser_download_url', ''))" <<< "$UPLOAD_RESPONSE")

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}[✓] SUCCESS: Magisk Module Published to GitHub!      ${NC}"
echo -e "Direct Download Link: ${YELLOW}$BROWSER_DOWNLOAD_URL${NC}"
echo -e "Release Page:         ${BLUE}https://github.com/${GH_USER}/${GH_REPO}/releases/tag/${TAG}${NC}"
echo -e "${GREEN}====================================================${NC}"
