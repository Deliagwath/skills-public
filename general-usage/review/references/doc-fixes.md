# Fix pass — applying approved review findings

Run after the user approves a subset of a review's findings. Apply exactly the approved class, in one pass, and report the result. The repo nests skills under family directories (`facilitated-waterfall/conventions/`, `general-usage/review/`, …) — check the layout once and use the nested paths.

## Scope

- "Fix X first" means X only. The user triages findings into fix-now, accepted-drift, and queued-aspects; the pass applies fix-now.
- An open question the user left open (e.g. a backward-compatibility call) gets evidence and a recommended default in the report; the spec waits for the user's decision.

## Check the tree first

- Before applying anything, run `git status` and read `git diff` on the target files. A parallel session may have landed the approved fix, committed or uncommitted. When it is present, the pass becomes verification: re-check each finding against the current text, the tool's source and the suite, and report it as verified-already-resolved, not as changed in this pass.
- Another session's uncommitted hunks stay as they are: leave the tree as you found it, and say in the report whose work sits uncommitted in it.

## Evidence before direction

- For each doc-vs-tool contradiction, re-read the tool's source for the disputed behavior and confirm which side bends. The tool is what runs; the document is its cache and bends first.
- For each spec line you will change, grep the repo for the exact old string — and every phrase you are rewording — to enumerate all copies (sibling skills, README, docs) before the first patch.

## Apply in one pass

- Patch all copies of a changed spec line in a single pass, so every file reads the same.
- Preserve quoted invariants: ADRs, probes and other documents quote spec strings verbatim (e.g. the status enum). After editing, grep the quoted strings and confirm the quotations are still true.
- History keeps its wording: changelogs record the past, and tool-internal comments describe the tool. Count such survivors as accounted for.

## Verify, then report

- Grep the repo for every retired phrase: expect zero, or account for every survivor by name.
- For naming or renaming changes, first check that the read layer is name-agnostic (`sp` indexes by directory and resolves by frontmatter id; `sp migrate` deliberately leaves renames out of scope). If reads do not depend on the name, the change is forward-only — old artifacts keep working. Present "support as-is vs one-shot rename" to the user, and write a migration directive into the spec on their decision.
- When the change touches the system-doc orbit (any SKILL.md, the conventions, the README, or the `sp` script), run the sp eval suite: `sh scripts/test.sh` in `facilitated-waterfall/` (a few thousand cases, a few minutes). Green is the gate that the tree is still consistent; the pass stands on a green suite.
- Report shape: what changed (per contradiction), the evidence that set its direction, the verification greps with their counts, and the deferred list. When the pass only verified, say so per finding.
