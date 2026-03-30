#!/bin/bash
# Volere requirement card validator
# Usage: ./validate.sh <requirement.yaml> [schema.json]
#
# Validates a YAML requirement card against the Volere schema.
# Requires: node

set -euo pipefail

CARD="${1:?Usage: validate.sh <requirement.yaml> [schema.json]}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="${2:-$PLUGIN_DIR/schema/requirement.schema.json}"

if [ ! -f "$CARD" ]; then
  echo "Error: $CARD not found" >&2
  exit 1
fi

if [ ! -f "$SCHEMA" ]; then
  echo "Error: $SCHEMA not found" >&2
  exit 1
fi

node -e "
const fs = require('fs');

// Parse YAML using a state machine that handles the Volere card subset:
// nested objects, multiline strings (>), inline arrays, scalars
function parseVolereYaml(text) {
  const lines = text.split('\n');
  const root = {};
  const path = [{ obj: root, indent: -2, key: null }];
  let multiline = null; // { path: [...keys], indent: N }
  let multilineText = '';

  function setNested(obj, keys, value) {
    let cur = obj;
    for (let i = 0; i < keys.length - 1; i++) {
      if (!(keys[i] in cur)) cur[keys[i]] = {};
      cur = cur[keys[i]];
    }
    cur[keys[keys.length - 1]] = value;
  }

  function current() { return path[path.length - 1]; }

  function getObj(keys) {
    let cur = root;
    for (const k of keys) cur = cur[k];
    return cur;
  }

  function pathKeys() {
    return path.slice(1).map(p => p.key).filter(Boolean);
  }

  for (const line of lines) {
    const trimmed = line.trimEnd();
    if (trimmed === '' || trimmed.trim().startsWith('#')) {
      continue;
    }

    const indent = line.search(/\S/);

    // Handle multiline continuation
    if (multiline) {
      if (indent > multiline.indent) {
        multilineText += (multilineText ? ' ' : '') + trimmed.trim();
        continue;
      } else {
        setNested(root, multiline.path, multilineText.trim());
        multiline = null;
        multilineText = '';
      }
    }

    // Array item (- key: value)
    const arrayMatch = trimmed.match(/^(\s*)- (\w+):\s*(.*)/);
    if (arrayMatch) {
      // Pop to correct level
      while (path.length > 1 && indent <= current().indent) path.pop();
      const parentKeys = pathKeys();
      let arr = root;
      for (const k of parentKeys) arr = arr[k];
      if (!Array.isArray(arr)) {
        // Parent key needs to become array
        const parentKey = parentKeys[parentKeys.length - 1];
        let parent = root;
        for (let i = 0; i < parentKeys.length - 1; i++) parent = parent[parentKeys[i]];
        parent[parentKey] = [];
        arr = parent[parentKey];
      }
      const item = {};
      const [, , ak, av] = arrayMatch;
      item[ak.trim()] = parseValue(av.trim());
      arr.push(item);
      // Subsequent keys at deeper indent go into this item
      path.push({ obj: item, indent: indent, key: null, arrayItem: arr.length - 1 });
      continue;
    }

    // Key: value
    const kvMatch = trimmed.match(/^(\s*)([^:]+):\s*(.*)/);
    if (!kvMatch) continue;
    const [, , rawKey, rawVal] = kvMatch;
    const key = rawKey.trim();
    const val = rawVal.trim();

    // Pop stack to correct indent
    while (path.length > 1 && indent <= current().indent) path.pop();

    const parentKeys = pathKeys();

    if (val === '>' || val === '|') {
      multiline = { path: [...parentKeys, key], indent: indent };
      multilineText = '';
      path.push({ obj: null, indent: indent, key: key });
    } else if (val === '' && !val.startsWith('[')) {
      // Nested object
      let parent = root;
      for (const k of parentKeys) parent = parent[k];
      parent[key] = {};
      path.push({ obj: parent[key], indent: indent, key: key });
    } else {
      let parent = root;
      for (const k of parentKeys) parent = parent[k];
      // Handle array item continuation
      if (current().arrayItem !== undefined && indent > current().indent) {
        const arr = parent;
        // This is not right for our case, just set on current array item
      }
      parent[key] = parseValue(val);
    }
  }

  // Flush trailing multiline
  if (multiline) {
    setNested(root, multiline.path, multilineText.trim());
  }

  return root;
}

