# Execution: Phase 5 — cmd/a2a Consolidation

Run this from a Claude Code session in `thul-studio/`.

## Context

Phases 1–4 and 2–3 complete. The codebase has 479 tests, all passing. The `cmd/a2a/` binary duplicates ~1,465 lines of code that already exists in `internal/` packages. This phase eliminates that duplication by making `cmd/a2a/` import from `internal/`.

Key reference: `docs/requirements/reviews/trace-synthesis.md` section 4, Phase 5 (C-36 through C-40).

## Pre-flight

1. All tests pass: `go test ./... -count=1`
2. Working tree is clean
3. Create a branch: `git checkout -b consolidation/cmd-a2a`

## Decision Record

**server.go stays in cmd/a2a/:** The A2A server handler (`cmd/a2a/server.go`, 692 lines) is specific to the standalone A2A binary. It has different routing, different response handling, and different concurrency patterns than `internal/a2a/handler.go`. Do NOT try to merge these — they serve different purposes (standalone server vs Studio-embedded proxy).

**client.go stays in cmd/a2a/:** The A2A client (`cmd/a2a/client.go`, 157 lines) is CLI-specific. `internal/a2a/client.go` serves the Studio proxy. Keep both.

**main.go stays in cmd/a2a/:** CLI entry point, obviously stays.

## Duplication Map

Before starting, verify these duplications are still accurate by reading both files:

| cmd/a2a/ file | Lines | Duplicates | internal/ target |
|---------------|-------|------------|-----------------|
| `tmux.go` | 728 | State detection, tmux ops, response extraction, sanitize, HMAC | `internal/session/state.go`, `internal/session/tmux.go`, `internal/a2a/response.go`, `internal/shared/shell.go` |
| `card.go` | 293 | Card generation, SOUL parsing, skill loading | `internal/a2a/card.go` |
| `discovery.go` | 290 | Peer discovery, registry, refresh | `internal/a2a/discovery.go` |
| `roster.go` | 154 | YAML roster parsing, agent resolution | `internal/roster/roster.go` |

## Prompt

