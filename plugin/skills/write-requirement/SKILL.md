---
name: write-requirement
description: Writes a Volere requirement card — guides through snow card format with multi-dimensional fit criteria, DAL classification, and traceability. Use when adding a requirement, creating a UR or TC, or when a new requirement is identified during work.
---

# Write Requirement

Guide the agent through writing a Volere requirement card in YAML format. Every requirement must be testable, traceable, and classified by risk.

## When to Use

- "Add a requirement"
- "Write a UR for session persistence"
- "Create a technical constraint for idle debounce"
- "We need a requirement for..."
- Any time a new requirement is identified during work

## Before Writing

1. **Read the project context** if it exists:
   ```
   docs/requirements/context.yaml
   ```
   Understand the project scope, stakeholders, glossary, and constraints.
   Use the glossary terms — don't invent synonyms.

2. **Read existing requirements** to understand numbering and patterns:
   ```
   ls docs/requirements/UR-*.yaml docs/requirements/TC-*.yaml
   ```
   Find the next available number.

3. **Determine the requirement level:**
   - **BUC** (Business Use Case, Volere §7) — high-level business process the system supports. Answers "why do these requirements exist?" Decomposes into PUCs or URs.
   - **PUC** (Product Use Case, Volere §8) — specific user-system interaction. Answers "what does the user do?" Decomposes into URs. Each PUC serves a BUC.
   - **UR** (User Requirement, Volere §9-17) — what the user needs from the system. Implements a PUC or BUC. Decomposes into TCs.
   - **TC** (Technical Constraint) — implementation contract that serves a UR. Emerged during development, not from user needs.
   - **SHR** (Stakeholder Requirement, Volere §1-5) — high-level need (complex/regulated projects only)

   **Decomposition rule:** Start with BUCs. If URs exist without a parent BUC, that's a gap — either the BUC is missing or the UR is orphaned. Not every project needs PUCs (the intermediate layer), but every project needs BUCs to give requirements context.

## Writing the Card

Work through each field. Do NOT skip fields — every field exists for a reason.

### 1. Title and Description
- Title: one line, max 100 characters, describes WHAT
- Description: one sentence, describes the system behavior
- **Test:** Can you read the title and know what this requirement is about without reading the description? If not, rewrite the title.

### 2. Rationale
- WHY this requirement exists — the pain that created it
- Reference the real-world trigger (a bug, a user complaint, a regulatory need)
- **Test:** If someone asks "why do we need this?", does the rationale answer it? If the rationale just restates the description, it's too weak.

### 3. Fit Criteria (the most important field)

Every fit criterion must be:
- **Measurable** — contains a number, threshold, or binary condition
- **Testable** — an agent can write an automated test for it
- **Specific** — references real system components, not vague concepts

Bad: "The system should be fast"
Good: "95% of API responses complete within 200ms"

Bad: "The system should be secure"
Good: "Non-Tailscale origin requests receive no CORS headers on API routes"

**Multi-dimensional fit criteria:**

Ask: does this requirement have acceptance conditions beyond the user dimension?

| Dimension | When to add | Example |
|-----------|-------------|---------|
| `user` | Always — the primary acceptance condition | "Response visible in chat within 5s of agent idle" |
| `security` | When the requirement handles auth, data, or trust boundaries | "Broadcast content > 1MB rejected with 413" |
| `operational` | When the requirement affects reliability, deployment, or monitoring | "Works during cross-machine deployment" |
| `performance` | When speed, throughput, or resource usage matters | "Port allocation completes in < 10ms" |
| Regulatory (e.g., `fcc-part15`, `iec-62443`) | When the project has compliance profiles in `.volere/compliance.yaml` | "Conducted emissions below 47 CFR 15.107 limits" |

For each dimension, specify:
- `criterion` — the measurable condition
- `verification` — how it's verified: `test`, `analysis`, `review`, or `demonstration`
- `test_type` — if verification is `test`: `unit`, `integration`, `system`, `performance`, `security`, or `lab-test`

### 4. DAL Classification

Classify the risk if this requirement fails:

| DAL | Failure Impact | Example |
|-----|---------------|---------|
| **A** | Catastrophic — data loss, safety incident, security breach | Database migration, auth bypass, safety-critical control |
| **B** | Critical — service degradation, data corruption | Session data integrity, secrets exposure |
| **C** | Moderate — feature broken, user impact | Session state detection, file preview |
| **D** | Minor — cosmetic, workaround exists | Workspace grouping, context summary |
| **E** | Cosmetic — no user impact | CSS fix, documentation |

### 5. Priority (MoSCoW)

