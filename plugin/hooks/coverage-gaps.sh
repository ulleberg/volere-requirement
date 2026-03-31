#!/bin/bash
# Volere SessionStart hook: inject uncovered requirements into agent context
# Reads the coverage state and surfaces gaps so the agent knows what to work on
# before the user says anything.
#
# Usage: Register as a SessionStart hook in .claude/settings.json:
#   "hooks": {
#     "SessionStart": [
#       { "command": "plugin/hooks/coverage-gaps.sh" }
#     ]
#   }
#
# Output goes to stdout — Claude Code injects it into the session context.

set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
VOLERE_CLI="$PROJECT_ROOT/plugin/cli/volere"
REQS_DIR="$PROJECT_ROOT/docs/requirements"

# Skip if not a Volere project
if [ ! -d "$PROJECT_ROOT/.volere" ] && [ ! -d "$REQS_DIR" ]; then
  exit 0
fi

# Skip if no requirements exist
if [ ! -d "$REQS_DIR" ]; then
  exit 0
fi

CARD_COUNT=$(find -L "$REQS_DIR" -name "*.yaml" -not -name "context.yaml" 2>/dev/null | wc -l | tr -d ' ')
if [ "$CARD_COUNT" -eq 0 ]; then
  exit 0
fi

# Count total, tested, and untested requirements
TOTAL=0
TESTED=0
UNTESTED_LIST=""
DAL_B_GAPS=""

for f in "$REQS_DIR"/*.yaml; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "context.yaml" ] && continue

  id=$(grep "^id:" "$f" 2>/dev/null | head -1 | awk '{print $2}')
  [ -z "$id" ] && continue

  # Skip deprecated requirements
  status=$(grep "^status:" "$f" 2>/dev/null | head -1 | awk '{print $2}')
  [ "$status" = "deprecated" ] && continue

  # Skip not-yet-implemented requirements (don't inflate denominator)
  testability=$(grep "^testability:" "$f" 2>/dev/null | head -1 | awk '{print $2}' || echo "automatable")
  [ -z "$testability" ] && testability="automatable"
  [ "$testability" = "not-yet-implemented" ] && continue

  dal=$(grep "^dal:" "$f" 2>/dev/null | head -1 | awk '{print $2}')
  title=$(grep "^title:" "$f" 2>/dev/null | head -1 | sed 's/^title: //; s/^"//; s/"$//')

  TOTAL=$((TOTAL + 1))

  # Check if any test file references this ID
  has_test=$(grep -rl "$id" "$PROJECT_ROOT" \
    --include="*_test.go" --include="*.test.js" --include="*.test.ts" --include="*.spec.*" \
    --include="*test*.sh" --include="*_test.py" --include="*_test.rs" \
    2>/dev/null | grep -v node_modules | head -1 || true)

  if [ -n "$has_test" ]; then
    TESTED=$((TESTED + 1))
  else
    UNTESTED_LIST="$UNTESTED_LIST  - $id: $title (DAL-$dal)\n"
    if [ "$dal" = "A" ] || [ "$dal" = "B" ]; then
      DAL_B_GAPS="$DAL_B_GAPS  - $id: $title (DAL-$dal)\n"
    fi
  fi
done

if [ "$TOTAL" -eq 0 ]; then
  exit 0
fi

UNTESTED=$((TOTAL - TESTED))
PCT=$((TESTED * 100 / TOTAL))

# Only output if there are gaps
if [ "$UNTESTED" -eq 0 ]; then
  echo "Volere coverage: $TESTED/$TOTAL (100%) — all testable requirements covered."
  exit 0
fi

echo "Volere acceptance coverage: $TESTED/$TOTAL ($PCT%)"
echo ""

# Highlight DAL-B+ gaps first (highest priority)
if [ -n "$DAL_B_GAPS" ]; then
  echo "Critical gaps (DAL-A/B — close first):"
  echo -e "$DAL_B_GAPS"
fi

# Show remaining gaps
if [ "$UNTESTED" -gt 5 ]; then
  # Truncate for context window efficiency
  echo "Uncovered requirements ($UNTESTED total, showing DAL-A/B above):"
  echo "  Run 'volere coverage' for full list."
else
  echo "Uncovered requirements:"
  echo -e "$UNTESTED_LIST"
fi

echo "Propose which gaps to close in this session."
