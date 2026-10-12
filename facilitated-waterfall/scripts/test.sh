#!/bin/sh
# Fixture tests for nav. Builds a throwaway repo in a temp dir and checks each
# query, in ctags mode (when Universal Ctags is installed) and in grep mode.
# Usage: sh test.sh   (exit status is the number of failed checks, capped at 1)
set -u
LC_ALL=C
export LC_ALL
# A user's own call log (Direction 005) never sees fixture calls; log_tests sets
# its own.
unset SP_LOG SP_LOG_LEVEL SP_LOG_META

HERE=$(cd "$(dirname "$0")" && pwd -P)
SP=${SP_UNDER_TEST:-$HERE/sp}
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

usage() {
	cat <<USAGE
usage: util
USAGE
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
	# Field shapes (probe-2026-10-09-nav-in-field-use F5, F6, F9).
	mkfile "$R/tools/extra.py" <<'EOF'
def prose_sup_fn():
    return 1
EOF
	mkfile "$R/docs/adr/0010-before.md" <<'EOF'
---
id: docs/adr/0010-before.md
title: Before
---
Uses `prose_sup_fn`.
EOF
	mkfile "$R/docs/adr/0011-after.md" <<'EOF'
---
id: docs/adr/0011-after.md
title: After
supersedes:
  - docs/adr/0010-before.md (rules 4-6: the adoption-time mode)
---
Uses `prose_sup_fn`.
EOF
	mkfile "$R/docs/handbook/commands.md" <<'EOF'
# Commands

## Run the extra tool

- Run `prose_sup_fn` (tools/extra.py) once.
- Stage: provisional
EOF
	mkfile "$R/docs/directions/007-d.md" <<'EOF'
---
id: "007"
title: "D7"
intent: "D seven"
---
EOF
	mkfile "$R/docs/tasks/007-t.md" <<'EOF'
---
id: "007"
title: "T7"
relates: ["epic-007", "adr-0010"]
intent: "T seven"
---
EOF
	mkfile "$R/docs/epics/007-e.md" <<'EOF'
---
id: "epic-007"
title: "E7"
relates: ["007"]
intent: "E seven"
---
EOF
	mkfile "$R/docs/plans/007-p.md" <<'EOF'
---
id: "007"
title: "P7"
relates: ["adr-0010", "007"]
---
EOF
	# Kind-prefixed ids and both supersession edges (Task 022; ADRs 0005, 0006).
	mkfile "$R/tools/kp.py" <<'EOF'
def kp_fn():
    return 1


def own_fn():
    return 2


def legacy_fn():
    return 3
EOF
	mkfile "$R/docs/adr/0020-k.md" <<'EOF'
---
id: adr-0020
title: "K"
relates: []
---
Uses `kp_fn`.
EOF
	mkfile "$R/docs/adr/0021-k2.md" <<'EOF'
---
id: adr-0021
title: "K2"
supersedes: [adr-0020]
relates: []
---
Uses `kp_fn`.
EOF
	mkfile "$R/docs/adr/0022-own.md" <<'EOF'
---
id: adr-0022
title: "Own"
superseded-by:
  - adr-0023
---
Uses `own_fn`.
EOF
	mkfile "$R/docs/adr/0023-own2.md" <<'EOF'
---
id: adr-0023
title: "Own2"
---
Uses `own_fn`.
EOF
	mkfile "$R/docs/adr/0024-legacy.md" <<'EOF'
---
id: adr-0024
title: "Legacy"
status: superseded by adr-0025
---
Uses `legacy_fn`.
EOF
	mkfile "$R/docs/adr/0025-legacy2.md" <<'EOF'
---
id: adr-0025
title: "Legacy2"
---
Uses `legacy_fn`.
EOF
	mkfile "$R/docs/directions/030-d.md" <<'EOF'
---
id: direction-030
title: "D30"
created: 2026-10-09
intent: D thirty.
supersedes: [docs/directions/002-b.md]
relates:
  - probe-b
  - docs/directions/002-b.md
---
EOF
	mkfile "$R/docs/directions/031-d.md" <<'EOF'
---
id: direction-031
title: "D31"
intent: D thirty-one.
relates: ["007"]
---
EOF
	mkfile "$R/docs/epics/030-e.md" <<'EOF'
---
id: epic-030
title: "E30"
created: 2026-10-09
intent: E thirty.
relates: [direction-030]
---
EOF
	mkfile "$R/docs/tasks/030-t.md" <<'EOF'
---
id: task-030
title: "T30"
intent: T thirty.
relates: [adr-0021, probe-b, epic-030]
---
EOF
	mkfile "$R/docs/tasks/031-x.md" <<'EOF'
---
id: docs/tasks/031-x.md
title: "T31"
intent: T thirty-one.
relates: [epic-030]
---
EOF
	mkfile "$R/docs/plans/030-p.md" <<'EOF'
---
id: plan-030
title: "P30"
relates: [task-031]
---
EOF
	mkfile "$R/docs/tasks/032-a.md" <<'EOF'
---
title: "T32a"
---
EOF
	mkfile "$R/docs/tasks/032-b.md" <<'EOF'
---
title: "T32b"
---
EOF
	# Well-formedness (Task 023): one clean doc, and one of each problem.
	mkfile "$R/docs/tasks/040-clean.md" <<'EOF'
---
id: task-040
title: "Clean"
created: 2026-10-09
intent: Clean task.
relates: [epic-030]
---
EOF
	mkfile "$R/docs/adr/0030-map.md" <<'EOF'
---
id: adr-0030
title: "Map"
created: 2026-10-09
supersedes:
  - adr-0020: absorbed the first half
---
EOF
	mkfile "$R/docs/tasks/041-bad.md" <<'EOF'
---
id: task-041
title: "unclosed
created: 2026-10-09
---
EOF
	mkfile "$R/docs/tasks/042-open.md" <<'EOF'
---
id: task-042
title: "Open"
EOF
	mkfile "$R/docs/tasks/043-status.md" <<'EOF'
---
id: task-043
title: "Status"
created: 2026-10-09
intent: Has a status.
status: done
relates: [epic-030]
---
EOF
	mkfile "$R/docs/epics/031-down.md" <<'EOF'
---
id: epic-031
title: "Down"
created: 2026-10-09
intent: Points down.
relates: [task-040, direction-030]
---
EOF
	mkfile "$R/docs/tasks/044-cross.md" <<'EOF'
---
id: task-044
title: "Cross"
created: 2026-10-09
intent: Links out.
relates: [other/docs/tasks/001-x.md, "orchestrator:probe-x"]
---
EOF
	cat >>"$R/docs/handbook/gotchas.md" <<'EOF'

### No stage here
Moment: something. Because: not recorded.
EOF
	# Doc reads (Task 025): headings, item ids, a fenced line that is no heading.
	mkfile "$R/docs/probes/probe-c.md" <<'EOF'
---
id: probe-c
title: "Probe C"
status: open
relates: [task-030]
---

# Probe: C

## Trigger

Something.

## Findings

- F3. Third finding.
  continues here.
- F30. Thirtieth finding.

**D1 — A decision.** Text.

```sh
# not a heading
```

### Q2 Open question

Body of Q2.

## Deliberation

Last.
EOF
	# Output contract (Direction 004 Constraint 9): a file with more definitions
	# than an answer shows, and one signature longer than a line may be.
	{
		i=1
		while [ $i -le 80 ]; do printf 'def many_fn_%02d():\n    return %d\n\n\n' $i $i; i=$((i + 1)); done
		printf 'def long_sig(%s):\n    return 0\n' "$(i=1; while [ $i -le 12 ]; do printf 'a_rather_long_parameter_name_%02d, ' $i; i=$((i + 1)); done)z"
	} >"$R/tools/big.py"
	git -C "$R" add -A
	git -C "$R" -c user.name=t -c user.email=t@t commit -q -m fixture
}

