const { Octokit } = require('@octokit/rest');
const fs = require('fs');

class LabelSyncer {
  constructor(token, org) {
    this.octokit = new Octokit({ auth: token });
    this.org = org;
    this.labels = JSON.parse(fs.readFileSync('./config/labels.json', 'utf8'));
  }

  async syncLabelsToRepo(repo) {
    console.log(`🏷️ Syncing labels to ${this.org}/${repo}...`);
    
    try {
      // Get existing labels
      const { data: existingLabels } = await this.octokit.rest.issues.listLabelsForRepo({
        owner: this.org,
        repo: repo
      });

      // Create a map of existing labels
      const existingLabelMap = new Map(existingLabels.map(l => [l.name, l]));

      // Process each label from our config
      for (const label of this.labels) {
        if (existingLabelMap.has(label.name)) {
          // Update existing label if different
          const existing = existingLabelMap.get(label.name);
          if (existing.color !== label.color || existing.description !== label.description) {
            await this.octokit.rest.issues.updateLabel({
              owner: this.org,
              repo: repo,
              name: label.name,
              color: label.color,
              description: label.description
            });
            console.log(`  ✅ Updated: ${label.name}`);
          }
        } else {
          // Create new label
          await this.octokit.rest.issues.createLabel({
            owner: this.org,
            repo: repo,
            name: label.name,
            color: label.color,
            description: label.description
          });
          console.log(`  ➕ Created: ${label.name}`);
        }
      }

      // Remove labels not in our config (optional - controlled by settings)
      const configLabelNames = new Set(this.labels.map(l => l.name));
      const labelsToDelete = existingLabels.filter(l => 
        !configLabelNames.has(l.name) && 
        !['duplicate', 'invalid', 'wontfix'].includes(l.name) // Keep some default GitHub labels
      );

      for (const label of labelsToDelete) {
        await this.octokit.rest.issues.deleteLabel({
          owner: this.org,
          repo: repo,
          name: label.name
        });
        console.log(`  ❌ Deleted: ${label.name}`);
      }

      return true;
    } catch (error) {
      console.error(`  ❌ Error syncing ${repo}: ${error.message}`);
      return false;
    }
  }

  async syncToAllRepos() {
    console.log(`🚀 Starting organization-wide label sync for ${this.org}...`);
    
    try {
      // Get all repositories
      const { data: repos } = await this.octokit.rest.repos.listForOrg({
        org: this.org,
        type: 'all',
        per_page: 100
      });

      const settings = JSON.parse(fs.readFileSync('./config/settings.json', 'utf8'));
      const excludeRepos = settings.settings.repository_filters.exclude_repos || [];
      
      // Filter repositories
      const targetRepos = repos.filter(repo => {
        if (excludeRepos.includes(repo.name)) return false;
        if (!settings.settings.repository_filters.include_private && repo.private) return false;
        if (!settings.settings.repository_filters.include_public && !repo.private) return false;
        return true;
      });

      console.log(`📋 Found ${targetRepos.length} repositories to sync`);

      let successCount = 0;
      let failCount = 0;

      // Sync labels to each repository
      for (const repo of targetRepos) {
        const success = await this.syncLabelsToRepo(repo.name);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
        
        // Add a small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      console.log(`\n✅ Sync complete: ${successCount} succeeded, ${failCount} failed`);
      return { success: successCount, failed: failCount };

    } catch (error) {
      console.error(`❌ Failed to sync: ${error.message}`);
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

  const syncer = new LabelSyncer(token, org);
  await syncer.syncToAllRepos();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = LabelSyncer;