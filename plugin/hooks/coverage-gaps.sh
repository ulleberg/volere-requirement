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

# Count total dimensions, tested dimensions, and untested gaps
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

  # Skip not-yet-implemented requirements
  testability=$(grep "^testability:" "$f" 2>/dev/null | head -1 | awk '{print $2}' || echo "automatable")
  [ -z "$testability" ] && testability="automatable"
  [ "$testability" = "not-yet-implemented" ] && continue

  dal=$(grep "^dal:" "$f" 2>/dev/null | head -1 | awk '{print $2}')
  title=$(grep "^title:" "$f" 2>/dev/null | head -1 | sed 's/^title: //; s/^"//; s/"$//')

  # Extract dimension names from fit_criteria block
  in_fit=0
  dims_list=""
  while IFS= read -r line; do
    if echo "$line" | grep -q "^fit_criteria:"; then
      in_fit=1; continue
    fi
    if [ "$in_fit" -eq 1 ]; then
      if echo "$line" | grep -qE "^[a-z_]+:" && ! echo "$line" | grep -qE "^  "; then
        break
      fi
      if echo "$line" | grep -qE "^  [a-z_]+:$"; then
        dname=$(echo "$line" | sed 's/^  //; s/://')
        dims_list="$dims_list $dname"
      fi
    fi
  done < "$f"
  dims_list=$(echo "$dims_list" | xargs)
  [ -z "$dims_list" ] && dims_list="user"

  # Find test files referencing this ID
  test_files=$(grep -rl "$id" "$PROJECT_ROOT" \
    --include="*_test.go" --include="*.test.js" --include="*.test.ts" --include="*.spec.*" \
    --include="*test*.sh" --include="*_test.py" --include="*_test.rs" \
    2>/dev/null | grep -v node_modules || true)

  # Check each dimension
  for dname in $dims_list; do
    TOTAL=$((TOTAL + 1))
    found=0

    if [ -n "$test_files" ]; then
      if echo "$test_files" | xargs grep -l "$id:$dname" 2>/dev/null | head -1 | grep -q .; then
        found=1
      fi
      if [ "$found" -eq 0 ] && [ "$dname" = "user" ]; then
        if echo "$test_files" | xargs grep -l "$id" 2>/dev/null | head -1 | grep -q .; then
          found=1
        fi
      fi
    fi

    if [ "$found" -eq 1 ]; then
      TESTED=$((TESTED + 1))
    else
      UNTESTED_LIST="$UNTESTED_LIST  - $id: $title ($dname, DAL-$dal)\n"
      if [ "$dal" = "A" ] || [ "$dal" = "B" ]; then
        fit_text=$(grep -A1 "criterion:" "$f" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//' | head -c 120 || true)
        [ -z "$fit_text" ] && fit_text="(no fit criterion)"
        DAL_B_GAPS="$DAL_B_GAPS  - $id: $title ($dname, DAL-$dal)\n    Fit: $fit_text\n"
      fi
    fi
  done
done

if [ "$TOTAL" -eq 0 ]; then
  exit 0
fi

UNTESTED=$((TOTAL - TESTED))
PCT=$((TESTED * 100 / TOTAL))

# Only output if there are gaps
if [ "$UNTESTED" -eq 0 ]; then
  echo "Volere coverage: $TESTED/$TOTAL (100%) — all testable requirements covered."
fi

if [ "$UNTESTED" -gt 0 ]; then
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
fi

# Documentation staleness check (UR-021)
# Constitution docs are always checked; profile.yaml docs field adds extras
CONSTITUTION_DOCS="ARCHITECTURE.md README.md CLAUDE.md"
EXTRA_DOCS=""
if [ -f "$PROJECT_ROOT/.volere/profile.yaml" ]; then
  EXTRA_DOCS=$(grep -A 100 "^docs:" "$PROJECT_ROOT/.volere/profile.yaml" 2>/dev/null | \
    grep "^  - " | sed 's/^  - //' | tr -d '"' || true)
fi

# Find most recent source change in plugin/
LATEST_SOURCE=0
for ext in yaml sh md; do
  candidate=$(find "$PROJECT_ROOT/plugin" -name "*.$ext" -not -path "*/reviews/*" 2>/dev/null | \
    xargs stat -f %m 2>/dev/null | sort -rn | head -1 || \
    find "$PROJECT_ROOT/plugin" -name "*.$ext" -not -path "*/reviews/*" -exec stat -c %Y {} \; 2>/dev/null | sort -rn | head -1 || echo 0)
  [ "${candidate:-0}" -gt "$LATEST_SOURCE" ] && LATEST_SOURCE="$candidate"
done

STALE_DOCS=""
for doc in $CONSTITUTION_DOCS $EXTRA_DOCS; do
  doc_path="$PROJECT_ROOT/$doc"
  [ -f "$doc_path" ] || continue
  doc_mtime=$(stat -f %m "$doc_path" 2>/dev/null || stat -c %Y "$doc_path" 2>/dev/null || echo 0)
  if [ "$LATEST_SOURCE" -gt 0 ] && [ "$doc_mtime" -gt 0 ]; then
    days_stale=$(( (LATEST_SOURCE - doc_mtime) / 86400 ))
    if [ "$days_stale" -gt 7 ]; then
      STALE_DOCS="$STALE_DOCS  - $doc ($days_stale days)\n"
    fi
  fi
done

if [ -n "$STALE_DOCS" ]; then
  echo ""
  echo "Stale docs:"
  echo -e "$STALE_DOCS"
fi
