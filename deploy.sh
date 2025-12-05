#!/bin/bash

# Auto-Deploy Script for Kali Using Windows SSH Agent
# Author: jcla101

echo "🚀 Starting Auto-Deploy..."

# 1. Add all changes
git add -A

# 2. Commit with an auto-generated message (or custom if passed)
if [ -z "$1" ]
then
  git commit -m "Auto-deploy: $(date '+%Y-%m-%d %H:%M:%S')"
else
  git commit -m "$1"
fi

# 3. Push to GitHub
git push -u origin main

echo "✅ Deploy complete!"
