# Team Prompt: Codebase-to-Requirements Trace (Pass 2)

Run this from a Claude Code session in `thul-studio/`.

## Purpose

Trace existing code and tests back to the updated requirements (43 URs + 12 TCs).
Identify: dead code (no requirement), test theater (tests that don't verify fit criteria),
missing test coverage (fit criteria without tests), and orphaned features.

## Prompt

```
Create an agent team to trace the thul-studio codebase back to requirements.

Context: We have 43 user requirements (docs/requirements/user.md) and 12 technical
constraints (docs/requirements/technical-constraints.md) — all reviewed and validated.
Now we need to know: does the code match the requirements? What's dead? What's missing?

All teammates should read:
- docs/requirements/user.md (43 URs)
- docs/requirements/technical-constraints.md (12 TCs)
- ARCHITECTURE.md (system overview)
- CLAUDE.md (conventions and gotchas)

Spawn these teammates:

1. Go Code Tracer — spawn with prompt:
   "You are a code analyst tracing Go server code to requirements.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/test-engineer/SOUL.md

   Then read:
   - docs/requirements/user.md (43 URs)
   - docs/requirements/technical-constraints.md (12 TCs)
   - ARCHITECTURE.md

   Your task: For every Go package in internal/ and every command in cmd/,
   determine which UR(s) or TC(s) it serves.

   Method:
   1. List every .go file (excluding _test.go) in internal/ and cmd/
   2. For each file, read it and determine which requirement(s) it implements
   3. Flag files/functions that don't trace to any UR or TC — these are
      candidates for dead code or missing requirements

   Your deliverable — write to docs/requirements/reviews/trace-code.md:

   A table with columns: File | Functions | Traces to | Status
   Status is one of:
   - TRACED: clearly serves one or more URs/TCs
   - ORPHANED: no requirement found — candidate for dead code or missing UR
   - PARTIAL: some functions trace, others don't

   Then a summary section:
   - Total files, traced %, orphaned %
   - List of orphaned code with your assessment: dead code or missing requirement?
   - Any code that serves a [proposed] UR (not yet implemented) — flag separately

   Be thorough. Read every file. Don't guess from filenames."

2. Test Tracer — spawn with prompt:
   "You are a test analyst tracing tests to fit criteria.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/test-engineer/SOUL.md

   Then read:
   - docs/requirements/user.md (43 URs — focus on fit criteria)
   - docs/requirements/technical-constraints.md (12 TCs — focus on fit criteria)
   - docs/regression-baseline.md (existing test-to-UR mapping)
   - docs/studio-v-model-testplan.md (V-Model test plan)

   Your task: For every test file, determine whether it verifies a FIT CRITERION
   (not just a UR). A test that checks implementation details but doesn't verify
   the stated fit criterion is test theater.

   Method:
   1. List every _test.go file and every .test.js file
   2. For each test, read it and match to a specific fit criterion
   3. Classify each test as:
      - VERIFIES: directly tests a stated fit criterion
      - SUPPORTS: tests implementation that serves a fit criterion indirectly
      - THEATER: tests implementation details with no connection to any fit criterion
      - REDUNDANT: duplicates another test's coverage of the same criterion

   Your deliverable — write to docs/requirements/reviews/trace-tests.md:

   Part 1 — Test classification table:
   Test File | Test Name | Fit Criterion | Classification

   Part 2 — Coverage matrix:
   For each UR and TC, list which tests verify its fit criteria.
   Flag fit criteria with NO tests.
   Flag fit criteria that are marked [proposed] (expected to have no tests).

   Part 3 — Recommendations:
   - Tests to remove (THEATER + REDUNDANT)
   - Tests to add (fit criteria with no coverage)
   - Tests to rewrite (SUPPORTS → should be VERIFIES)

   Be honest. The point is to find gaps, not to confirm coverage."

3. Frontend Tracer — spawn with prompt:
   "You are a frontend analyst tracing browser code to requirements.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/fullstack-engineer/SOUL.md

   Then read:
   - docs/requirements/user.md (43 URs — especially UI-facing ones:
     UR-01, 03, 04, 05, 06, 07, 08, 09, 10, 12, 17, 18, 19, 20, 26)
   - ARCHITECTURE.md (browser surfaces section)

   Your task: Trace browser code (landing/, grid/, chat/) to requirements.

   Method:
   1. Read each browser surface: landing/index.html, grid/index.html, chat/ modules
   2. For each UI feature/component, identify which UR it serves
   3. Flag features with no UR (orphaned UI code)
   4. Flag URs with no UI implementation (missing features)
   5. Check for dead CSS, unused JavaScript functions, commented-out code

   Your deliverable — write to docs/requirements/reviews/trace-frontend.md:

   Part 1 — Surface-to-UR mapping:
   Surface | Component/Feature | Traces to | Status (TRACED/ORPHANED/PARTIAL)

   Part 2 — Dead frontend code:
   - Unused CSS classes
   - Unreachable JavaScript functions
   - Commented-out features
   - Legacy code from pre-Go-rewrite (Node.js artifacts)

   Part 3 — UI coverage gaps:
   URs that specify UI behavior but have no frontend implementation."

4. Synthesis Lead — spawn with prompt:
   "You are the Chief of Staff synthesising the codebase trace.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/chief-of-staff/SOUL.md

   Wait for all three tracers to complete, then read:
   - docs/requirements/reviews/trace-code.md
   - docs/requirements/reviews/trace-tests.md
   - docs/requirements/reviews/trace-frontend.md

   Your deliverable — write to docs/requirements/reviews/trace-synthesis.md:

   1. The dead code list: files/functions with no requirement, recommended for removal.
      For each: is it truly dead, or does it serve an undocumented need?

   2. The test theater list: tests recommended for removal or rewrite.
      Cross-reference with the test tracer's classification.

   3. The coverage gap list: fit criteria with no tests, prioritized by DAL/priority.

   4. The cleanup plan: ordered list of cleanup actions, grouped into:
      - Safe removals (dead code + theater tests — no risk)
      - Rewrites (tests that should verify fit criteria instead of implementation)
      - New tests needed (uncovered fit criteria)
      - Code changes needed (implementation doesn't match requirement)

   5. Effort estimate: small/medium/large for each cleanup action.

   Challenge the tracers. If they marked something as dead but it's actually
   serving an undocumented need, say so. If they marked something as VERIFIES
   but the test is actually weak, push back."

Goal: Produce a complete map from code → requirements and tests → fit criteria.
The output drives the cleanup/refactoring plan.
Have teammates share findings and challenge each other.
```

## Pre-flight

1. Ensure the blocker fixes are committed and pushed (maxSessions=10, incremental transcript, TC-05)
2. Create reviews directory if needed: `mkdir -p docs/requirements/reviews`
3. Run from thul-studio root directory
