# Artifact Cleanup + Doc Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `volere clean` CLI command, doc tracking nudge, and requirement-before-brainstorm gate to the Volere framework.

**Architecture:** Three changes: a new CLI command in `plugin/cli/volere`, a new skill file `plugin/skills/using-volere/SKILL.md` (previously only in the published plugin), and tests in `plugin/hooks/test-hooks.sh`. The sync workflow needs updating to stop excluding `using-volere/`.

**Tech Stack:** Bash (CLI), Markdown (skill), shell tests

---

### Task 1: Create `using-volere` skill in source repo

The `using-volere` skill currently only exists in the published plugin (excluded from sync). We need it in the source repo so we can add the new instructions and have changes tracked by git + CI.

**Files:**
- Create: `plugin/skills/using-volere/SKILL.md`

- [ ] **Step 1: Create the skill file with existing content plus new instructions**

```markdown
---
name: using-volere
description: Use when starting any conversation — establishes Volere Agentic Framework context, detects project state, and guides to the right skill
---

# Volere Agentic Framework

Structured requirements engineering and V-Model verification for agentic software development.

## Project State Detection

Check the project to determine what's needed:

| Condition | Action |
|-----------|--------|
| No `.volere/` or `docs/requirements/` | Not set up — suggest `volere init` or scaffold manually |
| `docs/requirements/` empty | Write requirements first — use `write-requirement` skill |
| Requirements exist, no `reviews/` | Run a review — use `review-requirements` skill |
| Reviews exist, code exists | Trace codebase — use `trace-codebase` skill |
| Tests exist | Audit test quality — use `audit-tests` skill |
| Making a change | Classify risk — use `classify-risk` skill |

## Core Principles

1. **Requirements before code.** Understand what to build before building it.
2. **Every fit criterion must be testable.** No vague words (should, appropriate, reasonable).
3. **Agents test everything autonomously.** "Manually verified" is a bug in the process.
4. **Soft + hard at every level.** CLAUDE.md instructs, hooks and CI enforce.
5. **Graduated rigour (DAL A-E).** Scale verification to risk.

## Requirement Gate

Before invoking `/brainstorm` or any implementation skill, identify which requirement card (UR/TC) the work serves. If no card exists, write the requirement first using `/write-requirement`. This ensures every piece of work has fit criteria and acceptance tests before implementation begins.

Without a card there are no fit criteria. Without fit criteria there are no acceptance tests. Without acceptance tests the work is untraceable.

## Doc Tracking

When creating a document intended to be maintained — presentations, API references, guides, runbooks — offer to add it to `.volere/profile.yaml` under the `docs:` field. This enables staleness detection by the SessionStart hook and `volere check-docs`.

Do NOT offer tracking for process artifacts (specs, plans, briefs, options, execution prompts). These are snapshots in time, not maintained documents.

## Available Skills

| Skill | When to use |
|-------|-------------|
| `write-requirement` | Writing or updating a requirement card |
| `extract-requirements` | Scanning an existing codebase to draft cards |
| `simplify-requirements` | Reducing card count by merging and deleting |
| `review-requirements` | Reviewing requirements with an agent team |
| `trace-codebase` | Mapping code to requirements |
| `audit-tests` | Finding test theater and coverage gaps |
| `classify-risk` | Assigning DAL level to a change |
| `glossary` | Abbreviations, DAL levels, terminology reference |

## Quick Reference

` ` `
BUC (§7) — Why do these requirements exist?
PUC (§8) — What does the user do?
UR (§9-17) — What must the system do?
TC — What must the implementation guarantee?
DAL A-E — How much verification is needed?
` ` `
```

- [ ] **Step 2: Verify file exists**

Run: `ls -la plugin/skills/using-volere/SKILL.md`
Expected: file exists

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/using-volere/SKILL.md
git commit -m "feat: add using-volere skill to source repo (UR-023, UR-024)"
```

---

### Task 2: Update sync workflow to include `using-volere`

Now that the skill exists in source, remove the exclude from the rsync command.

**Files:**
- Modify: `.github/workflows/sync-plugin.yml:36`

- [ ] **Step 1: Remove the `--exclude='using-volere/'` from rsync**

Change line 36 from:
```yaml
          rsync -a --delete --exclude='using-volere/' source/plugin/skills/ target/skills/
