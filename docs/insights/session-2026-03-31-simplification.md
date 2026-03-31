# Session Insight: Teaching Agents to Delete

**Date:** 2026-03-31
**Source:** Thread-pulling from AI verbosity in karpathy/autoresearch extraction
**Project:** Volere Agentic Framework

---

## Insight 16: Agents need to learn deletion before addition

Agents default to comprehensive coverage. They add detail, add structure, add documentation. They never remove. This is the opposite of what great engineers do — Einstein ("as simple as possible, but not simpler"), Musk ("the best part is no part, the best process is no process").

The extract-requirements skill produced 11 cards for a system with 3 real constraints. The agent was thorough. Thoroughness is the enemy of simplicity.

**The root cause:** Agents don't feel the pain of complexity. They never maintain what they wrote. They never come back 3 months later and wonder why there are 39 cards for a framework. Without that pain, they have no motivation to reduce.

**The fix:** You can't teach an agent to *value* simplicity (that's a feeling). You can make them *justify* complexity (that's a gate).

Musk's five-step process, applied to requirement extraction:
1. Question every requirement — can you explain why it exists?
2. Delete — the best requirement is no requirement
3. Merge — overlapping cards should be one card
4. Simplify — tighter fit criteria, fewer dimensions
5. Only then: organize, classify, link

The order matters. Most agents start at step 5 (organize and classify). They should start at step 2 (delete).

**Enforcement mechanism:** The simplification pass runs after extraction, before owner review. It presents what was removed and why. The card-to-constraint ratio flags over-specification (> 3:1 is a smell). The owner can restore anything, but the default is reduced.

**The deeper principle:** "If in doubt, delete. The owner can always add back. They cannot easily remove what the agent convinced them to keep through detailed justification." Bias toward reduction. Reward deletion in the review flow. Score fewer cards as a better outcome.

**Framework action:** Simplification pass added to extract-requirements skill. Principles section added. "No complexity for completeness" added to the Does NOT Do list.
