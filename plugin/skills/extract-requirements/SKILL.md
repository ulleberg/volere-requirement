---
name: extract-requirements
description: Extracts requirements from an existing codebase — scans code, tests, and docs to draft UR/TC cards grouped by module, then guides the owner through review where BUCs surface naturally. Use when retrofitting Volere to an existing project, onboarding to a new codebase, or analyzing what a system does.
---

# Extract Requirements

Read an existing codebase and extract User Requirements (URs) and Technical Constraints (TCs) as draft YAML snow cards. Group by module. Guide the codebase owner through review. Business Use Cases (BUCs) surface from the owner's answers — they are never invented by the agent.

## When to Use

- "Extract requirements from this codebase"
- "What are the requirements for this project?"
- "Retrofit Volere to this project"
- "Analyze this codebase for requirements"
- When applying Volere to an existing project for the first time
- When onboarding to a new codebase and wanting to understand what it does

## Before Starting

1. **Check if Volere is initialized:**
   ```bash
   ls .volere/profile.yaml docs/requirements/ 2>/dev/null
   ```
   If not initialized, run `volere init` first (or suggest it).

2. **Check repo size:**
   ```bash
   find . -type f \
     -not -path './.git/*' \
     -not -path '*/node_modules/*' \
     -not -path '*/vendor/*' \
     -not -path '*/dist/*' \
     -not -path '*/build/*' \
     -not -path '*/__pycache__/*' \
     | wc -l
   ```
   - **<500 files:** Proceed with whole-repo scan.
   - **500+ files:** Warn the owner: "This repo has N files. I can scan everything (slower, more comprehensive) or focus on a specific directory. Which do you prefer?" Proceed with the owner's choice.

3. **Read existing docs for context:**
   ```bash
   # These reveal informally stated requirements
   cat README.md 2>/dev/null
   cat CLAUDE.md 2>/dev/null
   cat ARCHITECTURE.md 2>/dev/null
   ls docs/ 2>/dev/null
   ```

4. **Create the staging area:**
   ```bash
   mkdir -p docs/requirements/draft
   ```

## Phase 1: Scan

Read the codebase systematically. For each source category, look for specific signals:

### Source Files (→ URs)

Read source files to understand what the system does. Look for:

| Signal | What it reveals | Example |
|--------|----------------|---------|
| HTTP routes / API endpoints | Functional capabilities | `POST /api/sessions` → "System creates sessions" |
| UI components / pages | User-facing features | `GridPage.tsx` → "System displays sessions in a grid" |
| CLI commands / flags | User-facing operations | `--format json` → "System outputs in JSON format" |
| Business logic functions | Core domain behavior | `calculatePricing()` → "System calculates pricing" |
| Event handlers / listeners | Reactive behaviors | `onStatusChange()` → "System reacts to status changes" |
| Scheduled tasks / cron | Automated behaviors | `cleanupExpired()` → "System cleans up expired sessions" |

### Tests (→ Fit Criteria)

Read test files to find existing acceptance conditions:

| Signal | What it reveals |
|--------|----------------|
| Test assertions with thresholds | Measurable fit criteria: "response < 200ms" |
| Test assertions with counts | Countable fit criteria: "returns exactly 5 states" |
| Test assertions with specific values | Binary fit criteria: "header contains X-Frame-Options" |
| Test names describing behavior | Requirement descriptions: "TestUserCanCreateSession" |
| Test fixtures / setup | Operational constraints: requires database, needs auth token |

For each test, note:
- Which fit criterion it asserts (if any)
- Whether it VERIFIES (directly asserts criterion) or SUPPORTS (tests implementation)
- The `verification_method`: unit, integration, system, or acceptance

### Error Handling & Constraints (→ TCs)

| Signal | What it reveals |
|--------|----------------|
| Retry logic, circuit breakers | Reliability constraints |
| Timeouts, rate limits | Performance constraints |
| Input validation, sanitization | Security constraints |
| Schema validation, type checks | Data integrity constraints |
| Graceful degradation, fallbacks | Availability constraints |
| Transaction boundaries, locks | Consistency constraints |

### Config & Operations (→ Operational URs)

| Signal | What it reveals |
|--------|----------------|
| Environment variables | Deployment requirements |
| Config files, feature flags | Configuration requirements |
| Health check endpoints | Monitoring requirements |
| Logging, metrics, tracing | Observability requirements |
| Migration scripts | Data evolution requirements |

