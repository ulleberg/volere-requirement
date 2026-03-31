---
name: audit-tests
description: Classifies tests as VERIFIES, SUPPORTS, THEATER, or REDUNDANT against fit criteria — detects test theater and coverage gaps. Use when auditing test quality, finding test theater, checking if tests actually verify requirements, or before trusting an "all tests pass" claim.
---

# Audit Tests

Classify every test in the project against the requirement fit criteria it claims to verify. Detects test theater (tests that pass but prove nothing), redundant tests (duplicated coverage), and coverage gaps (fit criteria without tests). For terminology reference, run `/glossary`.

## When to Use

- "Audit test quality"
- "Find test theater"
- "Which tests can we remove?"
- "Are our tests actually testing the requirements?"
- After a trace review identifies test quality concerns
- Before trusting a "all tests pass" claim from an agent

## Why This Matters

Agents are lazy testers. They optimise for coverage metrics, not verification quality. Common patterns:

- **Theater:** `TestDefaults` — tests that config has default values. No fit criterion requires specific defaults. If defaults break, other tests catch it.
- **Theater:** `TestMarshalJSON` — tests JSON serialization. If marshaling breaks, every API test fails. Testing the plumbing, not the requirement.
- **Redundant:** Same state detection logic tested in Go AND JavaScript when only Go is authoritative.
- **Supports but doesn't verify:** Test checks that a function runs without error, but doesn't assert the specific condition from the fit criterion.

## How to Classify

For each test, ask: **"Which fit criterion does this test verify? Can I point to the specific measurable condition?"**

Classify as VERIFIES, SUPPORTS, THEATER, or REDUNDANT. See `/glossary` for definitions.

### Decision Tree

```
Does this test assert a condition from a fit criterion?
  ├── YES → Does it assert the EXACT condition (measurable threshold, specific behavior)?
  │         ├── YES → VERIFIES
  │         └── NO (asserts related but not the stated condition) → SUPPORTS
  └── NO → Is there ANY fit criterion this test is related to?
           ├── YES (but tests implementation, not criterion) → SUPPORTS
           └── NO (tests pure implementation detail) → THEATER
               └── Is there another test covering the same criterion?
                   └── YES → also REDUNDANT
```

### Examples

**VERIFIES:**
```go
// Fit criterion: "Non-Tailscale origin requests receive no CORS headers"
func TestCORSRejectsNonTailscaleOrigin(t *testing.T) {
    req := httptest.NewRequest("GET", "/sessions", nil)
    req.Header.Set("Origin", "https://evil.com")
    // ... asserts no Access-Control-Allow-Origin header
}
```

**SUPPORTS:**
```go
// Fit criterion: "State detection accuracy > 95% across 20+ patterns"
func TestDetectStateIdle(t *testing.T) {
    // Tests ONE pattern, not the 95% accuracy threshold
    result := DetectState("❯ ")
    assert(result == "idle")
}
```
This supports UR-003 but doesn't verify the fit criterion (which requires 20+ patterns and a 95% threshold). A test that runs ALL 20+ patterns and asserts > 95% accuracy would be VERIFIES.

**THEATER:**
```go
func TestGenerateSessionName(t *testing.T) {
    name := generateName("/path/to/project")
    assert(strings.Contains(name, "project"))
}
```
No fit criterion requires a specific name format. This is testing implementation detail.

**REDUNDANT:**
```javascript
// test/logic.test.js
describe('detectSessionState', () => {
    it('idle prompt', () => { ... })
})
```
Same logic already tested in `internal/session/state_test.go` (Go is authoritative). The JavaScript test is a legacy duplicate.

## Running the Audit

### Manual (single agent)

1. List all test files
2. For each test, read the test code
3. Match to a fit criterion from `docs/requirements/*.yaml`
4. Classify and record

### Team (for large codebases)

Use the Test Tracer from the trace-codebase skill or review-requirements skill (trace review type).

## Output Format

### Verification Level Analysis

For each fit criterion, report the highest V-Model level at which it has been tested:

| Requirement | Fit Criterion | Expected Level | Actual Level | Gap? |
|-------------|--------------|----------------|--------------|------|
| UR-03 | Grid renders sessions | system | unit | YES — browser-facing criterion needs system test |
| UR-12 | TTS plays audio | acceptance | integration | YES — hardware-adjacent criterion needs acceptance test |
| UR-27 | CSP headers set | system | system | No |

**Verification level mismatch detection:** Fit criteria contain signals that imply a minimum verification level. Flag any criterion where actual verification is below the minimum:

