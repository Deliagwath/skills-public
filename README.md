# skills

A collection of AI-agent skills (slash commands) for Claude Code, Cursor, OpenCode, and Mirai, organized into two namespaces:

- **`facilitated-waterfall`** — an append-only, in-repo documentation system designed so that agents work from a rich, durable, and *enforceable* source of project knowledge rather than from a single throwaway prompt.
- **`general-usage`** — general-purpose skills for everyday work in a workspace, useful on their own regardless of whether you adopt facilitated-waterfall.

## Why this exists

An agent is only as good as the context it can recover. Chat history evaporates; a `docs/` tree does not. facilitated-waterfall turns the decisions made *around* a piece of work — the problem, the scope, the trade-offs, the plan — into committed artifacts that:

- **persist** across sessions and agents, giving any fresh agent a real source of truth to read;
- **link** to each other, so an agent can walk from a line of code back up to the reason it exists;
- **constrain**, so implementation can be checked against what was actually decided, not against a vibe.

The result is documentation that is both *referrable* (an agent can find the governing decision) and *enforceable* (drift from it is detectable).

## The two namespaces

### `facilitated-waterfall/`

The core methodology. Work flows in **two directions** that meet at a dividing line — the **waterline** — which separates *commitment* (recorded, expensive to reverse) from *mechanism* (local, reversible):

```
Direction → Epic? → Task → ADR          top-down: intent descends to the line
                      ⭡      │
                      │      ▼
                    Plan → Code          bottom-up: fixes ascend to the line
        ⮑ CONTEXT.md (shared glossary)   ⮑ docs/probes/ (bottom-up working memory)
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

### `general-usage/`

General-purpose skills for everyday work in a workspace — reviewing, exploring, assessing, drilling, and accumulating project knowledge (`note`/`recall`) that compounds across sessions. They stand on their own and are useful whether or not you use facilitated-waterfall at all. One of them (`to-waterfall`) happens to offer a path *into* the waterfall, but that's an option, not the point.

| Skill | What it does |
|-------|--------------|
| `note` | Records what a session learned into a fixed six-file knowledge base in `docs/knowledge/`; also prunes stale notes. |
| `recall` | Loads knowledge relevant to a query from `docs/knowledge/` before you start work. The read half of `note`. |
| `review` | Reviews a diff/branch/PR or a waterfall document for correctness, quality, consistency. |
| `simulate` | Traces every execution branch of a function/route/system and writes the findings out. |
| `supervise` | Reviews implementation against plans + ADRs in iterative cycles with fresh subagents. |
| `survey` | Honest landscape assessment: what exists, what's unclear, what's blocking. |
| `to-waterfall` | Translates a conversation's findings into Directions, Epics, Tasks, ADRs, or CONTEXT.md entries. |
| `zoom-in` | Drills relentlessly into a plan's details to reach shared understanding. |
| `zoom-out` | Steps back to question whether a direction is worth pursuing at all. |

If you *do* run facilitated-waterfall, `to-waterfall` provides an optional path back into it: do exploratory work with these skills, then promote what's worth keeping into the append-only system.

## Core principles

- **Append-only.** Artifacts are not edited in place once they record a decision. A changed decision is captured by appending a *new* ADR that supersedes the old one — the history of why stays intact.
- **Completion is recorded, not inferred.** `implement` appends one line to `docs/plans/LEDGER.md` when a Plan's verification passes — done once, never edited. A wrong entry is fixed by a new line, not a rewrite, same as ADR supersession. This is what lets `what-next` and `audit-doc` know a Plan is finished without guessing from code or git history.
- **The `relates` graph is the source of truth.** Links point upward (Epic→Direction, Task→Epic, Plan→Task, ADR→artifact) and are fixed at creation. A child's existence proves its parent was broken down; the codebase proves a Plan was implemented.
- **Code is ground truth; docs are the boundary.** When they disagree, that disagreement *is* the finding. The `conventions` audit reports it rather than silently picking a side.
- **The waterline divides commitment from mechanism.** Below it (module, class, placement) is reversible — the engineer decides freely. Above it (ADR decisions, Direction constraints) is committed — changing it needs an accepted trade-off, recorded as a superseding ADR. Top-down stops at the line and hands off; bottom-up may not overturn a commitment without recorded acceptance.
- **Drill before you write.** Every authoring stage shares one technique: sharpen fuzzy language, probe with concrete scenarios, push back on first answers, and resolve decisions inline rather than batching them.
- **Glossary, not prose.** `CONTEXT.md` holds resolved domain terms only — no implementation detail.

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
  probes/<id>-slug.md      Trigger · Governing docs · Findings · Open questions · Deliberation · Risk · Reconciliation
CONTEXT.md                 Glossary of resolved domain terms
```

Every durable file carries frontmatter with at least `id`, `title`, `created`, and `relates: [...]`, and is numbered sequentially from the highest existing file in its directory. **Probes are the exception**: they are mutable working memory (`open` → `reconciled`/`abandoned`), use collision-free dated ids (`probe-YYYY-MM-DD-slug`), and freeze once reconciled — everything a probe *produces* stays append-only.

## Installation

```sh
./install.sh
```

`install.sh` detects which clients are present and installs into each. It is idempotent — safe to re-run.

| Client | Destination | Invocation |
|--------|-------------|------------|
| Claude Code / VS Code extension | `~/.claude/commands/<namespace>/<skill>.md` (symlinked) | `/<namespace>:<skill>` |
| Cursor | `~/.cursor/commands/<namespace>-<skill>.md` (symlinked) | `/<namespace>-<skill>` |
| OpenCode | `~/.config/opencode/skills/<namespace>-<skill>/SKILL.md` (copied) | `<namespace>-<skill>` |
| Mirai | `~/.mirai/skills/<namespace>-<skill>/SKILL.md` (copied) | `<namespace>-<skill>` |

> OpenCode and Mirai require YAML frontmatter (`name` + `description`) in every skill; the installer validates this and refuses to install a namespace with any skill missing it.

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
