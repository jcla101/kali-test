#!/bin/bash

set -e

LOG="deploy-log.txt"
echo "🚀 Starting Release Builder…" | tee -a "$LOG"

# ============================================================
# 1. PRE-FLIGHT CHECKS
# ============================================================
echo "🔍 Running safety checks…" | tee -a "$LOG"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "❌ Not inside a Git repository!"
    exit 1
}

# Ensure something is staged
if ! git diff --cached --quiet; then
    echo "📦 Staged changes detected."
else
    echo "❌ No staged changes. Nothing to release."
    exit 1
fi

# ============================================================
# 2. SEMANTIC VERSION ENGINE (Power-Up #11)
# ============================================================
# Read the staged commit contents to classify the release
DIFF_CONTENT=$(git diff --cached)

if echo "$DIFF_CONTENT" | grep -qi "BREAKING CHANGE"; then
    BUMP="major"
    CHANGE_TYPE="🔥 BREAKING CHANGE"
elif echo "$DIFF_CONTENT" | grep -qi "^feat"; then
    BUMP="minor"
    CHANGE_TYPE="✨ Feature"
elif echo "$DIFF_CONTENT" | grep -qi "^fix"; then
    BUMP="patch"
    CHANGE_TYPE="🐛 Fix"
else
    BUMP="patch"
    CHANGE_TYPE="📦 General Update"
fi

echo "🔧 Semantic classification: $CHANGE_TYPE ($BUMP bump)" | tee -a "$LOG"

# ============================================================
# 3. AUTO-COMMIT WITH AI-ENHANCED MESSAGE
# ============================================================
CHANGED_FILES=$(git diff --cached --name-only | sed 's/^/- /')

AI_MESSAGE="Auto Release: Updated files

Change Type: $CHANGE_TYPE

Changed Files:
$CHANGED_FILES
"

git add -A
git commit -m "$AI_MESSAGE"

# ============================================================
# 4. SEMANTIC VERSION BUMP
# ============================================================
CURRENT=$(git tag --sort=-v:refname | head -1 | sed 's/v//')
[ -z "$CURRENT" ] && CURRENT="1.0.0"

IFS="." read -r MAJ MIN PAT <<< "$CURRENT"

case "$BUMP" in
    major) NEW_VERSION="$((MAJ+1)).0.0" ;;
    minor) NEW_VERSION="$MAJ.$((MIN+1)).0" ;;
    patch) NEW_VERSION="$MAJ.$MIN.$((PAT+1))" ;;
esac

echo "🔢 New version → v$NEW_VERSION" | tee -a "$LOG"
echo "v$NEW_VERSION" > VERSION

git add VERSION
git commit -m "Version bump → v$NEW_VERSION"
git tag "v$NEW_VERSION"

# ============================================================
# 5. SMART CHANGELOG GENERATION
# ============================================================
echo "📝 Generating CHANGELOG…" | tee -a "$LOG"

{
    echo "## v$NEW_VERSION — $(date '+%Y-%m-%d')"
    echo "- $CHANGE_TYPE"
    echo ""
    git log -1 --pretty=format:"%h — %s (%an)"
    echo ""
} >> CHANGELOG.md

git add CHANGELOG.md
git commit -m "Update CHANGELOG for v$NEW_VERSION"

# ============================================================
# 6. RELEASE ARTIFACT PACKAGING
# ============================================================
RELEASE_DIR="releases/v$NEW_VERSION"
mkdir -p "$RELEASE_DIR"

cp -r *.sh *.txt VERSION CHANGELOG.md "$RELEASE_DIR" 2>/dev/null || true

echo "📦 Artifacts stored in $RELEASE_DIR/" | tee -a "$LOG"

# ============================================================
# 7. PUSH TO GITHUB
# ============================================================
echo "🚀 Deploying to GitHub…"
git push origin main --follow-tags

echo "🎉 Release v$NEW_VERSION successfully deployed!"
echo "⚡ Power-Up #11 activated!"

