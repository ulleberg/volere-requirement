---
name: review-requirements
description: Run agent team reviews on requirements — detects review type (full, validation, trace) and generates parameterised team prompts from proven patterns
---

# Review Requirements

Assemble an agent team to review, validate, or trace requirements. Three review types, each with a proven pattern. The skill detects which type is needed and generates the team assembly prompt.

## When to Use

- "Review the requirements"
- "Are these URs right?"
- "Validate our changes"
- "Trace code to requirements"
- "Find dead code and test theater"
- After writing or updating requirements (write-requirement skill)
- Before any major refactoring or cleanup

## Review Type Detection

Check the project state to determine which review type to run:

| Condition | Review Type | Team Size |
|-----------|------------|-----------|
| No `docs/requirements/reviews/` directory | **Full Review** (Pass 1) | 5 agents |
| Reviews exist, requirements changed since last review | **Validation Review** (Pass 1.5) | 3 agents |
| User asks to "trace" or "find dead code" or "audit tests" | **Trace Review** (Pass 2) | 4 agents |

**How to detect "requirements changed since last review":**
```bash
# Compare last review date vs last requirement modification
LAST_REVIEW=$(stat -f %m docs/requirements/reviews/synthesis.md 2>/dev/null || echo 0)
LAST_REQ=$(find docs/requirements -name "*.yaml" -newer docs/requirements/reviews/synthesis.md 2>/dev/null | head -1)
# If LAST_REQ is non-empty, requirements changed → validation review
```

### When NOT to run a review

- **< 5 requirements:** Too few for a multi-agent team. Use the write-requirement skill to improve individual cards instead.
- **Single UR added or changed:** Run a targeted validation, not a full review. Or just have the implementing agent review the card against the quality checklist in write-requirement.
- **No codebase yet:** Trace review requires code to exist. Use full review for requirements-only projects.

## Before Starting

1. **Count and list requirements:**
   ```bash
   ls docs/requirements/*.yaml 2>/dev/null | wc -l
   ls docs/requirements/*.yaml 2>/dev/null
   ```

2. **Find the agent roster:**
   Look for the roster in order:
   - `.volere/context.yaml` — `agents` section if present
   - Project's own `roster.yaml`
   - `${VOLERE_AGENTS_PATH}/roster.yaml` if the env var is set
   - Ask the user for the path to their agent definitions
   - If none found, use **Zero-Agent Mode** (see below)

3. **Read the project context:**
   ```bash
   cat docs/requirements/context.yaml   # stakeholders, scope, glossary
   ```

4. **Check if agent teams are enabled:**
   ```json
   // ~/.claude/settings.json
   { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
   ```

## Zero-Agent Mode

When no agent roster is configured (`${VOLERE_AGENTS_PATH}` is unset and `.volere/context.yaml` has no `agents` section), the review runs all perspectives sequentially in one Claude Code session:

1. Each review perspective gets its own heading
2. The agent adopts each role in sequence (architecture-reviewer → test-engineer → security-engineer → synthesis-lead)
3. Each perspective produces its analysis before the next begins
4. The synthesis runs last, consolidating all perspectives

This is slower but requires no infrastructure beyond a single Claude Code session.

## Review Type 1: Full Review (Pass 1)

**When:** First review, or major rewrite of requirements.

**Team:** 5 agents
- Architecture Reviewer (CTO) — fit criteria quality, missing URs, cross-UR dependencies, derived requirements
- Test Engineer — test quality, fit criteria testability, coverage gaps, test theater
- Security Engineer — security dimensions, threat model gaps, multi-dimensional fit criteria
- DevOps Engineer — operational gaps, observability, scalability, data integrity
- Synthesis Lead — cross-cutting findings, contradictions, priority-ranked recommendations

**Prompt template:**

