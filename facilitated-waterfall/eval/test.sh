#!/bin/sh
# Tests for the eval suite itself, spending no model calls: the extractor's checks
# (test_extract.py), the runner's prepare, judge and report, and the fixture's shape.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
SP=$HERE/../scripts/sp
pass=0 fail=0
ok() { pass=$((pass + 1)); echo "PASS  $1"; }
no() { fail=$((fail + 1)); echo "FAIL  $1"; }
T=$(mktemp -d /tmp/sp-eval-test.XXXXXX)
trap 'rm -rf "$T"' EXIT

python3 -I "$HERE/test_extract.py" >"$T/x" 2>&1
tail -1 "$T/x" | grep -q ', 0 failed$' && ok "extractor: $(tail -1 "$T/x")" || { cat "$T/x"; no "extractor"; }

cp -R "$HERE/fixture" "$T/fx"
(cd "$T/fx" && git init -q && git add -A && git -c user.name=e -c user.email=e@l commit -qm f)
"$SP" -C "$T/fx" check --all | grep -q ' 0 breaking in 0 docs · 0 drift' && ok "fixture: sp check --all clean" || no "fixture: sp check --all clean"
[ "$(wc -c <"$HERE/fixture/docs/directions/002-tally-reports-by-month.md")" -gt 8000 ] && ok "fixture: direction-002 over 8000 bytes (S2)" || no "fixture: direction-002 over 8000 bytes (S2)"

# prepare, with a claude on PATH that records any call: no model is ever called.
mkdir -p "$T/bin"
printf '#!/bin/sh\ntouch %s/CALLED\nexit 1\n' "$T" >"$T/bin/claude"; chmod +x "$T/bin/claude"
P="env PATH=$T/bin:$PATH EVAL_PROJECTS=$T/projects"
$P "$HERE/run.sh" prepare --models haiku,qwen --scenario S1,S6 --runs 1 --out "$T/out" >"$T/prep" 2>&1
[ "$(grep -c '^S[1-6] .* made ' "$T/prep")" = 4 ] && ok "prepare: 2 scenarios × 2 models × 1 run" || { cat "$T/prep"; no "prepare: 4 cells made"; }
head -1 "$T/prep" | grep -q '^prepare · .* no model is called$' && ok "prepare: summary first" || no "prepare: summary first"
[ ! -e "$T/CALLED" ] && ok "prepare: calls no model" || no "prepare: calls no model"
grep -rqE '(^|[;&|( 	])(exec +)?claude( |$)' "$HERE/run.sh" "$T/out" && no "nothing starts a session (task-028 Amendment)" || ok "nothing starts a session (task-028 Amendment)"
[ "$(cat "$T/out/S1-haiku-1/prompt.txt")" = "/facilitated-waterfall:bottom-up src/tally/ledger.py: Ledger.balance(upto) leaves out entries dated on the upto day itself" ] && ok "prompt.txt: the bare invocation, one line" || no "prompt.txt: the bare invocation, one line"
grep -q '^/facilitated-waterfall:top-down ' "$T/out/S6-qwen-1/prompt.txt" && ok "prompt.txt: S6 is S3's invocation" || no "prompt.txt: S6 is S3's invocation"
grep -q '^S1 haiku-1  made .*/S1-haiku-1/ws$' "$T/prep" && ok "prepare: names each ws/ to open" || no "prepare: names each ws/ to open"
echo driven >"$T/out/S1-haiku-1/ws/mark"
$P "$HERE/run.sh" prepare --models haiku --scenario S1 --runs 1 --out "$T/out" | grep -q '^S1 haiku-1  kept ' && [ -f "$T/out/S1-haiku-1/ws/mark" ] && ok "prepare: keeps a driven cell" || no "prepare: keeps a driven cell"

