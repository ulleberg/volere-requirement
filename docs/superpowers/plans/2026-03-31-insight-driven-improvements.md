# Insight-Driven Plugin Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 16 improvements to the Volere plugin derived from 8 session insights — schema additions, skill updates, new hooks, and productization changes.

**Architecture:** Additive changes to existing schemas (new optional fields), skill markdown updates (new sections), two new bash hooks (post-checkout, post-merge), and installer/CLI updates. All changes are backward compatible — existing requirement cards remain valid.

**Tech Stack:** JSON Schema, Markdown (skills), Bash (hooks/CLI), YAML (templates/profiles)

**Spec:** `docs/superpowers/specs/2026-03-31-insight-driven-improvements-design.md`

---

### Task 1: Schema — Add `cross_verify` to requirement schema

**Files:**
- Modify: `plugin/schema/requirement.schema.json:92-111`

- [ ] **Step 1: Add `cross_verify` field to properties**

In `plugin/schema/requirement.schema.json`, add after the `decomposed_to` property (after line 111):

```json
    "cross_verify": {
      "type": "array",
      "items": { "type": "string", "pattern": "^(UR|TC|SHR|SEC|BUC|PUC)-[0-9]{3}$" },
      "description": "Requirements whose fit criteria must be re-verified when this requirement changes — catches cross-requirement breakage (e.g., CSP hardening breaking CDN-dependent pages)"
    },
```

- [ ] **Step 2: Validate schema is valid JSON**

Run: `python3 -c "import json; json.load(open('plugin/schema/requirement.schema.json'))"`
Expected: No output (valid JSON)

- [ ] **Step 3: Validate existing cards still pass**

Run: `plugin/validate.sh plugin/requirements/UR-001.yaml 2>&1; plugin/validate.sh plugin/requirements/UR-002.yaml 2>&1`
Expected: Both pass (field is optional)

- [ ] **Step 4: Commit**

```bash
git add plugin/schema/requirement.schema.json
git commit -m "Add cross_verify field to requirement schema (Insight 2)

Captures cross-requirement verification dependencies — e.g., CSP
hardening must re-verify grid and TTS requirements."
```

---

### Task 2: Schema — Add `verification_method` to fit criteria

**Files:**
- Modify: `plugin/schema/requirement.schema.json:127-157` (the `$defs/fit_criterion` section)

- [ ] **Step 1: Add `verification_method` to fit_criterion definition**

In the `fit_criterion` definition's `properties` object (after the `evidence` property, line 154), add:

```json
        "verification_method": {
          "type": "string",
          "enum": ["unit", "integration", "system", "acceptance"],
          "description": "Expected V-Model verification level — flags mismatches when a browser-facing criterion has only unit tests"
        }
```

- [ ] **Step 2: Validate schema is valid JSON**

Run: `python3 -c "import json; json.load(open('plugin/schema/requirement.schema.json'))"`
Expected: No output (valid JSON)

- [ ] **Step 3: Validate existing cards still pass**

Run: `plugin/validate.sh plugin/requirements/UR-001.yaml 2>&1; plugin/validate.sh plugin/requirements/UR-002.yaml 2>&1`
Expected: Both pass (field is optional)

- [ ] **Step 4: Commit**

```bash
git add plugin/schema/requirement.schema.json
git commit -m "Add verification_method to fit criteria schema (Insight 3)

Makes expected V-Model level explicit per criterion so audit-tests
can flag mismatches (browser-facing criterion with only unit tests)."
```

---

### Task 3: Schema — Add `verification_level` to evidence schema

**Files:**
- Modify: `plugin/schema/evidence.schema.json:5-8`
- Modify: `plugin/schema/evidence.schema.json:27-30` (add new property)

- [ ] **Step 1: Add `verification_level` to required fields**

In `plugin/schema/evidence.schema.json`, change the `required` array on line 8 from:

```json
  "required": ["requirement", "dimension", "criterion", "method", "status"],
```

to:

```json
  "required": ["requirement", "dimension", "criterion", "method", "status", "verification_level"],
```

- [ ] **Step 2: Add `verification_level` property**

After the `method` property (after line 26), add:

```json
    "verification_level": {
      "type": "string",
      "enum": ["unit", "integration", "system", "acceptance"],
      "description": "V-Model level at which this evidence was collected. DAL-B requires system minimum, DAL-A requires acceptance."
    },
```

- [ ] **Step 3: Update evidence template**

In `plugin/templates/evidence/evidence-record.yaml`, add `verification_level` field after `method`:

```yaml
verification_level: unit  # unit | integration | system | acceptance — V-Model level
```

- [ ] **Step 4: Validate schema is valid JSON**

Run: `python3 -c "import json; json.load(open('plugin/schema/evidence.schema.json'))"`
Expected: No output (valid JSON)

- [ ] **Step 5: Commit**

```bash
git add plugin/schema/evidence.schema.json plugin/templates/evidence/evidence-record.yaml
git commit -m "Add verification_level to evidence schema (Insight 5)

Records V-Model level (unit/integration/system/acceptance) at which
evidence was collected. DAL-B requires system minimum, DAL-A acceptance."
```

