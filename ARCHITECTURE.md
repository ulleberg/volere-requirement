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
│   ├── skills/                      9 Claude Code skills
│   │   ├── using-volere/            Session start: project detection, requirement gate, doc tracking
│   │   ├── extract-requirements/    Scan codebase → draft UR/TC cards → owner review
│   │   ├── simplify-requirements/   Reduce cards: delete, merge, question every card
│   │   ├── write-requirement/       Card format + cross-impact prompt
│   │   ├── review-requirements/     3 review types + zero-agent mode
│   │   ├── trace-codebase/          Map code→requirements, find dead code
│   │   ├── audit-tests/             VERIFIES/SUPPORTS/THEATER + verification levels + loopback
│   │   ├── classify-risk/           DAL scoring + browser-facing escalation
│   │   └── glossary/                Abbreviations, DAL levels, terminology reference
│   ├── hooks/                       7 git hooks (full lifecycle)
│   │   ├── check-secrets.sh         Pre-commit: block secret patterns
│   │   ├── check-simplicity.sh      Pre-commit: diff stats + simplicity check
│   │   ├── check-traceability.sh    Commit-msg: warn/block missing requirement IDs
│   │   ├── check-fit-criteria.sh    Pre-push: configurable verification commands
│   │   ├── check-checkout.sh        Post-checkout: requirement drift detection
│   │   ├── check-merge.sh           Post-merge: suspect links + cross-verify
│   │   ├── coverage-gaps.sh         SessionStart: report acceptance coverage
│   │   ├── install.sh               Hook installer with chaining
│   │   └── test-hooks.sh            52-test suite
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
│   ├── requirements/                Framework's own requirements (39 cards, dogfooding)
│   └── validate.sh                  Card validator (Node.js, no external deps)
├── CLAUDE.md
├── ARCHITECTURE.md                  This file
└── README.md
```

## V-Model Mapping

This framework's core contribution: connecting two proven disciplines for the first time.

- **Volere** (Robertson & Robertson, 1995) defines requirement types — BUC, PUC, UR, TC — with testable fit criteria. It says nothing about verification levels.
- **V-Model** (systems engineering) defines a symmetry between definition levels and verification levels. It says nothing about requirement formats.
- **This framework** maps each Volere requirement type to a V-Model verification level, creating a complete definition→verification chain for agentic development.

```
Volere (Definition)                    V-Model (Verification)
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

### Chesterton's Fence + Simplicity Criterion

> "Don't remove a fence until you know why it was built. Once you know why, ask whether the reason still holds and whether the cost is justified."

Two counterbalancing principles:

**Chesterton's Fence:** The Volere framework has been refined over 30 years (1995-2025). We keep every element until we've proven it's unnecessary — not the other way around. BUCs, PUCs, 9 non-functional types, satisfaction scores — all included because Volere included them for reasons developed over decades.

**Simplicity Criterion:** Every line of code and every document is a liability until verified, and a compounding liability if not maintained. Dead code traps agents into assuming it matters. Stale docs teach the wrong thing with authority. Every skill, hook, schema field, and CLI command must answer: "What breaks if this is removed?" If the answer is "nothing," it's a candidate for removal.

These aren't contradictions — they're a protocol. First ask "why was this built?" (Chesterton's Fence). Then ask "does that reason still justify the complexity cost?" (Simplicity Criterion). The first prevents premature removal. The second prevents permanent accumulation.

Learned from: karpathy/autoresearch achieves rigorous autonomous operation with 3 files and a 115-line skill. Radical constraint beats comprehensive coverage.

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
