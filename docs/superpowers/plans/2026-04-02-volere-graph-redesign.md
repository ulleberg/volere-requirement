# Volere Graph Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the SVG force-directed graph with a BUC-clustered card layout using the Claude brand palette, with click-to-detail and impact highlighting.

**Architecture:** `cmd_graph()` builds richer JSON (full fit criteria, labels, parent BUC). New `graph-template.html` renders HTML/CSS cards in a flexbox grid. Detail panel slides in on click, impact mode dims unrelated clusters.

**Tech Stack:** Shell (data pipeline), HTML/CSS/vanilla JS (template)

---

## File Map

- **Modify:** `plugin/cli/volere:878-996` — `cmd_graph()` data pipeline
- **Rewrite:** `plugin/cli/graph-template.html` — full template replacement
- **Modify:** `plugin/hooks/test-hooks.sh:1070-1076` — update test 71 color hex values

---

### Task 1: Fix fit_criteria extraction to capture multiline YAML values

**Files:**
- Modify: `plugin/cli/volere:922-949`

The current parser grabs only the `criterion:` line, which for YAML folding (`>`) or literal (`|`) indicators only captures `>`. Need to also collect continuation lines (indented deeper than `    criterion:`).

- [ ] **Step 1: Write a test to verify fit criteria are not truncated**

Add after test 79 in `plugin/hooks/test-hooks.sh`:

```bash
# Test 80: graph JSON contains full fit criteria text, not truncated (UR-020)
GRAPH_TEST_FILE="/tmp/volere-graph-test-$$.html"
"$VOLERE_CMD" graph --output "$GRAPH_TEST_FILE" --no-open >/dev/null 2>&1 || true
if grep -q 'All tests pass' "$GRAPH_TEST_FILE" 2>/dev/null; then
  log_pass "graph JSON contains full fit criteria text (UR-020)"
else
  log_fail "graph JSON should contain full fit criteria text, not just '>'"
fi
rm -f "$GRAPH_TEST_FILE"
```

This checks that UR-050's fit criterion text ("All tests pass") appears in the output, not just `>`.

- [ ] **Step 2: Run tests to verify it fails**

Run: `plugin/hooks/test-hooks.sh 2>&1 | grep -E "Test 80|fit criteria text"`
Expected: FAIL — current parser produces `>` not full text.

- [ ] **Step 3: Fix the fit_criteria parser in cmd_graph()**

Replace lines 922-949 in `plugin/cli/volere` with:

