# Problem Brief

## Status: Draft
## Date: 2026-03-30

## Problem Statement

AI agents can write code but nothing forces them to build software *well*. As codebases grow, agents degrade them — choosing quick fixes over root causes, skipping tests, accumulating technical debt, violating architectural boundaries. The result: monoliths, test theater, interface drift, and specifications that contradict themselves.

Structured requirements engineering (Volere) and systematic verification (V-Model) solved this for human teams. Nobody has translated these disciplines into the agentic world. The pieces exist — CLAUDE.md, skills, hooks, CI/CD, agent teams — but there is no integrated framework that makes quality the default path for agents.

## Target User

**Thomas Ulleberg** — and engineering leaders like him who:
- Manage agentic teams (not just single agents) building real products
- Work in regulated domains (FCC, RED, ATEX, IEC 61508, security standards)
- Have experience with structured requirements and V-Model verification
- Want predictable, compounding quality — not ad hoc prompting
- Are building toward "Agents as a Service" delivery models

## What Success Looks Like

1. **An agent team receives a set of Volere requirements and produces verified, traceable software** — every requirement has a fit criterion, every fit criterion has an automated test, every test passes before delivery.

2. **Quality compounds instead of degrading.** Each feature makes the system stronger. Architectural boundaries are enforced by CI, not just declared in CLAUDE.md. Agents cannot commit code that violates structure.

3. **Multi-dimensional acceptance works.** A single requirement can carry fit criteria across user, regulatory, security, and safety dimensions. Agents know which dimensions apply and cannot close a requirement without satisfying all of them.

4. **The framework is predictable and programmatic.** Starting a new project means scaffolding a known structure — not hand-rolling CLAUDE.md and hoping for the best. The setup is repeatable across projects and domains.

5. **It integrates with the existing thul ecosystem.** Agent definitions (SOUL.md), expertise (curricula), collaboration (A2A), and operations (thul-ops) are preserved. The framework adds the requirements and verification layer these systems currently lack.

## Constraints

### Must
- Work with Claude Code as the primary agent runtime
- Integrate with the thul-agents/thul-studio/thul-ops ecosystem
- Support multi-agent teams (proven in Experiment 001)
- Handle non-functional requirements (performance, security, operational — Volere types 10-17)
- Produce machine-readable requirements that agents can parse and verify against
- Support regulatory compliance dimensions (not just user acceptance)

### Must Not
- Require enterprise ALM tools (DOORS, Polarion, Jama) — must work with files + git
- Add ceremony that slows small projects — graduated rigour based on project risk
- Break existing workflows — extend, don't replace

### Should
- Use YAML or similar for machine-readable requirement cards (not Word/PDF)
- Generate test skeletons from fit criteria (BDD/Gherkin bridge)
- Include architectural fitness functions as CI checks
- Support suspect link management (impact analysis when requirements change)
- Track derived requirements (implementation decisions that create new constraints)

### Could
- Include opinionated starter architectures per domain
- Provide compliance-as-code profiles (like OSCAL) for common regulatory frameworks
- Support SBOM generation for agent-produced code
- Include refactoring triggers (hotspot analysis, complexity budgets)
- Offer "Agents as a Service" packaging for customer delivery

## Evidence Base

### From Research (5 sub-agent reports, 2026-03-30)
- Volere snow card maps directly to agent task definitions — no other framework covers project template + atomic testable format + non-functional requirements
- V-Model for agentic development is genuine whitespace — nobody has published this
- Safety-critical industries (DO-178C, IEC 61508, ISO 26262) have mature requirements-to-verification patterns we can adapt
- Compliance-as-code (OPA, InSpec, OSCAL) proves fit criteria can be executable — but only for infrastructure/security, not functional safety or regulatory
- Six documented anti-patterns when agents lack structural constraints

### From Experiment 001 (thul-agentic-research)
- Skilled agent teams produce **100% testable fit criteria** in technical requirements
- Cross-document coherence is the decisive difference between unskilled and skilled teams — directly validates the V-Model's horizontal traceability
- Skilled teams **self-organize** to produce verification artifacts not requested
- Skilled teams **catch contradictions** between requirement documents that unskilled teams miss
- Training ROI is highest for: cross-document integration, operational edge cases, and emergent coordination

### From Production Experience
- JS monolith degradation proved that soft constraints (CLAUDE.md) without hard enforcement (CI) leads to codebase collapse
- 33 specialist agent roles already exist with SOUL.md, expertise, curricula — the organisational layer is built
- Multi-agent pair programming proven (2026-03-24) — agents can work concurrently on same codebase without conflicts

## What We're NOT Solving

- **General AI alignment** — we're solving engineering discipline, not safety alignment
- **Replacing human judgement entirely** — humans decide when to move phases, approve architecture, and make risk trade-offs
- **Building a commercial ALM product** — this is a framework/methodology, not a SaaS tool
- **Making agents smarter** — we're constraining agents that are already capable but undisciplined

## Core Tension

The framework must be **rigorous enough to prevent degradation** but **lightweight enough that it doesn't become the bottleneck**. Safety-critical standards (DO-178C) are effective but produce tens of thousands of pages of documentation. Agile/lean approaches are fast but lack the structural backbone agents need.

The answer is likely **graduated rigour** — DAL levels (from DO-178C) applied to agentic development. A CSS change gets DAL-E (minimal). A database migration gets DAL-A (full V-Model verification). The framework scales verification effort to risk.

## Next Step

Move to **Develop** phase: generate at least two competing approaches to building this framework, evaluate trade-offs, and converge on a spec for delivery.
