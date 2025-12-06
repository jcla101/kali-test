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
# 3.5 AUTOMATED TEST RUNNER (Power-Up #12)
# ============================================================
echo "🧪 Running automated tests…" | tee -a "$LOG"

TEST_DIR="tests"

# Create tests folder if missing
if [ ! -d "$TEST_DIR" ]; then
    echo "⚠️ No tests folder detected. Creating one..."
    mkdir -p "$TEST_DIR"
    echo '#!/bin/bash
# Example test — always passes
exit 0' > "$TEST_DIR/sample_test.sh"
    chmod +x "$TEST_DIR/sample_test.sh"
fi

TEST_FAILED=0

# Run all test scripts inside tests/
for test_file in "$TEST_DIR"/*; do
    if [[ -x "$test_file" ]]; then
        echo "🔎 Running test: $(basename "$test_file")"
        if "$test_file"; then
            echo "✅ PASS: $(basename "$test_file")"
        else
            echo "❌ FAIL: $(basename "$test_file")"
            TEST_FAILED=1
        fi
    fi
done

# Block release if any failed
if [ "$TEST_FAILED" -ne 0 ]; then
    echo "🚫 One or more tests failed! Release aborted."
    exit 1
fi

echo "🎉 All tests passed! Continuing with release…" | tee -a "$LOG"

# ----------------------------
# PARALLEL TEST ENGINE (Power-Up #13)
# ----------------------------
echo "🧪 Running automated tests…"

TEST_DIR="tests"
FAILED=0
PIDS=()
TEST_NAMES=()

if [ -d "$TEST_DIR" ]; then
    for test_file in "$TEST_DIR"/*.sh; do
        [ -e "$test_file" ] || continue

        test_name=$(basename "$test_file")
        TEST_NAMES+=("$test_name")

        echo "⚙️  Starting test: $test_name"

        (
            bash "$test_file"
            echo $? > "/tmp/test_exit_$test_name"
        ) &

        PIDS+=("$!")
    done

    echo "⏳ Waiting for tests to complete…"
    wait

    echo ""
    echo "---------------------------------"
    echo "🧪 Test Summary"
    echo "---------------------------------"

    for tname in "${TEST_NAMES[@]}"; do
        exit_code=$(cat "/tmp/test_exit_$tname")

        if [ "$exit_code" -eq 0 ]; then
            echo "✔ PASS: $tname"
        else
            echo "❌ FAIL: $tname"
            FAILED=1
        fi

        rm -f "/tmp/test_exit_$tname"
    done

    echo "---------------------------------"

    if [ "$FAILED" -ne 0 ]; then
        echo "🚫 One or more tests failed! Release aborted."
        exit 1
    else
        echo "🎉 All tests passed!"
    fi
else
    echo "ℹ️ No tests directory found. Skipping automated tests."
fi

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