| Scenario | Fit criterion signals | Minimum level | Why unit/integration isn't enough |
|----------|----------------------|---------------|----------------------------------|
| **Browser-facing** | "user can see/hear", "renders", "displays", "shows", "plays", "page", "screen", "browser", "loads", "navigates" | system | curl 200 ≠ page renders correctly |
| **Multi-service** | "service A calls/returns", "API responds", "endpoint returns", "upstream/downstream" | integration | Testing one service doesn't verify the contract |
| **Stateful/temporal** | "after N minutes/hours", "expires", "timeout triggers", "eventually", "within N seconds" | system | Snapshot tests don't verify behavior over time |
| **Data pipeline** | "pipeline produces", "downstream receives", "transforms and delivers", "end-to-end" | system | Transform logic works but schema changed downstream |
| **Deployment/infra** | "deploys to", "runs on", "in production", "across machines", "multi-node", "cluster" | acceptance | Tests pass locally, target environment differs |
| **Hardware-adjacent** | "microphone", "camera", "speaker", "sensor", "GPS", "bluetooth" | acceptance | See Loopback Testing Pattern below |

If a fit criterion matches signals from this table but only has verification below the minimum level, flag it:

```
⚠ UR-03:user — "Grid renders all active sessions" — browser-facing criterion
  Current verification: unit (TestGridHandler returns JSON)
  Required verification: system (browser renders grid with sessions visible)
  Action: Add Playwright or browser-check test that verifies the rendered page

⚠ UR-08:operational — "Session expires after 30 minutes of inactivity" — stateful/temporal
  Current verification: unit (TestSessionExpiry with mocked clock)
  Required verification: system (real timer fires and session is cleaned up)
  Action: Add integration test with shortened timeout that verifies actual expiry

⚠ UR-15:user — "Auth service validates token with API gateway" — multi-service
  Current verification: unit (TestTokenValidation with mocked gateway)
  Required verification: integration (real auth service → real gateway → verified response)
  Action: Add integration test that exercises the actual service boundary
```

### Classification Legend

Always include this legend at the top of audit results so the reader doesn't have to look it up:

```
Classification legend:
  VERIFIES   — Test directly asserts the fit criterion condition. This is a real acceptance test. Keep.
  SUPPORTS   — Test checks implementation that serves a criterion, but doesn't assert the criterion itself. Keep, consider strengthening.
  THEATER    — Test has no connection to any fit criterion. Inflates coverage without adding verification. Remove.
  REDUNDANT  — Test duplicates another's coverage of the same criterion. Remove the weaker one.

For full terminology reference, run /glossary
```

### Classification Table

```markdown
| Test File | Test Name | Fit Criterion | Classification | Notes |
|-----------|-----------|--------------|----------------|-------|
| auth_test.go | TestCORSRestriction | UR-027:security | VERIFIES | |
| auth_test.go | TestCORSAgentCard | UR-027:security | VERIFIES | A2A exception |
| config_test.go | TestDefaults | (none) | THEATER | No FC requires defaults |
| session_test.go | TestDetectState/* | UR-003:user | SUPPORTS | Tests patterns, not 95% threshold |
```

### Coverage Matrix

```markdown
| Requirement | Fit Criterion | Tests | Classification |
|-------------|--------------|-------|----------------|
| UR-001 | "terminal latency < 1s" | (none) | GAP |
| UR-003 | "5 states, accuracy > 95%" | state_test.go (18) | SUPPORTS |
| UR-027 | "non-mesh origin rejected" | cors_test.go (6) | VERIFIES |
| TC-005 | "3 consecutive idle readings" | (none) | GAP — DAL-A |
```

### Summary

```markdown
Total tests: 285
  VERIFIES:   98 (34%)
  SUPPORTS:  112 (39%)
  THEATER:    45 (16%)
  REDUNDANT:  30 (11%)

Fit criteria coverage:
  Covered (VERIFIES): 38/55 (69%)
  Partially covered (SUPPORTS only): 10/55 (18%)
  Uncovered (GAP): 7/55 (13%)

Recommendations:
  Remove: 75 tests (THEATER + REDUNDANT)
  Rewrite: 10 tests (SUPPORTS → VERIFIES)
  Add: 7 tests (uncovered fit criteria)

Verification levels:
  Acceptance: 12/55 fit criteria (22%)
  System:     18/55 fit criteria (33%)
  Integration: 15/55 fit criteria (27%)
  Unit only:  10/55 fit criteria (18%)

Browser-facing gaps: 3 criteria with only unit tests (should be system+)
Hardware-adjacent: 2 criteria — loopback approach recommended
```

## After the Audit

1. **Remove THEATER tests** — they add no verification value and slow the suite
2. **Remove REDUNDANT tests** — keep the stronger of duplicates
3. **Rewrite SUPPORTS → VERIFIES** — change assertions to match the stated fit criterion
4. **Add tests for GAPS** — prioritised by DAL level (A first)
5. **Update the coverage matrix** — run `volere coverage` (v0.5) to confirm improvement

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

## Integration with Other Skills

- **write-requirement** — when writing a new UR, immediately check if existing tests VERIFY its fit criteria
- **trace-codebase** — audit-tests is the test-specific layer of the full codebase trace
- **classify-risk** — DAL level determines which GAPS are urgent (DAL-A gaps block, DAL-E gaps can wait)
