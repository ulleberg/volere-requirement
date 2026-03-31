# Plugin Sync Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Auto-sync `volere-requirement/plugin/` → `ulleberg/volere` via GitHub Actions when tests pass.

**Architecture:** Single workflow file in `volere-requirement`. Runs tests, checks out the target repo with a PAT, rsync-copies the file mapping, commits and pushes if changed.

**Tech Stack:** GitHub Actions, bash, rsync

---

### Task 1: Create the sync workflow

**Files:**
- Create: `.github/workflows/sync-plugin.yml`

- [ ] **Step 1: Create the workflow file**

```yaml
name: Sync plugin to ulleberg/volere

on:
  push:
    branches: [main]
    paths: ['plugin/**']
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run test suite
        run: plugin/hooks/test-hooks.sh

  sync:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source
        uses: actions/checkout@v4
        with:
          path: source

      - name: Checkout target
        uses: actions/checkout@v4
        with:
          repository: ulleberg/volere
          token: ${{ secrets.VOLERE_PLUGIN_PAT }}
          path: target

      - name: Sync files
        run: |
          # Skills (preserve using-volere which only exists in target)
          rsync -a --delete --exclude='using-volere/' source/plugin/skills/ target/skills/

          # CLI
          mkdir -p target/commands/cli
          rsync -a --delete source/plugin/cli/ target/commands/cli/

          # Schema, catalogs, templates
          rsync -a --delete source/plugin/schema/ target/schema/
          rsync -a --delete source/plugin/catalogs/ target/catalogs/
          rsync -a --delete source/plugin/templates/ target/templates/

          # Validator
          cp source/plugin/validate.sh target/validate.sh

          # SessionStart hook script
          cp source/plugin/hooks/coverage-gaps.sh target/hooks/session-start/coverage-gaps.sh

      - name: Check for changes
        id: changes
        working-directory: target
        run: |
          git diff --quiet && git diff --cached --quiet && echo "changed=false" >> "$GITHUB_OUTPUT" || echo "changed=true" >> "$GITHUB_OUTPUT"

      - name: Commit and push
        if: steps.changes.outputs.changed == 'true'
        working-directory: target
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add -A
          git commit -m "Sync from volere-requirement @ $(cd ../source && git rev-parse --short HEAD)"
          git push
```

- [ ] **Step 2: Verify the workflow YAML is valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/sync-plugin.yml'))" && echo "Valid YAML"`
Expected: "Valid YAML"

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/sync-plugin.yml
git commit -m "ci: add plugin sync workflow to ulleberg/volere"
```

---

### Task 2: Add the PAT secret to GitHub

- [ ] **Step 1: Verify the secret name matches the workflow**

The workflow references `secrets.VOLERE_PLUGIN_PAT`. The user must add this secret manually:

```bash
# Option A: via gh CLI
gh secret set VOLERE_PLUGIN_PAT --repo ulleberg/volere-requirement

# Option B: via GitHub UI
# Settings → Secrets and variables → Actions → New repository secret
# Name: VOLERE_PLUGIN_PAT
# Value: (GitHub PAT with repo scope for ulleberg/volere)
```

- [ ] **Step 2: Test the workflow**

Push the workflow file to trigger it, or run manually:

```bash
gh workflow run sync-plugin.yml --repo ulleberg/volere-requirement
```

- [ ] **Step 3: Verify sync worked**

```bash
cd /Users/thul/repos/ulleberg/volere && git pull
git log --oneline -1
# Should show: "Sync from volere-requirement @ <short-sha>"
```
