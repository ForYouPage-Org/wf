#!/bin/bash

# --- Configuration ---
# Set your GitHub organization name here
ORGANIZATION="ForYouPage-Org"

# The full content of the YAML file to be created.
# Using a 'heredoc' like this is great for multi-line strings.
WORKFLOW_FILE_CONTENT=$(cat <<'EOF'
name: Sync Labels from Central Config
on:
  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:
  # Runs on a schedule (daily at 2 AM UTC)
  schedule:
    - cron: '0 2 * * *'
  # Also runs when changes are pushed to the default branch,
  # specifically if the central config file path is mentioned.
  push:
    branches: [ main, master ]

jobs:
  sync-labels:
    runs-on: ubuntu-latest
    steps:
      - name: Sync Labels
        uses: micnncim/action-label-syncer@v1
        env:
          GITHUB_TOKEN:  ${{ secrets.GITHUB_TOKEN }}
          # URL to your centralized labels file in the .github repository
          FILE: https://raw.githubusercontent.com/ForYouPage-Org/.github/main/labels.yml

        with:
          # Deletes labels in this repo that are NOT in the central file.
          # Set to 'false' to prevent deletion and only allow additions/updates.
          prune: true
EOF
)

# --- Script Execution ---
echo "Fetching repositories for organization: $ORGANIZATION..."

# Get a list of all repository names in the organization
# The --jq query filters the JSON output to give us just the names
REPOS=$(gh repo list "$ORGANIZATION" --limit 500 --json name --jq '.[].name')

# Loop through each repository name
for REPO in $REPOS; do
  echo "--------------------------------------------------"
  echo "Processing repository: $ORGANIZATION/$REPO"

  # Skip the central .github repository itself
  if [ "$REPO" == ".github" ]; then
    echo "Skipping the .github repository."
    continue
  fi

  # Create a temporary directory for cloning to avoid name conflicts
  TEMP_DIR="temp_repo_clone"
  rm -rf $TEMP_DIR
  
  echo "Cloning..."
  if ! gh repo clone "$ORGANIZATION/$REPO" $TEMP_DIR; then
    echo "ERROR: Failed to clone $REPO. Skipping."
    continue
  fi

  cd $TEMP_DIR

  # Create the necessary directory structure
  mkdir -p .github/workflows

  # Write the workflow content to the file
  echo "$WORKFLOW_FILE_CONTENT" > .github/workflows/sync-labels.yml
  echo "Workflow file created."

  # Add, commit, and push the new workflow file
  git add .github/workflows/sync-labels.yml
  
  # Check if there are any changes to commit
  if git diff --staged --quiet; then
    echo "Workflow file already exists and is up-to-date. No changes to commit."
  else
    echo "Committing and pushing workflow file..."
    git commit -m "ci: Add workflow to sync labels from central config"
    if ! git push; then
        echo "ERROR: Failed to push to $REPO."
    else
        echo "Successfully pushed workflow to $REPO."
    fi
  fi

  # Clean up by removing the temporary directory
  cd ..
  rm -rf $TEMP_DIR
done

echo "--------------------------------------------------"
echo "Script finished. All repositories have been processed."