---
name: using-volere
description: Use when starting any conversation — establishes Volere Agentic Framework context, detects project state, and guides to the right skill
---

# Volere Agentic Framework

Structured requirements engineering and V-Model verification for agentic software development.

## Project State Detection

Check the project to determine what's needed:

| Condition | Action |
|-----------|--------|
| No `.volere/` or `docs/requirements/` | Not set up — suggest `volere init` or scaffold manually |
| `docs/requirements/` empty | Write requirements first — use `write-requirement` skill |
| Requirements exist, no `reviews/` | Run a review — use `review-requirements` skill |
| Reviews exist, code exists | Trace codebase — use `trace-codebase` skill |
| Tests exist | Audit test quality — use `audit-tests` skill |
| Making a change | Classify risk — use `classify-risk` skill |

## Core Principles

1. **Requirements before code.** Understand what to build before building it.
2. **Every fit criterion must be testable.** No vague words (should, appropriate, reasonable).
3. **Agents test everything autonomously.** "Manually verified" is a bug in the process.
4. **Soft + hard at every level.** CLAUDE.md instructs, hooks and CI enforce.
5. **Graduated rigour (DAL A-E).** Scale verification to risk.

## Requirement Gate

Before invoking `/brainstorm` or any implementation skill, identify which requirement card (UR/TC) the work serves. If no card exists, write the requirement first using `/write-requirement`. This ensures every piece of work has fit criteria and acceptance tests before implementation begins.

Without a card there are no fit criteria. Without fit criteria there are no acceptance tests. Without acceptance tests the work is untraceable.

## Doc Tracking

When creating a document intended to be maintained — presentations, API references, guides, runbooks — offer to add it to `.volere/profile.yaml` under the `docs:` field. This enables staleness detection by the SessionStart hook and `volere check-docs`.

Do NOT offer tracking for process artifacts (specs, plans, briefs, options, execution prompts). These are snapshots in time, not maintained documents.

## Available Skills

| Skill | When to use |
|-------|-------------|
| `write-requirement` | Writing or updating a requirement card |
| `extract-requirements` | Scanning an existing codebase to draft cards |
| `simplify-requirements` | Reducing card count by merging and deleting |
| `review-requirements` | Reviewing requirements with an agent team |
| `trace-codebase` | Mapping code to requirements |
| `audit-tests` | Finding test theater and coverage gaps |
| `classify-risk` | Assigning DAL level to a change |
| `glossary` | Abbreviations, DAL levels, terminology reference |

## Quick Reference

```
BUC (§7) — Why do these requirements exist?
PUC (§8) — What does the user do?
UR (§9-17) — What must the system do?
TC — What must the implementation guarantee?
DAL A-E — How much verification is needed?
```
