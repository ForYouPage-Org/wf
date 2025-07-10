const { Octokit } = require('@octokit/rest');
const fs = require('fs');

class IssueManager {
  constructor(token, org) {
    this.octokit = new Octokit({ auth: token });
    this.org = org;
    this.settings = JSON.parse(fs.readFileSync('./config/settings.json', 'utf8')).settings;
  }

  async checkIssueLimits(repo) {
    console.log(`🔍 Checking issue limits for ${this.org}/${repo}...`);
    
    try {
      // Get open issues
      const { data: issues } = await this.octokit.rest.issues.listForRepo({
        owner: this.org,
        repo: repo,
        state: 'open',
        per_page: 100
      });

      const limits = this.settings.issue_limits;
      const warnings = [];

      // Check total open issues
      if (issues.length > limits.max_open_issues_per_repo) {
        warnings.push(`⚠️ Too many open issues: ${issues.length}/${limits.max_open_issues_per_repo}`);
      }

      // Check sprint-current issues
      const sprintIssues = issues.filter(issue => 
        issue.labels.some(label => label.name === 'sprint-current')
      );
      if (sprintIssues.length > limits.max_sprint_current) {
        warnings.push(`⚠️ Too many sprint issues: ${sprintIssues.length}/${limits.max_sprint_current}`);
      }

      // Check in-progress issues
      const inProgressIssues = issues.filter(issue => 
        issue.labels.some(label => label.name === 'in-progress')
      );
      if (inProgressIssues.length > limits.max_in_progress) {
        warnings.push(`⚠️ Too many in-progress issues: ${inProgressIssues.length}/${limits.max_in_progress}`);
      }

      if (warnings.length > 0) {
        console.log(`  ${warnings.join('\n  ')}`);
        
        // Create a warning issue if limits are exceeded
        await this.createLimitWarningIssue(repo, warnings);
      } else {
        console.log(`  ✅ All limits within bounds`);
      }

      return { repo, warnings, counts: {
        total: issues.length,
        sprint: sprintIssues.length,
        inProgress: inProgressIssues.length
      }};

    } catch (error) {
      console.error(`  ❌ Error checking ${repo}: ${error.message}`);
      return { repo, error: error.message };
    }
  }

  async createLimitWarningIssue(repo, warnings) {
    const title = '⚠️ Issue Limits Exceeded - Action Required';
    const body = `
# Issue Limits Exceeded

This repository has exceeded the organization's issue limits:

${warnings.map(w => `- ${w}`).join('\n')}

## Recommended Actions:

1. **Review Open Issues**: Close completed or outdated issues
2. **Prioritize Work**: Move low-priority items to backlog  
3. **Focus Sprint**: Limit active sprint work to maintain velocity
4. **Complete In-Progress**: Finish work before starting new items

## Current Limits:
- Maximum open issues: ${this.settings.issue_limits.max_open_issues_per_repo}
- Maximum sprint-current: ${this.settings.issue_limits.max_sprint_current}  
- Maximum in-progress: ${this.settings.issue_limits.max_in_progress}

This issue will be automatically closed when limits are back within bounds.

*Automated by ForYouPage-Org productivity system*
`;

    try {
      // Check if warning issue already exists
      const { data: existingIssues } = await this.octokit.rest.issues.listForRepo({
        owner: this.org,
        repo: repo,
        state: 'open',
        creator: 'app/github-actions[bot]',
        labels: 'automated-warning'
      });

      if (existingIssues.length === 0) {
        await this.octokit.rest.issues.create({
          owner: this.org,
          repo: repo,
          title: title,
          body: body,
          labels: ['automated-warning', 'blocked']
        });
        console.log(`  📝 Created warning issue`);
      }
    } catch (error) {
      console.error(`  ❌ Failed to create warning issue: ${error.message}`);
    }
  }

  async syncCalendarEvents(repo) {
    if (!this.settings.calendar_sync.enabled) {
      return;
    }

    console.log(`📅 Syncing calendar events for ${this.org}/${repo}...`);
    
    try {
      // Get issues with due dates
      const { data: issues } = await this.octokit.rest.issues.listForRepo({
        owner: this.org,
        repo: repo,
        state: 'open',
        per_page: 100
      });

      const issuesWithDueDates = issues.filter(issue => {
        const body = issue.body || '';
        const title = issue.title || '';
        return /due:\s*\d{1,2}\/\d{1,2}\/\d{2,4}/i.test(body) || 
               /\[\d{1,2}\/\d{1,2}(?:\/\d{2,4})?\]/.test(title);
      });

      console.log(`  📋 Found ${issuesWithDueDates.length} issues with due dates`);

      // Note: Actual calendar integration would require Google Calendar API setup
      // This is a placeholder for the calendar sync logic
      for (const issue of issuesWithDueDates) {
        console.log(`  📅 Would sync: ${issue.title}`);
      }

    } catch (error) {
      console.error(`  ❌ Error syncing calendar for ${repo}: ${error.message}`);
    }
  }

  async manageAllRepos() {
    console.log(`🚀 Starting organization-wide issue management for ${this.org}...`);
    
    try {
      // Get all repositories
      const { data: repos } = await this.octokit.rest.repos.listForOrg({
        org: this.org,
        type: 'all',
        per_page: 100
      });

      const excludeRepos = this.settings.repository_filters.exclude_repos || [];
      
      // Filter repositories
      const targetRepos = repos.filter(repo => {
        if (excludeRepos.includes(repo.name)) return false;
        if (!this.settings.repository_filters.include_private && repo.private) return false;
        if (!this.settings.repository_filters.include_public && !repo.private) return false;
        return true;
      });

      console.log(`📋 Managing ${targetRepos.length} repositories`);

      const results = [];

      // Process each repository
      for (const repo of targetRepos) {
        const result = await this.checkIssueLimits(repo.name);
        results.push(result);
        
        // Sync calendar events
        await this.syncCalendarEvents(repo.name);
        
        // Add delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 200));
      }

      // Summary
      const reposWithWarnings = results.filter(r => r.warnings && r.warnings.length > 0);
      console.log(`\n📊 Summary: ${reposWithWarnings.length} repositories have warnings`);
      
      return results;

    } catch (error) {
      console.error(`❌ Failed to manage repositories: ${error.message}`);
      throw error;
    }
  }
}

// Main execution
async function main() {
  const token = process.env.GITHUB_TOKEN;
  const org = process.env.GITHUB_ORGANIZATION || 'ForYouPage-Org';

  if (!token) {
    console.error('❌ GITHUB_TOKEN environment variable is required');
    process.exit(1);
  }

  const manager = new IssueManager(token, org);
  await manager.manageAllRepos();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = IssueManager;