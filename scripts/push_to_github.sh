#!/usr/bin/env bash
# ==============================================================================
# Cloud SSD: Push Project to GitHub Helper Script
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}       Cloud SSD: GitHub Push Automation            ${NC}"
echo -e "${GREEN}====================================================${NC}"

GH_USER="${1:-PandeyJI-9}"
GH_REPO="${2:-Cloud-ssd-on-Android}"
GH_TOKEN="$3"

if [ -z "$GH_TOKEN" ]; then
    read -s -p "Enter your GitHub Personal Access Token (PAT): " GH_TOKEN
    echo ""
fi

# Ensure git is installed
if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}[X] Error: git is not installed!${NC}"
    exit 1
fi

cd "$(dirname "$0")/.."

# Set git identity
git config user.name "$GH_USER"
git config user.email "${GH_USER}@users.noreply.github.com"

echo -e "${BLUE}[*] Staging all files...${NC}"
git add .

if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${BLUE}[*] Creating commit...${NC}"
    git commit -m "feat: complete cloud ssd setup for PandeyJI-9/Cloud-ssd-on-Android"
else
    echo -e "${YELLOW}[!] Working tree clean, nothing new to commit.${NC}"
fi

# Construct Remote URL
if [ -n "$GH_TOKEN" ]; then
    REMOTE_URL="https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git"
else
    REMOTE_URL="https://github.com/${GH_USER}/${GH_REPO}.git"
fi

if git remote | grep -q "^origin$"; then
    echo -e "${BLUE}[*] Updating origin remote to: https://github.com/${GH_USER}/${GH_REPO}.git${NC}"
    git remote set-url origin "$REMOTE_URL"
else
    echo -e "${BLUE}[*] Adding origin remote: https://github.com/${GH_USER}/${GH_REPO}.git${NC}"
    git remote add origin "$REMOTE_URL"
fi

echo -e "\n${YELLOW}[*] Pushing to GitHub (main branch)...${NC}"
git push -u origin main

# Clean token from stored remote URL for safety
git remote set-url origin "https://github.com/${GH_USER}/${GH_REPO}.git"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}[✓] SUCCESS: Repository successfully pushed to GitHub!${NC}"
echo -e "View your repo at: ${BLUE}https://github.com/${GH_USER}/${GH_REPO}${NC}"
echo -e "${GREEN}====================================================${NC}"
