# Decisions

## Date: 2026-03-30
## Phase: Develop

## Options Comparison

| Criterion | A: Volere-Native | B: Enforcement-First | C: Agent Team Verification |
|-----------|:---:|:---:|:---:|
| Prevents degradation | ★★★★ | ★★★★★ | ★★★ |
| Requirements traceability | ★★★★★ | ★★ | ★★★ |
| Multi-dimensional fit criteria | ★★★★★ | ★★ | ★★★★ |
| Regulatory compliance support | ★★★★★ | ★★★ | ★★★★ |
| Speed for simple projects | ★★ | ★★★★★ | ★★★ |
| Cross-document coherence | ★★★★ | ★ | ★★★★★ |
| Deterministic/repeatable | ★★★★ | ★★★★★ | ★★ |
| Runtime cost | ★★★★★ | ★★★★★ | ★★ |
| Builds on thul ecosystem | ★★★ | ★★ | ★★★★★ |
| Catches novel problems | ★★ | ★ | ★★★★★ |
| Evidence chain for auditors | ★★★★ | ★★★ | ★★ |
| Effort to build | ★★ | ★★★★ | ★★★★ |

## The Obvious Answer: Combine Them

None of these options is complete alone. Each solves what the others miss:

- **Option A** provides the WHAT (requirements, fit criteria, traceability) — but has no teeth without enforcement
- **Option B** provides the TEETH (hard constraints, CI gates, pre-commit hooks) — but has no brain without requirements
- **Option C** provides the JUDGEMENT (cross-cutting review, novel problem detection, coherence) — but is non-deterministic without guardrails

The V-Model itself tells us this: you need BOTH definition (left side) AND verification (right side). And verification needs both automated (Option B) and human-like review (Option C).

## Proposed Hybrid: "Volere Agentic Framework"

```
            Option A                Option B              Option C
            (Requirements)          (Enforcement)         (Verification)
            ─────────────           ────────────           ────────────
Layer 1     YAML snow cards    →    CI acceptance tests    Agent team review
            (what to build)         (hard gate)            (cross-cutting check)

Layer 2     ARCHITECTURE.md    →    Fitness functions      Architecture reviewer
            boundaries.yaml         dependency-cruiser      (judgement calls)

Layer 3     Interface contracts →   Contract tests         Test engineer
                                    mutation testing        (test quality review)

Layer 4     Coding standards   →    Pre-commit hooks       Code reviewer
                                    linting, types          (anti-pattern check)

Layer 5     Compliance profiles →   Automated checks       Compliance officer
            (FCC, RED, etc.)        (where possible)        + Auditor (where not)
```

**Each V-Model level gets all three layers: definition → automated enforcement → agent review.**

### How it flows in practice

1. **Start light** — `volere init --profile minimal` scaffolds the project with boundaries.yaml, budgets.yaml, and basic CI. No requirement cards yet. (Option B)

2. **Add requirements when needed** — When the project gets serious, write YAML snow cards with fit criteria. The `volere trace` CLI shows coverage gaps. (Option A)

3. **Scale verification with risk** — DAL-E gets pre-commit hooks only. DAL-C adds CI gates. DAL-A adds agent team review. (Option C, graduated)

4. **Compliance when required** — Load a compliance profile (FCC, RED, IEC 61508). It adds dimension-specific fit criteria templates and automated checks. Agent auditor verifies what automation can't. (All three)

### Incremental delivery

| Increment | What ships | Value delivered |
|-----------|-----------|----------------|
| **v0.1** | YAML snow card schema + `volere init` scaffold | Machine-readable requirements, project structure |
| **v0.2** | Pre-commit hooks + boundaries.yaml + budgets.yaml | Hard enforcement of architecture + complexity |
| **v0.3** | `volere trace` + `volere coverage` CLI | Traceability visibility |
| **v0.4** | CI pipeline template with DAL profiles | Graduated verification in CI |
| **v0.5** | Fit criteria → test skeleton generation (BDD bridge) | Automated test scaffolding from requirements |
| **v0.6** | Verification agent roles + skills (architecture-reviewer, test-engineer) | Agent team review layer |
| **v0.7** | Suspect link management + impact analysis | Change impact awareness |
| **v0.8** | Compliance profiles (FCC, RED, IEC 61508) | Regulatory dimension support |
| **v0.9** | Evidence chain generation | Audit-ready output |
| **v1.0** | Full framework with documentation | Production-ready |

## Open Decisions

### OD-1: Requirement card format
YAML is proposed, but alternatives exist:
- **YAML** — human-readable, git-diffable, parseable
- **TOML** — simpler syntax, but less expressive for nested structures
- **Markdown + frontmatter** — more human-friendly, but harder to parse multi-dimensional fit criteria
- **JSON Schema validated YAML** — adds validation but increases complexity

**Leaning:** YAML with JSON Schema validation. Best balance of readability + machine parseability.

### OD-2: Where does the framework live?
- **Claude Code plugin** (in thul-plugins marketplace) — skills + hooks, no CLI
- **Standalone npm package** — CLI + CI templates, framework-agnostic
- **Both** — plugin for agent integration, npm package for CLI/CI

**Leaning:** Both. Plugin for the agent skills/hooks, npm package for the CLI and CI tooling.

### OD-3: How do fit criteria generate tests?
- **BDD/Gherkin** — Given/When/Then maps to fit criteria naturally
- **Direct test generation** — agent reads fit criterion, writes test in project's test framework
- **Property-based** — fit criteria as properties (Hypothesis, fast-check)

