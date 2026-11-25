# Verifying a test-suite fix

The trigger is a red (or suspiciously green) suite, and the tests' pass/fail depends on **repo state** — what the tests copy or parse from the live tree (frontier, ledger, fixtures) — not only the code under test. Then today's green is a property of the tree, not proof of the code: a fix can pass at HEAD merely because another session's commit happens to leave the state the old code could read. This is the recipe for proving the fix either way.

## Count, then attribute by measurement

Run the suite; group the failures by file and method — a count, not "red". Then attribute the cause by measurement, not by git recency: "the last commit before the red" is a hypothesis, pin the tree and test it. State-dependent failures usually have a boring cause — an item moved out of reach, a ledger line appeared, a fixture changed shape — and the line that owns the cause can sit several commits back, in a file the recent history never touches.

## Pin a tree that reproduces the failure

Find the commit at which the state the failing tests read was last in the shape that breaks them: `git log` on the *files the tests copy or parse*, not on the code you are fixing. Pin that tree (scratch tree or worktree) and run the suite with the **pre-fix** code: it must reproduce the red you were handed — the same count, the same failing methods. Record the pinned commit in Findings. If the pinned tree does not reproduce the failure, the cause attribution is wrong: go back to attribution. Never proceed to a fix proven on a tree that does not fail.

## Prove red→green on the pinned tree

Apply the fix on the same pinned tree and re-run: the suite must go green there. The pair — red pre-fix on the pinned tree, green post-fix on the pinned tree — is the proof. A run on today's tree does not substitute for it.

## Also run at HEAD, and treat the difference as a finding

Run the same suite at HEAD. If the pass counts of the pinned run and the HEAD run differ, the difference is itself a finding: record what state differs between the trees and which tests depend on it. Green at HEAD alone is not a passing verification for a state-dependent suite.

## When HEAD moves under your run, say so

Concurrent sessions can commit while a run is in flight, and what moves is exactly the state your green was measured on. Before closing, compare HEAD with the commit you verified on; if it moved, record the moved commits (id, which stream, what state they changed) as a dated Finding and re-run the suite at the new HEAD. The report states the green at the commit it was verified on and names the commits that moved since — never silently re-claim a green that now rests partly on state you did not verify.

## Record the filter

In Findings, dated: the pinned commit and what was pinned; the pre-fix count on the pinned tree; the post-fix count on the pinned tree; the count at HEAD; the commits that moved in between. A resuming session must be able to re-run the same pair without re-deriving the pinned commit.
