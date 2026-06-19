---
name: to-waterfall
description: Translates findings from a conversation session into facilitated-waterfall artifacts like Directions, Epics, Tasks, ADRs, or CONTEXT.md entries. Use after a discussion to capture emergent decisions, validated problems, resolved domain terms, or implementation plans before they are lost.
---

Translate findings from the current session into the appropriate facilitated-waterfall artifact. The session may have used zoom-in, zoom-out, survey, or open conversation — the goal is to capture what emerged before it is lost.

## Phase 1 — Extract

Identify what the session produced. Look for:

- A validated problem or goal worth pursuing → Direction
- A decomposition of work → Epic or Task
- A hard-to-reverse design decision with real trade-offs → ADR
- A domain term that was resolved or clarified → CONTEXT.md entry
- An implementation plan for known work → Plan

A single session may produce more than one artifact type. List what you find before writing anything.

## Phase 2 — Orient

Scan the existing `docs/` structure:

- Does a Direction already exist that this extends or supersedes?
- Does an ADR already cover this decision, or does it conflict with one?
- Is a CONTEXT.md term being redefined, or is this net new?

State explicitly what each finding relates to, supersedes, or leaves untouched. Do not write until this is clear.

## Phase 3 — Write

Write each artifact in the correct location and format:

**Direction** (`docs/directions/NNN-slug.md`) — frontmatter: `id`, `title`, `status: draft`, `created`, `relates: []`. Body: Problem · Appetite · Out of scope · Success signal · Constraints.

**Epic** (`docs/epics/NNN-slug.md`) — frontmatter: `id`, `title`, `status: draft`, `created`, `relates: [<direction id>]`. Body: Goal · Scope · Out of scope.

**Task** (`docs/tasks/NNN-slug.md`) — frontmatter: `id`, `title`, `status: draft`, `created`, `relates: [<epic id>]`. Body: Goal · Notes.

**ADR** (`docs/adr/NNN-slug.md`) — frontmatter: `id`, `title`, `status: accepted`, `created`, `relates: []`. Body: Context · Decision · Consequences.

**CONTEXT.md** — append to the glossary. Term and definition only. No implementation detail.

**Plan** (`docs/plans/NNN-slug.md`) — frontmatter: `id`, `title`, `created`, `relates: [<task id>, <adr ids>]`. Body: Context · Steps · Verification.

Number each new file sequentially from the highest existing file in the target directory. Produce artifacts one at a time, confirming each before moving to the next.

## Rules

- Do not invent findings. Only capture what the session actually produced.
- If the session produced nothing worth preserving, say so.
- If an existing artifact is superseded, update its `status` to `superseded` and add a `superseded-by` field pointing to the new file.
- Do not duplicate content already in the conversation into the artifact verbatim — distil it.
