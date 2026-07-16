---
name: pr-prep
description: Pre-review your own branch before requesting code review. Runs a diff digest, traces behavior through unchanged dependencies and tests, produces a walkthrough with numbered in-code comments, runs a Socratic understanding check, and drafts a PR description from your repo's template.
argument-hint: "[base-branch] [--document] (optional; auto-detects base otherwise)"
---

# PR Prep

Complete pre-review of your own branch before requesting code review. Validates that you understand every line of your changes.

## When to use

- **Before opening a PR**: "Check my changes before I push them up."
- **Before requesting review**: "I'm about to ask for feedback — let me make sure I understand my own changes."
- **After making changes**: Validates that your implementation matches your intent.

## How to invoke

```
/pr-prep
```

(pre-reviews HEAD vs the auto-detected base branch, e.g., `origin/main`)

```
/pr-prep main
```

(explicitly specify the base branch to compare against)

```
/pr-prep --document
```

(`--document` writes the complete outcome to a new branch-named Markdown file under `.pr-prep/`)

```
/pr-prep main --document
```

(compare against an explicit base and write a new report)

## What it does

1. **Runs `/diff-digest`**: gathers the diff, surfaces automated risk patterns.
2. **Scans for risk and maintainability** (auth, PII, secrets, migrations, debug leftovers, new ESLint suppressions, code smells, unnecessary dependencies, and oversized or broad changes). A new ESLint suppression makes the branch `not ready`: fix the underlying lint violation rather than suppressing it. Only an exception explicitly approved by the user and documented in the review may proceed.
3. **Performs a scope and code-smell check**: state the intended scope, classify changed files as necessary or incidental, and look for duplication, dead or commented-out code, speculative abstractions, excessive nesting/complexity, unclear naming, and dependency or configuration bloat. Record a clear verdict: `ready`, `ready with follow-up`, or `not ready`, with the specific files or changes behind it.
4. **Performs a proportional semantic dependency trace**: changed files are the starting inventory, not always the review boundary. First classify each behavior change by whether it crosses a state, I/O, asynchronous, cache, authorization, public-contract, or UI boundary, or has an unclear data contract. Deepen the trace when one of those conditions applies; isolated low-risk changes may be marked `not applicable` with a brief reason.
   - Follow calls into services/helpers and follow returned data into stores, caches, selectors, renderers, or other consumers.
   - Verify declared types against the producer's real runtime shape. Treat `unknown`, broad casts, optional chaining, or runtime shape checks added near typed state as prompts to inspect the source contract, not as proof that the code is safe.
   - Where a reused path can have side effects, inventory relevant I/O, shared-state writes, subscriptions, loading state, navigation, telemetry, and user-visible intermediate state. For example, prefetch/count/probe calls must not accidentally perform full-load side effects or expose partial data.
   - Check conditional work for eager evaluation. Role-, flag-, or mode-specific dependencies should not be fetched, selected, or subscribed to on paths that do not need them.
   - When behavior or regression risk changes, find the lowest practical owning test layer even when its test file is unchanged. Check meaningful positive, negative, and context-specific paths; do not assume higher-level tests cover lower-layer contracts and side effects.
   - Read enough surrounding implementation to verify the full chain. Do not stop after one hop when state, I/O, or UI behavior continues elsewhere.
   - For interactive or stateful changes, trace every boundary where an external event, value, or lifecycle signal enters the changed code. For each boundary, identify the value/state before the event, the framework or library update that happens automatically, the handler's observed value, and the expected state afterward. Treat event ordering, two-way binding, callbacks, subscriptions, modal close/dismiss signals, retries, cancellation, and component destruction as behaviors to verify rather than implementation details.
   - For parent/child or producer/consumer contracts, trace nullability, optionality, defaults, and runtime dereferences end to end. A guard on one render path is not proof that a value is non-null on every open, callback, async completion, or error path.
   - When a change introduces a new workflow that resembles an existing one, compare the nearest analogous implementation for state transitions, lifecycle cleanup, event bindings, error handling, and tests. Differences require an intentional explanation or a finding.
   - For each stateful boundary, check the meaningful transition matrix: initial state, primary success path, alternate input or repeated interaction, cancellation/close, failure, empty or missing data, and teardown. Require a test at the lowest practical layer for each transition that could regress; isolated method tests do not prove framework wiring or event ordering.
