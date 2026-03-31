---
name: simplify-requirements
description: Reduces requirement card count by merging overlaps, deleting redundancy, and questioning every card. Use when the card set feels bloated, before a release, after reviews add cards, or when the card-to-constraint ratio exceeds 3:1.
---

# Simplify Requirements

Reduce. The best requirement is no requirement. The best card is the one you don't need because a tighter constraint makes it redundant.

> "Everything should be made as simple as possible, but not simpler." — Einstein
> "The best part is no part. The best process is no process." — Musk

## When to Use

- "We have too many requirement cards"
- "Can any of these be merged?"
- "Simplify the requirements"
- "Clean up before release"
- After a review cycle that added cards
- When card-to-constraint ratio > 3:1
- Before publishing or sharing the requirement set

## Before Starting

1. Read all requirement cards:
   ```bash
   ls docs/requirements/*.yaml | wc -l
   ls docs/requirements/*.yaml
   ```

2. Count the real constraints — things that, if violated, break the system. Not cards. Constraints. Write them down.

3. Compute the ratio: cards / constraints. If > 3:1, there's significant reduction opportunity.

## The Five Steps (in order — the order matters)

### Step 1: Question every card

For each card, ask: **"If I remove this, what breaks?"**

| Answer | Action |
|--------|--------|
| "Nothing" | Delete |
| "Another card already covers it" | Merge |
| "An obvious thing that doesn't need stating" | Delete — don't document gravity |
| "Something important and unique" | Keep |

Record your findings in a table:

```
| Card | What breaks without it? | Action |
|------|------------------------|--------|
| TC-004 | Nothing — it's a judgment call, not testable | DELETE |
| UR-002 | UR-001 covers this as a subprocess | MERGE into UR-001 |
| TC-001 | Agent scope enforcement — critical | KEEP |
```

### Step 2: Delete

Remove cards marked DELETE. Don't hesitate. The owner can restore anything during review. What you can't easily undo is an agent convincing the owner to keep a card through detailed justification.

Cards to target:
- **Implementation details masquerading as requirements.** "Agent commits before training" is a step in a workflow, not a requirement.
- **Obvious constraints.** "The system must not crash" — if this needs stating, the system has bigger problems.
- **Judgment calls that can't be tested.** "Prefer simpler code" — real but not mechanically enforceable. Capture it in CLAUDE.md conventions, not in a requirement card.
- **Aspirational cards.** Requirements with `status: proposed` and no path to implementation. If nobody is going to build it, don't track it.

### Step 3: Merge

Combine cards that share:
- **Same BUC** with overlapping fit criteria
- **Same enforcement mechanism** (e.g., three TCs all enforced by one hook)
- **Same code path** (if `volere trace` maps them to the same files)

Merge rules:
- Keep the stronger fit criterion (more measurable, more specific)
- Keep the higher DAL level
- Combine `depends_on` and `cross_verify` lists
- Note the merge in the surviving card's history

Example:
```
BEFORE:
  TC-001: "Agent may only modify train.py"
  TC-002: "Agent may not install new packages"
  TC-003: "Agent may not modify prepare.py"

AFTER:
  TC-001: "Agent scope limited to train.py"
  Fit criterion: "Only train.py is modified. prepare.py is read-only.
  No new packages installed. No new files except results.tsv and run.log."
```

Three cards → one card. Same enforcement. Tighter.

### Step 4: Simplify surviving cards

For each remaining card:
- Can the fit criterion be stated in fewer words?
- Are there dimensions that don't add verification value? Remove them.
- Is the DAL justified or defaulted? Re-evaluate.
- Can `depends_on` links be reduced? A card that depends on everything depends on nothing.

### Step 5: Present the reduction

Show the owner what changed:

```
Simplification complete:
  Before: 39 cards (6 BUCs, 15 URs, 16 TCs + 2 existing)
  After:  28 cards (4 BUCs, 12 URs, 12 TCs)

  Deleted: 5 cards
    - TC-004: Simplicity criterion — judgment call, moved to CLAUDE.md
    - UR-002: Setup workflow — merged into UR-001
    - ...

  Merged: 6 cards → 3 cards
    - TC-001 + TC-002 + TC-003 → TC-001 (agent scope constraint)
    - ...

  Ratio: 39/3 (13:1) → 28/3 (9.3:1)

  Target: < 3:1 for tight systems, < 5:1 for complex ones.
```

The owner reviews the reduction. They can restore any card. But the default is fewer.

## Principles

- **Justify complexity, not simplicity.** Adding needs a reason. Removing doesn't.
- **If in doubt, delete.** The owner can add back. They can't easily remove what an agent justified.
- **Fewer, tighter cards > comprehensive coverage.** 7 cards tracing to 3 constraints is better than 39 cards tracing to the same 3 constraints.
- **Move, don't lose.** Deleted judgment calls go to CLAUDE.md conventions. Deleted process steps go to skill instructions. The knowledge isn't lost, it's relocated to where it belongs.
- **Score reduction.** Fewer cards after simplification is a better outcome, not a worse one. Report the ratio improvement.

## What This Skill Does NOT Do

- **No card creation** — this skill only reduces, never adds
- **No code changes** — read-only analysis of requirement cards
- **No automatic deletion** — everything goes through owner review
- **No simplification below correctness** — "as simple as possible, but not simpler"
