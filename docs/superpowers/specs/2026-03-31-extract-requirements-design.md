# Extract Requirements Skill Design

**Date:** 2026-03-31
**Status:** Approved
**Scope:** New skill for the Volere Agentic Framework plugin

---

## Goal

A Claude Code skill that reads an arbitrary codebase and extracts User Requirements (URs) and Technical Constraints (TCs) as draft YAML snow cards, then guides the codebase owner through a module-by-module review where Business Use Cases (BUCs) surface from the owner's answers.

## Principle

**Extract wide, review narrow.** Scan the whole repo to catch cross-cutting concerns (security, shared infrastructure, error handling), but present draft cards grouped by module so the owner reviews a digestible set at a time.

## Workflow

```
Codebase → Scan → Draft cards (staging) → Owner review (per module) → Confirmed cards (committed)
```

### Phase 1: Scan

The agent reads the codebase systematically, looking for requirements in five source categories:

| Source | Extracts | Requirement type |
|--------|----------|-----------------|
| Source files (routes, handlers, UI components, business logic) | Functional capabilities | UR |
| Tests (assertions, test names, fixtures) | Existing fit criteria | UR fit criteria |
| Error handling, retries, timeouts, schema constraints, validation | Implementation guarantees | TC |
| Config, env vars, CLI flags, deployment scripts | Operational requirements | UR (operational) |
| Auth, CORS, CSP, secrets patterns, encryption | Security requirements | UR (security) |
| README, CLAUDE.md, docs/, comments | Informally stated requirements | UR or BUC |

**Size check:** At the start, count files in the repo (excluding `.git/`, `node_modules/`, `vendor/`, build artifacts).
- <500 files: proceed with whole-repo scan
- 500+ files: warn the owner, suggest scoping to a directory or module, proceed if owner confirms

**Output:** Internal working list — not yet YAML cards. Each entry has:
- What the system does (description)
- Where in the code it lives (file paths)
- What tests exist for it (if any)
- What module/feature group it belongs to (inferred from directory structure)

### Phase 2: Draft Cards

Convert the working list into draft YAML snow cards using the `write-requirement` skill format.

**Grouping:** Cards are grouped by module/feature, auto-detected from directory structure. The agent uses top-level source directories as groups (e.g., `internal/api/`, `internal/auth/`, `components/`, `lib/`). If the structure is flat, group by functional area.

**Card fields:**

| Field | How it's populated |
|-------|-------------------|
| `id` | Auto-incremented (UR-001, TC-001, etc.) |
| `type` | Inferred from source category |
| `title` | One-line summary of what the system does |
| `description` | What the system must do — derived from code behavior |
| `rationale` | Left as "Pending owner review — why does this exist?" |
| `fit_criteria` | Derived from existing tests if they exist. Each criterion marked `source: test` (from assertion) or `source: inferred` (from code behavior). `verification_method` set based on test type. |
| `dal` | Tentative, using `classify-risk` heuristics |
| `priority` | `should` (default — owner confirms during review) |
| `status` | `proposed` |
| `origin` | `stakeholder: "extract-requirements"`, `date: today`, `trigger: "Codebase extraction"` |
| `cross_verify` | Populated where the agent detects cross-module dependencies |
| `depends_on` | Populated where code dependencies are clear |

**Staging area:** Cards are written to `docs/requirements/draft/`, not `docs/requirements/`. Nothing is confirmed until the owner reviews it.

**Draft summary:** After writing all draft cards, produce a summary:

```
Extraction complete:
  23 draft URs across 5 modules
  7 draft TCs
  14 fit criteria derived from existing tests
  9 fit criteria inferred from code behavior

Modules:
  internal/api/     — 8 URs, 2 TCs
  internal/auth/    — 4 URs, 2 TCs
  internal/storage/ — 5 URs, 1 TC
  web/components/   — 3 URs
  cmd/              — 3 URs, 2 TCs

Ready for owner review. Start with which module?
```

### Phase 3: Owner Review

Present one module at a time. For each module:

1. **Show the group summary** — how many URs/TCs, what area of the system
2. **Present each card** — title, description, fit criteria (with source), tentative DAL
3. **Ask three questions per card:**
   - **Confirm / Reject / Edit?** — is this a real requirement?
   - **Why does this exist?** — the answer becomes the rationale (and surfaces BUCs)
   - **How critical is this?** — validates or adjusts DAL and priority

**BUC surfacing:** When the owner explains "why," the agent checks if the answer maps to an existing BUC or if a new one is needed. If a new BUC emerges:
- Agent drafts a BUC card with the owner's explanation as description
- Links the URs that serve this BUC via `depends_on`
- BUC goes to `docs/requirements/draft/` for confirmation in the same review pass

**Batch mode:** The owner can respond to multiple cards at once ("confirm 1-5, reject 6, edit 7"). The agent adapts — don't force one-at-a-time if the owner wants to move fast.

**Review output per module:**
- Confirmed cards: ready to commit
- Rejected cards: deleted from draft
- Edited cards: updated in draft, re-presented for confirmation
- New BUCs: drafted and presented for confirmation

### Phase 4: Commit

After the owner has reviewed all modules (or chosen to stop):

1. Move confirmed cards from `docs/requirements/draft/` to `docs/requirements/`
2. Delete rejected cards and the `draft/` directory
3. Run `volere validate` on confirmed cards
4. Run `volere trace` to connect cards to code
5. Commit with message listing what was extracted and confirmed

**Post-extraction next steps** (suggested to owner):
- Run `volere coverage` to see fit criteria gaps
- Run the `audit-tests` skill to classify existing tests against confirmed requirements
- Fill missing fit criteria for confirmed URs
- Write additional requirements the extraction missed

## What This Skill Does NOT Do

- **No code changes** — read-only codebase analysis
- **No test generation** — that's a separate step after requirements are confirmed
- **No BUC invention** — BUCs only come from the owner's answers during review
- **No PUC extraction** — PUCs are optional; they emerge later if the owner wants user flow decomposition
- **No automatic commit** — everything passes through owner review in the staging area
- **No fit criteria fabrication** — fit criteria come from existing tests or are marked as inferred. The agent doesn't invent thresholds.

## Skill Integration

| Existing skill | How extract-requirements uses it |
|---------------|----------------------------------|
| `write-requirement` | Card format and quality checklist |
| `classify-risk` | Tentative DAL assignment during drafting |
| `audit-tests` | Suggested as post-extraction next step |
| `trace-codebase` | Run after confirmed cards are committed |
| `review-requirements` | Suggested for team review after extraction |

## File Structure

```
plugin/skills/extract-requirements/
  skill.md          — the skill (instructions for the agent)
```

No new schemas, hooks, or CLI commands needed. The skill uses existing infrastructure.
