# Requirements

## Format

Requirements follow the Volere Agentic Framework — YAML snow cards with multi-dimensional fit criteria.

Each requirement is a separate `.yaml` file validated against the Volere schema.

## Structure

| Prefix | Level | Scope |
|--------|-------|-------|
| `UR-` | User Requirement | What the user needs from the system |
| `TC-` | Technical Constraint | Implementation contract serving a UR |
| `SHR-` | Stakeholder Requirement | High-level need (for complex/regulated projects) |

## V-Model Mapping

```
User Requirements (UR-xxx)           ←→  Acceptance / E2E tests
  └── Technical Constraints (TC-xxx) ←→  Unit / Integration tests
```

## Files

- `context.yaml` — Project scope, stakeholders, glossary, constraints
- `UR-xxx.yaml` — Individual user requirement cards
- `TC-xxx.yaml` — Technical constraint cards
- `reviews/` — Agent team review artifacts

## Commands

```bash
volere new --type functional     # Create a new UR
volere new --type technical-constraint --serves UR-001  # Create a TC
volere validate                  # Check all cards against schema
volere coverage                  # Which fit criteria have tests?
volere trace                     # Traceability matrix
```
