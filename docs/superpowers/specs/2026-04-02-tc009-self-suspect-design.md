# TC-009 Operational: Self-Suspect on Fit Criteria Change

**Date:** 2026-04-02
**Requirement:** TC-009 operational dimension
**DAL:** B

## Problem

`suspect auto` marks *dependents* of changed cards but never marks the *changed card itself* as suspect when its `fit_criteria` block changes. Acceptance tests tied to those fit criteria may no longer match — the card needs re-verification.

## Design

In `cmd_auto()` (suspect.sh), after identifying each changed requirement file, use `git diff` with content (not `--name-only`) to check if the diff touches `fit_criteria`. If it does, mark the card itself as suspect with reason "fit criteria changed — re-verify acceptance tests".

### Changes

1. **`plugin/cli/suspect.sh` — `cmd_auto()`**: After extracting the card `$id`, run `git diff HEAD~$depth..HEAD -- "$PROJECT_ROOT/$f"` and grep for `fit_criteria`. If matched, call `cmd_mark "$id"` with the specified reason.

2. **`plugin/hooks/test-hooks.sh`**: Add a test that modifies UR-050's fit_criteria block, commits, runs `suspect auto`, and asserts UR-050 itself appears in suspects.yaml with dimension tag `TC-009:operational`.

### Scope

~5 lines of shell in suspect.sh, ~15 lines of test. No schema changes, no new files.
