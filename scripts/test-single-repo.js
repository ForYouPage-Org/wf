const { Octokit } = require('@octokit/rest');
const fs = require('fs');

async function testLabelSync() {
  const token = process.env.GITHUB_TOKEN;
  const org = 'ForYouPage-Org';
  const testRepo = 'Earth'; // Test on Earth repository
  
  if (!token) {
    console.error('❌ GITHUB_TOKEN environment variable is required');
    process.exit(1);
  }

  console.log('🧪 Testing label sync on single repository...');
  console.log(`Organization: ${org}`);
  console.log(`Repository: ${testRepo}`);
  console.log('');

  const octokit = new Octokit({ auth: token });
  const labels = JSON.parse(fs.readFileSync('./config/labels.json', 'utf8'));

  try {
    // Step 1: Get current labels
    console.log('📋 Current labels in repository:');
    const { data: currentLabels } = await octokit.rest.issues.listLabelsForRepo({
      owner: org,
      repo: testRepo,
      per_page: 100
    });
    
    console.log(`Found ${currentLabels.length} existing labels:`);
    currentLabels.forEach(label => {
      console.log(`  - ${label.name} (${label.color})`);
    });
    console.log('');

    // Step 2: Show labels to be synced
    console.log('🏷️ Labels from config to sync:');
    labels.forEach(label => {
      console.log(`  - ${label.name}: "${label.description}" (${label.color})`);
    });
    console.log('');

    // Step 3: Perform sync
    console.log('🚀 Starting sync...');
    const LabelSyncer = require('./sync-labels.js');
    const syncer = new LabelSyncer(token, org);
    const result = await syncer.syncLabelsToRepo(testRepo);

    // Step 4: Verify results
    console.log('');
    console.log('✅ Sync completed!');
    console.log('');
    
    console.log('📋 Final labels in repository:');
    const { data: finalLabels } = await octokit.rest.issues.listLabelsForRepo({
      owner: org,
      repo: testRepo,
      per_page: 100
    });
    
    console.log(`Total labels: ${finalLabels.length}`);
    finalLabels.forEach(label => {
      console.log(`  - ${label.name}: "${label.description}" (${label.color})`);
    });

    // Step 5: Validation
    console.log('');
    console.log('🔍 Validation Results:');
    
    const configLabelNames = new Set(labels.map(l => l.name));
    const finalLabelNames = new Set(finalLabels.map(l => l.name));
    
    // Check if all config labels exist
    let allConfigLabelsExist = true;
    labels.forEach(label => {
      if (!finalLabelNames.has(label.name)) {
        console.log(`  ❌ Missing: ${label.name}`);
        allConfigLabelsExist = false;
      }
    });
    
    if (allConfigLabelsExist) {
      console.log('  ✅ All configured labels exist in repository');
    }
    
    // Check for extra labels
    const extraLabels = finalLabels.filter(l => !configLabelNames.has(l.name));
    if (extraLabels.length > 0) {
      console.log(`  ℹ️ Extra labels not in config: ${extraLabels.map(l => l.name).join(', ')}`);
    }

    console.log('');
    console.log('🎉 Test completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run the test
testLabelSync().catch(console.error);