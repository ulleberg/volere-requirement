# Design: Process Artifact Cleanup + Doc Tracking

**Date:** 2026-04-02
**Cards:** UR-022, UR-023, UR-024

## Summary

Three additions to the Volere framework:
1. `volere clean` CLI command — detects and removes process artifacts from discovery/execution plugins
2. Doc tracking nudge — skill instruction to offer profile.yaml tracking for new maintained docs
3. Requirement-before-brainstorm gate — skill instruction requiring a card before brainstorming

## 1. `volere clean` CLI command (UR-022)

### Artifact patterns

Built-in pattern list with source attribution:

```
# discovery-to-delivery
docs/problem.md                    (discovery-to-delivery)
docs/brief.md                      (discovery-to-delivery)
docs/options/                      (discovery-to-delivery)
docs/spec.md                       (discovery-to-delivery)
docs/decisions.md                  (discovery-to-delivery)

# superpowers
docs/superpowers/                  (superpowers)
.superpowers/                      (superpowers)

# execution artifacts
docs/execution-*.md                (execution)
docs/team-prompt-*.md              (execution)
```

### Behavior

**Advisory mode (default):**
- List each found artifact with age (days) and source attribution
- Report total count
- Print: `Run: volere clean --rm`
- Print: `git history preserves all removed files`

**Removal mode (`--rm`):**
- For each artifact: check if uncommitted in git (dirty). If dirty, skip with warning.
- Remove clean artifacts (files and directories)
- Report count removed and count skipped

**Clean state:**
- If no artifacts found: `No process artifacts found.`

### Implementation

Add `cmd_clean()` to `plugin/cli/volere` (~50 lines). Register as `clean` in the case statement. Add to help text.

### Tests (5)

1. `volere clean` lists planted process artifacts with age and source
2. `volere clean` reports clean state when no artifacts present
3. `volere clean` skips files not matching patterns (no false positives)
4. `volere clean --rm` removes artifacts and reports count
5. `volere clean --rm` skips uncommitted files with warning

### Future: plugin-declared artifacts (Approach B)

When plugins adopt cache directories with manifests (e.g., `.discovery/manifest.yaml`), `volere clean` reads manifests first and falls back to pattern matching. This avoids maintaining a central pattern list as the plugin ecosystem grows. Tracked in `docs/insights/d2d-artifact-caching.md`.

## 2. Doc tracking nudge (UR-023)

### Where

Add instruction to `plugin/skills/using-volere/SKILL.md`.

### Instruction

When the agent creates a document intended to be maintained (not a process artifact), offer to add it to `.volere/profile.yaml` docs tracking. Examples of maintained docs: presentations, API references, guides, runbooks. Examples of non-maintained docs (don't nudge): specs, plans, briefs, options, execution prompts.

### Test (1)

Structural test: grep the skill file for the doc tracking instruction (pattern: `profile.yaml` AND `docs`).

## 3. Requirement-before-brainstorm gate (UR-024)

### Where

Add instruction to `plugin/skills/using-volere/SKILL.md`.

### Instruction

Before invoking brainstorm, identify which requirement card (UR/TC) the work serves. If no card exists, write the requirement first using `/write-requirement`. This ensures every piece of work has fit criteria and acceptance tests before implementation begins.

### Future hardening

If the soft instruction proves insufficient: PreToolUse hook on Skill tool invocation that checks whether a requirement ID has been referenced in the conversation before brainstorm is invoked.

### Test (1)

Structural test: grep the skill file for the brainstorm gate instruction (pattern: `write-requirement` AND `brainstorm`).

## Files changed

| File | Change |
|------|--------|
| `plugin/cli/volere` | Add `cmd_clean()`, register in case statement, add to help |
| `plugin/skills/using-volere/SKILL.md` | Add doc tracking nudge + brainstorm gate instructions |
| `plugin/hooks/test-hooks.sh` | Add 7 tests (5 clean + 1 doc nudge + 1 brainstorm gate) |
| `plugin/requirements/UR-022.yaml` | Already created |
| `plugin/requirements/UR-023.yaml` | Already created |
| `plugin/requirements/UR-024.yaml` | Already created |
