#!/usr/bin/env python3
"""Whole-graph check for a facilitated-waterfall docs/ tree (conventions -> Batch check).

Usage:  check-graph.py [repo-root | docs-dir]      (default: current dir)

Reports, for every artifact in the tree:
  - a same-repo link in relates / supersedes / superseded-by that does not resolve
  - duplicate ids
  - non-sequential numbering per kind (direction / epic / task / plan / adr)

Cross-workspace entries (a repo-qualified `repo:id`, or a path outside `docs/`) are
expected and skipped — the same rule as `sp check`'s informational drift. A probe's id
is its file name. LEDGER.md files are not artifacts.

Prints one line per break, then a summary. Exit 0 clean, 1 on breaks, 2 on usage error.
"""
import os
import re
import sys
from collections import Counter

FW_KINDS = {
    "direction": "directions",
    "epic": "epics",
    "task": "tasks",
    "plan": "plans",
    "adr": "adr",
}
PRODUCT_KINDS = {
    "product-direction": "product/directions",
    "product-epic": "product/epics",
    "story": "product/stories",
}
LINK_KEYS = ("relates", "supersedes", "superseded-by")


def collect(docs):
    files = []
    for kinds in (FW_KINDS, PRODUCT_KINDS):
        for sub in kinds.values():
            d = os.path.join(docs, *sub.split("/"))
            if os.path.isdir(d):
                files += [os.path.join(d, f) for f in sorted(os.listdir(d))
                          if f.endswith(".md") and not f.startswith("LEDGER")]
    p = os.path.join(docs, "probes")
    if os.path.isdir(p):
        files += [os.path.join(p, f) for f in sorted(os.listdir(p))
                  if f.endswith(".md") and not f.startswith("LEDGER")]
    return files


def frontmatter(path):
    try:
        text = open(path, encoding="utf-8").read()
    except OSError as e:
        print(f"unreadable: {path} ({e})")
        return None
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        return {}
    out, key = {}, None
    for line in m.group(1).splitlines():
        km = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):\s*(.*)$", line)
        if km:
            key, out[key] = km.group(1), km.group(2).strip()
        elif key and line.strip().startswith("- "):
            out[key] += " " + line.strip()[2:]
    return out


def refs_of(fm):
    for k in LINK_KEYS:
        v = (fm.get(k) or "").strip().lstrip("[").rstrip("]")
        for tok in re.split(r"[,\s]+", v):
            if tok:
                yield tok


def main(argv):
    root = argv[1] if len(argv) > 1 else "."
    cand = os.path.join(root, "docs")
    docs = cand if os.path.isdir(cand) else root
    if not os.path.isdir(docs):
        print(f"no docs tree at {root} (looked for {cand})", file=sys.stderr)
        return 2

    root = os.path.dirname(os.path.abspath(docs))
    files = collect(docs)
    if not files:
        print(f"no artifacts under {docs}", file=sys.stderr)
        return 2

    errors = []
    ids, seen = set(), {}
    for f in files:
        fm = frontmatter(f)
        if fm is None:
            continue
        rel = os.path.relpath(f, root)
        aid = fm.get("id")
        if not aid:
            base = os.path.basename(f)[:-3]
            if os.path.basename(os.path.dirname(f)) == "probes":
                aid = base
            else:
                errors.append(f"{rel}: no id in frontmatter")
                continue
        if aid in ids:
            errors.append(f"duplicate id {aid}: {seen[aid]} and {rel}")
        ids.add(aid)
        seen[aid] = rel
        for tok in refs_of(fm):
            if ":" in tok:            # repo-qualified: another workspace
                continue
            if "/" in tok:            # a path link
                p = tok if tok.endswith(".md") else tok + ".md"
                if not p.startswith("docs/"):
                    continue          # outside the repo
                if not os.path.exists(os.path.join(root, p)):
                    errors.append(f"{rel}: {tok} — file missing")
                continue
            if tok not in ids:        # a same-repo bare id
                errors.append(f"{rel}: {tok} — not in this repo")

    for kind in FW_KINDS:
        pre = kind + "-"
        nums = sorted(int(i[len(pre):]) for i in ids
                      if i.startswith(pre) and i[len(pre):].isdigit())
        if not nums:
            continue
        miss = [n for n in range(1, max(nums) + 1) if n not in nums]
        if miss:
            errors.append(f"{kind}: missing numbers {miss} (have {nums})")
    for kind in PRODUCT_KINDS:
        pre = kind + "-"
        nums = [int(i[len(pre):]) for i in ids
                if i.startswith(pre) and i[len(pre):].isdigit()]
        dup = [n for n, c in Counter(nums).items() if c > 1]
        if dup:
            errors.append(f"{kind}: duplicate numbers {dup}")

    for e in errors:
        print(e)
    if errors:
        print(f"FAIL — {len(errors)} break(s) across {len(files)} artifacts")
        return 1
    print(f"OK — {len(files)} artifacts: ids unique, numbers sequential, same-repo links resolve")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
