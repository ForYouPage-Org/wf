#!/bin/bash
set -euo pipefail

# Quick fix for Earth repository workflow
REPO="ForYouPage-Org/Earth"

echo "🔧 Fixing workflow in $REPO..."

# Clone the repository
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

gh repo clone "$REPO" "$TEMP_DIR" -- --depth=1
cd "$TEMP_DIR"

# Create the fixed workflow
mkdir -p .github/workflows
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
    permissions:
      contents: read
      issues: write
      
    steps:
      - name: 🔍 Get Labels Config
        run: |
          # Download labels.yml from the wf repository
          curl -sSL https://raw.githubusercontent.com/ForYouPage-Org/wf/main/labels.yml -o labels.yml
          
      - name: 🏷️ Sync Labels
        uses: micnncim/action-label-syncer@v1
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

# Also create a backup version that embeds labels directly
cat > .github/workflows/sync-labels-embedded.yml << 'EOF'
name: 🏷️ Sync Labels (Embedded)

on:
  workflow_dispatch:
  schedule:
    - cron: '0 2 * * *'
  push:
    branches: [main, master]

jobs:
  sync-labels:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
      
    steps:
      - name: 🏷️ Create Labels Config
        run: |
          # Create labels.yml with Mercury-style labels
          cat > labels.yml << 'LABELS_EOF'
          - name: "bug"
            description: "Something isn't working"
            color: "d73a4a"
          
          - name: "documentation"
            description: "Improvements or additions to documentation"
            color: "0075ca"
          
          - name: "enhancement"
            description: "New feature or request"
            color: "a2eeef"
          
          - name: "good first issue"
            description: "Good for newcomers"
            color: "7057ff"
          
          - name: "help wanted"
            description: "Extra attention is needed"
            color: "008672"
          
          - name: "invalid"
            description: "This doesn't seem right"
            color: "e4e669"
          
          - name: "question"
            description: "Further information is requested"
            color: "d876e3"
          
          - name: "wontfix"
            description: "This will not be worked on"
            color: "ffffff"
          
          - name: "🎯 sprint-current"
            description: "Active sprint work"
            color: "960167"
          
          - name: "📋 backlog"
            description: "Future work"
            color: "611e65"
          
          - name: "🚀 ready-to-grab"
            description: "Refined, anyone can take"
            color: "adb281"
          
          - name: "⏳ in-progress"
            description: "Someone's working on it"
            color: "6597a3"
          
          - name: "✅ done"
            description: "Completed, awaiting review"
            color: "379f81"
          
          - name: "🚨 blocked"
            description: "Needs help"
            color: "5a8d63"
          
          - name: "literature review"
            description: "Requires literature review or research"
            color: "67ff32"
          LABELS_EOF
          
      - name: 🏷️ Sync Labels
        uses: micnncim/action-label-syncer@v1
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

# Commit and push
git add .github/workflows/sync-labels.yml
git commit -m "🔧 Fix label sync workflow - embed labels directly"
git push

echo "✅ Fixed workflow in $REPO"
echo "🔄 Triggering workflow..."
gh workflow run sync-labels.yml --repo "$REPO"

echo "✅ Done! Check status with:"
echo "   ./verify.sh $REPO"