### Security Patterns (→ Security URs)

| Signal | What it reveals |
|--------|----------------|
| Auth middleware, JWT, OAuth | Authentication requirements |
| CORS headers, CSP policies | Browser security requirements |
| Secret management, encryption | Data protection requirements |
| RBAC, permissions checks | Authorization requirements |
| Rate limiting, IP filtering | Abuse prevention requirements |

### Existing Docs (→ URs or BUCs)

| Source | What it reveals |
|--------|----------------|
| README "features" section | Stated capabilities (often informal URs) |
| CLAUDE.md conventions | Technical constraints and operational requirements |
| ARCHITECTURE.md | Design decisions (may imply requirements) |
| Issue tracker references in code | Requirements with external context |
| TODO/FIXME comments | Missing or incomplete requirements |

### Grouping

As you scan, group findings by module. Use the top-level source directory structure:

```bash
# Detect module structure
ls -d */ src/*/ internal/*/ lib/*/ app/*/ cmd/*/ 2>/dev/null | head -20
```

If the structure is flat (everything in one directory), group by functional area instead (auth, api, storage, ui, etc.).

## Phase 2: Draft Cards

Convert findings into draft YAML cards. Use one card per distinct capability or constraint.

### Card Format

Follow the `write-requirement` skill format. For each draft card:

```yaml
id: UR-001
type: functional  # or performance, security, operational, etc.
title: "Short title of what the system does"
description: "One sentence: the system must [behavior]"
rationale: "Pending owner review"
fit_criteria:
  user:
    criterion: "Measurable condition from test or code"
    verification: test
    test_type: integration
    verification_method: integration  # unit | integration | system | acceptance
dal: C  # tentative — from classify-risk heuristics
priority: should  # default — owner confirms
status: proposed
origin:
  stakeholder: extract-requirements
  date: "2026-03-31"  # today's date
  trigger: "Codebase extraction"
  source: "internal/api/handler.go"  # file where this was found
```

### Fit Criteria Rules

- **From tests:** If a test directly asserts a condition, use that assertion as the fit criterion. Note `# source: test` in a YAML comment.
- **From code:** If no test exists but the code implies a constraint (e.g., timeout of 30s), derive the criterion. Note `# source: inferred` in a YAML comment.
- **Never fabricate thresholds.** If you can't determine a measurable condition, write the criterion as "Owner to define — [what needs measuring]" and flag it during review.

### DAL Assignment

Use `classify-risk` heuristics:
- Security, auth, encryption, secrets → minimum DAL-B
- Data persistence, migrations → minimum DAL-B
- Core user-facing features → DAL-C
- Config, logging, cosmetic → DAL-D or DAL-E

### Cross-Verify

While drafting, note cross-module dependencies:
- Security middleware that affects multiple routes → `cross_verify` lists affected URs
- Shared libraries used by multiple features → `cross_verify` on the library's TC

### Output

Write all cards to `docs/requirements/draft/`:

```bash
# Example output
docs/requirements/draft/UR-001.yaml
docs/requirements/draft/UR-002.yaml
docs/requirements/draft/TC-001.yaml
```

### Draft Summary

After writing all cards, present the summary with a proposed review order:

```
Extraction complete:
  N draft URs across M modules
  N draft TCs
  N fit criteria from existing tests
  N fit criteria inferred from code

Modules:
  module-a/  — N URs, N TCs
  module-b/  — N URs, N TCs
```

### Proposed Review Order

Propose a review order following the V-Model bottom-up principle, with rationale:

1. **TCs and enforcement first** — Implementation constraints, hooks, validation rules, schema enforcement. These define what the system *guarantees*. Getting these right first means URs can accurately reference them in `depends_on`.

2. **Core features second** — CLI commands, APIs, user-facing operations. These are concrete and testable. Reviewing them second lets you link each feature to the TCs it depends on.

3. **Guidance and orchestration last** — Skills, templates, catalogs, documentation. These are softer — they guide agent behavior rather than mechanically enforce it. Reviewing last means the full TC/UR foundation exists for accurate `depends_on` and `cross_verify`.

**The principle:** Review bottom-up through the V-Model. Constraints anchor to code. Features build on constraints. Guidance orchestrates everything above. This ensures each layer's dependencies are confirmed before the layer that depends on them.

