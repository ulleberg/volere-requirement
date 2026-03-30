# Retrofitting Volere to an Existing Project

Apply the Volere Agentic Framework to a project that already has code, tests, and (possibly) informal requirements.

## Prerequisites

- An existing git repository with source code
- Some form of existing requirements (user stories, tickets, acceptance criteria, or just "what it does")
- Existing tests (any framework)

## Step 1: Initialize

```bash
volere init --dal C
```

This creates:
- `docs/requirements/` — where requirement cards will live
- `.volere/profile.yaml` — DAL configuration
- `.volere/boundaries.yaml` — module boundary rules
- Git hooks — secrets, traceability, fit criteria checks

## Step 2: Capture Existing Requirements

Your project already has requirements — they're just not in snow card format. Look for them in:

- **Issue tracker** — tickets, user stories, epics
- **README** — "features" section, usage examples
- **Tests** — test names and assertions often encode requirements
- **CLAUDE.md / docs** — conventions, constraints, acceptance criteria
- **Stakeholder conversations** — "it must do X" statements

For each requirement found, create a card:

```bash
volere new --type functional
# Edit the generated card with the requirement details
```

Start with the most critical 5-10 requirements. You don't need to capture everything at once.

**Tip:** Don't force-fit. If a requirement doesn't feel like a UR, it might be a BUC (business context), PUC (user interaction), or TC (technical constraint).

## Step 3: Trace Existing Code

```bash
volere trace
```

This maps your source files to requirements. On first run, most code will be ORPHANED (no requirement linked). That's expected — it tells you where to focus next.

Priorities:
1. **Critical orphaned code** — important code with no requirement → write the missing requirement
2. **Dead code** — code that serves no requirement and no test → candidate for removal
3. **Partially traced** — code that serves a requirement but isn't fully linked → add traceability

## Step 4: Audit Existing Tests

```bash
volere review  # select "trace review" type
```

Or use the `audit-tests` skill directly. This classifies your existing tests:

| Classification | What it means | Action |
|---------------|---------------|--------|
| **VERIFIES** | Test directly asserts a fit criterion | Keep — these are valuable |
| **SUPPORTS** | Test checks implementation, not the criterion | Consider rewriting to verify the criterion |
| **THEATER** | Test has no connection to any requirement | Remove — it inflates coverage |
| **REDUNDANT** | Test duplicates another's coverage | Remove the weaker one |

Don't be surprised if < 30% of tests VERIFY fit criteria. This is normal for projects without structured requirements.

## Step 5: Fill Gaps

After tracing and auditing, you'll have a clear picture:

```bash
volere coverage
```

This shows:
- Fit criteria without tests (write tests)
- Requirements without code (implement or remove)
- Code without requirements (write requirements or remove code)

Prioritize by DAL level — DAL-A gaps first, DAL-E gaps can wait.

## Step 6: Set DAL Levels

Review each requirement's DAL classification:

```bash
# Use the classify-risk skill or set manually in each card
```

Most requirements in an existing project start at DAL-C (moderate). Escalate:
- Auth, encryption, secrets → DAL-B minimum
- Data migrations, safety-critical → DAL-A
- Cosmetic, docs → DAL-E

## What NOT to Do

- **Don't rewrite all tests at once.** Classify first, then improve incrementally.
- **Don't capture every possible requirement.** Start with 5-10 critical ones. Add more as you work.
- **Don't clean code before tracing.** The mess is evidence — dead code reveals derived requirements, unnecessary tests reveal theater.
- **Don't treat this as a documentation exercise.** The goal is verification, not paperwork.

## Timeline

A typical retrofit takes 2-3 sessions:

1. **Session 1:** Init, capture 5-10 requirements, first trace
2. **Session 2:** Audit tests, classify, fill critical gaps
3. **Session 3:** Set DAL levels, configure hooks, establish workflow

After that, the framework maintains itself through hooks and CI.