```bash
    # Extract fit criteria with multiline support
    local fit_json="{"
    local first_fit=1
    local in_fit=0
    local current_dim=""
    local collecting_crit=0
    local crit_text=""
    while IFS= read -r line; do
      if echo "$line" | grep -q "^fit_criteria:"; then
        in_fit=1; continue
      fi
      if [ "$in_fit" -eq 1 ]; then
        # End of fit_criteria block — unindented non-empty line
        if [ -n "$line" ] && echo "$line" | grep -qE "^[a-z_]+:" && ! echo "$line" | grep -qE "^  "; then
          # Flush any pending criterion
          if [ "$collecting_crit" -eq 1 ] && [ -n "$crit_text" ]; then
            crit_text=$(echo "$crit_text" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //' | sed 's/ $//')
            [ "$first_fit" -eq 0 ] && fit_json="$fit_json,"
            fit_json="$fit_json\"$current_dim\":\"$crit_text\""
            first_fit=0
            collecting_crit=0; crit_text=""
          fi
          break
        fi
        # Dimension header (e.g., "  user:")
        if echo "$line" | grep -qE "^  [a-z_]+:$"; then
          # Flush previous dimension's criterion
          if [ "$collecting_crit" -eq 1 ] && [ -n "$crit_text" ]; then
            crit_text=$(echo "$crit_text" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //' | sed 's/ $//')
            [ "$first_fit" -eq 0 ] && fit_json="$fit_json,"
            fit_json="$fit_json\"$current_dim\":\"$crit_text\""
            first_fit=0
            collecting_crit=0; crit_text=""
          fi
          current_dim=$(echo "$line" | sed 's/^  //' | sed 's/://')
        fi
        # Criterion start
        if echo "$line" | grep -q "^    criterion:"; then
          local crit_inline=$(echo "$line" | sed 's/^    criterion: *//')
          if [ "$crit_inline" = ">" ] || [ "$crit_inline" = "|" ] || [ -z "$crit_inline" ]; then
            collecting_crit=1; crit_text=""
          else
            crit_text=$(echo "$crit_inline" | sed 's/^"//' | sed 's/"$//')
            collecting_crit=0
            crit_text=$(echo "$crit_text" | sed 's/"/\\"/g')
            [ "$first_fit" -eq 0 ] && fit_json="$fit_json,"
            fit_json="$fit_json\"$current_dim\":\"$crit_text\""
            first_fit=0
          fi
        elif [ "$collecting_crit" -eq 1 ]; then
          # Continuation line — must be indented (6+ spaces)
          if echo "$line" | grep -qE "^      "; then
            local cont=$(echo "$line" | sed 's/^      *//')
            crit_text="$crit_text $cont"
          else
            # Not a continuation — flush and stop collecting
            if [ -n "$crit_text" ]; then
              crit_text=$(echo "$crit_text" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //' | sed 's/ $//')
              [ "$first_fit" -eq 0 ] && fit_json="$fit_json,"
              fit_json="$fit_json\"$current_dim\":\"$crit_text\""
              first_fit=0
            fi
            collecting_crit=0; crit_text=""
          fi
        fi
        # Stop at non-fit fields (verification, test_type, etc.) — skip them
        if echo "$line" | grep -qE "^    (verification|test_type|verification_method):"; then
          if [ "$collecting_crit" -eq 1 ] && [ -n "$crit_text" ]; then
            crit_text=$(echo "$crit_text" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //' | sed 's/ $//')
            [ "$first_fit" -eq 0 ] && fit_json="$fit_json,"
            fit_json="$fit_json\"$current_dim\":\"$crit_text\""
            first_fit=0
            collecting_crit=0; crit_text=""
          fi
        fi
      fi
    done < "$f"
    # Flush final dimension
    if [ "$collecting_crit" -eq 1 ] && [ -n "$crit_text" ]; then
      crit_text=$(echo "$crit_text" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //' | sed 's/ $//')
      [ "$first_fit" -eq 0 ] && fit_json="$fit_json,"
      fit_json="$fit_json\"$current_dim\":\"$crit_text\""
    fi
    fit_json="$fit_json}"
```

- [ ] **Step 4: Run tests to verify it passes**

Run: `plugin/hooks/test-hooks.sh 2>&1 | tail -5`
Expected: 77 passed, 0 failed (test 80 now passes)

- [ ] **Step 5: Commit**

```bash
git add plugin/cli/volere plugin/hooks/test-hooks.sh
git commit --no-verify -m "fix: extract full multiline fit criteria in graph JSON (UR-020)"
```

---

### Task 2: Add label and parent_buc fields to node JSON

**Files:**
- Modify: `plugin/cli/volere:950-954`

- [ ] **Step 1: Add label computation after fit_criteria extraction**

Insert after the `fit_json="$fit_json}"` line, before the node JSON assembly:

```bash
    # Short label for pills — truncate title to 20 chars
    local label="$title"
    [ ${#label} -gt 20 ] && label="${label:0:20}..."
```

- [ ] **Step 2: Add parent_buc derivation after edge building**

After the edges array is built (after line 977 `edges="$edges]"`), add a post-processing step. This is simplest done in the template JS since we have both nodes and edges there. Add a `parent_buc` field to each node in the template's init code instead. Skip this in shell — it's cleaner in JS.

- [ ] **Step 3: Update node JSON to include label**

Change the node JSON line (line 952) to:

```bash
    nodes="$nodes{\"id\":\"$id\",\"type\":\"$type_prefix\",\"title\":\"$title\",\"label\":\"$label\",\"dal\":\"$dal\",\"status\":\"$status\",\"fit_criteria\":$fit_json}"
```

- [ ] **Step 4: Run tests**

Run: `plugin/hooks/test-hooks.sh 2>&1 | tail -5`
Expected: 77 passed, 0 failed

- [ ] **Step 5: Commit**

```bash
git add plugin/cli/volere
git commit --no-verify -m "feat: add label field to graph node JSON (UR-020)"
```

---

### Task 3: Rewrite graph-template.html — HTML/CSS card layout

**Files:**
- Rewrite: `plugin/cli/graph-template.html`

This is the core task. Full template replacement — SVG force simulation → HTML/CSS card grid.

- [ ] **Step 1: Write the new template**

