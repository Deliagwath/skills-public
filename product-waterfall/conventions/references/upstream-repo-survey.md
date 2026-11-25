# Upstream repo survey — grounding an open-source adoption

The recipe for `Grounding external dependencies` when the dependency is a repo the unit might adopt as its base (or swap between). Goal: one defensible candidate table, a source-grounded capability delta, and the remainder named as spikes. Run it before a Direction or Task commits to the adoption.

## 1 — Candidate space (metadata)

GitHub REST works unauthenticated via `curl` (60 req/hour per IP — batch calls, save responses to files, grep locally):

- One project: `curl -s https://api.github.com/repos/OWNER/NAME` — read `stargazers_count`, `pushed_at`, `license.spdx_id`, `forks_count`, `open_issues_count`, and **`default_branch`** (step 2 needs it).
- The variant space: `curl -s "https://api.github.com/search/repositories?q=<name>"` for the ecosystem, plus `orgs/<org>/repos?per_page=30&sort=pushed` for the org family (server, clients, extensions, docs, packaging).
- Judge liveness by `pushed_at` first; stars measure popularity. A repo with no push in months leaves the candidate set; an archived repo says so in `archived`.
- With `gh` authenticated, `gh search repos` / `gh repo view` return the same data; the curl paths are the unauthenticated route.

## 2 — Capability grounding (source tree)

Feature-presence claims come from the source tree:

1. `curl -sL "https://api.github.com/repos/OWNER/NAME/git/trees/<default_branch>?recursive=1"`, with the `default_branch` read in step 1 (`main` and `master` both occur).
2. Save the JSON to a file, then grep the path list for the feature domain (`backup|restore|scheduler|sync|…`); file names locate the territory before reading it.
3. Fetch the few files that matter from `https://raw.githubusercontent.com/OWNER/NAME/<default_branch>/<path>`, and read **setting names, defaults, cron expressions, flags, and shipped client names** as the evidence for "it already provides X". A setting with a default, or a test file that pins the format, is strong evidence.
4. The code search API needs auth; trees-grep plus raw fetch is the unauthenticated route.
5. A docs site that returns nothing to text extraction (JS-rendered docs under `curl` plus tag-strip) has told you nothing: go to the tree.

## 3 — Scope delta

Line the unit's requirements up against the source-grounded feature list. Three buckets, each cited:

- **Already provided** → the unit configures it. When a shipped feature *is* the unit's success signal (a scheduled backup, a restore path), the acceptance becomes "configure and demonstrate," and the schedule is mechanism.
- **Provided with a collision** → it conflicts with an existing docs/PRODUCT.md decision or out-of-scope rule (a shipped web UI against an exclusion, a client fork against a client rule). That is a waterline question for `reflect`, resolved before the unit is written.
- **Missing** → this is the work. When the whole delta is "configure and push to storage," say so plainly; the unit's appetite and success signal get cheaper.

## 4 — Remainder → named spikes

Whatever reading cannot verify — per-environment behaviour, client compatibility of a specific extension or source set, quotas in practice — is recorded as a named spike for the unit's engineering, as `Grounding external dependencies` does for vendor dependencies. The Direction carries the candidate and the spike, and promises verified capabilities only.
