# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). This project is not yet versioned; entries are grouped under **Unreleased** until a first tagged release.

## [Unreleased]

### Added

- `facilitated-waterfall/` namespace: an append-only documentation system implementing the Direction → Epic → Task → Plan → Code pipeline.
  - `shape` — define a Direction (Problem · Appetite · Out of scope · Success signal · Constraints).
  - `breakdown` — decompose a Direction into Epics, or an Epic into Tasks.
  - `design` — interview-driven design decisions, recording ADRs sparingly.
  - `plan` — turn a Task + ADRs into concrete, verifiable steps.
  - `implement` — implement a Plan and verify against the Plan and its ADRs.
  - `audit-doc` — read-only check that an implementation stays inside its governing documents.
  - `what-next` — recommend the best next action by walking the `relates` graph and codebase.
- `general-usage/` namespace: skills usable outside the waterfall, able to feed into it.
  - `note` — record what a session learned into a self-improving knowledge base: a fixed six-file store in `docs/knowledge/`, harvested from the conversation, verified, routed, and pruned to stay current.
  - `recall` — load knowledge relevant to a query from the `note` store before starting work; the read half of `note`.
  - `review` — review code changes or waterfall documents.
  - `simulate` — trace every execution branch of a target and write findings out.
  - `supervise` — iterative implementation review with fresh subagents.
  - `survey` — honest landscape assessment of the current project.
  - `to-waterfall` — promote conversation findings into waterfall artifacts.
  - `zoom-in` — drill into a plan's details.
  - `zoom-out` — question whether a direction is worth pursuing.
- `install.sh` — idempotent installer with client detection for Claude Code / VS Code, Cursor, and OpenCode.
- `README.md` and `CHANGELOG.md`.

### Changed

- Skill names prefixed with their namespace (`facilitated-waterfall-*`, `general-usage-*`) to avoid collisions across clients.
- `what-next` dropped explicit status tracking in favor of deriving the frontier from the `relates` graph and codebase evidence.

### Fixed

- All skills given YAML frontmatter (`name` + `description`); the installer now validates it for OpenCode and skips namespaces with missing frontmatter.
- OpenCode skills installed as `<namespace>-<skill>/SKILL.md` subdirectories rather than flat `.md` files, matching OpenCode's loader.