**Leaning:** Direct test generation first (agent reads criterion, writes test). BDD bridge as v0.5 feature.

### OD-4: Requirement numbering scheme
- **Simple sequential** — TR-001, SR-001, OR-001
- **Hierarchical** — 1.2.3 (chapter.section.item)
- **Type-prefixed** — FUNC-001, PERF-001, SEC-001

**Leaning:** Type-prefixed, matching Volere requirement types. FUNC, PERF, LOOK, USAB, OPER, MAIN, SEC, CULT, LEGAL.

### OD-5: Where to start?
- **Start with a real project** — apply the framework to thul-studio or another active repo
- **Start with the framework itself** — build the plugin/CLI as a standalone project
- **Start with a spike** — minimal prototype to validate the YAML format + one CI check

**DECIDED: Start with thul-studio.** Thomas's call — thul-studio triggered the insight, already has 26 URs in Volere-inspired format, already has a V-Model test plan with 577 tests, and already has the agent infrastructure. The framework gets validated by using it to strengthen the requirements and refactor the codebase.

### OD-6: What to do first in thul-studio?
**DECIDED: Requirements review before any refactoring.** Before touching code or tests, do a hard review of the 26 URs:
- Are they the right requirements? Missing any?
- Are the fit criteria truly testable and specific?
- Do they cover non-functional dimensions (performance, security, operational)?
- Are there derived requirements hiding in the codebase that aren't captured?
- Are the 577 tests actually verifying fit criteria, or is some of it test theater?

### OD-7: Synthesis Q1 — CORS fix scope
**DECIDED: Option A — restrict CORS to Tailscale origins.** Tailscale provides network-level auth. Terminal auth would break the iframe approach for low threat-model benefit.

### OD-8: Synthesis Q2 — Token lifecycle
**DECIDED: Static token is sufficient.** Single user, behind Tailscale. Move token from config to `~/.secrets` for consistency. No rotation/expiry needed.

### OD-9: UR-33 broadened to secrets management
**DECIDED: UR-33 expanded from "token lifecycle" to full secrets management.**

The investigation revealed the documented convention ("all secrets in `~/.secrets`") doesn't match reality:
- Daemon processes (launchd) use local `.env` files because launchd doesn't source zshrc
- Three repos (thul-ops, thul-studio, thul-finance) use `.env` — this is legitimate but undocumented
- No pre-commit hooks for secrets detection in any repo
- No CI secrets scanning (gitleaks, trufflehog) anywhere
- Doc-health agent scans monthly but is report-only
- `STUDIO_TOKEN` exists in `~/.secrets` but isn't in the dotfiles README template

This is a concrete example of soft constraints (CLAUDE.md) without hard enforcement (hooks/CI) = drift. Exactly the problem the Volere Agentic Framework is designed to solve.

Updated UR-33 captures the two-tier pattern and adds hard enforcement via pre-commit hooks + CI + doc-health.

### OD-10: Synthesis Q3 — Session isolation priority
**DECIDED: P3 with documented trigger.** Single-operator threat model makes this low priority today. Re-evaluate if: others join the Tailscale mesh, untrusted prompts run in sessions, or "Agents as a Service" puts customer agents on the infrastructure.

### OD-11: Synthesis Q4 — Derived requirements placement
**DECIDED: Technical Constraints appendix.** Create `docs/requirements/technical-constraints.md` with TC- prefix. Same Volere format, traces upward to URs. Lives at the design level of the V-Model, verified by unit tests. Keeps UR document clean (user-facing only).

### OD-12: Synthesis Q5 — Conference transcript durability
**DECIDED: P1 — transcripts are reference material.** Incremental writes per round (crash resilient). Structured metadata (participants, topic, date, decisions). Future: skill/hook to extract decisions and feed back into requirements/expertise.

### OD-13: Synthesis Q6 — Machine count in URs
**DECIDED: Design for N machines.** URs reference "all machines" or "across the mesh," never specific counts. roster.yaml abstracts topology. M5, M6, or cloud nodes work without rewriting requirements.

### OD-14: Synthesis Q7 — Chat history persistence
**DECIDED: File-persisted on campus (Option 2).** Chat history stored in `thul-agents/agents/{role}/chats/{date}.md`. One file per day, pruned after 30 days. Campus synced across mesh via git (needed anyway for roster). Chat is agent knowledge — belongs with the agent, not the infrastructure.

**Side finding: Campus sync is a prerequisite.** roster.yaml, expertise/, SOUL.md, and now chats/ all need syncing. This should be a UR or technical constraint.

### OD-15: Synthesis Q8 — Workspace grouping
**DECIDED: "Ungrouped" section at bottom for non-pinned folders.** Pin manually if frequent. Takes effect on page load, no restart.

### OD-16: Synthesis Q9 — Health checks scope
**DECIDED: Split clearly.** UR-20 = project standards compliance (per-session, file quality + staleness). UR-30 = machine health (/health endpoint, infrastructure). Renamed UR-20 from "Project health checks" to "Project standards compliance."

**Side finding: Need a Project Constitution.** UR-20 checks existence AND quality, but the standard it checks against needs to be defined. Created `docs/project-constitution.md` as a framework-level spec defining minimum content for CLAUDE.md, ARCHITECTURE.md, README.md, requirements/. This is a Volere Agentic Framework deliverable, not a Studio UR.

## Status: All 9 synthesis questions decided
