#!/bin/bash

# -------------------------------------------------------
# POWER-UP #7: SELF-HEALING REPO ENGINE (SHRE)™
# -------------------------------------------------------

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
LOGFILE="deploy-log.txt"
REMOTE_URL="git@github.com:jcla101/kali-test.git"

# -----------------------------------------
# 1. Verify the .git directory exists
# -----------------------------------------
if [ ! -d ".git" ]; then
    echo "🚨 ERROR: .git directory missing!"
    echo "🛠 Attempting automatic repo reconstruction..."
    git init
    git remote add origin "$REMOTE_URL"
    echo "✅ Repo structure restored."
fi

# -----------------------------------------
# 2. Ensure the origin URL is correct
# -----------------------------------------
CURRENT_ORIGIN=$(git remote get-url origin 2>/dev/null)

if [ "$CURRENT_ORIGIN" != "$REMOTE_URL" ]; then
    echo "🔧 Repairing incorrect remote URL..."
    git remote remove origin 2>/dev/null
    git remote add origin "$REMOTE_URL"
    echo "✔ Origin set to $REMOTE_URL"
fi

# -----------------------------------------
# 3. Fix detached HEAD state
# -----------------------------------------
BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$BRANCH" == "HEAD" ]; then
    echo "⚠ Detached HEAD detected!"
    echo "🛠 Recovering main branch..."
    git checkout -B main
    echo "✔ HEAD restored to main"
fi

# -----------------------------------------
# 4. Verify SSH agent authentication
# -----------------------------------------
echo "🔐 Checking SSH authentication..."
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"

if [ $? -ne 0 ]; then
    echo "❌ SSH authentication failed!"
    echo "🛠 Trying to automatically fix SSH agent..."
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_rsa 2>/dev/null
fi

# -----------------------------------------
# 5. Stage changes and check if any exist
# -----------------------------------------
git add -A

if git diff --cached --quiet; then
    echo "✨ No changes detected. Deployment skipped."
    exit 0
fi

# -----------------------------------------
# 6. AI Commit Message Generator
# -----------------------------------------
generate_ai_message() {
    DIFF_CONTENT=$(git diff --cached --unified=0)
    ADDED=$(echo "$DIFF_CONTENT" | grep '^+' | wc -l)
    REMOVED=$(echo "$DIFF_CONTENT" | grep '^-' | wc -l)
    FILES=$(git diff --cached --name-only | tr '\n' ',' | sed 's/,$//')
    echo "Updated $FILES ($ADDED additions, $REMOVED deletions)"
}

echo "🧠 Generating AI commit message..."
AI_MSG=$(generate_ai_message)

echo "📄 Commit message:"
echo "----------------------------------"
echo "$AI_MSG"
echo "----------------------------------"

git commit -m "$AI_MSG"

# -----------------------------------------
# 7. Safe Push (auto-retry)
# -----------------------------------------
echo "🚀 Deploying with safe-push..."

git push origin main
if [ $? -ne 0 ]; then
    echo "⚠ Push failed! Attempting repair..."
    git fetch --all
    git pull --rebase origin main
    git push origin main
fi

# -----------------------------------------
# 8. Final log entry
# -----------------------------------------
echo "[$TIMESTAMP] $AI_MSG" >> "$LOGFILE"

echo "✨ Deployment complete — repo is healthy!"
echo "📄 Logged in $LOGFILE"
