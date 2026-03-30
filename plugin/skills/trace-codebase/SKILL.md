---
name: trace-codebase
description: Maps code files and tests to requirements — identifies dead code, test theater, coverage gaps, and orphaned features using agent team trace. Use when tracing code to requirements, finding dead code, identifying untested fit criteria, or before major refactoring.
---

# Trace Codebase

Map every source file and test to the requirements it serves. Identifies dead code (no requirement), test theater (tests that don't verify fit criteria), coverage gaps (fit criteria without tests), and orphaned features.

## When to Use

- "Trace code to requirements"
- "What's dead code?"
- "Find test theater"
- "Which fit criteria aren't tested?"
- Before any major refactoring or cleanup
- After requirements are stable (run review-requirements first)

## Prerequisites

- Requirements exist in `docs/requirements/*.yaml` (at least 5)
- Requirements have been reviewed (reviews/synthesis.md exists)
- ARCHITECTURE.md is current
- Codebase has tests

## How It Works

This skill generates a Trace Review team prompt (review type 3 from review-requirements). It can be run standalone or as part of the review-requirements skill.

### Step 1: Inventory

Before assembling the team, inventory what needs tracing:

```bash
# Count source files (excluding tests, deps, generated)
find src/ internal/ cmd/ lib/ app/ -name "*.go" -o -name "*.js" -o -name "*.ts" -o -name "*.py" \
  | grep -v _test | grep -v node_modules | grep -v vendor | wc -l

# Count test files
find . -name "*_test.go" -o -name "*.test.js" -o -name "*.test.ts" -o -name "*.spec.*" \
  | grep -v node_modules | wc -l

# Count requirements
ls docs/requirements/UR-*.yaml docs/requirements/TC-*.yaml 2>/dev/null | wc -l

# Check for frontend code
ls -d landing/ grid/ chat/ web/ public/ src/components/ 2>/dev/null
```

### Step 2: Determine Team Composition

| Project type | Team |
|-------------|------|
| Backend only (Go, Python, Node API) | Code Tracer + Test Tracer + Synthesis (3 agents) |
| Full stack (backend + frontend) | Code Tracer + Test Tracer + Frontend Tracer + Synthesis (4 agents) |
| Monorepo (multiple services) | One Code Tracer per service + Test Tracer + Synthesis |

### Step 3: Assemble Team

Use the trace review prompt from the review-requirements skill. Each tracer:

**Code Tracer deliverable** (`reviews/trace-code.md`):
```markdown
| File | Functions | Traces to | Status |
|------|-----------|-----------|--------|
| internal/auth/cors.go | NewCORSMiddleware, isAllowedOrigin | UR-027 | TRACED |
| internal/session/state.go | DetectState, debounceIdle | UR-003, TC-005 | TRACED |
| internal/legacy/old.go | processLegacy | (none) | ORPHANED |

Summary: X files, Y% traced, Z orphaned
```

Status values:
- **TRACED** — clearly serves one or more URs/TCs
- **ORPHANED** — no requirement found (candidate for dead code or missing requirement)
- **PARTIAL** — some functions trace, others don't
- **PROPOSED** — serves a `[proposed]` requirement (not yet implemented)

**Test Tracer deliverable** (`reviews/trace-tests.md`):
```markdown
| Test File | Test Name | Fit Criterion | Classification |
|-----------|-----------|--------------|----------------|
| auth_test.go | TestCORSRestriction | UR-027 "non-mesh origin gets no headers" | VERIFIES |
| auth_test.go | TestMarshalConfig | (none) | THEATER |
| session_test.go | TestDetectState/idle | UR-003 "5 states, accuracy > 20 patterns" | VERIFIES |
| session_test.go | TestPortAlloc | TC-003 "OS-level port conflict" | SUPPORTS |
```

Classification values:
- **VERIFIES** — directly tests a stated fit criterion
- **SUPPORTS** — tests implementation that serves a fit criterion indirectly
- **THEATER** — tests implementation details with no connection to any fit criterion
- **REDUNDANT** — duplicates another test's coverage of the same criterion

**Frontend Tracer deliverable** (`reviews/trace-frontend.md`):
- Surface-to-UR mapping
- Dead CSS classes, unreachable JS functions, commented-out features
- URs that specify UI behavior but have no frontend implementation

**Synthesis deliverable** (`reviews/trace-synthesis.md`):
Cleanup plan in phases:
1. **Safe removals** — dead code + theater tests (zero risk)
2. **Test rewrites** — make tests verify fit criteria, not implementation
3. **New tests** — cover uncovered fit criteria, prioritised by DAL
4. **Code changes** — implementation doesn't match requirement
5. **Structural refactoring** — duplicated code, module consolidation

Each action: what to do, which UR/TC it serves, effort estimate, dependencies.

### Step 4: Execute the Cleanup Plan

After the trace, execute phases in order:
1. Safe removals first (immediate value, zero risk)
2. Then security/DAL-A fixes
3. Then test rewrites and new tests
4. Then structural refactoring

**Always:** run tests after each removal step. Commit after each step. If tests fail, stop and investigate.

## Output Format

The trace produces a complete map:

```
Code → Requirements (which code serves which requirement)
Tests → Fit Criteria (which tests verify which criterion)
Requirements → Coverage (which criteria have no tests)
```

This map drives the `volere trace` and `volere coverage` CLI commands (v0.5).
