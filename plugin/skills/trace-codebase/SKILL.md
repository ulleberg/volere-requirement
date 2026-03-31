---
name: trace-codebase
description: Maps code files and tests to requirements. Use when tracing code to requirements, finding dead code, or before major refactoring. Delegates to review-requirements with trace review type.
---

# Trace Codebase

This skill is a shortcut to the **Trace Review (Pass 2)** in the `review-requirements` skill.

## What to do

Run `/review-requirements` and select or let it auto-detect the **Trace Review** type. This maps every source file and test to requirements, using agent teams to classify:

- Code: TRACED / ORPHANED / PARTIAL / PROPOSED (see `/glossary`)
- Tests: VERIFIES / SUPPORTS / THEATER / REDUNDANT (see `/glossary`)

## When to use this instead of volere trace

| Tool | What it does | When to use |
|------|-------------|-------------|
| `volere trace` (CLI) | Quick grep for requirement IDs in source/test files | Fast automated check, CI |
| `/trace-codebase` (this skill) | Deep agent-team analysis of every file | Before major refactoring, after requirements stabilize |

## Prerequisites

- At least 5 requirements in `docs/requirements/*.yaml`
- Requirements have been reviewed (run `/review-requirements` full review first)
- ARCHITECTURE.md exists and is current
- Codebase has tests