- **must** — system doesn't work without it
- **should** — important, but system functions without it
- **could** — nice to have
- **wont** — not this version (but documented for future)

### 6. Origin

- Who requested it (stakeholder name or agent role)
- When (ISO date)
- What triggered it (the event, bug, or pain)
- Source (parent requirement ID if this was derived)

### 7. Traceability

- `depends_on` — what must be true for this to work?
- `conflicts` — what can't coexist with this?
- `decomposed_to` — what child requirements does this break into?
- `serves` (TC only) — which UR(s) does this technical constraint serve?

### 8. Cross-Impact Verification

Ask: **"Does this requirement's fit criterion affect other requirements?"**

If this is a security, infrastructure, or platform change, identify which user-facing requirements could break:

| Change type | Ask | Example |
|-------------|-----|---------|
| Security (CSP, CORS, auth) | Which browser surfaces or API consumers does this restrict? | CSP blocking CDN scripts breaks grid page |
| Infrastructure (ports, networking, deployment) | Which features depend on the infrastructure being changed? | Port change breaks WebSocket connections |
| Performance (rate limits, timeouts, caching) | Which features hit the constrained resource? | Cache TTL change breaks real-time updates |
| Data model (schema, storage, format) | Which features read/write this data? | Column rename breaks downstream queries |

Populate the `cross_verify` field with the affected requirement IDs:

```yaml
cross_verify:
  - UR-03   # Grid page — loads React from CDN
  - UR-12   # TTS audio — uses blob: URLs
```

**Test:** If this requirement changes, would someone know which OTHER requirements to re-verify? If not, `cross_verify` is incomplete.

### 9. Testability

Default: `automatable`. Only change if you can justify why this requirement cannot be verified by running code.

| Value | When to use | Justification required? |
|-------|-------------|------------------------|
| `automatable` | Fit criterion can be asserted by a test | No (default) |
| `operational` | Requires live infrastructure (cross-machine, deployment) | Yes — what specifically requires live infra? |
| `hardware-dependent` | Requires physical device | Yes — and consider loopback testing first |
| `not-yet-implemented` | Requirement exists but feature not built yet | No — but update when implemented |

**"Manual-only" is not an option.** If you think a requirement can only be verified manually, reconsider. Mobile PWA can be tested with Playwright device emulation. Crash recovery can be tested with SSH kill/restart scripts. STT can be tested with TTS loopback. The question is not "can a human verify this?" but "what observable state change proves this criterion is met?"

## Output

Write the requirement card to:
- `docs/requirements/UR-{NNN}.yaml` for user requirements
- `docs/requirements/TC-{NNN}.yaml` for technical constraints

Use the template from the plugin:
- `plugin/templates/requirement-card.yaml` (UR)
- `plugin/templates/technical-constraint.yaml` (TC)

## Validation

After writing, validate the card against the schema:

```bash
# If yq and jsonschema are available:
yq -o json docs/requirements/UR-{NNN}.yaml | jsonschema plugin/schema/requirement.schema.json

# Or use volere validate (when CLI is available):
volere validate --file docs/requirements/UR-{NNN}.yaml
```

If validation fails, fix the card before committing.

## Quality Checklist

Before committing, verify:

- [ ] Title is clear and < 100 characters
- [ ] Description is one sentence, describes system behavior
- [ ] Rationale explains WHY (not just restates WHAT)
- [ ] Every fit criterion is measurable and testable
- [ ] No fit criterion says "should" or "appropriate" or "reasonable" — these are vague
- [ ] DAL is justified (not just defaulting to C)
- [ ] Priority is justified (not just defaulting to must)
- [ ] Origin has a real stakeholder, date, and trigger
- [ ] Traceability links are correct (depends_on, serves, decomposed_to)
- [ ] Card passes schema validation
- [ ] If this is a TC, the `serves` field references at least one UR
- [ ] If this is a security/infrastructure change, `cross_verify` lists affected user-facing requirements

## Anti-patterns to Avoid

- **Solution masquerading as requirement:** "Use Redis for caching" is a design decision, not a requirement. The requirement is "Response time < 200ms" — Redis is one way to achieve it.
- **Implementation detail in fit criterion:** "The `detectState()` function returns correct state" is testing code, not a requirement. The fit criterion is "State detection accuracy > 95% across 20+ known patterns."
- **Missing failure mode:** If the fit criterion only describes the happy path, add the failure case. "If the agent is unreachable, show error within 15s."
- **Untestable criterion:** "The system should be user-friendly" — what does "user-friendly" mean? Replace with measurable: "Task completion time < 30s for common workflows."
- **Gold-plating:** Don't add dimensions that don't apply. Not every requirement needs security and operational fit criteria. Add dimensions that matter.