---

### Task 4: Schema — Add `verification_commands` to profile schema

**Files:**
- Modify: `plugin/schema/profile.schema.json:28-58` (the `$defs/profile_level` section)

- [ ] **Step 1: Add `verification_commands` property to profile_level**

In the `profile_level` definition's `properties` object (after the `verification` property, around line 56), add:

```json
        "verification_commands": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Commands to run for fit criteria verification at this DAL level (e.g., 'npm test', 'npx playwright test'). Falls back to auto-detection if not specified."
        }
```

- [ ] **Step 2: Validate schema is valid JSON**

Run: `python3 -c "import json; json.load(open('plugin/schema/profile.schema.json'))"`
Expected: No output (valid JSON)

- [ ] **Step 3: Commit**

```bash
git add plugin/schema/profile.schema.json
git commit -m "Add verification_commands to profile schema (Insight 4)

Configurable test commands per DAL level instead of hardcoded go test / npm test.
Supports browser verification (Playwright, custom browse scripts)."
```

---

### Task 5: Skill — Update `write-requirement` with cross-impact prompt

**Files:**
- Modify: `plugin/skills/write-requirement/skill.md:117-119` (after traceability section)

- [ ] **Step 1: Add cross-impact section after traceability**

After the "### 7. Traceability" section (line 118), add a new section:

```markdown
### 8. Cross-Impact Verification

Ask: **"Does this requirement's fit criterion affect other requirements?"**

If this is a security, infrastructure, or platform change, identify which user-facing requirements could break:

| Change type | Ask | Example |
|-------------|-----|---------|
| Security (CSP, CORS, auth) | Which browser surfaces or API consumers does this restrict? | CSP blocking CDN scripts breaks grid page |
| Infrastructure (ports, networking, deployment) | Which features depend on the infrastructure being changed? | Port change breaks WebSocket connections |
| Performance (rate limits, timeouts, caching) | Which features hit the constrained resource? | Cache TTL change breaks real-time updates |
| Data model (schema, storage, format) | Which features read/write this data? | Column rename breaks downstream queries |

Populate the `cross_verify` field with the affected requirement IDs:

```yaml
cross_verify:
  - UR-03   # Grid page — loads React from CDN
  - UR-12   # TTS audio — uses blob: URLs
```

**Test:** If this requirement changes, would someone know which OTHER requirements to re-verify? If not, `cross_verify` is incomplete.
```

- [ ] **Step 2: Update quality checklist**

Add to the quality checklist (around line 156):

```markdown
- [ ] If this is a security/infrastructure change, `cross_verify` lists affected user-facing requirements
```

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/write-requirement/skill.md
git commit -m "Add cross-impact prompt to write-requirement skill (Insight 2)

Guides authors to populate cross_verify field for security and
infrastructure requirements that could break user-facing features."
```

---

### Task 6: Skill — Update `audit-tests` with verification level reporting

**Files:**
- Modify: `plugin/skills/audit-tests/skill.md:106-164`

- [ ] **Step 1: Add verification level reporting section**

After the "## Output Format" heading (line 106), add a new subsection before "### Classification Table":

```markdown
### Verification Level Analysis

For each fit criterion, report the highest V-Model level at which it has been tested:

| Requirement | Fit Criterion | Expected Level | Actual Level | Gap? |
|-------------|--------------|----------------|--------------|------|
| UR-03 | Grid renders sessions | system | unit | YES — browser-facing criterion needs system test |
| UR-12 | TTS plays audio | acceptance | integration | YES — hardware-adjacent criterion needs acceptance test |
| UR-27 | CSP headers set | system | system | No |

**Browser-facing flag:** Any fit criterion containing these keywords requires system or acceptance level verification:
- "user can see", "renders", "displays", "shows", "page", "screen"
- "user can hear", "plays", "audio", "speaks"
- "browser", "loads", "navigates"

If a fit criterion matches these keywords but only has unit or integration tests, flag it:

```
⚠ UR-03:user — "Grid renders all active sessions" — browser-facing criterion
  Current verification: unit (TestGridHandler returns JSON)
  Required verification: system (browser renders grid with sessions visible)
  Action: Add Playwright or browser-check test that verifies the rendered page
```
```

- [ ] **Step 2: Add loopback testing section**

After the "## After the Audit" section (line 152), add:

```markdown
## Loopback Testing Pattern

When a fit criterion involves hardware (microphone, camera, speaker, sensor), don't mark it as "requires manual testing." Instead, suggest a loopback approach:

1. **Identify the service boundary** — where does software meet hardware? (e.g., STT WebSocket endpoint)
2. **Generate synthetic input** — use another service's output (e.g., TTS generates speech → MP3 bytes)
3. **Feed through the pipeline** — send synthetic input through the same path real hardware would use
4. **Verify the output** — assert the pipeline produces the expected result

### Examples

