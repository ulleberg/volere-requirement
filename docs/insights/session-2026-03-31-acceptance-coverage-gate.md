# Session Insights: Acceptance Coverage Gate

**Date:** 2026-03-31
**Source:** Full-day session — acceptance test gap analysis, living coverage gate, 4 features implemented, cross-machine validation
**Project:** thul-studio (55 requirements, 51 implemented, 538 tests, 92.7% coverage)

---

## Insight 1: Agent reviews produce false findings about implementation state

Three independent agent reviewers (code tracer, test tracer, synthesis agent) reported that UR-35 (session reconciliation / orphan adoption) was "not implemented — the helper function exists but is never called during startup." This was stated as the P1 most dangerous gap.

It was wrong. `AdoptOrphans()` has been wired into `cmd/studio/server.go:104-128` since the Go rewrite. The agents found the function definition but didn't trace the call site. The acceptance coverage gate — which runs a live kill/restart cycle via SSH — proved it works: 4 sessions recovered on M4 after SIGTERM.

**Framework action:** Agent-generated review documents are hypotheses, not evidence. The Volere Agentic Framework should distinguish between:
- **Review findings** (agent read code and made a claim) — requires verification
- **Acceptance evidence** (test ran against live infrastructure and produced output) — is verification

A claim like "function X is never called" must be backed by `grep -rn "FunctionX(" --include="*.go"` output, not by an agent's assertion. The acceptance gate methodology (tag tests with requirement IDs, run against live infrastructure, generate matrix) provides evidence that reviews cannot.

---

## Insight 2: "100% of testable requirements" is the right coverage target

55 requirements. 4 have zero implementation (proposed). 2 have no code (not_implemented). Demanding 100% coverage means either writing tests for unbuilt features (waste) or building features to satisfy a metric (wrong driver).

The correct framing: **100% of implemented requirements have acceptance-level evidence.** The remaining gaps go in a risk register with explicit accept/defer decisions and a rationale.

This produced a coverage matrix with three states per requirement:
- **Covered** — at least one tagged test asserts the fit criterion
- **Accepted gap** — explicitly documented reason (not built, proposed, operational)
- **Action needed** — implemented but untested (close now)

The "action needed" category is what drives work. When it reaches zero, coverage is complete for the current state of the codebase. New features add to both the requirement catalog and the test suite simultaneously.

**Framework action:** The Volere template should include a `testability` field per requirement: `automatable`, `operational`, `hardware-dependent`, `not-yet-implemented`. The coverage gate uses this to compute the denominator correctly.

---

## Insight 3: Cross-machine Playwright eliminates "manual-only" as a category

6 requirements were initially classified as manual-only: mobile PWA (UR-04), conference calls (UR-06), drag-drop (UR-10), STT quality (UR-11), response latency (UR-24), and crash recovery (UR-22).

All 6 were automated:
- **UR-04**: Playwright with `devices['iPhone 13']` emulation (Chromium, not WebKit — viewport and user-agent are what matter, not the rendering engine)
- **UR-06**: Unit tests for server-side broadcast + conference transcript persistence
- **UR-10**: API-level POST to inbox endpoint
- **UR-11**: TTS→STT loopback script already existed; added Playwright test for STT status endpoint
- **UR-24**: Validated by aligning polling constants (code fix, not just test)
- **UR-22**: SSH-based kill/restart/verify script against M4 over Tailscale

The key enabler: running Playwright on M3 against M4's server over Tailscale tests the real network path. This is *more* realistic than testing on localhost — it exercises TLS, Tailscale routing, and cross-machine latency.

**Framework action:** The default assumption should be "automatable" for any fit criterion that can be expressed as an observable state change. "Manual-only" should require justification — what specifically about this criterion makes it impossible to observe programmatically?

---

## Insight 4: A living gate catches what one-time audits miss

