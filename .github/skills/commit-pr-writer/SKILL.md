---
name: commit-pr-writer
description: Generate a conventional-commit message for staged changes, or a structured pull-request description for a branch, derived from the actual diff. Reads the repo's PR standards (PULL_REQUEST_TEMPLATE.md, CONTRIBUTING.md) and fills the real template, matching the repo's commit style and prompting the author for anything missing. Use when asked to write a commit message, draft a PR description, or summarize changes for review.
argument-hint: "[base-branch for PR description, e.g. main] (omit for a commit message)"
---

# Commit & PR writer

Generates commit messages and PR descriptions **from the real diff**, in the repo's existing
style. A script gathers the context (free) so the model only writes the prose. This file is reference material — reference it from an agent body via `#file:${userHome}/Library/Application Support/Code/User/prompts/skills/commit-pr-writer/SKILL.md`.

## How to run
The script lives outside whatever repo you're currently in (it's part of the user-level Copilot config). Invoke it by absolute path through the `~/.copilot/skills/` symlink — that resolves to the canonical version in the dotfiles repo, regardless of the active workspace:

```bash
bash "$HOME/.copilot/skills/commit-pr-writer/scripts/gather.sh"         # commit message for staged changes
bash "$HOME/.copilot/skills/commit-pr-writer/scripts/gather.sh" main    # PR description for branch vs origin/main
```

VS Code may show a one-time prompt the first time it runs a script from outside the active workspace — approve it. Read-only; never commits or pushes. It also prints recent commit titles — **match that style** (prefix casing, scope usage, length).

## Commit message format (Conventional Commits)
```
<type>(<optional scope>): <imperative summary, ≤72 chars>

<body: what & why, wrapped ~72 cols. Omit if the summary is self-explanatory.>

<footer: BREAKING CHANGE: …  /  Refs #123>
```
Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `chore`, `ci`.
Rules: imperative mood ("add", not "added"); summary describes the *change*, not the activity;
mark behavior-changing edits, never bury a `BREAKING CHANGE`.

## PR description format
**If the repo has a PR template or contributing rules** (the script prints them under
`PR STANDARDS`), fill *that* template and follow those rules — do not substitute the generic
format below. Use the default only when the repo has no template.

**Prompt the author interactively** for anything the diff can't supply: ticket/issue link,
rollout & rollback plan, screenshots/recordings for UI, what was tested, and reviewers. Ask only
for what's actually missing; don't interrogate.

Default format (when no repo template exists):
```
## Summary
<2–4 sentences: what this does and why.>

## Changes
- <grouped bullets of the meaningful changes; collapse trivial/mechanical ones>

## Business-logic / behavior changes
<explicitly list any; "none" if purely refactor/cosmetic>

## Risk & rollout
<migrations, feature flags, ordering, rollback notes — or "low risk">

## Testing
<what was added/run to verify>
```

## Rules
- Derive everything from the diff. Don't invent changes that aren't there, and don't omit ones that are.
- Keep it scannable — a reviewer should grasp the PR in 20 seconds.
- If the diff suggests an undocumented behavior change, surface it rather than smoothing it over.
- For a full risk pass before review, use the **diff-digest** skill / **PR Prep** prompt; this skill is about the write-up, not the audit.
