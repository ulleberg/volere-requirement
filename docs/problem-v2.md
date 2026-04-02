# Problem Discovery v2

## Status: In progress
## Date: 2026-04-02 (extends 2026-03-30 discovery)

## The Actual Problem

**How do you develop a trusted, repeatable methodology for human+agent product development — one that works from MVP to millions of users, that you can grow with, and eventually teach to others?**

This is not about building a requirements framework. It's not about fixing a testing gap. It's about finding the *development methodology for the agentic age* — covering the full loop: discover what to build, build it with agents you trust, ship it, observe, iterate.

Requirements, execution, verification, and observation are all parts of the methodology. None of them is the methodology itself.

## How We Got Here

The original problem discovery (2026-03-30) identified that agents degrade codebases because nothing forces them to build well. We built the Volere Agentic Framework as an experiment in solving this: structured requirements, V-Model verification, DAL-scaled effort, coverage enforcement.

On 2026-04-02, while using the framework to build a requirement graph visualization, **the framework failed to prevent exactly the problem it was designed to solve.** An agent shipped a blank page, declared "77 tests pass," and moved on. The tests were structural greps (THEATER) that verified string presence in a file, not functional behavior in a browser. The page had a JavaScript parse error that no test caught.

This failure exposed deeper layers of the problem — and ultimately revealed that we were solving a narrower problem than the one that actually matters.

## The Deeper Problem

### Pain Point 7: The executor self-assesses

Superpowers (the execution plugin) lets the agent write code, write tests, run tests, review code, and declare done — all in one loop. This is like having a developer write, test, review, and approve their own PR. The V-Model works because different roles verify at different levels. Superpowers collapses all roles into one self-assessing agent.

**Research findings (2026-04-02):**
- Stripe uses external deterministic graders. The agent never self-assesses.
- GSD's verifier explicitly says "never trust claims" and checks artifacts independently.
- gstack's `/qa` opens a real browser and sees what the user sees.
- None of these have V-Model awareness, but the ones that work share one trait: **verification is external to the executor.**

### Pain Point 8: Plans decompose horizontally, not vertically

Superpowers' `writing-plans` skill decomposes work by component (parser, template, tests) — horizontal layers. Each task is complete within its layer before moving to the next. The `test-driven-development` skill drives TDD within each layer, but at that layer's level (unit tests for unit code).

This means:
- The parser gets built and unit-tested (all 39 cards)
- The template gets built and structurally tested (300 lines)
- Integration between them is never tested until the very end
- System-level behavior (does it render?) is never tested at all

Thomas's approach: **thin vertical slice first** — get one card rendering in the browser with acceptance, system, integration, and unit tests. Then broaden.

### Pain Point 9: Coverage hook can't distinguish VERIFIES from THEATER

The coverage hook counts tagged tests: `# Dimension: UR-020:user` on a grep test counts the same as a browser-based system test. The card specifies `test_type: system` but nothing enforces that the tagged test actually operates at the system level.

**Result:** 100% coverage with 0% confidence.

### Pain Point 10: Token economics demand acceptance-first investment

Running full V-Model verification on every change doesn't scale economically. The insight:

