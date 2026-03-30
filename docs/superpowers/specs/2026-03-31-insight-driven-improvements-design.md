# Insight-Driven Plugin Improvements

**Date:** 2026-03-31
**Source:** 8 insights from Studio hardening session (2026-03-30)
**Scope:** v0.9 (schema + skills + hooks) and v1.0 (productization)
**Status:** Approved

---

## Context

A 10-hour Studio hardening session (Phase 5 consolidation, Pass 2 codebase trace, 33 cleanup actions, browser acceptance testing, voice loopback testing) produced 8 insights documented in `docs/insights/session-2026-03-30-studio-hardening.md`. Each insight traces to a concrete framework gap. This spec captures the improvements.

## Changes

### 1. Schema: `cross_verify` field (Insight 2)

**File:** `plugin/schema/requirement.schema.json`

Add optional `cross_verify` array of requirement IDs to the snow card schema. Lists URs whose fit criteria must be re-verified when this requirement changes.

```yaml
# Example: UR-27 (CSP hardening)
cross_verify:
  - UR-03  # Grid page — React loaded from CDN
  - UR-12  # TTS audio — blob: URLs
```

**Rationale:** UR-27 was implemented correctly for security but broke UR-03 and UR-12. The root cause: no structured way to declare cross-requirement dependencies beyond `depends_on` (which models build-order, not verification-order).

**Consumers:**
- `volere impact <ID>` — includes cross_verify targets in impact graph
- `check-fit-criteria` hook — re-verifies cross_verify targets when a requirement changes
- `post-merge` hook — flags cross_verify violations in merged changes
- `write-requirement` skill — prompts author to populate this field

**Schema addition:**
```json
"cross_verify": {
  "type": "array",
  "items": { "type": "string", "pattern": "^(UR|TC|BUC|PUC|SEC|SHR)-[0-9]{3}$" },
  "description": "Requirements whose fit criteria must be re-verified when this requirement changes"
}
```

### 2. Schema: `verification_method` on fit criteria (Insight 3)

**File:** `plugin/schema/requirement.schema.json`

Add optional `verification_method` enum to each fit criterion entry: `unit | integration | system | acceptance`.

**Rationale:** A fit criterion that says "user can see the grid" should not be verified by a unit test. Making the expected V-Model level explicit per criterion lets the `audit-tests` skill flag mismatches automatically.

**Schema addition** (inside fit_criteria items):
```json
"verification_method": {
  "type": "string",
  "enum": ["unit", "integration", "system", "acceptance"],
  "description": "Expected V-Model verification level for this criterion"
}
```

### 3. Schema: `verification_level` on evidence (Insight 5)

**File:** `plugin/schema/evidence.schema.json`

Add required `verification_level` enum: `unit | integration | system | acceptance`.

**Rationale:** "go test passes" is not evidence that TTS works. Evidence must record the V-Model level at which verification occurred. DAL-B requires system-level evidence minimum. DAL-A requires acceptance-level evidence.

**Schema addition:**
```json
"verification_level": {
  "type": "string",
  "enum": ["unit", "integration", "system", "acceptance"],
  "description": "V-Model level at which this evidence was collected"
}
```

**Enforcement:** The `audit-tests` skill reports the highest verification level achieved per fit criterion. The `check-fit-criteria` hook validates that DAL-B+ requirements have system-level or higher evidence.

### 4. Skill: `write-requirement` cross-impact prompt (Insight 2)

**File:** `plugin/skills/write-requirement/skill.md`

After the fit criteria section, add a cross-impact prompt:

> "Does this requirement's fit criterion affect other requirements? If this is a security or infrastructure change, which user-facing requirements could it break? List them in the `cross_verify` field."

Guide the author to think about:
- Security changes that restrict what browser surfaces can load/execute
- Infrastructure changes that affect multiple user-facing features
- Performance constraints that limit functionality
- Data model changes that break downstream consumers

### 5. Skill: `audit-tests` verification level reporting (Insights 1, 5, 8)

**File:** `plugin/skills/audit-tests/skill.md`

Three additions:

**a) Verification level per fit criterion.** For each fit criterion, report the highest verification level achieved:

| Requirement | Fit Criterion | Highest Level | Required Level | Gap? |
|-------------|--------------|---------------|----------------|------|
| UR-03 | Grid renders sessions | unit | system | YES |
| UR-12 | TTS plays audio | integration | acceptance | YES |

**b) Browser-facing flag.** Flag any UR with browser-facing fit criteria (keywords: "user can see", "renders", "displays", "user can hear", "plays", "shows") that has only unit or integration level tests. These require system or acceptance level verification.