```
Create an agent team to review the requirements in docs/requirements/.

Context: This project has {COUNT} requirements ({UR_COUNT} URs, {TC_COUNT} TCs).
The goal: Are these the right requirements? Are we missing any? Are the fit criteria
truly testable and specific?

All teammates should read:
- docs/requirements/*.yaml (all requirement cards)
- docs/requirements/context.yaml (project scope, stakeholders, glossary)
- ARCHITECTURE.md (system overview)
- CLAUDE.md (conventions and gotchas)

Spawn these teammates:

1. Architecture Reviewer — spawn with prompt:
   "You are the Architecture Reviewer (architecture-reviewer role).
   {LOAD_SOUL: architecture-reviewer}

   Read all requirement cards in docs/requirements/.
   Read ARCHITECTURE.md and CLAUDE.md.

   Deliverable — write to docs/requirements/reviews/architecture-review.md:
   1. Fit criterion quality: score each UR 1-5 on specificity and measurability
   2. Missing URs: requirements implied by the architecture but not captured
   3. Cross-UR dependencies: conflicts, implicit couplings, missing dependency annotations
   4. Derived requirements: implementation contracts that should be formalised as TCs

   Stay in your lane — architecture and completeness."

2. Test Engineer — spawn with prompt:
   "You are the Test Engineer (test-engineer role).
   {LOAD_SOUL: test-engineer}

   Read all requirement cards in docs/requirements/.
   Read the test files and any existing test plan.

   Deliverable — write to docs/requirements/reviews/test-review.md:
   1. Fit criteria testability: can you write a test for each criterion? Score 1-5.
   2. Test coverage: which URs/TCs have tests? Which have gaps?
   3. Test theater: tests that check implementation details, not fit criteria
   4. Recommendations: tests to add, rewrite, or remove

   Stay in your lane — test quality and coverage."

3. Security Engineer — spawn with prompt:
   "You are the Security Engineer (security-engineer role).
   {LOAD_SOUL: security-engineer}

   Read all requirement cards in docs/requirements/.
   Read CLAUDE.md for security-relevant gotchas.

   Deliverable — write to docs/requirements/reviews/security-review.md:
   1. Security dimension completeness: which URs need security fit criteria?
   2. Threat model gaps: what threats aren't addressed by any UR?
   3. Multi-dimensional fit criteria: security conditions to add to existing URs
   4. Attack chain analysis: identify exploitable combinations of gaps

   Stay in your lane — security only."

4. DevOps Engineer — spawn with prompt:
   "You are the DevOps Engineer (devops-engineer role).
   {LOAD_SOUL: devops-engineer}

   Read all requirement cards in docs/requirements/.
   Read ARCHITECTURE.md for deployment model.

   Deliverable — write to docs/requirements/reviews/ops-review.md:
   1. Operational gaps: logging, metrics, alerting, backup, graceful degradation
   2. Scalability: what breaks at 10x current load?
   3. Data integrity: persistence mechanisms, corruption recovery
   4. Deployment: automation, rollback, health verification

   Stay in your lane — operations and reliability."

5. Synthesis Lead — spawn with prompt:
   "You are the Synthesis Lead (synthesis-lead role).
   {LOAD_SOUL: synthesis-lead}

   Wait for all four reviewers to complete, then read all reviews.

   Deliverable — write to docs/requirements/reviews/synthesis.md:
   1. Cross-cutting findings: themes from 2+ reviewers
   2. Contradictions: where reviewers disagree (and your assessment)
   3. Priority-ranked missing URs with proposed numbers
   4. Priority-ranked fit criteria rewrites
   5. Recommendations: keep, modify, split, or remove for each UR
   6. Questions for stakeholder — ambiguities only they can resolve

   Challenge the reviewers. Push back on weak findings."

Have teammates discuss and challenge each other's findings.
```

**Replace {PLACEHOLDERS}:**
- `{COUNT}`, `{UR_COUNT}`, `{TC_COUNT}` — from file listing
- `{LOAD_SOUL: role}` — replace with: "Read your identity: `${VOLERE_AGENTS_PATH}/agents/<role>/SOUL.md`" if the env var is set, otherwise omit the SOUL line and proceed in Zero-Agent Mode

**Output structure:**
```
docs/requirements/reviews/
├── architecture-review.md
├── test-review.md
├── security-review.md
├── ops-review.md
└── synthesis.md
```

## Review Type 2: Validation Review (Pass 1.5)

**When:** Requirements were updated after a full review. Validates changes are consistent.

**Team:** 3 agents
- Architecture Reviewer (CTO) — cross-UR consistency, dependency completeness, TC traceability
- Test Engineer — fit criteria testability of changes, test alignment
- Synthesis Lead — verdict (ready for next phase?), blockers, improvements confirmed

**Prompt template:**

