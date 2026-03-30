# Option B: Enforcement-First — Build the Guardrails, Not the Documents

## Approach

Start from the enforcement side. Instead of writing requirement documents that agents should follow, build automated guardrails that agents cannot bypass. The philosophy: **don't tell agents what to do — make it impossible to do the wrong thing.** Requirements emerge from the constraints, not the other way around.

Inspired by compliance-as-code (OPA, InSpec), architectural fitness functions, and the research finding that agents respect hard failures but ignore soft guidelines.

## How It Works

### 1. Project Skeleton with Built-in Constraints

```
project/
├── .volere/
│   ├── profile.yaml              # Which checks are active (DAL level)
│   ├── boundaries.yaml           # Module dependency rules
│   ├── contracts/                # Interface contracts (assume/guarantee)
│   ├── budgets.yaml              # Complexity, dependency, file size limits
│   └── compliance/               # Regulatory check definitions
├── .github/workflows/
│   └── verify.yaml               # CI pipeline with all gates
├── .husky/
│   ├── pre-commit                # Fast checks (lint, types, boundaries)
│   └── pre-push                  # Slower checks (tests, mutation, coverage)
├── CLAUDE.md                     # Points to .volere/ — "read your constraints"
└── src/
```

### 2. Constraint Types

**Architectural boundaries** (enforced by dependency-cruiser / eslint-plugin-boundaries):
```yaml
# .volere/boundaries.yaml
modules:
  domain:
    allowed_imports: []            # Domain imports nothing
    description: "Pure business logic, no framework dependencies"
  application:
    allowed_imports: [domain]
    description: "Use cases, orchestration"
  infrastructure:
    allowed_imports: [domain, application]
    description: "Database, API, external services"
  ui:
    allowed_imports: [application]
    description: "Presentation layer"
```

**Complexity budgets** (enforced by ESLint + custom CI):
```yaml
# .volere/budgets.yaml
max_file_lines: 300
max_cyclomatic_complexity: 15
max_cognitive_complexity: 20
max_dependencies: 30
max_dependency_depth: 4
max_duplication_percentage: 3
min_mutation_score: 70
coverage_threshold: 80
```

**Interface contracts** (enforced by contract tests):
```yaml
# .volere/contracts/session-manager.yaml
module: src/sessions/
provides:
  - function: createSession
    accepts: { type: "object", required: [folder, type] }
    returns: { type: "object", required: [id, pid, port] }
    guarantees:
      - "returned port is within configured range"
      - "session is added to sessions.json atomically"
requires:
  - "port pool has at least one available port"
  - "target folder exists and is readable"
```

**Compliance checks** (enforced by custom CI steps):
```yaml
# .volere/compliance/security-baseline.yaml
checks:
  - id: SEC-001
    title: No secrets in source
    type: grep-absence
    pattern: "(api_key|secret|password|token)\\s*[:=]\\s*['\"][^'\"]{8,}"
    exclude: ["*.test.*", "*.example.*"]
  - id: SEC-002
    title: Dependencies have no critical CVEs
    type: command
    run: "npm audit --audit-level=critical"
  - id: SEC-003
    title: All API endpoints require authentication
    type: custom
    script: "scripts/check-auth-middleware.sh"
```

### 3. The CLAUDE.md Is Minimal

```markdown
# Project

## Constraints
All constraints are defined in `.volere/` and enforced by CI.
Read `.volere/profile.yaml` to understand what level of rigour applies.
Read `.volere/boundaries.yaml` before creating or modifying modules.
Read `.volere/contracts/` before changing any interface.

## Rules
- Run `npm test` before committing
- If a pre-commit hook fails, fix the root cause — do not bypass
- If you need a new dependency, check budgets.yaml first
- If you need to cross a module boundary, check boundaries.yaml first
```

### 4. Requirements Are Reverse-Engineered

Instead of writing requirements upfront, requirements emerge from:
- **Failing constraint checks** → "we need X because check Y failed"
- **Interface contracts** → "module A guarantees X to module B"
- **Compliance profiles** → "FCC Part 15 requires emission testing below X dBm"

When a requirement IS needed (for traceability in regulated domains), it's a lightweight card that points to the enforcement mechanism:

```yaml
id: TR-042
title: Session state detection accuracy
enforced_by:
  - test: tests/integration/session-state.test.ts
  - contract: .volere/contracts/session-manager.yaml
  - budget: max_cyclomatic_complexity (session-detector module)
dal: C
```

## Strengths

- **Agents can't cheat.** Constraints are enforced by tooling, not by instructions. An agent literally cannot commit code that violates boundaries.
- **Zero ceremony for simple projects.** Start with `profile: minimal`, add constraints as the project grows.
- **Immediately actionable.** No need to write requirements before starting — constraints protect from day one.
- **Leverages existing tools.** dependency-cruiser, ESLint, Jest, Stryker, npm audit — all mature, well-documented.
- **Fast feedback.** Pre-commit hooks catch violations in seconds, not at review time.
- **Scales down.** A solo developer gets 80% of the value from just boundaries.yaml + budgets.yaml.

## Weaknesses

- **No "why."** Constraints tell agents WHAT they can't do, but not WHY. Without rationale, agents may work around constraints in creative but undesirable ways.
- **Requirements traceability is weak.** Regulated domains need bidirectional traceability (requirement → test → evidence). Reverse-engineering requirements from constraints doesn't provide this naturally.
- **Doesn't drive discovery.** The framework catches violations but doesn't help discover WHAT to build. It's defensive, not generative.
- **Multi-dimensional fit criteria don't fit.** Compliance checks are binary (pass/fail), but Volere fit criteria can be nuanced ("95% of responses under 200ms"). The enforcement model oversimplifies acceptance.
- **Miss the cross-document coherence win.** Experiment 001 showed that the biggest value of structured requirements is cross-document integration. Enforcement-first produces fragmented checks, not an integrated specification.
- **Interface contracts are hard to write.** Defining assume/guarantee pairs for every module interface is significant upfront work — and agents are bad at writing them without examples.

## Effort Estimate

- Project scaffold template: Small
- Boundaries + budgets config: Small
- CI pipeline with all gates: Small-Medium
- Interface contract system: Medium
- Compliance profiles: Medium (per regulation)
- Reverse-engineered requirement tracking: Medium
- **Total: Medium, mostly wiring existing tools together**

## Best For

Projects where speed matters more than traceability. Internal tools. Prototypes that might become products. Teams already comfortable with CI/CD. Situations where "prevent bad code" is more important than "specify good requirements."
