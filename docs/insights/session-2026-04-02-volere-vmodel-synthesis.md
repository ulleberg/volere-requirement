# Session Insight: The Volere + V-Model Synthesis Is Novel

**Date:** 2026-04-02
**Source:** Building interactive presentation — forced precise attribution of where each concept comes from
**Project:** Volere Agentic Framework

---

## Insight 16: The V-Model mapping is not from Volere — it's the framework's core contribution

While designing section 7 of the presentation ("Loop 2 — Volere"), we needed to explain the V-Model mapping to a general audience. This forced the question: where does this mapping actually come from?

**Finding:** Original Volere (Robertson & Robertson, 1995-2025) defines requirement types (BUC, PUC, UR, TC) and the snow card format. It says nothing about V-Model, verification levels, or test type mapping. Zero mentions of "V-Model" in the Volere Template v15 PDF.

The V-Model (systems engineering) defines the definition↔verification symmetry. It says nothing about requirement formats.

**This framework's novel contribution** is connecting them: BUC→Acceptance, PUC→System, UR→System, Architecture→Integration, TC→Unit, Code→Static Analysis.

**Why it matters:** The framework's documentation (ARCHITECTURE.md, README.md) had been presenting this mapping as if it were pre-existing — "maps Volere to V-Model" — which obscures the innovation. The presentation forced clarity: "Two proven disciplines, combined for the first time."

**Framework action items (completed this session):**
- Updated ARCHITECTURE.md — explicit three-source attribution (Volere, V-Model, this framework)
- Updated README.md — renamed "V-Model Decomposition" to "Requirement Hierarchy (Volere)", separated the synthesis
- Updated glossary skill — added Volere→V-Model synthesis table with attribution
- Plugin synced to marketplace

---

## Insight 17: DAL provenance should be explicit — DO-178C, not Volere

The DAL (Design Assurance Level) system used in the framework is adapted from DO-178C (aerospace safety standards), not from Volere. This wasn't stated anywhere in the framework until the presentation added it: "borrowed from aerospace safety standards (DO-178C), adapted for software."

**Why it matters:** Users from regulated industries will recognize DO-178C. Users from web development need the context to understand why graduated rigour matters. Both audiences are served by explicit attribution.

**Framework action item:** Presentation section 12 now includes the attribution. Consider adding DO-178C reference to the classify-risk skill.

---

## Insight 18: Building a presentation is a verification activity

The act of explaining the framework to a general audience exposed three inconsistencies:
1. Section 7 showed a simplified 3-level V-Model (BUC/UR/TC) — the full model has 6 levels
2. Section 11 fit criteria test_types didn't align with V-Model levels defined in section 7
3. Section 12 DAL bars lumped V-Model levels incorrectly ("unit + integration" as one level)

All three were corrected once we established section 7 as the source of truth and propagated it.

**Principle:** If you can't explain it consistently to an outsider, your internal docs are inconsistent too. The presentation caught what code review didn't.

**Framework action item:** Consider adding a "presentation test" to the review-requirements skill — can you explain each requirement to someone outside the project without contradicting other requirements?

---

## Insight 19: Multi-dimensional fit criteria explain the test-to-card ratio

The dogfooding section showed 32 cards → 52 tests, which looks wrong at first glance. The explanation — multi-dimensional fit criteria mean one requirement produces multiple tests across user/security/operational/regulatory dimensions — is actually the framework's strongest selling point, not a discrepancy.

**Why it matters:** This is the single most concrete demonstration of why Volere's approach is better than "one test per requirement." A traditional framework would have 32 tests. The multi-dimensional approach catches failures that single-dimension testing misses.

**Framework action item:** The presentation now includes this explanation. Consider adding a "coverage ratio" metric to `volere coverage` that shows cards:tests ratio as a health indicator — a ratio close to 1:1 might indicate single-dimensional testing.
