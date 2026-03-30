#!/bin/bash
# Volere pre-commit hook: check for secrets in staged files
# Blocks commit if secret patterns are found.
# Exit 0 = pass, exit 1 = blocked
#
# Install: copy to .git/hooks/pre-commit or use plugin/hooks/install.sh

set -euo pipefail

# Patterns that indicate secrets (regex)
PATTERNS=(
  # Generic API keys and tokens (long hex/base64 strings in assignments)
  '(api_key|apikey|api_token|secret_key|secret_token|access_key|private_key)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{20,}'
  # AWS access keys
  'AKIA[0-9A-Z]{16}'
  # Generic long hex tokens (40+ chars, likely secrets)
  '(token|secret|password|passwd|credential)\s*[:=]\s*["\x27][0-9a-fA-F]{40,}'
  # Private keys
  'BEGIN.*PRIVATE KEY'
  # Connection strings with passwords
  '(mongodb|postgres|mysql|redis):\/\/[^:]+:[^@]+@'
)

# Files to skip
SKIP_PATTERNS='(\.(test|spec|example)\.|\.env\.example|\.schema\.json|_test\.go|test/|tests/|\.md$)'

found=0
while IFS= read -r file; do
  # Skip binary files
  if file "$file" | grep -q "binary"; then
    continue
  fi

  # Skip test/example files
  if echo "$file" | grep -qE "$SKIP_PATTERNS"; then
    continue
  fi

  for pattern in "${PATTERNS[@]}"; do
    matches=$(grep -nEi "$pattern" "$file" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      if [ "$found" -eq 0 ]; then
        echo "🔒 Volere check-secrets: potential secrets detected"
        echo ""
      fi
      found=1
      echo "  $file:"
      echo "$matches" | while IFS= read -r line; do
        echo "    $line"
      done
      echo ""
    fi
  done
done < <(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

if [ "$found" -eq 1 ]; then
  echo "Commit blocked. Remove secrets before committing."
  echo "If this is a false positive, use: git commit --no-verify"
  echo "(but document why in the commit message)"
  exit 1
fi

exit 0
