#!/bin/bash
# Volere commit-msg hook: check for requirement ID references in commit message
# Warns (or blocks in strict mode) if no requirement ID is found.
#
# Set VOLERE_TRACEABILITY_STRICT=1 to block commits without requirement references.
# Exit 0 = pass/warn, exit 1 = blocked (strict mode only)
#
# Install: copy to .git/hooks/commit-msg or use plugin/hooks/install.sh

set -euo pipefail

COMMIT_MSG_FILE="${1:-.git/COMMIT_MSG}"

if [ ! -f "$COMMIT_MSG_FILE" ]; then
  exit 0
fi

COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Skip merge commits
if echo "$COMMIT_MSG" | head -1 | grep -qE "^Merge "; then
  exit 0
fi

# Skip initial commit
if ! git rev-parse HEAD >/dev/null 2>&1; then
  exit 0
fi

# Look for requirement ID patterns: UR-NNN, TC-NNN, BUC-NNN, PUC-NNN, SEC-NNN, SHR-NNN
ID_PATTERN='(UR|TC|BUC|PUC|SEC|SHR)-[0-9]{3}'

if echo "$COMMIT_MSG" | grep -qE "$ID_PATTERN"; then
  # Found a requirement reference
  IDS=$(echo "$COMMIT_MSG" | grep -oE "$ID_PATTERN" | sort -u | tr '\n' ' ')
  exit 0
fi

# No requirement reference found
STRICT="${VOLERE_TRACEABILITY_STRICT:-0}"

if [ "$STRICT" = "1" ]; then
  echo "🔗 Volere check-traceability: no requirement ID found in commit message"
  echo ""
  echo "  Expected: UR-NNN, TC-NNN, BUC-NNN, PUC-NNN, SEC-NNN, or SHR-NNN"
  echo "  Example:  'Fix idle debounce timing (TC-005)'"
  echo ""
  echo "  Commit blocked (VOLERE_TRACEABILITY_STRICT=1)"
  echo "  To bypass: git commit --no-verify (but document why)"
  exit 1
else
  echo "⚠ Volere: commit message has no requirement reference (UR-NNN, TC-NNN, etc.)"
  echo "  This is a warning. Set VOLERE_TRACEABILITY_STRICT=1 to enforce."
  exit 0
fi
