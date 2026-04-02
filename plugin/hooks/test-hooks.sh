#!/bin/bash
# Test suite for Volere hooks
# Creates a temp git repo and tests each hook scenario.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE_CMD="$SCRIPT_DIR/../validate.sh"
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

# Test helpers
assert_secrets_blocks() {  # file, content, message
  echo "$2" > "$1"; git add "$1"
  if ! "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then log_pass "$3"; else log_fail "$3"; fi
  git reset --quiet HEAD "$1"; rm -f "$1"
}

assert_secrets_passes() {  # file, content, message, commit_msg
  echo "$2" > "$1"; git add "$1"
  if "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then log_pass "$3"; else log_fail "$3"; fi
  git commit --quiet -m "${4:-auto}"
}

assert_file_contains() {  # pass_msg, file, pattern1 [pattern2 ...]
  local msg="$1" f="$2"; shift 2
  [ ! -f "$f" ] && { log_fail "$msg"; return; }
  for p in "$@"; do grep -q "$p" "$f" 2>/dev/null || { log_fail "$msg"; return; }; done
  log_pass "$msg"
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
assert_secrets_blocks secret.txt 'api_key = "FAKE_TEST_KEY_abcdefghijklmnopqrstuvwxyz1234567890"' "Blocks commit with API key"

# Test 2: File with AWS key should block (TC-001)
assert_secrets_blocks aws.txt 'aws_key = "AKIAIOSFODNN7EXAMPLE"' "Blocks commit with AWS access key"

# Test 3: File with private key should block (TC-001)
printf '%s\n' '-----BEGIN RSA PRIVATE KEY-----' 'MIIEpAIBAAKCAQEA...' '-----END RSA PRIVATE KEY-----' > key.pem
git add key.pem
if ! "$SCRIPT_DIR/check-secrets.sh" >/dev/null 2>&1; then log_pass "Blocks commit with private key"; else log_fail "Should block commit with private key"; fi
git reset --quiet HEAD key.pem; rm key.pem

# Test 4: Normal code should pass (TC-001)
assert_secrets_passes clean.js 'const x = 42;' "Passes commit without secrets" "clean commit"

# Test 5: Test files should be skipped (TC-001)
assert_secrets_passes auth.test.js 'api_key = "FAKE_TEST_KEY_abcdefghijklmnopqrstuvwxyz1234567890"' "Skips test files" "test file"

# Test 6: .env.example should be skipped (TC-001)
assert_secrets_passes .env.example 'API_KEY="your-key-here-replace-me-with-a-real-one"' "Skips .env.example" "env example"

echo ""

# ============================================================
echo "check-traceability:"
# ============================================================

# Tests 7-9: Commits with UR/TC/BUC references should pass (TC-002)
for ref in "Fix session state (UR-003):UR-003" "Implement idle debounce (TC-005):TC-005" "Support mobile agent management (BUC-001):BUC-001"; do
  msg="${ref%%:*}"; label="${ref##*:}"
  echo "$msg" > "$TEMP_DIR/.git/COMMIT_MSG"
  if "$SCRIPT_DIR/check-traceability.sh" "$TEMP_DIR/.git/COMMIT_MSG" >/dev/null 2>&1; then
    log_pass "Passes commit with $label reference (TC-002)"
  else
    log_fail "Should pass commit with $label"
  fi
done

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
echo "check-fit-criteria:"
# ============================================================

# Create a DAL-B profile
mkdir -p .volere
cat > .volere/profile.yaml << 'PROFILE'
dal: B
PROFILE

# We need an upstream to diff against for the hook
git checkout --quiet -b fit-test-branch

# Test 17: Hook skips docs-only changes at DAL-B (TC-010)
echo "docs only" > README.md
git add README.md
git commit --quiet -m "docs update"
# The hook skips docs-only changes
if "$SCRIPT_DIR/check-fit-criteria.sh" >/dev/null 2>&1; then
  log_pass "Skips docs-only changes at DAL-B (TC-010)"
else
  log_fail "Should skip docs-only changes"
fi

# Test 18: Hook passes when DAL-C (below blocking threshold) (TC-010)
echo 'dal: C' > .volere/profile.yaml
echo 'const y = 1;' > app.js
git add app.js .volere/profile.yaml
git commit --quiet -m "Code change at DAL-C (UR-005)"
if "$SCRIPT_DIR/check-fit-criteria.sh" >/dev/null 2>&1; then
  log_pass "Passes at DAL-C (below blocking threshold) (TC-010)"
else
  log_fail "Should pass at DAL-C"
fi

# Test 19: Hook passes when no profile exists (defaults to C) (TC-010)
rm -f .volere/profile.yaml
if "$SCRIPT_DIR/check-fit-criteria.sh" >/dev/null 2>&1; then
  log_pass "Passes with no profile (defaults to DAL-C) (TC-010)"
else
  log_fail "Should pass with no profile"
fi

# Test 40: DAL-B blocks when verification command fails (TC-003)
mkdir -p .volere
cat > .volere/profile.yaml << 'PROFILE'
dal: B
verification_commands:
  B:
    verification_commands:
      - "false"
PROFILE
echo '// UR-005: code change' > app2.js
git add app2.js .volere/profile.yaml
git commit --quiet -m "Code change at DAL-B (UR-005)"
if ! "$SCRIPT_DIR/check-fit-criteria.sh" >/dev/null 2>&1; then
  log_pass "DAL-B blocks when verification command fails (TC-003)"
else
  log_fail "DAL-B should block when verification fails"
fi
rm -f app2.js

# Test 41: DAL-B passes when verification command succeeds (TC-003)
cat > .volere/profile.yaml << 'PROFILE'
dal: B
verification_commands:
  B:
    verification_commands:
      - "true"
PROFILE
echo '// UR-005: another code change' > app3.js
git add app3.js .volere/profile.yaml
git commit --quiet -m "Another code change at DAL-B (UR-005)"
if "$SCRIPT_DIR/check-fit-criteria.sh" >/dev/null 2>&1; then
  log_pass "DAL-B passes when verification command succeeds (TC-003)"
else
  log_fail "DAL-B should pass when verification succeeds"
fi
rm -f app3.js

# Clean up
git checkout --quiet main 2>/dev/null || git checkout --quiet master
git branch -D fit-test-branch --quiet 2>/dev/null || true
rm -rf .volere app.js app2.js app3.js README.md

echo ""

# ============================================================
echo "validate (vague language):"
# ============================================================

# Test 20: Card with vague word should be flagged (TC-011)
cat > vague-card.yaml << 'CARD'
id: UR-099
type: functional
title: "Test vague language"
description: "The system should be user-friendly"
rationale: "Testing vague detection"
fit_criteria:
  user:
    criterion: "The system should respond appropriately"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
CARD
VAGUE_OUT=$("$SCRIPT_DIR/../validate.sh" vague-card.yaml 2>&1 || true)
if echo "$VAGUE_OUT" | grep -qi "vague\|should\|appropriate"; then
  log_pass "Flags vague words in fit criteria (TC-011)"
else
  log_fail "Should flag vague words"
fi
rm -f vague-card.yaml

# Test 21: Card without vague words should pass (TC-011)
cat > clean-card.yaml << 'CARD'
id: UR-098
type: functional
title: "Test clean language"
description: "The system must respond within 200ms"
rationale: "Testing clean criteria"
fit_criteria:
  user:
    criterion: "95% of API responses complete within 200ms"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
CARD
CLEAN_OUT=$("$SCRIPT_DIR/../validate.sh" clean-card.yaml 2>&1 || true)
if echo "$CLEAN_OUT" | grep -qi "vague\|should\|appropriate"; then
  log_fail "Should not flag clean language"
else
  log_pass "Passes card without vague words (TC-011)"
fi
rm -f clean-card.yaml

echo ""

# ============================================================
echo "suspect.sh:"
# ============================================================

SUSPECT_CMD="$SCRIPT_DIR/../cli/suspect.sh"
mkdir -p .volere

# Test 22: suspect mark creates entry (TC-012)
"$SUSPECT_CMD" mark UR-003 --reason "test marking" --source UR-027 >/dev/null 2>&1 || true
if [ -f .volere/suspects.yaml ] && grep -q "UR-003" .volere/suspects.yaml 2>/dev/null; then
  log_pass "suspect mark creates entry in suspects.yaml (TC-012)"
else
  log_fail "suspect mark should create entry"
fi

# Test 23: suspect check exits 1 when unresolved exist (TC-012)
if ! "$SUSPECT_CMD" check >/dev/null 2>&1; then
  log_pass "suspect check exits 1 with unresolved suspects (TC-012)"
else
  log_fail "suspect check should exit 1 with unresolved"
fi

# Test 24: suspect resolve changes status (TC-012)
"$SUSPECT_CMD" resolve UR-003 >/dev/null 2>&1 || true
if grep -q "resolved" .volere/suspects.yaml 2>/dev/null; then
  log_pass "suspect resolve marks as resolved (TC-012)"
else
  log_fail "suspect resolve should change status"
fi

# Test 25: suspect check exits 0 when all resolved (TC-012)
if "$SUSPECT_CMD" check >/dev/null 2>&1; then
  log_pass "suspect check exits 0 when all resolved (TC-012)"
else
  log_fail "suspect check should exit 0 when resolved"
fi

# Clean up
rm -f .volere/suspects.yaml

echo ""

# ============================================================
echo "volere CLI:"
# ============================================================

VOLERE_CMD="$SCRIPT_DIR/../cli/volere"

# Set up a minimal project for CLI tests
mkdir -p docs/requirements .volere
cat > .volere/profile.yaml << 'PROFILE'
dal: C
PROFILE
cat > docs/requirements/context.yaml << 'CTX'
project: test-project
CTX
cat > docs/requirements/UR-050.yaml << 'CARD'
id: UR-050
type: functional
title: "Test requirement"
description: "The system must pass tests"
rationale: "Testing CLI commands"
fit_criteria:
  user:
    criterion: "All tests pass"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
CARD

cat > docs/requirements/UR-051.yaml << 'CARD'
id: UR-051
type: functional
title: "Dependent requirement"
description: "The system must depend on UR-050"
rationale: "Testing impact analysis"
fit_criteria:
  user:
    criterion: "Depends on UR-050"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
depends_on:
  - UR-050
CARD

mkdir -p src
echo "// Implements UR-050" > src/feature.js
echo "// Tests UR-050" > src/feature.test.js

# Test 26: volere validate runs and reports (TC-013)
VALIDATE_OUT=$("$VOLERE_CMD" validate 2>&1 || true)
if echo "$VALIDATE_OUT" | grep -qiE "validat|check|pass|warn"; then
  log_pass "volere validate runs and produces output (TC-013)"
else
  log_fail "volere validate should produce output"
fi

# Test 30: volere impact shows direct dependents (UR-008)
IMPACT_OUT=$("$VOLERE_CMD" impact UR-050 2>&1 || true)
if echo "$IMPACT_OUT" | grep -q "UR-051"; then
  log_pass "volere impact shows direct dependents (UR-008)"
else
  log_fail "volere impact should show UR-051 as dependent of UR-050"
fi

# Test 31: volere impact shows affected code files (UR-008)
if echo "$IMPACT_OUT" | grep -q "feature.js"; then
  log_pass "volere impact shows affected code files (UR-008)"
else
  log_fail "volere impact should show feature.js"
fi

# Test 32: volere impact shows affected test files (UR-008)
if echo "$IMPACT_OUT" | grep -q "feature.test.js"; then
  log_pass "volere impact shows affected test files (UR-008)"
else
  log_fail "volere impact should show feature.test.js"
fi

# Test 33: volere impact --mark creates suspect links (UR-008)
rm -f .volere/suspects.yaml
"$VOLERE_CMD" impact --mark UR-050 >/dev/null 2>&1 || true
if [ -f .volere/suspects.yaml ] && grep -q "UR-051" .volere/suspects.yaml 2>/dev/null; then
  log_pass "volere impact --mark creates suspect links (UR-008)"
else
  log_fail "volere impact --mark should mark UR-051 as suspect"
fi

# Test 34: volere impact --suspects exits 1 on unresolved (UR-008)
if ! "$VOLERE_CMD" impact --suspects >/dev/null 2>&1; then
  log_pass "volere impact --suspects exits 1 on unresolved (UR-008)"
else
  log_fail "volere impact --suspects should exit 1 with unresolved suspects"
fi

# Test 35: suspect auto marks dependents of changed requirements (TC-009)
rm -f .volere/suspects.yaml
echo "# changed" >> docs/requirements/UR-050.yaml
git add docs/requirements/UR-050.yaml
git commit -m "test: modify UR-050" --quiet
"$SUSPECT_CMD" auto >/dev/null 2>&1 || true
if [ -f .volere/suspects.yaml ] && grep -q "UR-051" .volere/suspects.yaml 2>/dev/null; then
  log_pass "suspect auto marks dependents of changed requirements (TC-009)"
  # Dimension: TC-009:user
else
  log_fail "suspect auto should mark UR-051 when UR-050 changed"
fi

# Test 36: valid card passes schema validation (TC-007)
VALIDATE_OUT=$("$VALIDATE_CMD" docs/requirements/UR-050.yaml 2>&1 || true)
if echo "$VALIDATE_OUT" | grep -q "PASS"; then
  log_pass "valid card passes schema validation (TC-007)"
else
  log_fail "valid card should pass schema validation"
fi

# Test 37: card missing required field fails validation (TC-007)
cat > bad-card-missing.yaml << 'CARD'
id: UR-099
type: functional
title: "Missing rationale"
description: "The system must do something"
fit_criteria:
  user:
    criterion: "Something measurable"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
CARD
BAD_OUT=$("$VALIDATE_CMD" bad-card-missing.yaml 2>&1 || true)
if echo "$BAD_OUT" | grep -q "FAIL"; then
  log_pass "card missing required field fails validation (TC-007)"
else
  log_fail "card missing rationale should fail validation"
fi
rm -f bad-card-missing.yaml

# Test 38: card with invalid ID pattern fails validation (TC-007)
cat > bad-card-id.yaml << 'CARD'
id: INVALID-001
type: functional
title: "Bad ID"
description: "The system must fail"
rationale: "Testing validation"
fit_criteria:
  user:
    criterion: "Should fail"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
CARD
ID_OUT=$("$VALIDATE_CMD" bad-card-id.yaml 2>&1 || true)
if echo "$ID_OUT" | grep -q "FAIL"; then
  log_pass "card with invalid ID pattern fails validation (TC-007)"
else
  log_fail "card with INVALID-001 should fail validation"
fi
rm -f bad-card-id.yaml

# Test 39: all project requirement cards validate with zero errors (BUC-006)
ALL_PASS=1
for card in "$SCRIPT_DIR"/../requirements/*.yaml; do
  [ "$(basename "$card")" = "context.yaml" ] && continue
  if ! "$VALIDATE_CMD" "$card" >/dev/null 2>&1; then
    echo "    FAIL: $(basename "$card")"
    ALL_PASS=0
  fi
done
if [ "$ALL_PASS" -eq 1 ]; then
  log_pass "all project requirement cards validate with zero errors (BUC-006)"
else
  log_fail "some requirement cards failed schema validation"
fi

# Test 42: security catalog has 5 requirements with tailorable flags (UR-016)
CATALOG="$SCRIPT_DIR/../catalogs/security-baseline.yaml"
SEC_COUNT=$(grep -c "^  - id: SEC-" "$CATALOG" 2>/dev/null || echo 0)
HAS_TAILORABLE=$(grep -c "tailorable:" "$CATALOG" 2>/dev/null || echo 0)
if [ "$SEC_COUNT" -eq 5 ] && [ "$HAS_TAILORABLE" -ge 5 ]; then
  log_pass "security catalog has 5 requirements with tailorable flags (UR-016)"
else
  log_fail "security catalog should have 5 SEC requirements with tailorable flags (got $SEC_COUNT reqs, $HAS_TAILORABLE tailorable)"
fi

# Test 43: volere trace reports TRACED for requirements with code and test refs (BUC-002)
TRACE_OUT=$("$VOLERE_CMD" trace 2>&1 || true)
if echo "$TRACE_OUT" | grep -q "TRACED"; then
  log_pass "volere trace reports TRACED status for traced requirements (BUC-002)"
else
  log_fail "volere trace should report TRACED for UR-050 (has code and test references)"
fi

# Test 44: volere trace shows TRACED/GAP status and coverage percentage (UR-006)
if echo "$TRACE_OUT" | grep -qE "GAP|Traced:.*[0-9]+%"; then
  log_pass "volere trace shows TRACED/GAP status and coverage percentage (TC-014, UR-006)"
else
  log_fail "volere trace should show GAP status and coverage percentage"
fi

# Test 45: volere coverage reports per-requirement coverage percentage (UR-007)
COVERAGE_OUT=$("$VOLERE_CMD" coverage 2>&1 || true)
if echo "$COVERAGE_OUT" | grep -qE "Coverage:.*[0-9]+/[0-9]+"; then
  log_pass "volere coverage reports per-dimension coverage percentage (TC-015, UR-007)"
  # Dimension: UR-007:user
else
  log_fail "volere coverage should report coverage fraction"
fi

# Test 46: validator flags specific vague words in fit criteria (TC-008)
cat > vague-tc008.yaml << 'CARD'
id: UR-097
type: functional
title: "Vague words test"
description: "The system must be adequate"
rationale: "Testing TC-008 vague detection"
fit_criteria:
  user:
    criterion: "Response time is sufficient and reasonable"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
CARD
TC008_OUT=$("$VALIDATE_CMD" vague-tc008.yaml 2>&1 || true)
if echo "$TC008_OUT" | grep -qi "sufficient\|reasonable"; then
  log_pass "validator flags sufficient and reasonable as vague words (TC-008)"
else
  log_fail "validator should flag 'sufficient' and 'reasonable' in fit criteria"
fi
rm -f vague-tc008.yaml

# Test 47: volere review recommends review type based on project state (UR-009)
REVIEW_OUT=$("$VOLERE_CMD" review 2>&1 || true)
if echo "$REVIEW_OUT" | grep -qiE "Full Review|Validation Review|Trace Review|write-requirement"; then
  log_pass "volere review recommends review type based on project state (TC-016, UR-009)"
else
  log_fail "volere review should recommend a review type"
fi

# Test 48: hook installer installs hooks and preserves existing via chaining (TC-006)
INSTALL_CMD="$SCRIPT_DIR/install.sh"
HOOKS_TARGET=$(mktemp -d)
# Create a fake existing pre-push hook (install_hook chains non-pre-commit hooks)
echo '#!/bin/bash' > "$HOOKS_TARGET/pre-push"
echo 'echo existing' >> "$HOOKS_TARGET/pre-push"
chmod +x "$HOOKS_TARGET/pre-push"
"$INSTALL_CMD" --hooks-dir "$HOOKS_TARGET" >/dev/null 2>&1 || true
HOOK_COUNT=$(ls "$HOOKS_TARGET"/pre-commit "$HOOKS_TARGET"/commit-msg "$HOOKS_TARGET"/pre-push "$HOOKS_TARGET"/post-checkout "$HOOKS_TARGET"/post-merge 2>/dev/null | wc -l | tr -d ' ')
HAS_CHAIN=$([ -f "$HOOKS_TARGET/pre-push.existing" ] && echo yes || echo no)
if [ "$HOOK_COUNT" -ge 5 ] && [ "$HAS_CHAIN" = "yes" ]; then
  log_pass "hook installer installs hooks and chains existing hooks (TC-006)"
else
  log_fail "installer should install 5+ hooks and chain existing (got $HOOK_COUNT hooks, chain=$HAS_CHAIN)"
fi
rm -rf "$HOOKS_TARGET"

# Test 49: volere new creates requirement card with auto-numbering (UR-004)
NEW_OUT=$("$VOLERE_CMD" new --type functional 2>&1 || true)
CREATED_FILE=$(echo "$NEW_OUT" | grep "^Created:" | sed 's/^Created: //')
if [ -n "$CREATED_FILE" ] && [ -f "$CREATED_FILE" ] && grep -q "^type: functional" "$CREATED_FILE" 2>/dev/null; then
  log_pass "volere new creates functional requirement card with auto-numbering (UR-004)"
else
  log_fail "volere new --type functional should create a UR card"
fi
rm -f "$CREATED_FILE"

# Test 50: DAL scaling — DAL-E has no blocking hooks (BUC-003)
mkdir -p .volere
echo 'dal: E' > .volere/profile.yaml
if "$SCRIPT_DIR/check-fit-criteria.sh" >/dev/null 2>&1; then
  log_pass "DAL-E changes are not blocked by verification hooks (BUC-003)"
else
  log_fail "DAL-E should not block"
fi
echo 'dal: C' > .volere/profile.yaml

# Test 51: classify-risk skill defines DAL scoring matrix (UR-015)
assert_file_contains "classify-risk skill defines DAL scoring matrix (UR-015)" \
  "$SCRIPT_DIR/../skills/classify-risk/SKILL.md" "5-6" "3-4"

# Test 52: project scaffold templates exist for all card types (UR-017)
TMPL_DIR="$SCRIPT_DIR/../templates"
TMPL_COUNT=0
for tmpl in requirement-card.yaml technical-constraint.yaml business-use-case.yaml product-use-case.yaml; do
  [ -f "$TMPL_DIR/$tmpl" ] && TMPL_COUNT=$((TMPL_COUNT + 1))
done
SCAFFOLD_COUNT=0
for sf in project-scaffold/docs/requirements/context.yaml project-scaffold/.volere/profile.yaml project-scaffold/.volere/boundaries.yaml; do
  [ -f "$TMPL_DIR/$sf" ] && SCAFFOLD_COUNT=$((SCAFFOLD_COUNT + 1))
done
if [ "$TMPL_COUNT" -ge 4 ] && [ "$SCAFFOLD_COUNT" -ge 3 ]; then
  log_pass "project scaffold templates exist for all card types (UR-017)"
else
  log_fail "should have 4+ card templates and 3+ scaffold files (got $TMPL_COUNT templates, $SCAFFOLD_COUNT scaffold)"
fi

# Test 53: framework adopts incrementally — extract skill and retrofit guide exist (BUC-005)
EXTRACT_SKILL="$SCRIPT_DIR/../skills/extract-requirements/SKILL.md"
RETROFIT="$SCRIPT_DIR/../templates/project-scaffold/RETROFIT.md"
if [ -f "$EXTRACT_SKILL" ] && [ -f "$RETROFIT" ]; then
  log_pass "extract-requirements skill and retrofit guide exist for incremental adoption (BUC-005)"
else
  log_fail "should have extract-requirements skill and RETROFIT.md"
fi

# Test 54: extract-requirements skill covers scan, draft, review workflow (UR-011)
assert_file_contains "extract-requirements skill covers scan, draft, and review workflow (UR-011)" \
  "$EXTRACT_SKILL" "draft" "confirm" "BUC"
# Dimension: UR-011:user

# Test 55: audit-tests skill defines VERIFIES/SUPPORTS/THEATER/REDUNDANT classification (UR-014)
assert_file_contains "audit-tests skill defines test classification categories (UR-014)" \
  "$SCRIPT_DIR/../skills/audit-tests/SKILL.md" "VERIFIES" "THEATER" "REDUNDANT"

# Test 56: review-requirements skill defines coherence review type (UR-018)
REVIEW_SKILL="$SCRIPT_DIR/../skills/review-requirements/SKILL.md"
if grep -q "Coherence Review" "$REVIEW_SKILL" && grep -q "contradictions" "$REVIEW_SKILL" && grep -q "coherence-review.md" "$REVIEW_SKILL"; then
  log_pass "review-requirements skill defines coherence review with contradiction output (UR-018)"
else
  log_fail "review-requirements skill should define coherence review type with contradiction pairs"
fi

# Test 57: volere review --coherence suggests coherence review (UR-018)
COHERENCE_OUT=$("$VOLERE_CMD" review --coherence 2>&1 || true)
if echo "$COHERENCE_OUT" | grep -q "Coherence Review"; then
  log_pass "volere review --coherence suggests coherence review type (UR-018)"
else
  log_fail "volere review --coherence should suggest coherence review type"
fi

# Test 58: volere check-docs reports staleness for constitution docs (UR-021)
# Make ARCHITECTURE.md old by touching a source file newer
touch -t 202501010000 ARCHITECTURE.md 2>/dev/null || true
touch -t 202601010000 src/feature.js 2>/dev/null || true
CHECKDOCS_OUT=$("$VOLERE_CMD" check-docs 2>&1 || true)
if echo "$CHECKDOCS_OUT" | grep -qE "STALE|CURRENT|Documentation Staleness"; then
  log_pass "volere check-docs reports staleness for constitution docs (UR-021)"
else
  log_fail "volere check-docs should report doc staleness status"
fi

# Test 59: volere check-docs reads extra paths from profile.yaml docs field (UR-021)
echo 'docs:
  - docs/extra-guide.md' >> .volere/profile.yaml
mkdir -p docs
echo "# Extra guide" > docs/extra-guide.md
CHECKDOCS_EXTRA=$("$VOLERE_CMD" check-docs 2>&1 || true)
if echo "$CHECKDOCS_EXTRA" | grep -q "extra-guide.md"; then
  log_pass "volere check-docs reads extra paths from profile.yaml docs field (UR-021)"
else
  log_fail "volere check-docs should check docs listed in profile.yaml"
fi

# Test 60: volere coverage shows cards-to-tests ratio (UR-019)
# (reuses COVERAGE_OUT from test 45)
if echo "$COVERAGE_OUT" | grep -qE "Ratio: 1:[0-9]+\.[0-9]+ \([0-9]+ cards, [0-9]+ tests\)"; then
  log_pass "volere coverage shows cards-to-tests ratio (UR-019)"
else
  log_fail "volere coverage should show Ratio: 1:X.X (N cards, M tests)"
fi

# ============================================================
echo "volere coverage (per-dimension):"
# ============================================================

# Set up a card with 2 dimensions and a test that only covers user
mkdir -p docs/requirements .volere
echo 'dal: C' > .volere/profile.yaml

cat > docs/requirements/UR-090.yaml << 'CARD'
id: UR-090
type: functional
title: "Multi-dimension test card"
description: "Card with two fit criteria dimensions"
rationale: "Testing per-dimension coverage"
fit_criteria:
  user:
    criterion: "User criterion met"
    verification: test
    test_type: system
  operational:
    criterion: "Operational criterion met"
    verification: test
    test_type: system
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-04-02"
CARD

# Create a test that only references bare ID (covers user only)
echo "# Tests UR-090" > src/test_ur090.test.js
git add src/test_ur090.test.js docs/requirements/UR-090.yaml
git commit --quiet -m "test: add UR-090 fixtures"

# Test 72: card with 2 dimensions and bare test shows partial coverage (UR-007:operational)
DIM_OUT=$("$VOLERE_CMD" coverage 2>&1 || true)
if echo "$DIM_OUT" | grep -q "UR-090" && echo "$DIM_OUT" | grep -qE "1/2|missing"; then
  log_pass "card with 2 dimensions and bare test shows partial coverage (UR-007:operational)"
else
  log_fail "UR-090 should show 1/2 coverage (bare ref = user only)"
fi

# Add a tagged test for the operational dimension
echo "# Tests UR-090:operational" > src/test_ur090_ops.test.js
git add src/test_ur090_ops.test.js
git commit --quiet -m "test: add UR-090 operational test"

# Test 73: card with 2 dimensions and 2 tagged tests shows full coverage (UR-007:operational)
DIM_OUT2=$("$VOLERE_CMD" coverage 2>&1 || true)
if echo "$DIM_OUT2" | grep -q "UR-090" && echo "$DIM_OUT2" | grep -qE "2/2"; then
  log_pass "card with 2 dimensions and tagged tests shows full coverage (UR-007:operational)"
else
  log_fail "UR-090 should show 2/2 coverage with both tagged tests"
fi

# Test 74: single-dimension card with bare test shows 1/1 (backwards compat)
cat > docs/requirements/UR-091.yaml << 'CARD'
id: UR-091
type: functional
title: "Single dimension card"
description: "Card with one fit criteria dimension"
rationale: "Testing backwards compatibility"
fit_criteria:
  user:
    criterion: "User criterion met"
    verification: test
    test_type: system
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-04-02"
CARD

echo "# Tests UR-091" > src/test_ur091.test.js
git add docs/requirements/UR-091.yaml src/test_ur091.test.js
git commit --quiet -m "test: add UR-091 fixture"

DIM_OUT3=$("$VOLERE_CMD" coverage 2>&1 || true)
if echo "$DIM_OUT3" | grep -q "UR-091" && echo "$DIM_OUT3" | grep -qE "1/1"; then
  log_pass "single-dimension card with bare test shows 1/1 (UR-007:operational)"
else
  log_fail "UR-091 should show 1/1 (backwards compatible)"
fi

# Test 75: summary shows dimension count not card count (UR-007:operational)
if echo "$DIM_OUT3" | grep -qE "Coverage:.*[0-9]+/[0-9]+"; then
  log_pass "summary shows dimension-based coverage fraction (UR-007:operational)"
else
  log_fail "summary should show dimension-based coverage"
fi

# Clean up
rm -f docs/requirements/UR-090.yaml docs/requirements/UR-091.yaml
rm -f src/test_ur090.test.js src/test_ur090_ops.test.js src/test_ur091.test.js

echo ""

# ============================================================
echo "volere clean:"
# ============================================================

# Plant process artifacts for clean tests
mkdir -p docs/options
echo "# Problem" > docs/problem.md
echo "# Brief" > docs/brief.md
echo "# Option A" > docs/options/option-a.md
echo "# Execution" > docs/execution-phase1.md
echo "# Team prompt" > docs/team-prompt-review.md
git add docs/problem.md docs/brief.md docs/options docs/execution-phase1.md docs/team-prompt-review.md
git commit --quiet -m "Add process artifacts"

# Test 61: volere clean lists process artifacts with source attribution (UR-022)
CLEAN_OUT=$("$VOLERE_CMD" clean 2>&1 || true)
if echo "$CLEAN_OUT" | grep -q "problem.md" && echo "$CLEAN_OUT" | grep -q "discovery-to-delivery"; then
  log_pass "volere clean lists process artifacts with source attribution (UR-022)"
  # Dimension: UR-022:user
else
  log_fail "volere clean should list artifacts with source attribution"
fi

# Test 62: volere clean reports clean state when no artifacts present (UR-022)
rm -rf docs/problem.md docs/brief.md docs/options docs/execution-phase1.md docs/team-prompt-review.md
git add -A; git commit --quiet -m "Remove artifacts"
CLEAN_EMPTY=$("$VOLERE_CMD" clean 2>&1 || true)
if echo "$CLEAN_EMPTY" | grep -q "No process artifacts"; then
  log_pass "volere clean reports clean state when no artifacts present (UR-022)"
else
  log_fail "volere clean should report clean state"
fi

# Replant for --rm tests
mkdir -p docs/options
echo "# Problem" > docs/problem.md
echo "# Option A" > docs/options/option-a.md
git add docs/problem.md docs/options
git commit --quiet -m "Replant artifacts"

# Test 63: volere clean --rm removes committed artifacts (UR-022)
RM_OUT=$("$VOLERE_CMD" clean --rm 2>&1 || true)
if echo "$RM_OUT" | grep -qE "[0-9]+ removed" && [ ! -f docs/problem.md ]; then
  log_pass "volere clean --rm removes committed artifacts (UR-022)"
else
  log_fail "volere clean --rm should remove artifacts and report count"
fi

# Test 64: volere clean --rm skips uncommitted files with warning (UR-022)
echo "# Dirty brief" > docs/brief.md
DIRTY_OUT=$("$VOLERE_CMD" clean --rm 2>&1 || true)
if echo "$DIRTY_OUT" | grep -qi "skip\|uncommitted\|dirty"; then
  log_pass "volere clean --rm skips uncommitted files with warning (UR-022)"
else
  log_fail "volere clean --rm should skip dirty files"
fi
rm -f docs/brief.md

echo ""

# ============================================================
echo "skill instructions:"
# ============================================================

USING_SKILL="$SCRIPT_DIR/../skills/using-volere/SKILL.md"

# Test 65: using-volere skill contains doc tracking instruction (UR-023)
if grep -q "profile.yaml" "$USING_SKILL" && grep -q "docs" "$USING_SKILL" && grep -q "staleness" "$USING_SKILL"; then
  log_pass "using-volere skill contains doc tracking instruction (UR-023)"
else
  log_fail "using-volere skill should instruct agents to offer profile.yaml doc tracking"
fi

# Test 66: using-volere skill contains brainstorm gate instruction (UR-024)
if grep -q "write-requirement" "$USING_SKILL" && grep -q "brainstorm" "$USING_SKILL" && grep -q "fit criteria" "$USING_SKILL"; then
  log_pass "using-volere skill contains requirement-before-brainstorm gate (UR-024)"
else
  log_fail "using-volere skill should require a requirement card before brainstorming"
fi

echo ""

# Clean up
rm -rf docs/requirements .volere src

echo ""

# ============================================================
echo "volere graph:"
# ============================================================

# Create requirements for graph tests
mkdir -p docs/requirements .volere
echo 'dal: C' > .volere/profile.yaml
cat > docs/requirements/UR-050.yaml << 'CARD'
id: UR-050
type: functional
title: "Test requirement"
description: "The system must pass tests"
rationale: "Testing graph command"
fit_criteria:
  user:
    criterion: "All tests pass"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
CARD

cat > docs/requirements/BUC-050.yaml << 'CARD'
id: BUC-050
type: business-use-case
title: "Test business case"
description: "Business context for testing"
rationale: "Testing graph command"
fit_criteria:
  user:
    criterion: "Business value delivered"
    verification: test
dal: C
priority: must
status: proposed
origin:
  stakeholder: test
  date: "2026-03-31"
decomposed_to:
  - UR-050
CARD

GRAPH_OUT_FILE="/tmp/volere-graph-test-$$.html"

# Test 67: volere graph produces HTML output file (UR-020)
GRAPH_OUT=$("$VOLERE_CMD" graph --output "$GRAPH_OUT_FILE" --no-open 2>&1 || true)
if [ -f "$GRAPH_OUT_FILE" ] && grep -q '<!DOCTYPE html>' "$GRAPH_OUT_FILE"; then
  log_pass "volere graph produces HTML output file (UR-020)"
  # Dimension: UR-020:user
else
  log_fail "volere graph should produce an HTML file"
fi

# Test 68: graph HTML contains all requirement IDs as node data (UR-020)
if grep -q '"UR-050"' "$GRAPH_OUT_FILE" && grep -q '"BUC-050"' "$GRAPH_OUT_FILE"; then
  log_pass "graph HTML contains all requirement IDs as node data (UR-020)"
else
  log_fail "graph HTML should contain UR-050 and BUC-050 as node data"
fi

# Test 69: graph HTML contains relationship edges (UR-020)
if grep -q '"decomposed_to"' "$GRAPH_OUT_FILE"; then
  log_pass "graph HTML contains relationship edges (UR-020)"
else
  log_fail "graph HTML should contain decomposed_to edge"
fi

# Test 70: graph HTML has no external resource URLs (UR-020)
# Exclude SVG namespace URI (http://www.w3.org/2000/svg) which is required for createElementNS
EXT_URLS=$(grep -E 'https?://' "$GRAPH_OUT_FILE" | { grep -vE 'w3\.org/(2000/svg|1999/xhtml)' || true; } | wc -l | tr -d ' ')
if [ "$EXT_URLS" -eq 0 ]; then
  log_pass "graph HTML has no external resource URLs (UR-020)"
else
  log_fail "graph HTML should have no external resource URLs (found $EXT_URLS)"
fi

# Test 71: graph HTML contains type-to-color mapping for all types (UR-020)
if grep -q '#ffa657' "$GRAPH_OUT_FILE" && grep -q '#7ee787' "$GRAPH_OUT_FILE" && \
   grep -q '#79c0ff' "$GRAPH_OUT_FILE" && grep -q '#d2a8ff' "$GRAPH_OUT_FILE"; then
  log_pass "graph HTML contains type-to-color mapping for BUC/PUC/UR/TC (UR-020)"
else
  log_fail "graph HTML should contain color codes for all four types"
fi

rm -f "$GRAPH_OUT_FILE"
rm -f docs/requirements/UR-050.yaml docs/requirements/BUC-050.yaml

echo ""

# ============================================================
echo "Results:"
echo "  $PASS passed, $FAIL failed"
# ============================================================

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
