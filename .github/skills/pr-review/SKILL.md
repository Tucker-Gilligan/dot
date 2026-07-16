---
name: pr-review
description: Review someone else's PR with structured, severity-ranked comments. Runs the same risk scan as `/pr-prep`, produces file-by-file comments, and surfaces auth/PII/migration concerns.
argument-hint: "[PR URL or branch] [--document] (e.g. https://github.com/owner/repo/pull/123)"
---

# PR Review

Review someone else's PR with structured, severity-ranked comments and automated risk analysis.

## When to use

- **Code review**: "Review this PR for me."
- **PR URL or branch**: Point at `https://github.com/…/pull/123` or a remote branch.
- **Async code review**: You're reviewing a PR asynchronously and want structured feedback.

## How to invoke

```
/pr-review https://github.com/owner/repo/pull/123
```

```
/pr-review https://github.com/owner/repo/compare/main...feature-branch
```

```
/pr-review https://github.com/owner/repo/pull/123 --document
```

(`--document` writes the complete review to a new branch-named Markdown file at the repository root.)

## What it does

1. **Fetches the PR or branch**: reads the diff and the PR description or comparison context.
2. **Runs the same risk scan as `/diff-digest`**: flags debug leftovers, secrets, migrations, auth changes, new ESLint suppressions, generated artifacts, and broad changes.
3. **Reads the PR template and context**: understands what was promised, what is out of scope, and which tests or rollout details are expected.
4. **Checks scope and atomicity**: identifies necessary versus incidental files, detects unrelated or speculative work, and records whether the PR is a coherent change or should be split.
5. **Checks maintainability and code smells**: looks for duplication, dead or commented-out code, excessive complexity or nesting, unclear naming, unnecessary dependencies, configuration bloat, and missing documentation.
6. **Performs a proportional semantic dependency trace**: changed files are the starting inventory, not always the review boundary. For behavior that crosses state, I/O, asynchronous, cache, authorization, public-contract, or UI boundaries, follow calls into services and helpers and follow returned data into stores, caches, selectors, renderers, and other consumers.
   - Verify declared types against the producer's real runtime shape. Treat `unknown`, broad casts, optional chaining, and nearby runtime shape checks as prompts to inspect the source contract, not as proof that it is safe.
   - Inventory I/O, shared-state writes, subscriptions, loading state, navigation, telemetry, and user-visible intermediate state for reused paths and prefetch, count, probe, cache-fill, or background modes.
   - Check role-, flag-, and mode-specific paths for unnecessary eager fetching, selection, or subscriptions.
   - Trace parent/child and producer/consumer contracts end to end, including nullability, optionality, defaults, and runtime dereferences.
7. **Checks tests at the lowest practical owning layer**: find meaningful positive, negative, alternate-input, repeated-interaction, failure, empty-data, cancellation, and teardown coverage. Do not assume a higher-level test covers a lower-layer contract or side effect.
8. **Checks interactive and lifecycle transitions**: for each relevant external event, callback, subscription, retry, cancellation, modal close, async completion, or component destruction, identify the state before the event, the framework update, the handler-observed value, the expected terminal or failure state, cleanup, and the analogous implementation if one exists.
9. **Records trace evidence before assigning a verdict**: include a compact table for each relevant behavior change with the changed entry point, dependencies and consumers inspected, contracts and side effects, test evidence, and a status of `verified`, `finding`, or `not applicable`. An applicable but unverified item is a finding; do not silently mark it ready.
10. **Produces a numbered IDE-style walkthrough**: for each risky or unclear change, show the actual code in a correctly tagged fenced block with a clickable file/line header, 2–4 lines of surrounding context, and a sequenced comment annotation on the exact line.
11. **Produces structured review comments**:
   - Grouped by file and severity (blocker, important, nice-to-have), including maintainability and scope/bloat findings.
   - Each comment explains the concern and suggests a fix.
   - Each comment links the exact file/line (`path#Lstart-Lend`) for quick reference.
