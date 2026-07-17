# Research: Patterns Across the Top Claude Code Skill Repositories

**Date:** 2026-07-17
**Method:** Each repo below was researched by fetching real file content (READMEs, actual `SKILL.md`/command files, GitHub API metadata) rather than relying on blog-post summaries — the SEO coverage of this space is thick with inflated/fabricated star counts and skill counts, which is called out explicitly where relevant. Repo #10 is this repository (`skills-public`), included as a grounded baseline for comparison rather than researched externally.

## Repos covered

| # | Repo | Category |
|---|------|----------|
| 1 | [mattpocock/skills](https://github.com/mattpocock/skills) | Personal, curated `.claude` directory |
| 2 | [obra/superpowers](https://github.com/obra/superpowers) (+ `superpowers-skills`) | Enforced methodology framework |
| 3 | [anthropics/skills](https://github.com/anthropics/skills) | Official reference implementation |
| 4 | [wshobson/agents](https://github.com/wshobson/agents) | Multi-harness marketplace, scale-oriented |
| 5 | [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | Pure curation, vendor-skill index |
| 6 | [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | Personal, standardized skill factory |
| 7 | [GetBindu/awesome-claude-code-and-skills](https://github.com/GetBindu/awesome-claude-code-and-skills) | Pure curation, meta-aggregator |
| 8 | [disler/infinite-agentic-loop](https://github.com/disler/infinite-agentic-loop) | Command-based orchestration (non-SKILL.md paradigm) |
| 9 | [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | Curated ecosystem index (skills + hooks + commands + plugins) |
| 10 | this repo (`skills-public`: `facilitated-waterfall` + `general-usage`) | Append-only documentation pipeline |

---

## 1. mattpocock/skills

**1. Prompting techniques** — Socratic interviewing isolated into a reusable primitive (`grilling`, invoked by `grill-me`/`grill-with-docs`): *"Ask the questions one at a time, waiting for feedback on each question before continuing."* Notably, the repo's own skill-writing guide *argues against* negation-based prompting ("don't think of an elephant names the elephant") while still using hard negatives as guardrails of last resort (`to-spec`: *"Do NOT interview the user — just synthesize what you already know"*). Also: anchored vocabulary as compression ("tracer bullet," "seam," "frontier"), forced enumeration/checklists, and explicit state machines (`wayfinder`'s ticket graph: frontier/blocked/fog-of-war/out-of-scope).

**2. Structure** — Folders, not lone files: `skills/<bucket>/<skill-name>/SKILL.md` + optional sibling docs. A custom `disable-model-invocation: true` frontmatter flag distinguishes user-invoked vs. model-invoked skills. Extremely terse (`implement/SKILL.md` is 8 lines). Ships as an installable plugin (`.claude-plugin/marketplace.json`).

**3. Output artifacts** — `to-spec` has a rigid spec template (Problem Statement / Solution / User Stories / Implementation Decisions / Testing Decisions / Out of Scope), explicitly banning file paths/code snippets. `wayfinder` defines a map-document template. `improve-codebase-architecture` produces an HTML report.

**4. Goal / philosophy** — Fixes four named failure modes: misalignment, agent verbosity from missing shared vocabulary, code that doesn't work, architectural entropy. Explicitly positions itself *against* process-owning frameworks ("GSD, BMAD, Spec-Kit... take away your control"). States plainly: *"A skill exists to wrangle determinism out of a stochastic system."*

**5. Relations** — Explicit and graph-like, documented in the README's own routing table. `implement` says *"Use /tdd where possible... use /code-review to review."* `ask-matt` is a dedicated router skill. Rule: "a user-invoked skill may invoke model-invoked skills, but never another user-invoked one."

**Distinctive**: a self-aware, principled theory of prompt engineering embedded in the skill-writing skill itself — it names its own anti-patterns ("sediment," "no-op," "sprawl") and critiques the all-caps NEVER/ALWAYS style common elsewhere in the ecosystem.

---

## 2. obra/superpowers (+ superpowers-skills)

**1. Prompting techniques** — The most coercive framing of any repo studied. Custom pseudo-tags: `<EXTREMELY-IMPORTANT>… IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.` and `<HARD-GATE>` blocks that block progress until a condition is met. A recurring, distinctive device: **"Red Flags" / "Common Rationalizations" tables** — a `Thought → Reality` mapping designed to pre-empt the model's own excuse-making (*"'Emergency, no time for process' → Systematic debugging is FASTER than guess-and-check thrashing"*). Iron-law gates ("NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST"). Graphviz state diagrams embedded directly in the skill body. Skill-writing itself is framed as TDD against subagents: write a "pressure scenario," observe baseline failure, write the skill, re-test — backed by a real eval harness.

**2. Structure** — `skills/<name>/SKILL.md`, minimal frontmatter (`name`, `description` only in the current repo; the older companion `superpowers-skills` repo used a legacy `when_to_use` + `version` shape — evidence of the project migrating conventions over time). Notably includes **executable scripts as first-class skill assets** (not just reference docs), and file-handoff scripts (`review-package`, `task-brief`) that write context to disk rather than pasting it inline — a deliberate context-hygiene mechanism. CLAUDE.md reports a 94% PR rejection rate and requires eval evidence for any change to house style.

**3. Output artifacts** — `brainstorming` writes a design doc to a fixed path (`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`) with a mandatory inline self-review. `writing-plans` enforces a rigid plan template (Goal/Architecture/Tech Stack/Global Constraints/per-task Files+Interfaces+steps) with an explicit **banned-phrases list** ("TBD", "Add appropriate error handling"). A durable progress ledger (`.superpowers/sdd/progress.md`) survives context compaction.

**4. Goal / philosophy** — A full, **mandatory** pipeline: brainstorming → worktrees → writing-plans → subagent-driven-development → TDD → code-review → finish-branch. States outright: "Mandatory workflows, not suggestions." This is the opposite pole from mattpocock's "stay composable, keep control" stance.

**5. Relations** — Tightly and explicitly chained via literal `REQUIRED SUB-SKILL:` annotations inside artifact templates. `using-superpowers` is the bootstrap/router, with a stated priority order (process skills before implementation skills).

**Distinctive**: skill-writing treated as literal red/green TDD against subagents, with a dedicated eval harness (`superpowers-evals`) driving real tmux sessions and an LLM verifier — the most empirical, falsifiable approach to prompt engineering of any repo studied.

---

## 3. anthropics/skills

**1. Prompting techniques** — Doctrine: *all* "when to use" information belongs in the YAML `description`, never the body — and descriptions should be written "pushy" to fight under-triggering. Decision trees for branchy tasks (`webapp-testing` opens with an ASCII tree). Negative constraints are specific, not blanket ("DO NOT read the source until you try running the script first"), paired with ❌/✅ examples. A stated anti-pattern: *"if you find yourself writing ALWAYS or NEVER in all caps... that's a yellow flag — reframe and explain the reasoning"* (a direct contrast with obra/superpowers' house style). Worked "Quick Start" snippets precede deep reference material.

**2. Structure** — The reference implementation of the format: only `name` + `description` required in frontmatter. Canonical three-tier progressive disclosure, explicitly named: (1) metadata always loaded, (2) SKILL.md body (<500 lines ideal), (3) bundled `scripts/`, `references/`, `assets/` loaded on demand. Multi-domain skills fan out via `references/<variant>.md` (e.g. `references/{aws,gcp,azure}.md`) rather than in-body branching. `spec/` (the actual public Agent Skills spec) is deliberately decoupled from `skills/` (examples).

**3. Output artifacts** — Document skills (docx/pdf/pptx/xlsx) produce real office files via bundled scripts. `skill-creator` defines rigorous evaluation artifacts: `evals/evals.json`, `grading.json` (fixed field names the viewer depends on), `benchmark.json/.md`, and a generated HTML review UI.

**4. Goal / philosophy** — Explicitly "demonstration and educational," while some skills (docx/pdf/pptx/xlsx) are literally in production. Positions itself as the reference implementation of a standard independent of Anthropic's own product (agentskills.io). `skill-creator`'s meta-philosophy: skill quality is empirical and evaluable (benchmarked, A/B tested), not a one-shot document.

**5. Relations** — Minimal explicit skill-to-skill chaining; each skill is self-contained and triggered independently by description-matching. The one clear inter-skill relationship: `skill-creator` builds and evaluates other skills. Distinctive: skills reference **live external docs via WebFetch at runtime** (mcp-builder: "Use WebFetch to load https://raw.githubusercontent.com/...") — extending progressive disclosure past the filesystem onto the open web.

**Distinctive**: a description-optimization loop (`scripts/run_loop.py`) that runs actual trigger-accuracy A/B experiments (train/test split, repeated trials, held-out scoring) purely to tune the YAML `description` string — treating a documentation field as a tunable, benchmarked hyperparameter.

---

## 4. wshobson/agents

**1. Prompting techniques** — Nearly every skill repeats a rigid **"## When to Use This Skill"** bullet section in the body — a direct deviation from Anthropic's doctrine of keeping all triggering info solely in the YAML description. House style favors decision/selection tables (a "Sync vs Async Decision Guide"), numbered "Pattern N" code catalogs (denser, more inline-snippet-heavy than Anthropic's skills), and "Common Pitfalls" enumerations in nearly every skill. Literal fill-in-the-blank templates for subagent task handoff (Objective/Owned Files/Requirements/Interface Contract/Acceptance Criteria/Scope Boundaries).

**2. Structure** — `plugins/{plugin}/skills/{skill}/SKILL.md` + optional `assets/`/`references/`; sampled skills lacked `scripts/` (more reference-heavy than tool-bundling, unlike Anthropic's script-leaning document skills). A per-skill `version` field appears in frontmatter — not observed in Anthropic's samples. The whole marketplace is generated from **one Markdown source compiled to five harnesses** (Claude Code, Codex, Cursor, OpenCode, Gemini CLI) via `make generate HARNESS=...`.

**3. Output artifacts** — Mostly inline code patterns meant to be copied into the user's own codebase, not files the skill itself produces (contrast with Anthropic's docx/pdf skills, which emit binary deliverables). Where structured output exists, it's team-coordination task specs consumed by other agents. `marketplace.json` is itself an elaborate package-manifest schema (name/source/description/version/author/homepage/license/category) — absent from anthropics/skills.

**4. Goal / philosophy** — Headline differentiator is multi-harness portability from one source. Scale is an explicit value proposition (marketplace.json advertises plugin/agent/skill counts directly in its metadata). Self-declared as a **downstream consumer** of Anthropic's Agent Skills Specification, not a competing standard.

**5. Relations** — The most explicit documented **agent-to-skill chaining narrative** of any repo studied: *"backend-architect agent → Plans API architecture ↓ api-design-principles skill → provides best practices ↓ fastapi-templates skill → supplies templates."* A dedicated "Agent Teams" plugin category (6 skills) codifies multi-agent orchestration conventions (file-ownership boundaries, blockedBy/blocks dependency graphs) as its own category — structurally absent from anthropics/skills.

**Distinctive**: per-skill semantic versioning plus a formal `evaluation-methodology`/PluginEval skill — a marketplace-scale QA analogue to Anthropic's skill-creator eval loop, but aimed at auditing hundreds of skills rather than iterating one.

---

## 5. VoltAgent/awesome-agent-skills

**Reality check**: the repo itself is 4 files (README, CONTRIBUTING, LICENSE, .gitignore) — a pure link index to other orgs' skills, rendered on a companion site (`officialskills.sh`). "Prompting technique" analysis here applies to the *vendor* skills it links to.

**1. Prompting techniques (linked vendor skills)** — Cloudflare's `wrangler` skill opens with an explicit anti-hallucination directive: *"Your knowledge of Wrangler CLI flags... may be outdated. **Prefer retrieval over pre-training**"* backed by a doc-URL routing table. Stripe's `stripe-best-practices` uses an "Integration routing" table mapping user intent to API + reference file, with hard constraints ("Always recommend a restricted API key over a secret key"). Sentry's `sentry-workflow` is a pure router: *"Trust the skill — read it carefully and follow it. Do not improvise."* Vendor skills are uniformly terse, imperative, and retrieval-biased rather than narrative.

**2. Structure** — Minimal frontmatter; heavy reliance on `references/` subfolders (Stripe: `references/{billing,connect,payments,security,tax,treasury}.md`). Vendor skills are commonly **repackaged per-harness inside the same source repo** (Stripe: `providers/{claude,codex,cursor,grok}/plugin/skills/...`).

**3. Output artifacts** — Advisory/reference only; these steer code the agent writes rather than producing documents.

**4. Goal / philosophy** — Explicitly curation, not content: *"Hand-picked, not AI-slop generated."* CONTRIBUTING is blunt about gatekeeping ("don't submit skills you created 3 hours ago"). The license section disclaims any audit/endorsement of listed projects.

**5. Relations** — Organized strictly by vendor, not task taxonomy. Within individual vendor repos (Sentry), skills cross-reference each other via relative links to a `SKILL_TREE.md`.

**Distinctive**: the clearest evidence in this research of a **vendor-vs-hobbyist rigor gap** — official vendor skills are short, mechanical, and anti-hallucination-hardened by design; hobbyist skills (see #6) are longer, more persona-driven, and more willing to assert domain knowledge inline rather than defer to retrieval.

---

## 6. alirezarezvani/claude-skills

**1. Prompting techniques** — Governed top-down by a single authored style guide (`SKILL-AUTHORING-STANDARD.md`) codifying "10 Patterns." Pattern 2, "Practitioner Voice": *"You are an expert in [domain]... Opinionated > neutral... 'Do X' beats 'You might consider X'"* with explicit anti-patterns flagged (❌ hedging language). Pattern 1, "Context-First," mandates checking for a domain context file before asking the user anything. A sampled skill (`cfo-review`) shows this as a forced six-question interrogation, each with a hard numeric threshold ("Burn multiple above 2x is a problem").

**2. Structure** — Unusually rich frontmatter (`name, description, version, author, license, tags[], compatible_tools[]`). Deep per-domain folders with `scripts/` subfolders holding deterministic Python tools the skill shells out to (e.g. a burn-rate calculator) rather than trusting the model's arithmetic. The entire skill set is mirrored into **five separate harness trees** (`.claude/`, `.codex/skills/`, `.gemini/skills/`, `.hermes/skills/`, `.vibe/skills/`).

**3. Output artifacts** — Standardized by the authoring template's mandatory "Output Artifacts" table and a "Communication" section requiring bottom-line-first answers and confidence tagging (🟢 verified / 🟡 medium / 🔴 assumed). `process-mapper` concretely promises a process map, ranked bottleneck list, and cycle-time analysis (P50/P90, Little's-Law throughput) computed by stdlib Python, not model guesswork.

**4. Goal / philosophy** — Genuinely original content at scale (claimed 355 skills across engineering, marketing, security, C-level advisory), standardized by one author's own house style — the opposite pole from VoltAgent/GetBindu's pure aggregation.

**5. Relations** — Mandatory "Related Skills Navigation" section on every skill, explicitly disambiguating adjacent skills (*"Distinct from sales-pipeline, system-reliability (SLO)..."*). Shared domain context files (`company-context.md`, `marketing-context.md`) function as real cross-skill shared state, not just links.

**Distinctive**: skills shell out to small deterministic scripts for anything computable (burn rate, cycle time), rather than asking the model to compute it — a clear "don't trust the LLM with arithmetic" design choice.

---

## 7. GetBindu/awesome-claude-code-and-skills

**Reality check**: 3 files total (readme, LICENSE, .gitignore) — a single ~112KB README, no hosted skill content.

**1–3. Prompting/structure/artifacts** — None; it is bullet-point descriptions of external repos organized under a standard `awesome-*` TOC format (9 categories: Development, Multi-Agent Systems, Security, Marketing, Domain-Specific, Productivity, Learning, Skill Development).

**4. Goal / philosophy** — Curation, explicitly: *"This list focuses on verified, actively maintained projects... Quality over quantity."* Notably mixes in **paid/commercial listings** (e.g. a $49 sub-agent pack) without visually distinguishing them from free entries — unlike VoltAgent's stated "hand-picked, not slop" purity stance.

**5. Relations** — This repo is itself a **meta-aggregator of repos #5 and #6** in this list, directly citing both (with self-reported counts that don't even agree with each other — a concrete example of the "aggregator marketing figures, not verified totals" risk this research was warned to watch for).

---

## 8. disler/infinite-agentic-loop

This is **not** a SKILL.md-based repo — it's a pair of Claude Code **slash commands** (`.claude/commands/infinite.md`, `prime.md`), useful here specifically as a contrast case.

**1. Prompting techniques** — A single long imperative prompt organized into numbered phases (PHASE 1–5), with an explicit **"ULTRA-THINKING DIRECTIVE"** forcing deliberation before action ("How to prevent duplicate concepts across parallel streams"). Anti-duplication is mechanical, not just "be creative": Phase 2 mandates literally listing existing output files and the highest iteration number present before generating anything, then handing each spawned sub-agent a distinct "Uniqueness Directive" / "Assigned creative direction" via a templated context block. Infinite mode is specified as pseudocode (`WHILE context_capacity > threshold: ...`) with a "Progressive Sophistication Strategy" escalating from Wave 1 ("basic functional replacements") to Wave N ("revolutionary concepts").

**2. Structure** — No YAML frontmatter at all. Plain markdown invoked by explicit name with positional args (`/project:infinite <spec_file> <output_dir> <count>`). This is the core paradigm split: a **command** is an imperative, explicitly-invoked script-like prompt with parsed arguments; a **SKILL.md** is a declarative, auto-discovered capability matched against conversation context via its `description`.

**3. Output artifacts** — Concrete generated files, verified directly: `src/ui_hybrid_N.html` (flat single-file components), `src_group/ui_hybrid_N/{index.html,styles.css,script.js}` (multi-file variant), with `legacy/` holding superseded experiment batches. Inspected content confirms genuine creative divergence between same-numbered iterations across different runs.

**4. Goal / philosophy** — Spec-driven generative divergence at scale: one static spec branches into arbitrarily many non-duplicate creative outputs via parallel sub-agents, bounded only by context-window exhaustion.

**5. Relations** — `prime.md` (a lightweight context-loading command) and `infinite.md` are siblings, not chained — nothing in `infinite.md`'s text invokes `/prime`. The real pipeline logic (spec analysis → directory recon → strategy → parallel dispatch → wave loop) lives entirely inside the one command, executed via repeated Task-tool calls the orchestrator issues to itself.

**Why it matters for this research**: it demonstrates that "skill-like" behavior doesn't require the SKILL.md format at all — command-based orchestration is a legitimate, different paradigm for a different job (bulk generative fan-out vs. single-responsibility capability triggering).

---

## 9. hesreallyhim/awesome-claude-code

**1–3. Prompting/structure/artifacts** — None of its own; it's a curated, **auto-generated** link index. `README.md` is mechanically produced by `generate_readme.py` reading `THE_RESOURCES_TABLE_NEW.csv` + `config.yaml` (which declares category order and an ID-prefix scheme: `docs-`, `research-`, `skill-`, `orchestration-`, etc.). Contribution is structured as data-entry (a CSV row + config category), not prose authoring. "Prompting technique" appears only at the curatorial level: entry descriptions are written skeptically, e.g. flagging one project as "notable for publishing a replication-gated evaluation instead of unsupported quality claims" — an explicit norm against inflated claims, unusual among awesome-lists.

**4. Goal / philosophy** — States its purpose as favoring "resources that were not on the last iteration," explicitly gatekeeping for quality over exhaustiveness; stale entries move to a separate `README_ALTERNATIVES/` file rather than being deleted.

**5. Relations** — Purely by category/sub-category membership (19 top-level categories) and alphabetical sort within them — no dependency graph or invocation chain between listed projects, unlike disler's internally phase-sequenced command.

---

## 10. This repo (`skills-public`) — baseline for comparison

**1. Prompting techniques** — The signature technique, named explicitly and applied identically across every authoring skill (`shape`, `breakdown`, `design`, `plan`, `zoom-in`), is "drill before you write": *"Sharpen fuzzy language... Probe with scenarios... Push back... Resolve inline."* Questions are asked one at a time with a recommended answer offered up front — closer to mattpocock's grilling than obra's coercive gates, but softer in tone (no all-caps imperatives, no rationalization tables).

**2. Structure** — Every skill is a single flat `.md` file (`facilitated-waterfall/plan.md`, `general-usage/review.md`) with `name` + `description` frontmatter — no bundled `scripts/`/`references/`/`assets/` subfolders anywhere in the repo, the leanest structure of any repo studied. Skills are organized into two flat namespaces rather than nested buckets.

**3. Output artifacts** — The most rigorously specified artifact *graph* of any repo studied: a fixed five-stage document pipeline (`Direction → Epic → Task → Plan → Code`, with `ADR` and `CONTEXT.md` as cross-cutting artifacts), each with a fixed section template (e.g. Plan: Context/Steps/Verification) and mandatory frontmatter (`id`, `title`, `created`, `relates: [...]`). Append-only: a changed decision is a *new* ADR that supersedes the old one, not an edit.

**4. Goal / philosophy** — Stated directly: "an agent is only as good as the context it can recover... chat history evaporates; a `docs/` tree does not." Its `relates` graph is explicitly the source of truth, with a codified stance on drift: "code is ground truth; docs are the boundary. When they disagree, that disagreement *is* the finding" (`audit-doc` reports rather than silently resolving it).

**5. Relations** — The tightest, most literal pipeline of any repo studied — not just "skill A can invoke skill B" but a **structural document dependency graph** enforced through the `relates` field and directory numbering convention, checkable independent of any single conversation (`audit-doc`, `what-next` both walk this graph directly rather than relying on a router skill's judgment).

---

## Cross-cutting patterns

### A. Two structural paradigms, not one
Every repo studied is either:
- **Declarative / auto-triggered** (SKILL.md + `description`-matching): mattpocock, obra, anthropics, wshobson, VoltAgent's vendor skills, alirezarezvani, this repo.
- **Imperative / explicitly-invoked command** (no frontmatter, positional args, script-like prompt): disler's `/infinite`.

The SKILL.md paradigm optimizes for silent composability across many capabilities; the command paradigm optimizes for a single, deliberately user-triggered, multi-phase orchestration. Curated lists (VoltAgent, GetBindu, hesreallyhim) sit outside both — they're indexes, not executable prompts.

### B. A coercion spectrum in prompting technique
From softest to hardest:
1. **This repo / mattpocock** — persuasive, principle-explained, negation used sparingly as a last-resort guardrail; mattpocock's own skill-writing guide explicitly argues against blanket negation.
2. **anthropics/skills** — explicitly discourages ALL-CAPS ALWAYS/NEVER as a "yellow flag," prefers explaining *why*.
3. **wshobson/agents, alirezarezvani** — rigid repeated templates ("When to Use This Skill," "Related Skills," confidence tags) enforced by a house style doc, but not coercive in tone.
4. **obra/superpowers** — the hard end: `<EXTREMELY-IMPORTANT>`/`<HARD-GATE>` pseudo-tags, "Red Flags"/rationalization tables that pre-empt the model's own excuse-making, and iron-law gates blocking progress until a condition is met.

Coercion strength correlates with how mandatory the author wants the pipeline to be: obra's is a non-negotiable methodology; mattpocock's is explicitly meant to stay optional and composable.

### C. Artifact rigor correlates with whether the repo enforces a pipeline
Repos with a genuinely enforced multi-stage pipeline (obra, this repo, mattpocock's `to-spec`/`wayfinder`) have the most rigid artifact templates, often with banned-phrase lists or required sections checked structurally. Repos that are single-skill capability libraries (anthropics, wshobson, VoltAgent's vendor skills) have looser, more task-specific output shapes — a document skill emits a real file, an API-design skill emits inline snippets, there's no shared template because there's no shared pipeline to produce a template for.

### D. Skill chaining ranges from graph-verifiable to purely social
- **Structurally enforced** (this repo): a `relates` field + directory convention an external tool (`audit-doc`) can walk and verify independent of any conversation.
- **Explicitly named in prose, not enforced** (obra's `REQUIRED SUB-SKILL:` annotations, mattpocock's `/tdd` → `/code-review` mentions, wshobson's agent→skill→skill worked example): the model is told the chain but nothing checks it happened.
- **Taxonomy-only, no chain at all** (VoltAgent, GetBindu, hesreallyhim): skills relate only by shared category membership.
- **Self-contained, no chaining concept** (anthropics/skills): each skill triggers independently; the only cross-skill relationship is `skill-creator` operating *on* other skills as data, not calling them.

### E. Curation repos are a distinct genre, and their numbers should not be trusted at face value
VoltAgent, GetBindu, and hesreallyhim contain zero-to-minimal skill content of their own — they are link indexes with generation tooling (CSV/YAML → README) or hand-maintained bullet lists. Their headline counts ("1000+ skills," "355 skills") are aggregate or self-reported figures about *other* projects, not independently verified totals — GetBindu's own count for alirezarezvani's repo doesn't even match alirezarezvani's self-reported count. Treat any specific star/skill count encountered via blog coverage of this space with the same skepticism.

### F. A convergent, unplanned split: vendor-authored vs. hobbyist-authored style
Official vendor skills surfaced through VoltAgent's index (Cloudflare, Stripe, Sentry) are short, mechanical, retrieval-biased, and explicitly anti-hallucination-hardened ("prefer retrieval over pre-training," routing tables to reference docs). Hobbyist/personal skills (alirezarezvani, mattpocock, obra) are longer, more persona-driven ("You are an expert in..."), and more willing to assert domain knowledge inline. Neither camp cites the other's convention — this is a convergent, not coordinated, split, and it shows up consistently across every vendor skill sampled.

### G. Evaluation-of-skills-as-a-skill is an emerging, still-rare pattern
Only two repos studied treat skill quality as something to empirically test rather than assert: anthropics/skills' `skill-creator` (A/B-tested trigger descriptions, benchmark.json, a generated HTML eval-review UI) and obra/superpowers (skill-writing as literal TDD against subagents, backed by a real eval harness driving tmux sessions). wshobson has a parallel but shallower analogue (a `PluginEval`/`evaluation-methodology` skill oriented at marketplace-scale QA rather than iterative refinement of one skill). No other repo studied has anything comparable — most skills in most repos are still written and shipped on author conviction alone, without a feedback loop.
