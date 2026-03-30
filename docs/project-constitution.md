# Project Constitution (Draft)

## Status: Placeholder — to be developed as part of the Volere Agentic Framework

## Purpose

Defines the minimum content standards for project documentation files across the thul ecosystem. These files are the V-Model definition artifacts — agents read them before working. Their quality directly affects agent output quality.

Studio's UR-20 enforces this standard. Doc-health validates it monthly. CI checks it on push.

## Required Files and Minimum Content

### CLAUDE.md (Design Specification)
V-Model level: Design

Must contain:
- **Architecture overview** — what the system is, key components, how they connect
- **Testing** — how to run tests, what types exist, verification protocol
- **Conventions** — coding standards, naming, patterns specific to this project
- **Gotchas** — things that will bite you if you don't know them (load-bearing invariants)
- **Skills** — available skills and when to use them (if applicable)

Should contain:
- Git workflow conventions
- Deployment instructions
- Key file locations

### ARCHITECTURE.md (Architecture Specification)
V-Model level: Architecture

Must contain:
- **System diagram** — visual overview of components and their relationships
- **Design decisions** — key architectural choices with rationale
- **Module boundaries** — what depends on what, what's allowed to import what

Should contain:
- File map — where to find things
- Data flow — how information moves through the system
- Interface contracts — what each module provides and requires

### README.md (Project Overview)
V-Model level: Requirements (entry point)

Must contain:
- **What it is** — one paragraph
- **How to install** — 3 commands or less
- **How to run** — 3 commands or less

Should contain:
- Features list
- API reference (if applicable)
- Related repos / ecosystem context

### docs/requirements/ (Requirements Specification)
V-Model level: Requirements

Must contain (when project has URs):
- **user.md** — Volere-format requirements with: description, rationale, fit criteria, origin
- Each fit criterion must be testable (binary or measurable)

Should contain:
- **technical-constraints.md** — TC-prefixed derived requirements
- **reviews/** — review artifacts from agent team reviews

### .volere/ (Enforcement Configuration)
V-Model level: All (enforcement layer)

Should contain (when project uses the framework):
- **boundaries.yaml** — module dependency rules
- **budgets.yaml** — complexity, dependency, file size limits
- **profile.yaml** — DAL level, which checks are active

## Staleness Rule

If the latest code commit is more than 30 days newer than the latest documentation file change, the project is considered stale. This triggers a warning in UR-20 compliance checks and is flagged by doc-health.

## Validation

- **UR-20 (Studio)** — per-session compliance badge
- **Doc-health agent (thul-ops)** — monthly ecosystem-wide sweep
- **CI (future)** — content quality check on push