- **Acceptance tests are the trust layer.** If acceptance passes, the software meets the requirement. Ship it.
- **Lower levels (system/integration/unit) are the debug layer.** They exist to locate bugs when acceptance fails, not to prove correctness.
- **DAL scales the investment.** DAL-A acceptance: thorough (browser QA, API validation, compliance checks). DAL-E acceptance: minimal (output exists and isn't empty).

This inverts conventional testing wisdom (cheap unit tests first, expensive acceptance last). For agents, acceptance is where trust lives — invest there.

### Pain Point 11: You can't anticipate every way an agent will get it wrong

Acceptance tests verify what you specified. But agents fail in ways you didn't think to specify (unescaped quotes in JSON, awk consuming backslashes, blank pages that pass grep tests). 

**Hypothesis:** An agentic scenario synthesizer (chaos-monkey-for-requirements) could:
- Read requirement cards and fit criteria
- Generate adversarial usage scenarios the acceptance tests don't cover
- Run them against the live system
- Report failures as candidate fit criteria

This is testing what you *forgot to specify*, feeding the discovery loop.

## Who's Affected

### Primary: Thomas and other technical founders
- Building commercial SW products with agent teams
- Need to trust agent output enough to ship to paying users
- Need the economics to work: verification cost must scale with risk, not ceremony

### Secondary: Teams adopting agentic development
- Moving from "agent as assistant" to "agent as autonomous builder"
- Need a framework that makes agent output trustworthy by construction
- Can't afford to manually verify every agent commit

## The Trust Model

Trust comes from three sources:

1. **Right requirements** — captured from real user pain, validated by actual usage
2. **Regression you can trust** — acceptance tests verify behavior, not structure
3. **Usage observation** — see how users actually use it, feed back into requirements

The full loop: **discover → build → ship → observe → discover again.** Fast iterations, high confidence.

## Current Workarounds

1. **Manual verification** — human opens the browser, clicks around. Doesn't scale.
2. **Superpowers review subagents** — review code, not behavior. Missed the blank page.
3. **Coverage hook** — counts test existence, not test quality. 100% coverage, 0% confidence.
4. **Grep-based tests** — verify string presence in files. Structural, not functional.

## Assumptions (to validate)

1. Acceptance-first development is more cost-effective for agent workflows than unit-first
2. External verification (agent can't self-assess) is necessary for trust
3. DAL-scaled verification is economically viable (DAL-E near-zero cost, DAL-A high cost)
4. An agentic scenario synthesizer can find bugs that authored acceptance tests miss
5. Claude Code's `Stop` hook with `type: agent` is the right primitive for enforcement
6. The V-Model is the right mental model — not just a human process mapped to agents
7. Thin vertical slices produce better outcomes than horizontal layer decomposition

### Pain Point 12: Requirements approach must fit the product stage

Volere was designed for regulated industries where requirements are known, stakes are high, and traceability is mandatory. But commercial SW products go through stages where the need is fundamentally different:

| Stage | Need | Ceremony tolerance |
|-------|------|--------------------|
| Discovery / MVP | Ship fast, learn, throw away what doesn't work | Near zero |
| Product-market fit | Stabilize what works, build regression trust | Low-medium |
| Scaling (1K→1M users) | Rock-solid regression, compliance, auditability | Medium-high |
| Regulated / enterprise | Full traceability, audit trail, multi-dimensional compliance | High — mandatory |

A full Volere snow card with DAL, compliance dimensions, and schema validation may be the right tool at the scaling stage but too heavy for MVP. Conversely, a one-line acceptance criterion works for MVP but won't survive an audit.

**The requirement format must scale with the product, not be fixed from day one.**

### Requirement Capture Approaches — Stage Fit Assessment

| Approach | Strengths | Best stage fit | Agent-friendly? |
|----------|-----------|----------------|-----------------|
| **Volere snow cards** | Atomic, testable, traceable, multi-dimensional compliance | Scaling, Regulated | Yes — structured YAML, machine-readable |
| **Jobs to be Done** | Value-focused, lightweight, user-centered | Discovery, MVP | Partial — captures intent but not testable criteria |
| **User story mapping** | Visual, discovery-friendly, reveals gaps | Discovery | No — spatial, hard for agents to consume |
| **BDD/Gherkin** | Executable specifications, no translation gap from requirement to test | MVP, PMF | Yes — requirements *are* tests |
| **Metrics-driven** | Outcome-focused (retention, conversion), lets builder choose how | MVP, PMF | Yes — measurable, agent can optimize toward a number |
| **Lightweight acceptance criteria** | One-line fit criterion, minimal overhead | MVP | Yes — trivially parseable |
| **Novel/TBD** | Approaches that may only make sense in the agentic context | Unknown | Unknown |

**Open possibility:** The agentic age may produce requirement formats that don't exist yet. Agents have capabilities humans don't (running code instantly, spawning verifiers, reading entire codebases). A requirement format designed *for* agent consumption might look nothing like one designed for human teams. We should stay open to discovering this rather than assuming the answer is an existing framework.

## Open Questions

1. **What can the LLM reliably do vs. what does it fail at?** We need to understand Claude's actual capabilities (Code Intelligence, tool use, reasoning) to design verification around its failure modes, not generic human failure modes.
1b. **Is Volere the right requirement format, or one of several tools for different stages?** Need to assess each approach against the stage-need matrix and stay open to novel formats.
1c. **What does a requirement format designed *for* agent consumption look like?** Agents can execute code, spawn verifiers, read codebases. A format designed for their capabilities might be fundamentally different from one designed for human teams.
2. **Should Volere own the execution layer or stay as the verification layer?** Replace Superpowers, extend it, or add a gate between them?
3. **What does an acceptance test look like for different product types?** CLI tool, web app, API service, mobile app — the verification method changes.
4. **How do you write acceptance tests for requirements that haven't been validated by users yet?** MVP stage: requirements are hypotheses. Do you still invest in acceptance tests?
5. **What's the right granularity for the chaos/synthesizer?** Per-card? Per-release? Continuous?
6. **How do other heavy adopters of agentic coding (beyond Stripe) handle verification?** Need broader research.
7. **Is the V-Model the right frame, or is there a better model for agent verification?** The V-Model assumes sequential phases. Agents work in rapid iterations. Does the model need adapting?

## Key Insight (updated)

> **Layer 1 (March 30):** "Nothing forces agents to build well."
> 
> **Layer 2 (April 2, morning):** "Agents cannot be trusted to verify their own work, and the economics demand that verification effort concentrates at the acceptance level."
> 
> **Layer 3 (April 2, afternoon):** "We're not building a requirements framework. We're searching for the development methodology for the agentic age — how human+agent teams discover, build, ship, observe, and iterate on commercial products they can trust. Requirements, execution, verification, and observation are all components of this methodology. The Volere experiment taught us what works (structured fit criteria, DAL scaling, coverage tracking) and what doesn't (self-assessing agents, horizontal plans, theater tests). The methodology we're looking for may draw from Volere, from V-Model, from novel approaches that only make sense with agents — or from something we haven't discovered yet."

## Research Completed

| Source | Key Pattern | Applicable? |
|--------|-------------|-------------|
| Superpowers | Horizontal plans, unit TDD, self-review | Current approach — identified as root cause |
| gstack | Real browser QA, scope drift detection | Browser QA valuable; advisory not enforced |
| GSD | Atomic plans in waves, exists/substantive/wired verifier | Verifier model good; no V-Model awareness |
| Stripe | External deterministic graders, agent never self-assesses | Most aligned with our needs |
| Claude Code | `Stop` hook blocks completion, `type: agent` spawns verifier | Key primitive for enforcement |

## Next Steps

1. **Deep-read Claude Code documentation** — understand LLM capabilities, Code Intelligence, plugin model. The methodology must be built on what agents *can* do, not what we wish they could do.
2. **Map agent failure modes** — not human failure modes. Agents don't make typos. They ship blank pages with confidence. The verification model must target their actual failure patterns.
3. **Study what the Volere experiment taught us** — what worked (fit criteria, DAL, coverage tracking), what didn't (self-assessment, horizontal plans, theater tests), and what's still unknown.
4. **Assess requirement approaches against product stages** — Volere, JTBD, BDD, metrics-driven, novel. Which fits where? Is there a progression?
5. **Prototype acceptance-first workflow** — on one real feature, with external verification. Does it actually produce better outcomes?
6. **Stay open** — the methodology may not look like anything that exists today. Agents have capabilities humans don't. A methodology designed for human+agent teams might be fundamentally different from one designed for human teams.
