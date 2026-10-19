# skills

A collection of AI-agent skills (slash commands) for Claude Code, Cursor, OpenCode, Mirai, and DeepSeek Harness, organized into four namespaces:

- **`facilitated-waterfall`** — an append-only, in-repo documentation system designed so that agents work from a rich, durable, and *enforceable* source of project knowledge rather than from a single throwaway prompt.
- **`product-waterfall`** — the same two-direction discipline one layer up, for product decisions. It stacks on top of facilitated-waterfall and hands off to it at the Story.
- **`general-usage`** — general-purpose skills for everyday work in a workspace, useful on their own regardless of whether you adopt facilitated-waterfall.
- **`debugging`** — skills that find and fix defects in the tooling itself from evidence, starting with `improve-sp`, which turns `sp`'s call log into fixes.

## Why this exists

An agent is only as good as the context it can recover. Chat history evaporates; a `docs/` tree does not. facilitated-waterfall turns the decisions made *around* a piece of work — the problem, the scope, the trade-offs, the plan — into committed artifacts that:

- **persist** across sessions and agents, giving any fresh agent a real source of truth to read;
- **link** to each other, so an agent can walk from a line of code back up to the reason it exists;
- **constrain**, so implementation can be checked against what was actually decided, not against a vibe.

The result is documentation that is both *referrable* (an agent can find the governing decision) and *enforceable* (drift from it is detectable).

## The namespaces

### `facilitated-waterfall/`

The core methodology. Work flows in **two directions** that meet at a dividing line — the **waterline** — which separates *commitment* (recorded, expensive to reverse) from *mechanism* (local, reversible):

```
Direction → Epic? → Task → ADR          top-down: intent descends to the line
                      ⭡      │
                      │      ▼
                    Plan → Code          bottom-up: fixes ascend to the line
        ⮑ docs/CONTEXT.md (glossary)     ⮑ docs/probes/ (bottom-up working memory)
```

- **Top-down** descends from intent and stops at a *placed, bounded unit* (a Task) — it never runs straight into implementation.
- **Bottom-up** starts from a concrete fix in the code and climbs to check it sits in the right place, implementing *below* the line and reconciling what it learned back *up* into the record.
- **ADR** is the shared ledger at the waterline: top-down writes it looking forward; bottom-up supersedes it on contact with code. Neither side may cross the line — top-down into code, or bottom-up over a commitment — without stopping (top-down hands off; bottom-up needs an accepted trade-off recorded as a superseding ADR).
- **Epic is optional** — a manifest layer used only when one Direction spawns several ordered or dependent Tasks.

**Three composed skills** are the primary interface:

| Skill | Direction | What it does |
|-------|-----------|--------------|
| `top-down` | intent → waterline | Shapes a Direction, breaks it into Epics/Tasks, records ADRs — stopping at a bounded, implementable unit. |
| `bottom-up` | code → waterline | Anchors a fix, climbs the abstraction ladder against the governing docs, resolves at the line, implements, and reconciles learnings back up. Records working memory in `docs/probes/`; loads `top-down` as a subroutine when it hits an above-the-line gap. |
| `conventions` | — | Shared rules (drilling technique, the waterline, append-only, artifact formats, numbering) **and** the read-only audit: checks whether what was built stayed inside what was decided. |

`what-next` remains a standalone navigation skill: it surveys the `relates` graph and codebase (now including open probes) to recommend the single best next action.

The original granular skills — `shape`, `breakdown`, `design`, `plan`, `implement`, `audit-doc` — are the **units these compose from** and remain usable directly. Use the small parts when you want one stage; use the composed skills when you want the whole motion in one flow.

### `product-waterfall/`

The product layer. It runs the same up-and-down motion against **`docs/PRODUCT.md`**: product identity, append-only resolved decisions (`D-NNN`), product-level out of scope (`X-NNN`), strategic themes, and a product glossary. It's platform-agnostic: everything lives in `docs/`, and an optional `tracker:` frontmatter key can link out to Jira or similar without any skill calling it.

