# 🚀 GitHub Organization Sync Setup

## Required: Personal Access Token (PAT)

The system requires a Personal Access Token with organization-wide permissions to sync labels and manage issues across all repositories.

### Step 1: Create Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token" → "Generate new token (classic)"
3. Set expiration to your preference (recommend 90 days or no expiration for automation)
4. Select the following scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `public_repo` (Access public repositories) 
   - ✅ `admin:repo_hook` (Read and write repository hooks)
   - ✅ `admin:org_hook` (Read and write organization hooks)
   - ✅ `read:org` (Read organization membership and teams)

### Step 2: Add Token as Repository Secret

1. Go to your `wf` repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `ORG_ACCESS_TOKEN`
4. Value: Paste your Personal Access Token
5. Click "Add secret"

### Step 3: Test the Setup

After adding the token, run the workflow manually:

```bash
gh workflow run org-sync.yml --repo ForYouPage-Org/wf
```

Or trigger it from GitHub Actions UI:
1. Go to Actions tab in your `wf` repository
2. Click "🚀 Organization Sync" workflow
3. Click "Run workflow" button
4. Leave all inputs as default and click "Run workflow"

## 🔍 Troubleshooting

### If you see "Resource not accessible by integration" errors:
1. Verify the PAT has the correct scopes (repo access)
2. Check that the PAT hasn't expired
3. Ensure the secret name is exactly `ORG_ACCESS_TOKEN`

### For private repositories:
- The PAT must have `repo` scope (full repository access)
- Organization admin may need to approve PAT usage for private repos

### Alternative: GitHub App (Advanced)
For production use, consider creating a GitHub App instead of using a PAT:
1. Create GitHub App with repository permissions
2. Install app on organization
3. Use app installation token in workflows

## 🎯 What the System Does

Once configured, this system will:

- ✅ **Label Sync**: Apply Mercury-style labels to all organization repositories
- ✅ **Issue Management**: Monitor issue limits and enforce WIP constraints  
- ✅ **Calendar Integration**: Sync issue due dates to Google Calendar (planned)
- ✅ **Template Sync**: Deploy issue templates across repositories (planned)
- ✅ **Automated Workflows**: Run daily or trigger manually/on-demand

## 📊 Current Label Configuration

The system applies these Mercury-style labels:
- `test` - wf beta test
- `sprint-current` - 🎯 Active sprint work  
- `backlog` - 📋 Future work items
- `ready-to-grab` - 🟢 Ready for development
- `in-progress` - 🔄 Currently being worked on
- `done` - ✅ Completed work
- `blocked` - 🚫 Cannot proceed