# Build Spec: Volere Agentic Framework

## Status: Ready for Deliver
## Date: 2026-03-30

## What We're Building

A Claude Code plugin that brings structured requirements engineering (Volere) and V-Model verification to agentic software development. Ships as skills + hooks + templates + a CLI, installable via the thul-plugins marketplace.

## Proven By

- **Experiment 001** (thul-agentic-research): skilled agent teams produce 100% testable fit criteria and self-organize for cross-document coherence
- **thul-studio validation** (this session): 26 URs → 43 URs + 12 TCs, 3 agent team reviews, 12,814 lines dead code removed, 23 security tests added via TDD, 5 P0 gaps closed

## Package Name

`volere@ulleberg` — installed via `claude plugins install volere@ulleberg`

## Components

### 1. Skills (how agents think)

| Skill | Trigger | What it does |
|-------|---------|-------------|
| `write-requirement` | "Add a requirement", "write a UR" | Guides agent through Volere snow card format: description, rationale, fit criteria (multi-dimensional), priority, DAL, dependencies. Outputs YAML. |
| `review-requirements` | "Review the requirements", "are these URs right?" | Assembles agent team (CTO, test, security, ops, synthesis) to review URs. Produces reviews/ directory with per-role findings and synthesis. Proven pattern from Pass 1. |
| `trace-codebase` | "Trace code to requirements", "what's dead?" | Assembles agent team (code tracer, test tracer, frontend tracer, synthesis) to map code→URs and tests→fit criteria. Produces cleanup plan. Proven pattern from Pass 2. |
| `audit-tests` | "Audit test quality", "find test theater" | Classifies tests as VERIFIES / SUPPORTS / THEATER / REDUNDANT against fit criteria. Produces coverage matrix and recommendations. |
| `classify-risk` | "What DAL is this?", "how much verification?" | Assigns DAL level (A-E) to a change based on blast radius, reversibility, and affected URs. Scales verification effort to risk. |

### 2. Hooks (hard enforcement)

| Hook | Event | What it does |
|------|-------|-------------|
| `check-traceability` | pre-commit | Warns if changed code files don't reference a UR or TC in commit message. Advisory in DAL-E, blocking in DAL-A. |
| `check-fit-criteria` | pre-push | Verifies that every UR with tests has passing tests. Fails push if fit criteria tests fail. |
| `check-secrets` | pre-commit | Runs gitleaks pattern matching. Blocks commits containing secret patterns. |

### 3. Templates

| Template | Command | What it creates |
|----------|---------|-----------------|
| `project-scaffold` | `volere init` | Creates docs/requirements/, .volere/, CLAUDE.md skeleton, ARCHITECTURE.md skeleton, CI workflow. Applies a DAL profile. |
| `requirement-card` | `volere new` | Creates a YAML snow card with all fields pre-populated for completion. |
| `team-review` | `volere review` | Generates a team assembly prompt customised to the project's URs and agent roster. |

### 4. Schema

**YAML Snow Card** (JSON Schema validated):

```yaml
id: UR-042
type: functional          # functional | performance | usability | operational |
                          # maintainability | security | cultural | legal
title: Session state detection accuracy
description: >
  One-sentence statement of what the system must do.
rationale: >
  Why this requirement exists — the pain that created it.

fit_criteria:
  user:
    criterion: "95% of state transitions detected within 2s"
    verification: test    # test | analysis | review | demonstration
    test_type: integration
  security:
    criterion: "State detection cannot be spoofed by terminal output injection"
    verification: test
    test_type: unit
  operational:
    criterion: "State detection works during cross-machine deployment"
    verification: test
    test_type: system

dal: C                    # A=catastrophic B=critical C=moderate D=minor E=cosmetic
priority: must            # must | should | could | wont
status: implemented       # proposed | implemented | verified | deprecated
satisfaction: 5           # 1-5 stakeholder happiness if implemented (Kano)
dissatisfaction: 4        # 1-5 stakeholder unhappiness if missing (Kano)

origin:
  stakeholder: Thomas Ulleberg
  date: 2026-03-30
  trigger: "Session cards showing wrong state"
  source: UR-07           # traces to parent requirement

depends_on: [UR-038]
conflicts: []
decomposed_to: [TC-05]   # traces downward to child requirements

history:
  - date: 2026-03-30
    action: created
    by: embedded-engineer
```

**Technical Constraint Card** (same format, TC- prefix, adds `serves` field):

```yaml
id: TC-05
type: technical-constraint
title: Idle state debounce
serves: [UR-03, UR-16]   # traces upward to URs
# ... rest same as snow card
```

### 5. Project Context (Volere sections 1-4)

Before writing requirements, the framework captures project-level context that scopes everything else.

**Project context file** (`docs/requirements/context.yaml`):

