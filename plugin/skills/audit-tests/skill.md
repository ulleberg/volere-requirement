---
name: audit-tests
description: Classify tests as VERIFIES, SUPPORTS, THEATER, or REDUNDANT against fit criteria — detects test theater and coverage gaps
---

# Audit Tests

Classify every test in the project against the requirement fit criteria it claims to verify. Detects test theater (tests that pass but prove nothing), redundant tests (duplicated coverage), and coverage gaps (fit criteria without tests).

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

| Classification | Criterion | Action |
|---------------|-----------|--------|
| **VERIFIES** | Test directly asserts the condition stated in a fit criterion | Keep — this is a real acceptance test |
| **SUPPORTS** | Test checks implementation that serves a fit criterion, but doesn't assert the criterion itself | Keep, but consider rewriting to verify the criterion directly |
| **THEATER** | Test checks implementation details with no connection to any fit criterion | Remove — it inflates coverage without adding verification |
| **REDUNDANT** | Test duplicates another test's coverage of the same criterion | Remove the weaker one — keep the test that most directly verifies the criterion |

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
```

## After the Audit

1. **Remove THEATER tests** — they add no verification value and slow the suite
2. **Remove REDUNDANT tests** — keep the stronger of duplicates
3. **Rewrite SUPPORTS → VERIFIES** — change assertions to match the stated fit criterion
4. **Add tests for GAPS** — prioritised by DAL level (A first)
5. **Update the coverage matrix** — run `volere coverage` (v0.5) to confirm improvement

## Integration with Other Skills

- **write-requirement** — when writing a new UR, immediately check if existing tests VERIFY its fit criteria
- **trace-codebase** — audit-tests is the test-specific layer of the full codebase trace
- **classify-risk** — DAL level determines which GAPS are urgent (DAL-A gaps block, DAL-E gaps can wait)