| Feature | Loopback approach |
|---------|------------------|
| STT (microphone) | TTS → MP3 → STT WebSocket → verify transcription keywords |
| Camera upload | Generate test image → POST to inbox → verify file processed |
| Voice commands | TTS a command → STT transcribe → verify intent parsed |
| Speaker output | TTS → verify MP3 is valid audio (duration, format, non-silent) |
| Multi-machine health | Mock peer health endpoint → verify dashboard renders status |

The constraint "we can't test this because it needs hardware" is usually false. The real question: **"What's the minimum loop that exercises the full pipeline without physical devices?"**
```

- [ ] **Step 3: Update the summary format**

In the Summary section (around line 131), add verification level stats:

```markdown
Verification levels:
  Acceptance: 12/55 fit criteria (22%)
  System:     18/55 fit criteria (33%)
  Integration: 15/55 fit criteria (27%)
  Unit only:  10/55 fit criteria (18%)

Browser-facing gaps: 3 criteria with only unit tests (should be system+)
Hardware-adjacent: 2 criteria — loopback approach recommended
```

- [ ] **Step 4: Commit**

```bash
git add plugin/skills/audit-tests/skill.md
git commit -m "Add verification level reporting and loopback testing to audit-tests (Insights 1, 5, 8)

Reports highest V-Model verification level per fit criterion, flags
browser-facing criteria with only unit tests, suggests loopback
testing for hardware-dependent features."
```

---

### Task 7: Skill — Update `classify-risk` with browser-facing auto-escalation

**Files:**
- Modify: `plugin/skills/classify-risk/skill.md:72-78` (override rules section)

- [ ] **Step 1: Add browser-facing override rule**

In the "### Override Rules" section (after line 78), add a new rule:

```markdown
- **Any UR with browser-facing fit criteria → minimum DAL-C, recommend system-level verification**
  Keywords: "user can see", "user can hear", "renders", "displays", "plays", "shows", "browser", "page", "screen"
  Rationale: `curl` returns 200 with valid HTML while the page is black. Browser-facing criteria cannot be verified below system level.
```

- [ ] **Step 2: Add browser-facing example**

After Example 5 (line 195), add:

```markdown
### Example 6: Add grid page for session management
- Q1: Affects one feature used frequently → +1
- Q2: Easy to reverse → 0
- Q3: Functional UR → 0
- Total: 1 → **DAL-C**
- Override: browser-facing fit criteria ("user can see sessions in a grid") → minimum DAL-C ✓
- Note: system-level verification required (Playwright or browser check, not just API test)
```

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/classify-risk/skill.md
git commit -m "Add browser-facing auto-escalation to classify-risk (Insight 3)

Browser-facing fit criteria auto-escalate to minimum DAL-C with
system-level verification. curl 200 != page renders correctly."
```

---

### Task 8: Hook — Create `check-checkout.sh` (post-checkout)

**Files:**
- Create: `plugin/hooks/check-checkout.sh`

- [ ] **Step 1: Write the hook**

```bash
#!/bin/bash
# Volere post-checkout hook: detect requirement drift between branches
# Advisory only — never blocks (checkout already happened).
#
# Install: plugin/hooks/install.sh (installs as post-checkout)

set -euo pipefail

# post-checkout receives: previous HEAD, new HEAD, branch flag (1=branch, 0=file)
PREV_HEAD="${1:-}"
NEW_HEAD="${2:-}"
BRANCH_FLAG="${3:-1}"

# Only run on branch checkouts, not file checkouts
if [ "$BRANCH_FLAG" != "1" ]; then
  exit 0
fi

# Skip if no previous HEAD (initial checkout)
if [ -z "$PREV_HEAD" ] || [ "$PREV_HEAD" = "0000000000000000000000000000000000000000" ]; then
  exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROFILE="$PROJECT_ROOT/.volere/profile.yaml"
REQS_DIR="$PROJECT_ROOT/docs/requirements"

# Skip if not a Volere project
if [ ! -d "$PROJECT_ROOT/.volere" ] && [ ! -d "$REQS_DIR" ]; then
  exit 0
fi

echo ""
echo "🔍 Volere post-checkout: checking requirement state"

WARNINGS=0

# 1. Check for DAL mismatch between branches
if [ -f "$PROFILE" ]; then
  CURRENT_DAL=$(grep "^dal:" "$PROFILE" 2>/dev/null | head -1 | awk '{print $2}' || true)
  PREV_DAL=$(git show "$PREV_HEAD:$( git ls-files --full-name "$PROFILE" 2>/dev/null || echo '.volere/profile.yaml')" 2>/dev/null | grep "^dal:" | head -1 | awk '{print $2}' || true)

  if [ -n "$PREV_DAL" ] && [ -n "$CURRENT_DAL" ] && [ "$PREV_DAL" != "$CURRENT_DAL" ]; then
    echo "  ⚠ DAL level changed: $PREV_DAL → $CURRENT_DAL"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# 2. Check for changed requirement cards
if [ -d "$REQS_DIR" ]; then
  CHANGED_REQS=$(git diff --name-only "$PREV_HEAD" "$NEW_HEAD" -- "$REQS_DIR" 2>/dev/null || true)

  if [ -n "$CHANGED_REQS" ]; then
    ADDED=$(echo "$CHANGED_REQS" | while read -r f; do git show "$PREV_HEAD:$(git ls-files --full-name "$f" 2>/dev/null || echo "$f")" >/dev/null 2>&1 || echo "$f"; done | grep -c . || echo 0)
    MODIFIED=$(echo "$CHANGED_REQS" | wc -l | tr -d ' ')

    echo "  ⚠ $MODIFIED requirement card(s) differ from previous branch:"
    echo "$CHANGED_REQS" | while read -r f; do
      echo "    - $(basename "$f")"
    done
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# 3. Quick validation (if volere CLI is available)
VOLERE_CLI="$PROJECT_ROOT/plugin/cli/volere"
if [ -x "$VOLERE_CLI" ] && [ -d "$REQS_DIR" ]; then
  CARD_COUNT=$(find "$REQS_DIR" -name "*.yaml" -not -name "context.yaml" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CARD_COUNT" -gt 0 ]; then
    if ! "$VOLERE_CLI" validate --quiet 2>/dev/null; then
      echo "  ⚠ Some requirement cards may have validation issues"
      echo "    Run: volere validate"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
fi

if [ "$WARNINGS" -eq 0 ]; then
  echo "  ✓ Requirement state consistent"
fi

echo ""
exit 0
```

