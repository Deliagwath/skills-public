---
name: general-usage-note
description: Records what a working session learned into the project handbook in docs/handbook/ — five fixed files capturing how to run things, reproducible errors and their reflexes, what each area is for, and conventions with their reasons. Invoke at the end of a session (usually bare) to harvest and bank the findings, or with "prune" to clean stale notes, or once per repo with "backfill" to replay closed probes into it. To read the handbook back, use recall.
---

Records what a session turned up into the project **handbook**, so the next session starts ahead of this one. This is the **write** end of the handbook; to read it before working, use `recall`.

The store is a **fixed set of five files** in `docs/handbook/`. Knowledge is routed into these five, which keeps the handbook small and prunable.

| File | Holds |
|------|-------|
| `index.md` | Read-first: one line per file with its `last verified` date, plus one `last pruned: DATE · N entries` line. |
| `map.md` | Purpose and entry points, one line per area. Structure comes from `sp module <path>`. |
| `commands.md` | How to build, run, test, lint, deploy; setup steps; required env. |
| `gotchas.md` | Reproducible errors and their fixes, footguns, surprising behaviour, time-wasters. |
| `conventions.md` | Recurring code patterns, naming, "how we do X here", architectural norms. |

**Terms are not handbook entries.** A domain term goes to `docs/CONTEXT.md` as one glossary line. A product term goes to `docs/PRODUCT.md` when the workspace has one. Check both before appending, because a term lives in exactly one of them.

**Research is not the handbook.** Long-form material belongs in `docs/research/` and is only ever looked up. An existing `docs/knowledge/` directory is research too, and stays as it is.

Pick the mode:

- `docs/handbook/` missing or empty → **Bootstrap**, then continue to Write.
- Argument is `prune` (or "clean up / verify the base") → **Prune**.
- Argument is `backfill` → **Backfill** (Bootstrap first if needed).
- Otherwise → **Write**.

---

## Bootstrap

Run only if `docs/handbook/` does not exist or is empty.

Create the directory and all five files. Each content file gets a one-line header comment stating what it holds, and no entries. Create `index.md` listing the four content files with `last verified: never`, plus the line `last pruned: never · 0 entries`. Then continue to Write.

---

## Write

Capture what the session learned. The facts usually live in **the preceding conversation**: the user types `/note` after the work is done to bank what just happened.

### 1 — Harvest from the conversation

Re-read the session and pull out what is durable and was non-obvious. Look especially for:

- **Commands that were corrected** — the trail matters. "`npm test` and `npx test` both fail; `pnpm test` works (this repo is pnpm-only)" belongs in `commands.md`. Record the working answer *and* the dead ends tried.
- **Errors that were reproduced and resolved** → `gotchas.md`. Record how to trigger it and how to fix it, and also **the wrong first move**, if the session made one or the user named one.
- **An area's purpose that became clear**, and its entry point → `map.md`, one line per area. `sp module <path>` derives the structure.
- **Conventions noticed** → `conventions.md`. **Terms pinned down** → `docs/CONTEXT.md` (or `docs/PRODUCT.md` for a product term).
- **The reason behind a practice.** Look for why it holds, not only what it is. Record a reason only if the session observed it or the user stated it.
- **An effect observed.** Did this session see, in real use, whether an earlier implemented Task had its intended effect? If so, append its line to `docs/tasks/LEDGER.md` (create the file with no header if it is missing):
  - `<task-id> — done DATE — effect: <what was observed, and where>`
  - or `<task-id> — effect not achieved DATE — <what was observed>`

  Name the observation itself; a Verification result ("tests pass") belongs on the implemented line, and with no observation the effect line stays unwritten. If the Task's `relates` chain reaches a product Story, judge it against the Story's Outcome and end the effect with `— story-NNN Outcome: met | not met`. This is not a handbook entry.

Discard what was one-off or specific to this conversation. A list of candidate facts before writing is good; confirm the set with the user if it is large.

### 2 — Verify before recording

