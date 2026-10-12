"""Tests for extract.py: hand-made transcripts over real fixture copies, no model.

usage: python3 -I test_extract.py

Each scenario has one run that passes every check, and one case per check that
must fail that check. Tool outputs come from running the real `sp` in the copy.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = os.path.join(HERE, "fixture")
SP = os.path.realpath(os.path.join(HERE, "..", "scripts", "sp"))
EXTRACT = os.environ.get("EVAL_EXTRACT") or os.path.join(HERE, "extract.py")
TMP = tempfile.mkdtemp(prefix="sp-eval-test.")
BIN = os.path.join(TMP, "bin")
os.makedirs(BIN)
os.symlink(SP, os.path.join(BIN, "sp"))
PID = "probe-2026-10-01-balance-off-by-a-cent-on-rounding"
PROBE = f"docs/probes/{PID}.md"
FAILS = []
PASSES = 0


MESSY_TASK = ("---\nid: docs/tasks/009-messy.md\ntitle: \"Messy\"\ncreated: 2026-09-01\n"
              "relates:\n  - task-099\n---\n\n# Task 009: Messy\n")


class Run:
    """A run dir as run.sh makes it. messy: the workspace starts malformed, like an
    unmigrated clone (a path id on the S4 target, a doc with a broken link)."""

    def __init__(self, name, messy=False):
        self.dir = os.path.join(TMP, name)
        self.ws = os.path.join(self.dir, "ws")
        shutil.copytree(FIXTURE, self.ws)
        if messy:
            open(os.path.join(self.ws, "docs/tasks/009-messy.md"), "w").write(MESSY_TASK)
            a2 = os.path.join(self.ws, "docs/adr/0002-amounts-are-integer-cents.md")
            text = open(a2).read()
            open(a2, "w").write(text.replace(
                "id: adr-0002", "id: docs/adr/0002-amounts-are-integer-cents.md"))
        shutil.copytree(self.ws, os.path.join(self.dir, "pristine"))
        g = ["git", "-C", self.ws, "-c", "user.name=eval", "-c", "user.email=eval@local"]
        subprocess.run(g[:3] + ["init", "-q"], check=True)
        subprocess.run(g[:3] + ["add", "-A"], check=True)
        subprocess.run(g + ["commit", "-qm", "fixture"], check=True)
        r = subprocess.run([SP, "-C", self.ws, "check", "--all"], capture_output=True, text=True)
        open(os.path.join(self.dir, "check-before.txt"), "w").write(r.stdout + r.stderr)
        shutil.rmtree(os.path.join(self.ws, ".git", "nav"), ignore_errors=True)
        json.dump({"s4_adr": "adr-0002", "s5_probe": PID}, open(os.path.join(self.dir, "meta.json"), "w"))
        self.events, self.n = [], 0

    def call(self, name, inp, out="", result=None):
        """result: the entry's toolUseResult, as Claude Code records it."""
        self.n += 1
        tid = f"t{self.n}"
        self.events.append({"type": "assistant", "message": {"content": [
            {"type": "tool_use", "id": tid, "name": name, "input": inp}]}})
        u = {"type": "user", "message": {"content": [
            {"type": "tool_result", "tool_use_id": tid, "content": out}]}}
        if result is not None:
            u["toolUseResult"] = result
        self.events.append(u)
        return self

    def bash(self, cmd):
        env = dict(os.environ, PATH=BIN + os.pathsep + os.environ["PATH"])
        r = subprocess.run(cmd, shell=True, cwd=self.ws, env=env, capture_output=True, text=True)
        return self.call("Bash", {"command": cmd}, r.stdout + r.stderr)

    def read(self, path, **kw):
        out = open(os.path.join(self.ws, path)).read()
        return self.call("Read", dict(file_path=os.path.join(self.ws, path), **kw), out)

    def write(self, path, content):
        p = os.path.join(self.ws, path)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        old = open(p).read() if os.path.exists(p) else None
        open(p, "w").write(content)
        return self.call("Write", {"file_path": p, "content": content}, "ok", {
            "type": "update" if old is not None else "create", "filePath": p,
            "content": content, "originalFile": old})

    def edit(self, path, old, new):
        p = os.path.join(self.ws, path)
        text = open(p).read()
        assert old in text, (path, old)
        open(p, "w").write(text.replace(old, new, 1))
        return self.call("Edit", {"file_path": p, "old_string": old, "new_string": new}, "ok")

    def judge(self, scen, end="text"):
        """The session as the user left it (an interactive transcript: no result
        event). end: "text" (the model answered), "api_error" (it ended on an API
        error), "tool" (stopped mid-turn, a tool call with no answer after it)."""
        if end == "text":
            self.events.append({"type": "assistant", "message": {"content": [
                {"type": "text", "text": "Done."}]}})
        elif end == "api_error":
            self.events.append({"type": "assistant", "isApiErrorMessage": True, "message": {
                "content": [{"type": "text", "text": "API Error: 529 overloaded"}]}})
        elif end == "tool":
            self.events.append({"type": "assistant", "message": {"content": [
                {"type": "tool_use", "id": "dangling", "name": "Bash", "input": {"command": "ls"}}]}})
        with open(os.path.join(self.dir, "transcript.jsonl"), "w") as f:
            for e in self.events:
                f.write(json.dumps(e) + "\n")
        subprocess.run([sys.executable, "-I", EXTRACT, scen, self.dir],
                       check=True, capture_output=True)
        return json.load(open(os.path.join(self.dir, "verdict.json")))


