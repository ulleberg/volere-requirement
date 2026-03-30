#!/bin/bash
# Volere hook installer
# Usage: ./install.sh [--strict-traceability] [--hooks-dir /path/to/.git/hooks]
#
# Installs check-secrets (pre-commit) and check-traceability (commit-msg)
# into the project's git hooks directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STRICT=0
HOOKS_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --strict-traceability) STRICT=1; shift ;;
    --hooks-dir) HOOKS_DIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Find git hooks directory
if [ -z "$HOOKS_DIR" ]; then
  GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || true)
  if [ -z "$GIT_DIR" ]; then
    echo "Error: not in a git repository" >&2
    exit 1
  fi
  HOOKS_DIR="$GIT_DIR/hooks"
fi

mkdir -p "$HOOKS_DIR"

# Install check-secrets as pre-commit
install_hook() {
  local source="$1"
  local target="$2"
  local hook_name="$3"

  if [ -f "$target" ]; then
    # Check if it's already our hook
    if grep -q "Volere" "$target" 2>/dev/null; then
      echo "  Updated: $hook_name (was already installed)"
      cp "$source" "$target"
    else
      # Chain with existing hook
      local existing="$target.existing"
      mv "$target" "$existing"
      cat > "$target" << CHAIN
#!/bin/bash
# Volere hook chain — runs existing hook first, then Volere hook
"$existing" "\$@"
existing_exit=\$?
if [ \$existing_exit -ne 0 ]; then exit \$existing_exit; fi
"$source" "\$@"
CHAIN
      chmod +x "$target"
      echo "  Chained: $hook_name (preserved existing hook at $existing)"
    fi
  else
    cp "$source" "$target"
    echo "  Installed: $hook_name"
  fi

  chmod +x "$target"
}

echo "Volere hook installer"
echo ""

# Install pre-commit (check-secrets)
install_hook "$SCRIPT_DIR/check-secrets.sh" "$HOOKS_DIR/pre-commit" "pre-commit (check-secrets)"

# Install commit-msg (check-traceability)
install_hook "$SCRIPT_DIR/check-traceability.sh" "$HOOKS_DIR/commit-msg" "commit-msg (check-traceability)"

# Configure strict mode
if [ "$STRICT" -eq 1 ]; then
  echo ""
  echo "  Strict traceability enabled."
  echo "  Add to your shell: export VOLERE_TRACEABILITY_STRICT=1"
  echo "  Or add to .volere/profile.yaml: traceability_strict: true"
fi

echo ""
echo "Done. Hooks installed in $HOOKS_DIR"
