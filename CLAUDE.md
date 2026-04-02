# Volere Agentic Framework

Archive of the original Volere Requirements Template (v15) plus the Volere Agentic Framework — a Claude Code plugin for structured requirements engineering and V-Model verification in agentic software development.

## Architecture

- **Original Volere files (a–i)** — template, case studies, requirement stationery. Preserved as-is.
- **docs/** — discovery-to-delivery documentation: problem, brief, options, decisions, spec, roadmap, team prompts, execution plans.
  - **docs/insights/** — session insights from applying the framework to real projects. Research findings with framework action items. Read these before proposing changes to the framework — they contain lessons from production use.
- **plugin/** — the framework (v0.1–v0.8 shipped, v0.9 hardening):
  - `schema/` — 4 JSON schemas (requirement with cross_verify + verification_method, profile with verification_commands, compliance, evidence with verification_level)
  - `skills/` — 8 skills (extract-requirements, simplify-requirements, write-requirement, review-requirements, trace-codebase, audit-tests, classify-risk, glossary)
  - `hooks/` — 7 hooks (check-secrets, check-simplicity, check-traceability, check-fit-criteria, check-checkout, check-merge, coverage-gaps) + installer
  - `cli/` — CLI with 7 commands + suspect link manager
  - `catalogs/` — shared requirement catalogs (security-baseline)
  - `templates/` — project scaffold, BUC/PUC/UR/TC/evidence/compliance templates, retrofit guide
  - `requirements/` — 36 cards dogfooding the framework (5 BUCs, 16 URs, 15 TCs), 57 tests, 97% coverage

See `ARCHITECTURE.md` for the full V-Model mapping, design principles, and design decisions.

## Key Concepts

- **Snow card** — Volere's atomic requirement format, modernised as YAML with multi-dimensional fit criteria
- **BUC** (Business Use Case, §7) — why requirements exist (business context)
- **PUC** (Product Use Case, §8) — what the user does (interaction flows)
- **UR** (User Requirement, §9-17) — what the system must do
- **TC** (Technical Constraint) — what the implementation must guarantee
- **DAL** (Design Assurance Level, A-E) — scales verification effort to risk
- **Fit criterion** — measurable condition defining when a requirement is satisfied
- **Suspect link** — a downstream requirement that needs re-verification after an upstream change
- **Cross-verify** — requirements whose fit criteria must be re-verified when a related requirement changes
- **Verification level** — V-Model level (unit/integration/system/acceptance) at which evidence was collected

## Testing

```bash
# Validate requirement cards against schema
plugin/validate.sh plugin/requirements/UR-001.yaml

# Run hook + CLI + validator test suite (52 tests)
plugin/hooks/test-hooks.sh

# CLI commands
plugin/cli/volere help
plugin/cli/volere validate
plugin/cli/volere trace
plugin/cli/volere coverage
plugin/cli/volere impact UR-001
```

## Session Start

The `SessionStart` hook reports acceptance coverage. **When you see this hook output, proactively brief:**

- **Gaps exist (X < Y):** Summarize X/Y coverage, list uncovered gaps ranked by DAL level (DAL-A/B first), and propose which gaps to close — consider impact, feasibility, and what the user is likely working on today. When proposing gap closure, pass the requirement's fit criterion into `/brainstorm` as the acceptance target — don't start from scratch.
- **Full coverage (X = Y):** Report X/Y, then ask whether the user wants to work on new features, add new requirements, or something else.

Don't wait to be asked — this is the session briefing.

## Simplicity Protocol

Every action in this project follows the simplicity protocol. This is not optional.

**Before creating anything** (file, card, test, skill, hook, function):
1. Can this be accomplished by modifying something that already exists?
2. If not, what is the minimum that achieves the goal?
3. After creating it, what existing thing can now be removed or merged?

**Before committing:**
4. Did you add more than you removed? If yes, justify why.
5. Can any new code be replaced by a tighter constraint that makes the code unnecessary?
6. Would someone reading this in 3 months understand it without context?

**After completing a task:**
7. What did you create that the user didn't ask for? Remove it.
8. Can any new files be merged into existing files?
9. Is there a simpler way to achieve the same result?

**The default is removal, not addition.** Adding requires justification. Removing doesn't. If you're unsure whether something should exist, it probably shouldn't.

When the pre-commit hook reports your diff stats, use them: a commit that removes more than it adds is a good commit. A commit that only adds is suspect.

## Post-Implementation Checklist

After completing any feature or fix driven by a requirement:

1. **Verify fit criteria:** Run `volere coverage` — did coverage improve?
2. **Audit new tests:** Do they VERIFY fit criteria, or just SUPPORT implementation?
3. **Check impact:** Run `volere impact` on changed requirements — any suspect links?
4. **Update card status:** Move requirement from `proposed` → `implemented` if fit criteria are now verified.

If the implementation wasn't driven by a requirement, ask: should it have been? Missing requirements are how code becomes untraceable.

## Conventions

- Requirement cards are individual YAML files, one per requirement
- IDs follow the pattern: `{PREFIX}-{NNN}` (e.g., BUC-001, UR-042, TC-005)
- Every fit criterion must be measurable — no vague words (should, appropriate, reasonable)
- Chesterton's fence + simplicity criterion: keep elements until proven unnecessary, then ask if the cost is still justified
- System testing (V-Model architecture level), not just e2e — includes performance, security, failure modes
- Autonomous verification: agents test everything, "manually verified" is a bug in the process
