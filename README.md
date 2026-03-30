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
- **Compliance profiles** — FCC, RED, IEC 62443, IEC 61508 (v0.8)

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

**Chesterton's fence** — Volere has been refined over 30 years. We keep every element until we've proven it's unnecessary, not the other way around.

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