def expect_pass(label, v):
    global PASSES
    bad = [c for c in v["checks"] if not c["ok"]]
    if bad:
        FAILS.append(f"{label}: expected all pass, got {[(c['name'], c['detail']) for c in bad]}")
    else:
        PASSES += 1
        print(f"PASS  {label}")


def expect_fail(label, v, check):
    global PASSES
    c = next((c for c in v["checks"] if c["name"] == check), None)
    if c is None or c["ok"] or v["pass"]:
        FAILS.append(f"{label}: expected '{check}' to fail, got {c}")
    else:
        PASSES += 1
        print(f"PASS  {label}")


def probe_new(r, title="balance drops the upto day"):
    return r.bash(f'sp new probe "{title}" --relates task-002,adr-0002')


def probe_path(r):
    return [p for p in os.listdir(os.path.join(r.ws, "docs/probes"))
            if p.startswith("probe-") and PID not in p][0]


def governing(r):
    p = "docs/probes/" + probe_path(r)
    return r.edit(p, "## Governing docs\n", "## Governing docs\n\n- task-002: balance(upto)"
                  " sums every entry.\n\nRead depth: task-002 — FULL; adr-0002 — PARTIAL\n")


# ---- S1 -----------------------------------------------------------------------
r = Run("s1-pass")
r.bash("test -x ~/.agent-skills/facilitated-waterfall/scripts/sp && echo yes")
r.bash("sp file src/tally/ledger.py")
r.read("docs/tasks/002-balance-up-to-a-day.md")
probe_new(r)
governing(r)
expect_pass("S1 pass", r.judge("S1"))

r = Run("s1-read-first")
r.read("docs/tasks/002-balance-up-to-a-day.md")
r.bash("sp file src/tally/ledger.py")
probe_new(r)
governing(r)
expect_fail("S1 doc read before sp file", r.judge("S1"), "sp file before any doc read")

r = Run("s1-cat-first")
r.bash("cat docs/tasks/002-balance-up-to-a-day.md | head -20")
r.bash("$SP file src/tally/ledger.py")
expect_fail("S1 bounded cat still counts as a read", r.judge("S1"), "sp file before any doc read")

r = Run("s1-write-probe")
r.bash("sp file src/tally/ledger.py")
r.write("docs/probes/probe-2026-10-09-x.md",
        "---\nid: probe-2026-10-09-x\ntitle: \"x\"\ncreated: 2026-10-09\nstatus: open\n"
        "relates:\n  - task-002\n---\n\n# Probe: x\n\n## Governing docs\n\n- task-002 — FULL\n")
expect_fail("S1 probe by Write", r.judge("S1"), "probe made by sp new probe")

# F60: one Write that fills sp's skeleton and keeps its frontmatter byte for byte.
r = Run("s1-fill-by-write")
r.bash("sp file src/tally/ledger.py")
probe_new(r)
p = "docs/probes/" + probe_path(r)
r.write(p, open(os.path.join(r.ws, p)).read().replace("## Governing docs\n",
        "## Governing docs\n\n- task-002: balance(upto) sums every entry.\n\n"
        "Read depth: task-002 — FULL\n"))
