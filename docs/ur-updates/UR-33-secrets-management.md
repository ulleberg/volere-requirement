# UR-33: Secrets management (updated — was "Secret and token lifecycle")

**Description:** All secrets follow a two-tier pattern: `~/.secrets` for interactive shell and Claude Code sessions, `.env` (gitignored) for daemon/launchd processes. No secret values appear in config files, source code, or git history. Enforcement is automated at commit time and in CI.

**Rationale:** The thul ecosystem runs across interactive sessions (Claude Code, CLI tools, MCP servers) and background daemons (thul-ops runner, Studio launchd service). Interactive processes inherit env vars from `~/.zshrc` which sources `~/.secrets`. Daemon processes launched by launchd do not source zshrc, so they need a local `.env` file. Both patterns are legitimate — but only the `~/.secrets` pattern was documented, leading to inconsistency. Without automated enforcement, secrets drift into config files and source code.

**Fit criteria:**
1. `~/.secrets` contains all secret env vars listed in thul-dotfiles README. `chmod 600`. Sourced by `~/.zshrc`.
2. Repos with daemon processes have `.env` in `.gitignore` and `.env.example` documenting required vars (without values).
3. A pre-commit hook (gitleaks or equivalent) rejects commits containing patterns matching known secret formats (API keys, tokens, hex strings > 20 chars). Runs in < 2 seconds.
4. CI pipeline includes a secrets scan step (`gitleaks detect`) that fails the build on any match.
5. Doc-health monthly scan reports zero new secret leakage across all thul-* repos.
6. Config files reference env var names (e.g., `process.env.STUDIO_TOKEN`), never literal values.
7. Adding a new secret to the ecosystem requires updating: `~/.secrets`, thul-dotfiles README template, and the consuming repo's `.env.example` (if daemon).

**Origin:** Thomas Ulleberg, March 2026. Discovered during Volere Agentic Framework discovery — investigation revealed undocumented `~/.secrets` vs `.env` split and zero automated enforcement across the ecosystem.

**Priority:** P1 — required for production confidence.

**DAL:** B — secrets leakage is a security incident.
