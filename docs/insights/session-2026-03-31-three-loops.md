# Session Insight: The Three-Loop Agentic Development Lifecycle

**Date:** 2026-03-31
**Source:** Dogfooding session — realized while comparing Superpowers vs Volere that they're complementary layers, not competitors
**Project:** Volere Agentic Framework + discovery-to-delivery + Superpowers

---

## Insight 15: Three loops compose into a complete agentic development lifecycle

Agentic software development has three distinct loops, each answering a different question:

```
DISCOVERY                    VOLERE                       SUPERPOWERS
(understand the problem)     (specify what to build)      (build it with discipline)

Discover → Define →          Extract → Review →           Brainstorm → Plan →
Develop → Spec               Trace → Coverage → Gate      TDD → Execute → Review

Outputs:                     Outputs:                     Outputs:
  docs/problem.md              BUCs, URs, TCs               Design doc
  docs/brief.md                Fit criteria                 Implementation plan
  docs/options/                DAL levels                   Tests + code
  docs/decisions.md            Coverage matrix              Commits
  docs/spec.md                 Suspect links                PR / merge
                               Evidence chain
```

**Discovery** answers: *What's the problem and which solution approach?*
**Volere** answers: *What exactly must we build and how do we verify it?*
**Superpowers** answers: *How do we build it well?*

### Why three loops, not one?

Each loop has a different quality criterion:

| Loop | Quality criterion | Failure mode without it |
|------|-------------------|------------------------|
| Discovery | Right problem, right approach | Build the wrong thing entirely |
| Volere | Right requirements, right verification | Build something that passes tests but doesn't deliver value |
| Superpowers | Right code, right process | Build the right thing badly — monoliths, test theater, drift |

Skipping any loop produces a specific class of failure. Most teams skip 1-2 and wonder why agents produce poor results.

### Handoff points

Three explicit handoffs connect the loops:

**1. Discovery → Volere:** `docs/spec.md` → `extract-requirements` or `write-requirement`

The spec describes intent. Volere formalizes it into testable cards with measurable fit criteria. Without this handoff, requirements are informal and unverifiable.

**2. Volere → Superpowers:** Confirmed requirement cards → `/brainstorm`

The brainstorming skill receives not just "build X" but "build X such that these fit criteria pass at this DAL level." The verification target is explicit before any code is written. Without this handoff, Superpowers builds to a plan but doesn't know what success looks like.

**3. Superpowers → Volere:** Completed implementation → `coverage-gaps` hook → next session

After implementation, the SessionStart hook fires and checks: did the code satisfy the fit criteria? Did tests verify at the right V-Model level? Are there new suspect links? Without this handoff, implementation is a dead end — nobody checks whether what was built matches what was specified.

### The cycle

It's a cycle, not a pipeline:

```
Discovery → Volere → Superpowers → Volere (verify) → Discovery (new insights)
     ↑                                                        │
     └────────────────────────────────────────────────────────┘
```

Superpowers ships code. Volere verifies it. Gaps feed back into Discovery (new problem to solve) or directly into new requirements (refinement). The coverage-gaps hook is the feedback mechanism that closes the loop.

### What exists today

All three plugins are installed and working:
- `discovery-to-delivery@ulleberg` — Discovery loop
- `volere-requirement` (this repo) — Volere loop (not yet published as plugin)
- `superpowers@claude-plugins-official` — Superpowers loop

The handoff points are implicit (file conventions):
- Discovery outputs `docs/spec.md` which Volere reads
- Volere outputs requirement cards which Superpowers' brainstorming could reference
- Superpowers outputs code which Volere's hooks verify

### What should be built

The handoffs should be explicit — skill-to-skill invocation with context passing:

1. **Discovery `/deliver` → Volere `/extract-requirements`:** When the spec is written, automatically suggest extraction. The spec context (problem, constraints, decisions) informs the extraction.

2. **Volere coverage gate → Superpowers `/brainstorm`:** When a gap is identified, the briefing should include the requirement card and fit criteria as input to brainstorming. The agent doesn't start from scratch — it starts from a verified requirement.

3. **Superpowers completion → Volere `/audit-tests`:** After implementation, automatically suggest a test audit against the requirement that drove the work. The fit criteria become the acceptance check.

These aren't complex integrations — they're contextual suggestions at the right moments. The skills already exist. The integration is knowing *when* to invoke which skill with *what* context.

### Why this matters

Most agentic coding tools are Superpowers-shaped: they make agents write better code. But "better code" without requirements is just a faster path to the wrong destination. And requirements without a discovery process are assumptions dressed as specifications.

The three-loop lifecycle is what makes agentic development reliable end-to-end: understand the problem, specify the solution, build it well, verify it works, learn, repeat.

**Framework action:** Build the explicit handoffs between the three loops. This is the v1.0 differentiator — not just a requirements plugin, but the bridge between understanding, specifying, and building.
