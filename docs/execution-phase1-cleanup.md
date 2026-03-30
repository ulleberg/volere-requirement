# Execution: Phase 1 — Safe Removals

Run this from a Claude Code session in `thul-studio/`.

## Pre-flight

1. All tests pass: `go test ./... -count=1 && npx playwright test --config playwright.go.config.js`
2. Working tree is clean: `git status` shows no uncommitted changes
3. Create a branch: `git checkout -b cleanup/phase-1-dead-code`

## Decision Record

**CORS on agent cards:** Keep `Access-Control-Allow-Origin: *` on `/.well-known/agent-card.json` (A2A spec requires discoverability). Restrict CORS on all other API routes to Tailscale origins. Amend UR-27 fit criteria to exclude agent card endpoint.

## Prompt

```
Execute cleanup Phase 1 from docs/requirements/reviews/trace-synthesis.md.
This is safe removals only — zero behavioral change to the running system.

Before you start, read:
- docs/requirements/reviews/trace-synthesis.md (the cleanup plan — section 4, Phase 1)
- docs/requirements/user.md (requirements — to verify nothing traced is removed)
- CLAUDE.md (bug-fix protocol, verification protocol)

IMPORTANT RULES:
- Run tests BEFORE any changes to establish baseline
- After EACH removal step, run tests to confirm nothing breaks
- If a test fails, STOP and investigate — do not continue
- Commit after each step (not one big commit at the end)
- Do NOT remove anything that traces to a UR or TC

Execute these steps in order:

STEP 1: Delete server.js (C-01)
- Delete server.js (3018 lines, legacy Node.js server)
- Run: go test ./... -count=1
- Run: npx playwright test --config playwright.go.config.js
- Commit: "Remove legacy Node.js server (server.js)

  Fully replaced by Go binary. 3018 lines of dead code.
  No UR references server.js — all requirements served by Go packages."

STEP 2: Delete web/ directory (C-02)
- Check if web/grid/app.jsx has unique content vs grid/
  - If unique JSX source exists, copy it to grid/app.jsx first
  - If it's a duplicate, just delete
- Delete web/ directory
- Run tests
- Commit: "Remove web/ directory — duplicate of landing/, grid/, chat/

  Pre-restructure copy. No unique content after JSX source check."

STEP 3: Delete cmd/a2a/server.go.bak (C-03)
- Delete cmd/a2a/server.go.bak
- Commit: "Remove server.go.bak backup file"

STEP 4: Delete dead Node.js test suites (C-05)
- Delete test/api.test.js (96 tests — duplicated by Go integration tests)
- Delete test/conference.test.js (duplicated by Go conference tests)
- Delete test/roster.test.js (duplicated by Go roster tests)
- From test/logic.test.js, remove these test sections:
  - detectSessionState tests (17 tests — Go is authoritative)
  - extractLastResponse/extractConversationalResponse tests (19 tests)
  - resolveAgentSouls tests (6 tests)
  - wsParseFrame/wsSendFrame tests (10 tests — dead WS framing)
  - diffOutput tests (6 tests — abandoned approach)
- Do NOT remove from test/logic.test.js:
  - checkProjectHealth tests (19 tests — verify UR-20 fit criteria, keep until Go equivalent)
  - validateTeamRequest tests (5 tests — verify UR-26 fit criteria, keep until Go equivalent)
  - buildA2aMessagePayload tests that verify UR-15 "from" field (keep until Go equivalent)
- Run: node --test test/logic.test.js (confirm remaining tests pass)
- Run: go test ./... -count=1 (confirm Go tests unaffected)
- Commit: "Remove redundant Node.js test suites

  Removed 154 tests duplicated by Go equivalents:
  - test/api.test.js (96) — covered by internal/api/*_test.go
  - test/conference.test.js — covered by internal/conference/conference_test.go
  - test/roster.test.js — covered by internal/roster/roster_test.go
  - logic.test.js: state detection (17), response extraction (19),
    roster resolution (6), WS framing (10), diffOutput (6)

  Kept: checkProjectHealth (19), validateTeamRequest (5),
  buildA2aMessagePayload UR-15 tests — no Go equivalent yet."

STEP 5: Delete dead shared.js functions (C-04)
- From shared.js, remove these functions:
  - wsParseFrame()
  - wsSendFrame()
  - diffOutput()
  - shouldResurrectClaude()
  - buildScaffoldPrompt()
  - parseRoster()
  - resolveAgentSouls()
  - buildTeamPrompt()
  - buildA2aMessagePayload()
- Do NOT remove:
  - checkProjectHealth() (still tested, verifies UR-20)
  - validateTeamRequest() (still tested, verifies UR-26)
  - detectSessionState() (used by remaining logic tests? check first)
  - extractLastResponse/extractConversationalResponse (check if remaining tests use them)
  - Any function used by browser surfaces (landing/, grid/, chat/)
- Before removing each function, grep all browser surfaces to confirm no caller
- Run: node --test test/logic.test.js
- Commit: "Remove 9 dead shared.js functions

  Functions only called by deleted server.js or deleted tests.
  Verified no browser surface references any removed function."

STEP 6: Delete dead chat code (C-06)
- From chat/agents.js, remove _sendA2AMessage() function
  (HTTP fallback removed — WS-only agent communication)
- From chat/index.html, remove .session-btn CSS class (unreferenced)
- Run: npx playwright test --config playwright.go.config.js
- Commit: "Remove dead chat code — unused A2A HTTP fallback and CSS"

STEP 7: Delete theater tests from Go (C-07)
- Delete these tests (theater — test implementation details, no FC):
  - TestDefaults (internal/config/config_test.go) — default values, no FC
  - TestInferTags (internal/a2a/card_test.go) — tag inference, implementation detail
  - TestMarshalCard (internal/a2a/card_test.go) — JSON serialization, redundant with TestGenerateCard
  - TestGenerateConfID (internal/conference/conference_test.go) — cosmetic ID format
  - TestClientGet/Post/GetText/Delete (cmd/studio/main_test.go) — HTTP client internals
  - TestCmdAttachNestedTmuxDetection + NoNestedTmux (cmd/studio/main_test.go) — no FC
  - TestGenerateSessionName + Uniqueness (cmd/studio/main_test.go) — no FC
- Do NOT delete tests in cmd/a2a/ — those are redundant but only safe to remove
  after Phase 5 refactor
- Run: go test ./... -count=1
- Commit: "Remove theater tests — implementation details without fit criteria

  15 tests removed. Each tested internal mechanics (default values,
  JSON marshaling, ID format, HTTP client, name generation) rather
  than verifying a user requirement or technical constraint."

STEP 8: Final verification
- Run full test suite: go test ./... -count=1
- Run: node --test test/logic.test.js
- Run: npx playwright test --config playwright.go.config.js
- Run: git diff --stat cleanup/phase-1-dead-code main (show total impact)
- Update docs/regression-baseline.md with new test counts

STEP 9: Amend UR-27
- In docs/requirements/user.md, update UR-27 fit criteria:
  Change: "CORS Access-Control-Allow-Origin is restricted to Tailscale machine hostnames (no wildcard)."
  To: "CORS Access-Control-Allow-Origin is restricted to Tailscale machine hostnames on all API routes. Exception: /.well-known/agent-card.json uses CORS * per A2A protocol spec (agent cards must be discoverable)."
- Commit: "Amend UR-27: CORS * permitted on agent card endpoint per A2A spec"

After all steps, report:
- Lines of code removed
- Tests removed
- Tests remaining
- Any surprises or issues found
```

## Post-Phase-1

After Phase 1 is complete and merged:

1. **Phase 4 security fixes** (CORS restriction, CSP, input validation) — P0 priority
2. **Phase 3 critical tests** (TC-05 idle debounce, UR-27 CORS, UR-21 HMAC) — DAL-A gaps
3. **Phase 2 test rewrites + Phase 5 cmd/a2a consolidation** — can run in parallel

These can be separate prompts or agent team work. Phase 1 clears the noise first.