- [ ] **Step 2: Make executable**

Run: `chmod +x plugin/hooks/check-checkout.sh`

- [ ] **Step 3: Commit**

```bash
git add plugin/hooks/check-checkout.sh
git commit -m "Add post-checkout hook for requirement drift detection (Insight 4)

Advisory hook that warns on DAL mismatch, changed requirement cards,
and validation issues when switching branches. Never blocks."
```

---

### Task 9: Hook — Create `check-merge.sh` (post-merge)

**Files:**
- Create: `plugin/hooks/check-merge.sh`

- [ ] **Step 1: Write the hook**

```bash
#!/bin/bash
# Volere post-merge hook: detect suspect links and cross-verify violations
# Advisory only — never blocks (merge already happened).
#
# Install: plugin/hooks/install.sh (installs as post-merge)

set -euo pipefail

# post-merge receives: squash flag (0=normal merge, 1=squash)
SQUASH_FLAG="${1:-0}"

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
REQS_DIR="$PROJECT_ROOT/docs/requirements"
SUSPECT_CMD="$PROJECT_ROOT/plugin/cli/suspect.sh"

# Skip if not a Volere project
if [ ! -d "$PROJECT_ROOT/.volere" ] && [ ! -d "$REQS_DIR" ]; then
  exit 0
fi

# Get the merge commit range
MERGE_HEAD=$(git rev-parse HEAD)
MERGE_BASE=$(git rev-parse HEAD~1 2>/dev/null || exit 0)

echo ""
echo "🔍 Volere post-merge: checking requirement impacts"

WARNINGS=0

# 1. Find requirement cards changed in the merge
CHANGED_REQS=$(git diff --name-only "$MERGE_BASE" "$MERGE_HEAD" -- "$REQS_DIR" 2>/dev/null | grep '\.yaml$' | grep -v 'context\.yaml' || true)

if [ -z "$CHANGED_REQS" ]; then
  echo "  ✓ No requirement cards changed in merge"
  echo ""
  exit 0
fi

echo "  Changed requirements:"
CHANGED_IDS=""
for f in $CHANGED_REQS; do
  basename_f=$(basename "$f" .yaml)
  echo "    - $basename_f"
  # Extract ID from filename (e.g., UR-003 from UR-003.yaml)
  id=$(echo "$basename_f" | grep -oE '(UR|TC|BUC|PUC|SEC|SHR)-[0-9]{3}' || true)
  if [ -n "$id" ]; then
    CHANGED_IDS="$CHANGED_IDS $id"
  fi
done

# 2. Mark suspect links for changed requirements
if [ -x "$SUSPECT_CMD" ]; then
  for id in $CHANGED_IDS; do
    echo ""
    echo "  Marking suspect links for $id..."
    "$SUSPECT_CMD" auto "$id" 2>/dev/null || true
    WARNINGS=$((WARNINGS + 1))
  done
else
  echo ""
  echo "  ⚠ Suspect link manager not found — run 'volere impact <ID>' manually for:"
  for id in $CHANGED_IDS; do
    echo "    - $id"
  done
  WARNINGS=$((WARNINGS + 1))
fi

# 3. Check cross_verify targets
for f in $CHANGED_REQS; do
  full_path="$PROJECT_ROOT/$f"
  if [ -f "$full_path" ]; then
    # Extract cross_verify entries from YAML (simple grep approach)
    CROSS_TARGETS=$(grep -A 20 'cross_verify:' "$full_path" 2>/dev/null | grep -oE '(UR|TC|BUC|PUC|SEC|SHR)-[0-9]{3}' || true)
    if [ -n "$CROSS_TARGETS" ]; then
      basename_f=$(basename "$f" .yaml)
      echo ""
      echo "  ⚠ $basename_f has cross_verify targets that need re-verification:"
      for target in $CROSS_TARGETS; do
        echo "    → $target"
      done
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
done

# 4. Validate merged cards
echo ""
VOLERE_CLI="$PROJECT_ROOT/plugin/cli/volere"
if [ -x "$VOLERE_CLI" ]; then
  if ! "$VOLERE_CLI" validate --quiet 2>/dev/null; then
    echo "  ⚠ Post-merge validation found issues"
    echo "    Run: volere validate"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "  ✓ Post-merge validation passed"
  fi
fi

if [ "$WARNINGS" -gt 0 ]; then
  echo ""
  echo "  $WARNINGS item(s) need attention. Run 'volere validate' for details."
fi

echo ""
exit 0
```

