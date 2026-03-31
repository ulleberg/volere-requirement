---
name: classify-risk
description: Assigns DAL level (A-E) to a change based on blast radius, reversibility, and affected requirements — scales verification effort to risk. Use when determining verification depth for a change, writing a new requirement, or deciding if tests can be skipped.
---

# Classify Risk

Assign a Design Assurance Level (A-E) to a code change, feature, or requirement. The DAL level determines how much verification is required — from linting only (E) to full multi-agent review with mutation testing (A).

## When to Use

- Before implementing any change — "What DAL is this?"
- When writing a new requirement — "How critical is this?"
- When an agent is about to skip tests — "Does the DAL allow that?"
- When deciding verification depth for a PR

## DAL Levels

| DAL | Failure Impact | Verification Required | Example Changes |
|-----|---------------|----------------------|-----------------|
| **A** | Catastrophic — data loss, security breach, safety incident | Unit + integration + system + acceptance + performance + mutation + multi-agent review | Auth bypass fix, DB migration, encryption change, safety-critical control logic |
| **B** | Critical — service degradation, data corruption, secrets exposure | Unit + integration + system + acceptance + performance + code review | Session data persistence, secrets handling, CORS configuration, API contract changes |
| **C** | Moderate — feature broken, user-visible impact, workaround may exist | Unit + integration + system + acceptance + code review | New feature, state detection logic, file preview, WebSocket handling |
| **D** | Minor — cosmetic issue, easy workaround, limited user impact | Unit + basic integration | Config default change, log format, error message text, minor UI tweak |
| **E** | Cosmetic — no user impact, no behavioral change | Linting + type checking | Documentation, CSS fix, comment update, dependency version bump (patch) |

## Classification Method

Ask these three questions:

### Q1: What's the blast radius?

| Blast Radius | Score |
|-------------|-------|
| Affects all users / all sessions / all machines | +2 |
| Affects one feature used frequently | +1 |
| Affects one feature used rarely | 0 |
| Affects internal-only / no user visibility | -1 |

### Q2: Is it reversible?

| Reversibility | Score |
|--------------|-------|
| Irreversible — data loss, sent messages, published data | +2 |
| Hard to reverse — DB migration, config deployed to N machines | +1 |
| Easy to reverse — code change, revert and redeploy | 0 |
| Automatically reversible — feature flag, A/B test | -1 |

### Q3: What requirements does it affect?

| Requirement type | Score |
|-----------------|-------|
| Security UR (UR with security fit criteria) | +2 |
| Safety / regulatory UR (compliance dimensions) | +2 |
| Data integrity UR (persistence, backup, corruption) | +1 |
| Functional UR (core feature) | 0 |
| Operational UR (monitoring, logging) | 0 |
| Look-and-feel / usability UR | -1 |
| No UR affected (pure refactoring within tested boundaries) | -1 |

### Scoring

| Total Score | DAL |
|------------|-----|
| 5-6 | A |
| 3-4 | B |
| 1-2 | C |
| -1 to 0 | D |
| -2 to -3 | E |

### Override Rules

Regardless of score:
- **Any change to auth, encryption, or secrets → minimum DAL-B**
- **Any change touching regulatory fit criteria → minimum DAL-B**
- **Any DB migration or schema change → minimum DAL-B**
- **Pure documentation or comments → DAL-E** (even if the file is in a critical module)
- **Requirement's own DAL field** — the change's DAL cannot be lower than the affected requirement's DAL
- **Any UR with fit criteria that imply system-level or higher verification → minimum DAL-C**
  Scenarios: browser-facing ("renders", "displays", "page"), multi-service ("service calls", "API responds"), stateful/temporal ("expires after", "timeout triggers"), data pipeline ("pipeline produces", "downstream receives"), deployment ("deploys to", "in production", "across machines"), hardware-adjacent ("microphone", "camera", "speaker").
  Rationale: Unit tests cannot verify behavior that spans browsers, services, time, pipelines, environments, or hardware. See `audit-tests` skill for the full verification level mismatch table.

