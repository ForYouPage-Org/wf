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
echo -e "${BLUE}🔍 Verifying ForYouPage-Org workflows in $REPO...${NC}"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    exit 1
fi

# Check workflow files
echo -e "${YELLOW}📋 Checking workflow files...${NC}"
WORKFLOWS=$(gh api repos/$REPO/contents/.github/workflows --jq '.[].name' 2>/dev/null | grep -E '(sync-labels|wip-limiter|calendar-sync)' | wc -l)

if [ "$WORKFLOWS" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $WORKFLOWS workflow file(s)${NC}"
    gh api repos/$REPO/contents/.github/workflows --jq '.[] | select(.name | test("sync-labels|wip-limiter|calendar-sync")) | "   • " + .name' 2>/dev/null
else
    echo -e "${RED}❌ No ForYouPage-Org workflows found${NC}"
    echo "   Run: ./deploy.sh $REPO"
    exit 1
fi

echo ""

# Check recent workflow runs
echo -e "${YELLOW}🔄 Checking recent workflow runs...${NC}"
RUNS=$(gh run list --repo $REPO --limit 5 --json status,conclusion,name,createdAt 2>/dev/null | jq -r '.[] | "   • \(.name): \(.status) \(.conclusion // "") (\(.createdAt | split("T")[0]))"' 2>/dev/null || echo "")

if [ -n "$RUNS" ]; then
    echo "$RUNS"
else
    echo -e "${YELLOW}⚠️  No recent workflow runs found${NC}"
    echo "   Trigger manually: gh workflow run sync-labels.yml --repo $REPO"
fi

echo ""

# Check labels
echo -e "${YELLOW}🏷️ Checking Mercury-style labels...${NC}"
MERCURY_LABELS=$(gh api repos/$REPO/labels --jq '.[] | select(.name | test("sprint-current|backlog|ready-to-grab|in-progress|done|blocked")) | .name' 2>/dev/null | wc -l)

if [ "$MERCURY_LABELS" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $MERCURY_LABELS Mercury-style labels${NC}"
    gh api repos/$REPO/labels --jq '.[] | select(.name | test("sprint-current|backlog|ready-to-grab|in-progress|done|blocked")) | "   • " + .name' 2>/dev/null
else
    echo -e "${YELLOW}⚠️  Mercury-style labels not found${NC}"
    echo "   Run workflow: gh workflow run sync-labels.yml --repo $REPO"
fi

echo ""

# Check if Actions are enabled
echo -e "${YELLOW}⚙️ Checking Actions status...${NC}"
ACTIONS_ENABLED=$(gh api repos/$REPO --jq '.has_actions' 2>/dev/null)

if [ "$ACTIONS_ENABLED" = "true" ]; then
    echo -e "${GREEN}✅ GitHub Actions are enabled${NC}"
else
    echo -e "${RED}❌ GitHub Actions are disabled${NC}"
    echo "   Enable at: https://github.com/$REPO/settings/actions"
fi

echo ""

# Overall status
if [ "$WORKFLOWS" -gt 0 ] && [ "$ACTIONS_ENABLED" = "true" ]; then
    echo -e "${GREEN}🎉 Repository is ready for ForYouPage-Org productivity workflows!${NC}"
    
    echo ""
    echo -e "${BLUE}🎯 Quick Actions:${NC}"
    echo "   • View runs:        gh run list --repo $REPO"
    echo "   • Trigger sync:     gh workflow run sync-labels.yml --repo $REPO"
    echo "   • View logs:        gh run view --repo $REPO"
    echo "   • Open Actions:     https://github.com/$REPO/actions"
else
    echo -e "${YELLOW}⚠️  Setup incomplete - see suggestions above${NC}"
fi

echo ""