| Skill | Direction | What it does |
|-------|-----------|--------------|
| `direct` | intent → product waterline | Shapes a product Direction against `docs/PRODUCT.md`, breaks it into Epics and Stories, and stops at a Story. Also refines Stories. |
| `reflect` | signal → product waterline | Classifies a real-world signal or an engineering finding, deliberates against `docs/PRODUCT.md`, records supersessions, and lists every affected artifact in both layers. `reflect bootstrap` creates `docs/PRODUCT.md`. |
| `conventions` | — | The two stacked waterlines, the hooks, formats, and a read-only product-alignment audit. |

**The two layers stack.** A Story is mechanism to the PM and commitment to engineering, so it's where one layer hands off to the other:

```
direct ──Story──▶ top-down ──Task──▶ bottom-up
  ▲                  │                  │
  │     conflicts with PRODUCT.md       │ Story can't be met / product commitment wrong
  │                  ▼                  ▼
  └──Affected────  reflect  ◀──────────┘ (or direct Refine, if only the Story moves)
```

An ADR can never override a product commitment. When engineering hits one, `bottom-up` hands it to `direct` (the Story changes) or `reflect` (a `docs/PRODUCT.md` decision is at stake). Both always involve the PM.

### `general-usage/`

General-purpose skills for everyday work in a workspace — reviewing, exploring, assessing, drilling, and accumulating project knowledge (`note`/`recall`) that compounds across sessions. They stand on their own and are useful whether or not you use facilitated-waterfall at all. One of them (`to-waterfall`) happens to offer a path *into* the waterfall, but that's an option, not the point.

| Skill | What it does |
|-------|--------------|
| `note` | Records what a session learned into a fixed five-file handbook in `docs/handbook/`; also prunes stale notes, and once per repo backfills it from closed probes. Terms go to `docs/CONTEXT.md`. |
| `recall` | Loads what the handbook in `docs/handbook/` knows about a query before you start work. The read half of `note`. |
| `review` | Reviews a diff/branch/PR or a waterfall document for correctness, quality, consistency. |
| `simulate` | Traces every execution branch of a function/route/system and writes the findings out. |
| `supervise` | Reviews implementation against plans + ADRs in iterative cycles with fresh subagents. |
| `survey` | Honest landscape assessment: what exists, what's unclear, what's blocking. |
| `to-waterfall` | Translates a conversation's findings into Directions, Epics, Tasks, ADRs, or docs/CONTEXT.md entries. |
| `zoom-in` | Drills relentlessly into a plan's details to reach shared understanding. |
| `zoom-out` | Steps back to question whether a direction is worth pursuing at all. |

If you *do* run facilitated-waterfall, `to-waterfall` provides an optional path back into it: do exploratory work with these skills, then promote what's worth keeping into the append-only system.

### `debugging/`

Skills that find and fix defects in the tooling itself, from evidence.

| Skill | What it does |
|-------|--------------|
| `improve-sp` | Reads `sp`'s own call log (`SP_LOG`, through `sp log`), re-runs a failed or flagged call exactly, judges whether `sp` is at fault, and hands a real defect to `bottom-up` with the record as its trigger. Fixes land in `sp` with a regression case in `test.sh`. |

## Core principles

- **Append-only.** Artifacts are not edited in place once they record a decision. A changed decision is captured by appending a *new* ADR that supersedes the old one — the history of why stays intact. The old one gains only a `superseded-by` key, so a reader of it sees the change first.
- **Completion is recorded, not inferred.** `implement` appends one line to `docs/plans/LEDGER.md` when a Plan's verification passes — done once, never edited. A wrong entry is fixed by a new line, not a rewrite, same as ADR supersession. This is what lets `what-next` and `audit-doc` know a Plan is finished without guessing from code or git history.
- **The `relates` graph is the source of truth.** Links point upward (Epic→Direction, Task→Epic, Plan→Task, ADR→artifact) and are fixed at creation. A child's existence proves its parent was broken down; the codebase proves a Plan was implemented.
- **Code is ground truth; docs are the boundary.** When they disagree, that disagreement *is* the finding. The `conventions` audit reports it rather than silently picking a side.
- **The waterline divides commitment from mechanism.** Below it (module, class, placement) is reversible — the engineer decides freely. Above it (ADR decisions, Direction constraints) is committed — changing it needs an accepted trade-off, recorded as a superseding ADR. Top-down stops at the line and hands off; bottom-up may not overturn a commitment without recorded acceptance.
- **Drill before you write.** Every authoring stage shares one technique: sharpen fuzzy language, probe with concrete scenarios, push back on first answers, and resolve decisions inline rather than batching them.
- **Glossary, not prose.** `docs/CONTEXT.md` (engineering) and the `docs/PRODUCT.md` glossary (product) hold resolved terms only — no implementation detail.

