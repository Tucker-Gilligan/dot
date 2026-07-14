---
name: diff-digest
description: Produce a token-efficient digest of pending git changes (stat, changed files, full diff) plus an automated risk-pattern scan (debug leftovers, ESLint suppressions, secrets, removed auth, raw SQL, destructive migrations, generated artifacts, broad changes). Use before code review, when preparing a PR, or whenever asked "what's risky in my diff" / "review my changes". Pairs with the `/pr-prep` skill.
argument-hint: "[base-branch] (optional, e.g. main)"
---

# Diff Digest

This skill gathers everything needed to review a change set **deterministically via a script**,
so the model spends tokens on judgment — not on reading the raw diff line by line. This file is reference material — reference it from an agent body via `#file:${userHome}/Library/Application Support/Code/User/prompts/skills/diff-digest/SKILL.md`.

## When to use
- Preparing a PR / pre-review self-check.
- Any request like "what changed", "what's risky here", "review my diff before I push".
- As the first step the **pr-prep** skill runs.

## How to run
The script ([scripts/collect-diff.sh](./scripts/collect-diff.sh)) lives in this user-level prompts folder, **outside the user's code repo**. Invoking it by absolute path from a `runInTerminal` call inside the user's repo triggers a cross-workspace permission prompt. To avoid that, the agent must **inline the script body via a heredoc** so the terminal command contains no path outside the active repo.

Procedure (read-only — no commits, pushes, or resets):

1. Use `read/files` (the `read_file` tool) to load the full body of [scripts/collect-diff.sh](./scripts/collect-diff.sh) into context. Reading from the prompts folder is already permitted because this skill itself is loaded from there.
2. Issue a single `execute/runInTerminal` call that pipes the script body to `bash -s` via a quoted heredoc, passing the optional base branch as `$1`:

   ```bash
   bash -s -- "<base-or-empty>" <<'COLLECT_DIFF'
   # ... paste the full contents of scripts/collect-diff.sh here, verbatim ...
   COLLECT_DIFF
   ```

   - Omit the base (`bash -s -- ""`) for uncommitted-work-vs-HEAD.
   - Pass a base branch (`bash -s -- "main"`) to compare HEAD vs `origin/main`.
   - The quoted heredoc terminator (`'COLLECT_DIFF'`) prevents shell expansion of the script body. Do not rename the terminator unless the script ever contains the literal string `COLLECT_DIFF`.
3. To raise the diff cap on very large change sets, prefix the env var on the same line: `MAX_DIFF_LINES=8000 bash -s -- "$BASE" <<'COLLECT_DIFF' … COLLECT_DIFF`.

If the user hasn't said which base to compare against and the branch clearly targets one
(e.g. a feature branch off `main`), pass that base. Otherwise run with no argument to digest
uncommitted work. Ask only if it's genuinely ambiguous.

`scripts/collect-diff.sh` remains the single source of truth — do not maintain a parallel copy. Re-read it each run so any edits to the script take effect immediately.

## What the script outputs
1. **Change stat** and **changed-files** list.
2. **Risk flags** — automated, pattern-based. Each flag is a *lead to verify*, not a verdict:
   - debug leftovers (`console.log`, `debugger`, `print`, `pry`, …)
   - `TODO`/`FIXME`/`HACK`/`XXX`
   - possible secrets (keys, tokens, passwords, private-key headers)
   - raw / concatenated SQL
   - broad exception handling, disabled/`.only` tests
   - new ESLint suppressions: inline disable directives, ignored files/patterns, disabled rules in ESLint config, and suppression baseline entries
   - dependency-manifest changes
   - migration / destructive schema changes (DROP, TRUNCATE, remove_column, …)
   - **removed** auth/permission checks
   - generated/build artifacts
   - broad change shape (many files or changed lines)
3. **Full diff** (capped).