expect_pass("S1 probe filled by one Write, frontmatter kept", r.judge("S1"))

r = Run("s1-overwrite-frontmatter")
r.bash("sp file src/tally/ledger.py")
probe_new(r)
p = "docs/probes/" + probe_path(r)
r.write(p, open(os.path.join(r.ws, p)).read().replace("  - adr-0002\n",
        "  - adr-0002\n  - plan-001\n").replace("## Governing docs\n",
        "## Governing docs\n\n- task-002 — FULL\n"))
expect_fail("S1 Write changes sp's frontmatter", r.judge("S1"), "probe made by sp new probe")

r = Run("s1-overwrite-unknown")
r.bash("sp file src/tally/ledger.py")
probe_new(r)
p = "docs/probes/" + probe_path(r)
body = open(os.path.join(r.ws, p)).read().replace("## Governing docs\n",
        "## Governing docs\n\n- task-002 — FULL\n")
open(os.path.join(r.ws, p), "w").write(body)
r.call("Write", {"file_path": os.path.join(r.ws, p), "content": body}, "ok")
expect_fail("S1 Write with no originalFile counts as hand-written", r.judge("S1"),
            "probe made by sp new probe")

r = Run("s1-no-governing")
r.bash("sp file src/tally/ledger.py")
probe_new(r)
expect_fail("S1 empty Governing docs", r.judge("S1"), "governing docs carry trace and read depth")

r = Run("s1-breaking")
r.bash("sp file src/tally/ledger.py")
probe_new(r)
governing(r)
r.edit("docs/tasks/002-balance-up-to-a-day.md", "  - epic-001\n", "  - epic-001\n  - task-099\n")
expect_fail("S1 broken link written", r.judge("S1"), "sp check clean on everything written")

# ---- S2 -----------------------------------------------------------------------
D2 = "docs/directions/002-tally-reports-by-month.md"
r = Run("s2-pass")
r.bash("sp tree direction-002")
r.bash("sp show direction-002 Constraints")
r.read(D2, offset=1, limit=40)
probe_new(r, "monthly report")
expect_pass("S2 pass", r.judge("S2"))

r = Run("s2-late-tree")
r.call("Glob", {"pattern": "docs/**/*.md"}, "")
r.call("Grep", {"pattern": "direction-002"}, "")
r.read("docs/epics/002-monthly-report.md")
r.bash("sp tree direction-002")
expect_fail("S2 tree after 3 calls", r.judge("S2"), "sp tree or trace within the first 3 calls")

r = Run("s2-long")
r.bash("sp trace direction-002")
for h in ("Problem", "Appetite", "Constraints", "Risk", "Success signal"):
    r.bash(f'sp show direction-002 "{h}"')
probe_new(r, "monthly report")
expect_fail("S2 5 calls before the probe", r.judge("S2"), "orientation under 5 calls")

r = Run("s2-no-probe")
r.bash("sp tree direction-002")
for h in ("Problem", "Appetite", "Constraints", "Risk", "Success signal"):
    r.bash(f'sp show direction-002 "{h}"')
expect_fail("S2 no probe, 6 calls", r.judge("S2"), "orientation under 5 calls")

r = Run("s2-stops-to-ask")
r.bash("sp tree direction-002")
expect_pass("S2 orients then stops to ask", r.judge("S2"))

r = Run("s2-cat")
r.bash("sp tree direction-002")
r.bash(f"cat {D2}")
probe_new(r, "monthly report")
expect_fail("S2 cat of a big doc", r.judge("S2"), "no whole read of a doc over 2k tok")

r = Run("s2-read")
r.bash("sp tree direction-002")
r.read(D2)
probe_new(r, "monthly report")
expect_fail("S2 unbounded Read of a big doc", r.judge("S2"), "no whole read of a doc over 2k tok")

r = Run("s2-small-whole")
r.bash("sp tree direction-002")
r.read("docs/epics/002-monthly-report.md")
r.bash(f"cat {D2} | head -40")
probe_new(r, "monthly report")
expect_pass("S2 whole small doc and bounded big doc are fine", r.judge("S2"))