**c) Loopback testing suggestion.** When fit criteria involve hardware (microphone, camera, speaker, sensor), suggest the loopback pattern:
1. Identify the service boundary (e.g., STT WebSocket endpoint)
2. Generate synthetic input (e.g., TTS output → MP3 bytes)
3. Feed through the pipeline (e.g., MP3 → WebSocket → Deepgram)
4. Verify the output (e.g., keyword match on transcription)

### 6. Skill: `classify-risk` browser-facing auto-escalation (Insight 3)

**File:** `plugin/skills/classify-risk/skill.md`

Add auto-escalation rule: any UR with browser-facing fit criteria keywords → minimum DAL-C, recommend system-level verification. Keywords: "user can see", "user can hear", "renders", "displays", "plays", "shows", "browser", "page", "screen".

This complements the existing override rules (auth/encryption/secrets/regulatory → minimum DAL-B).

### 7. Hook: `check-fit-criteria` configurable verification commands (Insights 3, 4)

**File:** `plugin/hooks/check-fit-criteria.sh`

Currently hardcoded to detect and run `go test ./...` or `npm test`. Change to read verification commands from `.volere/profile.yaml`:

```yaml
dal_levels:
  C:
    verification_commands:
      - "npm test"
  B:
    verification_commands:
      - "npm test"
      - "npx playwright test"
  A:
    verification_commands:
      - "npm test"
      - "npx playwright test"
      - "./scripts/acceptance-check.sh"
```

**Fallback:** If no `verification_commands` configured, use current auto-detection (`go test` / `npm test`).

**Profile schema update** (`plugin/schema/profile.schema.json`): Add `verification_commands` array to each DAL level configuration.

### 8. Hook: `post-checkout` — branch requirement drift (New)

**File:** `plugin/hooks/check-checkout.sh`

Runs after `git checkout` / `git switch`. Catches requirement drift between branches:

1. **Validate cards:** Run `volere validate --quiet` on the new branch. Warn on invalid/conflicting cards.
2. **DAL mismatch:** Compare `.volere/profile.yaml` DAL level between old and new branch. Warn if different.
3. **Requirement diff:** List requirement cards that were added, removed, or modified between the branches.

**Mode:** Advisory only (exit 0 always). Post-checkout hooks should never block — the checkout already happened.

### 9. Hook: `post-merge` — suspect link detection (New)

**File:** `plugin/hooks/check-merge.sh`

Runs after `git merge`. Catches downstream impacts of merged changes:

1. **Auto-suspect:** For any requirement card changed in the merge, mark downstream requirements as suspect via `volere suspect mark`.
2. **Cross-verify:** For any changed requirement that has `cross_verify` targets, list the targets that need re-verification.
3. **Validate:** Run `volere validate` to catch YAML merge conflicts in requirement cards.
4. **Report:** Print summary of suspect links created and cross-verify targets flagged.

**Mode:** Advisory (exit 0 always). Prints warnings but does not block. The merge already happened — the hook's job is to surface what needs attention.

### 10. Hook: `volere init` defaults (Insight 4)

**File:** `plugin/cli/volere` (init command) + `plugin/hooks/install.sh`

- Hooks installed by default during `volere init`. Currently optional — now required.
- Add `--no-hooks` flag for explicit opt-out (documented as "not recommended for DAL-C+").
- Profile template includes the rule: "Every fit criterion at DAL-C+ must have a corresponding hook or CI check."

### 11. Hook installer: full lifecycle support

**File:** `plugin/hooks/install.sh`

Add installation of the two new hooks (post-checkout, post-merge) alongside existing hooks. The installer chains with existing hooks (preserves any pre-existing post-checkout/post-merge hooks).

Updated hook suite:

| Git phase | Hook | File | Behavior |
|-----------|------|------|----------|
| Staging | pre-commit | check-secrets.sh | Blocks (secrets, binaries) |
| Committing | commit-msg | check-traceability.sh | Advisory or strict |
| Pushing | pre-push | check-fit-criteria.sh | Blocks at DAL-B+ |
| Switching branches | post-checkout | check-checkout.sh | Advisory |
| Merging | post-merge | check-merge.sh | Advisory |

### 12. Productization: parameterize paths (Insight 6)

**Files:** `plugin/skills/review-requirements/skill.md`, team prompt templates

Replace all hardcoded paths:
- `/Users/thul/repos/ulleberg/thul-agents/agents/...` → `${VOLERE_AGENTS_PATH}` or auto-detection from `.volere/context.yaml`
- Agent roster names (Steve, Albert, Steinar) → role-based references (architecture-reviewer, test-engineer, security-engineer)
- thul-studio specific examples → generic examples with a note "(replace with your project's requirements)"

