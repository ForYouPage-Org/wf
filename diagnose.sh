#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO=${1:-ForYouPage-Org/Earth}

echo -e "${BLUE}🔍 Diagnosing workflow issues for $REPO...${NC}"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    exit 1
fi

# Get the latest failed run
echo -e "${YELLOW}📋 Getting latest workflow run details...${NC}"
LATEST_RUN=$(gh run list --repo $REPO --workflow=sync-labels.yml --limit 1 --json id,status,conclusion,url 2>/dev/null | jq -r '.[0] | "\(.id) \(.status) \(.conclusion) \(.url)"' 2>/dev/null || echo "")

if [ -z "$LATEST_RUN" ]; then
    echo -e "${RED}❌ No workflow runs found${NC}"
    echo "   Try running: gh workflow run sync-labels.yml --repo $REPO"
    exit 1
fi

RUN_ID=$(echo "$LATEST_RUN" | cut -d' ' -f1)
RUN_STATUS=$(echo "$LATEST_RUN" | cut -d' ' -f2)
RUN_CONCLUSION=$(echo "$LATEST_RUN" | cut -d' ' -f3)
RUN_URL=$(echo "$LATEST_RUN" | cut -d' ' -f4)

echo -e "   Run ID: $RUN_ID"
echo -e "   Status: $RUN_STATUS"
echo -e "   Result: $RUN_CONCLUSION"
echo -e "   URL: $RUN_URL"
echo ""

# Get the workflow logs
echo -e "${YELLOW}🔍 Fetching workflow logs...${NC}"
gh run view $RUN_ID --repo $REPO --log 2>/dev/null || {
    echo -e "${RED}❌ Could not fetch logs${NC}"
    echo "   View online: $RUN_URL"
}

echo ""

# Check the workflow file
echo -e "${YELLOW}📄 Checking workflow file...${NC}"
gh api repos/$REPO/contents/.github/workflows/sync-labels.yml --jq '.content' 2>/dev/null | base64 -d | head -20 || {
    echo -e "${RED}❌ Could not read workflow file${NC}"
}

echo ""

# Test downloading labels.yml
echo -e "${YELLOW}🏷️ Testing labels.yml download...${NC}"
if curl -sSL https://raw.githubusercontent.com/ForYouPage-Org/.github/main/labels.yml -o /tmp/test-labels.yml; then
    echo -e "${GREEN}✅ Labels file downloaded successfully${NC}"
    echo "   First few lines:"
    head -5 /tmp/test-labels.yml
    rm -f /tmp/test-labels.yml
else
    echo -e "${RED}❌ Could not download labels.yml${NC}"
    echo "   Check: https://raw.githubusercontent.com/ForYouPage-Org/.github/main/labels.yml"
fi

echo ""

# Check repository permissions
echo -e "${YELLOW}🔐 Checking repository permissions...${NC}"
PERMISSIONS=$(gh api repos/$REPO --jq '.permissions' 2>/dev/null || echo "{}")
echo "   Permissions: $PERMISSIONS"

echo ""
echo -e "${BLUE}💡 Common fixes:${NC}"
echo "   1. Make sure .github repository is public"
echo "   2. Check labels.yml is valid YAML"
echo "   3. Verify workflow has correct permissions"
echo "   4. Re-run workflow: gh workflow run sync-labels.yml --repo $REPO"