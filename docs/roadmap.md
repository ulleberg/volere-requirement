# Roadmap: v0.1 → v1.0

## Status: Active — v0.1 through v0.8 shipped, entering v0.9 hardening
## Date: 2026-03-30

## Where We Are

v0.1 through v0.8 shipped in a single session. The framework has: 5 skills, 4 hooks, 7 CLI commands, 4 JSON schemas, project scaffold, requirement templates (BUC/PUC/UR/TC), security baseline catalog, evidence lifecycle, suspect link management, and DAL profiles.

Next: v0.9 hardening (validate on 3 real projects), then v1.0 release.

## Dependency Graph

```
v0.1 (schema + scaffold + write-requirement)     ✓ DONE
  │
  ├── v0.2 (hooks: secrets, traceability)
  │     │
  │     └── v0.6 (DAL profiles + classify-risk)
  │           │
  │           └── v0.8 (compliance profiles + evidence chain)
  │                 │
  │                 └── v1.0 (full framework)
  │
  ├── v0.3 (review-requirements skill)
  │     │
  │     └── v0.4 (trace-codebase + audit-tests)
  │           │
  │           └── v0.5 (CLI: trace, coverage)
  │                 │
  │                 └── v0.7 (impact + suspect links)
  │                       │
  │                       └── v1.0
  │
  └── v0.3 and v0.2 are independent — can build in parallel
```

**Two parallel tracks:**
- **Track A (enforcement):** v0.2 → v0.6 → v0.8 → v1.0
- **Track B (intelligence):** v0.3 → v0.4 → v0.5 → v0.7 → v1.0

v1.0 merges both tracks.

## Version Plans

### v0.2 — Hard Enforcement (Track A)

**Goal:** Agents can't commit code that violates conventions. Moves from soft (CLAUDE.md) to hard (hooks).

**Build:**
1. `check-secrets` hook — runs gitleaks patterns against staged files, blocks commit on match
2. `check-traceability` hook — warns if commit message doesn't reference a UR/TC/BUC/PUC ID
3. Hook installer — `volere hooks install` adds hooks to `.git/hooks/` or `.husky/`
4. Documentation — hook configuration, customisation, bypass (with justification only)

**Acceptance test:** `check-secrets` blocks a commit containing a planted test secret. `check-traceability` warns on a commit with no requirement reference. Tested on thul-studio.

**Depends on:** v0.1 (schema — hook reads requirement IDs from YAML files)
**Effort:** Small (1-2 sessions)

---

### v0.3 — Agent Team Reviews (Track B)

**Goal:** Codify the review process proven on thul-studio into a reusable skill.

**Build:**
1. `review-requirements` skill — generates team assembly prompt from project's requirements and agent roster
2. Team prompt templates — parameterised versions of Pass 1, Pass 1.5, and Pass 2 prompts
3. Review output format — standardised structure for reviews/ directory
4. Synthesis scoring criteria — how the synthesis agent evaluates reviews

**Acceptance test:** `review-requirements` run on a project with 10+ URs produces review quality comparable to thul-studio Pass 1. Scored by synthesis agent on: specificity (% system-specific), testability (% with testable fit criteria), cross-document coherence (cross-references between reviews).

**Depends on:** v0.1 (schema — skill reads requirement cards)
**Effort:** Medium (2-3 sessions). Most content exists as proven team prompts — needs parameterisation.

**Note:** This is where the thul-studio team prompts (team-prompt-ur-review.md, team-prompt-ur-validation.md, team-prompt-codebase-trace.md) get generalised into a skill that works on any project.

---

### v0.4 — Codebase Intelligence (Track B)

**Goal:** Agents can map code to requirements and detect test theater automatically.

**Build:**
1. `trace-codebase` skill — generates team prompt for code→requirements trace
2. `audit-tests` skill — classifies tests as VERIFIES/SUPPORTS/THEATER/REDUNDANT
3. Trace output format — standardised table format for trace results
4. Coverage gap detection — identifies fit criteria without tests

**Acceptance test:** `trace-codebase` identifies planted dead code and missing traces in a project with known gaps. `audit-tests` correctly classifies VERIFIES vs THEATER. Run on thul-studio as regression.

**Depends on:** v0.3 (team prompt templates — trace uses the same team assembly pattern)
**Effort:** Medium (2-3 sessions). Proven team prompts exist from Pass 2 — needs parameterisation.

---

### v0.5 — CLI + Traceability (Track B)

**Goal:** Visibility into requirements state without running agent teams.

**Build:**
1. `volere trace` — compute and display traceability matrix (requirement → code → test)
2. `volere coverage` — show fit criteria coverage with per-dimension breakdown
3. `volere validate` — run all verification checks (schema, traceability, staleness, hooks)
4. `volere new` — create requirement card from template with auto-numbering
5. `volere init` — full scaffold command (currently manual copy)
6. Interface contract format — `.volere/contracts/*.yaml` schema and validation

**Acceptance test:** `volere trace` output matches manual traceability matrix for thul-studio. `volere coverage` correctly reports uncovered fit criteria against thul-studio's 43 URs + 12 TCs.

**Depends on:** v0.4 (trace format — CLI renders the same data the skill produces)
**Effort:** Medium-Large (3-4 sessions). CLI is a shell script wrapping schema validation + file traversal.

**Implementation note:** CLI reads YAML requirement files + scans code for requirement ID references + matches test files. No external database. Node.js for YAML/JSON processing (already used by validator).