function parseValue(v) {
  if (v.startsWith('[') && v.endsWith(']')) {
    return v.slice(1, -1).split(',').map(s => s.trim().replace(/^['\"]|['\"]$/g, '')).filter(Boolean);
  }
  if (v.startsWith('\"') || v.startsWith(\"'\")) return v.replace(/^['\"]|['\"]$/g, '');
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (v === 'null') return null;
  if (!isNaN(v) && v !== '') return Number(v);
  return v;
}

try {
  const yamlText = fs.readFileSync(process.argv[1], 'utf8');
  const schemaText = fs.readFileSync(process.argv[2], 'utf8');
  const card = parseVolereYaml(yamlText);
  const schema = JSON.parse(schemaText);

  const errors = [];
  const warnings = [];

  // Check required fields
  for (const field of (schema.required || [])) {
    if (!(field in card) || card[field] === null || card[field] === undefined) {
      errors.push('Missing required field: ' + field);
    }
  }

  // Check id format
  if (card.id && !/^(UR|TC|SHR|SEC)-[0-9]{3}$/.test(card.id)) {
    errors.push('Invalid id format: ' + card.id + ' (expected UR-001, TC-001, etc.)');
  }

  // Check enums
  const enumChecks = [
    ['type', schema.properties?.type?.enum],
    ['dal', schema.properties?.dal?.enum],
    ['priority', schema.properties?.priority?.enum],
    ['status', schema.properties?.status?.enum],
  ];
  for (const [field, valid] of enumChecks) {
    if (card[field] && valid && !valid.includes(card[field])) {
      errors.push('Invalid ' + field + ': ' + card[field] + ' (valid: ' + valid.join(', ') + ')');
    }
  }

  // Check fit_criteria
  if (card.fit_criteria && typeof card.fit_criteria === 'object') {
    const dims = Object.keys(card.fit_criteria);
    if (dims.length === 0) {
      errors.push('fit_criteria must have at least one dimension');
    }
    for (const dim of dims) {
      const fc = card.fit_criteria[dim];
      if (typeof fc !== 'object') {
        errors.push('fit_criteria.' + dim + ' must be an object');
        continue;
      }
      if (!fc.criterion) errors.push('fit_criteria.' + dim + ' missing criterion');
      if (!fc.verification) errors.push('fit_criteria.' + dim + ' missing verification');
      const validV = ['test', 'analysis', 'review', 'demonstration'];
      if (fc.verification && !validV.includes(fc.verification)) {
        errors.push('fit_criteria.' + dim + '.verification invalid: ' + fc.verification);
      }

      // Warn on vague words
      const vague = ['should', 'appropriate', 'reasonable', 'adequate', 'sufficient', 'user-friendly'];
      if (fc.criterion) {
        for (const w of vague) {
          if (fc.criterion.toLowerCase().includes(w)) {
            warnings.push('fit_criteria.' + dim + ' contains vague word \"' + w + '\" — make it measurable');
          }
        }
      }
    }
  }

  // Check title length
  if (card.title && card.title.length > 100) {
    errors.push('Title exceeds 100 characters (' + card.title.length + ')');
  }

  // Check origin
  if (card.origin) {
    if (!card.origin.stakeholder) errors.push('origin.stakeholder is required');
    if (!card.origin.date) errors.push('origin.date is required');
  }

  // Check TC has serves
  if (card.id && card.id.startsWith('TC-') && (!card.serves || card.serves.length === 0)) {
    errors.push('Technical constraints (TC-) must have a serves field with at least one UR');
  }

  // Output
  if (errors.length > 0) {
    console.error('FAIL: ' + process.argv[1]);
    errors.forEach(e => console.error('  ✗ ' + e));
    warnings.forEach(w => console.error('  ⚠ ' + w));
    process.exit(1);
  } else {
    console.log('PASS: ' + process.argv[1]);
    console.log('  ✓ id: ' + card.id);
    console.log('  ✓ type: ' + card.type);
    console.log('  ✓ dal: ' + card.dal);
    console.log('  ✓ fit_criteria: ' + Object.keys(card.fit_criteria || {}).join(', '));
    console.log('  ✓ All required fields present');
    if (warnings.length > 0) {
      warnings.forEach(w => console.log('  ⚠ ' + w));
    }
  }
} catch (e) {
  console.error('Error: ' + e.message);
  process.exit(1);
}
" "$CARD" "$SCHEMA"