```
Execute cmd/a2a consolidation Phase 5 from docs/requirements/reviews/trace-synthesis.md.

Before you start, read:
- docs/requirements/reviews/trace-synthesis.md (section 4, Phase 5: C-36 through C-40)
- CLAUDE.md (bug-fix protocol, verification protocol)
- This execution doc (decision record, duplication map)

IMPORTANT RULES:
- Run tests BEFORE any changes to establish baseline
- After EACH step, run `go test ./... -count=1` to confirm nothing breaks
- The a2a binary must still work after each step — test with `go build ./cmd/a2a/`
- If a test fails, STOP and investigate
- Commit after each step
- Do NOT touch cmd/a2a/server.go, cmd/a2a/client.go, or cmd/a2a/main.go
  (they stay as-is per the decision record)

APPROACH: For each file, the pattern is:
1. Read both the cmd/a2a/ file and the internal/ equivalent
2. Identify which functions are truly identical vs diverged
3. For identical functions: delete from cmd/a2a/, import from internal/
4. For diverged functions: decide whether to align internal/ first or keep both
5. Update imports in cmd/a2a/ files that reference the changed file
6. Run tests, build binary, commit

Execute these steps in order:

STEP 1: Consolidate roster.go (C-39) — smallest, safest
- Read cmd/a2a/roster.go (154 lines) and internal/roster/roster.go
- Compare types: AgentInfo, RosterDeployment, RosterRole, Roster
- Compare functions: parseRoster, loadRoster, agentsForMachine, enrichAgentsWithSOUL, resolveAgent
- Replace cmd/a2a/roster.go with imports from internal/roster/
- If type names differ, add type aliases in cmd/a2a/
- Update all references in cmd/a2a/*.go that use roster types
- Run: go test ./... -count=1 && go build ./cmd/a2a/
- Commit: "Consolidate cmd/a2a/roster.go → internal/roster/ (C-39)"

STEP 2: Consolidate card.go (C-37)
- Read cmd/a2a/card.go (293 lines) and internal/a2a/card.go
- Compare types: AgentCard, Config, AgentSkill, etc.
- Compare functions: generateCard, parseSoulName, parseSoulDescription, loadSkills, marshalCard
- Replace with imports from internal/a2a/
- Keep cmd/a2a/Config if it has fields not in internal (like agent-specific config)
- Run: go test ./... -count=1 && go build ./cmd/a2a/
- Commit: "Consolidate cmd/a2a/card.go → internal/a2a/ (C-37)"

STEP 3: Consolidate discovery.go (C-38)
- Read cmd/a2a/discovery.go (290 lines) and internal/a2a/discovery.go
- Compare types: Discovery, PeerInfo, Registry, RegistryEntry
- Compare functions: NewDiscovery, Start, Peers, FindByName, RegisterPeer
- Replace with imports from internal/a2a/
- Run: go test ./... -count=1 && go build ./cmd/a2a/
- Commit: "Consolidate cmd/a2a/discovery.go → internal/a2a/ (C-38)"

STEP 4: Consolidate tmux.go (C-36) — largest, most complex
- Read cmd/a2a/tmux.go (728 lines) and the internal/ equivalents:
  - internal/session/state.go (detectState, StateInfo)
  - internal/session/tmux.go (capturePane, sendKeys, waitForIdle)
  - internal/a2a/response.go (extractLastResponse, extractConversationalResponse)
  - internal/shared/shell.go (HmacSHA256, SanitizeFrom, IsBoxDrawingLine)
- Map each function in cmd/a2a/tmux.go to its internal/ equivalent
- Functions likely identical: detectState, capturePane, sendKeys, sanitizeFrom, isBoxDrawingLine
- Functions that may have diverged: waitForIdle (cmd/a2a/ has adaptive variant),
  sendAndWaitForResponse, writeVerifiedMessage, extractLastResponse
- For diverged functions: if cmd/a2a/ has features internal/ lacks, move
  the better version to internal/ first, then import
- For cmd/a2a/-specific functions (sendAndWaitForResponse, writeVerifiedMessage):
  keep in a smaller cmd/a2a/tmux.go that imports shared logic
- Run: go test ./... -count=1 && go build ./cmd/a2a/
- Commit: "Consolidate cmd/a2a/tmux.go → internal/ packages (C-36)"

STEP 5: Delete redundant tests (C-40)
- Only after C-36 through C-39 are complete
- Delete cmd/a2a/card_test.go (R-01, 187 lines)
- Delete cmd/a2a/tmux_test.go (R-02/R-03, 166 lines)
- Delete cmd/a2a/roster_test.go (R-04, 290 lines)
- Do NOT delete cmd/a2a/server_test.go or cmd/a2a/client_test.go
  (these test cmd/a2a/-specific code that stays)
- Run: go test ./... -count=1
- Commit: "Remove redundant cmd/a2a/ tests — now covered by internal/ (C-40)"

STEP 6: Final verification
- Run full test suite: go test ./... -count=1
- Build binary: go build ./cmd/a2a/
- Test binary manually: ./a2a card show (should print agent card JSON)
- Run: git diff --stat consolidation/cmd-a2a main
- Update docs/regression-baseline.md with new test counts

After all steps, report:
- Lines of code removed from cmd/a2a/
- Tests removed (redundant) vs added (if any new ones needed)
- Any divergences found that need follow-up
- Functions that were moved to internal/ (enriching the shared packages)
```

## Post-Phase-5

After Phase 5 is complete:

1. **Merge to main**, push
2. All 5 cleanup phases are done — the codebase is consolidated
3. Next priorities from volere-requirement:
   - Write a Phase 5 execution doc for the Volere Agentic Framework itself (v0.1 YAML schema)
   - Continue Phase 3 remaining tests (C-18 crash recovery, C-19 reconciliation, C-21 SIGTERM)
   - Begin Volere framework development (separate repo/branch)
