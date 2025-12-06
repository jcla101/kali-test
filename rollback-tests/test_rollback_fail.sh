#!/bin/bash
set -e

echo "🧪 Rollback failure test starting..."

# 1) Remember the current safe state
START_COMMIT=$(git rev-parse HEAD)
START_TAG=$(git tag --sort=-v:refname | head -1)

echo "   • Start commit: $START_COMMIT"
echo "   • Start tag:    ${START_TAG:-<none>}"

# 2) Make a tiny change so deploy.sh has something to release
echo "rollback-test $(date)" >> test.txt
git add test.txt

# 3) Inject a *deliberate failure* into deploy.sh near the end
#    (after your rollback trap has been set)
if ! grep -q "ROLLBACK_TEST_MARKER" deploy.sh; then
  cat << 'EOF' >> deploy.sh

# ROLLBACK_TEST_MARKER
echo "💥 Simulating deploy failure for rollback test..."
false   # non-zero exit code → should trigger rollback()
EOF
fi
git add deploy.sh

# 4) Run deploy.sh and EXPECT it to fail
set +e
./deploy.sh
STATUS=$?
set -e

if [ "$STATUS" -eq 0 ]; then
  echo "❌ deploy.sh succeeded but was expected to FAIL"
  exit 1
fi

echo "   • deploy.sh failed as expected, checking rollback state..."

# 5) Verify HEAD and tag are back to the original safe point
HEAD_COMMIT=$(git rev-parse HEAD)
LATEST_TAG=$(git tag --sort=-v:refname | head -1)

if [ "$HEAD_COMMIT" != "$START_COMMIT" ]; then
  echo "❌ HEAD moved (rollback failed)"
  echo "   Start: $START_COMMIT"
  echo "   Now:   $HEAD_COMMIT"
  exit 1
fi

if [ "$LATEST_TAG" != "$START_TAG" ]; then
  echo "❌ Latest tag changed (rollback failed)"
  echo "   Start tag: $START_TAG"
  echo "   Now tag:   $LATEST_TAG"
  exit 1
fi

# 6) Make sure working tree is clean
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ Working tree is not clean after rollback"
  exit 1
fi

echo "✅ Rollback test passed: repo restored to $START_TAG @ $START_COMMIT"

# 7) Clean up any injected marker (reset deploy.sh to the safe version)
git checkout -- deploy.sh

echo "🧹 Cleanup complete."