### 13. Productization: zero-agent mode (Insight 6)

**File:** `plugin/skills/review-requirements/skill.md`

The review skill must work without an agent roster:

- **With roster:** Dispatch agents in parallel (current behavior)
- **Without roster:** Run all review perspectives sequentially in one Claude Code session. Each perspective gets its own heading and analysis pass.

Detection: If `${VOLERE_AGENTS_PATH}` is unset and no roster is configured in `.volere/context.yaml`, use zero-agent mode automatically.

### 14. Productization: retrofit guide (Insight 6)

**File:** `plugin/templates/project-scaffold/RETROFIT.md` (new)

Guide for applying Volere to an existing project with existing tests:

1. Run `volere init` in the project root
2. Identify existing requirements (user stories, tickets, acceptance criteria) → convert to snow cards
3. Run `volere trace` to map existing code → requirements
4. Run `volere audit` to classify existing tests (VERIFIES/SUPPORTS/THEATER/REDUNDANT)
5. Fill gaps: requirements without tests, code without requirements
6. Set DAL level based on project risk profile

### 15. Productization: regulatory claims (Insight 6)

**Files:** README.md, docs/spec.md, ARCHITECTURE.md

- Remove specific standards claims (FCC Part 15, RED 2014/53/EU, IEC 61508, ATEX) from documentation
- Keep the compliance schema and evidence chain (they work generically)
- Add a note: "Compliance profiles for specific standards (FCC, RED, IEC) planned for v1.1"
- Keep multi-dimensional fit criteria with regulatory as a dimension — the mechanism works, just don't claim specific standard support

### 16. Productization: non-thul example (Insight 6)

**File:** `docs/examples/simple-project/` (new directory)

One complete requirement cycle on a small, relatable project (e.g., a CLI tool or simple web API):
- 3-5 URs with multi-dimensional fit criteria
- 1-2 TCs
- Trace matrix
- Test classification
- Evidence records

Proves the framework works outside the thul ecosystem.

---

## Implementation Priority

### v0.9 — Hardening (this release)

| # | Change | Component | Effort |
|---|--------|-----------|--------|
| 1 | `cross_verify` schema field | Schema | Small |
| 2 | `verification_method` on fit criteria | Schema | Small |
| 3 | `verification_level` on evidence | Schema | Small |
| 4 | `write-requirement` cross-impact prompt | Skill | Small |
| 5 | `audit-tests` verification level reporting | Skill | Medium |
| 6 | `classify-risk` browser-facing escalation | Skill | Small |
| 7 | `check-fit-criteria` configurable commands | Hook | Medium |
| 8 | `post-checkout` hook | Hook (new) | Medium |
| 9 | `post-merge` hook | Hook (new) | Medium |
| 10 | `volere init` hooks by default | CLI | Small |
| 11 | Hook installer update | Hook | Small |

### v1.0 — Release

| # | Change | Component | Effort |
|---|--------|-----------|--------|
| 12 | Parameterize paths | Skills/templates | Medium |
| 13 | Zero-agent mode | Skill | Medium |
| 14 | Retrofit guide | Template (new) | Medium |
| 15 | Regulatory claims cleanup | Docs | Small |
| 16 | Non-thul example | Docs (new) | Large |

---

## Acceptance Criteria

### Schema changes pass validation
- Existing requirement cards validate against updated schema (backward compatible)
- New fields are optional — no existing card breaks
- Evidence records with `verification_level` validate correctly

### Skills guide correctly
- `write-requirement` prompts for `cross_verify` after fit criteria
- `audit-tests` reports verification level gaps in its output table
- `audit-tests` suggests loopback testing for hardware-dependent fit criteria
- `classify-risk` auto-escalates browser-facing URs to DAL-C minimum

### Hooks enforce at the right moments
- `check-fit-criteria` reads verification commands from profile.yaml
- `check-fit-criteria` falls back to auto-detection when no commands configured
- `post-checkout` warns on DAL mismatch and requirement diff (advisory, never blocks)
- `post-merge` marks suspect links for changed requirements (advisory, never blocks)
- `volere init` installs all 5 hooks by default
- All existing hook tests (12/12) still pass
- New hooks have their own test coverage

### Productization works for non-Thomas users
- No hardcoded paths remain in skills or templates
- Review skill works in zero-agent mode (sequential perspectives)
- Retrofit guide covers the existing-project workflow
- Non-thul example demonstrates a complete cycle
- No specific regulatory standard claims in docs (compliance mechanism preserved)