## How to use the output
1. Run the script and read its output.
2. Treat each `[FLAG]` as something to confirm or dismiss with a one-line reason — never ignore silently. False positives are fine to wave off explicitly.
3. Feed the digest into the review. If the **pr-prep** skill invoked this one, use the digest to produce the structured self-review (change summary, inventory, sequence/dependencies, business-logic changes, ranked risks, author checklist).
4. The script flags patterns; **you** still judge business-logic correctness and blast radius — the scan can't.

## Human-judgment review checklist
The automated flags above are pattern-based leads. Beyond them, **you** must scan for the following — the regex can't catch intent. This is the single source of truth for the review checklist; `/pr-prep` and `/pr-review` both reference it rather than maintaining their own copies.

- **Auth / authorization** — added/removed/loosened checks, role changes, missing `requireAuth`-style guards.
- **PII & student data (FERPA / COPPA)** — fields like `email`, `dob`, `ssn`, `student_id`, `grade`; logs that include user data; new third-party data egress (analytics, AI APIs, webhooks).
- **Secrets** — hardcoded tokens, API keys, passwords, private keys, `.env` content committed.
- **DB migrations** — destructive ops (`DROP`, `TRUNCATE`, `RENAME`), non-concurrent index creation, `NOT NULL` adds without defaults/backfill, type narrowing, missing rollback. Migrations touching student records (grades, rosters, attendance) get a louder callout.
- **Public API surface** — renamed/removed endpoints, changed response shapes, removed query params.
- **Data and state contracts** — where data crosses a boundary or its shape is unclear, verify declared types against the actual producer, transformation, persistence/state, serialization, and consumer shapes. Treat new `unknown`, broad casts, defensive shape checks, and optional chaining as signals to trace the real contract.
- **Side effects and lifecycle** — where reused calls can have side effects, trace relevant I/O, subscriptions, loading state, shared-state/cache writes, events, navigation, telemetry, and stale or partial intermediate state. Prefetch, count, probe, and background work are examples of paths that may need separation from foreground behavior.
- **Performance and conditional work** — N+1 queries, unbounded loops/queries, `SELECT *`, sequential `await`s in a loop, large in-memory loads, and eagerly evaluated work that is only needed for one role, flag, mode, or branch.
- **Test ownership and branch coverage** — when behavior or regression risk changes, find the lowest practical owning test layer even when its tests are unchanged. Check meaningful positive, negative, context, state-transition, and failure paths; do not assume higher-level tests cover lower-layer contracts.
- **Accessibility** (if UI changed) — missing `alt`, unlabeled form controls, removed focus outlines, non-interactive elements with `onClick`, positive `tabindex`.
- **Debug / dev leftovers** — `console.log`, `debugger`, `TODO`, commented-out code, test-only flags left on.
- **ESLint suppressions** — reject new inline disable directives, ignored files/patterns, disabled rules, and suppression-baseline entries. Fix the underlying lint violation instead. Do not dismiss these as generated or pre-existing merely because a suppression tool created the added entry; any exception requires explicit user approval and a documented reason.
- **Maintainability / code smells** — duplicated logic, dead or commented-out code, speculative abstractions, excessive nesting or long functions, unclear naming, and unnecessary indirection.
- **Scope / bloat** — formatting-only churn, unrelated files, generated artifacts, dependency or configuration changes not required by the feature, and behavior changes that could be split into a separate PR. Classify each changed file as required, supporting, or incidental; remove, justify, or defer incidental work.
- **Change-shape confidence** — explain why the number of files and changed lines is appropriate, and call out any generated or mechanically rewritten content separately from authored behavior.

The changed-file list is an inventory, not always the review boundary. Apply these checks proportionally: deepen inspection for cross-boundary, stateful, asynchronous, I/O, cache, authorization, UI, or unclear-contract changes; mark a check `not applicable` with a brief reason for isolated low-risk changes. Applicable but unverified risks cannot receive a clean verdict.

## Notes
- The script never mutates the repo. If git history isn't available (e.g. shallow clone missing the base), fetch the base branch first or compare against a ref that exists locally.
