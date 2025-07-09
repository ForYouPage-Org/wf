# 🎉 Frictionless Setup Guide

## Zero Configuration Required!

This productivity system requires **NO Personal Access Tokens (PATs)** or special configuration. It works out of the box using GitHub's built-in permissions.

## How It Works

1. **Automatic Authentication**: All workflows use the built-in `GITHUB_TOKEN` that GitHub provides to every workflow run
2. **Public Repository Access**: The central `.github` repository is public, allowing all organization repositories to read from it
3. **Organization Admin Powers**: As an org admin, you already have all the permissions needed to deploy

## Quick Deploy (< 2 minutes)

```bash
# Clone this repo
git clone https://github.com/ForYouPage-Org/.github.git
cd .github

# Run deployment (as org admin)
./scripts/deploy-all.sh

# Select option 3 for complete setup
```

That's it! No tokens, no secrets, no configuration files.

## What Gets Deployed

### Without Any Configuration
✅ Label synchronization (daily)
✅ WIP limiting (automatic)
✅ Issue templates
✅ Workflow automation

### With Optional Configuration
📅 Google Calendar sync (requires Google Cloud secrets)

## Security Model

- **Read Access**: Any repository can read from the public `.github` repo
- **Write Access**: Only workflows with `issues: write` permission can modify labels
- **No Cross-Repo Access**: Each repo only modifies its own issues/labels
- **No Elevated Permissions**: Uses standard GitHub Actions permissions

## Troubleshooting

### "Permission denied" during deployment
- Ensure you're authenticated: `gh auth status`
- Verify you're an org admin: `gh api orgs/ForYouPage-Org/memberships/$(gh api user -q .login)`

### Workflows not running
- Check Actions are enabled in the repository
- Verify the `.github` repository is public
- Check workflow logs for specific errors

## The Magic Behind It

```yaml
# No PAT needed! Just this:
- uses: actions/checkout@v4
  with:
    repository: ForYouPage-Org/.github  # Public repo = no auth needed
    
# And this built-in token:
- uses: micnncim/action-label-syncer@v1
  with:
    manifest: labels.yml
    # Uses automatic GITHUB_TOKEN
```

## Why This Works

1. **Public Repository Strategy**: Making the central config public eliminates authentication complexity
2. **Built-in Tokens**: GitHub's automatic token has enough permissions for same-repo operations
3. **Smart Defaults**: Workflows are designed to work with minimal permissions

Enjoy your frictionless productivity system! 🚀