- [ ] **Step 2: Make executable**

Run: `chmod +x plugin/hooks/check-merge.sh`

- [ ] **Step 3: Commit**

```bash
git add plugin/hooks/check-merge.sh
git commit -m "Add post-merge hook for suspect link detection (Insight 4)

Advisory hook that auto-marks suspect links for changed requirements,
flags cross_verify targets needing re-verification, and validates
merged cards. Never blocks."
```

---

### Task 10: Hook — Update installer for full lifecycle

**Files:**
- Modify: `plugin/hooks/install.sh:76-89`

- [ ] **Step 1: Add post-checkout and post-merge installation**

After the pre-push install line (line 78), add:

```bash
# Install post-checkout (check-checkout) — advisory
install_hook "$SCRIPT_DIR/check-checkout.sh" "$HOOKS_DIR/post-checkout" "post-checkout (check-checkout, advisory)"

# Install post-merge (check-merge) — advisory
install_hook "$SCRIPT_DIR/check-merge.sh" "$HOOKS_DIR/post-merge" "post-merge (check-merge, advisory)"
```

- [ ] **Step 2: Update the summary message**

Change the "Done" message at the end (line 89) to:

```bash
echo "Done. 5 hooks installed in $HOOKS_DIR"
echo "  pre-commit:    check-secrets (blocks)"
echo "  commit-msg:    check-traceability (advisory or strict)"
echo "  pre-push:      check-fit-criteria (blocks at DAL-B+)"
echo "  post-checkout: check-checkout (advisory)"
echo "  post-merge:    check-merge (advisory)"
```

- [ ] **Step 3: Commit**

```bash
git add plugin/hooks/install.sh
git commit -m "Update hook installer for full git lifecycle (5 hooks)

Adds post-checkout and post-merge hook installation alongside
existing pre-commit, commit-msg, and pre-push hooks."
```

---

### Task 11: Hook — Update `check-fit-criteria` for configurable commands

**Files:**
- Modify: `plugin/hooks/check-fit-criteria.sh:97-125`

- [ ] **Step 1: Add verification_commands support**

Replace the test runner detection section (lines 97-121) with:

```bash
# Read verification commands from profile
VERIFICATION_CMDS=""
if [ -f "$PROFILE" ]; then
  # Extract verification_commands for current DAL level from profile
  # Simple YAML parsing — looks for the DAL section's verification_commands
  IN_DAL_SECTION=0
  IN_COMMANDS=0
  while IFS= read -r line; do
    # Match DAL section header (e.g., "  B:" or "  A:")
    if echo "$line" | grep -qE "^  $DAL:"; then
      IN_DAL_SECTION=1
      continue
    fi
    # Exit DAL section on next section header
    if [ "$IN_DAL_SECTION" -eq 1 ] && echo "$line" | grep -qE "^  [A-E]:"; then
      IN_DAL_SECTION=0
      IN_COMMANDS=0
      continue
    fi
    # Match verification_commands key
    if [ "$IN_DAL_SECTION" -eq 1 ] && echo "$line" | grep -q "verification_commands:"; then
      IN_COMMANDS=1
      continue
    fi
    # Exit commands on next key at same level
    if [ "$IN_COMMANDS" -eq 1 ] && echo "$line" | grep -qE "^    [a-z]"; then
      IN_COMMANDS=0
      continue
    fi
    # Collect command entries
    if [ "$IN_COMMANDS" -eq 1 ] && echo "$line" | grep -qE '^\s*- "'; then
      cmd=$(echo "$line" | sed 's/.*- "\(.*\)"/\1/')
      VERIFICATION_CMDS="$VERIFICATION_CMDS|$cmd"
    fi
  done < "$PROFILE"
fi

# Run verification commands
if [ -n "$VERIFICATION_CMDS" ]; then
  # Use configured commands
  echo "$VERIFICATION_CMDS" | tr '|' '\n' | grep -v '^$' | while read -r cmd; do
    echo "  Running: $cmd"
    if ! eval "$cmd" > /dev/null 2>&1; then
      echo ""
      echo "  ✗ Verification failed: $cmd"
      echo "  Push blocked (DAL-$DAL requires passing verification)."
      exit 1
    fi
    echo "  ✓ $cmd passed"
  done
  # Check if any command in the pipeline failed
  if [ $? -ne 0 ]; then
    exit 1
  fi
else
  # Fallback: auto-detect test runner (original behavior)
  if [ -f "go.mod" ]; then
    echo "  Running: go test ./... -count=1"
    if ! go test ./... -count=1 > /dev/null 2>&1; then
      echo ""
      echo "  ✗ Tests failed. Push blocked (DAL-$DAL requires passing tests)."
      echo "  Run 'go test ./... -v' to see failures."
      exit 1
    fi
    echo "  ✓ Go tests pass"
  fi

  if [ -f "package.json" ]; then
    if grep -q '"test"' package.json 2>/dev/null; then
      echo "  Running: npm test"
      if ! npm test > /dev/null 2>&1; then
        echo ""
        echo "  ✗ Tests failed. Push blocked (DAL-$DAL requires passing tests)."
        echo "  Run 'npm test' to see failures."
        exit 1
      fi
      echo "  ✓ Node tests pass"
    fi
  fi
fi
```

