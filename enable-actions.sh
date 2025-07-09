#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if repo provided
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}📎 Enter the GitHub repository:${NC}"
    echo "   Example: ForYouPage-Org/Earth"
    read -p "   Repository: " REPO
else
    REPO=$1
fi

echo ""
echo -e "${BLUE}⚙️ Enabling GitHub Actions for $REPO...${NC}"

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    exit 1
fi

# Check auth
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not logged in to GitHub CLI${NC}"
    echo "   Run: gh auth login"
    exit 1
fi

# Check current Actions status
echo -e "${YELLOW}🔍 Checking current Actions status...${NC}"
ACTIONS_STATUS=$(gh api repos/$REPO --jq '.has_actions' 2>/dev/null || echo "error")

if [ "$ACTIONS_STATUS" = "error" ]; then
    echo -e "${RED}❌ Could not access repository${NC}"
    echo "   Check that you have access to: $REPO"
    exit 1
fi

if [ "$ACTIONS_STATUS" = "true" ]; then
    echo -e "${GREEN}✅ GitHub Actions are already enabled${NC}"
    exit 0
fi

# Enable Actions
echo -e "${YELLOW}🔧 Enabling GitHub Actions...${NC}"

# Method 1: Try to enable via API
if gh api --method PUT repos/$REPO/actions/permissions --field enabled=true --field allowed_actions=all 2>/dev/null; then
    echo -e "${GREEN}✅ GitHub Actions enabled successfully${NC}"
    
    # Wait a moment for the change to take effect
    sleep 2
    
    # Verify it worked
    NEW_STATUS=$(gh api repos/$REPO --jq '.has_actions' 2>/dev/null || echo "false")
    if [ "$NEW_STATUS" = "true" ]; then
        echo -e "${GREEN}✅ Verification: Actions are now enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Actions may need a moment to activate${NC}"
    fi
    
else
    echo -e "${YELLOW}⚠️  Could not enable Actions via API${NC}"
    echo -e "${BLUE}📋 Manual steps needed:${NC}"
    echo "   1. Go to: https://github.com/$REPO/settings/actions"
    echo "   2. Click 'Enable Actions'"
    echo "   3. Select 'Allow all actions and reusable workflows'"
    echo "   4. Click 'Save'"
    echo ""
    echo -e "${YELLOW}💡 This usually happens when Actions are disabled at the organization level${NC}"
fi

echo ""
echo -e "${BLUE}🎯 Next steps:${NC}"
echo "   1. Run workflow: gh workflow run sync-labels.yml --repo $REPO"
echo "   2. Check status: gh run list --repo $REPO"
echo "   3. Verify labels: ./verify.sh $REPO"
echo ""