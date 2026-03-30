#!/bin/bash
# Volere post-merge hook: detect suspect links and cross-verify violations
# Advisory only — never blocks (merge already happened).
#
# Install: plugin/hooks/install.sh (installs as post-merge)

set -euo pipefail

# post-merge receives: squash flag (0=normal merge, 1=squash)
SQUASH_FLAG="${1:-0}"

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
REQS_DIR="$PROJECT_ROOT/docs/requirements"
SUSPECT_CMD="$PROJECT_ROOT/plugin/cli/suspect.sh"

# Skip if not a Volere project
if [ ! -d "$PROJECT_ROOT/.volere" ] && [ ! -d "$REQS_DIR" ]; then
  exit 0
fi

# Get the merge commit range
MERGE_HEAD=$(git rev-parse HEAD)
MERGE_BASE=$(git rev-parse HEAD~1 2>/dev/null || exit 0)

echo ""
echo "🔍 Volere post-merge: checking requirement impacts"

WARNINGS=0

# 1. Find requirement cards changed in the merge
CHANGED_REQS=$(git diff --name-only "$MERGE_BASE" "$MERGE_HEAD" -- "$REQS_DIR" 2>/dev/null | grep '\.yaml$' | grep -v 'context\.yaml' || true)

if [ -z "$CHANGED_REQS" ]; then
  echo "  ✓ No requirement cards changed in merge"
  echo ""
  exit 0
fi

echo "  Changed requirements:"
CHANGED_IDS=""
for f in $CHANGED_REQS; do
  basename_f=$(basename "$f" .yaml)
  echo "    - $basename_f"
  # Extract ID from filename (e.g., UR-003 from UR-003.yaml)
  id=$(echo "$basename_f" | grep -oE '(UR|TC|BUC|PUC|SEC|SHR)-[0-9]{3}' || true)
  if [ -n "$id" ]; then
    CHANGED_IDS="$CHANGED_IDS $id"
  fi
done

# 2. Mark suspect links for changed requirements
if [ -x "$SUSPECT_CMD" ]; then
  for id in $CHANGED_IDS; do
    echo ""
    echo "  Marking suspect links for $id..."
    "$SUSPECT_CMD" auto "$id" 2>/dev/null || true
    WARNINGS=$((WARNINGS + 1))
  done
else
  echo ""
  echo "  ⚠ Suspect link manager not found — run 'volere impact <ID>' manually for:"
  for id in $CHANGED_IDS; do
    echo "    - $id"
  done
  WARNINGS=$((WARNINGS + 1))
fi

# 3. Check cross_verify targets
for f in $CHANGED_REQS; do
  full_path="$PROJECT_ROOT/$f"
  if [ -f "$full_path" ]; then
    # Extract cross_verify entries from YAML (simple grep approach)
    CROSS_TARGETS=$(grep -A 20 'cross_verify:' "$full_path" 2>/dev/null | grep -oE '(UR|TC|BUC|PUC|SEC|SHR)-[0-9]{3}' || true)
    if [ -n "$CROSS_TARGETS" ]; then
      basename_f=$(basename "$f" .yaml)
      echo ""
      echo "  ⚠ $basename_f has cross_verify targets that need re-verification:"
      for target in $CROSS_TARGETS; do
        echo "    → $target"
      done
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
done

# 4. Validate merged cards
echo ""
VOLERE_CLI="$PROJECT_ROOT/plugin/cli/volere"
if [ -x "$VOLERE_CLI" ]; then
  if ! "$VOLERE_CLI" validate --quiet 2>/dev/null; then
    echo "  ⚠ Post-merge validation found issues"
    echo "    Run: volere validate"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "  ✓ Post-merge validation passed"
  fi
fi

if [ "$WARNINGS" -gt 0 ]; then
  echo ""
  echo "  $WARNINGS item(s) need attention. Run 'volere validate' for details."
fi

echo ""
exit 0
