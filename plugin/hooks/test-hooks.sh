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

# Test 1: File with secret should block
echo 'api_key = "FAKE_TEST_KEY_abcdefghijklmnopqrstuvwxyz1234567890"' > secret.txt
git add secret.txt
if ! "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Blocks commit with API key"
else
  log_fail "Should block commit with API key"
fi
git reset --quiet HEAD secret.txt
rm secret.txt

# Test 2: File with AWS key should block
echo 'aws_key = "AKIAIOSFODNN7EXAMPLE"' > aws.txt
git add aws.txt
if ! "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Blocks commit with AWS access key"
else
  log_fail "Should block commit with AWS key"
fi
git reset --quiet HEAD aws.txt
rm aws.txt

# Test 3: File with private key should block
printf '%s\n' '-----BEGIN RSA PRIVATE KEY-----' 'MIIEpAIBAAKCAQEA...' '-----END RSA PRIVATE KEY-----' > key.pem
git add key.pem
if ! "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Blocks commit with private key"
else
  log_fail "Should block commit with private key"
fi
git reset --quiet HEAD key.pem
rm key.pem

# Test 4: Normal code should pass
echo 'const x = 42;' > clean.js
git add clean.js
if "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Passes commit without secrets"
else
  log_fail "Should pass commit without secrets"
fi
git commit --quiet -m "clean commit"

# Test 5: Test files should be skipped
echo 'api_key = "FAKE_TEST_KEY_abcdefghijklmnopqrstuvwxyz1234567890"' > auth.test.js
git add auth.test.js
if "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then
  log_pass "Skips test files"
else
  log_fail "Should skip test files"
fi
git commit --quiet -m "test file"

# Test 6: .env.example should be skipped
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

# Test 7: Commit with UR reference should pass
echo "Fix session state (UR-003)" > "$TEMP_DIR/.git/COMMIT_MSG"
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Passes commit with UR-003 reference"
else
  log_fail "Should pass commit with UR-003"
fi

# Test 8: Commit with TC reference should pass
echo "Implement idle debounce (TC-005)" > "$TEMP_DIR/.git/COMMIT_MSG"
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Passes commit with TC-005 reference"
else
  log_fail "Should pass commit with TC-005"
fi

# Test 9: Commit with BUC reference should pass
echo "Support mobile agent management (BUC-001)" > "$TEMP_DIR/.git/COMMIT_MSG"
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Passes commit with BUC-001 reference"
else
  log_fail "Should pass commit with BUC-001"
fi

# Test 10: Commit without reference should warn (exit 0)
echo "Fix a bug" > "$TEMP_DIR/.git/COMMIT_MSG"
if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Warns (exit 0) on commit without reference"
else
  log_fail "Should warn (exit 0), not block"
fi

# Test 11: Strict mode should block
echo "Fix a bug" > "$TEMP_DIR/.git/COMMIT_MSG"
export VOLERE_TRACEABILITY_STRICT=1
if ! "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
  log_pass "Blocks in strict mode without reference"
else
  log_fail "Should block in strict mode"
fi
unset VOLERE_TRACEABILITY_STRICT

# Test 12: Merge commits should be skipped
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
echo "Results:"
echo "  $PASS passed, $FAIL failed"
# ============================================================

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