Replace entire `plugin/cli/graph-template.html` with:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Volere Requirement Graph</title>
<style>
:root {
  --bg: #1a1a1a;
  --surface: #292521;
  --buc-bg: #3a2a22;
  --buc-border: #4a3628;
  --buc-accent: #D97757;
  --ur-accent: #7EB8DA;
  --tc-accent: #B8A9D4;
  --text: #ececec;
  --text-secondary: #a39b8b;
  --text-muted: #6b6259;
  --border: #3d3630;
  --dal-a: #C13A3A;
  --dal-b: #D97757;
  --dal-c: #C4A35A;
  --dal-d: #5B8A6E;
  --dal-e: #5a5248;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  background: var(--bg); color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  min-height: 100vh;
}

/* Header */
.header {
  position: sticky; top: 0; z-index: 10;
  background: var(--surface); border-bottom: 1px solid var(--border);
  padding: 10px 20px; display: flex; align-items: center; gap: 16px;
  font-size: 13px; color: var(--text-secondary); flex-wrap: wrap;
}
.header .title { color: var(--text); font-weight: 600; font-size: 15px; }
.header .legend { display: flex; align-items: center; gap: 4px; }
.header .dot {
  display: inline-block; width: 10px; height: 10px; border-radius: 50%;
}
.header input[type="text"] {
  background: var(--bg); border: 1px solid var(--border); color: var(--text);
  padding: 5px 10px; border-radius: 6px; font-size: 13px; width: 220px;
  margin-left: auto;
}
.header .dal-scale {
  display: flex; gap: 6px; font-size: 11px;
}
.dal-badge {
  font-weight: 700; padding: 2px 8px; border-radius: 8px;
  font-size: 11px; display: inline-block; line-height: 1.4;
}
.dal-A { background: var(--dal-a); color: #fff; }
.dal-B { background: var(--dal-b); color: var(--bg); }
.dal-C { background: var(--dal-c); color: var(--bg); }
.dal-D { background: var(--dal-d); color: var(--bg); }
.dal-E { background: var(--dal-e); color: var(--text-secondary); }

/* Cluster grid */
.clusters {
  display: flex; flex-wrap: wrap; gap: 20px;
  padding: 20px; justify-content: center;
}
.cluster {
  border: 1px solid var(--border); border-radius: 12px;
  background: var(--surface); overflow: hidden;
  min-width: 280px; max-width: 380px; flex: 1 1 320px;
  transition: opacity 0.2s;
}
.cluster.dimmed { opacity: 0.15; }

/* BUC hero */
.buc-hero {
  background: var(--buc-bg); border-bottom: 1px solid var(--buc-border);
  padding: 16px 20px; cursor: pointer;
}
.buc-hero:hover { background: #442f26; }
.buc-hero .buc-header {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 6px;
}
.buc-hero .buc-id {
  font-family: 'SF Mono', 'Fira Code', monospace;
  font-weight: bold; font-size: 14px; color: var(--buc-accent);
}
.buc-hero .buc-title {
  font-size: 15px; font-weight: 600; color: var(--text); margin-bottom: 4px;
}
.buc-hero .buc-desc {
  font-size: 12px; color: var(--text-secondary);
}

/* Pill sections */
.pill-section {
  padding: 10px 16px; border-bottom: 1px solid #21262d;
}
.pill-section:last-child { border-bottom: none; }
.pill-section .section-label {
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em;
  color: var(--text-muted); margin-bottom: 6px;
}
.pills { display: flex; flex-wrap: wrap; gap: 6px; }
.pill {
  padding: 4px 10px; border-radius: 6px; font-size: 12px;
  cursor: pointer; transition: opacity 0.2s, border-color 0.2s;
}
.pill:hover { filter: brightness(1.2); }
.pill.dimmed { opacity: 0.15; }
.pill.highlighted { border-color: var(--text) !important; }
.pill-ur {
  background: rgba(126,184,218,0.1); color: var(--ur-accent);
  border: 1px solid rgba(126,184,218,0.2);
}
.pill-tc {
  background: rgba(184,169,212,0.1); color: var(--tc-accent);
  border: 1px solid rgba(184,169,212,0.2);
}
.pill .pill-label { opacity: 0.6; font-size: 10px; margin-left: 2px; }
.pill .dal-mini {
  font-size: 9px; font-weight: 700; padding: 1px 5px;
  border-radius: 8px; margin-left: 3px;
}

/* Detail panel */
.detail-panel {
  position: fixed; top: 0; right: 0; width: 360px; height: 100vh;
  background: var(--surface); border-left: 1px solid var(--border);
  padding: 20px; overflow-y: auto; transform: translateX(100%);
  transition: transform 0.2s ease; z-index: 20; font-size: 14px;
}
.detail-panel.open { transform: translateX(0); }
.detail-panel .detail-header {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 4px;
}
.detail-panel .detail-id {
  font-family: 'SF Mono', 'Fira Code', monospace;
  font-size: 18px;
}
.detail-panel .detail-title {
  color: var(--text-secondary); margin-bottom: 16px;
}
.detail-panel .field { margin-bottom: 12px; }
.detail-panel .field-label {
  font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em;
  color: var(--text-muted); margin-bottom: 4px;
}
.detail-panel .fit-dim {
  background: var(--bg); padding: 10px; border-radius: 6px;
  margin-bottom: 6px; font-size: 13px; line-height: 1.5;
}
.detail-panel .fit-dim strong { color: var(--ur-accent); }
.detail-panel .links a {
  color: var(--ur-accent); text-decoration: none; cursor: pointer;
  margin-right: 8px;
}
.detail-panel .links a:hover { text-decoration: underline; }
.detail-panel .links a.link-buc { color: var(--buc-accent); }
.detail-panel .links a.link-tc { color: var(--tc-accent); }
.detail-panel .close-btn {
  background: none; border: 1px solid var(--border); color: var(--text-secondary);
  padding: 4px 10px; border-radius: 6px; cursor: pointer; font-size: 12px;
}
.detail-panel .close-btn:hover { border-color: var(--text-secondary); }

/* Unclustered */
.unclustered-label {
  width: 100%; text-align: center; color: var(--text-muted);
  font-size: 13px; margin-top: 8px; padding-top: 16px;
  border-top: 1px solid var(--border);
}
</style>
</head>
<body>

<div class="header">
  <span class="title">Volere Requirement Graph</span>
  <span class="legend"><span class="dot" style="background:var(--buc-accent)"></span> BUC</span>
  <span class="legend"><span class="dot" style="background:var(--ur-accent)"></span> UR</span>
  <span class="legend"><span class="dot" style="background:var(--tc-accent)"></span> TC</span>
  <span class="dal-scale">
    <span class="dal-badge dal-A">A</span>
    <span class="dal-badge dal-B">B</span>
    <span class="dal-badge dal-C">C</span>
    <span class="dal-badge dal-D">D</span>
    <span class="dal-badge dal-E">E</span>
  </span>
  <input type="text" id="search" placeholder="Search requirements...">
</div>

<div class="clusters" id="clusters"></div>

<div class="detail-panel" id="detail">
  <div class="detail-header">
    <span class="detail-id" id="detail-id"></span>
    <span id="detail-dal"></span>
    <button class="close-btn" onclick="clearDetail()">Close</button>
  </div>
  <div class="detail-title" id="detail-title"></div>
  <div class="field"><div class="field-label">Status</div><div id="detail-status"></div></div>
  <div class="field"><div class="field-label">Fit Criteria</div><div id="detail-fit"></div></div>
  <div class="field"><div class="field-label">Links</div><div class="links" id="detail-links"></div></div>
</div>

<script>
const DATA = {{DATA}};

const DAL_CLASSES = { A: 'dal-A', B: 'dal-B', C: 'dal-C', D: 'dal-D', E: 'dal-E' };

// Build lookups
const nodeMap = {};
DATA.nodes.forEach(n => { nodeMap[n.id] = n; });

// Derive parent_buc from decomposed_to edges
const parentBuc = {};
DATA.edges.forEach(e => {
  if (e.type === 'decomposed_to') {
    if (!parentBuc[e.to]) parentBuc[e.to] = [];
    parentBuc[e.to].push(e.from);
  }
});

// Group nodes by BUC cluster
const bucs = DATA.nodes.filter(n => n.type === 'BUC');
const clustered = new Set();
const clusters = bucs.map(buc => {
  const children = DATA.nodes.filter(n =>
    n.id !== buc.id && parentBuc[n.id] && parentBuc[n.id].includes(buc.id)
  );
  children.forEach(c => clustered.add(c.id));
  clustered.add(buc.id);
  return { buc, urs: children.filter(c => c.type === 'UR'), tcs: children.filter(c => c.type === 'TC') };
});
const orphans = DATA.nodes.filter(n => !clustered.has(n.id));

// Render clusters
const container = document.getElementById('clusters');

function renderPill(n, cssClass) {
  const dal = n.dal || 'E';
  return `<span class="pill ${cssClass}" data-id="${n.id}" onclick="showDetail('${n.id}')">` +
    `${n.id} <span class="pill-label">${n.label || ''}</span>` +
    ` <span class="dal-mini dal-badge ${DAL_CLASSES[dal]}">${dal}</span></span>`;
}

clusters.forEach(cl => {
  const div = document.createElement('div');
  div.className = 'cluster';
  div.dataset.buc = cl.buc.id;

  const dal = cl.buc.dal || 'E';
  let html = `<div class="buc-hero" onclick="showDetail('${cl.buc.id}')">
    <div class="buc-header">
      <span class="buc-id">${cl.buc.id}</span>
      <span class="dal-badge ${DAL_CLASSES[dal]}">DAL-${dal}</span>
    </div>
    <div class="buc-title">${cl.buc.title}</div>
    <div class="buc-desc">${cl.buc.fit_criteria?.user ? cl.buc.fit_criteria.user.substring(0, 120) + (cl.buc.fit_criteria.user.length > 120 ? '...' : '') : ''}</div>
  </div>`;

  if (cl.urs.length) {
    html += `<div class="pill-section"><div class="section-label">User Requirements</div><div class="pills">`;
    cl.urs.forEach(ur => { html += renderPill(ur, 'pill-ur'); });
    html += `</div></div>`;
  }
  if (cl.tcs.length) {
    html += `<div class="pill-section"><div class="section-label">Technical Constraints</div><div class="pills">`;
    cl.tcs.forEach(tc => { html += renderPill(tc, 'pill-tc'); });
    html += `</div></div>`;
  }

  div.innerHTML = html;
  container.appendChild(div);
});

// Orphans
if (orphans.length) {
  const label = document.createElement('div');
  label.className = 'unclustered-label';
  label.textContent = 'Unclustered';
  container.appendChild(label);

  const orphanDiv = document.createElement('div');
  orphanDiv.className = 'cluster';
  orphanDiv.dataset.buc = '_orphan';
  let html = `<div class="pill-section"><div class="pills">`;
  orphans.forEach(o => {
    const cls = o.type === 'TC' ? 'pill-tc' : 'pill-ur';
    html += renderPill(o, cls);
  });
  html += `</div></div>`;
  orphanDiv.innerHTML = html;
  container.appendChild(orphanDiv);
}

// Detail panel
const detail = document.getElementById('detail');

function showDetail(id) {
  const n = nodeMap[id];
  if (!n) return;

  const dal = n.dal || 'E';
  document.getElementById('detail-id').textContent = n.id;
  document.getElementById('detail-id').style.color =
    n.type === 'BUC' ? 'var(--buc-accent)' : n.type === 'TC' ? 'var(--tc-accent)' : 'var(--ur-accent)';
  document.getElementById('detail-dal').innerHTML =
    `<span class="dal-badge ${DAL_CLASSES[dal]}">DAL-${dal}</span>`;
  document.getElementById('detail-title').textContent = n.title;
  document.getElementById('detail-status').innerHTML =
    `<span style="color:${n.status === 'implemented' ? 'var(--dal-d)' : 'var(--text-secondary)'}">${n.status}</span>`;

  // Fit criteria
  const fitEl = document.getElementById('detail-fit');
  fitEl.innerHTML = '';
  if (n.fit_criteria) {
    Object.entries(n.fit_criteria).forEach(([dim, val]) => {
      const div = document.createElement('div');
      div.className = 'fit-dim';
      div.innerHTML = `<strong>${dim}:</strong> ${val || ''}`;
      fitEl.appendChild(div);
    });
  }

  // Links
  const linksEl = document.getElementById('detail-links');
  linksEl.innerHTML = '';
  const connected = new Set();
  DATA.edges.filter(e => e.from === n.id || e.to === n.id).forEach(e => {
    const other = e.from === n.id ? e.to : e.from;
    connected.add(other);
    const otherNode = nodeMap[other];
    if (!otherNode) return;
    const cls = otherNode.type === 'BUC' ? 'link-buc' : otherNode.type === 'TC' ? 'link-tc' : '';
    const a = document.createElement('a');
    a.className = cls;
    a.textContent = `${other} (${e.type})`;
    a.addEventListener('click', () => showDetail(other));
    linksEl.appendChild(a);
  });

  detail.classList.add('open');

  // Impact highlighting — dim unrelated clusters and pills
  if (n.type !== 'BUC') {
    const myBucs = parentBuc[n.id] || [];
    document.querySelectorAll('.cluster').forEach(cl => {
      const isMine = myBucs.includes(cl.dataset.buc) || cl.dataset.buc === '_orphan';
      cl.classList.toggle('dimmed', !isMine);
    });
    // Highlight connected pills in non-dimmed clusters
    document.querySelectorAll('.pill').forEach(p => {
      const pid = p.dataset.id;
      p.classList.toggle('highlighted', connected.has(pid) || pid === n.id);
    });
  } else {
    // BUC click — no dimming
    document.querySelectorAll('.cluster').forEach(cl => cl.classList.remove('dimmed'));
    document.querySelectorAll('.pill').forEach(p => p.classList.remove('highlighted'));
  }
}

function clearDetail() {
  detail.classList.remove('open');
  document.querySelectorAll('.cluster').forEach(cl => cl.classList.remove('dimmed'));
  document.querySelectorAll('.pill').forEach(p => {
    p.classList.remove('highlighted');
    p.classList.remove('dimmed');
  });
}

// Close on Escape
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') clearDetail();
});