# ---- S3 -----------------------------------------------------------------------
def breakdown(r):
    r.bash('sp new epic "Statement Import" --relates direction-003')
    r.bash('sp new task "CSV Lines Parse to Cents" --relates epic-003')
    r.bash('sp new task "Duplicates Are Skipped" --relates epic-003')
    return r


TASK = ("---\nid: task-{n}\ntitle: \"Hand\"\ncreated: 2026-10-09\nintent: x.\n"
        "relates:\n  - epic-003\n---\n\n# Task {n}: Hand\n\n## Goal\n")

r = breakdown(Run("s3-pass"))
r.edit("docs/tasks/003-csv-lines-parse-to-cents.md", "## Goal\n", "## Goal\n\nParse.\n")
expect_pass("S3 pass", r.judge("S3"))

r = Run("s3-no-task")
r.bash('sp new epic "Statement Import" --relates direction-003')
expect_fail("S3 no Task", r.judge("S3"), "made at least one Task")

r = breakdown(Run("s3-hand"))
r.write("docs/tasks/005-hand.md", TASK.format(n="005"))
expect_fail("S3 Task by Write", r.judge("S3"), "every artifact made by sp new")

r = Run("s3-gap")
r.bash('sp new epic "Statement Import" --relates direction-003')
r.write("docs/tasks/004-hand.md", TASK.format(n="004"))
expect_fail("S3 number gap", r.judge("S3"), "numbers contiguous, none shared")

r = breakdown(Run("s3-bare"))
r.edit("docs/tasks/004-duplicates-are-skipped.md", "  - epic-003\n", '  - epic-003\n  - "003"\n')
expect_fail("S3 bare id", r.judge("S3"), "all references kind-NNN")

r = breakdown(Run("s3-broken"))
r.edit("docs/tasks/004-duplicates-are-skipped.md", "  - epic-003\n", "  - epic-003\n  - task-099\n")
expect_fail("S3 broken link", r.judge("S3"), "sp check clean")

r = breakdown(Run("s3-messy-pass", messy=True))
expect_pass("S3 on a messy workspace: old breaking is not the run's", r.judge("S3"))

r = breakdown(Run("s3-messy-worse", messy=True))
r.edit("docs/tasks/009-messy.md", "  - task-099\n", "  - task-099\n  - task-098\n")
expect_fail("S3 on a messy workspace: a doc made worse", r.judge("S3"), "sp check clean")

# ---- S4 -----------------------------------------------------------------------
A2 = "docs/adr/0002-amounts-are-integer-cents.md"
r = Run("s4-pass")
r.bash('sp new adr "Amounts Are Decimal" --relates task-001')
r.bash("sp supersede adr-0003 --of adr-0002")
r.bash("sp supersede adr-0003 --of adr-0002")
expect_pass("S4 pass (a repeat that changes nothing is fine)", r.judge("S4"))

r = Run("s4-messy", messy=True)
r.bash('sp new adr "Amounts Are Decimal" --relates task-001')
r.bash("sp supersede adr-0003 --of adr-0002")
expect_pass("S4 on a messy workspace (target id is a path)", r.judge("S4"))

r = Run("s4-two")
r.bash('sp new adr "Amounts Are Decimal" --relates task-001')
r.bash("sp supersede adr-0003 --of adr-0002")
r.bash("sp supersede adr-0003 --of adr-0001")
expect_fail("S4 two supersessions", r.judge("S4"), "one sp supersede")

r = Run("s4-hand")
r.bash('sp new adr "Amounts Are Decimal" --relates task-001')
r.edit("docs/adr/0003-amounts-are-decimal.md", "  - task-001\n", "  - task-001\nsupersedes:\n  - adr-0002\n")
v = r.judge("S4")
expect_fail("S4 hand edge: one edge only", v, "both edges present")
expect_fail("S4 hand edge: disagreement", v, "0 supersession disagreements")
expect_fail("S4 hand edge: no sp supersede", v, "one sp supersede")

r = Run("s4-body")
r.bash('sp new adr "Amounts Are Decimal" --relates task-001')
r.bash("sp supersede adr-0003 --of adr-0002")
r.edit(A2, "Sums are exact.", "Sums are exact. Superseded.")
expect_fail("S4 predecessor body edited", r.judge("S4"), "predecessor body byte-identical")

