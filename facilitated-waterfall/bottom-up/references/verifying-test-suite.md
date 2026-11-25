# Verifying a test-suite fix

The trigger is a red (or suspiciously green) suite whose pass/fail depends on **repo state** — what the tests copy or parse from the live tree (frontier, ledger, fixtures) — as well as the code under test. Green at HEAD then describes the tree; the proof of the code is a red→green pair on a pinned tree. This is the recipe.

## Count, then attribute by measurement

Run the suite and group the failures by file and method, as a count. Treat "the last commit before the red" as a hypothesis, and test it on a pinned tree. State-dependent failures usually have a plain cause — an item moved out of reach, a ledger line appeared, a fixture changed shape — and the line that owns it can sit several commits back, in a file the recent history does not touch.

## Pin a tree that reproduces the failure

Find the commit at which the state the failing tests read was last in the shape that breaks them: `git log` on the *files the tests copy or parse*. Pin that tree (scratch tree or worktree) and run the suite with the **pre-fix** code: it reproduces the red you were handed — the same count, the same failing methods. Record the pinned commit in Findings. When the pinned tree does not reproduce the failure, return to attribution.

## Prove red→green on the pinned tree

Apply the fix on the same pinned tree and re-run: the suite goes green there. The pair — red pre-fix and green post-fix, both on the pinned tree — is the proof.

## Also run at HEAD

Run the same suite at HEAD. When the pass counts of the pinned run and the HEAD run differ, record what state differs between the trees and which tests depend on it, as a finding.

## When HEAD moves during the run

Before closing, compare HEAD with the commit you verified on. When it moved, record the moved commits (id, which stream, what state they changed) as a dated Finding and re-run the suite at the new HEAD. The report states the green at the commit it was verified on and names the commits that moved since.

## Record the filter

In Findings, dated: the pinned commit and what was pinned; the pre-fix count on the pinned tree; the post-fix count on the pinned tree; the count at HEAD; the commits that moved in between — enough for a resuming session to re-run the pair directly.
