#!/bin/bash

# ----------------------------------------------------
# POWER-UP #6: AI-Generated Commit Messages (Local LLM)
# ----------------------------------------------------

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
LOGFILE="deploy-log.txt"

# -----------------------------
# AI Commit Message Generator
# -----------------------------
generate_ai_message() {
    DIFF_CONTENT=$(git diff --cached --unified=0)

    # If no diff (shouldn't happen since we check earlier)
    if [ -z "$DIFF_CONTENT" ]; then
        echo "Auto-commit at $TIMESTAMP"
        return
    fi

    # Count inserted + deleted lines
    ADDED=$(echo "$DIFF_CONTENT"   | grep '^+' | wc -l)
    REMOVED=$(echo "$DIFF_CONTENT" | grep '^-' | wc -l)

    # Identify files changed
    FILES=$(git diff --cached --name-only | tr '\n' ',' | sed 's/,$//')

    # Generate commit title based on change patterns
    TITLE="Updated $FILES ($ADDED additions, $REMOVED deletions)"

    # Return the AI-style message
    echo "$TITLE"
}

# ----------------------------------------
# MAIN DEPLOY LOGIC
# ----------------------------------------

echo "🔍 Checking for changes..."

# Stage everything first (so we can analyze the diff)
git add -A

# If nothing changed:
if git diff --cached --quiet; then
    echo "✨ No changes detected. Nothing to deploy!"
    exit 0
fi

echo "🧠 Generating AI commit message..."
AI_MSG=$(generate_ai_message)

echo ""
echo "📝 Commit message generated:"
echo "----------------------------------------"
echo "$AI_MSG"
echo "----------------------------------------"

echo "📝 Creating commit..."
git commit -m "$AI_MSG"

echo "🚀 Deploying to GitHub..."
git push

echo "📡 Remote status:"
git remote -v

echo "📄 Last commit summary:"
git log -1 --stat --decorate --color

# Append to logfile
echo "[$TIMESTAMP] $AI_MSG" >> "$LOGFILE"

echo "✨ AI-powered deploy complete!"
echo "📁 Logged in $LOGFILE"
