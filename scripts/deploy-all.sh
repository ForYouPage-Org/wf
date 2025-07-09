#!/bin/bash
set -euo pipefail

# Configuration
ORGANIZATION="ForYouPage-Org"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEMP_DIR=$(mktemp -d -t deploy-workflows-XXXX)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Cleanup on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

echo -e "${GREEN}🚀 ForYouPage-Org Workflow Deployment${NC}"
echo "================================================"

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Get all repositories
echo -e "${YELLOW}📋 Fetching repositories from $ORGANIZATION...${NC}"
REPOS=$(gh repo list "$ORGANIZATION" --limit 100 --json name -q '.[].name' | grep -v "^\.github$" || true)

if [ -z "$REPOS" ]; then
    echo -e "${RED}❌ No repositories found or access denied${NC}"
    exit 1
fi

REPO_COUNT=$(echo "$REPOS" | wc -l | tr -d ' ')
echo -e "${GREEN}✅ Found $REPO_COUNT repositories${NC}"

# Deployment menu
echo ""
echo "What would you like to deploy?"
echo "1) Label sync workflow only"
echo "2) All productivity workflows (labels, WIP limiter, calendar sync)"
echo "3) Complete system setup (workflows + initial configuration)"
echo ""
read -p "Select option (1-3): " DEPLOY_OPTION

case $DEPLOY_OPTION in
    1)
        WORKFLOWS=("sync-labels-workflow.yml:sync-labels.yml")
        COMMIT_MSG="🏷️ Add label sync workflow"
        ;;
    2)
        WORKFLOWS=(
            "sync-labels-workflow.yml:sync-labels.yml"
            "workflows/wip-limiter.yml:wip-limiter.yml"
            "workflows/calendar-sync.yml:calendar-sync.yml"
        )
        COMMIT_MSG="🚀 Add productivity workflows"
        ;;
    3)
        WORKFLOWS=(
            "sync-labels-workflow.yml:sync-labels.yml"
            "workflows/wip-limiter.yml:wip-limiter.yml"
            "workflows/calendar-sync.yml:calendar-sync.yml"
        )
        COMMIT_MSG="🎯 Complete productivity system setup"
        FULL_SETUP=true
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

# Deploy to each repository
SUCCESS_COUNT=0
FAIL_COUNT=0

for REPO in $REPOS; do
    echo ""
    echo -e "${YELLOW}🔄 Processing $REPO...${NC}"
    
    REPO_PATH="$TEMP_DIR/$REPO"
    
    # Clone repository
    if gh repo clone "$ORGANIZATION/$REPO" "$REPO_PATH" -- --quiet --depth 1; then
        cd "$REPO_PATH"
        
        # Create .github/workflows directory
        mkdir -p .github/workflows
        
        # Copy workflow files
        CHANGES_MADE=false
        for WORKFLOW in "${WORKFLOWS[@]}"; do
            SRC="${WORKFLOW%:*}"
            DEST="${WORKFLOW#*:}"
            
            if cp "$REPO_DIR/$SRC" ".github/workflows/$DEST" 2>/dev/null; then
                CHANGES_MADE=true
                echo -e "  ${GREEN}✅ Added $DEST${NC}"
            fi
        done
        
        # Full setup: Create initial issue if requested
        if [ "${FULL_SETUP:-false}" = true ] && [ "$CHANGES_MADE" = true ]; then
            # Check if onboarding issue exists
            if ! gh issue list --label "onboarding" --limit 1 | grep -q .; then
                echo -e "  ${YELLOW}📝 Creating onboarding issue...${NC}"
                gh issue create \
                    --title "🌱 Welcome to Our Productivity System!" \
                    --body "$(cat <<EOF
# 🌱 Welcome to Our Community Garden!

This repository now has the ForYouPage-Org productivity system installed. Here's how to get started:

## 🏷️ Labels
Your repository now syncs with our standard label system:
- **Status labels**: Track work progress (backlog → ready → in-progress → done)
- **Sprint labels**: Organize work into sprints
- **Standard labels**: bug, enhancement, documentation, etc.

## 🚦 WIP Limits
We automatically monitor work-in-progress to prevent overload:
- Maximum 5 items can be "in-progress" at once
- Maximum 10 items in current sprint

## 📅 Calendar Integration (Optional)
Issues with due dates can sync to Google Calendar. To enable:
1. Create a Google Cloud service account
2. Add these secrets to your repository:
   - \`GOOGLE_SERVICE_ACCOUNT_EMAIL\`
   - \`GOOGLE_SERVICE_ACCOUNT_KEY\`
   - \`GOOGLE_CALENDAR_ID\`

## 🚀 Getting Started
1. Review the [Team Working Guide](https://github.com/MARX1108/Mercury/issues/1)
2. Check your labels are synced correctly
3. Create your first issue using our workflow!

## 🎉 No Setup Required!
The workflows are already configured to work with GitHub's built-in permissions.
No PATs or additional secrets needed for label sync!

## ❓ Questions?
- Check our [central .github repository](https://github.com/$ORGANIZATION/.github)
- Ask in your team channel

Happy gardening! 🌻
EOF
                    )" \
                    --label "good first issue,documentation" || echo -e "  ${YELLOW}⚠️  Could not create onboarding issue${NC}"
            fi
        fi
        
        # Commit and push changes
        if [ "$CHANGES_MADE" = true ]; then
            git add .github/workflows/
            
            if git diff --staged --quiet; then
                echo -e "  ${YELLOW}ℹ️  No changes needed${NC}"
            else
                git commit -m "$COMMIT_MSG"
                
                if git push; then
                    echo -e "  ${GREEN}✅ Successfully deployed${NC}"
                    ((SUCCESS_COUNT++))
                else
                    echo -e "  ${RED}❌ Failed to push changes${NC}"
                    ((FAIL_COUNT++))
                fi
            fi
        else
            echo -e "  ${YELLOW}ℹ️  Workflows already up to date${NC}"
        fi
        
        cd - > /dev/null
    else
        echo -e "  ${RED}❌ Failed to clone repository${NC}"
        ((FAIL_COUNT++))
    fi
done

# Summary
echo ""
echo "================================================"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "  Successful: $SUCCESS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo ""

# Next steps
echo "Next steps:"
echo "1. Run 'gh workflow run sync-labels.yml' in any repo to trigger initial sync"
echo "2. Optionally configure Google Calendar secrets for calendar sync"
echo "3. Check workflow runs to ensure everything is working"
echo ""
echo -e "${YELLOW}💡 No additional secrets needed! Workflows use built-in GITHUB_TOKEN${NC}"