# contract <name> <answer>: the header first, no line over 200 bytes, and at
# most 60 lines unless a "+N more" line says what was cut.
contract() {
	bad=$(printf '%s\n' "$2" | awk -v n="$1" '
		NR == 1 && $0 !~ /^sp / { print "line 1 is not the sp header: " $0 }
		length($0) > 200 { print "line " NR " is " length($0) " bytes" }
		/\+[0-9]+ more/ { more = 1 }
		END { if (NR > 60 && !more) print NR " lines with no +N more line" }')
	[ -z "$bad" ] && ok "$1" || no "$1" "$bad"
}

# 36. migrate (Task 027, adr-0007), on its own fixture: every case it settles by
# rule, the ones it leaves to the settle file, and what it never touches.
M=$TMP/mig
build_mig() {
	rm -rf "$M"
	mkdir -p "$M"
	git -C "$M" init -q
	mkfile "$M/docs/directions/001-a.md" <<'EOF'
---
id: docs/directions/001-a.md
title: "A"
created: 2026-01-01
relates: []
---

# Direction 001: A
EOF
	mkfile "$M/docs/directions/002-b.md" <<'EOF'
---
id: "002"
title: "B"
created: 2026-01-02
relates: ["001"]
---

# Direction 002: B
EOF
	mkfile "$M/docs/epics/001-e.md" <<'EOF'
---
id: "001"
title: "E"
created: 2026-01-03
relates: ["002"]
---

# Epic 001: E
EOF
	mkfile "$M/docs/tasks/001-t.md" <<'EOF'
---
id: "001"
title: "T1"
created: 2026-01-04
relates: ["001"]
---

# Task 001: T1
EOF
	mkfile "$M/docs/tasks/002-t.md" <<'EOF'
---
id: "002"
title: "T2"
created: 2026-01-04
relates:
  - "003"
  - docs/tasks/001-t.md
---

# Task 002: T2
EOF
	mkfile "$M/docs/tasks/003-t.md" <<'EOF'
---
id: "003"
title: "T3"
created: 2026-01-04
relates: []
---
EOF
	mkfile "$M/docs/plans/003-p.md" <<'EOF'
---
id: "003"
title: "P3"
created: 2026-01-05
relates: ["003"]
---
EOF
	mkfile "$M/docs/plans/001-p.md" <<'EOF'
---
id: "001"
title: "P1"
created: 2026-01-05
relates: ["001"]
---
EOF
	mkfile "$M/docs/adr/0001-a.md" <<'EOF'
---
id: "0001"
title: "ADR A"
created: 2026-01-06
relates: ["001"]
---

# ADR 0001

This follows Direction 001.
EOF
	mkfile "$M/docs/adr/0002-b.md" <<'EOF'
---
id: adr-0002
title: "ADR B"
created: 2026-01-07
relates: ["002"]
supersedes:
  - docs/adr/0001-a.md (whole, and the rest
    of what it said)
---

# ADR 0002

Nothing cited here.
EOF
	mkfile "$M/docs/adr/0003-c.md" <<'EOF'
---
id: adr-0003
title: "ADR C"
created: 2026-01-08
relates: []
supersedes:
  - docs/adr/0002-b.md: rules 1-2
---

# ADR 0003
EOF
	mkfile "$M/docs/adr/0004-d.md" <<'EOF'
---
id: docs/adr/0004-d.md
title: "ADR D"
status: "superseded by docs/adr/0005-e.md"
created: 2026-01-09
relates: []
---

# ADR 0004
EOF
	mkfile "$M/docs/adr/0005-e.md" <<'EOF'
---
id: adr-0005
title: "ADR E"
created: 2026-01-10
relates: []
---

# ADR 0005
EOF
	mkfile "$M/docs/adr/0006-f.md" <<'EOF'
---
id: adr-0006
title: "ADR F"
status: superseded
created: 2026-01-11
relates: []
---

# ADR 0006
EOF
	mkfile "$M/docs/plans/deep.md" <<'EOF'
# Deepening "candidates"

Body.
EOF
	mkfile "$M/docs/tasks/004-nofm.md" <<'EOF'
# Task 004: Four

Body.
EOF
	mkfile "$M/docs/tasks/005-x.md" <<'EOF'
---
id: task-005
title: "T5"
created: 2026-01-12
relates: ["orchestrator:probe-x"]
---
EOF
	mkfile "$M/docs/tasks/006-y.md" <<'EOF'
---
id: task-006
title: "T6"
created: 2026-01-12
relates: [docs/adr/0005-old-slug.md]
---
EOF
	mkfile "$M/docs/probes/probe-2026-01-01-p.md" <<'EOF'
---
id: docs/probes/probe-2026-01-01-p.md
title: "P"
created: 2026-01-01
status: open
relates: ["002"]
---

Works from Task 002.
EOF
	mkfile "$M/CONTEXT.md" <<'EOF'
# Context
EOF
	git -C "$M" add -A
	git -C "$M" -c user.name=t -c user.email=t@t commit -q -m fixture
}

msum() { (cd "$M" && find . -name .git -prune -o -type f -print | sort | xargs cksum); }

migrate_tests() {
	build_mig
	before=$(msum)
	# The first call on a new repo regenerates the state: migrate must work then.
	out=$(cd "$M" && nav migrate)
	has "$mode 36Q migrate on a cold state" "$(printf '%s\n' "$out" | sed -n 2p)" '^migrate   preview: '
	hasnt "$mode 36R ... with no error" "$out" "can't open\|No such file"
	# Resolver: the not-downward rule (rs), seen through check.
	out=$(cd "$M" && nav check docs/directions/002-b.md)
	hasnt "$mode 36a a Direction's bare id: not-downward settles it" "$out" 'is ambiguous'
	out=$(cd "$M" && nav check docs/tasks/002-t.md)
	hasnt "$mode 36b a Task's sibling id: not-downward settles it" "$out" 'is ambiguous'
	out=$(cd "$M" && nav check docs/adr/0001-a.md)
	has "$mode 36c an ADR's bare id stays ambiguous" "$out" '001 is ambiguous'

	# Preview: counts, the settle file, the diff; nothing written.
	out=$(cd "$M" && nav migrate)
	sf=$M/.git/nav/migrate.settle
	has "$mode 36d preview: summary first" "$(printf '%s\n' "$out" | sed -n 2p)" '^migrate   preview: [0-9]* docs change'
	has "$mode 36e before counts" "$out" '^before    [0-9]* artifacts · [0-9]* breaking'
	has "$mode 36f after counts" "$out" '^after     [0-9]* artifacts · [0-9]* breaking'
	has "$mode 36g the settle file and its open lines" "$out" "^settle    7 open: $sf"
	has "$mode 36S next comes in the head" "$(printf '%s\n' "$out" | head -n 8)" '^next      review the diff and answer each settle line'
	has "$mode 36T left: a count and a file, not a list" "$out" "^left      1 links and ids left as they are: $M/.git/nav/migrate.left"
	has "$mode 36U the cap names --all" "$out" '^more      +[0-9]* more lines (sp migrate --all prints them all'
	has "$mode 36V a renamed path: its number is a guess" "$(cat "$M/.git/nav/migrate.settle")" '^docs/tasks/006-y.md	relates	docs/adr/0005-old-slug.md	adr-0005	# guess · resolves to no doc'
	has "$mode 36h the diff follows" "$out" '^-id: "0001"$'
	contract "$mode 36i contract: migrate" "$out"
	[ "$before" = "$(msum)" ] && ok "$mode 36j preview writes nothing in the work tree" || no "$mode 36j preview writes nothing in the work tree"
	s=$(cat "$sf" 2>/dev/null)
	has "$mode 36k settle: a body citation is a guess" "$s" '^docs/adr/0001-a.md	relates	001	direction-001	# guess · candidates: direction-001 epic-001 task-001 plan-001$'
	has "$mode 36l settle: no citation is blank" "$s" '^docs/adr/0002-b.md	relates	002		# candidates: direction-002 task-002$'
	has "$mode 36m settle: a bare superseded status" "$s" '^docs/adr/0006-f.md	superseded-by	status: superseded		# name its successor$'
	has "$mode 36n settle: a probe's citation" "$s" '^docs/probes/probe-2026-01-01-p.md	relates	002	task-002	# guess'
	has "$mode 36X settle: an Epic and a Direction above a Task are not ranked" "$s" '^docs/tasks/001-t.md	relates	001		# candidates: direction-001 epic-001$'
	has "$mode 36Y settle: no self and nothing below, nor a guess from its own heading" "$s" '^docs/plans/001-p.md	relates	001		# candidates: direction-001 epic-001 task-001$'
	out=$(cd "$M" && nav migrate --all)
	hasnt "$mode 36o --all: no cap" "$out" '^more      +'
	[ -s "$M/.git/nav/migrate.diff" ] && ok "$mode 36p the whole diff is kept" || no "$mode 36p the whole diff is kept"

	# A settle file that is not ready refuses, and writes nothing.
	cp "$sf" "$TMP/settle"
	out=$(cd "$M" && nav migrate --apply --settle "$TMP/settle")
	has "$mode 36q a blank answer refuses" "$out" 'line 2 has no answer'
	sed 's#^\(docs/adr/0002-b.md	relates	002	\)#\1adr-0005#' "$sf" >"$TMP/settle"
	out=$(cd "$M" && nav migrate --apply --settle "$TMP/settle")
	has "$mode 36r an answer that is no candidate refuses" "$out" 'line 2: adr-0005 is not a candidate'
	[ "$before" = "$(msum)" ] && ok "$mode 36s a refused apply writes nothing" || no "$mode 36s a refused apply writes nothing"

	# Apply with a reviewed settle file.
	awk -F'\t' 'BEGIN { OFS = "\t" } $1 == "docs/adr/0002-b.md" { $4 = "direction-002" } $1 == "docs/adr/0006-f.md" { $4 = "adr-0005" } $1 == "docs/tasks/001-t.md" { $4 = "epic-001" } $1 == "docs/plans/001-p.md" { $4 = "task-001" } { print }' "$sf" >"$TMP/settle"
	out=$(cd "$M" && nav migrate --apply --settle "$TMP/settle")
	has "$mode 36t apply: the after counts are live" "$out" '^after     [0-9]* artifacts · 0 breaking'
	out=$(cd "$M" && nav check --all)
	has "$mode 36u check: 0 breaking after apply" "$out" '^check     [0-9]* artifacts · 0 breaking'
	out=$(cd "$M" && nav tree adr-0006)
	has "$mode 36W tree: both edges name one successor once" "$(printf '%s\n' "$out" | sed -n 2p)" 'superseded by adr-0005\]$'
	has "$mode 36v ids are kind-prefixed" "$(cat "$M/docs/tasks/002-t.md")" '^id: task-002$'
	has "$mode 36w a block list keeps its form" "$(cat "$M/docs/tasks/002-t.md")" '^  - task-003$'
	has "$mode 36x an inline list keeps its form" "$(cat "$M/docs/epics/001-e.md")" '^relates: \[direction-002\]$'
	has "$mode 36y a settled link" "$(cat "$M/docs/adr/0001-a.md")" '^relates: \[direction-001\]$'
	has "$mode 36Z a settled upward link" "$(cat "$M/docs/tasks/001-t.md")" '^relates: \[epic-001\]$'
	has "$mode 36Z2 a sole Task above a Plan settles by rule" "$(cat "$M/docs/plans/003-p.md")" '^relates: \[task-003\]$'
	has "$mode 36z a note leaves supersedes" "$(sed -n '/^supersedes:/,/^[a-z]/p' "$M/docs/adr/0002-b.md")" '^  - adr-0001$'
	hasnt "$mode 36A its continuation goes too" "$(awk 'NR > 1 && /^---$/ { exit } { print }' "$M/docs/adr/0002-b.md")" 'of what it said'
	has "$mode 36B the note lands in the body" "$(tail -n 1 "$M/docs/adr/0002-b.md")" '^Supersession note: adr-0001 (whole, and the rest of what it said)$'
	has "$mode 36C a mapping's note lands too" "$(tail -n 1 "$M/docs/adr/0003-c.md")" '^Supersession note: adr-0002 (rules 1-2)$'
	has "$mode 36D the predecessor gets superseded-by" "$(cat "$M/docs/adr/0001-a.md")" '^  - adr-0002$'
	has "$mode 36E a legacy status gets both edges" "$(cat "$M/docs/adr/0005-e.md")" '^  - adr-0004$'
	has "$mode 36F ... and its status stays" "$(cat "$M/docs/adr/0004-d.md")" '^status: "superseded by docs/adr/0005-e.md"$'
	has "$mode 36G a settled successor" "$(cat "$M/docs/adr/0006-f.md")" '^  - adr-0005$'
	has "$mode 36H frontmatter for a numbered doc" "$(sed -n 1,6p "$M/docs/tasks/004-nofm.md")" '^id: task-004$'
	has "$mode 36I ... its title from the heading" "$(sed -n 1,6p "$M/docs/tasks/004-nofm.md")" '^title: "Task 004: Four"$'
	has "$mode 36J an unnumbered doc takes the next free number" "$(sed -n 1,6p "$M/docs/plans/deep.md")" '^id: plan-004$'
	has "$mode 36K ... and its quoted title" "$(sed -n 1,6p "$M/docs/plans/deep.md")" '^title: "Deepening \\"candidates\\""$'
	has "$mode 36L another workspace is left" "$(cat "$M/docs/tasks/005-x.md")" 'orchestrator:probe-x'
	git -C "$M" diff --quiet -- CONTEXT.md && ok "$mode 36M CONTEXT.md untouched" || no "$mode 36M CONTEXT.md untouched"
	d=$(git -C "$M" diff -U0 -- docs/adr/0001-a.md | grep '^[-+][^-+]')
	has "$mode 36N the predecessor: only id, links and superseded-by" "$(printf '%s\n' "$d" | grep -v -e '^[-+]id:' -e '^[-+]relates:' -e '^+superseded-by:' -e '^+  - adr-0002$' || echo clean)" '^clean$'
	out=$(cd "$M" && nav migrate)
	has "$mode 36O a second run changes nothing" "$(printf '%s\n' "$out" | sed -n 2p)" '^migrate   preview: 0 docs change'
	out=$(cd "$M" && "$NAV" migrate 2>&1)
	has "$mode 36P nav refuses migrate" "$out" 'run sp migrate'
}

# 37. Help: the command list, and a page per command (D16). Needs no workspace.
help_tests() {
	H=$TMP/nohelp
	mkdir -p "$H"
	for a in "" help --help; do
		# shellcheck disable=SC2086
		out=$(cd "$H" && "$SP" $a 2>/dev/null); st=$?
		has "$mode 37a sp ${a:-(bare)}: the command list" "$out" '^  check '
		has "$mode 37b sp ${a:-(bare)}: points to a command's help" "$out" 'run sp <command> help'
		[ "$st" = 0 ] && ok "$mode 37c sp ${a:-(bare)}: exit 0" || no "$mode 37c sp ${a:-(bare)}: exit 0" "exit $st"
		contract "$mode 37d contract: sp ${a:-(bare)}" "$out"
	done
	for c in def docs module file unresolved trace check tree outline show log new supersede relate ledger migrate; do
		for h in help --help; do
			out=$(cd "$H" && "$SP" "$c" "$h" 2>&1); st=$?
			has "$mode 37e $c $h: its own page" "$(printf '%s\n' "$out" | sed -n 1p)" "^sp $c — "
			has "$mode 37f $c $h: usage" "$out" "^usage     sp $c"
			has "$mode 37g $c $h: an example" "$out" "^example   sp $c"
			has "$mode 37h $c $h: the next step" "$out" '^then      '
			[ "$st" = 0 ] && ok "$mode 37i $c $h: exit 0" || no "$mode 37i $c $h: exit 0" "exit $st"
			contract "$mode 37j contract: $c $h" "$out"
		done
	done
	out=$(cd "$H" && "$SP" help check 2>&1)
	has "$mode 37k sp help <command> is its page" "$(printf '%s\n' "$out" | sed -n 1p)" '^sp check — '
	out=$(cd "$H" && "$SP" migrate help 2>&1)
	has "$mode 37l migrate help: the settle file" "$out" 'settle'
	has "$mode 37m migrate help: --apply on the user's word" "$out" "only on the user's word"
	out=$(cd "$R" && "$SP" check help 2>&1)
	hasnt "$mode 37n check help runs no check" "$out" '^check     '
	out=$(cd "$H" && "$SP" frob 2>&1); st=$?
	has "$mode 37o an unknown command says run sp help" "$out" "no command 'frob': run sp help"
	[ "$st" = 2 ] && ok "$mode 37p ... and exits 2" || no "$mode 37p ... and exits 2" "exit $st"
	out=$(cd "$H" && "$SP" help frob 2>&1)
	has "$mode 37q help on an unknown command" "$out" "no command 'frob': run sp help"
	out=$(cd "$R" && "$NAV" trace help 2>&1)
	has "$mode 37r nav: help for a read verb" "$(printf '%s\n' "$out" | sed -n 1p)" '^sp trace — '
	# help is reserved in any slot: as a title it asks for the page, never
	# names a new doc.
	before=$(ls "$R/docs/probes" | wc -l)
	out=$(cd "$R" && nav new probe help 2>&1)
	has "$mode 37s help as a title prints the page" "$(printf '%s\n' "$out" | sed -n 1p)" '^sp new — '
	has "$mode 37t help as a title writes nothing" "$(ls "$R/docs/probes" | wc -l)" "^$before\$"
}

# 38. The call log (Direction 005, task-029, task-030). Run once: the wrapper
# and sp log do not depend on the tool mode.
log_tests() {
	mode=log
	echo "== mode: log"
	build
	H=$TMP/nohelp
	mkdir -p "$H" "$TMP/home"
	LOG=$TMP/state/sp/sp.log
	(cd "$R" && "$SP" tree task-001 >/dev/null 2>&1) # the index, so no call regenerates it
	# Each class of call: a read verb, a usage error, help, no command, outside a
	# workspace, a bad role, and nav. Logged and unlogged answers are identical.
	n=0
	for c in "$R|tree task-001" "$R|show adr-9 Decision" "$R|bogus" "$R|help" "$R|" "$H|tree x" "$R|--role nope tree task-001" "$R/src|file auth/session.py"; do
		d=${c%%|*} a=${c#*|}
		# shellcheck disable=SC2086
		(cd "$d" && HOME=$TMP/home "$SP" $a >"$TMP/u.out" 2>"$TMP/u.err"; echo $? >"$TMP/u.st")
		# shellcheck disable=SC2086
		(cd "$d" && SP_LOG=$LOG "$SP" $a >"$TMP/l.out" 2>"$TMP/l.err"; echo $? >"$TMP/l.st")
		n=$((n + 1))
		cmp -s "$TMP/u.out" "$TMP/l.out" && cmp -s "$TMP/u.err" "$TMP/l.err" && cmp -s "$TMP/u.st" "$TMP/l.st" &&
			ok "log 38a logged = unlogged: sp $a" || no "log 38a logged = unlogged: sp $a" "$(diff "$TMP/u.out" "$TMP/l.out"; diff "$TMP/u.err" "$TMP/l.err"; cat "$TMP/u.st" "$TMP/l.st")"
	done
	out=$(find "$TMP/home" -type f)
	[ -z "$out" ] && ok "log 38b unset writes nothing" || no "log 38b unset writes nothing" "$out"
	(cd "$R" && SP_LOG=$LOG "$NAV" def Session.refresh >/dev/null 2>&1)
	(cd "$R" && SP_LOG=$LOG "$SP" new task "Logged" >/dev/null 2>&1)
	n=$((n + 2))
	[ "$(wc -l <"$LOG" | tr -d ' ')" = "$n" ] && ok "log 38c one record per call, every class" || no "log 38c one record per call, every class" "$(cat "$LOG")"
	has "log 38d a write verb is logged" "$(tail -1 "$LOG")" '"argv":\["new","task","Logged"\]'
	has "log 38e nav is logged as nav" "$(cat "$LOG")" '"name":"nav","argv":\["def","Session.refresh"\]'
	has "log 38f the workspace a subdirectory call resolved" "$(cat "$LOG")" "\"ws\":\"$R\",\"cwd\":\"$R/src\""
	has "log 38g a usage error, with its exit and stderr" "$(cat "$LOG")" "\"exit\":2,.*\"argv\":\\[\"bogus\"\\].*\"stderr\":\"sp: no command 'bogus': run sp help\""
	has "log 38h outside a workspace: exit 3" "$(cat "$LOG")" "\"exit\":3,\"ws\":\"$H\""
	hasnt "log 38i help is never marked" "$(grep '"argv":\["help"\]' "$LOG")" '"marks":\["'
	# Arguments survive tabs, quotes, backslashes and newlines, and rerun exactly.
	arg=$(printf 'a\tb "q" \\ c\nd')
	(cd "$R" && SP_LOG=$LOG CLAUDE_CODE_SESSION_ID=sess-1 "$SP" show task-999 "$arg" >/dev/null 2>&1)
	has "log 38j argv is escaped" "$(tail -1 "$LOG")" '"argv":\["show","task-999","a\\tb \\"q\\" \\\\ c\\nd"\]'
	has "log 38k the session id" "$(tail -1 "$LOG")" '"session":"sess-1"'
	out=$(cd "$H" && SP_LOG=$LOG "$SP" log 2>&1); st=$?
	[ "$st" = 0 ] && ok "log 38l sp log runs outside a workspace" || no "log 38l sp log runs outside a workspace" "exit $st: $out"
	contract "log 38m contract: sp log" "$out"
	has "log 38n failures come first" "$(printf '%s\n' "$out" | sed -n 3p)" '^fail      '
	rerun=$(printf '%s\n' "$out" | grep '^rerun .*bogus' | sed 's/^rerun     //')
	got=$(SP_LOG= sh -c "$rerun" 2>&1)
	has "log 38o a rerun line reproduces the call" "$got" "no command 'bogus'"
	rerun=$(printf '%s\n' "$out" | grep '^rerun .*show task-999 "' | sed 's/^rerun     //')
	has "log 38p a multi-line argument reruns on one line" "$rerun" "\"\$(printf 'a\\\\tb"
	(cd "$R" && SP_LOG=$LOG "$SP" bogus >/dev/null 2>&1)
	has "log 38q identical calls fold" "$(cd "$H" && SP_LOG=$LOG "$SP" log 2>&1)" '^fail      ×2 · last '
	# A log that cannot be written costs one stderr line, never the answer.
	: >"$TMP/afile"
	for bad in "$TMP/afile/sp.log" "rel.log"; do
		out=$(cd "$R" && SP_LOG=$bad "$SP" tree task-001 2>"$TMP/l.err"); st=$?
		[ "$st" = 0 ] && ok "log 38r unwritable $bad: exit kept" || no "log 38r unwritable $bad: exit kept" "exit $st"
		[ "$out" = "$(cd "$R" && "$SP" tree task-001 2>/dev/null)" ] && ok "log 38s unwritable $bad: answer kept" || no "log 38s unwritable $bad: answer kept" "$out"
		[ "$(grep -c 'SP_LOG not written' "$TMP/l.err")" = 1 ] && [ "$(wc -l <"$TMP/l.err" | tr -d ' ')" = 1 ] &&
			ok "log 38t unwritable $bad: one stderr line" || no "log 38t unwritable $bad: one stderr line" "$(cat "$TMP/l.err")"
	done
	[ ! -e "$R/rel.log" ] && ok "log 38u a relative path is never written" || no "log 38u a relative path is never written"
	(cd "$R" && SP_LOG=$LOG "$SP" outline task-001 >/dev/null 2>&1)
	hasnt "log 38v the default stores no answer" "$(tail -1 "$LOG")" '"stdout":'
	(cd "$R" && SP_LOG=$LOG SP_LOG_LEVEL=full "$SP" outline task-001 >/dev/null 2>&1)
	has "log 38w SP_LOG_LEVEL=full stores it" "$(tail -1 "$LOG")" '"stdout":"sp outline task-001 '
	# migrate runs sp check on a copy; the record keeps the workspace of the call.
	(cd "$R" && SP_LOG=$LOG "$SP" migrate >/dev/null 2>&1)
	has "log 38w2 a nested sp leaves the workspace alone" "$(tail -1 "$LOG")" "\"ws\":\"$R\",\"cwd\":\"$R\",\"name\":\"sp\",\"argv\":\\[\"migrate\"\\]"
	# A cut answer is flagged: sp log over many distinct failures stops at 60 lines.
	i=0
	while [ $i -lt 25 ]; do (cd "$R" && SP_LOG=$LOG "$SP" "nope$i" >/dev/null 2>&1); i=$((i + 1)); done
	out=$(cd "$H" && SP_LOG=$LOG "$SP" log 2>&1)
	has "log 38x a long sp log is cut" "$out" '^more      +'
	has "log 38y ... and its record says so" "$(tail -1 "$LOG")" '"argv":\["log"\],.*"cut":true'
	out=$(cd "$H" && "$SP" log 2>&1); st=$?
	has "log 38z unset: sp log says so" "$out" 'SP_LOG is unset'
	[ "$st" = 2 ] && ok "log 38z2 ... and exits 2" || no "log 38z2 ... and exits 2" "exit $st"
}

run_mode() { # run_mode <name> <SP_CTAGS> <SP_YQ> <SP_MDQ>
	mode=$1
	export SP_CTAGS="$2" SP_YQ="${3:-}" SP_MDQ="${4:-}"
	echo "== mode: $mode"
	build
	nav() { "$SP" "$@" 2>&1; }

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
	st=$(cd "$TMP" && "$SP" def Session.refresh >/dev/null 2>&1; echo $?)
	[ "$st" = 3 ] && ok "$mode 7d path-less outside a repo exits 3" || no "$mode 7d path-less outside a repo exits 3" "status $st"
	has "$mode 7e lists the candidate" "$out" "$R"
	out=$(cd "$TMP" && nav -C repo docs build_index)
	has "$mode 7f -C names the workspace" "$out" "· $R ·"

	# 8. Every query answers; the grep layer says so.
	for qa in "def build_index" "docs build_index" "module src" "file src/util.sh" "unresolved"; do
		# shellcheck disable=SC2086
		out=$(cd "$R" && nav $qa)
		if [ "$mode" = grep ]; then has "$mode 8 '$qa' answers via grep" "$out" '· grep · awk'
		else hasnt "$mode 8 '$qa' answers via ctags" "$out" '· grep · awk'; fi
	done
	out=$(cd "$R" && nav module src)
	has "$mode 8a module lists defs" "$out" 'defs      src/'
	has "$mode 8b module finds docs" "$out" 'on-match  docs/tasks/001-t.md'
	# A heredoc terminator delimits text; it defines nothing.
	hasnt "$mode 8c module lists no heredoc terminator" "$out" 'USAGE'
	has "$mode 8d module still lists the function" "$out" 'defs      src/util.sh  (3): build_index, start, usage$'
	out=$(cd "$R" && nav file src/util.sh)
	hasnt "$mode 8e file lists no heredoc terminator" "$out" 'USAGE'
	out=$(cd "$R" && nav def USAGE)
	hasnt "$mode 8f def finds no heredoc terminator" "$out" '^def       src/util.sh'

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
	st=$(cd "$R" && "$SP" --budget 100 docs Session.refresh >/dev/null 2>&1; echo $?)
	has "$mode 11a over share says trim" "$out" 'over share: trim on-match'
	[ "$st" = 0 ] && ok "$mode 11b exit 0 over budget" || no "$mode 11b exit 0 over budget" "status $st"
	has "$mode 11c always tier" "$out" 'always    docs/handbook/index.md'
	out=$(cd "$R" && AGENT_CONTEXT_TOKENS= "$SP" docs Session.refresh 2>&1)
	has "$mode 11d unset budget reports sizes" "$out" 'budget    unset'
	# Sessions pipe nav through `| head`: the summary must come before docs and defs.
	out=$(cd "$R" && nav --budget 100 file src/auth/session.py | sed -n 2p)
	has "$mode 11e budget is the line after the header" "$out" '^budget    '
	out=$(cd "$R" && nav --budget 100 file src/auth/session.py | tail -n 1)
	has "$mode 11f file defs come last" "$out" '^def       '

	# 22. Handbook entries in the answer are counted once each, against 1/4 of the share.
	out=$(cd "$R" && AGENT_CONTEXT_TOKENS= "$SP" docs Session.refresh 2>&1)
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

	# 25. Field shapes (probe-2026-10-09-nav-in-field-use).
	out=$(cd "$R" && nav docs prose_sup_fn)
	hasnt "$mode 25a prose after a supersedes link is not a link" "$out" 'supersedes (rules'
	has "$mode 25b the link itself is kept" "$out" 'supersedes docs/adr/0010-before.md (lookup)'
	hasnt "$mode 25c an ADR superseded with a note is sealed" "$out" 'on-match  docs/adr/0010-before.md'
	out=$(cd "$R" && nav trace docs/plans/007-p.md)
	has "$mode 25d a short id with a Task, an Epic and a Direction above is not ranked" "$out" '^trace     ambiguous link: 007 (docs/directions/007-d.md docs/tasks/007-t.md docs/epics/007-e.md)$'
	out=$(cd "$R" && nav trace docs/tasks/007-t.md)
	has "$mode 25e the Task resolves to its Epic" "$out" 'trace     epic-007: E seven$'
	has "$mode 25f short id resolves Epic -> Direction" "$out" 'trace     007: D seven$'
	hasnt "$mode 25f2 a quoted id is shown unquoted" "$out" '"'
	hasnt "$mode 25g adr- ids are skipped" "$out" 'Before'
	out=$(cd "$R" && nav trace 007)
	has "$mode 25h a bare shared id is ambiguous, not picked" "$out" '^trace     ambiguous link: 007 (docs/directions/007-d.md docs/plans/007-p.md docs/tasks/007-t.md docs/epics/007-e.md)'
	out=$(cd "$R" && nav trace epic-007)
	has "$mode 25i a unique short id resolves" "$out" 'trace     epic-007: E seven$'
	out=$(cd "$R" && nav file tools/extra.py)
	has "$mode 25j a ## handbook entry is counted" "$out" '^handbook  1 entries matched in 1 files'

	# 26. One resolver: kind-prefixed ids, then paths, then legacy short ids (Task 022).
	out=$(cd "$R" && nav trace task-030)
	has "$mode 26a a kind-prefixed id resolves through id:" "$out" '^trace     task-030: T thirty.'
	has "$mode 26b probes are not parents" "$out" '^trace     epic-030: E thirty.'
	has "$mode 26c the trace reaches the Direction" "$out" '^trace     direction-030: D thirty.'
	hasnt "$mode 26d a same-tier predecessor is not a parent" "$out" 'Direction B intent'
	out=$(cd "$R" && nav trace plan-030)
	has "$mode 26e kind dir + number when no id: matches" "$out" '^trace     docs/tasks/031-x.md: T thirty-one.'
	out=$(cd "$R" && nav trace task-032)
	has "$mode 26f two files with one number are ambiguous" "$out" '^trace     ambiguous link: task-032 (docs/tasks/032-a.md docs/tasks/032-b.md)'
	out=$(cd "$R" && nav trace direction-031)
	hasnt "$mode 26h an id shared only by non-parents is passed over" "$out" 'ambiguous'
	out=$(cd "$R" && nav trace docs/directions/030-d.md)
	has "$mode 26g a path still resolves" "$out" '^trace     direction-030: D thirty.'
	# A root that names no doc is a miss, said as show says it; a broken link
	# further up stays a trace row (10e).
	out=$(cd "$R" && nav trace task-099 2>&1) && no "$mode 26i a missing root exits 2" "$out" || ok "$mode 26i a missing root exits 2"
	has "$mode 26j a missing root names the highest of its kind" "$out" '^sp: task-099 names no doc: the highest task here is task-0'
	hasnt "$mode 26k a missing root is no broken link" "$out" 'broken link'
	# A link into another workspace is not followed, and is not broken.
	out=$(cd "$R" && nav trace task-044)
	has "$mode 26p another workspace is said, not followed" "$out" '^trace     another workspace: other/docs/tasks/001-x.md (not followed)$'
	hasnt "$mode 26q another workspace is no broken link" "$out" 'broken link'
	printf -- '---\nid: task-092\ntitle: "T092"\nintent: T ninety-two.\nrelates: ["orchestrator:probe-x", epic-030]\n---\n' | mkfile "$R/docs/tasks/092-out.md"
	out=$(cd "$R" && nav trace task-092)
	has "$mode 26r a probe in another workspace is passed over" "$out" '^trace     epic-030: E thirty.'
	rm "$R/docs/tasks/092-out.md"
	# file takes a path; an id gets the path to use, or the miss.
	out=$(cd "$R" && nav file task-030 2>&1) && no "$mode 26l file on an id exits 2" "$out" || ok "$mode 26l file on an id exits 2"
	has "$mode 26m file on an id names its path" "$out" '^sp: file takes a path: sp file docs/tasks/030-'
	out=$(cd "$R" && nav file task-099 2>&1)
	has "$mode 26n file on a missing id says so" "$out" '^sp: task-099 names no doc: the highest task here is task-0'
	out=$(cd "$R" && nav file src/none.py 2>&1)
	has "$mode 26o file on a missing path says so" "$out" '^sp: no such file in .*: src/none.py$'

	# 27. Sealing is the union of both edges and the legacy status (ADR 0005).
	out=$(cd "$R" && nav docs kp_fn)
	hasnt "$mode 27a sealed by a kind-prefixed supersedes" "$out" 'on-match  docs/adr/0020-k.md'
	has "$mode 27b the successor points at it" "$out" 'supersedes docs/adr/0020-k.md (lookup)'
	out=$(cd "$R" && nav docs own_fn)
	hasnt "$mode 27c sealed by its own superseded-by" "$out" 'on-match  docs/adr/0022-own.md'
	has "$mode 27d the backward edge draws the pointer" "$out" 'supersedes docs/adr/0022-own.md (lookup)'
	out=$(cd "$R" && nav docs legacy_fn)
	hasnt "$mode 27e sealed by a legacy status" "$out" 'on-match  docs/adr/0024-legacy.md'
	has "$mode 27f the successor named in the status points at it" "$out" 'supersedes docs/adr/0024-legacy.md (lookup)'

	# 28. The alias, and the header naming the tools that ran.
	out=$(cd "$R" && "$NAV" trace task-030 2>&1)
	has "$mode 28a nav still answers read verbs" "$out" '^trace     task-030: T thirty.'
	out=$(cd "$R" && "$NAV" new task x 2>&1)
	has "$mode 28b nav refuses other verbs and names sp" "$out" 'run sp new'
	out=$(cd "$R" && nav def build_index | head -n 1)
	if [ "$mode" = grep ]; then has "$mode 28c header names grep and awk" "$out" '^sp def build_index · .* · grep · awk'
	else has "$mode 28c header names ctags and awk" "$out" '^sp def build_index · .* · ctags · awk'; fi

	# 29. Output contract on every default answer (Direction 004 Constraint 9).
	out=$(cd "$R" && nav file tools/big.py)
	has "$mode 29a file caps its definitions" "$out" '^def       +[0-9]* more'
	for qa in "def build_index" "def Session.refresh" "docs Session.refresh" "docs build_index" "docs D-002" \
		"def long_sig" "module src" "module ." "file src/auth/session.py" "file tools/big.py" "unresolved" "trace task-030" "trace 007"; do
		# shellcheck disable=SC2086
		out=$(cd "$R" && nav $qa)
		contract "$mode 29 contract: $qa" "$out"
	done

	# 35. outline, show, tree, and file on a doc (Task 025).
	out=$(cd "$R" && nav outline probe-c)
	has "$mode 35a outline: budget line second" "$(printf '%s\n' "$out" | sed -n 2p)" '^budget    docs/probes/probe-c.md is'
	has "$mode 35b outline: frontmatter" "$out" '^fm        id: probe-c · status: open'
	has "$mode 35c outline: headings with lines" "$out" '^L14 *## Findings  (16 lines'
	has "$mode 35d outline: a heading under a heading" "$out" '### Q2 Open question'
	hasnt "$mode 35e outline: a fenced line is no heading" "$out" 'not a heading'
	has "$mode 35f outline: item ids, each with its line" "$out" '^items     4: F3 L16 ~[0-9]* · F30 L18 ~[0-9]* · D1 L20 ~[0-9]* · Q2 L26'
	out=$(cd "$R" && nav show probe-c F3)
	has "$mode 35g show: an item, with its range" "$out" '^show      docs/probes/probe-c.md  F3  L16-17'
	has "$mode 35h show: the item runs to the next one" "$out" 'continues here'
	hasnt "$mode 35i show: F3 never matches F30" "$out" 'Thirtieth'
	has "$mode 35j show: budget line second" "$(printf '%s\n' "$out" | sed -n 2p)" '^budget    shown'
	out=$(cd "$R" && nav show probe-c findings Deliberation)
	has "$mode 35k show: a heading, any case" "$out" '^show      docs/probes/probe-c.md  Findings  L14-29'
	has "$mode 35l show: the section holds its subsections" "$out" 'Body of Q2.'
	has "$mode 35m show: several at once" "$out" '^show      docs/probes/probe-c.md  Deliberation  L30-32'
	has "$mode 35n show: original lines, fences kept" "$out" '^# not a heading$'
	out=$(cd "$R" && nav show probe-c Nothing)
	has "$mode 35o show: a miss says what to do" "$out" 'not found: sp outline'
	out=$(cd "$R" && nav show adr-0099 Decision 2>&1)
	has "$mode 35E an unknown id names the highest of its kind" "$out" '^sp: adr-0099 names no doc: the highest adr here is adr-0030$'
	hasnt "$mode 35F an unknown id is not sent to sp check" "$out" 'sp check'
	out=$(cd "$R" && nav show product-epic-099 Goal 2>&1)
	has "$mode 35G an unknown id of an absent kind says so" "$out" 'names no doc: there is no product-epic here'
	out=$(cd "$R" && nav show docs/adr/0099-none.md Decision 2>&1)
	has "$mode 35H an unknown path says so" "$out" 'names no doc: no doc at that path'
	# A doc outside the kind directories (a nested fixture) is no artifact here:
	# its id: never wins over the workspace's own adr, which has a path id.
	mkfile "$R/vendor/kit/docs/adr/0001-kit.md" <<'EOF'
---
id: adr-0001
title: "Kit"
relates: []
---
EOF
	out=$(cd "$R" && nav outline adr-0001 2>&1)
	has "$mode 35I an id names an artifact, not a nested doc" "$out" 'docs/adr/0001-old.md'
	hasnt "$mode 35J a nested doc's id is passed over" "$out" 'vendor/kit'
	p=$(cd "$R" && nav new probe "Nested" --relates adr-0001 | awk '$1 == "new" { print $3 }')
	out=$(cat "$R/$p" 2>&1)
	has "$mode 35K a write verb links the artifact" "$out" '^  - adr-0001$'
	hasnt "$mode 35L a write verb never links the nested doc" "$out" 'vendor/kit'
	rm -rf "$R/vendor" "$R/$p"
	out=$(cd "$R" && nav show probe-c Trigger | head -n 1)
	if [ "$mode" = nomdq ]; then has "$mode 35p show without mdq says reduced" "$out" 'reduced: no mdq'
	else has "$mode 35p show names mdq" "$out" '· awk · mdq'; fi
	out=$(cd "$R" && nav tree direction-030)
	has "$mode 35q tree: summary first" "$(printf '%s\n' "$out" | sed -n 2p)" '^tree      direction-030  docs/directions/030-d.md  · [0-9]* descendants'
	has "$mode 35r tree: next free numbers" "$out" '^next      direction-032 · epic-032 · task-045 · plan-031 · adr-0031 · story-002'
	has "$mode 35s tree: a child" "$out" '^  epic-030  E30'
	has "$mode 35t tree: a grandchild" "$out" '^    task-030  T30'
	has "$mode 35u tree: an open probe, with its state" "$out" '^      probe-c  Probe C  \[open\]'
	has "$mode 35v tree: a Plan under its Task" "$out" '^      plan-030  P30'
	has "$mode 35w tree: a Task by its Plans" "$out" 'task-031  T31  \[0/1 plans implemented\]'
	hasnt "$mode 35x tree: a downward relates is no child" "$(cd "$R" && nav tree task-040)" 'epic-031'
	out=$(cd "$R" && nav tree docs/directions/002-b.md)
	has "$mode 35y tree: a superseded root says so" "$out" '^tree      .*superseded by direction-030'
	hasnt "$mode 35z tree: its successor is no child" "$out" '^  direction-030'
	out=$(cd "$R" && nav file docs/tasks/030-t.md)
	has "$mode 35A file on a doc: its trace" "$out" '^trace     task-030: T thirty.'
	has "$mode 35B file on a doc: its tree" "$out" '^tree      task-030'
	hasnt "$mode 35C file on a doc: no empty on-match" "$out" 'on-match  none'
	for qa in "outline probe-c" "show probe-c Findings" "tree direction-030" "file docs/tasks/030-t.md"; do
		# shellcheck disable=SC2086
		contract "$mode 35 contract: $qa" "$(cd "$R" && nav $qa)"
	done

	# 30. check: what breaks navigation, and drift (Task 023).
	out=$(cd "$R" && nav check task-040)
	has "$mode 30a a clean doc reports nothing" "$out" '^ok        nothing to report'
	has "$mode 30b one-doc summary" "$out" '^check     docs/tasks/040-clean.md: 0 breaking · 0 drift'
	out=$(cd "$R" && nav check --all)
	has "$mode 30c workspace summary first" "$(printf '%s\n' "$out" | sed -n 2p)" '^check     [0-9]* artifacts · [0-9]* breaking in'
	has "$mode 30d no frontmatter" "$out" '^break     docs/tasks/005-classes.md  frontmatter  none'
	has "$mode 30e does not parse" "$out" '^break     docs/tasks/041-bad.md  frontmatter  .*does not parse'
	has "$mode 30f no closing fence" "$out" '^break     docs/tasks/042-open.md  frontmatter  no closing ---'
	has "$mode 30g missing title" "$out" '^break     docs/plans/001-p.md  title  missing'
	has "$mode 30h path id is not kind-prefixed" "$out" '^break     docs/tasks/001-t.md  id  is the path: want task-001'
	has "$mode 30i a shared id" "$out" '^break     docs/plans/007-p.md  id  007 is shared by 3 docs'
	has "$mode 30j a mapping link item" "$out" '^break     docs/adr/0030-map.md  supersedes  item 1 is a mapping'
	has "$mode 30k a note after a link" "$out" '^break     docs/adr/0011-after.md  supersedes  item 1 carries a note'
	has "$mode 30l a broken link" "$out" '^break     docs/tasks/002-noint.md  relates  docs/missing/404.md resolves to no doc'
	hasnt "$mode 30m a Direction's bare id: not-downward settles it (adr-0007)" "$out" '^break     docs/directions/031-d.md  relates  007'
	has "$mode 30n supersedes without superseded-by" "$out" '^break     docs/adr/0020-k.md  superseded-by  missing docs/adr/0021-k2.md'
	has "$mode 30o superseded-by without supersedes" "$out" '^break     docs/adr/0023-own2.md  supersedes  missing docs/adr/0022-own.md'
	has "$mode 30p a legacy status with no edge" "$out" '^break     docs/adr/0024-legacy.md  superseded-by  status says superseded'
	has "$mode 30q status on a Task is drift" "$out" '^drift     docs/tasks/043-status.md  status  written on a task'
	has "$mode 30r relates pointing down is drift" "$out" '^drift     docs/epics/031-down.md  relates  task-040 points down'
	hasnt "$mode 30s relates pointing up is not" "$out" 'docs/epics/031-down.md  relates  direction-030'
	has "$mode 30t missing intent is drift" "$out" '^drift     docs/tasks/002-noint.md  intent  missing'
	has "$mode 30u another workspace is drift, by path" "$out" '^drift     docs/tasks/044-cross.md  relates  other/docs/tasks/001-x.md names another workspace'
	has "$mode 30v another workspace is drift, by repo:id" "$out" '^drift     docs/tasks/044-cross.md  relates  orchestrator:probe-x names another workspace'
	has "$mode 30w a handbook entry without a Stage" "$out" '^drift     docs/handbook/gotchas.md  entry  "No stage here" has no Stage'
	hasnt "$mode 30x a full handbook entry is not drift" "$out" '"Refresh races"'
	hasnt "$mode 30y ledgers are not artifacts" "$out" 'LEDGER.md'
	hasnt "$mode 30z research is not an artifact" "$out" 'docs/knowledge/notes.md'
	out=$(cd "$R" && nav check | head -n 1)
	if [ "$mode" = noyq ]; then hasnt "$mode 30A header without yq" "$out" '· yq'; else has "$mode 30A header names yq" "$out" '· awk · yq'; fi
	out=$(cd "$R" && nav check)
	has "$mode 30B the default answer is capped" "$out" '^more      +[0-9]* more lines'
	contract "$mode 30C contract: check" "$out"
	out=$(cd "$R" && nav check nothing-999 2>&1)
	has "$mode 30D an unknown doc says what to do" "$out" 'names no doc: name it by kind-prefixed id'
	out=$(cd "$R" && nav docs Session.refresh)
	has "$mode 30E a read answer counts malformed docs" "$out" '^check     [0-9]* docs in this answer are malformed: run sp check'
	out=$(cd "$R" && nav trace task-040)
	hasnt "$mode 30F a clean trace has no check line" "$out" '^check'
	out=$(cd "$R" && nav trace task-030)
	has "$mode 30G a trace counts malformed docs" "$out" '^check     [0-9]* docs in this trace are malformed'

	# State stays out of the work tree.
	st=$(git -C "$R" status --porcelain --ignored | grep -v -e ' docs/directions/002-b.md$' || :)
	[ -z "$st" ] && ok "$mode 12 nav adds nothing to the work tree" || no "$mode 12 nav adds nothing to the work tree" "$st"
	[ -f "$R/.git/nav/tags" ] && ok "$mode 13 tags under git-common-dir" || no "$mode 13 tags under git-common-dir"

	# 31. Write verbs (Task 024). They run last: they change the work tree.
	export SP_TODAY=2026-10-09
	out=$(cd "$R" && nav new task "A New Task: with *punctuation*" --relates epic-030 --intent "New task intent.")
	has "$mode 31a new allocates the next number" "$out" '^new       task-045  docs/tasks/045-a-new-task-with-punctuation.md'
	has "$mode 31b what it wrote passes check" "$out" '^check     docs/tasks/045-a-new-task-with-punctuation.md: 0 breaking · 0 drift'
	f=$R/docs/tasks/045-a-new-task-with-punctuation.md
	has "$mode 31c id, title, created, intent, relates" "$(sed -n 1,9p "$f")" '^relates:$'
	has "$mode 31d title quoted" "$(cat "$f")" '^title: "A New Task: with \*punctuation\*"$'
	has "$mode 31e the relates link is kind-prefixed" "$(cat "$f")" '^  - epic-030$'
	has "$mode 31f skeleton heading" "$(cat "$f")" '^# Task 045: A New Task'
	has "$mode 31g skeleton sections" "$(cat "$f")" '^## Notes$'
	out=$(cd "$R" && nav new adr "Next ADR")
	has "$mode 31h ADR numbers have four digits" "$out" '^new       adr-0031  docs/adr/0031-next-adr.md'
	out=$(cd "$R" && nav new probe "Why it broke")
	has "$mode 31i a probe gets a dated id" "$out" '^new       probe-2026-10-09-why-it-broke  docs/probes/probe-2026-10-09-why-it-broke.md'
	has "$mode 31j a probe opens" "$(cat "$R/docs/probes/probe-2026-10-09-why-it-broke.md")" '^status: open$'
	out=$(cd "$R" && nav new story "A story" --relates "docs/PRODUCT.md#D-002")
	has "$mode 31k product kinds, and a PRODUCT.md anchor" "$out" '^new       story-002  docs/product/stories/002-a-story.md'
	has "$mode 31l the anchor is kept" "$(cat "$R/docs/product/stories/002-a-story.md")" '^  - docs/PRODUCT.md#D-002$'
	(cd "$R" && "$SP" new task "Parallel one" >/dev/null 2>&1) &
	(cd "$R" && "$SP" new task "Parallel two" >/dev/null 2>&1) &
	wait
	n1=$(ls "$R/docs/tasks" | grep -c 'parallel-one'); n2=$(ls "$R/docs/tasks" | grep -c 'parallel-two')
	nums=$(ls "$R/docs/tasks" | grep parallel | cut -c1-3 | sort -u | wc -l | tr -d ' ')
	[ "$n1$n2$nums" = 112 ] && ok "$mode 31m two parallel news never share a number" || no "$mode 31m two parallel news never share a number" "$(ls "$R/docs/tasks")"
	before=$(find "$R/docs" -type f | wc -l)
	out=$(cd "$R" && nav new task "Broken link" --relates nothing-999)
	has "$mode 31n a broken relates refuses" "$out" 'names no doc'
	out=$(cd "$R" && nav new epic "Down link" --relates task-040)
	has "$mode 31o a downward relates refuses and says why" "$out" 'relates points up'
	out=$(cd "$R" && nav new adr "Shared" --relates 007)
	has "$mode 31p an ambiguous relates refuses" "$out" 'is ambiguous'
	[ "$(find "$R/docs" -type f | wc -l)" = "$before" ] && ok "$mode 31q a refusal writes nothing" || no "$mode 31q a refusal writes nothing"
	out=$(cd "$R" && nav new widget "x")
	has "$mode 31r an unknown kind lists the kinds" "$out" 'one of direction epic task'

	# supersede: both edges, nothing else on the predecessor, idempotent.
	body=$(sed '1,/^---$/d' "$R/docs/adr/0023-own2.md" | sed '1,/^---$/d')
	out=$(cd "$R" && nav supersede adr-0031 --of adr-0025)
	has "$mode 32a the successor gains supersedes" "$out" '^supersede adr-0031  supersedes += adr-0025 (changed)'
	has "$mode 32b the predecessor gains superseded-by" "$out" '^supersede adr-0025  superseded-by += adr-0031 (changed)'
	d=$(cd "$R" && git diff -U0 docs/adr/0025-legacy2.md | grep '^[-+][^-+]')
	[ "$d" = "$(printf '+superseded-by:\n+  - adr-0031')" ] && ok "$mode 32c the predecessor changes by that key only" || no "$mode 32c the predecessor changes by that key only" "$d"
	cp "$R/docs/adr/0025-legacy2.md" "$TMP/p1"; cp "$R/docs/adr/0031-next-adr.md" "$TMP/s1"
	out=$(cd "$R" && nav supersede adr-0031 --of adr-0025)
	has "$mode 32d a second run is unchanged" "$out" 'superseded-by += adr-0031 (unchanged)'
	cmp -s "$TMP/p1" "$R/docs/adr/0025-legacy2.md" && cmp -s "$TMP/s1" "$R/docs/adr/0031-next-adr.md" && ok "$mode 32e idempotent, byte for byte" || no "$mode 32e idempotent, byte for byte"
	out=$(cd "$R" && nav supersede adr-0021 --of adr-0020)
	has "$mode 32f an inline list that has it is unchanged" "$out" 'supersedes += adr-0020 (unchanged)'
	has "$mode 32g the missing backward edge is written" "$out" 'superseded-by += adr-0021 (changed)'
	out=$(cd "$R" && nav check adr-0020)
	hasnt "$mode 32h check no longer reports the disagreement" "$out" 'missing docs/adr/0021-k2.md'
	out=$(cd "$R" && nav docs kp_fn)
	hasnt "$mode 32i the predecessor stays sealed" "$out" 'on-match  docs/adr/0020-k.md'
	out=$(cd "$R" && nav supersede adr-0021 --of adr-0021)
	has "$mode 32j a doc does not supersede itself" "$out" 'does not supersede itself'

	# relate: one upward edge, refused otherwise.
	out=$(cd "$R" && nav relate task-040 --to direction-030)
	has "$mode 33a relate adds an upward edge" "$out" '^relate    task-040  relates += direction-030 (changed)'
	has "$mode 33b inline list grows in place" "$(cat "$R/docs/tasks/040-clean.md")" '^relates: \[epic-030, direction-030\]$'
	out=$(cd "$R" && nav relate task-040 --to direction-030)
	has "$mode 33c relate is idempotent" "$out" '(unchanged)'
	out=$(cd "$R" && nav relate task-040 --to plan-030)
	has "$mode 33d a downward edge refuses" "$out" 'relates points up'
	out=$(cd "$R" && nav relate task-040 --to nothing-1)
	has "$mode 33e a broken edge refuses" "$out" 'names no doc'

	# ledger: the line in ADR 0004 format; status only on a probe close.
	cp "$R/docs/tasks/040-clean.md" "$TMP/t1"
	out=$(cd "$R" && nav ledger done task-040 "seen in use at the fixture")
	out=$(cd "$R" && nav ledger implemented plan-030 "1/1 passed" && nav tree task-031)
	has "$mode 35D tree: state from the ledger" "$out" '^tree      task-031  docs/tasks/031-x.md  · 1 descendants  \[implemented (1/1 plans)\]'
	# A Plan that serves two Tasks counts for both (ADR 0004: every Plan relating to it).
	for n in 090 091; do printf -- '---\nid: task-%s\ntitle: "T%s"\nrelates: [epic-030]\n---\n' $n $n | mkfile "$R/docs/tasks/$n-shared.md"; done
	printf -- '---\nid: plan-090\ntitle: "P90"\nrelates: [task-090, task-091]\n---\n' | mkfile "$R/docs/plans/090-shared.md"
	out=$(cd "$R" && nav ledger implemented plan-090 "1/1 passed" && nav tree epic-030)
	has "$mode 35G tree: a shared Plan counts for its first Task" "$out" 'task-090  T090  \[implemented (1/1 plans)\]'
	has "$mode 35H tree: a shared Plan counts for its last Task" "$out" 'task-091  T091  \[implemented (1/1 plans)\]'
	# A cut tree says what tree takes: a branch or --all, not --type, which it ignores.
	i=100; while [ $i -lt 170 ]; do printf -- '---\nid: plan-%s\ntitle: "P%s"\nrelates: [task-090]\n---\n' $i $i | mkfile "$R/docs/plans/$i-many.md"; i=$((i + 1)); done
	out=$(cd "$R" && nav tree task-090)
	has "$mode 35I a cut tree names a branch and --all" "$out" '^more      +[0-9]* more lines (sp tree <descendant id> reads one branch; --all prints them all)$'
	hasnt "$mode 35J a cut tree never offers --type" "$out" '\-\-type'
	rm "$R"/docs/plans/1[0-6][0-9]-many.md
	rm "$R/docs/tasks/090-shared.md" "$R/docs/tasks/091-shared.md" "$R/docs/plans/090-shared.md"
	# A symlink names a file already indexed: its definitions are not listed twice.
	ln -s util.sh "$R/src/util-link.sh"
	out=$(cd "$R" && nav def build_index)
	[ "$(printf '%s\n' "$out" | grep -c '^def ')" = 1 ] && ok "$mode 35K a symlink adds no second definition" || no "$mode 35K a symlink adds no second definition" "$out"
	rm "$R/src/util-link.sh"
	has "$mode 34a a done line" "$(cat "$R/docs/tasks/LEDGER.md")" '^- task-040 — done 2026-10-09 — effect: seen in use at the fixture$'
	cmp -s "$TMP/t1" "$R/docs/tasks/040-clean.md" && ok "$mode 34b the Task itself is untouched" || no "$mode 34b the Task itself is untouched"
	out=$(cd "$R" && nav ledger not-achieved task-040 "nobody used it")
	has "$mode 34c an effect-not-achieved line" "$(cat "$R/docs/tasks/LEDGER.md")" '^- task-040 — effect not achieved 2026-10-09 — nobody used it$'
	out=$(cd "$R" && nav ledger implemented plan-030 "3/3 passed")
	has "$mode 34d an implemented line" "$(cat "$R/docs/plans/LEDGER.md")" '^- plan-030 — implemented 2026-10-09 — verification: 3/3 passed$'
	out=$(cd "$R" && nav ledger done plan-030 "x")
	has "$mode 34e the wrong kind refuses" "$out" 'done takes a task, and plan-030 is a plan'
	out=$(cd "$R" && nav ledger reconcile probe-b "found and fixed")
	has "$mode 34f a reconcile line" "$(cat "$R/docs/probes/LEDGER.md")" '^- probe-b — reconciled 2026-10-09 — found and fixed$'
	has "$mode 34g and the probe's status" "$(cat "$R/docs/probes/probe-b.md")" '^status: reconciled$'
	out=$(cd "$R" && nav docs Session.refresh)
	hasnt "$mode 34h the reconciled probe is sealed" "$out" 'on-match  docs/probes/probe-b.md'
	out=$(cd "$R" && nav ledger reconcile probe-p "resolved it")
	has "$mode 34i a product probe resolves" "$(cat "$R/docs/product/probes/LEDGER.md")" '^probe-p — resolved 2026-10-09 — outcome: resolved it$'
	has "$mode 34j its status" "$(cat "$R/docs/product/probes/probe-p.md")" '^status: resolved$'
	out=$(cd "$R" && "$NAV" ledger done task-040 "x" 2>&1)
	has "$mode 34k nav refuses write verbs" "$out" 'run sp ledger'
	contract "$mode 34l contract: new" "$(cd "$R" && nav new task "Contract")"
	migrate_tests
	help_tests
	unset SP_TODAY
}

if "$SP" --help >/dev/null 2>&1 && SP_CTAGS= sh -c 'for d in $(echo "$PATH" | tr : " ") /opt/homebrew/bin /usr/local/bin; do "$d/ctags" --version 2>/dev/null | grep -q "Universal Ctags" && exit 0; done; exit 1'; then
	run_mode ctags ""
	run_mode noyq "" none
	run_mode nomdq "" "" none
else
	echo "== mode: ctags skipped (Universal Ctags not found)"
fi
run_mode grep none
log_tests

echo "$pass passed, $fails failed"
[ "$fails" -eq 0 ]