4 test bugs found on the first cross-machine Playwright run:
1. **UR-40**: Test assumed `GET /sessions/:id` exists — it doesn't (sessions are resolved client-side from the list)
2. **UR-30**: Test checked for `sessions` field — actual field is `session_count`
3. **TC-11**: Test parsed HTML for CDN script URLs — got unpkg.com URLs that aren't local files
4. **UR-04**: Test prepended `/chat/` to manifest href — manifest is at root `/manifest.json`

A one-time audit would have written these tests, declared victory, and moved on. The tests would have silently failed on the next run (or never been run again). The living gate — integrated into `make acceptance` and producing a regenerated matrix — caught them immediately because the tests actually ran against production infrastructure.

**Framework action:** Acceptance evidence must be re-verifiable. A timestamped screenshot from March 15 is not evidence on March 31 — the code may have changed. The coverage matrix should be regenerated on every push (or at minimum, before any release). Stale evidence is not evidence.

---

## Insight 5: Acceptance analysis surfaces architectural inconsistencies

The agent WebSocket handler polled tmux at 2s intervals with a 4-consecutive idle threshold (8s debounce). Two other code paths — `WaitForIdle` and the A2A handler — used 500ms with 2-consecutive (1s debounce). Nobody noticed because nobody compared the three paths side by side.

The acceptance gap analysis forced the comparison because UR-24 (response latency <25s) required understanding the full pipeline. Tracing the latency budget revealed the inconsistency: identical logic, different constants, no justification for the difference.

After alignment: infrastructure overhead dropped from ~10s to ~1.5s. UR-24 was tightened from <25s to <15s round-trip.

**Framework action:** Fit criteria with quantitative thresholds (latency, capacity, timeouts) should trigger a trace through every code path that contributes to the measured quantity. If the same algorithm appears in multiple paths with different constants, that's either a bug or an undocumented design decision — both should be surfaced.

---

## Cross-cutting observation

The session produced a methodology for requirements-driven acceptance testing:

1. Write fit criteria in Volere format (testable, measurable)
2. Tag every test with its requirement ID (`UR-XX`, `TC-XX`)
3. Run an aggregator that scans test output for tags → coverage matrix
4. Run tests against live infrastructure (not mocks, not localhost)
5. Generate a risk register for gaps (accept/close/defer)
6. Regenerate on every push

This is the verification side of the Volere Agentic Framework. Experiment 001 showed that agents can derive requirements. This session showed that agents can verify them — but only by running code, not by reviewing it.

---

## Insight 6: SessionStart hooks close the loop between requirements and agent behavior

The coverage matrix and risk register are artifacts. Without a trigger, they sit in files that agents never read. The fix: a SessionStart hook that runs on every new conversation, reads the risk register, and injects uncovered requirements as context. The agent sees the gaps before the user says anything.

This is the missing piece in the verification methodology:

1. Write fit criteria → requirements exist
2. Tag tests with requirement IDs → traceability exists
3. Run aggregator → coverage matrix exists
4. Generate risk register → gaps are documented
5. **SessionStart hook reads risk register → agent knows what to work on**

Without step 5, the agent starts each session blank — the user must remember to say "check the coverage gaps." With step 5, the agent proposes work autonomously. The requirements drive the agent's behavior, not the user's memory.

Implementation (thul-studio):
- `scripts/coverage-gaps.sh` reads `test/acceptance/coverage-matrix.md`, counts uncovered requirements, outputs the gap list
- `.claude/settings.json` registers it as a `SessionStart` hook
- Every new session sees "Acceptance coverage: 50/55. Uncovered: UR-34, UR-37, UR-41, UR-42. Propose which gaps to close."

**Framework action:** The Volere Agentic Framework should include a `verification-loop` hook template that:
1. Reads the project's coverage matrix (generated by the `audit-tests` skill)
2. Identifies requirements with no acceptance evidence
3. Injects the gap list into the session context
4. Instructs the agent to propose work on uncovered requirements before starting other tasks

This turns requirements from passive documentation into active drivers of agent behavior. The requirements tell the agent what to build next — not the user.