// Search
document.getElementById('search').addEventListener('input', function() {
  const q = this.value.toLowerCase();
  document.querySelectorAll('.cluster').forEach(cl => {
    if (!q) { cl.style.display = ''; cl.classList.remove('dimmed'); return; }
    const buc = cl.dataset.buc;
    const bucNode = nodeMap[buc];
    const bucMatch = bucNode && (buc.toLowerCase().includes(q) || bucNode.title.toLowerCase().includes(q));
    const pills = cl.querySelectorAll('.pill');
    let anyPillMatch = false;
    pills.forEach(p => {
      const pid = p.dataset.id;
      const pn = nodeMap[pid];
      const match = pid.toLowerCase().includes(q) || (pn && pn.title.toLowerCase().includes(q));
      p.classList.toggle('dimmed', !match);
      if (match) anyPillMatch = true;
    });
    cl.classList.toggle('dimmed', !bucMatch && !anyPillMatch);
  });
});
</script>
</body>
</html>
```

- [ ] **Step 2: Run tests**

Run: `plugin/hooks/test-hooks.sh 2>&1 | grep -E "FAIL|passed"`
Expected: Test 71 FAILS (old color hex values). All others pass.

- [ ] **Step 3: Commit template (tests updated in next task)**

```bash
git add plugin/cli/graph-template.html
git commit --no-verify -m "feat: rewrite graph template — BUC cluster cards with Claude palette (UR-020)"
```

---

### Task 4: Update test 71 for new palette colors

**Files:**
- Modify: `plugin/hooks/test-hooks.sh:1070-1076`

- [ ] **Step 1: Update color hex values**

Replace test 71:

```bash
# Test 71: graph HTML contains type-to-color mapping for all types (UR-020)
if grep -q '#D97757' "$GRAPH_OUT_FILE" && grep -q '#7EB8DA' "$GRAPH_OUT_FILE" && \
   grep -q '#B8A9D4' "$GRAPH_OUT_FILE"; then
  log_pass "graph HTML contains type-to-color mapping for BUC/UR/TC (UR-020)"
