# skills

A collection of AI-agent skills (slash commands) for Claude Code, Cursor, and OpenCode, organized into two namespaces:

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

The core methodology. A waterfall pipeline where work flows downward and each stage produces a committed artifact:

```
Direction → Epic → Task → Plan → Code
                  ⮑ ADR (cross-cutting decisions)
                  ⮑ CONTEXT.md (shared glossary)
```

| Skill | Stage | What it does |
|-------|-------|--------------|
| `shape` | Direction | Interviews you to define a Direction (Problem · Appetite · Out of scope · Success signal · Constraints). |
| `breakdown` | Epic / Task | Decomposes a Direction into Epics, or an Epic into Tasks. |
| `design` | ADR | Interviews you about design decisions, walking the design tree and recording ADRs sparingly. |
| `plan` | Plan | Turns a Task + its ADRs into concrete, numbered, verifiable steps. |
| `implement` | Code | Reads a Plan + ADRs, drills ambiguities, implements, and verifies against both. |
| `audit-doc` | — | Read-only. Checks whether what was built stays inside what was decided. |
| `what-next` | — | Surveys the `relates` graph and codebase to recommend the single best next action. |

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
- **The `relates` graph is the source of truth.** Links point upward (Epic→Direction, Task→Epic, Plan→Task, ADR→artifact) and are fixed at creation. A child's existence proves its parent was broken down; the codebase proves a Plan was implemented.
- **Code is ground truth; docs are the boundary.** When they disagree, that disagreement *is* the finding. `/audit-doc` reports it rather than silently picking a side.
- **Drill before you write.** Every authoring skill shares one technique: sharpen fuzzy language, probe with concrete scenarios, push back on first answers, and resolve decisions inline rather than batching them.
- **Glossary, not prose.** `CONTEXT.md` holds resolved domain terms only — no implementation detail.

## Artifact layout

facilitated-waterfall skills read and write under `docs/` in the *target* project (not this repo):

```
docs/
  directions/NNN-slug.md   Problem · Appetite · Out of scope · Success signal · Constraints
  epics/NNN-slug.md        Goal · Scope · Out of scope
  tasks/NNN-slug.md        Goal · Notes
  plans/NNN-slug.md        Context · Steps · Verification
  adr/NNNN-slug.md         Decision · Consequences
CONTEXT.md                 Glossary of resolved domain terms
```

Every file carries frontmatter with at least `id`, `title`, `created`, and `relates: [...]`. Files are numbered sequentially from the highest existing file in their directory.

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

> OpenCode requires YAML frontmatter (`name` + `description`) in every skill; the installer validates this and refuses to install a namespace with any skill missing it.

Skills are referred to by bare name throughout this README (`shape`, `plan`, …); how you actually invoke one depends on the client — see the invocation column above.

## A typical flow

1. `shape` a Direction for a new initiative.
2. `breakdown` it into Epics, then an Epic into Tasks.
3. `design` the hard decisions, recording ADRs where the choice is irreversible, surprising, and a real trade-off.
4. `plan` a Task into numbered steps with observable verification.
5. `implement` the Plan.
6. `audit-doc` to confirm the code stayed inside its boundaries.
7. `what-next` whenever you're unsure where the frontier is.
