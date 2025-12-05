#!/bin/bash

# -------------------------------------------------------
#  CLA101 AUTONOMOUS DEPLOY ENGINE
#  Includes:
#   - AI Commit Messages
#   - Auto Semantic Versioning
#   - Auto Tags
#   - Auto Changelog
#   - GitHub Push Pipeline
# -------------------------------------------------------

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOGFILE="deploy.log"

# --- AI Commit Message Generator ------------------------
generate_ai_message() {
    DIFF_CONTENT=$(git diff --cached)

    if [[ -z "$DIFF_CONTENT" ]]; then
        echo "Update applied"
        return
    fi

    # Tiny built-in "AI-style" commit message generator
    if echo "$DIFF_CONTENT" | grep -qi "test"; then
        echo "Update test data"
    elif echo "$DIFF_CONTENT" | grep -qi "deploy"; then
        echo "Improve deployment script"
    else
        echo "General update applied"
    fi
}

AI_MSG=$(generate_ai_message)
echo "🧠 AI Commit Message: $AI_MSG"

# --- Stage all changes ---------------------------------
echo "📦 Staging files…"
git add .

# --- Commit --------------------------------------------
echo "📝 Creating commit…"
git commit -m "$AI_MSG"

# -------------------------------------------------------
# POWER-UP #8 — AUTONOMOUS VERSIONING (Auto-SemVer™)
# -------------------------------------------------------
VERSION_FILE="VERSION"
CHANGELOG="CHANGELOG.md"

# Create version file if missing
if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0.0" > "$VERSION_FILE"
fi

CURRENT_VERSION=$(cat "$VERSION_FILE")
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

CHANGED_FILES=$(git diff --cached --name-only)

if echo "$CHANGED_FILES" | grep -q "deploy.sh"; then
    BUMP="major"
elif echo "$CHANGED_FILES" | grep -q ".sh"; then
    BUMP="minor"
else
    BUMP="patch"
fi

case $BUMP in
    major)
        MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0;;
    minor)
        MINOR=$((MINOR + 1)); PATCH=0;;
    patch)
        PATCH=$((PATCH + 1));;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "$NEW_VERSION" > "$VERSION_FILE"

echo "🏷  New Version: v$NEW_VERSION ($BUMP update)"

# --- Update Changelog -----------------------------------
{
    echo "## v$NEW_VERSION — $TIMESTAMP"
    echo "- $AI_MSG"
    echo ""
} >> "$CHANGELOG"

# Stage version + changelog
git add $VERSION_FILE $CHANGELOG

# Commit version bump
git commit -m "Version bump to v$NEW_VERSION"

# Create git tag
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

# --- Push ------------------------------------------------
echo "🚀 Deploying to GitHub…"
git push --follow-tags

# --- Final Log ------------------------------------------
echo "[$TIMESTAMP] $AI_MSG" >> "$LOGFILE"

echo "✨ Done! GitHub synced successfully!"
