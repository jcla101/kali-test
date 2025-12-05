#!/bin/bash

set -e

LOG="deploy-log.txt"

echo "🚀 Starting Release Builder…" | tee -a "$LOG"

# ----------------------------
# 1. PRE-FLIGHT CHECKS
# ----------------------------
echo "🔍 Running safety checks…" | tee -a "$LOG"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "❌ Not inside a Git repo!"
    exit 1
}

# ----------------------------
# 2. DETECT VERSION CHANGE TYPE
# ----------------------------
if git diff --cached | grep -qi "BREAKING"; then
    BUMP="major"
elif git diff --cached | grep -qi "feat"; then
    BUMP="minor"
else
    BUMP="patch"
fi

# ----------------------------
# 3. AUTO-COMMIT WITH AI MESSAGE
# ----------------------------
MESSAGE=$(git diff --cached --name-only | sed 's/^/- /')
MESSAGE="Auto Release: Updated files

Changed:
$MESSAGE
"

git add -A
git commit -m "$MESSAGE"

# ----------------------------
# 4. VERSION BUMP
# ----------------------------
CURRENT=$(git tag --sort=-v:refname | head -1 | sed 's/v//g')
[ -z "$CURRENT" ] && CURRENT="1.0.0"

IFS="." read -r MAJ MIN PAT <<< "$CURRENT"

case "$BUMP" in
    major)
        NEW_VERSION="$((MAJ+1)).0.0"
        ;;
    minor)
        NEW_VERSION="$MAJ.$((MIN+1)).0"
        ;;
    patch)
        NEW_VERSION="$MAJ.$MIN.$((PAT+1))"
        ;;
esac

echo "v$NEW_VERSION" > VERSION
git add VERSION
git commit -m "Version bump → v$NEW_VERSION"

git tag "v$NEW_VERSION"

# ----------------------------
# 5. AUTO-GENERATE CHANGELOG
# ----------------------------
echo "📝 Generating CHANGELOG…" | tee -a "$LOG"

{
    echo "### Release v$NEW_VERSION"
    echo ""
    git log -1 --pretty=format:"%h — %s (%an)"
    echo ""
} >> CHANGELOG.md

git add CHANGELOG.md
git commit -m "Update CHANGELOG for v$NEW_VERSION"

# ----------------------------
# 6. RELEASE ARTIFACTS
# ----------------------------
mkdir -p releases/v$NEW_VERSION

cp -r *.sh *.txt VERSION CHANGELOG.md releases/v$NEW_VERSION 2>/dev/null || true

echo "📦 Artifacts stored in releases/v$NEW_VERSION/" | tee -a "$LOG"

# ----------------------------
# 7. PUSH EVERYTHING
# ----------------------------
git push origin main --follow-tags

echo "🎉 Release v$NEW_VERSION successfully deployed!"
echo "🚀 Power-Up #10 complete!"
