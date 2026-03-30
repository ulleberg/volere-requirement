#!/bin/bash
# Volere post-checkout hook: detect requirement drift between branches
# Advisory only — never blocks (checkout already happened).
#
# Install: plugin/hooks/install.sh (installs as post-checkout)

set -euo pipefail

# post-checkout receives: previous HEAD, new HEAD, branch flag (1=branch, 0=file)
PREV_HEAD="${1:-}"
NEW_HEAD="${2:-}"
BRANCH_FLAG="${3:-1}"

# Only run on branch checkouts, not file checkouts
if [ "$BRANCH_FLAG" != "1" ]; then
  exit 0
fi

# Skip if no previous HEAD (initial checkout)
if [ -z "$PREV_HEAD" ] || [ "$PREV_HEAD" = "0000000000000000000000000000000000000000" ]; then
  exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROFILE="$PROJECT_ROOT/.volere/profile.yaml"
REQS_DIR="$PROJECT_ROOT/docs/requirements"

# Skip if not a Volere project
if [ ! -d "$PROJECT_ROOT/.volere" ] && [ ! -d "$REQS_DIR" ]; then
  exit 0
fi

echo ""
echo "🔍 Volere post-checkout: checking requirement state"

WARNINGS=0

# 1. Check for DAL mismatch between branches
if [ -f "$PROFILE" ]; then
  CURRENT_DAL=$(grep "^dal:" "$PROFILE" 2>/dev/null | head -1 | awk '{print $2}' || true)
  PREV_DAL=$(git show "$PREV_HEAD:.volere/profile.yaml" 2>/dev/null | grep "^dal:" | head -1 | awk '{print $2}' || true)

  if [ -n "$PREV_DAL" ] && [ -n "$CURRENT_DAL" ] && [ "$PREV_DAL" != "$CURRENT_DAL" ]; then
    echo "  ⚠ DAL level changed: $PREV_DAL → $CURRENT_DAL"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# 2. Check for changed requirement cards
if [ -d "$REQS_DIR" ]; then
  CHANGED_REQS=$(git diff --name-only "$PREV_HEAD" "$NEW_HEAD" -- "$REQS_DIR" 2>/dev/null || true)

  if [ -n "$CHANGED_REQS" ]; then
    MODIFIED=$(echo "$CHANGED_REQS" | wc -l | tr -d ' ')
    echo "  ⚠ $MODIFIED requirement card(s) differ from previous branch:"
    echo "$CHANGED_REQS" | while read -r f; do
      echo "    - $(basename "$f")"
    done
    WARNINGS=$((WARNINGS + 1))
  fi
fi

if [ "$WARNINGS" -eq 0 ]; then
  echo "  ✓ Requirement state consistent"
fi

echo ""
exit 0
