# Session Insights: Studio Hardening & Pass 2 Trace

**Date:** 2026-03-30
**Source:** 8-hour session — Phase 5 consolidation, Pass 2 codebase trace, 33 cleanup actions, browser acceptance testing
**Project:** thul-studio (43 URs, 12 TCs, 437 tests)

---

## Insight 1: "Tests pass" is not verification

437 tests passed. The grid page was black. TTS audio was silent. UTF-8 characters rendered as underscores. The Playwright system test suite was 100% broken.

The V-Model distinction between unit tests (left side, verify implementation) and acceptance tests (right side, verify fit criteria) is not academic — it's the gap where production breaks live.

The Pass 2 test tracer classified 165 tests as SUPPORTS (verify implementation) vs 145 as VERIFIES (verify fit criteria). The SUPPORTS tests create a false sense of coverage. A CSP test that checks "does the header exist?" passes while the header actively breaks the page.

**Framework action:** Make this a hard rule in the `audit-tests` skill: *fit criteria verification ≠ test suite green.* The skill should flag any UR with browser-facing fit criteria that has only unit-level tests. DAL-B and above should require acceptance-level evidence, not just test-level evidence.

---

## Insight 2: Security fit criteria must be multi-dimensional

UR-27 (CSP hardening) was implemented correctly from a security perspective — restrictive `default-src 'self'`, no inline scripts from unknown origins. It also broke UR-03 (grid page — React loaded from unpkg.com CDN) and UR-12 (TTS audio — blob: URLs blocked by missing `media-src`).

A security requirement that breaks user requirements isn't secure — it's broken. The root cause: UR-27's fit criterion was one-dimensional (security only). It should have been:

> CSP headers are set **AND** all browser surfaces render without console errors **AND** TTS audio playback works **AND** CDN scripts load successfully.

The framework's multi-dimensional fit criteria (user, security, operational, regulatory) exist for exactly this case — but we didn't apply them. We wrote a security fit criterion without cross-referencing the user fit criteria it could break.

**Framework action:** The `write-requirement` skill should prompt: "Does this requirement's fit criterion affect other requirements? If this is a security/infrastructure change, which user-facing requirements could it break?" Add a `cross_verify` field to the snow card schema that lists URs whose fit criteria must be re-verified when this requirement changes.

---

## Insight 3: Browser-level verification is not optional for web systems

`curl` returns HTTP 200 with valid HTML, correct Content-Type, and proper CSP headers. The page is black.

Only a real browser catches:
- CSP blocking CDN scripts (React, highlight.js, marked.js)
- CSP blocking blob: URLs (TTS audio playback)
- Missing locale environment variables (UTF-8 rendering)
- Service worker SSL certificate errors
- JavaScript initialization failures that don't surface as HTTP errors

Any fit criterion that says "user can see X" or "user can hear X" requires browser verification. HTTP-level assertions verify the transport, not the experience.

**Framework action:** The `classify-risk` skill should auto-escalate DAL for any UR with browser-facing fit criteria. The `check-fit-criteria` hook should support browser verification commands (gstack browse, Playwright) alongside `go test` and `npm test`. Add a `verification_method` field to the snow card: `unit`, `integration`, `system`, `acceptance` — mapped to the V-Model right side.

---

## Insight 4: Hooks are the only enforcement that works

CLAUDE.md said "verify every browser surface before done." Agents skipped it. CLAUDE.md said "use Playwright for testing." Playwright was 100% broken for months. CLAUDE.md said "all secrets in ~/.secrets." No automated check existed.

The pre-push hook that runs gstack browse against every surface **cannot be skipped** (without `--no-verify`, which is auditable). In one session, the hook caught what months of documented guidelines didn't:

| What | Guideline (soft) | Hook (hard) |
|------|-----------------|-------------|
| CSP breaking grid | "Verify surfaces" in CLAUDE.md — not done | Pre-push: gstack browse checks console errors |
| CSP breaking TTS | "Test TTS" in CLAUDE.md — not done | Pre-push: POST /tts + verify MP3 |
| Secrets in code | "~/.secrets only" in CLAUDE.md — not enforced | Pre-commit: pattern scan on staged diffs |
| Binary in git | ".gitignore" — binaries weren't in it | Pre-commit: reject staged binary files |

The framework's hook-based enforcement (check-secrets, check-traceability, check-fit-criteria) is validated by this session. Soft constraints drift. Hard constraints hold.

**Framework action:** Promote hooks from "recommended" to "required for DAL-C and above." The `volere init` scaffold should install hooks by default, not as an optional step. The project constitution should require: "every fit criterion at DAL-C+ has a corresponding hook or CI check."

---

## Insight 5: Evidence must distinguish implementation from acceptance

The framework's evidence chain schema tracks test results as proof of verification. But "go test passes" is not evidence that UR-12 (TTS) works. Evidence should record *what was actually verified*:

| Evidence type | Example | V-Model level |
|--------------|---------|---------------|
| Implementation | `go test ./internal/api/ passes` | Unit |
| Integration | `TestHealthHandler returns all fields` | Integration |
| System | `Playwright: 30/30 pass, grid renders React` | System |
| Acceptance | `gstack browse: POST /tts → 200, valid MP3, zero CSP violations` | Acceptance |

A fit criterion verified only at the implementation level has weaker evidence than one verified at the acceptance level. The evidence schema should encode this distinction so that DAL-appropriate verification depth is enforced.

**Framework action:** Add `verification_level` to the evidence schema: `unit`, `integration`, `system`, `acceptance`. The `audit-tests` skill should report the highest verification level achieved per fit criterion. DAL-B requires system-level evidence minimum. DAL-A requires acceptance-level evidence.

---

## Insight 6: The framework is Thomas-shaped, not user-shaped

The framework works. This session proved it — 43 URs traced to code (96.2%), 12 TCs with test coverage, 33 cleanup actions executed, 3 bugs caught by cross-referencing tracers, browser acceptance hooks preventing regressions.

But it works for Thomas, on Thomas's machines, with Thomas's agent roster. Specifically:

- Team prompts hardcode `/Users/thul/repos/ulleberg/thul-agents/agents/chief-technical-officer/SOUL.md`
- Skills assume agents named Steve, Albert, Steinar exist in a roster
- The workflow assumes Studio's multi-agent A2A infrastructure for team assembly
- Examples reference thul-studio's specific URs, TCs, and architecture
- The CLI assumes the thul ecosystem directory structure

A developer opening the repo to apply it to their Django project or Rust CLI tool would find:
- No onboarding guide for existing projects (only `volere init` for new ones)
- No example showing the full cycle on a simple project
- Team prompts that can't run without the thul agent roster
- Regulatory claims (FCC, RED, IEC 61508) with no concrete implementation

For v1.0 marketplace publication, every path, agent name, and workflow assumption needs to be parameterized. The framework solves a real problem — but it's currently a personal tool, not a product.

**Framework action:**
1. Replace hardcoded paths with `${AGENTS_PATH}` or auto-detection
2. Make team prompts work with zero-agent setup (single Claude Code session, no roster)
3. Add a "Retrofit Guide" — how to apply Volere to an existing project with existing tests
4. Build one complete example on a small open-source project (not thul-*)
5. Remove or implement the regulatory claims (FCC, RED, IEC 61508)
6. Test the `volere init` → `volere trace` → `volere coverage` pipeline on a project that isn't thul-studio