## Verification Requirements Per DAL

Read from the project's `.volere/profile.yaml`. Default:

```yaml
A:  # catastrophic
  hooks: [check-secrets, check-traceability, check-fit-criteria]
  ci: [lint, typecheck, test, coverage, mutation, fitness-functions]
  review: [code-reviewer, test-engineer, architecture-reviewer, security-engineer]
  verification:
    unit: required
    integration: required
    system: required
    acceptance: required
    performance: required
    visual: required
    mutation: required
    manual: forbidden

C:  # moderate (default)
  hooks: [check-secrets, check-traceability]
  ci: [lint, typecheck, test, coverage]
  review: code-reviewer
  verification:
    unit: required
    integration: required
    system: required
    acceptance: required
    manual: forbidden

E:  # cosmetic
  hooks: []
  ci: [lint, typecheck]
  review: none
  verification:
    unit: optional
    integration: optional
    system: optional
    acceptance: optional
    manual: optional
```

## How Agents Use This

### Before implementing

```
1. Agent reads the task description
2. Agent identifies affected requirements (from volere trace or commit context)
3. Agent runs classify-risk mentally:
   - Q1: blast radius → score
   - Q2: reversibility → score
   - Q3: requirement type → score
   - Total → DAL level
4. Agent reads the DAL profile for that level
5. Agent follows the verification requirements for that DAL
```

### In the commit message

```
Fix CORS restriction to Tailscale origins (UR-027, DAL-B)

Restrict Access-Control-Allow-Origin to configured Tailscale hostnames.
Agent card endpoint keeps CORS * per A2A spec.
```

Including the DAL in the commit message makes verification expectations visible in the git log.

### When an agent tries to skip verification

If an agent says "tests pass, I'm done" but the DAL requires system tests:

```
DAL-B requires: unit + integration + system + acceptance + performance
You ran: unit + integration
Missing: system, acceptance, performance

Run the missing verification before claiming this is done.
```

The check-fit-criteria hook (v0.6) enforces this at push time.

## Examples

### Example 1: CORS Fix
- Q1: Affects all API routes (all users) → +2
- Q2: Easy to reverse (code change) → 0
- Q3: Security UR (UR-027) → +2
- Total: 4 → **DAL-B**
- Override: security change → minimum DAL-B ✓

### Example 2: Fix typo in error message
- Q1: Affects one error path (rare) → 0
- Q2: Easy to reverse → 0
- Q3: No UR affected → -1
- Total: -1 → **DAL-D**

### Example 3: Database migration
- Q1: Affects all data (all users) → +2
- Q2: Hard to reverse (migration) → +1
- Q3: Data integrity UR → +1
- Total: 4 → **DAL-B**
- Override: DB migration → minimum DAL-B ✓

### Example 4: Add CSS class for session card
- Q1: Affects one UI element → 0
- Q2: Easy to reverse → 0
- Q3: Look-and-feel UR → -1
- Total: -1 → **DAL-D**

### Example 5: Change JWT signing algorithm
- Q1: Affects all auth (all users) → +2
- Q2: Irreversible (existing tokens invalid) → +2
- Q3: Security UR → +2
- Total: 6 → **DAL-A**

### Example 6: Add grid page for session management
- Q1: Affects one feature used frequently → +1
- Q2: Easy to reverse → 0
- Q3: Functional UR → 0
- Total: 1 → **DAL-C**
- Override: browser-facing fit criteria ("user can see sessions in a grid") → minimum DAL-C ✓
- Note: system-level verification required (Playwright or browser check, not just API test)

## Integration

- **write-requirement:** Each UR gets a DAL field. classify-risk helps determine what DAL to assign.
- **audit-tests:** Coverage gaps prioritised by DAL (A-gaps first).
- **check-fit-criteria hook (v0.6):** Reads DAL from affected requirements and enforces verification depth.
- **review-requirements:** Full review team (5 agents) only at DAL-A. Lighter reviews at lower DALs.
