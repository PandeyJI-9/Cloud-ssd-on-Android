#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Start AList Middleware Daemon
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if alist is installed
if ! command -v alist >/dev/null 2>&1; then
    echo -e "${RED}[X] Error: alist binary not found! Please run scripts/install_dependencies_termux.sh first.${NC}"
    exit 1
fi

# Check if already running
if pgrep -x "alist" >/dev/null; then
    echo -e "${YELLOW}[!] AList is already running (PID: $(pgrep -x alist)).${NC}"
    echo -e "WebDAV Endpoint: ${GREEN}http://127.0.0.1:5244/dav${NC}"
    echo -e "Dashboard:       ${GREEN}http://127.0.0.1:5244${NC}"
    exit 0
fi

DATA_DIR="$HOME/.alist"
mkdir -p "$DATA_DIR"

echo -e "${GREEN}[+] Starting AList Daemon in background...${NC}"
nohup alist server --data "$DATA_DIR" > "$DATA_DIR/alist.log" 2>&1 &

sleep 2

if pgrep -x "alist" >/dev/null; then
    echo -e "${GREEN}[✓] AList started successfully! (PID: $(pgrep -x alist))${NC}"
    echo -e "----------------------------------------------------"
    echo -e "Dashboard URL:   ${GREEN}http://127.0.0.1:5244${NC}"
    echo -e "WebDAV URL:      ${GREEN}http://127.0.0.1:5244/dav${NC}"
    echo -e "Log file:        $DATA_DIR/alist.log"
    echo -e "----------------------------------------------------"
else
    echo -e "${RED}[X] Failed to start AList. Check logs at: $DATA_DIR/alist.log${NC}"
    exit 1
fi
