#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# --- Configuration ---
ORGANIZATION="ForYouPage-Org"
COMMIT_MESSAGE="ci: Update and standardize label sync workflow"

# --- Corrected Path Handling (THE FIX) ---
# Get the absolute path to the directory where this script is located.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Define the absolute path to the master workflow file.
WORKFLOW_SOURCE_FILE="$SCRIPT_DIR/sync-labels-workflow.yml"
# Destination path within each repository.
WORKFLOW_DEST_PATH=".github/workflows/sync-labels.yml"


# --- Pre-run Checks ---
if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI ('gh') not found. Please install it."
    exit 1
fi

if [ ! -f "$WORKFLOW_SOURCE_FILE" ]; then
    echo "ERROR: Master workflow file not found at '$WORKFLOW_SOURCE_FILE'"
    echo "Please ensure 'sync-labels-workflow.yml' is in the same directory as this script."
    exit 1
fi

# --- Main Execution ---
echo "Fetching repositories for organization: $ORGANIZATION..."
REPOS=$(gh repo list "$ORGANIZATION" --limit 500 --json name --jq '.[] | select(.name != ".github") | .name')

for REPO in $REPOS; do
  echo "--------------------------------------------------"
  echo "Processing: $ORGANIZATION/$REPO"

  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT

  echo "Cloning into temporary directory..."
  gh repo clone "$ORGANIZATION/$REPO" "$TEMP_DIR" -- --depth=1
  cd "$TEMP_DIR"

  mkdir -p "$(dirname "$WORKFLOW_DEST_PATH")"
  
  # Use the absolute path to copy the file.
  cp "$WORKFLOW_SOURCE_FILE" "$WORKFLOW_DEST_PATH"
  echo "Workflow file placed at '$WORKFLOW_DEST_PATH'."

  if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to workflow file. Repository is up-to-date."
  else
    echo "Changes detected. Committing and pushing..."
    git add "$WORKFLOW_DEST_PATH"
    git commit -m "$COMMIT_MESSAGE"
    git push

    if [ $? -eq 0 ]; then
        echo "Successfully pushed changes to $REPO."
    else
        echo "ERROR: Failed to push changes to $REPO."
    fi
  fi
  cd ..
done

echo "--------------------------------------------------"
echo "✅ Deployment script finished."