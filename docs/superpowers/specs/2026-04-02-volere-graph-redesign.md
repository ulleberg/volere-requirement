# Volere Graph Redesign — BUC Cluster Cards

**Date:** 2026-04-02
**Requirement:** UR-020

## Problem

The current graph is a force-directed SVG hairball. 39 nodes overlap, fit criteria are truncated to `>`, node labels show only IDs, and there's no meaningful hierarchy. Users can't understand the requirement structure at a glance.

## Design

Replace the SVG force-directed graph with an HTML/CSS card-based layout using BUC clusters.

### Palette — Claude Brand

| Role | Color | Hex |
|------|-------|-----|
| Background | Deep charcoal | `#1a1a1a` |
| Surface | Warm dark | `#292521` |
| BUC header bg | Dark terracotta | `#3a2a22` |
| BUC accent | Terracotta | `#D97757` |
| UR accent | Soft blue | `#7EB8DA` |
| TC accent | Muted purple | `#B8A9D4` |
| Primary text | Light | `#ececec` |
| Secondary text | Warm grey | `#a39b8b` |
| Muted text | Dark grey | `#6b6259` |
| Borders | Warm border | `#3d3630` |
| DAL-A | Deep red | `#C13A3A` |
| DAL-B | Terracotta | `#D97757` |
| DAL-C | Warm yellow | `#C4A35A` |
| DAL-D | Sage green | `#5B8A6E` |
| DAL-E | Warm grey | `#5a5248` |

### Architecture

Single self-contained HTML file. CSS in `<style>`, JS in `<script>`, data as `const DATA = {{DATA}}`. No external dependencies. No SVG, no physics simulation.

### Data Pipeline

`cmd_graph()` in `plugin/cli/volere` reads YAML cards, builds JSON, injects into `plugin/cli/graph-template.html` via `{{DATA}}` placeholder.

**Node shape changes:**

```json
{
  "id": "UR-008",
  "type": "UR",
  "title": "Analyse change impact with volere impact",
  "label": "Impact",
  "dal": "B",
  "status": "implemented",
  "fit_criteria": { "user": "full criterion text..." },
  "parent_buc": "BUC-002"
}
```

- `label`: title truncated to 20 characters with ellipsis, for pill display
- `fit_criteria`: full criterion text per dimension (fix current `>` truncation)
- `parent_buc`: BUC with `decomposed_to` edge to this node. Primary assignment; secondary parents shown as badge.

Edges: unchanged (already filtered to valid IDs).

Orphans: URs/TCs not reachable from any BUC via `decomposed_to` go into an "Unclustered" group.

### Components

1. **Header bar** — project title, type legend (BUC/UR/TC dots), DAL color scale, search input
2. **Cluster grid** — flexbox wrap, one card per BUC:
   - BUC hero section: ID, DAL badge, title, one-line description
   - UR pills section: compact chips with ID + short label + DAL mini-badge
   - TC pills section: same format, purple accent
3. **Detail panel** — slide-in from right on click:
   - ID, title, DAL badge, status
   - Full fit criteria per dimension
   - Upstream/downstream links as clickable IDs
4. **Impact mode** — clicking UR/TC pill highlights its cluster + cross-cluster connections, dims rest to 15%

### Interactions

- **Default (overview):** all clusters visible, search filters by ID/title, type checkboxes toggle UR/TC pills
- **Click UR/TC pill:** detail panel opens, impact highlighting activates (own cluster + cross-cluster links at full opacity, rest dims)
- **Click BUC hero:** detail panel opens, no dimming
- **Click detail panel link:** navigates to that card
- **Click background / Escape:** return to overview
- **No drag, zoom, or physics.** Static layout.

### Files Changed

1. **`plugin/cli/volere`** — `cmd_graph()`: richer JSON (full fit_criteria, label, parent_buc)
2. **`plugin/cli/graph-template.html`** — full rewrite: HTML/CSS cards replacing SVG force simulation
3. **`plugin/hooks/test-hooks.sh`** — update test 71 hex values to new palette

### Test Impact

Tests 67-70, 79 remain valid (HTML output, node IDs, no external URLs/scripts). Test 71 needs updated color hex values for the new palette.
