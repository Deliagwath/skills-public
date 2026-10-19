# Handbook — the session machinery

The reference half of `facilitated-waterfall/conventions`. Cites to `conventions → Handbook → Inherit` and `conventions → Handbook → Deposit at a close` resolve here; the core (`SKILL.md`) keeps only the pointer.

The handbook is a workspace's short, graded lessons for working in it. It lives at `docs/handbook/` and is the one store that the knowledge skills (`note`, `recall`) write and read. Other skills cite this section rather than restating it.

| File | Holds |
|------|-------|
| `index.md` | Read-first: one line per file with its `last verified` date, and one `last pruned: DATE · N entries` line. |
| `map.md` | Purpose and entry points only, one line per area. Structure is derived by `sp module <path>`, never written down. |
| `commands.md` | How to build, run, test and deploy; setup; required env. |
| `gotchas.md` | Lessons in the shape Moment / Reflex / Instead / Because. |
| `conventions.md` | "How we do X here", each with its reason. |

- **Five files, fixed.** A fact is routed to one of them or dropped. Terms go to `docs/CONTEXT.md` (and product terms to `docs/PRODUCT.md`), never to the handbook.
- **Entries.** Each is atomic, with `Because:` (or `not recorded`), `Stage:` (`provisional · established · canonical · superseded`) and an optional `· portable`. `note` holds the full entry rules.
- **Anchors name symbols.** A new entry points at code as `` `Symbol.member` (path) ``, with no line number, so it survives edits. `sp def` resolves it, with grep as the fallback. Older `path:line` anchors stay valid.
- **Warrants.** A probe can be an entry's warrant. The origin probe goes in the source (`` Source: `Sym.member` (path) · probe-<id> ``), and a promotion records the probe that justified it (`Stage: established ← probe-<id>`).
- **Research is the contrast.** Long-form material lives in `docs/research/` and is lookup-only: it is never inherited and never pruned. An existing `docs/knowledge/` is treated the same way. It is never written to, moved or renamed.
- **Nothing leaves the handbook except into a probe.** A removed entry (wrong, stale, superseded, merged away or idle) is moved word for word, with its reason, into the probe that removed it. It becomes sealed history, which is looked up and never deleted. `docs/` may be gitignored, so a plain deletion could not be recovered.
- **`sp`** (*The `sp` script*) is how a session reads the handbook's links. Always pass the target path, so it resolves the right workspace.

### Inherit

A session reads what its workspace knows at fixed **inherit points**: moments the skill already passes through. Each skill names its points and the `sp` query for each. This is how to take one.

1. **Ask `sp` about the target**, never cwd:
   - a code path: `sp file <path>`, `sp module <dir>` or `sp docs <symbol|path>`;
   - an artifact (a doc-shaped trigger, such as "direction-021"): `sp tree <id>` for where it stands and what is next, and `sp trace <id>` for its intent trace;
   - a product decision or exclusion: `sp docs D-NNN`. It gives the `docs/PRODUCT.md` row, what supersedes it, and the docs that cite it as `PRODUCT.md#D-NNN`.

   Pass `--role top-down` from `top-down` and `direct`. With no target yet, make no call, and say so.
2. **Read by tier.** Read `always` (`docs/handbook/index.md`) first. Then read `on-match` docs in rank order, at the lines `sp` lists, until the `budget` line's share is used. Of a governing doc, read the constraint sections first, with `sp show`: an ADR's Decision (`sp show adr-0005 Decision`), a Direction's Constraints and Out of scope, a Task's Goal. `sp outline <id>` lists a doc's sections and item ids with their sizes. `lookup` docs are sealed. Open one only for a stated reason, such as a `supersedes … (lookup)` pointer to a decision the successor may not restate.
3. **Over share, trim and say so.** On `over share: trim on-match`, stop at the share and name what was left unread. The budget never blocks the work.
4. **Take the intent trace** from `sp trace <id>` on the nearest governing artifact.
5. **State read depth at entry**, in the same shape as a resume block. Put the `sp` budget line (or `sp absent` / `no target path`) first, then one line per doc: `FULL`, `PARTIAL (<sections>)` or `NOT_READ (<why>)`, then each sealed doc opened and why. A probe carries this at the head of Governing docs, and other skills put it at the top of their output.

**Without `sp`**, take the same points by the text rules: walk `relates` upward, grep `docs/` for the path and its symbols, read the constraint sections first, and leave sealed artifacts (reconciled or abandoned probes, ledgered Plans, superseded ADRs) unread unless needed. The read-depth statement still applies.

### Deposit at a close

A probe's close turns what it learned into handbook entries, and keeps the handbook small. `bottom-up` Phase 5 runs this before `reconciled`. The model decides every step; there is no confirmation step with the human, because entries start `provisional` and the cut test prunes them.

1. **Deposit.** For each Finding, ask: *would the next session in this area act differently knowing it?* If yes, and it was not already carried into an ADR, a Task or `docs/CONTEXT.md`, write it as an entry in the file it routes to. Use `note`'s format, `Stage: provisional`, with `Because:` taken from the Finding (or `not recorded`), and a symbol-anchored source with this probe as the warrant: `` Source: `Sym.member` (path) · probe-<id> ``. If an entry on the same subject exists, update it instead.
2. **Promote or demote.** An entry the probe names as relied on, without surprise, moves up one stage, `Stage: established ← probe-<id>`. "Names" means in a read-depth block, a Finding or a Deliberation line. An entry the probe found wrong is fixed in place, or removed into the probe, and the change is said loudly. Never promote on a hunch: no citation, no warrant.
3. **Cut test, when triggered.** The **area** is the paths this probe changed or anchored. Its entries are the ones `sp file` / `sp module` links into those paths. Without `sp`, grep the handbook for those paths and symbols. Run the test when either trigger holds:
   - **size:** `sp`'s `handbook` footer line for the area reads `over: cut test due at close`. The area's entries may use a quarter of the role's inheritance share; with no budget set, this trigger is off;
   - **fence:** this probe's work makes the last Task of an Epic, or the last Epic of a Direction, `implemented` (read from the ledgers).

   Truth comes first: re-verify each entry in the area against the code, and fix or remove the wrong ones. Then ask of each true entry: *has this changed a decision since the area was last pruned?* Look for a citation in a probe, or a mistake it would have prevented.
   - **Earns its place:** keep it.
   - **True but idle, above `provisional`:** demote it one stage.
   - **True but idle, `provisional`:** retire it into this probe.
   - **The code already says it:** retire it.
   - **`canonical`:** cut only with a stated reason.

   Only the area's entries are in scope. A whole-handbook prune at every close is not.
4. **Gate.** Reconciliation carries one **Deposit** line naming each entry added, promoted, demoted or retired, by file and subject, or the words `nothing durable`. Retired entries follow, verbatim, each with its reason. Update `last verified` in `index.md` for each file touched. If the cut test ran, also update `last pruned: DATE · N entries`.