```
Create an agent team to validate the updated requirements.

Context: We updated requirements after a review. {CHANGE_SUMMARY}.
This validation checks that our changes are internally consistent and testable.

All teammates read: docs/requirements/*.yaml, docs/requirements/reviews/synthesis.md

1. Test Engineer — "Validate testability of changed fit criteria.
   For each changed UR: can you write a concrete test? Score 1-5.
   For each TC: does the fit criterion match existing tests?
   Write to docs/requirements/reviews/validation-test.md"

2. Architecture Reviewer — "Validate cross-UR consistency.
   Do any URs conflict? Are dependencies complete? Do TCs trace correctly?
   Write to docs/requirements/reviews/validation-architecture.md"

3. Synthesis Lead — "Wait for both, then synthesise.
   Verdict: ready for next phase? Blockers? Issues?
   Write to docs/requirements/reviews/validation-synthesis.md
   Challenge both reviewers — don't rubber-stamp."
```

**Replace `{CHANGE_SUMMARY}`** with what changed: "rewrote 13 fit criteria, added 17 URs, created 12 TCs" etc.

## Review Type 3: Trace Review (Pass 2)

**When:** Requirements are stable. Need to map code to requirements and find gaps.

**Team:** 4 agents
- Code Tracer — every source file → which UR/TC does it serve?
- Test Tracer — every test → does it verify a fit criterion (VERIFIES/SUPPORTS/THEATER/REDUNDANT)?
- Frontend Tracer — browser code → which URs? Dead CSS/JS?
- Synthesis Lead — dead code list, test theater list, coverage gaps, cleanup plan

**Prompt template:**

```
Create an agent team to trace the codebase back to requirements.

Context: {COUNT} requirements ({UR_COUNT} URs, {TC_COUNT} TCs), all reviewed.
Need to know: does the code match? What's dead? What's missing?

All teammates read: docs/requirements/*.yaml, ARCHITECTURE.md, CLAUDE.md

1. Code Tracer — "For every source file, determine which UR/TC it serves.
   Flag ORPHANED files (no requirement). Flag PARTIAL (some functions trace, others don't).
   Write to docs/requirements/reviews/trace-code.md"

2. Test Tracer — "For every test, classify as VERIFIES (tests fit criterion),
   SUPPORTS (indirect), THEATER (implementation detail), REDUNDANT (duplicate).
   Write to docs/requirements/reviews/trace-tests.md"

3. Frontend Tracer — "For browser code, map components to URs.
   Find dead CSS, unused JS, legacy artifacts.
   Write to docs/requirements/reviews/trace-frontend.md"

4. Synthesis Lead — "Synthesise into a cleanup plan:
   Phase 1: safe removals (zero risk)
   Phase 2: test rewrites (verify fit criteria, not implementation)
   Phase 3: new tests (uncovered fit criteria)
   Phase 4: code changes (implementation doesn't match requirement)
   Write to docs/requirements/reviews/trace-synthesis.md"
```

**Note:** If the project has no frontend (API-only, CLI tool), skip the Frontend Tracer and use a 3-agent team.

## Synthesis Scoring Criteria

The synthesis agent evaluates review quality using these metrics:

| Metric | What it measures | Target |
|--------|-----------------|--------|
| **Specificity** | % of findings that reference real system components (not generic advice) | > 85% |
| **Testability** | % of fit criteria scored as testable (3+ out of 5) | > 90% |
| **Cross-document coherence** | Number of cross-references between review documents | > 5 per review |
| **Contradiction detection** | Contradictions identified AND assessed (not just listed) | All assessed |
| **Actionability** | % of findings with a concrete proposed fix (not just "this is a problem") | > 80% |

If the synthesis scores below target, the review should be re-run with more specific instructions to the underperforming reviewer.

## After the Review

1. **Work through the synthesis questions** — these are decisions only the stakeholder can make
2. **Update requirements** based on decisions (use write-requirement skill for new URs)
3. **If changes are significant** — run a validation review (Pass 1.5) to check consistency
4. **When requirements are stable** — run a trace review (Pass 2) to map code and plan cleanup

## Quality Checklist

Before starting a review, verify:
- [ ] All requirement cards pass schema validation (`plugin/validate.sh`)
- [ ] context.yaml is filled in (scope, stakeholders, glossary)
- [ ] ARCHITECTURE.md exists and is current
- [ ] Agent teams are enabled in settings
- [ ] The roster path is known (for SOUL.md loading)
- [ ] The reviews/ directory is created: `mkdir -p docs/requirements/reviews`
