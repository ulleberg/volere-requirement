# UR-20: Project standards compliance (updated — was "Project health checks")

**Description:** Each session shows whether its project meets the thul ecosystem standards — not just file existence, but minimum content quality and freshness.

**Rationale:** File existence checks catch missing documentation but not stale or empty documentation. A CLAUDE.md that hasn't been updated since the architecture changed is worse than no CLAUDE.md — it's actively misleading. Agents rely on these files for context; quality directly affects agent output quality (proven in Experiment 001).

**Fit criteria:**
1. Each session card shows a compliance badge (pass/warn/fail).
2. Existence checks (8 categories): git, .gitignore, README.md, CLAUDE.md, ARCHITECTURE.md, tests, CI, lock file. Healthy at 6+/8, warning at 4-5/8, unhealthy below 4/8.
3. Content quality checks (for files that exist):
   - `CLAUDE.md`: must contain Architecture, Testing, and Gotchas/Conventions sections
   - `ARCHITECTURE.md`: must contain a system diagram and design decisions section
   - `README.md`: must contain what-it-is, how-to-install, how-to-run
4. Staleness check: if the latest code commit is more than 30 days newer than the latest doc file change, the compliance badge shows a staleness warning.
5. Clicking the badge shows which items are missing, incomplete, or stale.
6. Checks run on session creation and on demand.
7. This is distinct from machine health (UR-30 / `/health` endpoint).

**Origin:** Thomas Ulleberg, March 2026. Extended during Volere Agentic Framework discovery — existence checks are necessary but not sufficient. Quality and freshness matter because agents depend on these files.

**Note:** The full "Project Constitution" defining what each file must contain lives in the Volere Agentic Framework (`volere-requirement/`), not in Studio. UR-20 references and enforces that standard.