# judge: finds each session by its ws/ path, as Claude Code names the folder.
$P "$HERE/run.sh" judge --out "$T/out" >"$T/j0" 2>&1
grep -q '^S1-haiku-1  not driven yet: ' "$T/j0" && [ ! -e "$T/out/S1-haiku-1/verdict.json" ] && ok "judge: an undriven cell is not judged" || { cat "$T/j0"; no "judge: an undriven cell is not judged"; }
ws=$(cd "$T/out/S1-haiku-1/ws" && pwd -P)
pd=$T/projects/$(printf %s "$ws" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$pd"
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"old"}]}}' >"$pd/a.jsonl"
touch -t 202601010000 "$pd/a.jsonl"
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"Done."}]}}' >"$pd/b.jsonl"
$P "$HERE/run.sh" judge --out "$T/out" >"$T/j1" 2>&1
grep -q '^S1 S1-haiku-1 ' "$T/j1" && grep -q '/b.jsonl$' "$T/out/S1-haiku-1/transcript.src" && ok "judge: the newest session of that ws/" || { cat "$T/j1"; no "judge: the newest session of that ws/"; }
grep -q '"ended": "ended on an answer"' "$T/out/S1-haiku-1/verdict.json" && ok "judge: verdict says how the session ended" || no "judge: verdict says how the session ended"
grep -q '^eval report · .* 1 cells · 0 pass · 0 FAIL · 1 open$' "$T/j1" && ok "judge: ends with the report; one run is open, not a pass" || { cat "$T/j1"; no "judge: ends with the report"; }
$P "$HERE/run.sh" judge --out "$T/out" S6-qwen-1 "$pd/a.jsonl" >"$T/j2" 2>&1; grep -q '^S6 S6-qwen-1 ' "$T/j2" && grep -q '/a.jsonl$' "$T/out/S6-qwen-1/transcript.src" && ok "judge: a named cell from a named transcript" || no "judge: a named cell from a named transcript"
[ ! -e "$T/out/TAINTED" ] && ok "judge: not tainted while the skills are unchanged" || no "judge: not tainted"
echo changed >"$T/out/skills.sum"
$P "$HERE/run.sh" judge --out "$T/out" >"$T/j3" 2>&1; grep -q '^tainted' "$T/j3" && [ -e "$T/out/TAINTED" ] && ok "judge: tainted when the skills changed since prepare" || no "judge: tainted when the skills changed"
[ ! -e "$T/CALLED" ] && ok "judge: calls no model" || no "judge: calls no model"
"$HERE/run.sh" judge --out "$T/none" >/dev/null 2>&1; [ $? = 2 ] && ok "judge: nothing prepared exits 2" || no "judge: nothing prepared exits 2"
"$HERE/run.sh" --frob >/dev/null 2>&1; [ $? = 2 ] && ok "unknown step exits 2" || no "unknown step exits 2"
"$HERE/run.sh" prepare --frob >/dev/null 2>&1; [ $? = 2 ] && ok "unknown argument exits 2" || no "unknown argument exits 2"

# --report over hand-made verdicts: 2 of 3 passes, 1 of 3 fails.
for r in 1 2 3; do mkdir -p "$T/rep/S1-haiku-$r" "$T/rep/S4-qwen-$r"; done
v() { printf '{"pass": %s, "failed": "%s"}' "$2" "$3" >"$T/rep/$1/verdict.json"; }
v S1-haiku-1 true ""; v S1-haiku-2 false "probe made by sp new probe"; v S1-haiku-3 true ""
v S4-qwen-1 false "one sp supersede"; v S4-qwen-2 false "one sp supersede"; v S4-qwen-3 true ""
mkdir -p "$T/rep/S2-ref-1"; v S2-ref-1 true ""
"$HERE/run.sh" report --out "$T/rep" >"$T/rep.txt"
head -1 "$T/rep.txt" | grep -q '3 cells · 1 pass · 1 FAIL · 1 open$' && ok "report: summary first" || { cat "$T/rep.txt"; no "report: summary first"; }
grep -q '^S1  haiku *pass *✓✗✓' "$T/rep.txt" && ok "report: 2 of 3 passes" || no "report: 2 of 3 passes"
grep -q '^S4  qwen *FAIL *✗✗✓ .*one sp supersede' "$T/rep.txt" && ok "report: 1 of 3 fails, names the check" || no "report: 1 of 3 fails"

[ ! -e "$HOME/.agent-skills/facilitated-waterfall/eval" ] && [ ! -e "$HOME/.agent-skills/facilitated-waterfall/scripts/eval" ] && ok "eval is not under ~/.agent-skills (D17)" || no "eval is not under ~/.agent-skills (D17)"
grep -rqE 'sk-[a-f0-9]{16}' "$HERE" && no "no credential in eval/" || ok "no credential in eval/"

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