Record what is true. A fact *discovered* (inferred from code or output) is confirmed first — re-read the file, re-run the command. A fact *stated by the user* is taken as given, marked user-asserted when it cannot be checked. Mark anything uncertain `(unverified)`.

### 3 — Route to exactly one file

Pick the single best-fit file using the table above. A fact belongs in one place. If it seems to fit two, choose by primary use:

- "`src/auth/` handles sign-in; the entry point is `createSession` (src/auth/session.ts)" → `map.md`
- "tests run with `pnpm test:int`, needs Docker up" → `commands.md`
- "import fails unless `NODE_OPTIONS=--no-warnings`; reproduces on clean clone" → `gotchas.md`
- "all API handlers return `Result<T>`, never throw" → `conventions.md`
- "a 'tenant' is a billing account, not a user" → `docs/CONTEXT.md`, as a glossary line, not the handbook

When none of the five fits, the fact is probably not durable project knowledge: drop it.

### 4 — Dedup, then write atomic dated entries

Before adding, search the target file for an existing entry on the same subject. When one exists, **update it in place**. Each entry is atomic (one fact), titled, sourced, and dated:

```
### <short subject>
<the fact>.
Because: <why it holds | not recorded>. Stage: provisional. Source: `Symbol.member` (path) or `command`. Verified: 2026-06-29.
```

**Anchors name symbols.** Point at code as `` `Symbol.member` (path) ``, with no line number, so the anchor survives the next edit. `sp def <symbol>` (at `~/.agent-skills/facilitated-waterfall/scripts/sp`, if installed) or a grep resolves it. Older `path:line` anchors stay valid. When the entry comes from a probe, append the probe id to the source as its warrant: `` Source: `Symbol.member` (path) · probe-<id> ``.

`gotchas.md` entries take the lesson shape Moment / Reflex / Instead / Because instead of a bare fact. The **Reflex** records the tempting wrong response, so the next session recognises it:

```
### <short subject>
Moment: <when it bites: the trigger, the symptom>.
Reflex: <the tempting wrong response | not observed>.
Instead: <what to do>.
Because: <why | not recorded>. Stage: provisional. Source: `Symbol.member` (path) or `command`. Verified: 2026-06-29.
```

**Because.** Every `conventions.md` and `commands.md` entry carries its reason, so the rule can be applied with judgment. Write the reason when it was observed or stated; otherwise write `Because: not recorded`.

**Stage** says how settled the entry is: one of `provisional · established · canonical · superseded`. Pick it yourself.

| Stage | Means | Warrant to reach it |
|-------|-------|---------------------|
| `provisional` | Seen once, in this session. The default for a new entry. | — |
| `established` | Held up again. | A later session re-confirmed it or relied on it without surprise. |
| `canonical` | A rule of the workspace. | The user stated it as a rule, or it stayed established across several prunes. |
| `superseded` | Replaced. Write `Stage: superseded → <successor subject>`. | A newer entry replaced it. The next prune removes it into a probe. |

Promote with the warrant in hand; when the warrant is a probe, record it on the stage: `Stage: established ← probe-<id>`. When you demote, say which entry moved and why. Stage is **maturity**. It is separate from the **freshness** markers `(unverified)` and `(stale)`, which say whether the entry is still true. An entry can be `canonical` and `(stale)`.

**Portable.** Ask of each entry: *would this read correctly in a different repo?* If yes, append `· portable` to its metadata line. The tag only marks the entry; nothing moves it anywhere. When in doubt, leave it off.

Entries written before these fields existed stay valid as they are. Add the fields to an entry when you next touch it.

### 5 — Touch the index

Update the target file's `last verified` date in `index.md`. If the file was empty before, change its index line from `last verified: never` to today.

Confirm what was recorded and where. Keep it to one or two lines.

---

## Prune

Maintenance pass to stop rot. Run on request, or proactively when a file has grown long enough to be hard to scan. A probe's close runs the same test on just the area it touched (facilitated-waterfall `conventions` → Handbook → Deposit at a close); this mode is the whole-base pass.