```
to:
```yaml
          rsync -a --delete source/plugin/skills/ target/skills/
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/sync-plugin.yml
git commit -m "chore: sync using-volere skill from source (UR-023, UR-024)"
```

---

### Task 3: Add `volere clean` command

**Files:**
- Modify: `plugin/cli/volere` (add `cmd_clean()` and register in case statement + help)

- [ ] **Step 1: Write the failing test for `volere clean` advisory mode**

Add to `plugin/hooks/test-hooks.sh` before the cleanup section (before line 766 `rm -rf docs/requirements .volere src`). These tests use the existing temp repo setup that has `docs/requirements`, `.volere`, and `src` directories.

Plant process artifacts first, then test detection:

```bash
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `plugin/hooks/test-hooks.sh 2>&1 | tail -10`
Expected: 4 new tests FAIL (volere clean command doesn't exist yet)

- [ ] **Step 3: Implement `cmd_clean()` in the CLI**

Add before the `# Main` section (before line 718) in `plugin/cli/volere`:

```bash
# ============================================================
# volere clean
# ============================================================
cmd_clean() {
  local do_rm=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --rm) do_rm=1; shift ;;
      *) shift ;;
    esac
  done

  echo -e "${CYAN}Process Artifacts${NC} — $(basename "$PROJECT_ROOT")"
  echo ""

  # Known process artifact patterns
  local found=0
  local removed=0
  local skipped=0
  local artifacts=""

  # Check each pattern
  check_artifact() {
    local path="$1" source="$2"
    local full="$PROJECT_ROOT/$path"

    # Handle glob patterns
    local matches
    matches=$(find "$PROJECT_ROOT" -path "$full" 2>/dev/null || true)
    [ -z "$matches" ] && return

    while IFS= read -r match; do
      [ -e "$match" ] || continue
      local rel="${match#$PROJECT_ROOT/}"
      found=$((found + 1))

      if [ "$do_rm" -eq 1 ]; then
        # Check if uncommitted (dirty in git)
        if ! git -C "$PROJECT_ROOT" diff --quiet -- "$rel" 2>/dev/null || \
           ! git -C "$PROJECT_ROOT" diff --cached --quiet -- "$rel" 2>/dev/null || \
           git -C "$PROJECT_ROOT" ls-files --others --exclude-standard -- "$rel" 2>/dev/null | grep -q .; then
          echo -e "  ${YELLOW}⚠${NC} $rel — skipped (uncommitted changes)"
          skipped=$((skipped + 1))
        else
          rm -rf "$match"
          echo -e "  ${GREEN}✓${NC} $rel — removed"
          removed=$((removed + 1))
        fi
      else
        # Advisory mode — show age
        local age="unknown"
        if [ -f "$match" ]; then
          local mtime=$(stat -f %m "$match" 2>/dev/null || stat -c %Y "$match" 2>/dev/null || echo 0)
          local now=$(date +%s)
          if [ "$mtime" -gt 0 ]; then
            age="$(( (now - mtime) / 86400 )) days old"
          fi
        elif [ -d "$match" ]; then
          age="directory"
        fi
        printf "  %-40s %-16s (%s)\n" "$rel" "$age" "$source"
      fi
    done <<< "$matches"
  }

  # discovery-to-delivery
  check_artifact "docs/problem.md" "discovery-to-delivery"
  check_artifact "docs/brief.md" "discovery-to-delivery"
  check_artifact "docs/options" "discovery-to-delivery"
  check_artifact "docs/spec.md" "discovery-to-delivery"
  check_artifact "docs/decisions.md" "discovery-to-delivery"

  # superpowers
  check_artifact "docs/superpowers" "superpowers"
  check_artifact ".superpowers" "superpowers"

  # execution artifacts (glob)
  for f in "$PROJECT_ROOT"/docs/execution-*.md; do
    [ -f "$f" ] || continue
    local rel="${f#$PROJECT_ROOT/}"
    found=$((found + 1))
    if [ "$do_rm" -eq 1 ]; then
      if ! git -C "$PROJECT_ROOT" diff --quiet -- "$rel" 2>/dev/null || \
         ! git -C "$PROJECT_ROOT" diff --cached --quiet -- "$rel" 2>/dev/null || \
         git -C "$PROJECT_ROOT" ls-files --others --exclude-standard -- "$rel" 2>/dev/null | grep -q .; then
        echo -e "  ${YELLOW}⚠${NC} $rel — skipped (uncommitted changes)"
        skipped=$((skipped + 1))
      else
        rm -f "$f"
        echo -e "  ${GREEN}✓${NC} $rel — removed"
        removed=$((removed + 1))
      fi
    else
      local mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
      local now=$(date +%s)
      local age="$(( (now - mtime) / 86400 )) days old"
      printf "  %-40s %-16s (%s)\n" "$rel" "$age" "execution"
    fi
  done

  for f in "$PROJECT_ROOT"/docs/team-prompt-*.md; do
    [ -f "$f" ] || continue
    local rel="${f#$PROJECT_ROOT/}"
    found=$((found + 1))
    if [ "$do_rm" -eq 1 ]; then
      if ! git -C "$PROJECT_ROOT" diff --quiet -- "$rel" 2>/dev/null || \
         ! git -C "$PROJECT_ROOT" diff --cached --quiet -- "$rel" 2>/dev/null || \
         git -C "$PROJECT_ROOT" ls-files --others --exclude-standard -- "$rel" 2>/dev/null | grep -q .; then
        echo -e "  ${YELLOW}⚠${NC} $rel — skipped (uncommitted changes)"
        skipped=$((skipped + 1))
      else
        rm -f "$f"
        echo -e "  ${GREEN}✓${NC} $rel — removed"
        removed=$((removed + 1))
      fi
    else
      local mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
      local now=$(date +%s)
      local age="$(( (now - mtime) / 86400 )) days old"
      printf "  %-40s %-16s (%s)\n" "$rel" "$age" "execution"
    fi
  done

  echo ""
  if [ "$found" -eq 0 ]; then
    echo "  No process artifacts found."
  elif [ "$do_rm" -eq 1 ]; then
    echo "  $removed removed, $skipped skipped"
  else
    echo "  $found process artifacts found (git history preserves all removed files)"
    echo "  Run: volere clean --rm"
  fi
}
```

- [ ] **Step 4: Register `clean` in the case statement**

In the `Main` section, add before the `help` case:

```bash
  clean)    shift; cmd_clean "$@" ;;
```

- [ ] **Step 5: Add `clean` to help text**

Add after the `check-docs` line in the help section:

```bash
    echo "  clean [--rm]                Remove process artifacts from docs/"
```

- [ ] **Step 6: Update the CLI header comment**

Add `clean` to the commands list at the top of the file.

- [ ] **Step 7: Run tests to verify they pass**

Run: `plugin/hooks/test-hooks.sh 2>&1 | tail -10`
Expected: All tests pass including the 4 new clean tests

- [ ] **Step 8: Commit**

```bash
git add plugin/cli/volere plugin/hooks/test-hooks.sh
git commit -m "feat: implement volere clean command (UR-022)"
```

---

### Task 4: Add structural tests for skill instructions

**Files:**
- Modify: `plugin/hooks/test-hooks.sh`

- [ ] **Step 1: Write the failing tests**

Add after the clean tests block, before the cleanup section:

```bash
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
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `plugin/hooks/test-hooks.sh 2>&1 | tail -10`
Expected: All tests pass (skill was already created in Task 1 with both instructions)

- [ ] **Step 3: Commit**

```bash
git add plugin/hooks/test-hooks.sh
git commit -m "test: add structural tests for skill instructions (UR-023, UR-024)"
```

---

### Task 5: Update docs and card statuses

**Files:**
- Modify: `plugin/requirements/UR-022.yaml` (status: proposed → implemented)
- Modify: `plugin/requirements/UR-023.yaml` (status: proposed → implemented)
- Modify: `plugin/requirements/UR-024.yaml` (status: proposed → implemented)
- Modify: `CLAUDE.md` (update CLI command count, card count)
- Modify: `README.md` (update CLI command count, card count)
- Modify: `ARCHITECTURE.md` (update card count)

- [ ] **Step 1: Update card statuses**

In each of UR-022.yaml, UR-023.yaml, UR-024.yaml, change:
```yaml
status: proposed
```
to:
```yaml
status: implemented
```

- [ ] **Step 2: Update doc counts**

Counts after this work: 39 cards (5 BUCs, 19 URs, 15 TCs), 9 skills, 8 CLI commands (added `clean`). Test count will be determined after tests pass.

Update in CLAUDE.md, README.md, ARCHITECTURE.md:
- Card count: 36 → 39
- UR count: 16 → 19
- CLI commands: 7 → 8 (add `clean`)
- Skills: 8 → 9 (add `using-volere`)
- Test count and coverage: update after final test run

- [ ] **Step 3: Run full test suite to get final count**

Run: `plugin/hooks/test-hooks.sh 2>&1 | tail -5`
Expected: All pass, note the total count for docs

- [ ] **Step 4: Commit**

```bash
git add plugin/requirements/UR-022.yaml plugin/requirements/UR-023.yaml plugin/requirements/UR-024.yaml CLAUDE.md README.md ARCHITECTURE.md
git commit -m "docs: update card statuses and doc counts (UR-022, UR-023, UR-024)"
```
