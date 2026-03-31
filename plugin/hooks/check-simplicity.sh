#!/bin/bash
# Volere pre-commit hook: measure diff complexity and prompt self-evaluation
# Advisory — warns but never blocks. Pairs with the Simplicity Protocol in CLAUDE.md.
#
# Install: plugin/hooks/install.sh (installs as pre-commit, chained after check-secrets)

set -euo pipefail

# Get staged diff stats
STATS=$(git diff --cached --stat 2>/dev/null | tail -1 || true)

if [ -z "$STATS" ]; then
  exit 0
fi

# Parse insertions and deletions
INSERTIONS=$(echo "$STATS" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
DELETIONS=$(echo "$STATS" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)
FILES_CHANGED=$(echo "$STATS" | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || echo 0)

[ -z "$INSERTIONS" ] && INSERTIONS=0
[ -z "$DELETIONS" ] && DELETIONS=0
[ -z "$FILES_CHANGED" ] && FILES_CHANGED=0

NET=$((INSERTIONS - DELETIONS))

# Count new files being added
NEW_FILES=$(git diff --cached --name-status | grep "^A" | wc -l | tr -d ' ')

# Only speak up when there's something worth noting
if [ "$NET" -le 0 ] && [ "$NEW_FILES" -eq 0 ]; then
  # Net removal or neutral, no new files — this is good
  exit 0
fi

# Advisory output — never blocks
echo ""
echo "Simplicity check: +$INSERTIONS -$DELETIONS (net +$NET) across $FILES_CHANGED file(s), $NEW_FILES new"

if [ "$NET" -gt 100 ]; then
  echo "  Large addition. Have you questioned whether every line is needed?"
elif [ "$NEW_FILES" -gt 2 ]; then
  echo "  $NEW_FILES new files. Could any be merged into existing files?"
elif [ "$DELETIONS" -eq 0 ] && [ "$INSERTIONS" -gt 20 ]; then
  echo "  Pure addition, zero removal. Can anything existing be simplified or replaced?"
fi

exit 0
