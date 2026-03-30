# Problem Discovery

## Status: Complete — distilled into docs/brief.md
## Date: 2026-03-30

## The Problem Space

### Pain Point 1: Agents degrade as codebases grow
A JavaScript backend grew into a monolith. As complexity increased, the agent made more mistakes — choosing quick fixes over root-cause solutions, skipping regression tests even when asked. The codebase became a liability instead of an asset.

**Root cause hypothesis:** Without strong structural constraints (project setup, CLAUDE.md, skills, CI/CD), agents default to the path of least resistance. They optimise for "task done" not "system health."

### Pain Point 2: No predictable, compounding quality
The current experience is ad hoc — each session starts from scratch, quality depends on how well you prompt, and there's no systematic way to ensure agents verify and validate their work. The V-Model (requirements ↔ tests at every level) works with human teams but hasn't been translated into agentic workflows.

**What's needed:** A programmatic setup where quality compounds — each feature makes the system stronger, not more fragile.

### Pain Point 3: Project setup is the unsolved problem
The user has deep experience with Volere requirements and V-Model testing in human teams. The missing piece is: how do you structure a project (CLAUDE.md, skills, CLIs, CI/CD) so that agents *inherently* follow these disciplines instead of fighting them?

### Pain Point 4: Volere may need modernising
The Volere template has been used successfully for managing engineering teams for decades. But it was designed for human teams. Questions:
- Has Volere evolved since v15 (2010)?
- Are the authors thinking about agentic workflows?
- Can the atomic requirement format be adapted to drive agent behaviour directly?

### Pain Point 5: Starting right — tech stack and architecture decisions
Agents can't make the foundational judgement call: what tech stack to start with, what architecture fits the problem, and when the current structure needs refactoring vs. extending. They don't feel technical debt — they work around it until the codebase collapses. The JS monolith would have been avoided with a Volere + V-Model approach enforced from day one.

### Pain Point 6: Acceptance is multi-dimensional
User requirements are only one dimension of fit criteria. Real products must also satisfy:
- **Regulatory compliance** — FCC, RED (Radio Equipment Directive), ATEX, IECEx
- **Security standards** — IEC 62443, NIST, ISO 27001
- **Safety standards** — IEC 61508, SIL levels
- **Quality/Process** — ISO 9001, CMMI

A single requirement may need multiple fit criteria across different compliance dimensions. Agents need to know which dimensions apply and cannot ship non-compliant work. This also validates the V-Model — regulated industries already mandate it (IEC 61508 practically requires it).

## User Context

- Experienced engineering leader who has managed teams using Volere + V-Model
- Now transitioning to fully agentic workflow ("agents for everything")
- Works across domains that include regulatory compliance (FCC, RED, ATEX, security)
- Sees "Agents as a Service" as a business opportunity worth exploring
- Values: fix root causes, compounding quality, joy in the process
- Current tools: Claude Code with superpowers, skills, MCP servers, hooks

## Key Insight

> The problem isn't that agents can't build software. The problem is that nothing forces them to build it *well*. Volere solved this for human teams — structured requirements with fit criteria ensured testable, traceable, complete work. The question is: can we create the same structural discipline for agents?

## Research Findings (2026-03-30)

### Volere Status
- Template v15 (2010) is the last version. Book got 3rd edition (2012) adding agile guidance.
- Robertsons appear semi-retired. No AI/agentic work. Atlantic Systems Guild effectively dormant.
- **Nobody in the Volere community is connecting requirements to agentic execution.** This is genuine whitespace.
- Volere remains the only framework combining: project-level template + atomic testable format + non-functional coverage. No modern competitor covers all three.

### The Snow Card is Already Agent-Ready
The Volere atomic requirement card maps directly to agent task definitions:
- Requirement # → Task ID / traceability
- Description → What to build
- Rationale → Context for agent trade-off decisions
- Fit Criterion → Acceptance test assertion (the genius of Volere)
- Priority → Task ordering
- Conflicts → Dependency awareness
- Requirement Type → Scope classification

### V-Model for Agents: Nobody Has Done It
No published work maps the V-Model to agentic software development. The pieces exist independently:

| V-Model Level | Instruction (soft) | Enforcement (hard) |
|---------------|-------------------|-------------------|
| Requirements | Volere atomic cards | Acceptance tests from fit criteria |
| Architecture | ARCHITECTURE.md + CLAUDE.md | Fitness functions in CI |
| Design | Module specs / interfaces | Unit tests (TDD) |
| Code | Coding standards | Pre-commit hooks, linting |

**Key insight:** Most setups rely on CLAUDE.md alone (soft constraint). The monolith degradation pattern happens because there's no hard enforcement at the architecture level.

### Known Agent Anti-Patterns (Without Structural Constraints)
1. **Monolith Degradation** — no boundaries → ball of mud
2. **Test Theater** — high coverage, tests verify implementation not behaviour
3. **Interface Drift** — agent changes signatures, breaks downstream silently
4. **Dependency Accumulation** — packages for trivial things
5. **Documentation-Code Divergence** — code changes, docs don't
6. **Premature Abstraction** — over-engineering from training data patterns

### Gap Between Soft and Hard Constraints
CLAUDE.md is advisory. CI/CD is enforced. The gap between what CLAUDE.md declares and what CI enforces is a known failure mode. Effective setups need both columns at every V-Model level.

## Open Questions

1. ~~Has the Volere framework evolved since 2010?~~ **Answered: frozen at v15, book at 3rd ed (2012), no agentic work.**
2. What does a "V-Model ready" project structure look like for agentic development?
3. Can Volere atomic requirements become machine-readable agent task definitions? **Research says yes — the snow card format maps naturally.**
4. What CLAUDE.md patterns, skills, and CI/CD setups prevent agent laziness?
5. What does "Agents as a Service" look like as a business model?
6. What's the minimum viable project setup that makes agentic development predictable?
7. **NEW:** How do we translate V-Model levels into a layered enforcement system (soft + hard at each level)?
8. **NEW:** Can fit criteria auto-generate acceptance test skeletons? (BDD/Gherkin is the closest existing bridge.)
9. **NEW:** How do multi-dimensional fit criteria (user, regulatory, security, safety) work in the snow card? One card per dimension, or one card with multiple fit criteria?
10. **NEW:** Should the framework include opinionated starter architectures per domain, or be stack-agnostic?
11. **NEW:** How does an agent know when to refactor vs. extend? What signals/metrics trigger that decision?

## Pain Summary

The gap is between **"agents can write code"** and **"agents reliably deliver quality software."** Closing that gap requires structured requirements (Volere), systematic verification (V-Model), and project infrastructure that makes discipline the default path — not the hard path.

**The opportunity is real and novel.** Nobody has connected these dots. Volere's snow card is the best existing atomic format for agent contracts. The V-Model provides the verification structure. The tooling (CLAUDE.md, skills, hooks, CI/CD) exists. What's missing is the integration.