- [ ] **Step 2: Update the header comment**

Update the hook's header comment (line 2) to mention configurable commands:

```bash
# Volere pre-push hook: check that affected fit criteria have passing tests
# Reads DAL level and verification commands from .volere/profile.yaml.
# Uses configured verification_commands if present, falls back to auto-detection.
# Only blocks at DAL-B and above by default.
```

- [ ] **Step 3: Commit**

```bash
git add plugin/hooks/check-fit-criteria.sh
git commit -m "Support configurable verification commands in check-fit-criteria (Insight 4)

Reads verification_commands from profile.yaml per DAL level.
Falls back to auto-detection (go test / npm test) when not configured.
Enables Playwright and custom browser checks at higher DAL levels."
```

---

### Task 12: Hook tests — Add tests for new hooks

**Files:**
- Modify: `plugin/hooks/test-hooks.sh:165-177`

- [ ] **Step 1: Add check-checkout tests**

Before the Results section (line 168), add:

```bash
# ============================================================
echo "check-checkout:"
# ============================================================

# Create a second branch with different requirements
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

# Test 13: Post-checkout detects requirement changes
git checkout --quiet main 2>/dev/null || git checkout --quiet master
if "$SCRIPT_DIR/check-checkout.sh" "$FEATURE_HEAD" "$MAIN_HEAD" "1" >/dev/null 2>&1; then
  log_pass "Post-checkout runs without error (advisory)"
else
  log_fail "Post-checkout should never block (advisory)"
fi

# Test 14: Post-checkout skips file checkouts
if "$SCRIPT_DIR/check-checkout.sh" "$MAIN_HEAD" "$MAIN_HEAD" "0" >/dev/null 2>&1; then
  log_pass "Skips file checkouts (flag=0)"
else
  log_fail "Should skip file checkouts"
fi

# Clean up
git checkout --quiet main 2>/dev/null || git checkout --quiet master
git branch -D feature-branch --quiet 2>/dev/null || true

echo ""

# ============================================================
echo "check-merge:"
# ============================================================

# Test 15: Post-merge runs without error when no reqs changed
if "$SCRIPT_DIR/check-merge.sh" "0" >/dev/null 2>&1; then
  log_pass "Post-merge runs without error (no changes)"
else
  log_fail "Post-merge should never block (advisory)"
fi

# Test 16: Post-merge detects changed requirement cards
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
```

- [ ] **Step 2: Update results count in test output**

The results section automatically counts PASS/FAIL, so no changes needed — the counts increment correctly. But update the comment if present to reflect "16 tests" instead of "12 tests".

- [ ] **Step 3: Run the test suite**

Run: `plugin/hooks/test-hooks.sh`
Expected: 16 passed, 0 failed

- [ ] **Step 4: Commit**

```bash
git add plugin/hooks/test-hooks.sh
git commit -m "Add tests for post-checkout and post-merge hooks (16/16)

Tests advisory behavior, file checkout skip, no-change merge,
and changed requirement card detection."
```

---

### Task 13: CLI — Make hooks default in `volere init`

**Files:**
- Modify: `plugin/cli/volere:100-108` (init command, hooks section)

- [ ] **Step 1: Update init to install hooks by default with opt-out**

First, add `--no-hooks` flag parsing in the `cmd_init` function. Update the argument parsing (around line 54):

```bash
  while [ $# -gt 0 ]; do
    case "$1" in
      --dal) dal="$2"; shift 2 ;;
      --dal=*) dal="${1#--dal=}"; shift ;;
      --no-hooks) NO_HOOKS=1; shift ;;
      *) shift ;;
    esac
  done
```

Add `NO_HOOKS=0` initialization before the while loop (after `local dal="${1:-C}"`):

```bash
  local NO_HOOKS=0
```

