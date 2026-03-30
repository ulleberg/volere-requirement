# Volere Agentic Framework

Structured requirements engineering and V-Model verification for agentic software development. Built on the Volere Requirements Template (v15) by James & Suzanne Robertson.

## What This Is

A Claude Code plugin that makes quality the default path for AI agents. Agents that jump to code without requirements produce monoliths, test theater, and interface drift. This framework enforces the same discipline that works for human teams — structured requirements with testable fit criteria, systematic verification at every V-Model level, and graduated rigour based on risk.

## Quick Start

```bash
# Scaffold a new project
cp -r plugin/templates/project-scaffold/* your-project/

# Write your first requirement
# (Use the write-requirement skill in Claude Code, or copy the template)
cp plugin/templates/requirement-card.yaml your-project/docs/requirements/UR-001.yaml

# Validate
plugin/validate.sh your-project/docs/requirements/UR-001.yaml
```

## V-Model Decomposition

```
BUC  (Business Use Cases)     Why do these requirements exist?
 └── PUC  (Product Use Cases) What does the user do?
     └── UR  (User Requirements) What must the system do?
         └── TC  (Technical Constraints) What must the implementation guarantee?
```

Each level has testable fit criteria. Each level traces to the next. Each level has a corresponding verification level (acceptance → system → integration → unit tests).

## Framework Components

| Component | What it does |
|-----------|-------------|
| `plugin/schema/` | JSON Schema for requirement cards, DAL profiles, compliance, evidence |
| `plugin/skills/` | 5 skills: write-requirement, review-requirements, trace-codebase, audit-tests, classify-risk |
| `plugin/hooks/` | 4 hooks: check-secrets, check-traceability, check-fit-criteria, installer |
| `plugin/cli/volere` | CLI with 7 commands: init, new, validate, trace, coverage, impact, review |
| `plugin/catalogs/` | Shared requirement catalogs (security-baseline) |
| `plugin/templates/` | Project scaffold, BUC/PUC/UR/TC/evidence/compliance templates |
| `plugin/requirements/` | Framework's own requirements (dogfooding) |

## Key Features

- **Multi-dimensional fit criteria** — one requirement, multiple acceptance dimensions (user, security, operational, regulatory)
- **DAL levels (A-E)** — scale verification effort to risk, from linting-only to full multi-agent review
- **Autonomous verification mandate** — agents perform ALL testing, from unit through acceptance
- **Evidence chain** — verification results stored with expiry triggers for audit readiness
- **Compliance profiles** — generic compliance dimensions with evidence chain (v0.8); specific standard profiles (FCC, RED, IEC) planned for v1.1

## Proven By

- **thul-studio validation** — 26 URs strengthened to 43 URs + 12 TCs, 12,814 lines dead code removed, 23 security tests added via TDD
- **Experiment 001** (thul-agentic-research) — skilled agent teams produce 100% testable fit criteria and self-organize for cross-document coherence

## Original Volere Template

The original template files (2010) are preserved in the repo root:

| File | Description |
|------|-------------|
| `a–c` | Volere Template v15 (PDF + DOC) |
| `d–g` | Case studies (Library, Controller) |
| `h–i` | Atomic requirement spreadsheets (XLS) |

## Design Philosophy

**Chesterton's fence** — Volere has been refined over 30 years. We keep every element until we've proven it's unnecessary, not the other way around. BUCs, PUCs, satisfaction scores, 9 non-functional types — all included because they were included for a reason. Projects discover what they need; the framework doesn't pre-judge.

## Key Insights

These insights emerged from building and validating the framework on a real project (thul-studio: 43 URs, 12 TCs, 12,814 lines dead code removed, 23 security tests added).

**1. The "engineering manager" layer for agents is the missing piece.**
Agents can write code. Nothing forces them to write it *well*. Volere + V-Model provides the structural discipline that human engineering managers provide to human teams. The framework IS the engineering manager.

**2. Soft constraints without hard enforcement = drift.**
CLAUDE.md alone doesn't work. Agents respect hard failures (CI breaks, hook blocks) and ignore soft guidelines. Every V-Model level needs both columns: instruction (tells agents what to do) AND enforcement (catches when they don't).

**3. The snow card is already agent-ready.**
Volere's 30-year-old atomic requirement format maps almost perfectly to agent task definitions. Nobody had connected these dots. Description → what to build. Rationale → context for trade-offs. Fit criterion → acceptance test assertion.

**4. Skilled agent teams produce specifications, not just documents.**
Unskilled teams write parallel documents. Skilled teams write integrated specifications — cross-referencing, catching contradictions, self-organizing to produce coordination artifacts nobody asked for. (Proven in Experiment 001, thul-agentic-research.)

**5. Test theater is the silent killer.**
577 tests sound impressive. 23% actually verify fit criteria. The rest are theater — high coverage, low verification. Mutation testing and the VERIFIES/SUPPORTS/THEATER/REDUNDANT classification are essential.

**6. The mess is evidence — don't clean before you trace.**
Dead code reveals derived requirements. Unnecessary tests reveal test theater. Cleaning first destroys the signal. The sequence must be: requirements → trace → cleanup.

**7. Acceptance is multi-dimensional.**
A single requirement may need fit criteria across user, security, operational, and regulatory dimensions. Agents need to know which dimensions apply. This is where Volere's structured approach beats user stories and BDD. Compliance profiles for specific standards (FCC, RED, IEC) are planned for v1.1.

**8. Graduated rigour prevents both laziness and ceremony.**
DAL levels (A-E) scale verification to risk. A CSS fix doesn't need the same treatment as a database migration. Without this, the framework is either too heavy for small changes or too light for critical ones.

**9. Chesterton's fence applies to frameworks too.**
Volere included BUCs, PUCs, satisfaction/dissatisfaction scores, and 9 non-functional types for reasons developed over 30 years. We don't remove them because "our projects are small." We include them and let projects discover whether they need them.

**10. Agents are lazy — make the right path the only path.**
This was the trigger for the entire framework. A JS monolith degraded because agents chose the easy path. The framework's job is to make discipline the default, not the exception. Pre-commit hooks, not guidelines. Required system tests, not optional e2e. "Manually verified" is a bug in the process.

See `ARCHITECTURE.md` for the full design principles, V-Model mapping, and design decisions.

## Roadmap

| Version | Status | What ships |
|---------|--------|-----------|
| v0.1 | **Shipped** | Schema, scaffold, write-requirement skill, validator |
| v0.2 | **Shipped** | Pre-commit hooks (secrets, traceability), installer, 12/12 tests |
| v0.3 | **Shipped** | Agent team review skill (3 review types) |
| v0.4 | **Shipped** | Codebase trace + test audit skills |
| v0.5 | **Shipped** | CLI (init, new, validate, trace, coverage, impact, review) |
| v0.6 | **Shipped** | DAL profiles + classify-risk skill + check-fit-criteria hook |
| v0.7 | **Shipped** | Suspect link management (mark, resolve, auto, check) |
| v0.8 | **Shipped** | Compliance profiles, evidence chain, security baseline catalog |
| v0.9 | **Active** | Production hardening — validate on 3 real projects |
| v1.0 | Planned | Publish to thul-plugins marketplace as `volere@ulleberg` |
| v1.1 | Planned | Pre-built compliance profiles (FCC Part 15, RED 2014/53/EU, IEC 61508) |
