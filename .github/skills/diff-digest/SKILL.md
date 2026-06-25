---
name: diff-digest
description: Produce a token-efficient digest of pending git changes (stat, changed files, full diff) plus an automated risk-pattern scan (debug leftovers, secrets, removed auth, raw SQL, destructive migrations, oversized changes). Use before code review, when preparing a PR, or whenever asked "what's risky in my diff" / "review my changes". Pairs with the `/pr-prep` prompt.
argument-hint: "[base-branch] (optional, e.g. main)"
---

# Diff Digest

This skill gathers everything needed to review a change set **deterministically via a script**,
so the model spends tokens on judgment — not on reading the raw diff line by line. This file is reference material — reference it from an agent body via `#file:.github/skills/diff-digest/SKILL.md`.

## When to use
- Preparing a PR / pre-review self-check.
- Any request like "what changed", "what's risky here", "review my diff before I push".
- As the first step the **PR Prep** prompt runs.

## How to run
To run this skill's script, ask the active agent to execute `execute/runInTerminal` with one of (read-only — no commits, pushes, or resets):

```bash
bash .github/skills/diff-digest/scripts/collect-diff.sh            # uncommitted work vs HEAD
bash .github/skills/diff-digest/scripts/collect-diff.sh main       # this branch vs origin/main
```

If the user hasn't said which base to compare against and the branch clearly targets one
(e.g. a feature branch off `main`), pass that base. Otherwise run with no argument to digest
uncommitted work. Ask only if it's genuinely ambiguous.

See the script: [collect-diff.sh](./scripts/collect-diff.sh). Tune `MAX_DIFF_LINES` (env var) for very large diffs.

## What the script outputs
1. **Change stat** and **changed-files** list.
2. **Risk flags** — automated, pattern-based. Each flag is a *lead to verify*, not a verdict:
   - debug leftovers (`console.log`, `debugger`, `print`, `pry`, …)
   - `TODO`/`FIXME`/`HACK`/`XXX`
   - possible secrets (keys, tokens, passwords, private-key headers)
   - raw / concatenated SQL
   - broad exception handling, disabled/`.only` tests
   - dependency-manifest changes
   - migration / destructive schema changes (DROP, TRUNCATE, remove_column, …)
   - **removed** auth/permission checks
   - oversized change set
3. **Full diff** (capped).

## How to use the output
1. Run the script and read its output.
2. Treat each `[FLAG]` as something to confirm or dismiss with a one-line reason — never ignore silently. False positives are fine to wave off explicitly.
3. Feed the digest into the review. If the **PR Prep** prompt invoked this skill, use the digest to produce the structured self-review (change summary, inventory, sequence/dependencies, business-logic changes, ranked risks, author checklist).
4. The script flags patterns; **you** still judge business-logic correctness and blast radius — the scan can't.

## Notes
- The script never mutates the repo. If git history isn't available (e.g. shallow clone missing the base), fetch the base branch first or compare against a ref that exists locally.