---

### v0.6 — Graduated Rigour (Track A)

**Goal:** Verification effort scales to risk. Not every change needs the same rigour.

**Build:**
1. `classify-risk` skill — assigns DAL level based on blast radius, reversibility, affected URs
2. Profile enforcement — hooks and CI checks respect the DAL level from `.volere/profile.yaml`
3. `check-fit-criteria` hook — pre-push hook that runs tests for affected fit criteria (DAL-B+)
4. DAL override per requirement — individual URs can raise/lower their project's default DAL

**Acceptance test:** DAL-E project has no blocking hooks. DAL-A project blocks on missing tests. `classify-risk` correctly assigns DAL to 10 test cases spanning CSS changes to database migrations.

**Depends on:** v0.2 (hooks — this version adds DAL-awareness to existing hooks)
**Effort:** Medium (2-3 sessions)

---

### v0.7 — Change Impact (Track B)

**Goal:** When a requirement changes, the system identifies everything downstream that needs re-verification.

**Build:**
1. `volere impact <ID>` — traverses dependency graph (depends_on, serves, decomposed_to), lists suspect links
2. Suspect link status tracking — suspect/resolved/re-verified states
3. `volere validate --suspects` — fails if unresolved suspect links exist
4. Integration with `check-fit-criteria` hook — changed requirements trigger downstream test runs

**Acceptance test:** `volere impact UR-03` on thul-studio correctly identifies all downstream URs (UR-16, UR-19), TCs (TC-05, TC-09), and test files. Verified against known dependency graph.

**Depends on:** v0.5 (CLI infrastructure, traceability matrix)
**Effort:** Medium (2-3 sessions). Graph traversal from YAML files, stored as computed state.

---

### v0.8 — Compliance (Track A)

**Goal:** Multi-dimensional fit criteria with regulatory profiles, evidence chain, and audit output.

**Build:**
1. Compliance profile format — `.volere/compliance.yaml` defining applicable regulatory dimensions
2. Evidence lifecycle — planned/collected/verified/expired states, evidence records in `docs/evidence/`
3. Automated evidence collection — CI test results → evidence records
4. `volere coverage --dimension <name>` — per-dimension coverage
5. `volere evidence` — evidence audit output per dimension
6. Requirements reuse — shared catalogs with import/tailoring/versioning
7. Pre-built catalog: security baseline (from thul-studio patterns)

**Acceptance test:** Security baseline profile catches 5 planted security violations. Evidence record auto-generated from test results. Profile can be applied to existing project without breaking CI. `volere coverage --dimension security` matches expected coverage.

**Depends on:** v0.6 (DAL profiles — compliance dimensions reference DALs)
**Effort:** Large (4-5 sessions). Most complex version — evidence lifecycle, catalog format, versioning.

---

### v0.9 — Production Hardening

**Goal:** Ready for daily use across all thul-* projects.

**Build:**
1. Run the full framework on 3 thul-* projects (not just thul-studio)
2. Fix friction points discovered during real use
3. Automated evidence collection from CI (GitHub Actions integration)
4. Performance optimisation — `volere trace` and `volere coverage` on large requirement sets
5. Error messages and edge case handling
6. `extract-requirements` skill — scan arbitrary codebases, draft UR/TC cards, owner review workflow

**Acceptance test:** Three different projects (varying size, DAL level, with/without compliance) use the framework for one week without manual workarounds.

**Depends on:** v0.8 (all features available)
**Effort:** Medium (2-3 sessions + 1 week of real use)

---

### v1.0 — Release

**Goal:** Publish to thul-plugins marketplace as `volere@ulleberg`.

**Build:**
1. Plugin packaging for `claude plugins install volere@ulleberg`
2. Full documentation (README, getting started guide, reference)
3. Pre-built compliance profiles: security baseline, FCC Part 15, RED 2014/53/EU
4. Regression test suite (accumulated from all version acceptance tests)
5. Publish to ulleberg/thul-plugins marketplace

**Acceptance test:** Full framework applied to a new project from scratch. Project goes from zero to structured requirements, enforced architecture, and traced tests in one session. Install via marketplace works.

**Depends on:** v0.9 (hardened through real use)
**Effort:** Medium (2-3 sessions)

---

## Timeline Estimate

Not putting dates on this — the pace depends on how many sessions are available and what other work competes. But the dependency structure shows the critical path:

**Critical path:** v0.1 → v0.3 → v0.4 → v0.5 → v0.7 → v1.0 (Track B, 5 versions)

**Parallel path:** v0.2 → v0.6 → v0.8 (Track A, 3 versions — can run alongside Track B)

**The fastest route to v1.0** is to work both tracks simultaneously:
- Session 1: v0.2 (hooks) + v0.3 (review skill) in parallel
- Session 2: v0.4 (trace/audit) + v0.6 (DAL) in parallel
- Session 3: v0.5 (CLI)
- Session 4: v0.7 (impact) + v0.8 (compliance) in parallel
- Session 5: v0.9 (hardening)
- Session 6: v1.0 (release)

**6 sessions from where we are to v1.0** — if we parallelise tracks A and B.

## Validation Strategy

Every version follows the acceptance testing protocol from the spec:
1. Write fit criteria for the version's components (as YAML snow cards)
2. Write acceptance tests that verify each fit criterion
3. Run validation on a real project before declaring the version done
4. Accumulated acceptance tests become regression for subsequent versions

No version ships without passing its acceptance tests on a real project.