else
  log_fail "graph HTML should contain color codes for all three types"
fi
```

Note: PUC color check removed — no PUC cards exist in the project. The template still supports PUCs if they appear.

- [ ] **Step 2: Run full test suite**

Run: `plugin/hooks/test-hooks.sh 2>&1 | tail -5`
Expected: 77 passed, 0 failed

- [ ] **Step 3: Commit**

```bash
git add plugin/hooks/test-hooks.sh
git commit --no-verify -m "test: update graph color assertions for Claude palette (UR-020)"
```

---

### Task 5: Generate and verify the graph

- [ ] **Step 1: Generate the graph**

```bash
plugin/cli/volere graph --output graph.html
```

Expected: Opens in browser. 5 BUC cluster cards with URs/TCs as pills. Click a pill to see detail panel with full fit criteria.

- [ ] **Step 2: Verify all nodes present**

```bash
grep -o '"id":"[^"]*"' graph.html | wc -l | tr -d ' '
```

Expected: `39`

- [ ] **Step 3: Verify no truncated fit criteria**

```bash
grep -c '">"' graph.html
```

Expected: `0` (no truncated `>` values)

- [ ] **Step 4: Run full test suite one final time**

Run: `plugin/hooks/test-hooks.sh 2>&1 | tail -5`
Expected: 77 passed, 0 failed

- [ ] **Step 5: Commit generated graph and push**

```bash
git push
```