```yaml
# Project context — Volere sections 1-4
project:
  name: thul-studio
  purpose: >
    Browser-based terminal manager for multiple Claude Code sessions
    with multi-agent collaboration.
  scope:
    in: [session management, agent communication, browser UI, CLI]
    out: [agent identity (thul-agents), scheduling (thul-ops), billing]

stakeholders:
  - name: Thomas Ulleberg
    role: Owner / sole operator
    interests: [reliability, mobile access, multi-agent coordination]
  - name: Steve (CTO agent)
    role: Technical architect
    interests: [code quality, architecture coherence]
  # Add stakeholders as they emerge — customers, regulators, operators

constraints:
  mandated:
    - "Must run behind Tailscale — no public internet exposure"
    - "Go binary + static HTML — no Node.js runtime in production"
    - "Two runtime deps max (gorilla/websocket, gopkg.in/yaml.v3)"
  budget: null              # No budget constraint currently
  schedule: null            # No deadline currently
  platform: "macOS (M3/M4), Darwin, launchd"

glossary:
  session: "A Claude Code instance running in a tmux pane, accessible via browser terminal"
  campus: "The thul-agents repo — where agent identity, expertise, and training live"
  surface: "A browser page (Landing, Grid, Chat) served by Studio"
  fit criterion: "A measurable condition that defines when a requirement is satisfied"
  DAL: "Design Assurance Level (A-E) — scales verification effort to risk"
  snow card: "Volere's atomic requirement format — one card per requirement"

open_issues:
  - id: OI-01
    title: "Campus sync mechanism for multi-machine"
    status: open
    affects: [UR-05, UR-25]
  - id: OI-02
    title: "Agents as a Service — multi-tenant implications"
    status: parking-lot
    affects: [UR-38]

risks:
  - id: RISK-01
    title: "Context window blindness in large codebases"
    probability: high
    impact: medium
    mitigation: "grep-before-create rule, architectural fitness functions"
  - id: RISK-02
    title: "Test theater — agents write tests that pass but verify nothing"
    probability: high
    impact: high
    mitigation: "audit-tests skill, mutation testing in DAL-B+"
```

**The `volere init` scaffold creates this file** with placeholders. The `write-requirement` skill reads it to understand scope, stakeholders, and glossary before writing a requirement.

### 5a. Interface Contracts (V-Model architecture level)

The V-Model's architecture level maps to integration tests. Our spec has boundaries (what can import what) but is missing **interface contracts** — what each module provides and requires.

```yaml
# .volere/contracts/session-manager.yaml
module: internal/session/
version: 1

provides:
  - function: CreateSession
    accepts:
      folder: { type: string, required: true, constraint: "must exist" }
      type: { type: string, enum: [claude, claude-auto, shell] }
    returns:
      id: { type: string, format: "studio-{hex8}" }
      pid: { type: int, constraint: "> 0" }
      port: { type: int, constraint: "within configured range" }
    guarantees:
      - "Returned port is allocated and not in use"
      - "Session is persisted to sessions.json atomically"
      - "tmux session is created before function returns"
    errors:
      - condition: "No ports available"
        returns: "PortExhaustedError with capacity details"

requires:
  - "Port pool has at least one available port"
  - "Target folder exists and is readable"
  - "tmux is available on PATH"
```

**Verified by integration tests.** When an agent modifies a module, the contract tests catch interface violations. This prevents the interface drift anti-pattern.

**Ships in v0.5** alongside `volere trace`. Contract files are optional — projects add them for critical module boundaries.

### 5b. Requirement Decomposition (V-Model levels)

For complex systems, two levels (UR + TC) aren't enough. The V-Model decomposes:

```
Stakeholder Requirements (SHR)     "I want to talk to agents from my phone"
  └── System Requirements (UR)     "Mobile chat with STT/TTS over Tailscale"
      └── Subsystem Requirements   "Chat module handles voice, Grid handles sessions"
          └── Component Reqs (TC)  "Deepgram WebSocket needs CloseStream on shutdown"
```

The schema supports this via `source` (traces up) and `decomposed_to` (traces down):

```yaml
id: SHR-01
title: Mobile agent access
decomposed_to: [UR-04, UR-05, UR-11, UR-12]

id: UR-04
source: SHR-01
decomposed_to: [TC-07]

id: TC-07
serves: [UR-04, UR-11]
```

**For simple projects (< 50 requirements):** UR + TC is sufficient. Don't add SHR/subsystem levels unless complexity demands it.

**For complex/regulated projects:** Add levels as needed. The schema is the same at every level — only the prefix changes.

### 5c. Requirements Reuse (Shared Catalogs)

Multiple projects share requirements: security baselines, coding standards, project constitution compliance. Instead of duplicating, projects import from shared catalogs.

```yaml
# .volere/imports.yaml
catalogs:
  - name: security-baseline
    source: volere@ulleberg/catalogs/security-baseline.yaml
    version: 1.0
    tailoring:
      - exclude: [SEC-012]           # Not applicable to this project
      - override:
          SEC-003:
            dal: B                    # Raise from C to B for this project

  - name: project-standards
    source: volere@ulleberg/catalogs/project-standards.yaml
    version: 1.0
```

#### Catalog Format

A catalog is a YAML file containing requirement cards and metadata:

