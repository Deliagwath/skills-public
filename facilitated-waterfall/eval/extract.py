"""Judge one eval run from its transcript and the fixture's final state (Task 028).

usage: python3 -I extract.py <scenario> <run dir>

The run dir holds transcript.jsonl (the session the user drove: Claude Code's
.jsonl from ~/.claude/projects/, which run.sh judge copies in), ws/ (the workspace after
the run), pristine/ (its docs before it), check-before.txt (`sp check --all` before
it) and meta.json (the run's targets: s4_adr, s5_probe). Writes verdict.json and
prints one line. Every check is deterministic: tool calls, files, and `sp check`.
A workspace that starts malformed (an unmigrated clone) is judged by what the run
added, never by what was there.
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SP = os.environ.get("EVAL_SP") or os.path.join(HERE, "..", "scripts", "sp")

# A call to sp (or its read alias nav): bare, through a variable, or by path.
SP_CALL = re.compile(
    r"(?<![\w.-])(?:sp|nav|\$\{?SP\}?|\$\{?NAV\}?)[\'\"]?"
    r"(?:\s+-C\s+\S+|\s+--budget\s+\S+|\s+--role\s+\S+)*"
    r"\s+([a-z]+)(?:\s+([a-z][a-z-]*))?"
)
ANSWERED = re.compile(r"(?m)^(?:sp|nav) [a-z]+(?: [^\n·]*)? · ")
DOC_PATH = re.compile(r"(?:^|[\s'\"=/])((?:docs/[^\s'\"`;|&<>()]+\.md)|CONTEXT\.md)")
READERS = {"cat", "less", "more", "bat", "head", "tail", "sed", "awk", "nl"}
BOUNDED = {"head", "tail", "sed", "awk"}
ART_DIR = re.compile(r"^docs/(product/)?(directions|epics|tasks|plans|adr|probes|stories)/[^/]+\.md$")
KIND = {"directions": "direction", "epics": "epic", "tasks": "task", "plans": "plan",
        "adr": "adr", "probes": "probe", "stories": "story"}
LINK_ID = re.compile(
    r"^(?:direction|epic|task|plan|adr|story|product-direction|product-epic)-\d+$"
    r"|^(?:product-)?probe-\d{4}-\d\d-\d\d-[a-z0-9-]+$"
)
LINK_KEYS = ("relates", "supersedes", "superseded-by", "closes")
BIG_DOC = 8000  # bytes, about 2k tokens
COUNTED = {"Bash", "Read", "Grep", "Glob", "Edit", "Write", "MultiEdit", "NotebookEdit"}


# ---- transcript ---------------------------------------------------------------

def load(path):
    """Tool calls with their output, and the session's last assistant entry."""
    calls, by_id, last = [], {}, None
    for line in open(path, errors="replace"):
        try:
            e = json.loads(line)
        except ValueError:
            continue
        t = e.get("type")
        content = (e.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        if t == "assistant":
            last = e
        for b in content:
            if t == "assistant" and b.get("type") == "tool_use":
                c = {"name": b.get("name"), "input": b.get("input") or {}, "output": ""}
                calls.append(c)
                by_id[b.get("id")] = c
            elif t == "user" and b.get("type") == "tool_result":
                c = by_id.get(b.get("tool_use_id"))
                if c is None:
                    continue
                out = b.get("content")
                if isinstance(out, list):
                    out = "\n".join(x.get("text", "") for x in out if isinstance(x, dict))
                c["output"] = out or ""
                c["result"] = e.get("toolUseResult")
    return calls, last


def ended(last):
    """Did the session end on an answer: not an API error, not a dangling tool call?"""
    if last is None:
        return False, "no assistant turn"
    if last.get("isApiErrorMessage"):
        return False, "ended on an API error"
    blocks = last["message"]["content"]
    if not blocks or blocks[-1].get("type") != "text":
        return False, "ended mid-turn, on a tool call"
    return True, "ended on an answer"


def sp_verbs(call):
    """[(verb, arg)] for every sp call in a Bash command, in order."""
    if call["name"] != "Bash":
        return []
    return SP_CALL.findall(call["input"].get("command", ""))


def has_sp(call, verb, arg=None):
    return any(v == verb and (arg is None or a == arg) for v, a in sp_verbs(call))


def segments(cmd):
    """Pipelines of a shell command, each a list of word lists."""
    for chain in re.split(r"\n|;|&&|\|\|", cmd):
        pipe = []
        for seg in chain.split("|"):
            words = seg.split()
            while words and re.match(r"^\w+=", words[0]):
                words = words[1:]
            if words:
                pipe.append(words)
        if pipe:
            yield pipe


def doc_reads(call):
    """[(doc path, bounded)] that this call opens with a reader, not through sp."""
    name, inp = call["name"], call["input"]
    if name == "Read":
        m = DOC_PATH.search(" " + inp.get("file_path", ""))
        if m:
            return [(m.group(1), bool(inp.get("offset") or inp.get("limit")))]
        return []
    if name != "Bash":
        return []
    out = []
    for pipe in segments(inp.get("command", "")):
        progs = [os.path.basename(w[0]) for w in pipe]
        for i, words in enumerate(pipe):
            if progs[i] not in READERS:
                continue
            bounded = progs[i] in BOUNDED or any(p in BOUNDED for p in progs[i + 1:])
            for w in words[1:]:
                m = DOC_PATH.search(" " + w)
                if m:
                    out.append((m.group(1), bounded))
    return out


def counted(calls):
    return [c for c in calls if c["name"] in COUNTED]


# ---- files --------------------------------------------------------------------

def tree(root):
    """The docs a run may write: docs/** and the top-level *.md files."""
    out = {}
    for f in os.listdir(root):
        p = os.path.join(root, f)
        if f.endswith(".md") and os.path.isfile(p):
            out[f] = open(p, "rb").read()
    for d, dirs, files in os.walk(os.path.join(root, "docs")):
        for f in files:
            p = os.path.join(d, f)
            out[os.path.relpath(p, root)] = open(p, "rb").read()
    return out


def is_art(p):
    return bool(ART_DIR.match(p)) and not p.endswith("/LEDGER.md")


def kind_num(p):
    m = ART_DIR.match(p)
    if not m:
        return None, None
    k = KIND[m.group(2)]
    if m.group(1) and k in ("direction", "epic"):
        k = "product-" + k
    n = re.match(r"(\d+)-", os.path.basename(p))
    return k, int(n.group(1)) if n else None


def split_fm(text):
    """(frontmatter lines, body) of a doc; ([], text) when it has none."""
    if not text.startswith("---\n"):
        return [], text
    end = text.find("\n---\n", 4)
    if end < 0:
        return [], text
    return text[4:end].split("\n"), text[end + 5:]


def fm_lists(text):
    """{key: [items]} for list and scalar keys of a doc's frontmatter."""
    out, key = {}, None
    for line in split_fm(text)[0]:
        m = re.match(r"^([\w-]+):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            if val.startswith("["):
                out[key] = [x.strip().strip("'\"") for x in val.strip("[]").split(",") if x.strip()]
            elif val:
                out[key] = [val.strip("'\"")]
            else:
                out[key] = []
        elif key and re.match(r"^\s+-\s+", line):
            out[key].append(re.sub(r"^\s+-\s+", "", line).strip().strip("'\""))
    return out


def section(text, heading):
    m = re.search(r"(?ms)^## " + re.escape(heading) + r"\s*\n(.*?)(?=^## |\Z)", text)
    return m.group(1) if m else ""


def sp(ws, *args):
    r = subprocess.run([SP, "-C", ws] + list(args), capture_output=True, text=True)
    return r.stdout + r.stderr


BREAK = re.compile(r"(?m)^break\s+(\S+)\s+(\S+)\s.*$")


def breaks(text):
    """{path: breaking count} and the set of supersession problem lines."""
    counts = {}
    for m in BREAK.finditer(text):
        counts[m.group(1)] = counts.get(m.group(1), 0) + 1
    sup = set(re.findall(r"(?m)^(?:break|drift)\s+\S+\s+(?:supersedes|superseded-by)\s.*$", text))
    return counts, sup


# ---- the judge ----------------------------------------------------------------

class Judge:
    def __init__(self, run):
        self.run = run
        self.ws = os.path.join(run, "ws")
        self.calls, self.last = load(os.path.join(run, "transcript.jsonl"))
        self.before = tree(os.path.join(run, "pristine"))
        self.after = tree(self.ws)
        self.checks = []
        self.setup = ""
        mp = os.path.join(run, "meta.json")
        self.meta = json.load(open(mp)) if os.path.exists(mp) else {}
        bp = os.path.join(run, "check-before.txt")
        self.check_before = breaks(open(bp).read() if os.path.exists(bp) else "")
        self._after = None

    def check_after(self):
        if self._after is None:
            self._after = breaks(sp(self.ws, "check", "--all"))
        return self._after

    def find(self, kid):
        """The path of an artifact id: frontmatter id, probe stem, or kind + number."""
        for p in sorted(set(self.before) | set(self.after)):
            if not is_art(p):
                continue
            t = (self.before.get(p) or self.after.get(p)).decode("utf-8", "replace")
            if fm_lists(t).get("id") == [kid] or os.path.basename(p) == kid + ".md":
                return p
        m = re.match(r"^([a-z-]+)-(\d+)$", kid)
        if m:
            for p in sorted(self.before):
                if is_art(p) and kind_num(p) == (m.group(1), int(m.group(2))):
                    return p
        return "docs/?/" + kid

    def check(self, name, ok, detail=""):
        self.checks.append({"name": name, "ok": bool(ok), "detail": detail})

    def text(self, p):
        return self.after.get(p, b"").decode("utf-8", "replace")

    def new_arts(self, kind=None):
        return sorted(p for p in self.after if is_art(p) and p not in self.before
                      and (kind is None or kind_num(p)[0] == kind))

    def sp_new_paths(self):
        out = set()
        for c in self.calls:
            if has_sp(c, "new"):
                out.update(re.findall(r"(?m)^new\s+\S+\s+(\S+\.md)\s*$", c["output"]))
        return out

    def first(self, pred):
        for i, c in enumerate(self.calls):
            if pred(c):
                return i
        return None

    def check_clean(self, name):
        """No doc has more breaking problems than before the run."""
        old, new = self.check_before[0], self.check_after()[0]
        bad = [f"{p}: {old.get(p, 0)} → {n}" for p, n in sorted(new.items()) if n > old.get(p, 0)]
        self.check(name, not bad, "; ".join(bad[:5]) or
                   f"no doc gained a breaking problem ({sum(new.values())} before and after)")

    # S1: bottom-up from a one-line bug naming a code path
    def S1(self):
        f = self.first(lambda c: has_sp(c, "file"))
        r = self.first(lambda c: doc_reads(c))
        self.check("sp file before any doc read", f is not None and (r is None or f < r),
                   f"sp file at call {f}, first doc read at call {r}")
        probes = [p for p in self.sp_new_paths() if p.startswith("docs/probes/")]
        made = [p for p in probes if p in self.after]
        # A Write over the probe may fill sp's skeleton; it must not change the
        # frontmatter sp wrote (originalFile is the file before the Write; F60).
        written = [c for c in self.calls if c["name"] == "Write"
                   and any(c["input"].get("file_path", "").endswith(p) for p in made)]
        hand = [c for c in written if not isinstance(c.get("result"), dict)
                or split_fm(c["result"].get("originalFile") or "")[0]
                != split_fm(c["input"].get("content", ""))[0]]
        self.check("probe made by sp new probe", made and not hand,
                   f"sp new probe → {made or 'none'}; Write over it: {len(written)}, "
                   f"frontmatter changed by hand: {len(hand)}")
        gov = section(self.text(made[0]), "Governing docs") if made else ""
        self.check("governing docs carry trace and read depth",
                   re.search(r"\b(task|epic|direction|plan|adr|story)-\d+|docs/[a-z/]+/\d+-", gov)
                   and re.search(r"\b(FULL|PARTIAL|NOT_READ)\b", gov),
                   f"{len(gov)} chars in Governing docs")
        self.check_clean("sp check clean on everything written")

    # S2: bottom-up from a doc-shaped trigger
    def S2(self):
        cc = counted(self.calls)
        early = [i for i, c in enumerate(cc[:3]) if has_sp(c, "tree") or has_sp(c, "trace")]
        self.check("sp tree or trace within the first 3 calls", early,
                   f"first calls: {[c['name'] for c in cc[:3]]}")
        stop = next((i for i, c in enumerate(cc) if has_sp(c, "new", "probe")), len(cc))
        self.check("orientation under 5 calls", stop < 5,
                   f"{stop} calls before the probe" + ("" if stop < len(cc) else " (no probe made)"))
        big = sorted({p for c in self.calls for p, bounded in doc_reads(c)
                      if not bounded and len(self.before.get(p, b"")) > BIG_DOC})
        self.check("no whole read of a doc over 2k tok", not big, ", ".join(big))

    def numbering(self, name):
        bad = []
        for kind in ("direction", "epic", "task", "plan", "adr"):
            old = [kind_num(p)[1] for p in self.before if is_art(p) and kind_num(p)[0] == kind]
            new = sorted(kind_num(p)[1] for p in self.new_arts(kind))
            want = list(range(max(old, default=0) + 1, max(old, default=0) + 1 + len(new)))
            if new != want:
                bad.append(f"{kind}: {new} (want {want})")
        self.check(name, not bad, "; ".join(bad))

    def links_prefixed(self, name, paths):
        bad = [f"{p}: {k} {v}" for p in paths for k, vs in fm_lists(self.text(p)).items()
               if k in LINK_KEYS for v in vs if not LINK_ID.match(v)]
        self.check(name, not bad, "; ".join(bad[:5]))

    # S3: top-down breakdown of a Direction into Tasks
    def S3(self):
        new = self.new_arts()
        self.check("made at least one Task", self.new_arts("task"), f"{len(new)} new artifacts")
        stray = [p for p in new if p not in self.sp_new_paths()]
        self.check("every artifact made by sp new", new and not stray, ", ".join(stray))
        self.numbering("numbers contiguous, none shared")
        self.links_prefixed("all references kind-NNN", new)
        self.check_clean("sp check clean")

    # S4: design an ADR that replaces the target ADR (adr-0002 in fixture/)
    def S4(self):
        pid = self.meta.get("s4_adr", "adr-0002")
        pred = self.find(pid)
        names = {pid, pred, fm_lists(self.before.get(pred, b"").decode()).get("id", [""])[0]}
        ok = [c for c in self.calls if has_sp(c, "supersede")
              and re.search(r"(?m)^supersede .*\(changed\)", c["output"])]
        self.check("one sp supersede", len(ok) == 1, f"{len(ok)} that changed something")
        adrs = self.new_arts("adr")
        succ = fm_lists(self.text(adrs[0])).get("id", [""])[0] if len(adrs) == 1 else ""
        edges = (succ and set(fm_lists(self.text(pred)).get("superseded-by", [])) & {succ, adrs[0]}
                 and set(fm_lists(self.text(adrs[0])).get("supersedes", [])) & names)
        self.check("both edges present", edges, f"new ADRs {adrs}; successor {succ or '?'}")
        same = split_fm(self.text(pred))[1] == split_fm(self.before.get(pred, b"").decode())[1]
        self.check("predecessor body byte-identical", pred in self.before and same, pred)
        dis = sorted(self.check_after()[1] - self.check_before[1])
        self.check("0 supersession disagreements", not dis, "; ".join(dis[:3]))

    # S5: bottom-up resume and reconcile of the open probe
    def S5(self):
        pid = self.meta.get("s5_probe", "probe-2026-10-01-balance-off-by-a-cent-on-rounding")
        path = self.find(pid)
        touch = self.first(lambda c: (c["name"] in ("Edit", "Write", "MultiEdit")
                                      and c["input"].get("file_path", "").endswith(path))
                           or (c["name"] == "Bash" and path in c["input"].get("command", "")
                               and re.search(r">>|sed -i|perl -pi|tee", c["input"]["command"])))
        first = json.dumps(self.calls[touch]["input"]) if touch is not None else ""
        self.check("Resumed block is the first change", "Resumed" in first,
                   f"first change at call {touch}")
        self.check("sp ledger reconcile ran",
                   any(has_sp(c, "ledger", "reconcile") for c in self.calls))
        led = "docs/probes/LEDGER.md"
        old = set(self.before.get(led, b"").decode().splitlines())
        new = [l for l in self.text(led).splitlines() if l not in old]
        self.check("ledger line format",
                   any(re.match(rf"^- {pid} — reconciled \d{{4}}-\d\d-\d\d — \S", l) for l in new),
                   "; ".join(new) or "no new line")
        self.check("probe status reconciled",
                   fm_lists(self.text(path)).get("status") == ["reconciled"])

    # S6: S3 with sp hidden from the skills
    def S6(self):
        # sp answering from the installed path means the session was not cold: the
        # cell's setup failed, not the model (F62). judge reports it apart.
        warm = [c for c in self.calls if ".agent-skills" in c["input"].get("command", "")
                and sp_verbs(c) and ANSWERED.search(c["output"])]
        if warm:
            self.setup = "setup: sp answered from ~/.agent-skills, so the session was not cold"
        self.check("run completed", *ended(self.last))
        self.check("made at least one Task", self.new_arts("task"))
        hit = [c["input"].get("command", "")[:80] for c in self.calls
               if sp_verbs(c) and ANSWERED.search(c["output"])]
        self.check("no sp answered", not hit, "; ".join(hit[:2]))
        self.check_clean("sp check afterwards: no new breaking")


def cell_state(vs):
    """pass at 2 of 3; under 3 runs, a cell is open until the bar is met or out of reach.
    A run whose setup failed (S6 not cold) is not counted."""
    vs = [v for v in vs if not v.get("setup")]
    n, p = len(vs), sum(v["pass"] for v in vs)
    if n >= 3:
        return "pass" if 3 * p >= 2 * n else "FAIL"
    return "pass" if p >= 2 else "FAIL" if n - p >= 2 else "open"


def report(out):
    """One row per scenario × model: its state, the marks, the first failure."""
    cells = {}
    for name in sorted(os.listdir(out)) if os.path.isdir(out) else []:
        f = os.path.join(out, name, "verdict.json")
        m = re.match(r"^(S\d)-(.+)-(\d+)$", name)
        if m and os.path.isfile(f):
            cells.setdefault((m.group(1), m.group(2)), []).append(json.load(open(f)))
    states = [cell_state(vs) for vs in cells.values()]
    print(f"eval report · {out} · {len(cells)} cells · {states.count('pass')} pass · "
          f"{states.count('FAIL')} FAIL · {states.count('open')} open")
    if os.path.exists(os.path.join(out, "TAINTED")):
        print("tainted   the skills changed since prepare: prepare a new --out and rerun")
    lines = []
    for (s, m), vs in sorted(cells.items()):
        marks = "".join("s" if v.get("setup") else "✓" if v["pass"] else "✗" for v in vs)
        why = next((v["failed"] for v in vs if not v["pass"]), "")
        lines.append(f"{s:<4}{m[:19]:<20}{cell_state(vs):<6}{marks:<6}{why}"[:200])
    for l in lines[:58]:
        print(l)
    if len(lines) > 58:
        print(f"+{len(lines) - 58} more cells: see {out}/*/verdict.json")
    if not cells:
        print(f"none      no verdicts under {out}: run.sh prepare, drive the sessions, run.sh judge")


def main(argv):
    if len(argv) == 3 and argv[1] == "--report":
        return report(argv[2])
    if len(argv) != 3 or not re.match(r"^S[1-6]$", argv[1]):
        sys.exit("usage: extract.py S1|S2|S3|S4|S5|S6 <run dir> | --report <out dir>")
    scen, run = argv[1], argv[2]
    j = Judge(run)
    getattr(j, scen)()
    fail = j.setup or next((c["name"] for c in j.checks if not c["ok"]), "")
    v = {"scenario": scen, "run": os.path.basename(os.path.normpath(run)), "pass": not fail,
         "failed": fail, "checks": j.checks, "ended": ended(j.last)[1]}
    if j.setup:
        v["setup"] = j.setup
    json.dump(v, open(os.path.join(run, "verdict.json"), "w"), indent=1)
    state = "setup" if j.setup else "pass" if v["pass"] else "FAIL"
    print(f"{scen} {v['run']} {state} {fail}".rstrip())


if __name__ == "__main__":
    main(sys.argv)