12. **Requires a student-data / FERPA section**: every review explicitly states whether the diff touches PII, student records (grades, rosters, attendance), or destructive migrations on those tables — even if the answer is "none." This is the differentiator from a generic reviewer; never omit it.
13. **Confirms or dismisses every automated flag**: each `[FLAG]` from the diff-digest scan gets a one-line confirm/dismiss with a reason — no silent passes on secrets, removed auth, raw SQL, or removed authorization.
14. **Assigns a review verdict**: return `ready`, `ready with follow-up`, or `not ready`. Do not return `ready` when an applicable contract, side effect, consumer, test, lifecycle transition, or automated flag remains unverified or unresolved.
15. **Runs a Socratic understanding check**: ask 2–4 targeted questions about risky or unclear findings, anchored to clickable file/line links. Omit questions only when no risky or unclear items remain.
16. **Prompts for missing details**: identify absent ticket links, rollout plans, screenshots, testing notes, migration plans, or other context needed to approve the PR.
17. **Optionally documents the complete review**: when `--document` is present, write the full review after the analysis is complete to the current repository root as `<sanitized-reviewed-branch-name>-<n>.md`. Use the branch being reviewed, including the PR head branch when the input is a PR URL or compare range. Sanitize branch separators and other filename-unsafe characters consistently. Start `n` at `0` and choose the next unused integer for that branch, so successive reviews are named `<branch>-0.md`, `<branch>-1.md`, `<branch>-2.md`, and so on; never overwrite an earlier review. The file must include the verdict, scope and atomicity assessment, dependency-trace evidence, test and transition evidence, risk flags and dispositions, walkthrough, severity-ranked comments, Socratic questions, missing-details prompts, and student-data / FERPA section. Report the created path in the response.
18. **Returns the review** (you post it to GitHub; the skill doesn't).

## Comment format

Comments are grouped by severity:

- **Blocker** — must fix before merge (logic errors, auth bypasses, PII leaks, migration rollback failures).
- **Important** — should fix (performance issues, missing tests, unclear code, API-breaking changes).
- **Nice-to-have** — optional improvements (naming, style, documentation).

Each comment includes:
- A markdown link to the line(s) in question (`path#Lstart-Lend`).
- What's wrong or what could be better.
- A suggested fix (if applicable).

For the full set of things to scan beyond the automated flags (auth, PII/student data, migrations, API surface, performance, accessibility), use the **diff-digest** skill's `Human-judgment review checklist` — it is the single source of truth; don't restate it here.

## How to use the output

1. **Copy the comments**: the skill generates them; you post them to GitHub.
2. **Inspect the walkthrough and trace evidence**: verify that each finding is grounded in the actual code and that dependencies, consumers, side effects, and tests were followed far enough.
3. **Answer the Socratic questions and resolve missing details**: do not approve an applicable item that remains unverified.
4. **You author the review**: add a summary at the top (what's good about this PR, one-line theme) and preserve the verdict and required student-data section.
5. **Request changes or approve**: GitHub handles that; the skill just gives you the evidence and draft comments.

## Review closure gate

Before returning `ready`, classify each applicable item as `verified` or `not applicable` with a brief reason:

1. No new ESLint suppression, ignored file/pattern, disabled rule, or suppression-baseline entry was added.
2. Data contracts match the real producer and consumer shapes.
3. Reused paths do not introduce unintended I/O, shared-state, lifecycle, or user-visible side effects.
4. Background, prefetch, cache-fill, probe, count, and alternate execution modes do not leak foreground behavior or partial state.
5. Conditional paths avoid unnecessary or incorrectly eager work.
6. Behavior and regression risks have meaningful coverage at the lowest practical owning test layer.
7. Relevant unchanged dependencies, consumers, and tests were inspected and named when the change crossed a boundary or the contract was unclear.
8. Relevant interactive, asynchronous, lifecycle, and parent/consumer transitions have evidence for entry, success, failure, cancellation, repeated interaction, empty data, and teardown paths.

Passing tests and a clean automated scan do not override an incomplete trace or unresolved review finding.

## How this differs from the default GitHub Copilot reviewer

- **Domain-specific**: a required FERPA/COPPA + student-data section the stock reviewer won't reliably produce.
- **Deterministic**: runs the diff-digest pattern scan (secrets, removed auth, raw SQL, destructive migrations) and forces each flag to be confirmed or dismissed — rule-based, not just model-inferred.
- **You author it**: runs locally/read-only and hands you a draft to post, rather than auto-commenting as a bot.

## Notes

- Without `--document`, the skill is read-only (no mutations to the PR or codebase). With `--document`, it creates one local Markdown review artifact at the repository root.
- You author the final review; the skill does the analysis and suggests comments.
- For your **own** PR, use `/pr-prep` instead — that's a self-review workflow with a walkthrough and PR description draft.