## Artifact layout

facilitated-waterfall skills read and write under `docs/` in the *target* project (not this repo):

```
docs/
  directions/NNN-slug.md   Problem · Appetite · Out of scope · Success signal · Constraints · Risk?
  epics/NNN-slug.md        Goal · Scope · Out of scope · Tasks · Sequencing · Done when   (optional tier)
  tasks/NNN-slug.md        Goal · Acceptance Criteria · Notes
  plans/NNN-slug.md        Context · Steps · Verification · Risk
  plans/LEDGER.md          Append-only record of which Plans are implemented
  adr/NNNN-slug.md         Context · Decision · Consequences · Alternatives   (optional supersedes)
  probes/<id>.md           Trigger · Governing docs · Findings · Open questions · Deliberation · Risk · Reconciliation
  CONTEXT.md               Glossary of resolved engineering terms
  PRODUCT.md               product-waterfall: Identity · Decisions (D-NNN) · Out of scope (X-NNN) · Themes · Product glossary
  product/
    directions/NNN-slug.md Problem · Appetite · Out of scope · Success signal · Constraints
    epics/NNN-slug.md      Capability · Scope · Out of scope · Success signal · Stories · Sequencing   (optional tier)
    stories/NNN-slug.md    Outcome · Acceptance criteria · Out of scope · Revisions?   ← the seam to FW
    probes/<id>.md         Signal · Classification · Governing decisions · Deliberation · Outcome · Affected · Changes
```

Everything lives under `docs/`. The two glossaries are deliberately separate: product terms go in `PRODUCT.md`, engineering terms in `CONTEXT.md`, and a term lives in exactly one of them.

Every durable file carries frontmatter with at least `id`, `title`, `created`, and `relates: [...]`, and is numbered sequentially from the highest existing file in its directory. The `id` is kind-prefixed (`direction-020`, `task-084`, `adr-0034`, `story-013`), and links and prose cite artifacts by it. `sp new` writes all of this. **Probes are the exception**: they are mutable working memory (`open` → `reconciled`/`abandoned`), use collision-free dated ids (`probe-YYYY-MM-DD-slug`), and freeze once reconciled — everything a probe *produces* stays append-only.

## Installation

```sh
./install.sh
```

Each skill is one folder, `<namespace>/<skill>/SKILL.md`: the layout every client below loads, and the one Paperclip's skill library imports in place. `install.sh` detects which clients are present and installs into each. It is idempotent — safe to re-run.

To install into specific clients only, name them — this replaces detection:

```sh
./install.sh claude opencode dsh   # any of: claude cursor opencode mirai dsh
```

| Client | Destination | Invocation |
|--------|-------------|------------|
| Claude Code / VS Code extension | `~/.claude/commands/<namespace>/<skill>.md` (symlink to `SKILL.md`) | `/<namespace>:<skill>` |
| Cursor | `~/.cursor/commands/<namespace>-<skill>.md` (symlink to `SKILL.md`) | `/<namespace>-<skill>` |
| OpenCode | `~/.config/opencode/skills/<namespace>-<skill>/SKILL.md` (copied) | `<namespace>-<skill>` |
| Mirai | `~/.mirai/skills/<namespace>-<skill>/SKILL.md` (copied) | `<namespace>-<skill>` |
| DeepSeek Harness | `$DSH_HOME/skills/<namespace>-<skill>/` (symlink to the skill folder) | `<namespace>-<skill>` |

> Symlinked clients read this repo as it stands: an edit is live with no reinstall. OpenCode and Mirai get copies, because neither is verified to follow a linked skill folder; re-run `install.sh` after an edit for them.
>
> OpenCode, Mirai and DSH require YAML frontmatter (`name` + `description`) in every skill; the installer validates this and refuses to install a namespace with any skill missing it.

