---
name: glossary
description: Displays the Volere Agentic Framework glossary — abbreviations, requirement types, DAL levels, test classifications, and V-Model terminology. Use when the user encounters unfamiliar abbreviations, asks what a term means, or needs a reference table.
---

# Glossary

Present the relevant section(s) based on what the user is working with. If they ask generally, show all tables.

## Requirement Types

| Abbreviation | Full Form | Meaning |
|-------------|-----------|---------|
| **BUC** | Business Use Case | Why requirements exist — business context (Volere §7) |
| **PUC** | Product Use Case | What the user does — interaction flows (Volere §8) |
| **UR** | User Requirement | What the system must do (Volere §9-17) |
| **TC** | Technical Constraint | What the implementation must guarantee — derived from URs |
| **SHR** | Stakeholder Requirement | High-level need — complex/regulated projects only (Volere §1-5) |
| **SEC** | Security Catalog Entry | Reusable security requirement from a shared catalog |

## Design Assurance Levels (DAL)

| Level | Impact if Failed | Verification Required | Example |
|-------|-----------------|----------------------|---------|
| **DAL-A** | Catastrophic — data loss, security breach, safety incident | Full stack + mutation testing + multi-agent review | Auth bypass, DB migration, encryption |
| **DAL-B** | Critical — service degradation, data corruption | Unit + integration + system + acceptance + performance | Session integrity, secrets handling, CORS |
| **DAL-C** | Moderate — feature broken, user impact | Unit + integration + system + code review | New feature, state detection, WebSocket |
| **DAL-D** | Minor — cosmetic, workaround exists | Unit + basic integration | Config defaults, log format, UI tweak |
| **DAL-E** | Cosmetic — no user impact | Linting + type checking | CSS fix, documentation, comment update |

## Priority (MoSCoW)

| Priority | Meaning |
|----------|---------|
| **must** | System doesn't work without it |
| **should** | Important, but system functions without it |
| **could** | Nice to have |
| **wont** | Not this version (documented for future) |

## Test Classifications

| Classification | Meaning | Action |
|---------------|---------|--------|
| **VERIFIES** | Test directly asserts a fit criterion condition | Keep — real acceptance test |
| **SUPPORTS** | Test checks implementation serving a criterion indirectly | Keep, consider rewriting to verify directly |
| **THEATER** | Test has no connection to any fit criterion | Remove — inflates coverage |
| **REDUNDANT** | Test duplicates another's coverage | Remove the weaker one |

## Verification Methods (DO-178C)

| Method | When Used |
|--------|-----------|
| **test** | Automated test asserts the condition |
| **analysis** | Documented reasoning proves the condition holds |
| **review** | Human or agent inspection confirms compliance |
| **demonstration** | Live operation proves the condition |

## V-Model Verification Levels

| Level | Question Answered | Who Cares |
|-------|------------------|-----------|
| **unit** | Does the function work? | The developer |
| **integration** | Do the components connect? | The architect |
| **system** | Does the system behave correctly? | The team |
| **acceptance** | Does the user get value? | The user |

## Requirement Card Fields

| Field | Required | Purpose |
|-------|----------|---------|
| `id` | Yes | Unique ID: `{PREFIX}-{NNN}` (e.g., UR-042, TC-005) |
| `type` | Yes | Volere type: functional, security, performance, etc. |
| `title` | Yes | One-line summary (max 100 chars) |
| `description` | Yes | What the system must do |
| `rationale` | Yes | Why this requirement exists |
| `fit_criteria` | Yes | Measurable acceptance conditions (at least one dimension) |
| `dal` | Yes | Design Assurance Level: A-E |
| `priority` | Yes | MoSCoW: must/should/could/wont |
| `status` | Yes | Lifecycle: proposed → implemented → verified → deprecated |
| `origin` | Yes | Who requested it, when, and what triggered it |
| `depends_on` | No | Requirements that must be satisfied first |
| `serves` | TC only | Which UR(s) this technical constraint serves |
| `cross_verify` | No | Requirements to re-verify when this one changes |
| `conflicts` | No | Requirements that can't coexist with this one |
| `decomposed_to` | No | Child requirements this breaks into |

## Traceability Statuses

| Status | Meaning |
|--------|---------|
| **TRACED** | Code clearly serves one or more URs/TCs |
| **ORPHANED** | No requirement found — candidate for dead code or missing requirement |
| **PARTIAL** | Some functions trace, others don't |
| **PROPOSED** | Serves a proposed (not yet implemented) requirement |
| **GAP** | Fit criterion has no test coverage |
