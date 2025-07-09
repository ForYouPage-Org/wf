# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive GitHub organization productivity system for ForYouPage-Org that provides:
- Automated label synchronization across all repositories
- Work-in-progress (WIP) limiting to prevent overload
- Calendar integration for deadline management
- ADHD-friendly workflow automation

The system follows the Mercury working style with visual hierarchy and clear status tracking.

## Key Components

1. **scripts/deploy-all.sh** - Main deployment script with menu-driven options for deploying workflows
2. **sync.sh** - Legacy script for label-only synchronization
3. **sync-labels-workflow.yml** - GitHub Actions workflow for label synchronization
4. **workflows/wip-limiter.yml** - Enforces WIP limits on in-progress and sprint items
5. **workflows/calendar-sync.yml** - Syncs issue due dates to Google Calendar
6. **labels.yml** - Central label configuration in YAML format using Mercury-style labels with emojis

## Common Commands

### Deploy Complete Productivity System
```bash
./scripts/deploy-all.sh
# Then select option 3 for complete setup
```

### Deploy Only Label Sync
```bash
./sync.sh
# OR
./scripts/deploy-all.sh
# Then select option 1
```

### Verify Deployment
```bash
# Check workflow runs
gh run list --repo ForYouPage-Org/[REPO_NAME]

# Trigger manual sync
gh workflow run sync-labels.yml --repo ForYouPage-Org/[REPO_NAME]
```

### Prerequisites Check
```bash
# Verify GitHub CLI is installed
gh --version

# Check authentication status
gh auth status

# List organization repositories (to verify access)
gh repo list ForYouPage-Org --limit 100
```

## Architecture & Workflow

### Deployment System
1. **deploy-all.sh** provides three deployment options:
   - Label sync only
   - All productivity workflows
   - Complete system with initial setup
2. Scripts handle:
   - Repository cloning and modification
   - Workflow file deployment
   - Automatic commit and push
   - Optional onboarding issue creation

### Workflow Operations
1. **Label Sync**: Daily sync from central configuration
2. **WIP Limiter**: Monitors label additions and enforces limits (5 in-progress, 10 sprint-current)
3. **Calendar Sync**: Detects due dates in formats like [7/4] or [Due: 07/07/2025]

## Configuration Requirements

### Zero Configuration for Basic Setup
No secrets or PATs needed! The system uses GitHub's built-in permissions:
- Workflows use the automatic `GITHUB_TOKEN`
- Organization admins can deploy to all repositories
- Public central repository allows frictionless access

### Optional Calendar Integration
For Google Calendar sync, add these secrets:
- `GOOGLE_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_SERVICE_ACCOUNT_KEY`
- `GOOGLE_CALENDAR_ID`

## Label System

Mercury-style labels with visual hierarchy:
- **Status**: 📋 backlog, 🚀 ready-to-grab, ⏳ in-progress, ✅ done, 🚨 blocked
- **Sprint**: 🎯 sprint-current
- **Standard**: bug, enhancement, documentation, good first issue, etc.

## Key Technical Details

- All scripts use absolute path handling for reliability
- Temporary directories in `/tmp/` with automatic cleanup
- Error handling with proper exit codes and colored output
- Repository exclusion pattern prevents .github repo recursion
- Workflows use GitHub Actions v4 and latest action versions
- No PAT required - uses built-in GITHUB_TOKEN for all operations
- Frictionless setup for organization administrators