#!/bin/bash

# ----------- POWER-UP #4: Auto-Deploy System -----------
MSG="$1"

if [ -z "$MSG" ]; then
    MSG="Auto-deploy update from Kali"
fi

echo "🔄 Staging files..."
git add -A

echo "📝 Creating commit..."
git commit -m "$MSG"

echo "🚀 Deploying to GitHub..."
git push

echo "📡 Checking remote status..."
git remote -v

echo "📄 Latest commit log:"
git log -1 --stat --decorate --color

echo "🌿 Current branch:"
git branch --show-current

echo "✨ Done! GitHub synced successfully!"
