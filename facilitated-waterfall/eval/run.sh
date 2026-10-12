#!/bin/sh
# Task 028: the small-model suite. The user drives every session in Claude Code;
# this script never starts one and never calls a model (task-028 Amendment):
#   prepare  makes one run dir per cell, each with its own /tmp copy of a workspace
#            (fixture/ by default) and prompt.txt, the one line to type
#   (you)    open a Claude Code session in the cell's ws/ on its model, type the
#            line, take each recommended answer, quit when the skill is done
#   judge    copies each driven session's transcript in and judges it with
#            extract.py, then prints the report
# Never runs against a live repo: --fixture takes a throwaway clone.
#
# usage: run.sh prepare [--models opus] [--scenario S1,..] [--runs 3]
#                       [--out DIR] [--fixture DIR --scenarios FILE]
#        run.sh judge [--out DIR] [CELL [TRANSCRIPT]]
#        run.sh report [--out DIR]
#
# --scenarios is a sh file setting BUG, S2_TRIGGER, S3_TRIGGER, S4_CHANGE, S4_ADR and
# S5_PROBE for that workspace; unset ones keep fixture/'s values.
#
# Models name the cell only (opus by default, or any name): you pick the model in
# the session. S6 is S3 with sp unreachable from the session. prepare keeps a run dir that
# exists, so it never clobbers a driven session. judge without a CELL judges every
# driven cell that has no verdict; with a CELL it judges that one again, from
# TRANSCRIPT if given, else from the newest session Claude Code kept for its ws/.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
MODELS=opus SCEN=S1,S2,S3,S4,S5,S6 RUNS=3 OUT=/tmp/sp-eval
PROJECTS=${EVAL_PROJECTS:-$HOME/.claude/projects}
FIXTURE=${EVAL_FIXTURE:-$HERE/fixture} SCENARIOS=${EVAL_SCENARIOS:-}

die() { echo "run.sh: $*" >&2; exit 2; }
CMD=${1:-}
case $CMD in
prepare | judge | report) shift ;;
-h | --help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
*) die "no step '$CMD': run.sh prepare | judge | report (run.sh --help)" ;;
esac
ARGS=
while [ $# -gt 0 ]; do
	case $1 in
	--models) MODELS=$2; shift ;;
	--scenario) SCEN=$2; shift ;;
	--runs) RUNS=$2; shift ;;
	--out) OUT=$2; shift ;;
	--fixture) FIXTURE=$(cd "$2" && pwd); shift ;;
	--scenarios) SCENARIOS=$(cd "$(dirname "$2")" && pwd)/$(basename "$2"); shift ;;
	-*) die "unknown argument '$1': run.sh --help" ;;
	*) ARGS="$ARGS $1" ;;
	esac
	shift
done

BUG='src/tally/ledger.py: Ledger.balance(upto) leaves out entries dated on the upto day itself'
S2_TRIGGER='direction-002 tally'
S3_TRIGGER='break direction-003 down into Tasks'
S4_CHANGE='adr-0002 must be replaced: a 2.5% card fee now applies to amounts, so an amount needs sub-cent precision until it is rounded once at the end; store amounts as Decimal'
S4_ADR=adr-0002
S5_PROBE=probe-2026-10-01-balance-off-by-a-cent-on-rounding
if [ -n "$SCENARIOS" ]; then [ -f "$SCENARIOS" ] || die "no scenarios file $SCENARIOS"; . "$SCENARIOS"; fi

scenario() { # S → PROMPT
	case $1 in
	S1) PROMPT="/facilitated-waterfall:bottom-up $BUG" ;;
	S2) PROMPT="/facilitated-waterfall:bottom-up $S2_TRIGGER" ;;
	S3 | S6) PROMPT="/facilitated-waterfall:top-down $S3_TRIGGER" ;;
	S4) PROMPT="/facilitated-waterfall:design $S4_CHANGE" ;;
	S5) PROMPT="/facilitated-waterfall:bottom-up resume $S5_PROBE and reconcile it" ;;
	*) die "no scenario '$1' (S1..S6)" ;;
	esac
}

skills_sum() { # D17 and the Risk: a run must not change the skills it is judged by
	(cd "$REPO" && find facilitated-waterfall product-waterfall general-usage -type f \
		! -path '*/eval/*' -exec cksum {} + | sort | cksum)
}

