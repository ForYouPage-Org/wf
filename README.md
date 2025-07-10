# 🚀 ForYouPage-Org Centralized Management System

> **New Design**: Organization-first approach with centralized control

## 🎯 What This System Does

This repository serves as the **central control hub** for your entire GitHub organization:

- **🏷️ Automatic Label Sync**: Sync labels across all repositories from one place
- **📋 Issue Management**: Monitor and enforce issue limits organization-wide  
- **📅 Calendar Integration**: Sync issue due dates to Google Calendar
- **📝 Template Sync**: Deploy consistent issue templates everywhere
- **🔧 Zero Maintenance**: Set once, runs automatically

## ⚡ Quick Start

### 1. One-Command Deployment

```bash
# Deploy the entire system
./deploy-org.sh
```

### 2. Choose Your Action

- **Full Sync**: Labels + Issue Management + Templates
- **Labels Only**: Just sync labels across all repos
- **Issues Only**: Check limits and manage issues
- **Specific Repo**: Target one repository
- **Status Check**: View organization overview

## 🏗️ Architecture

```
ForYouPage-Org/wf (This Repository)
├── config/
│   ├── labels.json        # Master label configuration
│   └── settings.json      # Organization settings & limits
├── scripts/
│   ├── sync-labels.js     # Custom label sync (reliable)
│   └── issue-manager.js   # Issue limits & calendar sync
├── templates/
│   ├── bug_report.yml     # Bug report template
│   └── feature_request.yml # Feature request template
├── .github/workflows/
│   └── org-sync.yml       # Master workflow (runs here)
└── deploy-org.sh          # One-command deployment
```

## 🔧 Key Features

### 🎯 Centralized Control
- **Single Source**: All configuration in this repository
- **Batch Operations**: Process all repositories at once
- **Admin Control**: Organization admins control everything

### 🏷️ Smart Label Sync
- **Custom Script**: No dependency on broken third-party actions
- **Mercury Labels**: Full support for emoji labels and descriptions
- **Safe Updates**: Creates, updates, and optionally removes labels

### 📋 Intelligent Issue Management
- **WIP Limits**: Automatic enforcement of work-in-progress limits
- **Issue Limits**: Prevent repository overload
- **Warning System**: Automatic issues when limits exceeded
- **Calendar Sync**: Due date integration with Google Calendar

### 🚀 Automated Deployment
- **Daily Sync**: Runs automatically at 2 AM UTC
- **Manual Trigger**: Run anytime with workflow dispatch
- **Selective Sync**: Choose what to sync (labels, issues, etc.)
- **Repository Filtering**: Include/exclude private/public repos

## ⚙️ Configuration

### Labels (`config/labels.json`)
```json
[
  {
    "name": "sprint-current",
    "description": "🎯 Active sprint work", 
    "color": "960167"
  }
]
```

### Settings (`config/settings.json`)
```json
{
  "issue_limits": {
    "max_open_issues_per_repo": 50,
    "max_sprint_current": 10,
    "max_in_progress": 5
  },
  "repository_filters": {
    "exclude_repos": [".github", "wf"],
    "include_private": true,
    "include_public": true
  }
}
```

## 📋 Usage Examples

### Sync Everything
```bash
./deploy-org.sh
# Select option 1: Full organization sync
```

### Deploy to Specific Repository
```bash
./deploy-org.sh  
# Select option 4: Deploy to specific repository
# Enter: Earth
```

### Check Organization Status
```bash
./deploy-org.sh
# Select option 5: View organization status
```

### Manual Workflow Trigger
```bash
# Trigger from any repository
gh workflow run org-sync.yml --repo ForYouPage-Org/wf
```

## 🔐 Permissions Required

- **Organization Admin**: To access all repositories
- **Workflow Permissions**: `contents: read`, `issues: write`, `repository-projects: write`
- **GitHub Token**: Automatic `GITHUB_TOKEN` works for same-org access

## 🎯 Benefits of New Design

### ✅ What's Fixed
1. **No Third-Party Dependencies**: Custom scripts that actually work
2. **Organization-Level Control**: Manage everything from one place
3. **Reliable Label Sync**: Handles emojis and complex configurations
4. **Smart Issue Management**: Automatic limits and warnings
5. **Zero Repository Setup**: No workflow deployment needed per repo

### 🆚 vs. Old Approach
| Old | New |
|-----|-----|
| Deploy to each repo individually | Deploy once, manage everything |
| Unreliable third-party actions | Custom Node.js scripts |
| No centralized control | Full organization oversight |
| Manual issue management | Automated limits and warnings |
| Complex setup process | One-command deployment |

## 🔄 How It Works

1. **Configuration**: Edit `config/` files in this repository
2. **Trigger**: Run `./deploy-org.sh` or trigger workflows
3. **Processing**: Scripts process all repositories in parallel
4. **Results**: Labels synced, limits enforced, issues managed
5. **Monitoring**: Automatic warnings and status reports

## 🎉 Ready to Use

The system is **production-ready** and designed for:
- Busy executives managing multiple projects
- Organizations with many repositories
- Teams that need consistent workflows
- Automatic enforcement of productivity limits

**No external dependencies. No complex setup. Just works.** 🚀