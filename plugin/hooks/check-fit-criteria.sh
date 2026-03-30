#!/bin/bash
# Volere pre-push hook: check that affected fit criteria have passing tests
# Reads DAL level and verification commands from .volere/profile.yaml.
# Uses configured verification_commands if present, falls back to auto-detection.
# Only blocks at DAL-B and above by default.
#
# Exit 0 = pass, exit 1 = blocked
#
# Install: plugin/hooks/install.sh (installs as pre-push)

set -euo pipefail

# Find project root (where .volere/ lives)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROFILE="$PROJECT_ROOT/.volere/profile.yaml"
REQS_DIR="$PROJECT_ROOT/docs/requirements"

# Default DAL if no profile exists
DEFAULT_DAL="C"

# Read default DAL from profile
if [ -f "$PROFILE" ]; then
  DAL=$(grep "^dal:" "$PROFILE" 2>/dev/null | head -1 | awk '{print $2}' || echo "$DEFAULT_DAL")
else
  DAL="$DEFAULT_DAL"
fi

# DAL levels where this hook blocks (B and above)
BLOCKING_DALS="A B"

should_block() {
  local level="$1"
  for d in $BLOCKING_DALS; do
    if [ "$level" = "$d" ]; then
      return 0
    fi
  done
  return 1
}

# If project DAL doesn't require blocking, pass
if ! should_block "$DAL"; then
  exit 0
fi

# Get changed files in this push
CHANGED_FILES=$(git diff --name-only HEAD @{u} 2>/dev/null || git diff --name-only HEAD~1 HEAD 2>/dev/null || true)

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Check if any changed file is a source file (not docs, not config)
HAS_CODE_CHANGES=0
for f in $CHANGED_FILES; do
  case "$f" in
    *.go|*.js|*.ts|*.py|*.rb|*.rs|*.java|*.c|*.cpp|*.h)
      HAS_CODE_CHANGES=1
      break
      ;;
  esac
done

if [ "$HAS_CODE_CHANGES" -eq 0 ]; then
  # Docs-only change, no verification needed
  exit 0
fi

# Find affected requirements by searching for UR/TC IDs in changed files
AFFECTED_IDS=""
for f in $CHANGED_FILES; do
  if [ -f "$f" ]; then
    ids=$(grep -oE '(UR|TC|BUC|PUC)-[0-9]{3}' "$f" 2>/dev/null | sort -u || true)
    if [ -n "$ids" ]; then
      AFFECTED_IDS="$AFFECTED_IDS $ids"
    fi
  fi
done

# Also check commit messages for requirement IDs
COMMIT_IDS=$(git log @{u}..HEAD --format="%B" 2>/dev/null | grep -oE '(UR|TC|BUC|PUC)-[0-9]{3}' | sort -u || true)
AFFECTED_IDS="$AFFECTED_IDS $COMMIT_IDS"

# Deduplicate
AFFECTED_IDS=$(echo "$AFFECTED_IDS" | tr ' ' '\n' | sort -u | grep -v '^$' || true)

if [ -z "$AFFECTED_IDS" ]; then
  echo "⚠ Volere check-fit-criteria: code changes with no traceable requirement IDs"
  echo "  DAL-$DAL requires traceability. Consider adding requirement references."
  # Warn but don't block — check-traceability handles this
  exit 0
fi

# Run tests
echo "🔍 Volere check-fit-criteria (DAL-$DAL): verifying affected requirements"
echo "  Affected: $AFFECTED_IDS"
echo ""

# Read verification commands from profile
VERIFICATION_CMDS=""
if [ -f "$PROFILE" ]; then
  # Extract verification_commands for current DAL level
  IN_DAL_SECTION=0
  IN_COMMANDS=0
  while IFS= read -r line; do
    if echo "$line" | grep -qE "^  $DAL:"; then
      IN_DAL_SECTION=1
      continue
    fi
    if [ "$IN_DAL_SECTION" -eq 1 ] && echo "$line" | grep -qE "^  [A-E]:"; then
      IN_DAL_SECTION=0
      IN_COMMANDS=0
      continue
    fi
    if [ "$IN_DAL_SECTION" -eq 1 ] && echo "$line" | grep -q "verification_commands:"; then
      IN_COMMANDS=1
      continue
    fi
    if [ "$IN_COMMANDS" -eq 1 ] && echo "$line" | grep -qE "^    [a-z]"; then
      IN_COMMANDS=0
      continue
    fi
    if [ "$IN_COMMANDS" -eq 1 ] && echo "$line" | grep -qE '^\s*- "'; then
      cmd=$(echo "$line" | sed 's/.*- "\(.*\)"/\1/')
      VERIFICATION_CMDS="$VERIFICATION_CMDS|$cmd"
    fi
  done < "$PROFILE"
fi

# Run verification commands
if [ -n "$VERIFICATION_CMDS" ]; then
  # Use configured commands
  FAIL=0
  echo "$VERIFICATION_CMDS" | tr '|' '\n' | grep -v '^$' | while read -r cmd; do
    echo "  Running: $cmd"
    if ! eval "$cmd" > /dev/null 2>&1; then
      echo ""
      echo "  ✗ Verification failed: $cmd"
      echo "  Push blocked (DAL-$DAL requires passing verification)."
      exit 1
    fi
    echo "  ✓ $cmd passed"
  done || FAIL=$?
  if [ "$FAIL" -ne 0 ]; then
    exit 1
  fi
else
  # Fallback: auto-detect test runner (original behavior)
  if [ -f "go.mod" ]; then
    echo "  Running: go test ./... -count=1"
    if ! go test ./... -count=1 > /dev/null 2>&1; then
      echo ""
      echo "  ✗ Tests failed. Push blocked (DAL-$DAL requires passing tests)."
      echo "  Run 'go test ./... -v' to see failures."
      exit 1
    fi
    echo "  ✓ Go tests pass"
  fi

  if [ -f "package.json" ]; then
    if grep -q '"test"' package.json 2>/dev/null; then
      echo "  Running: npm test"
      if ! npm test > /dev/null 2>&1; then
        echo ""
        echo "  ✗ Tests failed. Push blocked (DAL-$DAL requires passing tests)."
        echo "  Run 'npm test' to see failures."
        exit 1
      fi
      echo "  ✓ Node tests pass"
    fi
  fi
fi

echo ""
echo "  ✓ Fit criteria verification passed for DAL-$DAL"
exit 0
