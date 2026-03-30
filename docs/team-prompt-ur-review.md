# Team Prompt: User Requirements Review

Run this from a Claude Code session in `thul-studio/`.

## Pass 1: Requirements Review

```
Create an agent team to review the 26 user requirements in docs/requirements/user.md.

The goal: Are these the right requirements? Are we missing any? Are the fit criteria truly testable and specific enough to drive automated verification?

Context for all teammates:
- Read docs/requirements/user.md (26 user requirements in Volere format)
- Read docs/requirements/README.md (requirements structure)
- Read ARCHITECTURE.md (system overview)
- Read CLAUDE.md (project conventions and gotchas)

Spawn these teammates:

1. Architecture Reviewer (CTO perspective) — spawn with prompt:
   "You are the Chief Technical Officer reviewing requirements for completeness.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/chief-technical-officer/SOUL.md
   Read expertise if available: /Users/thul/repos/ulleberg/thul-agents/agents/chief-technical-officer/expertise/

   Then read:
   - docs/requirements/user.md (the 26 URs under review)
   - ARCHITECTURE.md (current system)
   - CLAUDE.md (conventions and gotchas)

   Your deliverable — write to docs/requirements/reviews/architecture-review.md:
   1. For each of the 26 URs: is the fit criterion specific and measurable? Score 1-5.
   2. Missing URs: what requirements are implied by the architecture but not captured?
      Look at ARCHITECTURE.md, the 12 Go packages, the gotchas — what behaviours exist
      that have no corresponding UR?
   3. Architectural concerns: do any URs conflict? Are there implicit dependencies?
   4. Derived requirements: list requirements that emerged during development
      (HMAC verification, tmux line unwrapping, port allocation, ANSI stripping, etc.)
      that should be formalised.

   Stay in your lane — architecture and system completeness. Don't review security or ops."

2. Test Engineer — spawn with prompt:
   "You are the Test Engineer auditing test quality against requirements.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/test-engineer/SOUL.md

   Then read:
   - docs/requirements/user.md (the 26 URs)
   - docs/studio-v-model-testplan.md (V-Model test plan)
   - docs/regression-baseline.md (577 tests traced to URs)
   - Run: go test ./... -v -count=1 2>&1 | tail -50 (see current test state)
   - Run: npx playwright test --config playwright.go.config.js 2>&1 | tail -30

   Your deliverable — write to docs/requirements/reviews/test-review.md:
   1. Test theater audit: which tests verify fit criteria vs test implementation details?
      For each UR, check if the tests actually verify the stated fit criterion.
   2. Coverage gaps: which URs have no tests or weak tests?
   3. Unnecessary tests: tests that don't trace to any fit criterion — candidates for removal.
   4. Test quality: are tests resilient to refactoring or brittle (coupled to implementation)?
   5. Fit criteria testability: which fit criteria cannot be automated? Which need rewriting?

   Stay in your lane — test quality and coverage. Don't review architecture or security."

3. Security Engineer — spawn with prompt:
   "You are the Security Engineer reviewing requirements for security completeness.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/security-engineer/SOUL.md
   Read expertise if available: /Users/thul/repos/ulleberg/thul-agents/agents/security-engineer/expertise/

   Then read:
   - docs/requirements/user.md (the 26 URs — especially UR-21, UR-23)
   - CLAUDE.md (security-relevant gotchas)
   - internal/auth/ (auth middleware source)

   Your deliverable — write to docs/requirements/reviews/security-review.md:
   1. Security dimension completeness: are UR-21 and UR-23 sufficient?
      What security requirements are missing? (Input validation, rate limiting,
      session hijacking, CORS, CSP, dependency vulnerabilities, etc.)
   2. Fit criteria sharpness: are security fit criteria binary and testable?
   3. Threat model gaps: given the architecture (browser terminals with system access),
      what threats are not addressed by any UR?
   4. Multi-dimensional fit criteria: for existing URs that have security implications
      (e.g., UR-10 drag-and-drop file sharing), what security fit criteria should be added?

   Stay in your lane — security only. Don't review architecture or ops."

4. DevOps Engineer — spawn with prompt:
   "You are the DevOps Engineer reviewing requirements for operational completeness.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/devops-engineer/SOUL.md

   Then read:
   - docs/requirements/user.md (the 26 URs — especially UR-07, UR-22)
   - ARCHITECTURE.md (deployment model)
   - CLAUDE.md (operational gotchas)
   - com.thul.studio.plist (launchd config)

   Your deliverable — write to docs/requirements/reviews/ops-review.md:
   1. Operational gaps: what operational requirements are missing?
      Consider: logging/observability, metrics, alerting, backup/restore,
      session data migration, resource limits, graceful degradation,
      deployment automation, rollback, health check depth.
   2. Scalability: what happens at 50 sessions? 100? 10 agents in conference?
      Are there URs needed for resource management?
   3. Multi-machine: UR-07 covers visibility but what about deployment,
      config sync, version consistency across M3/M4?
   4. Data integrity: sessions.json is the only persistence.
      What about backup, export, corruption recovery?

   Stay in your lane — operations and reliability. Don't review architecture or security."

5. Synthesis Lead — spawn with prompt:
   "You are the Chief of Staff synthesising the team's findings.
   Read your identity: /Users/thul/repos/ulleberg/thul-agents/agents/chief-of-staff/SOUL.md

   Wait for all four reviewers to complete their deliverables, then read:
   - docs/requirements/reviews/architecture-review.md
   - docs/requirements/reviews/test-review.md
   - docs/requirements/reviews/security-review.md
   - docs/requirements/reviews/ops-review.md

   Your deliverable — write to docs/requirements/reviews/synthesis.md:
   1. Cross-cutting findings: themes that appear in multiple reviews
   2. Contradictions: where reviewers disagree
   3. Priority-ranked list of missing URs (with proposed UR numbers)
   4. Priority-ranked list of fit criteria that need rewriting
   5. Recommendation: which URs to keep, modify, split, or remove
   6. Questions back to Thomas — ambiguities only he can resolve

   Challenge the reviewers. If a finding seems weak, say so."

Have teammates discuss and challenge each other's findings before the synthesis.
The synthesis lead should wait for all reviews before writing.
```

## Pass 2: Codebase-to-Requirements Trace (run after Pass 1)

After the reviews are complete and Thomas has made decisions, run a second team to trace
existing code back to requirements. This identifies dead code (no requirement) and
missing requirements (code exists but no UR).

This is a separate session — do not combine with Pass 1.

## Pre-flight Checklist

Before running:
1. Ensure agent teams are enabled:
   ```json
   // ~/.claude/settings.json
   { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
   ```
2. Create the reviews output directory:
   ```bash
   mkdir -p docs/requirements/reviews
   ```
3. Verify agents exist:
   ```bash
   ls /Users/thul/repos/ulleberg/thul-agents/agents/{chief-technical-officer,test-engineer,security-engineer,devops-engineer,chief-of-staff}/SOUL.md
   ```
4. Run from thul-studio root directory
