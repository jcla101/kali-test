#!/bin/bash

# ----------------------------------------
# POWER-UP #5: Autonomous Git Deployer (AGD)
# ----------------------------------------

MSG="$1"
LOGFILE="deploy-log.txt"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# If no message provided → auto message
if [ -z "$MSG" ]; then
    MSG="Auto-deploy at $TIMESTAMP"
fi

echo "🔍 Checking for changes..."

# Check for changes
if git diff --quiet && git diff --cached --quiet; then
    echo "✨ No changes detected. Nothing to deploy!"
    exit 0
fi

echo "🖍 Showing color-coded diff:"
git --no-pager diff --color

echo ""
echo "🔄 Staging files..."
git add -A

echo "📝 Creating commit..."
git commit -m "$MSG"

echo "🚀 Deploying to GitHub..."
git push

echo "📡 Remote status:"
git remote -v

echo "📄 Last commit summary:"
git log -1 --stat --decorate --color

# Save to log file
echo "[$TIMESTAMP] $MSG" >> "$LOGFILE"

echo "📁 Deployment logged in $LOGFILE"
echo "✨ Autonomous deploy complete!"