cells() { # the matrix, one "S model n" per line
	for s in $(echo "$SCEN" | tr , ' '); do
		for m in $(echo "$MODELS" | tr , ' '); do
			i=1
			while [ "$i" -le "$RUNS" ]; do echo "$s $m $i"; i=$((i + 1)); done
		done
	done
}

prepare_one() { # "S model n": the run dir, the workspace copy, prompt.txt
	set -- $1
	d=$OUT/$1-$2-$3
	[ -e "$d" ] && { echo "$1 $2-$3  kept  $d/ws"; return 0; }
	mkdir -p "$d"
	# A clone keeps its history; the bare fixture gets one commit. sp's state is
	# dropped, so every run starts cold. pristine/ keeps the docs as they were.
	cp -R "$FIXTURE" "$d/ws"
	if [ -d "$d/ws/.git" ]; then rm -rf "$d/ws/.git/nav"; else
		(cd "$d/ws" && git init -q && git add -A &&
			git -c user.name=eval -c user.email=eval@local commit -qm fixture)
	fi
	mkdir "$d/pristine"
	cp -R "$d/ws/docs" "$d/pristine/"
	find "$d/ws" -maxdepth 1 -name '*.md' -exec cp {} "$d/pristine/" \;
	"$HERE/../scripts/sp" -C "$d/ws" check --all >"$d/check-before.txt" 2>&1 || :
	rm -rf "$d/ws/.git/nav"
	printf '{"fixture": "%s", "s4_adr": "%s", "s5_probe": "%s"}\n' \
		"$FIXTURE" "$S4_ADR" "$S5_PROBE" >"$d/meta.json"
	scenario "$1"
	echo "$PROMPT" >"$d/prompt.txt"
	echo "$1 $2-$3  made  $d/ws"
}

transcript() { # run dir → the newest session Claude Code kept for its ws/
	ws=$(cd "$1/ws" && pwd -P)
	dir=$PROJECTS/$(printf %s "$ws" | sed 's/[^A-Za-z0-9]/-/g')
	[ -d "$dir" ] && ls -t "$dir"/*.jsonl 2>/dev/null | head -1
}

judge_one() { # run dir [transcript]
	d=$1 cell=$(basename "$1")
	t=${2:-$(transcript "$d" || :)}
	[ -n "$t" ] || { echo "$cell  not driven yet: $d/ws"; return 0; }
	[ -f "$t" ] || die "no transcript $t"
	cp "$t" "$d/transcript.jsonl"
	echo "$t" >"$d/transcript.src"
	python3 -I "$HERE/extract.py" "${cell%%-*}" "$d"
}

case $CMD in
report)
	exec python3 -I "$HERE/extract.py" --report "$OUT" ;;
prepare)
	[ -d "$FIXTURE/docs" ] || die "no docs/ in $FIXTURE"
	mkdir -p "$OUT"
	[ -f "$OUT/skills.sum" ] || skills_sum >"$OUT/skills.sum"
	echo "prepare · $OUT · from $FIXTURE · no model is called"
	cells | while read -r c; do prepare_one "$c"; done
	echo "next      in each ws/: a Claude Code session on that cell's model, type its prompt.txt,"
	echo "          take each recommended answer; S6 with sp unreachable; then run.sh judge --out $OUT"
	;;
judge)
	[ -f "$OUT/skills.sum" ] || die "nothing prepared under $OUT: run.sh prepare --out $OUT"
	set -- $ARGS
	if [ $# -gt 0 ]; then
		[ -d "$OUT/$1/ws" ] || die "no prepared cell $OUT/$1"
		judge_one "$OUT/$1" "${2:-}"
	else
		for d in "$OUT"/S[1-6]-*; do
			if [ -d "$d/ws" ] && [ ! -f "$d/verdict.json" ]; then judge_one "$d"; fi
		done
	fi
	[ "$(skills_sum)" = "$(cat "$OUT/skills.sum")" ] ||
		echo "tainted: the skills changed since prepare" | tee "$OUT/TAINTED"
	python3 -I "$HERE/extract.py" --report "$OUT"
	;;
esac