```yaml
# catalogs/security-baseline.yaml
catalog:
  name: security-baseline
  version: "1.0"
  description: "Security baseline for thul-* ecosystem projects"
  author: Thomas Ulleberg
  date: 2026-04-01
  derived_from: "thul-studio UR-27, UR-28, UR-33 (proven patterns)"

requirements:
  - id: SEC-001
    type: security
    title: CORS restricted to mesh origins
    description: >
      API routes restrict CORS to configured mesh hostnames.
      No wildcard origins on routes that return sensitive data.
    fit_criteria:
      security:
        criterion: "Non-mesh origin requests receive no CORS headers"
        verification: test
        test_type: integration
    dal: B
    priority: must
    tailorable: true          # Projects can override DAL or exclude

  - id: SEC-002
    type: security
    title: Input validation at API boundaries
    # ... full snow card format
    tailorable: true

  - id: SEC-003
    type: security
    title: Secrets management
    # ...
    tailorable: false         # Cannot be excluded — always applies
```

#### Import Resolution

When a project imports a catalog:

```yaml
# .volere/imports.yaml
catalogs:
  - name: security-baseline
    source: volere@ulleberg/catalogs/security-baseline.yaml
    version: "1.0"
    tailoring:
      - exclude: [SEC-012]
      - override:
          SEC-003:
            dal: A              # Raise severity for this project
```

**Resolution rules:**
1. Catalog requirements are merged into the project's requirement set with their original IDs
2. `exclude` removes requirements marked `tailorable: true` — cannot exclude `tailorable: false`
3. `override` replaces specific fields — cannot override `id`, `type`, or `title`
4. Version pinning: projects pin to a catalog version. `volere validate` warns if a newer version exists
5. **No transitive imports** — catalogs don't import other catalogs (keeps the graph flat)

**Conflict resolution:**
- If a project has UR-027 "CORS restriction" and imports SEC-001 "CORS restricted to mesh origins", `volere validate` flags the overlap
- Resolution: project requirement takes precedence. The catalog requirement is marked `superseded_by: UR-027`
- `volere coverage` shows both and notes the supersession

**Catalog versioning:**
- Catalogs use semantic versioning (major.minor)
- Major version bump: requirement added or removed, fit criterion changed
- Minor version bump: description clarified, metadata updated
- Projects pin to major version (`"1.x"`) or exact version (`"1.0"`)
- `volere validate` warns on major version mismatch: "security-baseline v2.0 available, you're on v1.0"

**Ships in v0.8** alongside compliance profiles. The security baseline catalog is built from the patterns proven on thul-studio.

### 5d. Change Management (Suspect Links)

When a requirement changes, everything downstream is suspect until re-verified.

```
UR-03 changes (state detection accuracy)
  ↓ volere impact UR-03
  Suspect links:
    ├── TC-05 (idle debounce) — serves UR-03
    ├── TC-09 (context persistence) — serves UR-19, depends on UR-03
    ├── UR-16 (response extraction) — depends on UR-03
    ├── tests/session/state_test.go — verifies UR-03
    └── tests/a2a/handler_test.go — verifies TC-05

  Action required:
    - Review TC-05, TC-09, UR-16 for consistency with changed UR-03
    - Re-run affected tests
    - Mark as re-verified or update
```

**How it works:**
1. `volere impact <id>` traverses the dependency graph (source, depends_on, serves, decomposed_to)
2. Flags all downstream artifacts as "suspect"
3. Agent must review each suspect link and either confirm or update
4. `volere validate` fails if suspect links remain unresolved

**Ships in v0.7.** The dependency graph is built from the YAML files — no external database needed.

### 6. DAL Profiles

```yaml
# .volere/profile.yaml
dal: C                              # default DAL for this project
profiles:
  E:  # cosmetic
    hooks: []
    ci: [lint, typecheck]
    review: none
  D:  # minor
    hooks: [check-secrets]
    ci: [lint, typecheck, test]
    review: none
  C:  # moderate (default)
    hooks: [check-secrets, check-traceability]
    ci: [lint, typecheck, test, coverage]
    review: code-reviewer
  B:  # critical
    hooks: [check-secrets, check-traceability, check-fit-criteria]
    ci: [lint, typecheck, test, coverage, mutation]
    review: [code-reviewer, test-engineer]
  A:  # catastrophic
    hooks: [check-secrets, check-traceability, check-fit-criteria]
    ci: [lint, typecheck, test, coverage, mutation, fitness-functions]
    review: [code-reviewer, test-engineer, architecture-reviewer, security-engineer]
```

### 6a. Autonomous Verification Mandate

**Agents perform ALL verification — from unit tests through acceptance — without human intervention.** The tools are now good enough. No "please verify manually." No "I can't test browser behavior." No lazy shortcuts.

#### The Problem This Solves

