# Requirements

## Format

Requirements follow the Volere Agentic Framework — YAML snow cards with multi-dimensional fit criteria.

Each requirement is a separate `.yaml` file validated against the Volere schema.

## Structure

| Prefix | Volere § | Level | Scope |
|--------|---------|-------|-------|
| `BUC-` | §7 | Business Use Case | High-level business process the system supports |
| `PUC-` | §8 | Product Use Case | Specific user-system interaction |
| `UR-` | §9-17 | User Requirement | What the user needs from the system |
| `TC-` | — | Technical Constraint | Implementation contract serving a UR |
| `SHR-` | §1-5 | Stakeholder Requirement | High-level need (complex/regulated projects) |

## V-Model Mapping (Left Side → Right Side)

```
Business Use Cases (BUC-xxx)             ←→  Validation (right thing?)
  └── Product Use Cases (PUC-xxx)        ←→  Acceptance Tests
      └── User Requirements (UR-xxx)     ←→  System Tests
          └── Technical Constraints (TC-xxx) ←→  Unit / Integration Tests
```

## Decomposition

BUCs answer "why do these requirements exist?"
PUCs answer "what does the user do?"
URs answer "what must the system do?"
TCs answer "what must the implementation guarantee?"

Each level decomposes into the next via the `decomposed_to` field.
Each level traces upward via the `source` or `serves` field.

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
