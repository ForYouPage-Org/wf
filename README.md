# 🚀 ForYouPage-Org Productivity System

> Simple, intuitive GitHub workflow deployment - no configuration required!

## 🎯 What This Does

One command deploys Mercury-style productivity workflows to any repository:
- **🏷️ Smart Labels**: Consistent Mercury-style labels across repos
- **🚦 WIP Limits**: Prevent overload (max 5 in-progress, 10 sprint items)
- **📅 Calendar Sync**: Auto-sync issue due dates to Google Calendar
- **🤖 Zero Setup**: Works immediately with built-in GitHub permissions

## ⚡ Quick Start

### Deploy to One Repository

```bash
# Simple command - works with any GitHub repo
./deploy.sh https://github.com/ForYouPage-Org/Earth

# Or just:
./deploy.sh

# Then enter the repo URL when prompted
```

### Verify It Worked

```bash
# Check everything deployed correctly
./verify.sh ForYouPage-Org/Earth
```

### Important Notes

- **Repository must be public**: The ForYouPage-Org/wf repository must be public for workflows to access labels.yml
- **Actions must be enabled**: Ensure GitHub Actions are enabled in your target repository
- **Check workflow logs**: If you see "startup_failure", check the Actions tab in your repository

That's it! No tokens, no secrets, no configuration files.

## 🎛️ Deployment Options

The deploy script gives you three choices:

1. **🏷️ Label Sync Only** - Mercury-style labels that sync daily
2. **🚦 Labels + WIP Limits** - Adds work-in-progress monitoring  
3. **📅 Everything** - Complete productivity suite with calendar sync

## 📋 Mercury Label System

Your deployed labels will match the Mercury working style:

| Label | Use Case | 
|-------|----------|
| 🎯 sprint-current | Active sprint work |
| 📋 backlog | Future work |
| 🚀 ready-to-grab | Refined, anyone can take |
| ⏳ in-progress | Someone's working on it |
| ✅ done | Completed, awaiting review |
| 🚨 blocked | Needs help |

Plus: bug, enhancement, documentation, good first issue, etc.

## 🛠️ Key Features

### Automatic Label Sync
- Runs daily at 2 AM UTC
- Syncs from this central repository
- Keeps all repos consistent

### WIP Limiting
- Max 5 items "in-progress" 
- Max 10 items "sprint-current"
- Automatic warnings when exceeded

### Calendar Integration
- Detects due dates like `[7/4]` or `[Due: 07/07/2025]`
- Creates Google Calendar events
- Sends 1-day and 2-day reminders

## 🔧 Commands

```bash
# Deploy to any repository
./deploy.sh https://github.com/YourOrg/YourRepo

# Verify deployment worked
./verify.sh YourOrg/YourRepo

# Trigger manual sync
gh workflow run sync-labels.yml --repo YourOrg/YourRepo

# Check workflow status
gh run list --repo YourOrg/YourRepo
```

## 🎉 Zero Configuration Setup

**No PATs or secrets needed!** The system uses:
- GitHub's built-in `GITHUB_TOKEN` for workflows
- Public repository access for label configuration
- Standard GitHub Actions permissions

### Optional: Calendar Integration

For Google Calendar sync, add these repository secrets:
- `GOOGLE_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_SERVICE_ACCOUNT_KEY`  
- `GOOGLE_CALENDAR_ID`

## 🏗️ File Structure

```
.github/
├── deploy.sh           # 🚀 Main deployment script
├── verify.sh           # ✅ Verify deployment
├── labels.yml          # 🏷️ Mercury-style labels
├── workflows/          # 📁 Workflow templates
│   ├── wip-limiter.yml
│   └── calendar-sync.yml
└── README.md           # 📖 This file
```

## 🤝 Contributing

1. Keep it simple and intuitive
2. Follow Mercury working style
3. Test with `./verify.sh` before submitting

## 📚 Resources

- [Mercury Working Style](https://github.com/MARX1108/Mercury/issues/1)
- [GitHub CLI Documentation](https://cli.github.com/)
- [GitHub Actions](https://docs.github.com/actions)

---

*Built for busy executives who need one simple system that just works.*