**Shipped scripts.** A namespace with a `scripts/` folder (today, `facilitated-waterfall/scripts/sp`, with `nav` as an alias for its read verbs) is linked at `~/.agent-skills/<namespace>/scripts/`, the one path every skill names, whatever the client. Both waterfalls read and write artifacts through `sp`: `new`, `supersede`, `relate` and `ledger` write frontmatter, links and ledger lines; `check` reports what breaks navigation; `trace`, `tree`, `frontier`, `outline` and `show` read docs; `def`, `docs`, `module` and `file` link code and docs. `sp` works best with [Universal Ctags](https://ctags.io), [mdq](https://github.com/yshavit/mdq) and mikefarah's [yq](https://github.com/mikefarah/yq), each optional with an awk or grep fallback. If one is missing, the installer names the package-manager command and asks before running it; a non-interactive run only prints it. On macOS, Apple's `/usr/bin/ctags` can come first on `PATH`; the installer warns about it, and `sp` finds the Universal binary regardless.

**Tests.** `facilitated-waterfall/scripts/test.sh` checks every `sp` verb in four tool modes. `facilitated-waterfall/eval/` is the small-model suite (Task 028), kept outside `scripts/` so it is never installed: `eval/run.sh` covers six scenarios (`bottom-up`, `top-down`, `design`, a resume, and a run without `sp`) on Opus 5.5 (the user dropped Haiku, the local model and Sonnet on 2026-10-09), three runs a cell, and never calls a model itself. `run.sh prepare` makes one run dir per cell, each with its own `/tmp` copy of a small fixture workspace and a `prompt.txt` holding the one line to type. You open a Claude Code session in each `ws/` yourself, on that cell's model, type the line and take every recommended answer. `run.sh judge` then takes each session's transcript from `~/.claude/projects/` and judges it from the transcript and the workspace's final state, never by a model, and prints one pass/fail table. `--fixture <dir> --scenarios <file>` prepares the same scenarios on a throwaway clone of a real workspace instead, judging only what each run added (an unmigrated clone starts malformed). `eval/test.sh` tests the suite itself without a model call.

**DSH and multiple harness homes.** DSH scans `$DSH_HOME/skills` (per home) before `~/.agents/skills` (shared by every home on the machine). The installer writes the per-home root and resolves the home the way DSH does — `$DSH_HOME`, else `~/.dsh` — so a box running more than one harness chooses which one gets the skills by choosing the home for the run:

```sh
DSH_HOME=~/.dsh-harness ./install.sh   # the human-facing harness only
```

Setting `DSH_HOME` counts as detection on its own, so this works before that home has been created. Skills install model- **and** user-invocable (DSH's default for frontmatter that sets neither `disable-model-invocation` nor `user-invocable`): they appear in the model's `skill` catalog and as slash commands in the web UI.

Skills are referred to by bare name throughout this README (`top-down`, `bottom-up`, …); how you actually invoke one depends on the client — see the invocation column above.

## Typical flows

Work usually starts from one of two ends and meets at the waterline.

**Top-down — a new initiative:**

1. `top-down` shapes a Direction, breaks it into Tasks (introducing an Epic only if several Tasks need a shared manifest), and records ADRs for irreversible, surprising, real trade-offs — stopping at a bounded Task.
2. `bottom-up` picks up that Task, derives a Plan, implements below the line, and reconciles.
3. The `conventions` audit confirms the code stayed inside its boundaries.

**Bottom-up — a bug or change request rooted in code:**

1. `bottom-up` anchors the fix, walks `relates` upward to the governing docs, and climbs the abstraction ladder — right spot? right class? right module? right architecture?
2. If the fix fits *below* the line, it implements directly. If it needs an above-the-line change, it either records a superseding ADR (with accepted trade-off) or loads `top-down` to author the missing Direction/Task/ADR properly, then resumes.
3. On close, it reconciles: distils findings into durable artifacts, verifies touched glossary terms, and freezes the probe.

`what-next` at any point recommends the frontier — including resuming an open probe.
