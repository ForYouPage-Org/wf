#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ORG="ForYouPage-Org"
CENTRAL_REPO="wf"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}     🚀 ForYouPage-Org Centralized Deployment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "   Install from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
    echo "   Run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Menu
echo -e "${BLUE}What would you like to do?${NC}"
echo "  1) 🌐 Sync all repositories (labels + issue management)"
echo "  2) 🏷️ Sync labels only"
echo "  3) 📋 Manage issues only"
echo "  4) 🚀 Deploy to specific repository"
echo "  5) 📊 View organization status"
echo ""
read -p "Select (1-5): " CHOICE

case $CHOICE in
    1)
        echo -e "${YELLOW}🌐 Starting full organization sync...${NC}"
        gh workflow run org-sync.yml --repo $ORG/$CENTRAL_REPO \
          --field sync_labels=true \
          --field manage_issues=true
        echo -e "${GREEN}✅ Full sync triggered${NC}"
        ;;
    2)
        echo -e "${YELLOW}🏷️ Starting label sync...${NC}"
        gh workflow run org-sync.yml --repo $ORG/$CENTRAL_REPO \
          --field sync_labels=true \
          --field manage_issues=false
        echo -e "${GREEN}✅ Label sync triggered${NC}"
        ;;
    3)
        echo -e "${YELLOW}📋 Starting issue management...${NC}"
        gh workflow run org-sync.yml --repo $ORG/$CENTRAL_REPO \
          --field sync_labels=false \
          --field manage_issues=true
        echo -e "${GREEN}✅ Issue management triggered${NC}"
        ;;
    4)
        echo -e "${YELLOW}📎 Enter target repository name:${NC}"
        read -p "   Repository: " TARGET_REPO
        echo -e "${YELLOW}🚀 Deploying to $TARGET_REPO...${NC}"
        gh workflow run org-sync.yml --repo $ORG/$CENTRAL_REPO \
          --field sync_labels=true \
          --field manage_issues=true \
          --field target_repo="$ORG/$TARGET_REPO"
        echo -e "${GREEN}✅ Deployment to $TARGET_REPO triggered${NC}"
        ;;
    5)
        echo -e "${YELLOW}📊 Fetching organization status...${NC}"
        gh repo list $ORG --limit 100 --json name,isPrivate,pushedAt | \
          jq -r '.[] | "\(.name) (Private: \(.isPrivate)) - Last push: \(.pushedAt)"'
        echo ""
        echo -e "${BLUE}Recent workflow runs:${NC}"
        gh run list --repo $ORG/$CENTRAL_REPO --limit 5
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "   1. Monitor workflow: gh run list --repo $ORG/$CENTRAL_REPO"
echo "   2. View logs: gh run view --repo $ORG/$CENTRAL_REPO"
echo "   3. Check results in individual repositories"
echo ""
echo -e "${GREEN}🎉 Organization management complete!${NC}"