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

### 6. Project Constitution (built-in)

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

## Success Criteria

The framework is successful when:
1. A new thul-* project can be scaffolded with `volere init` and immediately has requirements structure, enforcement hooks, and a CI template
2. An agent team can review requirements using `review-requirements` and produce the same quality output as thul-studio Pass 1
3. A codebase can be traced using `trace-codebase` and produce the same quality output as thul-studio Pass 2
4. Test theater is caught before it accumulates — `audit-tests` flags tests that don't verify fit criteria
5. The framework works for Thomas's next 3 projects without modification to the plugin itself
