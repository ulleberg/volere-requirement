#!/bin/bash
# Test suite for Volere hooks
# Creates a temp git repo and tests each hook scenario.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR=$(mktemp -d)
PASS=0
FAIL=0

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

log_pass() {
  echo "  ✓ $1"
  PASS=$((PASS + 1))
}

log_fail() {
  echo "  ✗ $1"
  FAIL=$((FAIL + 1))
}

# Setup temp repo
cd "$TEMP_DIR"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test"

# Create initial commit so HEAD exists
echo "init" > .gitkeep
git add .gitkeep
git commit --quiet -m "Initial commit"

echo "Volere Hook Tests"
echo ""

# ============================================================
echo "check-secrets:"
# ============================================================

# Test 1: File with secret should block (TC-001)
echo 'api_key = "FAKE_TEST_KEY_abcdefghijklmnopqrstuvwxyz1234567890"' > secret.txt
git add secret.txt
if ! "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Blocks commit with API key"
else
  log_fail "Should block commit with API key"
fi
git reset --quiet HEAD secret.txt
rm secret.txt

# Test 2: File with AWS key should block (TC-001)
echo 'aws_key = "AKIAIOSFODNN7EXAMPLE"' > aws.txt
git add aws.txt
if ! "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Blocks commit with AWS access key"
else
  log_fail "Should block commit with AWS key"
fi
git reset --quiet HEAD aws.txt
rm aws.txt

# Test 3: File with private key should block (TC-001)
printf '%s\n' '-----BEGIN RSA PRIVATE KEY-----' 'MIIEpAIBAAKCAQEA...' '-----END RSA PRIVATE KEY-----' > key.pem
git add key.pem
if ! "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Blocks commit with private key"
else
  log_fail "Should block commit with private key"
fi
git reset --quiet HEAD key.pem
rm key.pem

# Test 4: Normal code should pass (TC-001)
echo 'const x = 42;' > clean.js
git add clean.js
if "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Passes commit without secrets"
else
  log_fail "Should pass commit without secrets"
fi
git commit --quiet -m "clean commit"

# Test 5: Test files should be skipped (TC-001)
echo 'api_key = "FAKE_TEST_KEY_abcdefghijklmnopqrstuvwxyz1234567890"' > auth.test.js
git add auth.test.js
if "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Skips test files"
else
  log_fail "Should skip test files"
fi
git commit --quiet -m "test file"

# Test 6: .env.example should be skipped (TC-001)
echo 'API_KEY="your-key-here-replace-me-with-a-real-one"' > .env.example
git add .env.example
if "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Skips .env.example"
else
  log_fail "Should skip .env.example"
fi
git commit --quiet -m "env example"

echo ""

# ============================================================
echo "check-traceability:"
# ============================================================

# Test 7: Commit with UR reference should pass (TC-002)
echo "Fix session state (UR-003)" > "$TEMP_DIR/.git/COMMIT_MSG"
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Passes commit with UR-003 reference"
else
  log_fail "Should pass commit with UR-003"
fi

# Test 8: Commit with TC reference should pass (TC-002)
echo "Implement idle debounce (TC-005)" > "$TEMP_DIR/.git/COMMIT_MSG"
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Passes commit with TC-005 reference"
else
  log_fail "Should pass commit with TC-005"
fi

# Test 9: Commit with BUC reference should pass (TC-002)
echo "Support mobile agent management (BUC-001)" > "$TEMP_DIR/.git/COMMIT_MSG"
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Passes commit with BUC-001 reference"
else
  log_fail "Should pass commit with BUC-001"
fi

# Test 10: Commit without reference should warn (exit 0) (TC-002)
echo "Fix a bug" > "$TEMP_DIR/.git/COMMIT_MSG"
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Warns (exit 0) on commit without reference"
else
  log_fail "Should warn (exit 0), not block"
fi

# Test 11: Strict mode should block (TC-002)
echo "Fix a bug" > "$TEMP_DIR/.git/COMMIT_MSG"
export VOLERE_TRACEABILITY_STRICT=1
if ! "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Blocks in strict mode without reference"
else
  log_fail "Should block in strict mode"
fi
unset VOLERE_TRACEABILITY_STRICT

# Test 12: Merge commits should be skipped (TC-002)
echo "Merge branch 'feature' into main" > "$TEMP_DIR/.git/COMMIT_MSG"
export VOLERE_TRACEABILITY_STRICT=1
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Skips merge commits (even in strict mode)"
else
  log_fail "Should skip merge commits"
fi
unset VOLERE_TRACEABILITY_STRICT

echo ""

# ============================================================
echo "check-checkout:"
# ============================================================

# Create requirements directory and a requirement card
mkdir -p docs/requirements
echo "id: UR-001" > docs/requirements/UR-001.yaml
git add docs/requirements/UR-001.yaml
git commit --quiet -m "Add UR-001"

MAIN_HEAD=$(git rev-parse HEAD)

git checkout --quiet -b feature-branch
echo "id: UR-002" > docs/requirements/UR-002.yaml
git add docs/requirements/UR-002.yaml
git commit --quiet -m "Add UR-002"
FEATURE_HEAD=$(git rev-parse HEAD)

# Test 13: Post-checkout runs without error (advisory) (TC-004)
git checkout --quiet main 2>/dev/null || git checkout --quiet master
if "$SCRIPT_DIR/check-checkout.sh" "$FEATURE_HEAD" "$MAIN_HEAD" "1" >/dev/null 2>&1; then
  log_pass "Post-checkout runs without error (advisory)"
else
  log_fail "Post-checkout should never block (advisory)"
fi

# Test 14: Post-checkout skips file checkouts (TC-004)
if "$SCRIPT_DIR/check-checkout.sh" "$MAIN_HEAD" "$MAIN_HEAD" "0" >/dev/null 2>&1; then
  log_pass "Skips file checkouts (flag=0)"
else
  log_fail "Should skip file checkouts"
fi

# Clean up
git branch -D feature-branch --quiet 2>/dev/null || true

echo ""

# ============================================================
echo "check-merge:"
# ============================================================

# Test 15: Post-merge runs without error when no reqs changed (TC-005)
if "$SCRIPT_DIR/check-merge.sh" "0" >/dev/null 2>&1; then
  log_pass "Post-merge runs without error (no changes)"
else
  log_fail "Post-merge should never block (advisory)"
fi

# Test 16: Post-merge detects changed requirement cards (TC-005)
git checkout --quiet -b merge-test
echo "id: UR-099" > docs/requirements/UR-099.yaml
git add docs/requirements/UR-099.yaml
git commit --quiet -m "Add UR-099"
git checkout --quiet main 2>/dev/null || git checkout --quiet master
git merge --quiet merge-test --no-edit 2>/dev/null || true
if "$SCRIPT_DIR/check-merge.sh" "0" >/dev/null 2>&1; then
  log_pass "Post-merge detects changed cards (advisory)"
else
  log_fail "Post-merge should never block (advisory)"
fi

# Clean up
git branch -D merge-test --quiet 2>/dev/null || true
rm -f docs/requirements/UR-001.yaml docs/requirements/UR-002.yaml docs/requirements/UR-099.yaml

echo ""

# ============================================================
echo "Results:"
echo "  $PASS passed, $FAIL failed"
# ============================================================

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
