# Execution: Phase 4 — Security Fixes (P0)

Run this from a Claude Code session in `thul-studio/`.

## Context

Phase 1 complete (12,814 lines removed). The codebase is clean. Now fix the P0 security items identified in the reviews.

Key reference: `docs/requirements/reviews/trace-synthesis.md` section 4, Phase 4 (C-27 through C-35).

## Pre-flight

1. All tests pass: `go test ./... -count=1`
2. Working tree is clean
3. Create a branch: `git checkout -b security/p0-hardening`

## Prompt

```
Execute security hardening Phase 4 from docs/requirements/reviews/trace-synthesis.md.

Before you start, read:
- docs/requirements/reviews/trace-synthesis.md (cleanup plan, Phase 4)
- docs/requirements/user.md (UR-27, UR-28, UR-29, UR-30, UR-31)
- docs/requirements/technical-constraints.md (TC-04)
- CLAUDE.md (bug-fix protocol — write failing test first, then fix)

IMPORTANT: Follow the bug-fix protocol for each change:
1. Write a failing test that verifies the fit criterion
2. Run it — confirm it fails
3. Implement the fix
4. Run it — confirm it passes
5. Commit test + fix together

This ensures we don't repeat the "light acceptance testing" problem from Phase 1.

Execute these items in priority order:

STEP 1: CORS restriction (C-28) — UR-27, P0
- Write test: request from non-Tailscale origin gets no CORS headers on API routes
- Write test: request to /.well-known/agent-card.json gets CORS * (A2A exception)
- Write test: request from Tailscale origin gets proper CORS headers
- Implement: add CORS middleware that checks Origin against configured Tailscale hostnames
- The Tailscale hostnames should come from config (machine names in peers list)
- Keep CORS * on /.well-known/agent-card.json only
- Run all tests
- Commit: "Restrict CORS to Tailscale origins (UR-27)

  API routes only accept requests from configured Tailscale hostnames.
  Agent card endpoint keeps CORS * per A2A protocol spec.
  Closes the T-01 attack chain from security review."

STEP 2: CSP headers (C-29) — UR-27, P0
- Write test: HTML responses include Content-Security-Policy header
- Implement: add CSP middleware for HTML responses
  - default-src 'self'
  - script-src 'self' 'unsafe-inline' (needed for inline scripts in grid/chat)
  - style-src 'self' 'unsafe-inline' (needed for inline styles)
  - connect-src 'self' wss: (WebSocket connections)
  - img-src 'self' data: (data URIs for icons)
  - frame-src 'self' (terminal iframes)
- Run all tests
- Commit: "Add Content-Security-Policy headers (UR-27)"

STEP 3: Input validation (C-30, C-31) — UR-28, P0
- Write test: session name with path traversal chars returns 400
- Write test: session name > 64 chars returns 400
- Write test: session name with valid chars (alphanumeric, hyphens) returns 200
- Write test: broadcast content > 1MB returns 413
- Write test: env vars in session create validated against allowlist
- Implement input validation middleware/helpers:
  - Session name: alphanumeric + hyphens, max 64 chars
  - Folder path: reject traversal sequences (../, ..\)
  - Broadcast content: max 1MB
  - Env vars: allowlist of permitted variable names
- Run all tests
- Commit: "Add input validation at API boundaries (UR-28)

  Session names validated (alphanumeric/hyphens, max 64).
  Broadcast content capped at 1MB.
  Env vars validated against allowlist.
  Returns 400 with descriptive error, never 500."

STEP 4: Cache-Control on token-injected pages (C-17) — TC-04
- Write test: HTML pages with injected token have Cache-Control: no-store
- Implement: add Cache-Control: no-store header in injectToken middleware
- Run all tests
- Commit: "Add Cache-Control: no-store on token-injected pages (TC-04)"

STEP 5: Wire health data into /health (C-27) — UR-30
- Write test: /health response includes session_count, port_capacity, memory_usage
- Implement: add session count from Manager.List(), port metrics from
  Manager.PortMetrics(), and runtime memory stats to /health response
- Write test: /crash-logs requires auth token (was public, security review T-05)
- Implement: add /crash-logs to authenticated routes
- Run all tests
- Commit: "Wire session/port/memory data into /health endpoint (UR-30)

  /health now reports session_count, port_capacity (used/total),
  memory_usage_mb, in addition to existing checks.
  /crash-logs now requires Bearer token authentication."

STEP 6: File lock for sessions.json (C-32) — UR-31
- Write test: concurrent writes to sessions.json don't corrupt data
- Write test: backup file created on write (sessions.json.bak)
- Implement: file lock (flock) around sessions.json writes
- Implement: backup-on-write (copy current file to .bak before overwriting)
- Run all tests
- Commit: "Add file lock and backup-on-write for sessions.json (UR-31)

  Prevents concurrent write corruption. Creates sessions.json.bak
  before each write for recovery."

STEP 7: Final verification
- Run full test suite: go test ./... -count=1
- Run: npx playwright test --config playwright.go.config.js
- Count new tests added vs baseline
- Verify all P0 items from UR-27 and UR-28 are covered

After all steps, report:
- Tests added (count and what they cover)
- Fit criteria now verified (which were previously untested)
- Any issues or decisions needed
```

## Post-Phase-4

After Phase 4 is complete:

1. **Merge to main**, run Playwright, deploy
2. **Phase 3 priority tests** — TC-05 (idle debounce), UR-21 (HMAC verification), UR-22 (crash recovery)
3. **Phase 2 + Phase 5** can run in parallel as agent teams
