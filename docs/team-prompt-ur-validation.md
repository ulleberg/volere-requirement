# Team Prompt: Requirements Validation Review (Pass 1.5)

Run this from a Claude Code session in `thul-studio/`.

## Purpose

Validate the updated requirements after the initial review and decision round. This is not a re-discovery — it's a verification that the changes are internally consistent, testable, and complete.

## Prompt

```
Create an agent team to validate the updated requirements in docs/requirements/.

Context: We ran a 5-agent review on the original 26 URs, made decisions on all findings,
rewrote 13 fit criteria, added 17 new URs (UR-27 to UR-43), and created 12 technical
constraints (TC-01 to TC-12). This validation checks that our changes are sound.

All teammates should read:
- docs/requirements/user.md (43 URs — the updated version)
- docs/requirements/technical-constraints.md (12 TCs)
- docs/requirements/README.md (structure and priority table)
- docs/requirements/reviews/synthesis.md (the original review findings we responded to)

Spawn these teammates:

1. Test Engineer — spawn with prompt:
   "You are the Test Engineer validating that every fit criterion is testable.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/test-engineer/SOUL.md

   Then read:
   - docs/requirements/user.md (43 URs)
   - docs/requirements/technical-constraints.md (12 TCs)
   - docs/requirements/reviews/test-review.md (your original review)

   Your deliverable — write to docs/requirements/reviews/validation-test.md:

   For each of the 17 NEW URs (UR-27 to UR-43):
   1. Can you write a concrete test for this fit criterion? Write a one-line test sketch
      (e.g., 'send request with path traversal chars, assert 400 response')
   2. Score testability 1-5. Flag any criterion you can't turn into a test.

   For each of the 13 REWRITTEN fit criteria (UR-01, 03, 05, 06, 07, 08, 10, 12, 15,
   16, 18, 19, 20, 21, 23, 25, 26):
   3. Is the rewrite an improvement over the original? Does it close the gap
      identified in the synthesis?

   For each of the 12 TCs:
   4. Does the fit criterion match what the existing tests actually verify?
      Check the test files in internal/ — do the tests align with the TC?
   5. Are there existing tests that now trace to a TC but didn't before?

   Summary: total testable %, any fit criteria that need another rewrite.

   Stay in your lane — testability only."

2. CTO (Steve) — spawn with prompt:
   "You are the Chief Technical Officer validating architectural consistency.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/chief-technical-officer/SOUL.md
   Read expertise if available: /Users/thul/repos/ulleberg/thul-agents/agents/chief-technical-officer/expertise/

   Then read:
   - docs/requirements/user.md (43 URs)
   - docs/requirements/technical-constraints.md (12 TCs)
   - docs/requirements/reviews/architecture-review.md (your original review)
   - ARCHITECTURE.md

   Your deliverable — write to docs/requirements/reviews/validation-architecture.md:

   1. Cross-UR consistency: do any of the 43 URs conflict with each other?
      Check especially: new URs (27-43) vs original URs (01-26), and the
      rewritten fit criteria vs URs that weren't rewritten.
   2. Dependency completeness: the updated URs document dependencies.
      Are there missing dependencies? Are any documented dependencies wrong?
   3. TC traceability: does each TC correctly identify the UR(s) it serves?
      Are there TCs that should trace to additional URs? Are there implementation
      contracts in the codebase that aren't captured by any TC?
   4. Architecture alignment: do the new URs (especially UR-32 port capacity,
      UR-35 reconciliation, UR-36 config management) align with the actual
      architecture, or do they assume things that aren't true?
   5. Gaps: after adding 17 URs and 12 TCs, is anything still missing?
      Or did we over-specify?

   Stay in your lane — architecture and consistency."

3. Synthesis Lead (Albert) — spawn with prompt:
   "You are the Chief of Staff synthesising the validation findings.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/chief-of-staff/SOUL.md

   Wait for both reviewers to complete, then read:
   - docs/requirements/reviews/validation-test.md
   - docs/requirements/reviews/validation-architecture.md
   - docs/requirements/reviews/synthesis.md (your original synthesis — compare)

   Your deliverable — write to docs/requirements/reviews/validation-synthesis.md:

   1. Verdict: are the updated requirements ready for Pass 2
      (codebase-to-requirements trace)? Yes/no with justification.
   2. Issues found: anything that needs fixing before Pass 2.
      For each issue: what's wrong, proposed fix, severity (blocker/minor).
   3. Improvements confirmed: which original synthesis findings are now
      properly addressed?
   4. Remaining gaps: anything from the original synthesis that wasn't
      addressed or was addressed weakly.
   5. Over-specification check: did we add URs or TCs that are unnecessary?
      Anything that should be removed or merged?

   Challenge both reviewers. If they rubber-stamp everything, push back —
   the point of this review is to catch problems, not confirm success."

Goal: Validate that our requirement updates are internally consistent, testable,
and complete. This is a quality gate before Pass 2 (codebase trace).
Have teammates challenge each other's findings.
```

## Pre-flight

1. Ensure agent teams are enabled
2. Verify the updated files are committed and current:
   ```bash
   git log --oneline -3  # Should show the requirements update commit
   ```
3. Run from thul-studio root directory
