# Volere Agentic Framework

Archive of the original Volere Requirements Template (v15) plus the Volere Agentic Framework — a Claude Code plugin for structured requirements engineering and V-Model verification in agentic software development.

## Architecture

- **Original Volere files (a–i)** — template, case studies, requirement stationery. Preserved as-is.
- **docs/** — discovery-to-delivery documentation: problem, brief, options, decisions, spec, roadmap, team prompts, execution plans.
  - **docs/insights/** — session insights from applying the framework to real projects. Research findings with framework action items. Read these before proposing changes to the framework — they contain lessons from production use.
- **plugin/** — the framework (v0.1–v0.8 shipped, v0.9 hardening):
  - `schema/` — 4 JSON schemas (requirement with cross_verify + verification_method, profile with verification_commands, compliance, evidence with verification_level)
  - `skills/` — 8 skills (extract-requirements, simplify-requirements, write-requirement, review-requirements, trace-codebase, audit-tests, classify-risk, glossary)
  - `hooks/` — 6 hooks (check-secrets, check-traceability, check-fit-criteria, check-checkout, check-merge, installer)
  - `cli/` — CLI with 7 commands + suspect link manager
  - `catalogs/` — shared requirement catalogs (security-baseline)
  - `templates/` — project scaffold, BUC/PUC/UR/TC/evidence/compliance templates, retrofit guide
  - `requirements/` — 39 cards dogfooding the framework (6 BUCs, 15 URs, 16 TCs), 29/29 tests, 41% coverage

See `ARCHITECTURE.md` for the full V-Model mapping, design principles, and design decisions.

## Key Concepts

- **Snow card** — Volere's atomic requirement format, modernised as YAML with multi-dimensional fit criteria
- **BUC** (Business Use Case, §7) — why requirements exist (business context)
- **PUC** (Product Use Case, §8) — what the user does (interaction flows)
- **UR** (User Requirement, §9-17) — what the system must do
- **TC** (Technical Constraint) — what the implementation must guarantee
- **DAL** (Design Assurance Level, A-E) — scales verification effort to risk
- **Fit criterion** — measurable condition defining when a requirement is satisfied
- **Suspect link** — a downstream requirement that needs re-verification after an upstream change
- **Cross-verify** — requirements whose fit criteria must be re-verified when a related requirement changes
- **Verification level** — V-Model level (unit/integration/system/acceptance) at which evidence was collected

## Testing

```bash
# Validate requirement cards against schema
plugin/validate.sh plugin/requirements/UR-001.yaml

# Run hook + CLI + validator test suite (29 tests)
plugin/hooks/test-hooks.sh

# CLI commands
plugin/cli/volere help
plugin/cli/volere validate
plugin/cli/volere trace
plugin/cli/volere coverage
plugin/cli/volere impact UR-001
```

## Conventions

- Requirement cards are individual YAML files, one per requirement
- IDs follow the pattern: `{PREFIX}-{NNN}` (e.g., BUC-001, UR-042, TC-005)
- Every fit criterion must be measurable — no vague words (should, appropriate, reasonable)
- Chesterton's fence: keep Volere elements until proven unnecessary, not the other way around
- System testing (V-Model architecture level), not just e2e — includes performance, security, failure modes
- Autonomous verification: agents test everything, "manually verified" is a bug in the process
