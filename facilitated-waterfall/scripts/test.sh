#!/bin/sh
# Fixture tests for nav. Builds a throwaway repo in a temp dir and checks each
# query, in ctags mode (when Universal Ctags is installed) and in grep mode.
# Usage: sh test.sh   (exit status is the number of failed checks, capped at 1)
set -u
LC_ALL=C
export LC_ALL

HERE=$(cd "$(dirname "$0")" && pwd -P)
NAV=$HERE/nav
TMP=$(mktemp -d "${TMPDIR:-/tmp}/navtest.XXXXXX")
TMP=$(cd "$TMP" && pwd -P)
trap 'rm -rf "$TMP"' EXIT INT TERM
R=$TMP/repo
fails=0
pass=0

ok() { pass=$((pass + 1)); echo "PASS  $1"; }
no() { fails=$((fails + 1)); echo "FAIL  $1"; [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/      | /'; }
has() { printf '%s\n' "$2" | grep -q -- "$3" && ok "$1" || no "$1" "$2"; }
hasnt() { printf '%s\n' "$2" | grep -q -- "$3" && no "$1" "$2" || ok "$1"; }

mkfile() { mkdir -p "$(dirname "$1")"; cat >"$1"; }

build() {
	rm -rf "$R"
	mkdir -p "$R"
	git -C "$R" init -q
	mkfile "$R/src/auth/session.py" <<'EOF'
class Session:
    def refresh(self):
        return True


def helper_unique_fn():
    return EVENT
EOF
	mkfile "$R/src/consts.py" <<'EOF'
EVENT = "launch_event_name"
EOF
	mkfile "$R/src/util.sh" <<'EOF'
# Indexing follows ADR 0002; the old way was ADR 0001.
build_index() {
	echo index
}

start() {
	:
}
EOF
	mkfile "$R/src/cache.py" <<'EOF'
def refresh():
    return _conn


_conn = None
EOF
	mkfile "$R/tests/test_rig.py" <<'EOF'
def only_in_tests_helper():
    return 1


class Rig:
    def seq_cursor(self):
        return 0
EOF
	mkfile "$R/docs/tasks/005-classes.md" <<'EOF'
Bare `refresh` is ambiguous.
Hinted `refresh` (src/cache.py) is anchored.
Hint miss `_conn` (src/auth/session.py) stays unlinked.
Plain `start` stays unlinked.
Test-only `only_in_tests_helper` stays unlinked.
Qualified but test-only `Rig.seq_cursor` stays unlinked.
A directory is not a module: `src.helper_unique_fn` stays unlinked.
EOF
	mkfile "$R/docs/adr/0001-old.md" <<'EOF'
---
id: docs/adr/0001-old.md
title: "Old"
relates: []
---
Old rule for `Session.refresh`.
EOF
	mkfile "$R/docs/adr/0002-new.md" <<'EOF'
---
id: docs/adr/0002-new.md
title: "New"
supersedes: [docs/adr/0001-old.md]
relates: []
---
New rule for `Session.refresh` and `build_index`.
EOF
	mkfile "$R/docs/directions/001-a.md" <<'EOF'
---
id: docs/directions/001-a.md
title: "A"
intent: Direction A intent.
relates: []
---
Constrains `build_index`.
EOF
	mkfile "$R/docs/directions/002-b.md" <<'EOF'
---
id: docs/directions/002-b.md
title: "B"
intent: Direction B intent.
supersedes:
  - docs/directions/001-a.md
relates: []
---
EOF
	mkfile "$R/docs/epics/001-e.md" <<'EOF'
---
id: docs/epics/001-e.md
title: "E"
intent: Epic E intent.
relates: [docs/directions/002-b.md]
---
EOF
	mkfile "$R/docs/tasks/001-t.md" <<'EOF'
---
id: docs/tasks/001-t.md
title: "T"
intent: Task T intent.
relates: [docs/adr/0002-new.md, docs/epics/001-e.md]
---
Touches `Session.refresh`, `build_index` and `helper_unique_fn()` together.
Once named `removed_symbol_xyz`; emits `launch_event_name`.
EOF
	mkfile "$R/docs/tasks/002-noint.md" <<'EOF'
---
id: docs/tasks/002-noint.md
title: "No intent here"
relates:
  - docs/missing/404.md
---
EOF
	mkfile "$R/docs/plans/001-p.md" <<'EOF'
---
id: docs/plans/001-p.md
relates: [docs/tasks/001-t.md]
---
Step on `Session.refresh`.
EOF
	mkfile "$R/docs/plans/002-q.md" <<'EOF'
---
id: docs/plans/002-q.md
relates: [docs/tasks/001-t.md]
---
Next step on `Session.refresh`.
EOF
	mkfile "$R/docs/plans/LEDGER.md" <<'EOF'
- docs/plans/001-p.md — implemented 2026-10-05 — verification: 3/3 passed
EOF
	mkfile "$R/docs/probes/probe-a.md" <<'EOF'
---
id: probe-a
status: reconciled
---
Found `Session.refresh` slow.
EOF
	mkfile "$R/docs/probes/probe-b.md" <<'EOF'
---
id: probe-b
status: open
---
Still on `Session.refresh`.
EOF
	mkfile "$R/docs/knowledge/notes.md" <<'EOF'
Research on `Session.refresh`.
EOF
	mkfile "$R/docs/handbook/index.md" <<'EOF'
# Handbook
EOF
	mkfile "$R/docs/handbook/gotchas.md" <<'EOF'
# Gotchas

### Refresh races
Moment: two tabs call `Session.refresh` (src/auth/session.py) at once.
Reflex: retry. Instead: serialise. Again: `Session.refresh` (src/auth/session.py).
Because: not recorded. Stage: provisional. Source: `Session.refresh` (src/auth/session.py) · probe-b.

### Unrelated
Moment: `build_index` (src/util.sh) is slow.
Because: not recorded. Stage: provisional.
EOF
	mkfile "$R/docs/PRODUCT.md" <<'EOF'
# Product

| ID | Decision | Rationale | Supersedes | Date |
|----|----------|-----------|------------|------|
| <a id="D-001"></a>D-001 | One user. | Simple. | — | 2026-01-01 |
| <a id="D-002"></a>D-002 | One user, many devices. | Reach. | D-001 | 2026-02-01 |

- X-001 — No billing — never.
EOF
	mkfile "$R/docs/product/stories/001-s.md" <<'EOF'
---
id: docs/product/stories/001-s.md
relates:
  - docs/PRODUCT.md#D-002
---
Bounded by docs/PRODUCT.md#D-002 and docs/PRODUCT.md#X-001.
EOF
	mkfile "$R/docs/product/probes/probe-p.md" <<'EOF'
---
id: probe-p
status: resolved
---
Superseded docs/PRODUCT.md#D-001 with D-002.
EOF
	mkfile "$R/docs/research/lab.md" <<'EOF'
The lab's own D-002 and D-0021 are not product decisions.
EOF
	git -C "$R" add -A
	git -C "$R" -c user.name=t -c user.email=t@t commit -q -m fixture
}

run_mode() { # run_mode ctags|none
	mode=$1
	export NAV_CTAGS="$2"
	echo "== mode: $mode"
	build
	nav() { "$NAV" "$@" 2>&1; }

	# 1. Both directions.
	out=$(cd "$R" && nav def Session.refresh)
	has "$mode 1a def finds the method" "$out" 'src/auth/session.py:2'
	out=$(cd "$R" && nav docs Session.refresh)
	has "$mode 1b docs finds the ADR" "$out" 'on-match  docs/adr/0002-new.md'
	has "$mode 1c docs finds the Task" "$out" 'on-match  docs/tasks/001-t.md'

	# 2. Several mentions on one line.
	for s in Session.refresh build_index helper_unique_fn; do
		out=$(cd "$R" && nav docs "$s")
		has "$mode 2 one-line mention $s" "$out" 'docs/tasks/001-t.md  *L7'
	done

	# 3. Sealed docs are lookup-only; --sealed lists them.
	out=$(cd "$R" && nav docs Session.refresh)
	hasnt "$mode 3a ledgered plan not on-match" "$out" 'on-match  docs/plans/001-p.md'
	hasnt "$mode 3b reconciled probe not on-match" "$out" 'on-match  docs/probes/probe-a.md'
	hasnt "$mode 3c superseded ADR not on-match" "$out" 'on-match  docs/adr/0001-old.md'
	hasnt "$mode 3d research not on-match" "$out" 'on-match  docs/knowledge/notes.md'
	has "$mode 3e unledgered plan is live" "$out" 'on-match  docs/plans/002-q.md'
	has "$mode 3f open probe is live" "$out" 'on-match  docs/probes/probe-b.md'
	has "$mode 3g lookup count" "$out" 'lookup    4 links in 4 sealed'
	out=$(cd "$R" && nav docs Session.refresh --sealed)
	has "$mode 3h --sealed lists them" "$out" 'lookup    docs/adr/0001-old.md'

	# 4. A Direction named in a later Direction's supersedes stays live (F20).
	out=$(cd "$R" && nav docs build_index)
	has "$mode 4 superseded Direction stays live" "$out" 'on-match  docs/directions/001-a.md'

	# 5. A live ADR points at what it superseded (F21).
	out=$(cd "$R" && nav docs Session.refresh)
	has "$mode 5 supersedes pointer" "$out" 'supersedes docs/adr/0001-old.md (lookup)'

	# 6. Lazy regeneration.
	out=$(cd "$R" && nav docs build_index)
	hasnt "$mode 6a no change, no regeneration" "$out" 'regenerated'
	sleep 1
	echo "More on \`build_index\`." >>"$R/docs/directions/002-b.md"
	out=$(cd "$R" && nav docs build_index)
	has "$mode 6b edit regenerates" "$out" 'regenerated'
	has "$mode 6c edit is seen" "$out" 'on-match  docs/directions/002-b.md'
	printf 'See `build_index`.\n' >"$R/docs/tasks/003-new.md"
	out=$(cd "$R" && nav docs build_index)
	has "$mode 6d add regenerates and is seen" "$out" 'on-match  docs/tasks/003-new.md'
	git -C "$R" add docs/tasks/003-new.md
	git -C "$R" mv docs/tasks/003-new.md docs/tasks/004-moved.md
	out=$(cd "$R" && nav docs build_index)
	has "$mode 6e rename is seen" "$out" 'on-match  docs/tasks/004-moved.md'
	hasnt "$mode 6f old name gone" "$out" 'docs/tasks/003-new.md'
	git -C "$R" rm -q -f docs/tasks/004-moved.md >/dev/null
	out=$(cd "$R" && nav docs build_index)
	has "$mode 6g delete regenerates" "$out" 'regenerated'
	hasnt "$mode 6h deleted doc gone" "$out" 'docs/tasks/004-moved.md'

	# 7. Workspace from the queried path, never cwd; refuse and list otherwise.
	out=$(cd "$TMP" && nav file repo/src/auth/session.py)
	has "$mode 7a path resolves the workspace" "$out" "· $R ·"
	has "$mode 7b file lists its definitions" "$out" 'refresh'
	has "$mode 7c file finds its docs" "$out" 'on-match  docs/tasks/001-t.md'
	out=$(cd "$TMP" && nav def Session.refresh)
	st=$(cd "$TMP" && "$NAV" def Session.refresh >/dev/null 2>&1; echo $?)
	[ "$st" = 3 ] && ok "$mode 7d path-less outside a repo exits 3" || no "$mode 7d path-less outside a repo exits 3" "status $st"
	has "$mode 7e lists the candidate" "$out" "$R"
	out=$(cd "$TMP" && nav -C repo docs build_index)
	has "$mode 7f -C names the workspace" "$out" "· $R ·"

	# 8. Every query answers; the grep layer says so.
	for qa in "def build_index" "docs build_index" "module src" "file src/util.sh" "unresolved"; do
		# shellcheck disable=SC2086
		out=$(cd "$R" && nav $qa)
		if [ "$mode" = grep ]; then has "$mode 8 '$qa' answers via grep" "$out" 'grep fallback'
		else hasnt "$mode 8 '$qa' answers via ctags" "$out" 'grep fallback'; fi
	done
	out=$(cd "$R" && nav module src)
	has "$mode 8a module lists defs" "$out" 'defs      src/'
	has "$mode 8b module finds docs" "$out" 'on-match  docs/tasks/001-t.md'

	# 9. Unresolved: removed symbols listed, code literals not.
	out=$(cd "$R" && nav unresolved)
	has "$mode 9a removed symbol listed" "$out" 'removed_symbol_xyz'
	hasnt "$mode 9b code literal not listed" "$out" 'launch_event_name'
	hasnt "$mode 9c defined symbol not listed" "$out" '  build_index$'

	# 10. Intent trace.
	out=$(cd "$R" && nav trace docs/tasks/001-t.md)
	has "$mode 10a task intent" "$out" 'docs/tasks/001-t.md: Task T intent.'
	has "$mode 10b skips the ADR parent" "$out" 'docs/epics/001-e.md: Epic E intent.'
	has "$mode 10c reaches the Direction" "$out" 'docs/directions/002-b.md: Direction B intent.'
	out=$(cd "$R" && nav trace docs/tasks/002-noint.md)
	has "$mode 10d gap reported, title as stand-in" "$out" 'no intent line · (title) No intent here'
	has "$mode 10e broken link reported" "$out" 'broken link: docs/missing/404.md'

	# 11. Budget is reported, never enforced.
	out=$(cd "$R" && nav --budget 100 docs Session.refresh)
	st=$(cd "$R" && "$NAV" --budget 100 docs Session.refresh >/dev/null 2>&1; echo $?)
	has "$mode 11a over share says trim" "$out" 'over share: trim on-match'
	[ "$st" = 0 ] && ok "$mode 11b exit 0 over budget" || no "$mode 11b exit 0 over budget" "status $st"
	has "$mode 11c always tier" "$out" 'always    docs/handbook/index.md'
	out=$(cd "$R" && AGENT_CONTEXT_TOKENS= "$NAV" docs Session.refresh 2>&1)
	has "$mode 11d unset budget reports sizes" "$out" 'budget    unset'
	# Sessions pipe nav through `| head`: the summary must come before docs and defs.
	out=$(cd "$R" && nav --budget 100 file src/auth/session.py | sed -n 2p)
	has "$mode 11e budget is the line after the header" "$out" '^budget    '
	out=$(cd "$R" && nav --budget 100 file src/auth/session.py | tail -n 1)
	has "$mode 11f file defs come last" "$out" '^def       '

	# 22. Handbook entries in the answer are counted once each, against 1/4 of the share.
	out=$(cd "$R" && AGENT_CONTEXT_TOKENS= "$NAV" docs Session.refresh 2>&1)
	has "$mode 22a one entry, three lines" "$out" '^handbook  1 entries matched in 1 files.*no size trigger'
	out=$(cd "$R" && nav --budget 100 docs Session.refresh)
	has "$mode 22b over the handbook share" "$out" '^handbook  1 entries.* of 2 tok (1/4 of share) · over: cut test due at close'
	out=$(cd "$R" && nav --budget 1000000 --role top-down file src/auth/session.py)
	has "$mode 22c within, top-down share" "$out" '^handbook  1 entries.* of 50000 tok (1/4 of share) · within'
	out=$(cd "$R" && nav --budget 1000000 module src)
	has "$mode 22d module counts both entries" "$out" '^handbook  2 entries matched in 1 files'
	out=$(cd "$R" && nav --budget 1000000 file src/consts.py)
	hasnt "$mode 22e no handbook link, no line" "$out" '^handbook'

	# 14-21. Links only on evidence (Plan 003).
	out=$(cd "$R" && nav docs refresh --unlinked)
	has "$mode 14a bare ambiguous name listed as unlinked" "$out" 'docs/tasks/005-classes.md:1  refresh  (ambiguous)'
	has "$mode 14b unlinked count line" "$out" '^unlinked  [0-9]* mentions of refresh'
	out=$(cd "$R" && nav file src/cache.py)
	has "$mode 15 hint anchors to the hinted file" "$out" 'docs/tasks/005-classes.md  *L2  *(1) anchored'
	out=$(cd "$R" && nav file src/auth/session.py)
	hasnt "$mode 16a hint miss links nowhere" "$out" 'docs/tasks/005-classes.md'
	out=$(cd "$R" && nav docs _conn --unlinked)
	has "$mode 16b hint miss is a reason" "$out" '(hint-miss)'
	out=$(cd "$R" && nav docs start --unlinked)
	has "$mode 17a plain word not linked" "$out" 'on-match  none'
	has "$mode 17b plain word is a reason" "$out" '(plain-word)'
	out=$(cd "$R" && nav docs only_in_tests_helper --unlinked)
	has "$mode 18a test-only not linked" "$out" 'on-match  none'
	has "$mode 18b test-only is a reason" "$out" '(test-only)'
	out=$(cd "$R" && nav file tests/test_rig.py)
	hasnt "$mode 18c qualified name never anchors in a test file" "$out" 'docs/tasks/005-classes.md'
	out=$(cd "$R" && nav docs helper_unique_fn --unlinked)
	has "$mode 18d a directory is not a module qualifier" "$out" 'src.helper_unique_fn  (ambiguous)'
	out=$(cd "$R" && nav file src/util.sh)
	has "$mode 19a code citation links the ADR" "$out" 'on-match  docs/adr/0002-new.md.*cited'
	has "$mode 19b cited superseded ADR is lookup" "$out" 'lookup    1 links in 1 sealed'
	for pair in "build_index src/util.sh" "Session.refresh src/auth/session.py" "helper_unique_fn src/auth/session.py"; do
		set -- $pair
		a=$(cd "$R" && nav docs "$1" | awk '$1 == "on-match" && $2 != "none" { print $2 }' | sort)
		b=$(cd "$R" && nav file "$2" | awk '$1 == "on-match" && $2 != "none" { print $2 }' | sort)
		missing=$(printf '%s\n' "$a" | while read -r d; do [ -z "$d" ] || printf '%s\n' "$b" | grep -qxF "$d" || echo "$d"; done)
		[ -z "$missing" ] && ok "$mode 20 symmetry docs $1 within file $2" || no "$mode 20 symmetry docs $1 within file $2" "$missing"
	done
	out=$(cd "$R" && nav docs Session.refresh)
	hasnt "$mode 21 dotted query stays in its class" "$out" 'docs/tasks/005-classes.md'

	# 23. A file with no definitions and no linked docs still answers (F44).
	out=$(cd "$R" && nav file docs/directions/001-a.md 2>&1) && ok "$mode 23a file with nothing linked exits 0" || no "$mode 23a file with nothing linked exits 0" "$out"
	has "$mode 23b and prints its budget line" "$out" '^budget    '

	# 24. A product decision id: its row, what supersedes it, and the docs that
	# cite it by anchor; a bare id is not a link (Task 020, F46).
	out=$(cd "$R" && nav docs D-002)
	has "$mode 24a row and status" "$out" '^product   D-002  docs/PRODUCT.md:6  current'
	has "$mode 24b anchor citation links" "$out" 'on-match  docs/product/stories/001-s.md  *L4,6  *(2) product'
	hasnt "$mode 24c bare id in research is not a link" "$out" 'lab.md'
	out=$(cd "$R" && nav docs D-001)
	has "$mode 24d superseded row names its successor" "$out" '^product   D-001  docs/PRODUCT.md:5  superseded by D-002'
	has "$mode 24e resolved product probe is lookup" "$out" 'lookup    1 links in 1 sealed'
	out=$(cd "$R" && nav docs X-001)
	has "$mode 24f exclusion row" "$out" '^product   X-001  docs/PRODUCT.md:8  current'
	out=$(cd "$R" && nav docs D-009)
	has "$mode 24g unknown id says so" "$out" '^product   D-009  not in docs/PRODUCT.md'

	# State stays out of the work tree.
	st=$(git -C "$R" status --porcelain --ignored | grep -v -e ' docs/directions/002-b.md$' || :)
	[ -z "$st" ] && ok "$mode 12 nav adds nothing to the work tree" || no "$mode 12 nav adds nothing to the work tree" "$st"
	[ -f "$R/.git/nav/tags" ] && ok "$mode 13 tags under git-common-dir" || no "$mode 13 tags under git-common-dir"
}

if "$NAV" --help >/dev/null 2>&1 && NAV_CTAGS= sh -c 'for d in $(echo "$PATH" | tr : " ") /opt/homebrew/bin /usr/local/bin; do "$d/ctags" --version 2>/dev/null | grep -q "Universal Ctags" && exit 0; done; exit 1'; then
	run_mode ctags ""
else
	echo "== mode: ctags skipped (Universal Ctags not found)"
fi
run_mode grep none

echo "$pass passed, $fails failed"
[ "$fails" -eq 0 ]
