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
    test_type: e2e

dal: C                    # A=catastrophic B=critical C=moderate D=minor E=cosmetic
priority: must            # must | should | could | wont
status: implemented       # proposed | implemented | verified | deprecated

origin:
  stakeholder: Thomas Ulleberg
  date: 2026-03-30
  trigger: "Session cards showing wrong state"
  source: UR-07           # traces to parent requirement

depends_on: [UR-038]
conflicts: []

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

### 5. DAL Profiles

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

### 6. Regulatory Compliance Framework

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
| **Test** | Behavior matches criterion | Yes (unit, integration, e2e) |
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

#### What Ships When

| Version | Compliance feature |
|---------|-------------------|
| v0.1 | Multi-dimensional `fit_criteria` in YAML schema (the structure) |
| v0.3 | Compliance agents included in review teams when profiles are active |
| v0.8 | Compliance profiles, evidence chain, `volere coverage --dimension` |
| v1.0 | Pre-built profiles for security baseline (IEC 62443), FCC Part 15, RED |

#### What This Is NOT

- Not a certification tool — it doesn't replace test labs or notified bodies
- Not a regulatory database — it doesn't track which standards apply to which product category
- Not legal advice — it structures the evidence, it doesn't interpret the law
- It IS a traceability and evidence management system that makes audits predictable

### 7. Project Constitution (built-in)

Defines minimum content standards for:
- `CLAUDE.md` — Architecture, Testing, Conventions sections
- `ARCHITECTURE.md` — System diagram, design decisions, module boundaries
- `README.md` — What, install, run
- `docs/requirements/` — Volere-format URs with fit criteria

Staleness check: warns if docs are 30+ days older than latest code commit.

### 7. CLI

```bash
volere init [--dal C]              # Scaffold project with DAL profile
volere new [--type functional]     # Create new requirement card
volere trace                       # Show traceability matrix (UR → code → test)
volere coverage                    # Which fit criteria have tests?
volere impact <UR-id>              # What breaks if this requirement changes?
volere validate                    # Run all verification checks
volere review                      # Generate team review prompt
```

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
