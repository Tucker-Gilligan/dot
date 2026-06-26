---
name: pr-review
description: Review someone else's PR with structured, severity-ranked comments. Runs the same risk scan as `/pr-prep`, produces file-by-file comments, and surfaces auth/PII/migration concerns.
argument-hint: "[PR URL or branch] (e.g. https://github.com/owner/repo/pull/123)"
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

## What it does

1. **Fetches the PR or branch**: reads the diff.
2. **Runs the same risk scan as `/diff-digest`**: flags debug leftovers, secrets, migrations, auth changes, etc.
3. **Reads the PR template and context**: understands what was promised in the description.
4. **Produces structured review comments**:
   - Grouped by file and severity (blocker, important, nice-to-have).
   - Each comment explains the concern and suggests a fix.
   - Callouts for risky patterns (auth, PII, migrations, performance).
5. **Returns the review** (you post it to GitHub; the skill doesn't).

## Comment format

Comments are grouped by severity:

- **Blocker** — must fix before merge (logic errors, auth bypasses, PII leaks, migration rollback failures).
- **Important** — should fix (performance issues, missing tests, unclear code, API-breaking changes).
- **Nice-to-have** — optional improvements (naming, style, documentation).

Each comment includes:
- The line(s) in question.
- What's wrong or what could be better.
- A suggested fix (if applicable).

## How to use the output

1. **Copy the comments**: the skill generates them; you post them to GitHub.
2. **You author the review**: Add a summary at the top (what's good about this PR, one-line theme).
3. **Request changes or approve**: GitHub handles that; the skill just gives you the bullets.

## Notes

- The skill is read-only (no mutations to the PR or codebase).
- You author the final review; the skill does the analysis and suggests comments.
- For your **own** PR, use `/pr-prep` instead — that's a self-review workflow with a walkthrough and PR description draft.