**Removed entries move into a probe.** Every entry this pass removes (wrong, stale, superseded, merged away or retired) is moved word for word, with its reason, into a probe. Use the open probe of this session if there is one. Otherwise write `docs/probes/probe-YYYY-MM-DD-handbook-prune.md`: frontmatter `id`, `title`, `created`, `status: reconciled`, `relates: []`; a **Trigger** line (`note prune`); and a **Reconciliation** section holding the removed entries. Then append `- probe-YYYY-MM-DD-handbook-prune — reconciled DATE — handbook prune: N removed` to `docs/probes/LEDGER.md`. The probe becomes sealed history, looked up on demand. (`docs/` may be gitignored, so the probe is the entries' only copy.)

1. Read every content file.
2. For each entry, re-verify against the current codebase. Then:
   - **Wrong / contradicted by current code** → fix it, or remove it into the probe. A fixed error in `gotchas.md` that no longer reproduces should go.
   - **Duplicated or overlapping** → merge into one entry. Consolidating is always preferred over splitting into another file.
   - **Unverifiable** (source gone, can't reproduce) → mark `(stale)`; remove it into the probe on the next pass if still unverifiable.
   - **`superseded`** → remove it into the probe, and leave the successor entry in place.
3. **Cut test.** Apply it to every entry that is still *true* after step 2. Truth comes first: a wrong entry is fixed or removed before it is cut. Ask: **has this changed a decision recently?**
   - "Recently" means since the previous prune. That is the oldest `last verified` date in `index.md`, or the entry's own Verified date if it is newer.
   - The evidence is git history and the artifacts written since that date. Would a session working on that history have done something differently with this entry than without it? Was the entry cited, or would it have prevented a mistake that was made?
   - **Earns its place** → keep it. If it was relied on without surprise, promote it per its warrant.
   - **True but idle** → demote it one stage. An idle `provisional` entry is retired: removed into the probe, verbatim, with its reason.
   - **What-the-code-already-says** → retire it. The code is the record now.
   - Cut a `canonical` entry only with a stated reason. Report it if the same canonical entry keeps being cut and restored.

   On a base of 15 or more entries, expect the cut test to remove something; when it removes nothing, say so plainly.
4. Refresh `last verified` dates in `index.md` for every file touched, and rewrite its `last pruned: DATE · N entries` line with today's date and the entry count after the prune.

Report what was fixed, merged, and removed, and name the probe that holds the removed entries. List each demotion or retirement by name, with its reason.

---

## Backfill

Replays a workspace's history into the handbook, as if the loop had always been running. Run it only when the user asks, once per repo; no other skill triggers it. The rules it replays are facilitated-waterfall `conventions` → Handbook → **Deposit at a close**. This mode adds only what replay changes.

**It is its own probe.** Look for an open `docs/probes/probe-*-handbook-backfill.md`. If there is one, **resume**: say which item of its replay list comes next, and continue from there with the list as written. Otherwise write `docs/probes/probe-YYYY-MM-DD-handbook-backfill.md`: frontmatter `id`, `title`, `created`, `status: open`, `relates: []`, and a **Trigger** line (`note backfill`). Before the first batch, write the **replay list** into its Findings:

- every closed probe (`status:` `reconciled`, `abandoned` or `resolved`), oldest → newest by close date. Take the date from its line in `docs/probes/LEDGER.md`, or from its frontmatter if it has no line;
- each **fence**, placed at its date: the day the last Task of an Epic, or the last Epic of a Direction, became implemented. An Epic's Tasks are those its manifest lists or whose `relates` names it; each Task's date is its latest Plan's line in `docs/plans/LEDGER.md`, or the probe that closed it when it was built without a Plan. A fence before the first closed probe has nothing to cut; leave it out;
- then each file under `docs/knowledge/`, if there is one.

**Batches.** Take about 8 probes at a time. Of each, read Findings, Deliberation and Reconciliation; the probe is sealed, and backfill is the stated reason to open it. After each batch, append one dated Findings block: `processed: <ids>`, then per probe the entries added, promoted, demoted or retired, or `nothing durable`. That block is the checkpoint. A session that stops mid-batch redoes the batch, and dedup makes that harmless.

**Per probe, run Deposit at a close steps 1–2, with these replay readings:**

- **Deposit the lesson, not the Finding.** Write what the next session should do differently, in `note`'s format, with the replayed probe as warrant and `Because:` only from its text.
- **Truth is judged now.** Resolve each code anchor against the current code (`sp def`, or grep). An anchor that no longer resolves marks the lesson as history: leave it in the probe. Judge commands from an old probe by reading them, since running them may touch live services. Write `Verified:` as the probe's close date.
- **A replay warrant is the later probe's own text.** Historical probes cite no entry, so a later probe "relied on" an entry when its Findings or Deliberation use or re-confirm the lesson without surprise. Promote with `Stage: established ← probe-<later-id>`, and name the line in the batch block. A warrant is a use or re-confirmation; shared topic is not one. `canonical` needs the user stating it as a rule, in the probe.
- **A later probe that contradicts an entry** fixes it in place, or removes it into the backfill probe, loudly, as Deposit at a close step 2 says.

**At each fence, run step 3's cut test** over that Epic's or Direction's area: the paths its probes changed or anchored. "Since last pruned" means since the previous fence in the replay. Retired entries move into the backfill probe.

**Then harvest `docs/knowledge/`.** It is research: read it, and leave it as it is. Take only practice lines (a command that works, a footgun, a norm with its reason), not findings or surveys. Each entry's source is the file and its section heading, `` Source: docs/knowledge/<file> (§ <heading>) ``. It starts `provisional` unless a replayed probe already relied on the same lesson. `docs/research/` is not harvested; it stays lookup-only.

**Close.** Run `sp --budget <window> module` (or `file`) on each area in `map.md`. Any area whose `handbook` line reads `over` gets the cut test now. The window is the smallest context window among the clients that read this workspace, because they all share one handbook. When no budget is set, ask the user for it: the backfill is judged on staying within budget. Then fill the probe's **Reconciliation**: the Deposit line, with entry counts per file and per stage; retired entries, verbatim, each with its reason; and `index.md`'s `last verified` and `last pruned: DATE · N entries`. Set `status: reconciled`, and append `- probe-YYYY-MM-DD-handbook-backfill — reconciled DATE — handbook backfill: N probes, M research files → E entries (P established)` to `docs/probes/LEDGER.md`.

Backfill writes no `intent:` lines, no `docs/tasks/LEDGER.md` lines, and no `status:` on any artifact but its own probe. Work done before the loop gets an effect line only on the user's word.

---

## Rules

- Five files, fixed, in `docs/handbook/`: route each fact to one, or drop it. Terms go to `docs/CONTEXT.md`.
- An existing `docs/knowledge/` is research: read it (`backfill` harvests from it) and leave it as it is.
- Verify discovered facts against code before recording. Mark anything uncertain `(unverified)`.
- One fact per entry; dedup before writing; update in place rather than appending duplicates.
- Every entry carries a source and a date so it can be re-verified and pruned, and every entry carries a stage. New code anchors name a symbol, not a line.
- A removed entry moves verbatim, with its reason, into a probe.
- Reasons, reflexes and effects are recorded when observed or stated; otherwise write `not recorded` or `not observed`.
- The model classifies stage, `portable` and gotcha shape.
- Record what was non-obvious or hard-won; leave out what the code already makes obvious and what matters only to the current conversation.
- An entry is a snapshot: when it conflicts with the live codebase, fix the entry to the code.
- **After writing, run `sp check` on each handbook file you touched, if `sp` is present** — the gate is the lines that name *your* entries; report pre-existing drift naming other sessions' entries as a count (`conventions` → Handbook holds the full gate).
