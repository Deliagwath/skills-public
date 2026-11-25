---
name: debugging-improve-sp
description: Turns the sp call log into fixes. Reads the log through `sp log`, picks the failed and flagged calls, re-runs one exactly, judges whether sp is at fault, and hands a real defect to facilitated-waterfall bottom-up with the record as its trigger. Use when asked to "improve sp from the log", or to find sp's defects from evidence rather than by eye. Run in the skills repo that holds sp's source.
---

`sp` is the script both waterfalls read and write through. When `SP_LOG` is set, every `sp` call appends one record to that file: argv, cwd, the workspace it resolved, exit code, stderr, the first line of the answer, and whether the answer was cut or said `ambiguous` or `broken`. This skill turns those records into fixes. It **selects and reproduces**; the fix itself goes through `bottom-up`.

`sp` lives at `~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file. Its page on the log: `sp log help`.

## 1. Preflight — first

Run these checks before reading anything else; on a failure, stop and say which one:

- **`sp` is missing.** Nothing to improve here.
- **`SP_LOG` is unset or empty** (`printf '%s\n' "${SP_LOG:-}"`). Say: no call is logged, so no defect can be found from evidence. Point to `sp log help` for the setup line. Report this as "logging off", distinct from "no defects".
- **`sp log` exits non-zero**, or reports `0 of 0` records. Report its stderr as is.
- **This is not the repo with `sp`'s source.** Fixes land in `facilitated-waterfall/scripts/sp` and `facilitated-waterfall/scripts/test.sh` of the skills repo, whatever workspace a logged call came from. If the current repo has no such files, say so and stop. The record's workspace is where to *reproduce*, not where to fix.

## 2. Read the log

Run `sp log` (the last 200 records; `sp log 1000` or `sp log --all` for a wider window). Rows come failures first, then flagged ones, most recent first, identical calls folded (`×N`):

- `fail` — a non-zero exit, or anything on stderr.
- `flag` — an answer cut at `+N more`, or one that says `ambiguous` or `broken`.
- `older sp` — the call ran on a different version of `sp`; it may be fixed already.

Each row ends with a `rerun` line: the record's cwd and argv, on the current `sp`.

`sp log` flags by exit code, stderr and those markers. A wrong answer with exit 0 (a heredoc terminator listed as a definition, a Direction labelled as superseded by an ADR) shows up when you re-run a call and read the answer.

## 3. Pick and reproduce

Pick one row to work, in this order of preference: a `fail` on the current `sp` (not `older sp`), then a repeated one (`×N`), then one spread over several workspaces, then a `flag`. Then:

1. **Re-run the `rerun` line exactly as written.**
2. **Compare** with the record: same exit, same stderr, same first line. A call that no longer fails on an `older sp` row is fixed; say so and pick another.
3. **Judge whose fault it is:**
   - *Caller error, good message.* The call was wrong, and the message said what to do instead. Not a defect. Move on.
   - *Caller error, bad message.* The call was wrong, but the message did not say how to recover, or pointed the wrong way. **A defect** (in the message).
   - *sp error.* A wrong, missing, truncated or misleading answer to a reasonable call, an abort with no message, a cut that hides what was needed, `ambiguous` where one doc is plainly meant, `broken` where the link is fine. **A defect.**
   - *Cannot reproduce on the current `sp`, and not an `older sp` row.* The record is missing something needed to re-run it (direction-005 Success signal 3). **A defect** in the record format: name the missing field.
4. For a `flag` row, or any row whose answer looks off, read the whole answer.

Work one defect at a time; note the others in the report for later.

## 4. Hand to bottom-up

Load `facilitated-waterfall:bottom-up` with **the record as the trigger**: paste its `sp log` rows (the row, its `ws`/stderr line, and the `rerun` line) and your verdict from step 3. `bottom-up` owns the rest: the probe, the climb, the fix in `sp`, a regression case in `test.sh`, and the reconcile.

Two things it should hear from you:

- **The log is private.** Records hold argv and paths from private repos. The regression case in `test.sh` reproduces the defect on the suite's own fixture, with fixture names, and everything committed to the public repo (`test.sh`, the README, the CHANGELOG) carries fixture names only.
- **`sp` may be live on save.** Where `~/.agent-skills/facilitated-waterfall/scripts` links to the repo folder, every edit to `sp` reaches every session at once. Build and test the fix on a copy, then save it over the original.

## 5. Report

End with one short list: each row you looked at, its verdict (`defect → bottom-up <probe id>`, `caller error`, `fixed in a newer sp`, `not reproduced: <missing field>`), and the rows left for a later session. The user reviews and decides what runs next.

## Rules

- `sp` is edited inside a `bottom-up` run in a session the user started (direction-005 Constraint 6).
- `sp`'s answers stay independent of the log at runtime; fixes go through code, `test.sh` and review.
- Find what failed through `sp log`, so a gap in what it shows is itself a finding. Open the raw record (one JSON line) for a field `sp log` does not show.
- An empty `sp log` with logging on is a result; a missing log means logging is off. Say which it is.
