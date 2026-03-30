# Option A: Volere-Native — Modernise the Snow Card

## Approach

Start from Volere's proven atomic requirement format. Modernise the snow card into machine-readable YAML. Build a Claude Code plugin (skill + hooks + CI templates) that enforces V-Model verification at each level. The requirement card is the primary artifact — everything flows from it.

## How It Works

### 1. The Modernised Snow Card (YAML)

```yaml
# requirements/TR-042.yaml
id: TR-042
type: functional                    # Volere types 9-17
title: Session state detection accuracy
description: >
  The system shall correctly detect whether a terminal session
  is active, idle, or terminated within 2 seconds of state change.
rationale: >
  False positives in idle detection cause premature session cleanup,
  losing user work. See gotchas.md G-02 "Idle Flicker."
origin:
  stakeholder: Thomas Ulleberg
  source: UR-07                     # Traces to user requirement
  derived_from: []                  # Empty = original, not derived

fit_criteria:
  user:
    criterion: "95% of state transitions detected within 2s, 0% false positives over 1000 transitions"
    verification: test              # test | analysis | review | demonstration
    test_type: integration          # unit | integration | e2e | performance
  operational:
    criterion: "State detection works correctly during cross-machine deployment (M3→M4 sequencing)"
    verification: test
    test_type: e2e

dal: C                              # A=catastrophic, B=critical, C=moderate, D=minor, E=cosmetic
priority: must
conflicts: []
depends_on: [TR-038]               # Interface contract dependency

satisfaction: 5                     # 1-5 stakeholder happiness if implemented
dissatisfaction: 5                  # 1-5 stakeholder unhappiness if missing

history:
  - date: 2026-03-30
    action: created
    by: embedded-engineer
```

### 2. V-Model Enforcement Layers

```
requirements/*.yaml          ←→  tests/acceptance/    (from fit_criteria)
docs/ARCHITECTURE.md         ←→  .architecture/       (fitness functions)
docs/interfaces/*.yaml       ←→  tests/integration/   (contract tests)
src/                         ←→  tests/unit/          (TDD)
                             ←→  .pre-commit hooks    (linting, types)
```

Each layer has:
- **A definition artifact** (left side) — what the agent reads before working
- **A verification artifact** (right side) — what CI enforces after working
- **A skill** that teaches agents HOW to work at that level

### 3. Plugin Structure

```
volere-agentic/
├── skills/
│   ├── write-requirement/       # How to write a Volere YAML card
│   ├── derive-requirements/     # How to decompose UR → TR/SR/OR
│   ├── verify-requirement/      # How to generate test from fit criterion
│   ├── architecture-check/      # How to validate against fitness functions
│   └── dal-classify/            # How to assign DAL level to a change
├── hooks/
│   ├── pre-commit/
│   │   ├── check-traceability   # Every code change traces to a requirement
│   │   ├── check-coverage       # Fit criteria have corresponding tests
│   │   └── check-architecture   # No boundary violations
│   └── post-commit/
│       └── update-suspect-links # Flag affected requirements on change
├── templates/
│   ├── project-scaffold/        # Full V-Model project skeleton
│   ├── requirement-card.yaml    # Snow card template
│   └── ci-pipeline.yaml         # GitHub Actions with verification gates
├── cli/
│   └── volere                   # CLI for requirement operations
│       ├── init                 # Scaffold a new project
│       ├── trace                # Show traceability matrix
│       ├── impact               # Impact analysis: "what breaks if I change X?"
│       ├── coverage             # Which requirements have tests?
│       └── validate             # Run all verification checks
└── profiles/
    ├── minimal.yaml             # DAL-E: linting + types only
    ├── standard.yaml            # DAL-C: + unit tests + architecture checks
    ├── regulated.yaml           # DAL-A: + integration + acceptance + evidence chain
    └── compliance/
        ├── fcc-part15.yaml      # FCC-specific fit criteria templates
        ├── red-2014-53.yaml     # EU Radio Equipment Directive
        ├── iec-61508.yaml       # Functional safety
        └── iec-62443.yaml       # Cybersecurity
```

### 4. Agent Workflow

```
1. Human writes user requirements (or agents help via /discover)
2. Agent team derives TR/SR/OR from URs (proven in Experiment 001)
   - Each requirement gets a YAML snow card
   - Each card gets multi-dimensional fit criteria
   - DAL level assigned based on risk
3. Agent generates test skeletons from fit criteria
   - fit_criteria.user → acceptance test
   - fit_criteria.operational → integration test
   - fit_criteria.security → security test
4. Agent implements (TDD — test exists before code)
5. Pre-commit hooks enforce:
   - Code traces to a requirement
   - Architecture boundaries respected
   - Tests pass
6. CI pipeline runs full verification:
   - Acceptance tests (from fit criteria)
   - Fitness functions (architecture)
   - Mutation testing (test quality)
   - Suspect link check (impact analysis)
7. Human reviews at phase boundaries
```

## Strengths

- **Proven foundation.** Volere has 30 years of real-world use. The snow card format is battle-tested.
- **Requirement-first thinking.** Forces agents to understand WHAT before jumping to HOW.
- **Natural traceability.** Every artifact links back to a requirement ID. Git provides the audit trail.
- **Graduated rigour (DAL).** Small projects use `minimal.yaml`, regulated projects use `regulated.yaml`. Same framework, different intensity.
- **Multi-dimensional fit criteria.** One card, multiple acceptance dimensions — exactly what regulated products need.
- **Integrates with thul-agents.** Specialist roles (compliance-officer, security-engineer) each own their fit criteria dimension.

## Weaknesses

- **Upfront investment.** Writing YAML requirement cards before coding adds ceremony. For a quick prototype, this feels heavy.
- **Requirement quality bottleneck.** The framework is only as good as the requirements. Garbage in, garbage out — even with fit criteria.
- **YAML schema complexity.** The snow card has many fields. Agents might fill them poorly (satisfying the format without the intent).
- **No existing tooling.** The CLI, hooks, and CI templates all need to be built from scratch.
- **Traceability maintenance.** Suspect links and impact analysis require graph traversal logic — non-trivial engineering.

## Effort Estimate

- Snow card YAML schema + validation: Small
- Claude Code plugin (skills + hooks): Medium
- CLI (init, trace, impact, coverage): Medium
- CI pipeline templates: Small
- Compliance profiles: Large (per regulation)
- **Total: Medium-Large, but incremental — each piece delivers value independently**

## Best For

Projects where requirements clarity matters more than speed. Regulated products. Multi-agent teams. Long-lived codebases. "Agents as a Service" delivery.