# ---- S5 -----------------------------------------------------------------------
RESUMED = ("**2026-10-09 — Resumed.** Read depth:\n- task-002 — FULL\n- adr-0002 — NOT_READ\n\n"
           "**2026-10-01 — Situate.**")
r = Run("s5-pass")
r.edit(PROBE, "**2026-10-01 — Situate.**", RESUMED)
r.edit(PROBE, "## Reconciliation\n", "## Reconciliation\n\n- Deposit: nothing durable.\n")
r.bash(f'sp ledger reconcile {PID} "a missing entry, not rounding"')
expect_pass("S5 pass", r.judge("S5"))

r = Run("s5-late-resume")
r.edit(PROBE, "## Reconciliation\n", "## Reconciliation\n\n- Deposit: nothing durable.\n")
r.edit(PROBE, "**2026-10-01 — Situate.**", RESUMED)
r.bash(f'sp ledger reconcile {PID} "a missing entry"')
expect_fail("S5 Resumed not first", r.judge("S5"), "Resumed block is the first change")

r = Run("s5-hand")
r.edit(PROBE, "**2026-10-01 — Situate.**", RESUMED)
r.write("docs/probes/LEDGER.md", f"- {PID} reconciled\n")
v = r.judge("S5")
expect_fail("S5 hand ledger: no sp call", v, "sp ledger reconcile ran")
expect_fail("S5 hand ledger: format", v, "ledger line format")
expect_fail("S5 hand ledger: status", v, "probe status reconciled")

# ---- S6 -----------------------------------------------------------------------
EPIC = ("---\nid: epic-003\ntitle: \"Statement Import\"\ncreated: 2026-10-09\nintent: x.\n"
        "relates:\n  - direction-003\n---\n\n# Epic 003: Statement Import\n")


def cold(r):
    r.bash("test -x ~/.agent-skills-absent/sp || echo missing")
    r.write("docs/epics/003-statement-import.md", EPIC)
    r.write("docs/tasks/003-hand.md", TASK.format(n="003"))
    return r


expect_pass("S6 pass", cold(Run("s6-pass")).judge("S6"))
expect_fail("S6 stopped mid-turn", cold(Run("s6-turns")).judge("S6", "tool"), "run completed")
expect_fail("S6 API error", cold(Run("s6-api")).judge("S6", "api_error"), "run completed")
v = cold(Run("s6-meta")).judge("S6")
if "cost" in v or "turns" in v:
    FAILS.append(f"verdict: no cost or turns from an interactive session, got {v}")
else:
    PASSES += 1
    print("PASS  verdict: no cost or turns from an interactive session")

r = Run("s6-no-task")
r.write("docs/epics/003-statement-import.md", EPIC)
expect_fail("S6 no Task", r.judge("S6"), "made at least one Task")

r = cold(Run("s6-sp"))
r.bash("sp tree direction-003")
expect_fail("S6 sp answered", r.judge("S6"), "no sp answered")

# F62: sp answered from the installed path, so the session was not cold. That is a
# setup gap, not a model FAIL, and it is kept out of the 2-of-3 count.
r = cold(Run("s6-not-cold"))
r.call("Bash", {"command": "SP=~/.agent-skills/facilitated-waterfall/scripts/sp; $SP tree direction-003"},
       "sp tree direction-003 · /tmp/ws · awk · regenerated\ntree      direction-003\n")
v = r.judge("S6")
if v.get("setup") and not v["pass"] and v["failed"].startswith("setup"):
    PASSES += 1
    print("PASS  S6 not cold is a setup gap")
else:
    FAILS.append(f"S6 not cold: expected a setup verdict, got {v}")

r = Run("s6-broken")
r.write("docs/epics/003-statement-import.md", EPIC)
r.write("docs/tasks/003-hand.md", TASK.format(n="003").replace("  - epic-003\n", "  - epic-009\n"))
expect_fail("S6 broken link", r.judge("S6"), "sp check afterwards: no new breaking")

for f in FAILS:
    print("FAIL  " + f)
print(f"{PASSES} passed, {len(FAILS)} failed")
shutil.rmtree(TMP) if not os.environ.get("KEEP") else print(TMP)
sys.exit(1 if FAILS else 0)
