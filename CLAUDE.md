# Volere Agentic Framework

Archive of the original Volere Requirements Template (v15) plus the Volere Agentic Framework — a Claude Code plugin for structured requirements engineering and V-Model verification in agentic software development.

## Architecture

- **Original Volere files (a–i)** — template, case studies, requirement stationery. Preserved as-is.
- **docs/** — discovery-to-delivery documentation: problem, brief, options, decisions, spec, team prompts, execution plans.
- **plugin/** — the framework itself: schema, skills, templates, validator, and its own requirements (dogfooding).

See `ARCHITECTURE.md` for the full V-Model mapping, design principles (Chesterton's fence, soft+hard enforcement, autonomous verification), and design decisions.

## Key Concepts

- **Snow card** — Volere's atomic requirement format, modernised as YAML with multi-dimensional fit criteria
- **BUC** (Business Use Case, §7) — why requirements exist (business context)
- **PUC** (Product Use Case, §8) — what the user does (interaction flows)
- **UR** (User Requirement, §9-17) — what the system must do
- **TC** (Technical Constraint) — what the implementation must guarantee
- **DAL** (Design Assurance Level, A-E) — scales verification effort to risk
- **Fit criterion** — measurable condition defining when a requirement is satisfied

## Testing

Validate requirement cards:
```bash
plugin/validate.sh plugin/requirements/UR-001.yaml
```

## Conventions

- Requirement cards are individual YAML files, one per requirement
- IDs follow the pattern: `{PREFIX}-{NNN}` (e.g., BUC-001, UR-042, TC-05)
- Every fit criterion must be measurable — no vague words (should, appropriate, reasonable)
- Chesterton's fence: keep Volere elements until proven unnecessary, not the other way around
