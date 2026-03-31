# Plugin Sync Workflow Design

## Goal

Auto-sync `volere-requirement/plugin/` → `ulleberg/volere` on every push to main that touches `plugin/**`. Tests gate the sync.

## Trigger

- `push` to `main` with path filter `plugin/**`
- `workflow_dispatch` for manual sync

## Steps

1. Checkout `volere-requirement`
2. Run `plugin/hooks/test-hooks.sh` — fail fast if tests break
3. Checkout `ulleberg/volere` (using PAT secret)
4. Sync files using the mapping below (rsync with delete for managed dirs)
5. If no changes: exit cleanly
6. Commit and push to `ulleberg/volere`

## File Mapping

| Source (`plugin/`) | Target (`volere/`) |
|---|---|
| `skills/` | `skills/` (excluding `using-volere/`) |
| `cli/` | `commands/cli/` |
| `schema/` | `schema/` |
| `catalogs/` | `catalogs/` |
| `templates/` | `templates/` |
| `validate.sh` | `validate.sh` |
| `hooks/coverage-gaps.sh` | `hooks/session-start/coverage-gaps.sh` |

## Protected files (never overwritten)

- `.claude-plugin/plugin.json`
- `hooks/hooks.json`, `hooks/run-hook.cmd`, `hooks/session-start/prompt.md`
- `skills/using-volere/`
- `README.md`, `.gitignore`, `LICENSE`

## Auth

Repository secret `VOLERE_PLUGIN_PAT` — GitHub PAT with `repo` scope for `ulleberg/volere`.

## Out of scope

- Version bumping (manual)
- Marketplace update (manual release step)
- Notifications