Present this order with module-specific rationale. The owner can override it, but the default should always be bottom-up.

## Phase 3: Owner Review

Present one module at a time. Let the owner choose which module to start with.

### Per-Card Review

Present each card one at a time in this structured format. The agent leads — the owner verifies and accepts.

```
TC-001: [Title]

  "[Description]"

  Fit criterion: [criterion]
  DAL: [level] | Priority: [priority] | Serves: [parent IDs]
  Tested: [Yes (test N-M) / Inferred]

  Assessment: [Agent's judgment on whether DAL and priority are right, with reasoning]

  Why this exists: [Agent's best understanding of the real-world pain or
  principle that created this requirement — traced to project insights,
  docs, or code patterns. Not invented — derived from evidence.]

  Proposed BUC link: [If the "why" points to a broader business need,
  name it here. BUC will be drafted after the TC/UR pass.]

  Confirm?
```

**The agent leads the review.** Don't just present data and ask three questions — provide your assessment, explain why it exists, and propose the BUC link. The owner's job is to verify and correct, not to do the analysis.

**Pacing:** One card per message. Wait for the owner's response before presenting the next card. The owner can say:
- "confirm" — accept as-is, move to next
- "edit [field]: [value]" — update and re-present
- "reject" — delete, move to next
- "confirm 2-5" — batch confirm (skip individual presentation)
```

### Handling Responses

**Confirm:** Card stays as-is. Move to next card.

**Reject:** Delete the draft card. Note the rejection reason (may reveal a misunderstanding).

**Edit:** Update the card with the owner's changes. Re-present for confirmation.

**Batch mode:** If the owner says "confirm 1-5, reject 6" — honor that. Don't force one-at-a-time.

### BUC Surfacing

When the owner answers "why does this exist?":

1. Check if the answer maps to an existing BUC in the draft set
2. If not, draft a new BUC card:

```yaml
id: BUC-001
type: business-use-case
title: "Business process this feature supports"
description: "From the owner's explanation"
rationale: "Owner stated during extraction review"
fit_criteria:
  user:
    criterion: "Owner to define — what makes this business process successful?"
    verification: review
dal: C
priority: must  # BUCs are usually must — the business needs them
status: proposed
origin:
  stakeholder: "[owner name]"
  date: "2026-03-31"
  trigger: "Extraction review"
```

3. Link URs to the BUC: add `depends_on: [BUC-001]` to the URs that serve it
4. Present the BUC for confirmation in the same review pass

### Module Complete

After reviewing all cards in a module:

```
Module [name] review complete:
  Confirmed: N URs, N TCs
  Rejected: N cards
  New BUCs: N

Next module: [name] (N URs, N TCs) — or "done" to commit confirmed cards
```

## Phase 4: Commit

After the owner has reviewed all modules (or chosen to stop):

1. **Move confirmed cards** from `docs/requirements/draft/` to `docs/requirements/`
2. **Re-number IDs** if needed (fill gaps from rejected cards)
3. **Delete draft directory:**
   ```bash
   rm -rf docs/requirements/draft
   ```
4. **Validate:**
   ```bash
   volere validate
   ```
5. **Trace:**
   ```bash
   volere trace
   ```
6. **Commit:**
   ```bash
   git add docs/requirements/
   git commit -m "Extract requirements from codebase: N URs, N TCs, N BUCs

   Modules: [list]
   Extracted by: extract-requirements skill
   Reviewed by: [owner name]"
   ```

### Suggested Next Steps

After extraction, suggest:

1. **`volere coverage`** — see which fit criteria lack tests
2. **`audit-tests` skill** — classify existing tests against confirmed requirements
3. **Fill gaps** — write missing fit criteria for confirmed URs (owner flagged "Owner to define")
4. **Team review** — run `review-requirements` for a multi-perspective review of the extracted set

## What This Skill Does NOT Do

- **No code changes** — read-only codebase analysis
- **No test generation** — separate step after requirements are confirmed
- **No BUC invention** — BUCs only come from the owner's answers
- **No PUC extraction** — PUCs are optional, emerge later if needed
- **No automatic commit** — everything passes through owner review
- **No fit criteria fabrication** — criteria come from tests or are marked "Owner to define"
- **No DAL override** — tentative DAL is presented, owner has final say
