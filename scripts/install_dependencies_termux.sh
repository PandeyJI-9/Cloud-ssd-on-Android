#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Termux Setup & Dependency Installer
# Installs Rclone, FUSE3, and downloads prebuilt AList binary for ARM64/ARM
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}      Cloud SSD: Installing Termux Core Packages     ${NC}"
echo -e "${GREEN}====================================================${NC}"

# Check Termux environment
if [ -z "$PREFIX" ]; then
    echo -e "${YELLOW}[!] Warning: Not running directly inside Termux environment, continuing...${NC}"
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="$PREFIX/bin"
fi

# 1. Update and install dependencies
echo -e "\n${YELLOW}[1/4] Updating package repos & installing tools...${NC}"
if command -v pkg >/dev/null 2>&1; then
    pkg update -y
    pkg install -y curl wget tar rclone fuse3 psmisc jq tsu
elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y curl wget tar rclone fuse3 psmisc jq
fi

# 2. Detect Architecture for AList binary
echo -e "\n${YELLOW}[2/4] Detecting architecture...${NC}"
ARCH=$(uname -m)
ALIST_ARCH=""

case "$ARCH" in
    aarch64|arm64)
        ALIST_ARCH="linux-arm64"
        ;;
    armv7l|armhf)
        ALIST_ARCH="linux-arm-7"
        ;;
    x86_64|amd64)
        ALIST_ARCH="linux-amd64"
        ;;
    *)
        echo -e "${RED}[X] Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}[+] Detected architecture: $ARCH -> Package: alist-$ALIST_ARCH.tar.gz${NC}"

# 3. Download & Install AList
echo -e "\n${YELLOW}[3/4] Fetching latest AList binary from GitHub...${NC}"
TEMP_DIR=$(mktemp -d)
DOWNLOAD_URL="https://github.com/AlistGo/alist/releases/latest/download/alist-$ALIST_ARCH.tar.gz"

echo "Downloading from: $DOWNLOAD_URL"
curl -L --progress-bar -o "$TEMP_DIR/alist.tar.gz" "$DOWNLOAD_URL"

tar -xzf "$TEMP_DIR/alist.tar.gz" -C "$TEMP_DIR"
chmod +x "$TEMP_DIR/alist"

if [ -w "$INSTALL_DIR" ]; then
    mv "$TEMP_DIR/alist" "$INSTALL_DIR/alist"
else
    su -c "mv $TEMP_DIR/alist $INSTALL_DIR/alist && chmod 755 $INSTALL_DIR/alist"
fi

rm -rf "$TEMP_DIR"
echo -e "${GREEN}[+] AList installed successfully at: $INSTALL_DIR/alist${NC}"

# 4. Initialize AList and print initial password
echo -e "\n${YELLOW}[4/4] Initializing AList Admin Credentials...${NC}"
alist admin set admin123 || alist admin

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}             Installation Completed!               ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Next steps:"
echo -e " 1. Start AList server:       ${YELLOW}bash scripts/start_alist.sh${NC}"
echo -e " 2. Open in browser:          ${YELLOW}http://127.0.0.1:5244${NC}"
echo -e " 3. Default Username:         ${GREEN}admin${NC}"
echo -e " 4. Default Password:         ${GREEN}admin123${NC}"
echo -e " 5. Add TeraBox in AList dashboard, then run ${YELLOW}bash scripts/mount_terabox.sh${NC}"
