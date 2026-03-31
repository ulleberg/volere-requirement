# Session Insights: Dogfooding & External Validation

**Date:** 2026-03-31
**Source:** Dogfooding session — extract-requirements on volere-requirement itself, then validation on karpathy/autoresearch
**Project:** Volere Agentic Framework (v0.9 hardening)

---

## Insight 9: Code and docs are a liability, not an asset

Every line of code is a liability until it's verified, and a compounding liability if it's not maintained. Dead code isn't just waste — it's a trap for the next agent that reads it and assumes it matters. Stale docs are worse than no docs — they teach the wrong thing with authority.

Karpathy's autoresearch achieves rigorous autonomous operation with 3 files and a 115-line markdown "skill." Our framework has 39 requirement cards, 7 skills, 6 hooks, 7 CLI commands, 4 schemas. Both work. But every element we add must justify its existence against the complexity cost.

Chesterton's fence says "don't remove until you know why it was built." The counterbalance: "once you know why, ask whether the reason still holds and whether the cost is justified." The framework has the first principle (Insight 9 from README). It's missing the second.

**Framework action:** Add a simplicity criterion to the framework's design principles. Every skill, hook, schema field, and CLI command must answer: "What breaks if this is removed?" If the answer is "nothing" or "something we don't actually need," it's a candidate for removal. Apply this during every review cycle, not just at cleanup time. The `review-requirements` skill should include a simplicity pass: "Which of these requirements could be removed or merged without losing verification capability?"

---

## Insight 10: Radical constraint beats comprehensive coverage

Karpathy's system works because it constrains, not because it covers. One file editable. One metric. One time budget. These constraints make the system powerful precisely because they remove decisions. Our framework gives agents options (9 requirement types, 5 DAL levels, 6 verification methods, 4 test classifications). Options require judgment. Constraints require nothing — they just work.

The practical question for every framework feature: is this enabling a decision the agent needs to make, or is it adding a decision the agent could skip? If the agent could skip it and the system would still work, the option is overhead, not capability.

**Framework action:** For each skill, identify the minimum set of decisions the agent must make. Everything else should either have a sensible default or be removed. The `write-requirement` skill asks agents to choose from 12 types, 5 DAL levels, 4 priorities, 4 verification methods, and N dimensions. Most cards end up as `type: functional, dal: C, priority: must, verification: test`. Make that the default path and let agents override only when they have reason to.

---

## Insight 11: Review bottom-up through the V-Model

When reviewing extracted requirements, order matters. Constraints (TCs) first, features (URs) second, guidance (skills) last. Each layer's dependencies point downward to already-confirmed cards. This makes `depends_on` and `cross_verify` accurate at write time, not patched later.

Discovered during self-dogfooding: proposing "start with which module?" leaves the ordering to the user, but there's a clear principle. Bottom-up through the V-Model: implementation constraints anchor to code, user features build on constraints, agent guidance orchestrates everything above.

**Framework action:** Already captured in the extract-requirements skill. The default review order is V-Model bottom-up with rationale. The owner can override, but the default should always be bottom-up.

---

## Insight 12: The agent should lead reviews, not just present data

During the TC/UR review, presenting a card and asking three questions ("confirm? why? DAL right?") puts the analytical burden on the owner. When the agent leads — providing its assessment, explaining why the requirement exists, and proposing the BUC link — the owner's job reduces to verification. Verify and correct is faster and more reliable than analyze and decide.

This is the same principle as code review: the author (agent) explains their reasoning, the reviewer (owner) checks it. Not the other way around.

**Framework action:** Already captured in the extract-requirements skill. The per-card review format now includes agent assessment, rationale, and BUC link proposal. The owner verifies and accepts.

---

## Insight 13: Users need a decoder ring for framework terminology

TC, UR, BUC, PUC, DAL-A through DAL-E, VERIFIES/SUPPORTS/THEATER/REDUNDANT, MoSCoW, V-Model levels — the framework has dense terminology. First-time users hit a wall of abbreviations. The glossary skill (/glossary) and the inline classification legend in audit-tests address this, but the deeper lesson: every framework term should be introduced where it's first used, not in a separate glossary.

**Framework action:** Already captured: glossary skill for on-demand reference, inline legend in audit-tests output. Future: each skill should define terms at first use, not assume the user has read the glossary.

---

## Insight 14: program.md validates the skill pattern

Karpathy independently arrived at the same pattern as Claude Code skills: a markdown file that guides agent behavior. He calls it "essentially a super lightweight skill." This validates the entire skill architecture — markdown instructions for agent guidance are a convergent design, not an arbitrary choice.

The difference: his is 115 lines for a tightly constrained system. Ours average 200+ lines for a broader framework. Both work. The question is whether our broader scope justifies the additional complexity, or whether tighter constraints would produce the same results with less guidance.

**Framework action:** No immediate action. This is a validation of the skill architecture and a reminder that shorter skills with tighter constraints may be more effective than longer skills with more options.
