#!/bin/bash
# Volere suspect link manager
# Tracks which requirements are suspect (need re-verification after upstream changes)
# State stored in .volere/suspects.yaml
#
# Usage:
#   suspect.sh mark <ID> --reason "UR-003 changed"    # Mark as suspect
#   suspect.sh resolve <ID>                             # Mark as resolved
#   suspect.sh list                                     # Show all suspect links
#   suspect.sh check                                    # Exit 1 if unresolved suspects exist

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SUSPECTS_FILE="$PROJECT_ROOT/.volere/suspects.yaml"

mkdir -p "$(dirname "$SUSPECTS_FILE")"
touch "$SUSPECTS_FILE"

cmd_mark() {
  local id="${1:?Usage: suspect.sh mark <ID> --reason 'why'}"
  shift
  local reason=""
  local source=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --reason) reason="$2"; shift 2 ;;
      --source) source="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local date=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Check if already suspect
  if grep -q "^  $id:" "$SUSPECTS_FILE" 2>/dev/null; then
    echo "Already suspect: $id"
    return 0
  fi

  # Append to suspects file
  if [ ! -s "$SUSPECTS_FILE" ]; then
    echo "suspects:" > "$SUSPECTS_FILE"
  fi

  cat >> "$SUSPECTS_FILE" << EOF
  $id:
    status: suspect
    reason: "$reason"
    source: "$source"
    date: "$date"
EOF

  echo "Marked as suspect: $id"
  [ -n "$reason" ] && echo "  Reason: $reason"
  [ -n "$source" ] && echo "  Source: $source"
}

cmd_resolve() {
  local id="${1:?Usage: suspect.sh resolve <ID>}"

  if ! grep -q "^  $id:" "$SUSPECTS_FILE" 2>/dev/null; then
    echo "Not suspect: $id"
    return 0
  fi

  # Update status to resolved
  local date=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Simple approach: remove the entry and re-add as resolved
  # (For a production tool, use a proper YAML editor)
  local temp=$(mktemp)
  awk -v id="  $id:" -v date="$date" '
    BEGIN { skip=0 }
    $0 == id { skip=1; print $0; next }
    skip && /^    status:/ { print "    status: resolved"; print "    resolved_date: \"" date "\""; next }
    skip && /^  [^ ]/ { skip=0 }
    { print }
  ' "$SUSPECTS_FILE" > "$temp"
  mv "$temp" "$SUSPECTS_FILE"

  echo "Resolved: $id"
}

cmd_list() {
  if [ ! -s "$SUSPECTS_FILE" ] || ! grep -q "status: suspect" "$SUSPECTS_FILE" 2>/dev/null; then
    echo "No suspect links."
    return 0
  fi

  echo "Suspect links:"
  echo ""

  # Parse and display
  local current_id=""
  while IFS= read -r line; do
    if echo "$line" | grep -qE "^  [A-Z]+-[0-9]+:"; then
      current_id=$(echo "$line" | sed 's/://g' | tr -d ' ')
    fi
    if echo "$line" | grep -q "status: suspect"; then
      local reason=$(grep -A3 "^  $current_id:" "$SUSPECTS_FILE" | grep "reason:" | sed 's/.*reason: //' | sed 's/^"//' | sed 's/"$//')
      local source=$(grep -A3 "^  $current_id:" "$SUSPECTS_FILE" | grep "source:" | sed 's/.*source: //' | sed 's/^"//' | sed 's/"$//')
      local date=$(grep -A3 "^  $current_id:" "$SUSPECTS_FILE" | grep "date:" | sed 's/.*date: //' | sed 's/^"//' | sed 's/"$//')
      echo "  ✗ $current_id"
      [ -n "$reason" ] && echo "    Reason: $reason"
      [ -n "$source" ] && echo "    Source: $source"
      [ -n "$date" ] && echo "    Since: $date"
      echo ""
    fi
  done < "$SUSPECTS_FILE"
}

cmd_check() {
  if grep -q "status: suspect" "$SUSPECTS_FILE" 2>/dev/null; then
    local count=$(grep -c "status: suspect" "$SUSPECTS_FILE")
    echo "✗ $count unresolved suspect link(s)"
    cmd_list
    echo "Resolve with: volere impact --resolve <ID>"
    exit 1
  else
    echo "✓ No unresolved suspect links"
    exit 0
  fi
}

# Auto-detect suspects from git changes
cmd_auto() {
  # Find requirements changed in recent commits (since last tag or last 10 commits)
  local changed_reqs=$(git diff --name-only HEAD~5..HEAD 2>/dev/null | grep "docs/requirements/.*\.yaml" | grep -v context.yaml || true)

  if [ -z "$changed_reqs" ]; then
    echo "No requirement changes in recent commits."
    return 0
  fi

  echo "Requirements changed recently:"
  for f in $changed_reqs; do
    local id=$(grep "^id:" "$PROJECT_ROOT/$f" 2>/dev/null | head -1 | awk '{print $2}')
    [ -z "$id" ] && continue
    echo "  $id ($f)"

    # Find dependents
    local reqs_dir="$PROJECT_ROOT/docs/requirements"
    for dep_file in "$reqs_dir"/*.yaml; do
      [ -f "$dep_file" ] || continue
      [ "$(basename "$dep_file")" = "context.yaml" ] && continue
      [ "$dep_file" = "$PROJECT_ROOT/$f" ] && continue

      if grep -q "$id" "$dep_file" 2>/dev/null; then
        local dep_id=$(grep "^id:" "$dep_file" | head -1 | awk '{print $2}')
        cmd_mark "$dep_id" --reason "$id changed" --source "$id" 2>/dev/null || true
      fi
    done
  done
}

case "${1:-list}" in
  mark)    shift; cmd_mark "$@" ;;
  resolve) shift; cmd_resolve "$@" ;;
  list)    cmd_list ;;
  check)   cmd_check ;;
  auto)    cmd_auto ;;
  *)       echo "Usage: suspect.sh {mark|resolve|list|check|auto}" ;;
esac