- [ ] **Step 2: Update hooks installation section**

Replace the hooks section (lines 100-108) with:

```bash
  # Install hooks (default: yes, opt-out with --no-hooks)
  echo ""
  if [ "$NO_HOOKS" -eq 1 ]; then
    echo "  Hooks: skipped (--no-hooks). Not recommended for DAL-C+."
  elif [ -d ".git" ]; then
    "$VOLERE_DIR/hooks/install.sh" --hooks-dir ".git/hooks" 2>/dev/null || \
      echo "  Hooks: install manually with: $VOLERE_DIR/hooks/install.sh"
  else
    echo "  Hooks: not a git repo — install hooks after git init"
  fi
```

- [ ] **Step 3: Commit**

```bash
git add plugin/cli/volere
git commit -m "Install hooks by default in volere init (Insight 4)

Hooks are now installed by default. Use --no-hooks to opt out
(not recommended for DAL-C+). Soft constraints drift, hard hold."
```

---

### Task 14: Productization — Parameterize paths in review skill

**Files:**
- Modify: `plugin/skills/review-requirements/skill.md`

- [ ] **Step 1: Read the full review-requirements skill**

Run: Read `plugin/skills/review-requirements/skill.md` in full to identify all hardcoded paths and agent names.

- [ ] **Step 2: Replace hardcoded paths**

Replace any paths like `/Users/thul/repos/ulleberg/thul-agents/agents/...` with:

```markdown
${VOLERE_AGENTS_PATH}/agents/<role>/SOUL.md
```

Replace specific agent names (Steve, Albert, Steinar) with role-based references:
- "architecture-reviewer" instead of specific agent names
- "test-engineer" instead of specific agent names
- "security-engineer" instead of specific agent names

- [ ] **Step 3: Add zero-agent mode section**

Add a section explaining how the review works without a roster:

```markdown
## Zero-Agent Mode

When no agent roster is configured (`${VOLERE_AGENTS_PATH}` is unset and `.volere/context.yaml` has no `agents` section), the review runs all perspectives sequentially in one Claude Code session:

1. Each review perspective gets its own heading
2. The agent adopts each role in sequence (architecture reviewer → test engineer → security engineer → synthesis lead)
3. Each perspective produces its analysis before the next begins
4. The synthesis runs last, consolidating all perspectives

This is slower but requires no infrastructure beyond a single Claude Code session.
```

- [ ] **Step 4: Replace thul-studio specific examples**

Replace any examples referencing thul-studio URs/TCs with generic examples:

```markdown
(Replace with your project's requirement IDs — e.g., UR-001, UR-042)
```

- [ ] **Step 5: Commit**

```bash
git add plugin/skills/review-requirements/skill.md
git commit -m "Parameterize paths and add zero-agent mode to review skill (Insight 6)

Replaces hardcoded thul paths with env vars, adds sequential
review mode for single-session use without agent roster."
```

---

### Task 15: Productization — Create retrofit guide

**Files:**
- Create: `plugin/templates/project-scaffold/RETROFIT.md`

- [ ] **Step 1: Write the retrofit guide**

