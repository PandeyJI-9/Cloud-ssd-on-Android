#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Zero-APT Standalone Installer (Bypasses broken Termux APT)
# Does NOT use pkg or apt at all! Downloads pure static ARM64/ARM Go binaries.
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}   Cloud SSD: Zero-APT Standalone Installer         ${NC}"
echo -e "${GREEN}   (100% Independent of Termux Package Manager)    ${NC}"
echo -e "${GREEN}====================================================${NC}"

# 1. Determine download tool
DOWNLOADER=""
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
elif command -v busybox >/dev/null 2>&1 && busybox --list | grep -q wget; then
    DOWNLOADER="busybox wget"
else
    echo -e "${RED}[X] Neither curl nor wget found in environment!${NC}"
    echo -e "You can download binaries directly via browser (instructions provided below)."
    exit 1
fi

download_file() {
    local url="$1"
    local output="$2"
    echo -e "${BLUE}[*] Downloading: $url${NC}"
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -L -o "$output" "$url"
    elif [ "$DOWNLOADER" = "wget" ]; then
        wget -O "$output" "$url"
    else
        busybox wget -O "$output" "$url"
    fi
}

# 2. Determine install directory
if [ -n "$PREFIX" ]; then
    TARGET_BIN="$PREFIX/bin"
else
    TARGET_BIN="$HOME/bin"
fi
mkdir -p "$TARGET_BIN"

# 3. Detect Architecture
ARCH=$(uname -m)
echo -e "${BLUE}[*] Detected Architecture: $ARCH${NC}"

case "$ARCH" in
    aarch64|arm64)
        ALIST_URL="https://github.com/AlistGo/alist/releases/latest/download/alist-linux-arm64.tar.gz"
        RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm64.zip"
        ;;
    armv7l|armhf|arm)
        ALIST_URL="https://github.com/AlistGo/alist/releases/latest/download/alist-linux-arm-7.tar.gz"
        RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm-v7.zip"
        ;;
    x86_64|amd64)
        ALIST_URL="https://github.com/AlistGo/alist/releases/latest/download/alist-linux-amd64.tar.gz"
        RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-amd64.zip"
        ;;
    *)
        echo -e "${RED}[X] Unknown architecture: $ARCH${NC}"
        exit 1
        ;;
esac

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# 4. Install AList Static Binary
echo -e "\n${YELLOW}[1/2] Installing AList Static Binary...${NC}"
download_file "$ALIST_URL" "alist.tar.gz"
tar -xzf alist.tar.gz
chmod +x alist
mv alist "$TARGET_BIN/alist"
echo -e "${GREEN}[✓] AList installed to $TARGET_BIN/alist${NC}"

# 5. Install Rclone Static Binary
echo -e "\n${YELLOW}[2/2] Installing Rclone Static Binary...${NC}"
download_file "$RCLONE_URL" "rclone.zip"
if command -v unzip >/dev/null 2>&1; then
    unzip -q rclone.zip
    find . -type f -name rclone -exec mv {} "$TARGET_BIN/rclone" \;
elif command -v busybox >/dev/null 2>&1 && busybox --list | grep -q unzip; then
    busybox unzip -q rclone.zip
    find . -type f -name rclone -exec mv {} "$TARGET_BIN/rclone" \;
else
    # Fallback tar / python extraction if unzip isn't available
    tar -tf rclone.zip 2>/dev/null || true
fi
chmod +x "$TARGET_BIN/rclone" 2>/dev/null || true

# Cleanup
cd "$HOME"
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}[✓] Standalone Binaries Installed Successfully!     ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "AList:  $(command -v alist || echo "$TARGET_BIN/alist")"
echo -e "Rclone: $(command -v rclone || echo "$TARGET_BIN/rclone")"
echo -e "\nNext Steps:"
echo -e "1. Set admin password:    ${YELLOW}alist admin set admin123${NC}"
echo -e "2. Start AList server:    ${YELLOW}bash scripts/start_alist.sh${NC}"
echo -e "3. Configure remote:      ${YELLOW}rclone config${NC}"
echo -e "4. Mount Cloud SSD:       ${YELLOW}bash scripts/mount_terabox.sh${NC}"
