# Architecture

## Overview

This repo serves two purposes:
1. **Archive** — the original Volere Requirements Template v15 (2010) and supporting materials
2. **Framework** — the Volere Agentic Framework, a Claude Code plugin that brings structured requirements engineering and V-Model verification to agentic software development

## Structure

```
volere-requirement/
├── a–i                              Original Volere template files (PDF, DOC, XLS)
├── docs/
│   ├── problem.md                   Discovery: problem space exploration
│   ├── brief.md                     Define: distilled problem statement
│   ├── options/                     Develop: three competing approaches
│   ├── decisions.md                 All decisions with rationale
│   ├── spec.md                      Build spec for the framework
│   ├── project-constitution.md      Minimum content standards for project docs
│   ├── team-prompt-*.md             Proven agent team prompts
│   └── execution-*.md              Phase execution prompts
├── plugin/                          The Volere Agentic Framework (v0.1–v0.9)
│   ├── schema/                      4 JSON Schemas
│   │   ├── requirement.schema.json  Snow card + cross_verify + verification_method
│   │   ├── profile.schema.json      DAL profiles + verification_commands
│   │   ├── compliance.schema.json   Compliance dimensions
│   │   └── evidence.schema.json     Evidence lifecycle + verification_level
│   ├── skills/                      5 Claude Code skills
│   │   ├── write-requirement/       Card format + cross-impact prompt
│   │   ├── review-requirements/     3 review types + zero-agent mode
│   │   ├── trace-codebase/          Map code→requirements, find dead code
│   │   ├── audit-tests/             VERIFIES/SUPPORTS/THEATER + verification levels + loopback
│   │   └── classify-risk/           DAL scoring + browser-facing escalation
│   ├── hooks/                       6 git hooks (full lifecycle)
│   │   ├── check-secrets.sh         Pre-commit: block secret patterns
│   │   ├── check-traceability.sh    Commit-msg: warn/block missing requirement IDs
│   │   ├── check-fit-criteria.sh    Pre-push: configurable verification commands
│   │   ├── check-checkout.sh        Post-checkout: requirement drift detection
│   │   ├── check-merge.sh           Post-merge: suspect links + cross-verify
│   │   ├── install.sh               Hook installer with chaining (5 hooks)
│   │   └── test-hooks.sh            16/16 test suite
│   ├── cli/                         CLI tooling
│   │   ├── volere                   7 commands (init, new, validate, trace, coverage, impact, review)
│   │   └── suspect.sh               Suspect link state management
│   ├── catalogs/                    Shared requirement catalogs
│   │   └── security-baseline.yaml   5 security requirements from thul-studio
│   ├── templates/                   Project scaffold + card templates + retrofit guide
│   │   ├── project-scaffold/        volere init output + RETROFIT.md for existing projects
│   │   ├── requirement-card.yaml    UR template
│   │   ├── technical-constraint.yaml TC template
│   │   ├── business-use-case.yaml   BUC template
│   │   ├── product-use-case.yaml    PUC template
│   │   ├── compliance-profile.yaml  Compliance dimension template
│   │   ├── imports.yaml             Catalog import template
│   │   └── evidence/                Evidence record template
│   ├── requirements/                Framework's own requirements (dogfooding)
│   └── validate.sh                  Card validator (Node.js, no external deps)
├── CLAUDE.md
├── ARCHITECTURE.md                  This file
└── README.md
```

## V-Model Mapping

The framework maps Volere's requirement structure to the V-Model's definition and verification levels:

```
V-Model Left (Definition)              V-Model Right (Verification)
──────────────────────────              ────────────────────────────

Stakeholder Needs                       Validation
  context.yaml (§1-5)                   "Are we building the right thing?"
         │
Business Use Cases (BUC-xxx, §7)        Acceptance Tests
  Why do these requirements exist?       "Does the system support the business?"
         │
Product Use Cases (PUC-xxx, §8)         System Tests
  What does the user do?                 "Does the system work as a whole?"
         │
User Requirements (UR-xxx, §9-17)       System Tests
  What must the system do?               Functional + non-functional verification
         │
Architecture Design                     Integration Tests
  ARCHITECTURE.md, boundaries.yaml       Module boundary verification
  contracts/                             Interface contract verification
         │
Detailed Design                         Unit Tests
  Technical Constraints (TC-xxx)         Component-level verification
  CLAUDE.md (conventions)
         │
Implementation                          Static Analysis
  Source code                            Linting, type checking, pre-commit hooks
```

## Design Principles

### Chesterton's Fence

> "Don't remove a fence until you know why it was built."

The Volere framework has been refined over 30 years (1995-2025). When we modernise it for agentic development, we keep every element until we've proven it's unnecessary — not the other way around.

Specific applications:
- **BUCs and PUCs are included** even though small projects may not need them. Volere included them for a reason (business context and user flow decomposition). We don't remove them because "our projects are small." We include them and let projects discover whether they need them.
- **All 9 non-functional requirement types** (§10-17) are in the schema even though most projects use only 3-4. Removing "cultural" or "legal" because they seem rare means you won't have them when you need them.
- **Satisfaction/dissatisfaction scores** (Kano model) are in the schema because Volere included them for prioritisation. We haven't proven they're unnecessary.

### Soft + Hard at Every Level

The core insight from thul-studio validation: **CLAUDE.md (soft) without CI/hooks (hard) = drift.**

Every V-Model level needs both:
- **Instruction** (what agents should do) — skills, CLAUDE.md, templates
- **Enforcement** (what agents must do) — hooks, CI checks, test gates

Soft constraints teach. Hard constraints enforce. Neither alone is sufficient.

### Autonomous Verification

Agents perform ALL verification from unit through acceptance autonomously. The tools (Playwright, gstack, curl, WebSocket clients) are good enough. "Please verify manually" is not an acceptable output.

Three exceptions: physical hardware, human judgment calls, missing external credentials. Everything else is automatable.

### Graduated Rigour (DAL)

Not every change needs the same verification. DAL levels (A through E) scale effort to risk:
- DAL-E (cosmetic): linting only
- DAL-C (moderate): unit + integration + system tests + code review
- DAL-A (catastrophic): full verification stack + mutation testing + multi-agent review

### Requirements Before Code

The framework enforces Volere's discipline: understand the problem (BUCs), define the interactions (PUCs), specify what's needed (URs with fit criteria), THEN build. Agents that jump to code without requirements produce monoliths, test theater, and interface drift.

### Dogfooding

The framework's own requirements are written as YAML snow cards using the framework's own schema. Every version is acceptance-tested on a real project before release. The framework that teaches agents to write proper fit criteria has proper fit criteria itself.

## Design Decisions

1. **YAML over Markdown for requirement cards** — machine-parseable, JSON Schema validatable, git-diffable. Markdown is human-friendly but agents need structure.

2. **Files over database** — requirements live as individual YAML files in git. No external ALM tool required. Traceability matrix is computed on demand, not stored.

3. **Plugin architecture** — ships as skills + hooks + templates, not a monolithic tool. Projects adopt incrementally.

4. **Preserve original Volere files** — the a-i prefixed files are the original template. They're the foundation this framework builds on.

5. **Multi-dimensional fit criteria** — one requirement, multiple acceptance dimensions (user, security, operational, regulatory). Inspired by regulated industries where a single requirement must satisfy multiple acceptance conditions simultaneously. Pre-built profiles for specific standards (FCC, RED, IEC 61508) are planned for v1.1.

6. **Evidence chain** — verification results are stored as YAML with expiry triggers. When code or requirements change, evidence expires and re-verification is required. Inspired by OSCAL and DO-178C.
