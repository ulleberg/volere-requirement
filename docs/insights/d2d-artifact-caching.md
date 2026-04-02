# Insight: discovery-to-delivery needs artifact caching

**Date:** 2026-04-02
**Source:** Doc staleness work in volere — realized d2d dumps process artifacts directly into docs/ with no lifecycle management.

## The problem

d2d creates `docs/problem.md`, `docs/brief.md`, `docs/options/`, `docs/spec.md`, `docs/decisions.md` directly in the project's docs directory. After delivery, these become noise — new contributors see them and wonder if they're current. Superpowers solved this with `.superpowers/` (gitignored cache) and persistent outputs in `docs/superpowers/`.

## The fix

Update d2d (separate plugin, not merged into volere) to adopt the superpowers caching pattern:

- **`.discovery/`** — process artifacts (problem.md, brief.md, options/). Gitignored. Cached for the duration of discovery.
- **`docs/spec.md`** and **`docs/decisions.md`** — persistent outputs. These are the handoff contract to superpowers. They survive because they're maintained docs, not process artifacts.
- **End-of-Deliver lifecycle** — d2d offers to archive process artifacts when the phase transitions to Deliver.

## Why not merge d2d into volere?

Different concerns. d2d is about understanding (diverge/converge on the problem). Volere is about engineering discipline (requirements, verification). The three-loop lifecycle (Discovery -> Volere -> Superpowers) works because they're separate loops with clean handoffs.

## Framework action

- [ ] Update d2d plugin: add `.discovery/` cache pattern
- [ ] Update d2d plugin: end-of-Deliver cleanup offer
- [ ] Volere `clean` command: detect stale process artifacts generically (from any plugin)
