#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}     🚀 ForYouPage-Org Workflow Deployer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) is not installed${NC}"
    echo "   Install from: https://cli.github.com/"
    exit 1
fi

# Check auth
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Error: Not logged in to GitHub CLI${NC}"
    echo "   Run: gh auth login"
    exit 1
fi

# Get repository URL
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}📎 Enter the GitHub repository URL:${NC}"
    echo "   Example: https://github.com/ForYouPage-Org/Earth"
    read -p "   URL: " REPO_URL
else
    REPO_URL=$1
fi

# Parse repository from URL
REPO=$(echo "$REPO_URL" | sed -E 's|https://github.com/||; s|\.git$||')
if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo -e "${RED}❌ Invalid repository format${NC}"
    echo "   Expected: owner/repo or https://github.com/owner/repo"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Repository: $REPO${NC}"

# Clone to temp directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo -e "${YELLOW}📥 Cloning repository...${NC}"
if ! gh repo clone "$REPO" "$TEMP_DIR" -- --depth=1 2>/dev/null; then
    echo -e "${RED}❌ Failed to clone repository${NC}"
    echo "   Check that you have access to: $REPO"
    exit 1
fi

cd "$TEMP_DIR"

# Menu
echo ""
echo -e "${BLUE}What would you like to deploy?${NC}"
echo "  1) 🏷️  Label sync only"
echo "  2) 🚦 Label sync + WIP limiter"
echo "  3) 📅 Everything (labels + WIP + calendar sync)"
echo ""
read -p "Select (1-3): " CHOICE

# Determine what to deploy
case $CHOICE in
    1)
        FEATURES=("labels")
        DESCRIPTION="label sync"
        ;;
    2)
        FEATURES=("labels" "wip")
        DESCRIPTION="label sync + WIP limiter"
        ;;
    3)
        FEATURES=("labels" "wip" "calendar")
        DESCRIPTION="complete productivity suite"
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}🔧 Deploying $DESCRIPTION...${NC}"

# Create directories
mkdir -p .github/workflows

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Deploy workflows based on selection
DEPLOYED=()

# Always deploy label sync
echo -e "  📋 Adding label sync workflow..."
cat > .github/workflows/sync-labels.yml << 'EOF'
name: 🏷️ Sync Labels

on:
  workflow_dispatch:
  schedule:
    - cron: '0 2 * * *'
  push:
    branches: [main, master]

jobs:
  sync-labels:
    runs-on: ubuntu-latest
    
    steps:
      - name: 🏷️ Create Labels Config
        run: |
          cat > labels.yml << 'LABELS'
          - name: bug
            description: "Something isn't working"
            color: d73a4a
          
          - name: documentation
            description: "Improvements or additions to documentation"
            color: 0075ca
          
          - name: enhancement
            description: "New feature or request"
            color: a2eeef
          
          - name: "good first issue"
            description: "Good for newcomers"
            color: 7057ff
          
          - name: "help wanted"
            description: "Extra attention is needed"
            color: 008672
          
          - name: invalid
            description: "This doesn't seem right"
            color: e4e669
          
          - name: question
            description: "Further information is requested"
            color: d876e3
          
          - name: wontfix
            description: "This will not be worked on"
            color: ffffff
          
          - name: "sprint-current"
            description: "Active sprint work"
            color: 960167
          
          - name: backlog
            description: "Future work"
            color: 611e65
          
          - name: "ready-to-grab"
            description: "Refined, anyone can take"
            color: adb281
          
          - name: "in-progress"
            description: "Someone's working on it"
            color: 6597a3
          
          - name: done
            description: "Completed, awaiting review"
            color: 379f81
          
          - name: blocked
            description: "Needs help"
            color: 5a8d63
          
          - name: "literature review"
            description: "Requires literature review or research"
            color: 67ff32
          LABELS
          
      - name: 🏷️ Sync Labels
        uses: micnncim/action-label-syncer@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          manifest: labels.yml
          prune: true
          
      - name: 📊 Report Status
        if: always()
        run: |
          if [ "${{ job.status }}" == "success" ]; then
            echo "✅ Labels synced successfully!"
          else
            echo "❌ Label sync failed - check logs"
          fi
EOF
DEPLOYED+=("sync-labels.yml")

# Deploy WIP limiter if selected
if [[ " ${FEATURES[@]} " =~ " wip " ]]; then
    echo -e "  🚦 Adding WIP limiter workflow..."
    cp "$SCRIPT_DIR/workflows/wip-limiter.yml" .github/workflows/
    DEPLOYED+=("wip-limiter.yml")
fi

# Deploy calendar sync if selected
if [[ " ${FEATURES[@]} " =~ " calendar " ]]; then
    echo -e "  📅 Adding calendar sync workflow..."
    cp "$SCRIPT_DIR/workflows/calendar-sync.yml" .github/workflows/
    DEPLOYED+=("calendar-sync.yml")
    CALENDAR_NOTE="true"
fi

# Check for changes
if [ -z "$(git status --porcelain)" ]; then
    echo ""
    echo -e "${YELLOW}ℹ️  Workflows already up to date${NC}"
    NEEDS_PUSH=false
else
    # Commit changes
    echo ""
    echo -e "${YELLOW}💾 Committing changes...${NC}"
    git add .github/workflows/
    git commit -m "🚀 Add ForYouPage-Org productivity workflows

Deployed: ${DEPLOYED[*]}"
    
    # Push changes
    echo -e "${YELLOW}📤 Pushing to GitHub...${NC}"
    if git push; then
        echo -e "${GREEN}✅ Successfully deployed!${NC}"
        NEEDS_PUSH=false
    else
        echo -e "${RED}❌ Failed to push changes${NC}"
        exit 1
    fi
fi

# Run initial sync
echo ""
echo -e "${BLUE}🔄 Running initial label sync...${NC}"
if gh workflow run sync-labels.yml --repo "$REPO" 2>/dev/null; then
    echo -e "${GREEN}✅ Workflow triggered${NC}"
    
    # Wait a moment for the run to start
    sleep 3
    
    # Check status
    echo ""
    echo -e "${BLUE}📊 Checking workflow status...${NC}"
    
    # Get the latest run
    RUN_STATUS=$(gh run list --repo "$REPO" --workflow=sync-labels.yml --limit=1 --json status,conclusion,name -q '.[0] | "\(.name): \(.status) \(.conclusion // "")"' 2>/dev/null || echo "")
    
    if [ -n "$RUN_STATUS" ]; then
        echo -e "   ${GREEN}$RUN_STATUS${NC}"
        echo ""
        echo -e "${YELLOW}💡 View full details:${NC}"
        echo "   gh run list --repo $REPO"
        echo "   gh run view --repo $REPO"
    fi
else
    echo -e "${YELLOW}⚠️  Could not trigger workflow - you may need to enable Actions${NC}"
    echo "   Visit: https://github.com/$REPO/actions"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Deployment Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Deployed Workflows:${NC}"
for workflow in "${DEPLOYED[@]}"; do
    echo "   • $workflow"
done

if [ "${CALENDAR_NOTE:-false}" = "true" ]; then
    echo ""
    echo -e "${YELLOW}📅 Note: Calendar sync requires Google Cloud secrets${NC}"
    echo "   See: https://github.com/ForYouPage-Org/wf#calendar-integration"
fi

echo ""
echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "   1. Check workflow runs: https://github.com/$REPO/actions"
echo "   2. Create an issue to test the labels"
echo "   3. View logs: gh run view --repo $REPO"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"