Agents are lazy. They consistently choose the easiest verification path:
- "Tests pass" (but the tests don't verify fit criteria — test theater)
- "Please check the browser" (avoiding browser automation they're capable of)
- "I verified visually" (unverifiable, unreproducible)
- "This can't be automated" (it almost always can)

This laziness was the root cause of the JS monolith degradation that triggered this entire framework. The V-Model only works if verification actually happens at every level.

#### The Verification Stack

Every V-Model level has tools that agents MUST use — not "should use" or "can use."

```
V-Model Level     Verification Tool           Agent Capability
─────────────     ─────────────────           ────────────────
Unit              go test / npm test           Native — no excuses
Integration       httptest / supertest         Native — no excuses
System            Playwright / gstack          Full system verification (functional, performance, security, failure modes)
Acceptance        Playwright + assertions      Browser + API + state verification
Performance       Benchmark tests / timing     Measurable — assert on metrics
Visual            Screenshots + diff           gstack --diff baselines
```

#### How It's Enforced

**In CLAUDE.md (soft constraint):**
```markdown
## Verification Protocol (mandatory)

After ANY code change, the agent MUST:
1. Run unit tests: `go test ./... -count=1`
2. Run browser tests: `npx playwright test` or `gstack browse`
3. Verify affected surfaces load and function
4. If a fit criterion is testable, write an automated test — NEVER ask the user to verify

"I can't automate this" is not acceptable unless:
- It requires physical hardware (RF emissions, thermal testing)
- It requires a human judgment call (UX feel, brand consistency)
- It requires external service credentials the agent doesn't have

Everything else is automatable. Use Playwright, gstack, curl, WebSocket clients,
or custom scripts. The agent has the tools — use them.
```

**In DAL profiles (hard constraint):**

```yaml
profiles:
  C:  # moderate
    verification:
      unit: required          # go test / npm test
      integration: required   # httptest
      system: required          # Playwright / gstack — functional + failure modes
      acceptance: required    # Fit criteria assertions
      manual: forbidden       # No "please check manually"

  A:  # catastrophic
    verification:
      unit: required
      integration: required
      system: required
      acceptance: required
      performance: required   # Benchmark assertions
      visual: required        # Screenshot diff baselines
      mutation: required      # Stryker / go-mutesting
      manual: forbidden
```

**In the `verify-change` skill (enforced workflow):**

```
After any code change:
1. Identify affected URs and TCs (from volere trace)
2. For each affected fit criterion:
   a. Does an automated test exist? → Run it
   b. No test exists? → Write one (TDD)
   c. Can't be automated? → Document WHY with specific reason
3. Run full verification stack for the DAL level
4. Report: which fit criteria verified, which need human review (with justification)
```

**In hooks (blocking):**

The `check-fit-criteria` pre-push hook verifies that:
- Changed code has corresponding test coverage
- Tests actually run (not just exist)
- No fit criterion is marked "manually verified" without a documented exception

#### Browser Testing Tools

The framework supports multiple browser automation approaches:

| Tool | Strength | When to use |
|------|----------|-------------|
| **Playwright** | Full browser automation, network interception, multi-browser | System tests, CI pipelines |
| **gstack** | CLI headless browser, ref-based selection, diff baselines, low token cost | Agent-driven acceptance testing, visual verification |
| **Playwright MCP** | Browser automation via MCP protocol | Real-time debugging, exploratory testing |

Agents choose the right tool for the job. The framework doesn't prescribe which — it prescribes that browser verification MUST happen, not "should" happen.

#### The Rule

> **If a fit criterion is testable, it MUST have an automated test. "Manually verified" is a bug in the verification process, not a valid status.**
>
> Exceptions require documented justification: physical hardware, human judgment, or missing credentials. "It's hard to automate" is not a justification — it's a skill gap the agent must close.

### 7. Regulatory Compliance Framework

Multi-dimensional acceptance is a core requirement (Pain Point 6 from discovery). A single requirement may need fit criteria across user, regulatory, security, and safety dimensions.

#### How It Works

**Compliance profiles** define which regulatory dimensions apply to a project:

```yaml
# .volere/compliance.yaml
dimensions:
  - id: fcc-part15
    name: FCC Part 15 (Unintentional Radiators)
    standard: 47 CFR Part 15
    applies_to: [performance, operational]    # Volere requirement types
    verification: [test, demonstration]       # DO-178C verification methods
    evidence_required: true                   # Must produce audit trail
    agent: rf-engineer                        # Specialist role for review

  - id: red-2014-53
    name: EU Radio Equipment Directive
    standard: Directive 2014/53/EU
    applies_to: [performance, security, operational]
    verification: [test, demonstration, analysis]
    evidence_required: true
    agent: regulatory-specialist

  - id: iec-62443
    name: Industrial Cybersecurity
    standard: IEC 62443
    applies_to: [security]
    verification: [test, analysis, review]
    evidence_required: true
    agent: security-engineer

  - id: iec-61508
    name: Functional Safety
    standard: IEC 61508
    applies_to: [functional, performance, operational, maintainability]
    verification: [test, analysis, review, formal-methods]
    evidence_required: true
    sil: 2                                    # Safety Integrity Level
    agent: compliance-officer
```

**Requirement cards carry per-dimension fit criteria:**

```yaml
id: UR-042
fit_criteria:
  user:
    criterion: "Device responds to commands within 200ms"
    verification: test
    test_type: performance
  fcc-part15:
    criterion: "Conducted emissions below 47 CFR 15.107 limits at all operating modes"
    verification: demonstration
    test_type: lab-test
    lab: accredited-test-lab              # Cannot be self-tested
    evidence: test-report                 # Produces audit artifact
  iec-62443:
    criterion: "Command interface rejects unauthenticated requests"
    verification: test
    test_type: integration
```

**Verification methods** (from DO-178C, applicable across domains):

| Method | What it proves | Automated? |
|--------|---------------|------------|
| **Test** | Behavior matches criterion | Yes (unit, integration, system) |
| **Analysis** | Design satisfies criterion by reasoning | Partial (static analysis, formal methods) |
| **Review** | Expert confirms criterion is met | No (agent team or human) |
| **Demonstration** | System shown to work in representative conditions | Partial (lab tests, simulation) |

**Evidence chain** (inspired by OSCAL):

```
Requirement (fit criterion)
  → Verification plan (which method, who, when)
  → Verification result (pass/fail, date, evidence)
  → Evidence artifact (test report, analysis document, review record)
```

Each verification result is stored as a YAML file:

```yaml
# docs/evidence/UR-042-fcc-part15.yaml
requirement: UR-042
dimension: fcc-part15
criterion: "Conducted emissions below 47 CFR 15.107 limits"
method: demonstration
status: passed
date: 2026-04-15
evidence:
  type: test-report
  lab: "TÜV Rheinland, ref: TR-2026-04-1234"
  path: docs/evidence/reports/fcc-part15-conducted.pdf
verified_by: rf-engineer
notes: "All operating modes tested. Margin: 6dB at 150kHz."
```

**The `volere coverage` CLI shows compliance status per dimension:**

```
$ volere coverage --dimension fcc-part15

FCC Part 15 Coverage
  UR-042: ✓ passed (TÜV report 2026-04-15)
  UR-043: ✗ not tested
  UR-044: ○ not applicable

  Coverage: 1/2 (50%)
  Missing: UR-043 — conducted emissions at max power
```

**Agent team review includes compliance dimension:**

When `review-requirements` runs on a project with compliance profiles, the compliance-officer and domain specialist (rf-engineer, security-engineer, etc.) are automatically included in the review team. They verify:
1. Are all compliance dimensions covered by fit criteria?
2. Are the verification methods appropriate for the standard?
3. Is evidence sufficient for certification/audit?

#### Evidence Lifecycle

Evidence is proof that a fit criterion was verified. The lifecycle:

```
1. PLANNED    — fit criterion exists, verification method chosen, no evidence yet
2. COLLECTED  — evidence artifact exists (test report, analysis doc, review record)
3. VERIFIED   — evidence reviewed and accepted (by agent or human)
4. EXPIRED    — requirement or code changed since evidence was collected → re-verify
```

**Directory structure:**

```
docs/evidence/
├── index.yaml                           # Evidence manifest — all evidence records
├── automated/                           # From CI/test runs (generated, not hand-written)
│   ├── UR-027-cors-2026-03-30.yaml     # Auto-generated from test results
│   └── UR-028-validation-2026-03-30.yaml
├── manual/                              # From lab tests, reviews, demonstrations
│   ├── UR-042-fcc-part15-2026-04-15.yaml
│   └── UR-042-red-2026-04-20.yaml
└── reports/                             # Binary evidence artifacts (PDFs, images)
    ├── fcc-part15-conducted.pdf
    └── red-essential-requirements.pdf
```

**Evidence record format:**

```yaml
# docs/evidence/automated/UR-027-cors-2026-03-30.yaml
requirement: UR-027
dimension: security
criterion: "Non-mesh origin requests receive no CORS headers"
method: test
status: verified              # planned | collected | verified | expired

collected:
  date: 2026-03-30T14:23:00Z
  by: steve (CTO agent)
  source: go test ./internal/auth/ -run TestCORS -v
  result: PASS
  tests_run: 6
  tests_passed: 6

verified:
  date: 2026-03-30T14:25:00Z
  by: steve (CTO agent)
  method: automated            # automated | human-review | lab-test

expires_when:
  - file_changed: internal/auth/cors.go
  - requirement_changed: UR-027
  # When either condition is true, status → expired, re-verification required
```

**Automated evidence collection:**

For fit criteria verified by tests (`verification: test`), evidence is generated automatically:
1. `volere validate` runs the tests
2. If tests pass, creates/updates the evidence record in `docs/evidence/automated/`
3. Sets `expires_when` triggers based on affected files
4. On next `volere validate`, checks if triggers fired → marks expired if so

**Manual evidence collection:**

For fit criteria verified by demonstration, review, or lab test:
1. Agent or human creates evidence record in `docs/evidence/manual/`
2. Attaches report artifact in `docs/evidence/reports/` (PDF, image, etc.)
3. `volere coverage --dimension` shows the evidence status
4. Expiry is tracked the same way — code/requirement changes expire the evidence

**Evidence retention:**
- Evidence records are git-committed (YAML files, small)
- Binary reports (PDFs) are git-committed if < 10MB, otherwise referenced by external URL
- Old evidence is never deleted — git history preserves it. Current evidence is what's in HEAD.
- `volere evidence prune` removes evidence for deleted/deprecated requirements

**Audit output:**

```
$ volere evidence --dimension fcc-part15

FCC Part 15 Evidence — thul-product

  UR-042  Conducted emissions:
    Status: VERIFIED
    Lab: TÜV Rheinland (ref: TR-2026-04-1234)
    Date: 2026-04-15
    Report: docs/evidence/reports/fcc-part15-conducted.pdf
    Expires when: UR-042 changes or hardware revision

  UR-043  Radiated emissions:
    Status: PLANNED
    Lab: (not yet scheduled)
    Next action: Schedule test at accredited lab

  Summary: 1/2 verified (50%)
```

#### What Ships When

| Version | Compliance feature |
|---------|-------------------|
| v0.1 | Multi-dimensional `fit_criteria` in YAML schema (the structure) |
| v0.3 | Compliance agents included in review teams when profiles are active |
| v0.8 | Compliance profiles, evidence chain, `volere coverage --dimension`, evidence lifecycle |
| v0.9 | Automated evidence collection from CI, `volere evidence` CLI |
| v1.0 | Pre-built profiles for security baseline (IEC 62443), FCC Part 15, RED |

#### What This Is NOT

- Not a certification tool — it doesn't replace test labs or notified bodies
- Not a regulatory database — it doesn't track which standards apply to which product category
- Not legal advice — it structures the evidence, it doesn't interpret the law
- It IS a traceability and evidence management system that makes audits predictable

### 8. Project Constitution (built-in)

Defines minimum content standards for:
- `CLAUDE.md` — Architecture, Testing, Conventions sections
- `ARCHITECTURE.md` — System diagram, design decisions, module boundaries
- `README.md` — What, install, run
- `docs/requirements/` — Volere-format URs with fit criteria

Staleness check: warns if docs are 30+ days older than latest code commit.

### 9. CLI

```bash
volere init [--dal C]              # Scaffold project with DAL profile
volere new [--type functional]     # Create new requirement card
volere trace                       # Show traceability matrix (UR → code → test)
volere coverage                    # Which fit criteria have tests?
volere impact <UR-id>              # What breaks if this requirement changes?
volere validate                    # Run all verification checks
volere review                      # Generate team review prompt
```

#### CLI Output Specifications

**`volere trace`** — Traceability matrix showing requirement → code → test linkage:

```
$ volere trace

Traceability Matrix — thul-studio (43 URs, 12 TCs)

UR-01  Browser access to sessions
  ├── Code: internal/api/terminal.go, internal/api/static.go
  ├── Tests: test/go-server.go-e2e.js (surface loading)
  ├── Fit criteria: 3/3 covered
  └── Status: ✓ TRACED

UR-02  Multiple concurrent sessions
  ├── Code: internal/session/manager.go, internal/session/port.go
  ├── Tests: internal/session/manager_test.go (5), internal/api/sessions_test.go (3)
  ├── Fit criteria: 4/4 covered
  └── Status: ✓ TRACED

UR-27  CORS and CSP hardening
  ├── Code: internal/auth/cors.go
  ├── Tests: internal/auth/cors_test.go (6)
  ├── Fit criteria: 3/3 covered
  └── Status: ✓ TRACED

TC-05  Idle state debounce
  ├── Code: internal/session/tmux.go:81-83
  ├── Tests: (none)
  ├── Fit criteria: 0/1 covered
  └── Status: ✗ GAP — DAL-A priority

Summary: 43 URs + 12 TCs = 55 requirements
  Traced: 48 (87%)    Gaps: 7 (13%)    Orphaned code: 0
```

**`volere coverage`** — Fit criteria coverage with per-dimension breakdown:

```
$ volere coverage

Fit Criteria Coverage — thul-studio

                          User  Security  Operational  Regulatory
  Total fit criteria:      43       8          12          0
  With automated tests:    38       7           9          0
  With manual evidence:     0       0           0          0
  Uncovered:                5       1           3          0

  Overall: 54/63 (86%)

  Uncovered (prioritized by DAL):
    DAL-A  TC-05   Idle debounce (user)
    DAL-B  UR-22   Crash recovery — launchd restart (operational)
    DAL-B  UR-35   Session reconciliation (operational)
    DAL-C  UR-14   CLI latency < 5s (user)
    DAL-C  TC-08   STUDIO_SESSION_ID env var (user)
    DAL-C  TC-09   Context persistence through idle (user)
    DAL-D  UR-24   Response latency < 25s (user)
    DAL-D  UR-13   Browser close/reopen persistence (operational)
    DAL-D  UR-07   Cross-machine peer health (operational)

$ volere coverage --dimension security

Security Coverage — thul-studio

  UR-21   HMAC verification:     ✓ tested (internal/a2a/handler_test.go)
  UR-23   Bearer token auth:     ✓ tested (internal/auth/middleware_test.go)
  UR-27   CORS restriction:      ✓ tested (internal/auth/cors_test.go)
  UR-27   CSP headers:           ✓ tested (internal/auth/cors_test.go)
  UR-28   Input validation:      ✓ tested (internal/api/sessions_test.go)
  UR-28   Broadcast size limit:  ✓ tested (internal/api/sessions_test.go)
  UR-33   Secrets in source:     ✗ no pre-commit hook installed
  TC-04   Cache-Control:         ✓ tested (internal/api/static_test.go)

  Coverage: 7/8 (88%)
```

**`volere impact`** — Dependency graph traversal with suspect link identification:

```
$ volere impact UR-03

Impact Analysis — UR-03 (Session state at a glance)

  Direct dependents:
    ├── UR-16  Response extraction (depends_on: UR-03)
    ├── UR-19  Context summary (uses state detection)
    └── TC-05  Idle debounce (serves: UR-03)

  Transitive dependents:
    ├── UR-24  Chat response latency (depends on UR-16 → UR-03)
    └── TC-09  Context persistence (serves: UR-19 → UR-03)

  Affected tests:
    ├── internal/session/state_test.go (18 tests)
    ├── internal/a2a/handler_test.go (idle debounce)
    └── test/go-server.go-e2e.js (state rendering)

  Affected code:
    ├── internal/session/state.go
    ├── internal/session/tmux.go:81-83 (debounce logic)
    └── grid/index.html (state badge rendering)

  If UR-03 changes:
    → 5 requirements become SUSPECT (review for consistency)
    → 3 test files must be re-run
    → 3 code files may need updates

  Run: volere validate --suspects to check resolution status
```

**`volere validate`** — Runs all verification checks and reports status:

```
$ volere validate

Volere Validation — thul-studio (DAL-C)

  Schema validation:
    ✓ 43 URs pass schema validation
    ✓ 12 TCs pass schema validation
    ✓ context.yaml is valid

  Traceability:
    ✓ All URs have at least one code file
    ✗ 7 fit criteria have no test (see volere coverage)
    ✓ All TCs trace to at least one UR

  Suspect links:
    ✓ No unresolved suspect links

  Project constitution:
    ✓ CLAUDE.md has required sections
    ✓ ARCHITECTURE.md has required sections
    ✓ README.md has required sections
    ✗ ARCHITECTURE.md is 45 days stale (last code change: 2 days ago)

  Hooks:
    ✓ check-secrets installed
    ✓ check-traceability installed
    ✗ check-fit-criteria not installed (required for DAL-C)

  Overall: 3 issues found
    1. 7 uncovered fit criteria (run volere coverage)
    2. ARCHITECTURE.md stale (update documentation)
    3. check-fit-criteria hook not installed (run volere hooks install)
```

**`volere init`** — Interactive scaffold with output:

```
$ volere init --dal C

Scaffolding project with DAL-C profile...

  Created: docs/requirements/README.md
  Created: docs/requirements/context.yaml (edit stakeholders, scope, glossary)
  Created: .volere/profile.yaml (DAL-C)
  Created: .volere/boundaries.yaml (edit module rules)
  Created: CLAUDE.md (skeleton — fill in Architecture, Testing, Conventions)
  Created: ARCHITECTURE.md (skeleton — fill in system diagram, decisions)

  Installed hooks:
    ✓ check-secrets (pre-commit)
    ✓ check-traceability (pre-commit)

  Not installed (DAL-C optional):
    ○ check-fit-criteria (install with: volere hooks install fit-criteria)

  Next steps:
    1. Edit docs/requirements/context.yaml (stakeholders, scope, glossary)
    2. Run: volere new --type functional (write your first requirement)
    3. Edit CLAUDE.md and ARCHITECTURE.md with project details

  Run: volere validate to check project health
```

**`volere new`** — Creates a requirement card:

```
$ volere new --type functional

Created: docs/requirements/UR-001.yaml

  Edit the file to fill in:
    - title (one line)
    - description (what the system must do)
    - rationale (why — the pain that created it)
    - fit_criteria (measurable acceptance conditions)
    - dal (A-E based on risk)
    - priority (must/should/could/wont)
    - origin (who requested, when, trigger)

  Validate: volere validate --file docs/requirements/UR-001.yaml

$ volere new --type technical-constraint --serves UR-003

Created: docs/requirements/TC-001.yaml (serves: [UR-003])
```

#### CLI Storage Format

The traceability matrix is not stored — it's computed on demand from:
- YAML requirement cards (source of truth for requirements)
- Git (source of truth for code)
- Test files (source of truth for verification)
- `.volere/trace-cache.json` (optional cache, regenerated by `volere trace --rebuild`)

This avoids the stale-matrix problem. The matrix is always fresh because it reads from the actual artifacts.

## Incremental Delivery

| Version | What ships | Value |
|---------|-----------|-------|
| **v0.1** | YAML schema + `volere init` scaffold + `write-requirement` skill | Machine-readable requirements, project structure |
| **v0.2** | `check-secrets` hook + `check-traceability` hook | Hard enforcement at commit time |
| **v0.3** | `review-requirements` skill + team prompt templates | Agent team reviews from proven patterns |
| **v0.4** | `trace-codebase` skill + `audit-tests` skill | Codebase mapping and test theater detection |
| **v0.5** | `volere trace` + `volere coverage` CLI | Traceability visibility |
| **v0.6** | DAL profiles + `classify-risk` skill | Graduated verification |
| **v0.7** | `volere impact` (suspect link management) | Change impact awareness |
| **v0.8** | Compliance profiles (security baseline) | Regulatory dimension support |
| **v1.0** | Full framework with docs | Production-ready |

## What This Is NOT

- Not a commercial ALM product (DOORS, Jama, Polarion)
- Not a replacement for CI/CD — it extends CI with requirements-aware checks
- Not a code generator — it generates requirements and verification structure
- Not prescriptive about tech stack — works with any language/framework

## Architecture

```
volere@ulleberg (plugin)
├── skills/
│   ├── write-requirement/skill.md
│   ├── review-requirements/skill.md
│   ├── trace-codebase/skill.md
│   ├── audit-tests/skill.md
│   └── classify-risk/skill.md
├── hooks/
│   ├── check-traceability.sh
│   ├── check-fit-criteria.sh
│   └── check-secrets.sh
├── templates/
│   ├── project-scaffold/
│   │   ├── docs/requirements/README.md
│   │   ├── .volere/profile.yaml
│   │   ├── .volere/boundaries.yaml
│   │   ├── CLAUDE.md.template
│   │   └── ARCHITECTURE.md.template
│   ├── requirement-card.yaml
│   └── technical-constraint.yaml
├── schema/
│   ├── requirement.schema.json
│   └── profile.schema.json
├── cli/
│   └── volere                    # Shell script wrapping skills + schema validation
└── README.md
```

## Dependencies

- Claude Code v2.1.32+ (agent teams support)
- `gitleaks` (for check-secrets hook) — optional, degrades gracefully
- No runtime dependencies — skills are prompt files, hooks are shell scripts

## Acceptance Testing

The framework must eat its own dogfood. Every version is acceptance-tested against fit criteria before release — no "light" acceptance.

### Per-Version Acceptance Protocol

Each version ships with:
1. **Fit criteria** for every component in that version (written as YAML snow cards using the framework's own schema)
2. **Acceptance tests** that verify each fit criterion — automated where possible, scripted manual where not
3. **Validation run** on a real project (not a toy example) before release

### Version-Specific Acceptance

| Version | Acceptance Test |
|---------|----------------|
| **v0.1** | `volere init` on a fresh repo produces valid structure. `write-requirement` skill produces a YAML card that passes JSON Schema validation. Run on a new thul-* project. |
| **v0.2** | `check-secrets` hook blocks a commit containing a test secret. `check-traceability` hook warns on a commit with no UR reference. Tested on thul-studio. |
| **v0.3** | `review-requirements` produces review quality comparable to thul-studio Pass 1 (scored by synthesis agent on specificity, testability, cross-document coherence). Run on a project with 10+ URs. |
| **v0.4** | `trace-codebase` identifies known dead code and test theater in a project with planted examples. `audit-tests` correctly classifies VERIFIES vs THEATER. Run on thul-studio as regression. |
| **v0.5** | `volere trace` output matches manual traceability matrix. `volere coverage` correctly reports uncovered fit criteria. Verified against thul-studio's 43 URs. |
| **v0.6** | DAL-E project has no blocking hooks. DAL-A project blocks on missing tests. `classify-risk` assigns correct DAL to 10 test cases spanning CSS changes to DB migrations. |
| **v0.7** | `volere impact UR-03` correctly identifies all downstream URs, TCs, and test files. Verified against thul-studio's known dependency graph. |
| **v0.8** | Security baseline profile catches 5 planted security violations. Profile can be applied to existing project without breaking CI. |
| **v1.0** | Full framework applied to a new project from scratch. Project goes from zero to structured requirements, enforced architecture, and traced tests in one session. |

### Regression

Each version's acceptance tests become regression tests for subsequent versions. By v1.0, the accumulated acceptance suite covers all components.

### The Rule

> No version is released until its acceptance tests pass on a real project. "Tests pass" means fit criteria are verified, not just "no errors."

## Success Criteria

The framework is successful when:
1. A new thul-* project can be scaffolded with `volere init` and immediately has requirements structure, enforcement hooks, and a CI template
2. An agent team can review requirements using `review-requirements` and produce the same quality output as thul-studio Pass 1
3. A codebase can be traced using `trace-codebase` and produce the same quality output as thul-studio Pass 2
4. Test theater is caught before it accumulates — `audit-tests` flags tests that don't verify fit criteria
5. The framework works for Thomas's next 3 projects without modification to the plugin itself
