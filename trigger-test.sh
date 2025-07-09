#!/bin/bash

# Trigger the workflow manually to test the YAML fix
echo "🔄 Triggering label sync workflow..."
gh workflow run sync-labels.yml --repo ForYouPage-Org/Earth

echo "⏳ Waiting for run to start..."
sleep 5

echo "📊 Checking status..."
gh run list --repo ForYouPage-Org/Earth --limit 1