```markdown
# Retrofitting Volere to an Existing Project

Apply the Volere Agentic Framework to a project that already has code, tests, and (possibly) informal requirements.

## Prerequisites

- An existing git repository with source code
- Some form of existing requirements (user stories, tickets, acceptance criteria, or just "what it does")
- Existing tests (any framework)

## Step 1: Initialize

```bash
volere init --dal C
```

This creates:
- `docs/requirements/` — where requirement cards will live
- `.volere/profile.yaml` — DAL configuration
- `.volere/boundaries.yaml` — module boundary rules
- Git hooks — secrets, traceability, fit criteria checks

## Step 2: Capture Existing Requirements

Your project already has requirements — they're just not in snow card format. Look for them in:

- **Issue tracker** — tickets, user stories, epics
- **README** — "features" section, usage examples
- **Tests** — test names and assertions often encode requirements
- **CLAUDE.md / docs** — conventions, constraints, acceptance criteria
- **Stakeholder conversations** — "it must do X" statements

For each requirement found, create a card:

```bash
volere new --type functional
# Edit the generated card with the requirement details
```

Start with the most critical 5-10 requirements. You don't need to capture everything at once.

**Tip:** Don't force-fit. If a requirement doesn't feel like a UR, it might be a BUC (business context), PUC (user interaction), or TC (technical constraint).

## Step 3: Trace Existing Code

```bash
volere trace
```

This maps your source files to requirements. On first run, most code will be ORPHANED (no requirement linked). That's expected — it tells you where to focus next.

Priorities:
1. **Critical orphaned code** — important code with no requirement → write the missing requirement
2. **Dead code** — code that serves no requirement and no test → candidate for removal
3. **Partially traced** — code that serves a requirement but isn't fully linked → add traceability

## Step 4: Audit Existing Tests

```bash
volere review  # select "trace review" type
```

Or use the `audit-tests` skill directly. This classifies your existing tests:

| Classification | What it means | Action |
|---------------|---------------|--------|
| **VERIFIES** | Test directly asserts a fit criterion | Keep — these are valuable |
| **SUPPORTS** | Test checks implementation, not the criterion | Consider rewriting to verify the criterion |
| **THEATER** | Test has no connection to any requirement | Remove — it inflates coverage |
| **REDUNDANT** | Test duplicates another's coverage | Remove the weaker one |

Don't be surprised if < 30% of tests VERIFY fit criteria. This is normal for projects without structured requirements.

## Step 5: Fill Gaps

After tracing and auditing, you'll have a clear picture:

```bash
volere coverage
```

This shows:
- Fit criteria without tests (write tests)
- Requirements without code (implement or remove)
- Code without requirements (write requirements or remove code)

Prioritize by DAL level — DAL-A gaps first, DAL-E gaps can wait.

## Step 6: Set DAL Levels

Review each requirement's DAL classification:

```bash
# Use the classify-risk skill or set manually in each card
```

Most requirements in an existing project start at DAL-C (moderate). Escalate:
- Auth, encryption, secrets → DAL-B minimum
- Data migrations, safety-critical → DAL-A
- Cosmetic, docs → DAL-E

## What NOT to Do

- **Don't rewrite all tests at once.** Classify first, then improve incrementally.
- **Don't capture every possible requirement.** Start with 5-10 critical ones. Add more as you work.
- **Don't clean code before tracing.** The mess is evidence — dead code reveals derived requirements, unnecessary tests reveal theater.
- **Don't treat this as a documentation exercise.** The goal is verification, not paperwork.

## Timeline

A typical retrofit takes 2-3 sessions:

1. **Session 1:** Init, capture 5-10 requirements, first trace
2. **Session 2:** Audit tests, classify, fill critical gaps
3. **Session 3:** Set DAL levels, configure hooks, establish workflow

After that, the framework maintains itself through hooks and CI.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/templates/project-scaffold/RETROFIT.md
git commit -m "Add retrofit guide for existing projects (Insight 6)

Step-by-step guide for applying Volere to projects that already
have code, tests, and informal requirements."
```

---

### Task 16: Productization — Clean up regulatory claims in docs

**Files:**
- Modify: `README.md:96-97`
- Modify: `ARCHITECTURE.md` (if it contains specific standard claims)

- [ ] **Step 1: Update README insight 7**

In `README.md`, change insight 7 (line 96-97) from referencing specific standards to:

```markdown
**7. Acceptance is multi-dimensional.**
A single requirement may need fit criteria across user, security, operational, and regulatory dimensions. Agents need to know which dimensions apply. This is where Volere's structured approach beats user stories and BDD. Compliance profiles for specific standards (FCC, RED, IEC) are planned for v1.1.
```

- [ ] **Step 2: Update roadmap**

In `README.md`, update the v1.0 row to remove "Pre-built compliance profiles (FCC, RED, IEC)" and add to a v1.1 row:

```markdown
| v1.0 | Planned | Publish to thul-plugins marketplace as `volere@ulleberg` |
| v1.1 | Planned | Pre-built compliance profiles (FCC Part 15, RED 2014/53/EU, IEC 61508) |
```

- [ ] **Step 3: Check ARCHITECTURE.md for specific claims**

Read and update any specific regulatory standard claims to say "planned for v1.1" rather than implying current support.

- [ ] **Step 4: Commit**

```bash
git add README.md ARCHITECTURE.md
git commit -m "Defer specific regulatory standard claims to v1.1 (Insight 6)

Keep compliance schema and evidence chain (they work generically).
Move FCC/RED/IEC specific profiles to v1.1 roadmap."
```

---

### Task 17: Final — Run all hook tests and validate schemas

**Files:**
- None (verification only)

- [ ] **Step 1: Validate all schemas**

Run:
```bash
python3 -c "import json; json.load(open('plugin/schema/requirement.schema.json')); print('requirement: OK')"
python3 -c "import json; json.load(open('plugin/schema/evidence.schema.json')); print('evidence: OK')"
python3 -c "import json; json.load(open('plugin/schema/profile.schema.json')); print('profile: OK')"
```
Expected: All OK

- [ ] **Step 2: Run hook tests**

Run: `plugin/hooks/test-hooks.sh`
Expected: 16 passed, 0 failed

- [ ] **Step 3: Validate existing requirement cards**

Run:
```bash
plugin/validate.sh plugin/requirements/UR-001.yaml
plugin/validate.sh plugin/requirements/UR-002.yaml
```
Expected: Both pass

- [ ] **Step 4: Update CLAUDE.md and ARCHITECTURE.md**

Update the hook count from "4 hooks" to "6 hooks" (4 original + 2 new), update test count from "12 tests" to "16 tests", and mention the new schema fields in the Key Concepts section.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md ARCHITECTURE.md
git commit -m "Update docs to reflect v0.9 changes: 6 hooks, 16 tests, new schema fields"
```

- [ ] **Step 6: Push**

```bash
git push
```
