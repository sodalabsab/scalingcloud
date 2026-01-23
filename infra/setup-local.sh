#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "🔍 ${YELLOW}Checking Local Development Prerequisites...${NC}"

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Error: Git is not installed.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Git is installed${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker is not installed.${NC}"
    exit 1
fi

# Check Docker Daemon
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Error: Docker daemon is not running. Please start Docker Desktop.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker is installed and running${NC}"

# Check K6
if ! command -v k6 &> /dev/null; then
    echo -e "${RED}❌ Error: k6 is not installed. (Required for Lab 2)${NC}"
    echo -e "${YELLOW}👉 Install k6: https://k6.io/docs/get-started/installation/${NC}"
    exit 1
fi
echo -e "${GREEN}✅ k6 is installed${NC}"

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: GitHub CLI ('gh') is not installed. (Required for Cloud Setup later)${NC}"
else
    echo -e "${GREEN}✅ GitHub CLI is installed${NC}"
    # Check login
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: You are not logged into GitHub. Run 'gh auth login' before Cloud Setup.${NC}"
    else
        echo -e "${GREEN}✅ Logged into GitHub${NC}"
    fi
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Local Environment Configured!                        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "   Git:    $(git --version)"
echo "   Docker: $(docker --version)"
echo "   K6:     $(k6 version)"
echo ""
echo -e "${YELLOW}👉 You are now ready for Lab 1 and Lab 2!${NC}"