5. **Records trace evidence before assigning readiness**: include a compact table for relevant behavior changes with the changed entry point, dependencies/consumers inspected, applicable contracts and side effects, test evidence, and a status of `verified`, `finding`, or `not applicable`. Keep evidence brief for isolated changes and expand it for cross-boundary or uncertain behavior. An applicable but unverified contract, side effect, consumer, or test is `not ready` or `ready with follow-up`, never silently `ready`.
6. **Produces a numbered walkthrough you can read like your IDE**: for each risky change, render a fenced code block showing the actual code — not just a description of it — so reviewing feels like scrolling the file in the editor. Each block must include:
   - A clickable header link to the location: `[path/to/file.ext:Lstart-Lend](path/to/file.ext#Lstart-Lend)`.
   - The relevant lines fenced with the **correct language tag** for syntax highlighting (` ```ts `, ` ```py `, etc.).
   - **2–4 lines of surrounding context** above and below the changed line(s) so the snippet reads in place.
   - A sequenced `// [n] ...` annotation on the exact line, in the file's comment syntax, explaining the intent/risk.
   Number the blocks in the order they appear through the diff. This rendered walkthrough is the primary output — the author should be able to review every flagged change without leaving the chat.
7. **Socratic check**: asks 2–4 targeted questions, scoped only to the items flagged risky or unclear in the scope/smell and dependency checks, to confirm you understand them. **Anchor every question to the exact location it's about** with a clickable Markdown link (`[file.ext:Lstart-Lend](path/to/file.ext#Lstart-Lend)`) so you can jump straight to the code — reuse the path/line of the matching numbered walkthrough comment, and link each distinct file/line range separately (never comma-join ranges). If a question spans multiple spots, list each link. Only omit the link when the question is about something with no single location (e.g. an absent test or a cross-cutting concern), and say so explicitly.
8. **Drafts a PR description**: fills your repo's actual `PULL_REQUEST_TEMPLATE.md` or generates a structured description.
9. **Prompts for missing details**: ticket links, rollout plans, screenshots, testing notes.
10. **Optionally documents the complete outcome**: when `--document` is present, write the full result after the analysis is complete to `.pr-prep/<sanitized-branch-name>-<n>.md`. Sanitize branch separators and other filename-unsafe characters consistently. Start `n` at `0` and choose the next unused integer for that branch, so successive reports are named `<branch>-0.md`, `<branch>-1.md`, `<branch>-2.md`, and so on; never overwrite an earlier report. The file must include the readiness verdict, change inventory, dependency-trace evidence, risk flags and dispositions, walkthrough, Socratic questions, PR description draft, and missing-details prompts. Report the created path in the response.

## Readiness closure gate

Before returning `ready`, classify each item below as `verified` or `not applicable` for each relevant behavior change. Give a brief reason for `not applicable`; investigate or lower the verdict for anything applicable but unverified.

1. No new ESLint suppression was added, including inline directives, ignored files/patterns, disabled rules, or suppression-baseline entries.
2. Data contracts match the real producer and consumer shapes.
3. Reused paths do not introduce unintended I/O, shared-state, lifecycle, or user-visible side effects.
4. Alternate execution modes such as background, prefetch, cache-fill, probe, or count paths do not leak partial state or foreground behavior.
5. Conditional paths avoid unnecessary or incorrectly eager work.
6. Behavior and regression risks have meaningful coverage at the lowest practical owning test layer.
7. Relevant unchanged dependencies, consumers, and tests were inspected and named when the change crossed a boundary or the contract was unclear.

For every relevant interactive, asynchronous, lifecycle, or parent/consumer boundary, also record the boundary's transition evidence before assigning `ready`. At minimum, name the entry event or producer, the state/contract observed by the handler or consumer, the terminal and failure paths checked, the analogous implementation if one exists, and the owning test. If event ordering, lifecycle signals, nullability, or teardown remains unverified, the verdict cannot be `ready`.

Passing tests and a clean automated risk scan do not override an incomplete trace for an applicable risk.

## How to use the output

1. **Review the walkthrough**: each flagged change is shown as a code snippet with its file/line header — read it like your editor. Does each change make sense? Are the risk assessments fair?
2. **Inspect the dependency-trace evidence**: confirm the review followed behavior through state, I/O, UI consumers, and owning tests rather than stopping at changed files.
3. **Resolve the scope/smell verdict**: remove, justify, or defer incidental and bloated changes before requesting review.
4. **Answer the Socratic questions**: Can you explain your changes confidently? Each question links to the code it's about — click through to verify before answering.
5. **Approve the PR description**: The skill drafts it; you finalize it.
6. **You own the explanation**: Before you push, you've thought through every line. That's the whole point.

## Risk checklist

Use the single-source checklist in the **diff-digest** skill (`Human-judgment review checklist` plus its automated flags) — auth, PII/student data, secrets, migrations, API surface, performance, accessibility, debug leftovers. Don't maintain a parallel copy here; diff-digest is the source of truth and `/pr-prep` runs it as step 1.

## Notes

- **You own this**: The skill proposes; you confirm or reject. Never push a PR you can't explain.
- Reports are local review artifacts and are ignored by Git; delete old reports when they are no longer useful.
- Use this **before** `git push` and **before** opening a PR.
- If the skill surfaces a genuine bug or design issue, fix it first — then re-run `/pr-prep`.
