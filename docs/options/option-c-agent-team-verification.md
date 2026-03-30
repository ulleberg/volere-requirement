# Option C: Agent Team Verification — Quality Through Multi-Agent Review

## Approach

Instead of encoding quality in documents (Option A) or tooling (Option B), encode it in **agent team structure**. Extend the existing thul-agents architecture with dedicated verification roles. Quality emerges from specialists challenging each other's work — just like it does in human engineering teams.

The insight from Experiment 001: skilled agent teams self-organize to produce verification artifacts and catch contradictions. This option leans into that finding and makes it systematic.

## How It Works

### 1. V-Model Roles Map to Agent Specialists

```
V-Model Level        Definition Agent          Verification Agent
─────────────        ────────────────          ──────────────────
Requirements         product-owner             acceptance-tester
Architecture         chief-technical-officer    architecture-reviewer
Design               domain-engineer            test-engineer
Code                 implementing-agent         code-reviewer
Compliance           compliance-officer         auditor
```

Each level has a pair: one agent defines, another verifies. They challenge each other through A2A protocol.

### 2. Verification Protocol

```yaml
# protocols/v-model-verification.yaml
phases:
  requirements:
    define: product-owner
    verify: acceptance-tester
    gate: "Every requirement has a testable fit criterion"
    output: requirements/*.yaml

  architecture:
    define: chief-technical-officer
    verify: architecture-reviewer
    gate: "No boundary violations, all interfaces documented"
    input: requirements/*.yaml
    output: docs/ARCHITECTURE.md, docs/interfaces/

  design:
    define: domain-engineer  # (embedded, fullstack, mobile, etc.)
    verify: test-engineer
    gate: "Every module has tests, coverage > threshold"
    input: docs/ARCHITECTURE.md
    output: src/, tests/

  code:
    define: implementing-agent
    verify: code-reviewer
    gate: "Tests pass, no new complexity, no boundary violations"
    input: tests/ (TDD — tests first)
    output: src/

  compliance:
    define: compliance-officer
    verify: auditor
    gate: "All compliance dimensions satisfied with evidence"
    input: requirements/*.yaml (fit_criteria)
    output: docs/compliance/evidence/
```

### 3. The Review Loop

```
1. Define-agent produces work
2. Work is committed to a feature branch
3. Verify-agent is spawned and reviews the work:
   - Reads the relevant V-Model level artifacts
   - Checks against gate criteria
   - Produces a review document with:
     - PASS items (with evidence)
     - FAIL items (with specific problems)
     - QUESTIONS (ambiguities needing human input)
4. If FAIL: define-agent addresses feedback, loop back to step 1
5. If PASS: move to next V-Model level or merge
6. Human reviews at phase boundaries (not every commit)
```

### 4. Specialist Verification Skills

Each verification role gets a skill defining HOW to review:

```
agents/
├── acceptance-tester/
│   └── skills/
│       └── verify-requirements/
│           └── skill.md          # How to check fit criteria testability
├── architecture-reviewer/
│   └── skills/
│       └── verify-architecture/
│           └── skill.md          # How to check boundaries, interfaces, cohesion
├── test-engineer/
│   └── skills/
│       └── verify-coverage/
│           └── skill.md          # How to check test quality (not just coverage)
├── code-reviewer/
│   └── skills/
│       └── verify-implementation/
│           └── skill.md          # How to review for anti-patterns
└── auditor/
    └── skills/
        └── verify-compliance/
            └── skill.md          # How to check regulatory dimensions
```

### 5. Team Assembly Per DAL Level

```yaml
# DAL-E (cosmetic): No verification agents
team: [implementing-agent]

# DAL-D (minor): Code review only
team: [implementing-agent, code-reviewer]

# DAL-C (moderate): + test engineer
team: [implementing-agent, code-reviewer, test-engineer]

# DAL-B (critical): + architecture reviewer
team: [implementing-agent, code-reviewer, test-engineer, architecture-reviewer]

# DAL-A (catastrophic): Full team
team: [product-owner, implementing-agent, code-reviewer, test-engineer,
       architecture-reviewer, acceptance-tester, compliance-officer, auditor]
```

### 6. Integration with thul-agents

This option extends what already exists:

```
thul-agents/
├── agents/
│   ├── acceptance-tester/        # NEW verification role
│   │   ├── SOUL.md
│   │   ├── skills/verify-requirements/
│   │   └── expertise/volere/     # Trained on Volere methodology
│   ├── architecture-reviewer/    # NEW verification role
│   │   ├── SOUL.md
│   │   ├── skills/verify-architecture/
│   │   └── expertise/fitness-functions/
│   ├── auditor/                  # NEW verification role
│   │   ├── SOUL.md
│   │   ├── skills/verify-compliance/
│   │   └── expertise/standards/  # FCC, RED, IEC 61508, etc.
│   └── ...existing roles...
├── protocols/
│   ├── v-model-verification.md   # NEW protocol
│   └── ...existing protocols...
└── roster.yaml                   # Updated with new roles
```

## Strengths

- **Builds on proven results.** Experiment 001 showed skilled teams catch contradictions and self-organize. This makes that systematic.
- **Natural fit with thul ecosystem.** Extends existing agent architecture, SOUL.md pattern, A2A protocol, and collaboration modes.
- **Human-like quality process.** Mirrors how good engineering teams work — specialists define, other specialists verify, disagreements surface problems.
- **Cross-document coherence built-in.** Multiple agents reviewing the same artifacts from different perspectives catches what single-agent work misses.
- **Flexible and adaptive.** Agent reviewers can exercise judgement, catch novel problems, and ask questions — unlike rigid CI checks.
- **Low tooling investment.** Uses existing thul-studio spawning, A2A, and session management. New code is mostly skills and protocols.

## Weaknesses

- **Expensive at runtime.** Every verification pass spawns additional agent sessions. DAL-A with 8 agents is 8x the token cost of solo work. At scale, this is significant.
- **Non-deterministic.** Agent reviews vary between runs. The same code might pass one review and fail another. No guarantee of consistency.
- **Soft constraints only.** Agent reviewers can be wrong, miss things, or rubber-stamp work. There's no hard enforcement — a bad review lets bad code through.
- **Review quality depends on SOUL.md + expertise.** If the architecture-reviewer's expertise is weak, reviews are weak. The "garbage in" problem moves from requirements to reviewer competence.
- **No automated traceability.** Traceability lives in review documents and agent conversations, not in machine-queryable links. Impact analysis requires re-running reviews, not querying a graph.
- **Scaling problem.** For a 100-requirement project, running full verification teams per requirement is prohibitively expensive. Need batching/prioritisation logic.
- **The "quis custodiet" problem.** Who reviews the reviewers? An architecture reviewer with incorrect mental model consistently approves bad architecture.

## Effort Estimate

- New verification SOUL.md files: Small
- Verification skills (5 roles): Medium
- V-Model verification protocol: Small
- Team assembly logic per DAL: Small
- Integration with Studio spawning: Small
- Training curricula for verification roles: Medium
- **Total: Small-Medium, mostly content (SOUL.md, skills, curricula) not code**

## Best For

Projects where the team structure already exists (thul ecosystem). Situations where flexibility and judgement matter more than determinism. Early-stage projects where requirements are still evolving. Contexts where human-like review quality is more valuable than automated enforcement.
