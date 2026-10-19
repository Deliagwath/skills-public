#!/bin/sh
# frontmatter-graph — the what-next cold Phase 1 extraction (no `sp`).
#
# Emits one line per artifact:  kind | id | relates(comma-joined) | intent
# Frontmatter only: everything after the closing `---` is ignored, so no body
# line is ever emitted. `relates` is captured in both YAML forms: inline
# (`relates: [a, b]`) and block (`relates:` followed by `  - a` lines) — a
# one-line grep of `relates:` silently drops every block-list link.
#
# The join step (what-next Phase 2) splits the third field on commas, strips
# brackets and quotes; a `repo:id` entry is a cross-workspace link, not a
# same-repo child. A line with an empty id is a malformed file: skip it and say so.
#
# Usage: sh frontmatter-graph.sh [repo-root]     # default: .

root=${1:-.}
docs="$root/docs"

for d in product/directions product/epics product/stories directions epics tasks plans; do
  [ -d "$docs/$d" ] || continue
  for f in "$docs/$d"/*.md; do
    [ -f "$f" ] || continue
    awk -v kind="$d" '
      /^---[ ]*$/ { n++; if (n >= 2) fm = 1; next }
      fm         { next }
      /^id:[ ]/   { id = $0; sub(/^id:[ ]*/, "", id) }
      /^intent:/  { it = $0; sub(/^intent:[ ]*/, "", it) }
      /^relates:/ { inrel = 1; val = $0; sub(/^relates:[ ]*/, "", val); buf = val; next }
      inrel && /^[ ]- / { v = $0; sub(/^[ ]- */, "", v); buf = (buf == "" ? v : buf "," v); next }
      inrel && !/^[ ]/  { inrel = 0 }
      END { if (id != "") printf "%s|%s|%s|%s\n", kind, id, buf, it }
    ' "$f"
  done
done
