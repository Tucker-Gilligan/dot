---
name: commit-prep
description: Pre-commit self-check for the work you're about to commit on the current branch. Runs a diff digest on the staged changes, scans for risk, produces a numbered in-code walkthrough, confirms the change is atomic, and drafts the commit message via commit-pr-writer. Scoped to a single local commit — not a whole-branch PR review.
argument-hint: "[no args — operates on staged changes; pass --all to include unstaged]"
---

# Commit Prep

Pre-commit self-check for a single local commit on the **current branch**. Validates that the work you're about to commit is coherent, atomic, and risk-free before you run `git commit`. This is the lighter, commit-scoped sibling of `/pr-prep`: same instincts, but it looks at one commit's worth of staged changes instead of a whole branch vs a base.

## When to use

- **Right before `git commit`**: "Check what I'm about to commit."
- **Mid-feature checkpoints**: you're committing incrementally on a working branch and want each commit to be clean and self-contained.
- **After staging**: "Is this staged change atomic, or am I bundling unrelated work?"

Use **`/pr-prep`** instead when you're done with the whole branch and about to open a PR — that one compares against a base, drafts a PR description, and runs the Socratic understanding check.

## How to invoke

```
/commit-prep
```

(checks the **staged** changes — `git diff --cached` — for the commit you're about to make)

```
/commit-prep --all
```

(also includes unstaged tracked changes, for when you intend to `git commit -a`)

## What it does

1. **Runs `/diff-digest` on the staged set**: gathers the staged diff and surfaces automated risk patterns. With `--all`, includes unstaged tracked changes too.
2. **Scans for risk and maintainability** (auth, PII, secrets, migrations, debug leftovers, code smells, unnecessary dependencies, and oversized or broad changes) — the same single-source checklist diff-digest owns.
3. **Produces a numbered walkthrough you can read like your IDE**: for each risky staged change, render a fenced code block showing the actual code — not just a description of it — so reviewing feels like scrolling the file in the editor. Each block must include:
   - A clickable header link to the location: `[path/to/file.ext:Lstart-Lend](path/to/file.ext#Lstart-Lend)`.
   - The relevant lines fenced with the **correct language tag** for syntax highlighting (` ```ts `, ` ```py `, etc.).
   - **2–4 lines of surrounding context** above and below the changed line(s) so the snippet reads in place.
   - A sequenced `// [n] ...` annotation on the exact line, in the file's comment syntax, explaining the intent/risk.
   Number the blocks in the order they appear through the staged diff, so the author can review every flagged change without leaving the chat.
4. **Atomicity check**: flags whether the staged set is a single coherent change or bundles unrelated work that should be split into separate commits.
5. **Drafts the commit message**: hands off to **`/commit-pr-writer`** to generate a Conventional Commits message from the actual staged diff, matching the repo's existing commit style.

## How to use the output

1. **Review the walkthrough**: each staged change is shown as a code snippet with its file/line header — read it like your editor. Does each change make sense? Are the risk assessments fair?
2. **Act on the atomicity flag**: if the change bundles unrelated work, unstage and split before committing.
3. **Approve the commit message**: the skill drafts it; you finalize and commit.
4. **You own the commit**: you've thought through every staged line before it lands in history.

## Risk checklist

Use the single-source checklist in the **diff-digest** skill (`Human-judgment review checklist` plus its automated flags) — auth, PII/student data, secrets, migrations, API surface, performance, accessibility, debug leftovers. Don't maintain a parallel copy here; diff-digest is the source of truth and `/commit-prep` runs it as step 1.

## Notes

- **Read-only on history**: the skill never runs `git commit`, `git add`, or any mutation — it analyzes the staged set and drafts the message. You commit.
- **Scoped to one commit**: it deliberately does *not* draft a PR description or run the full Socratic check — that's `/pr-prep`'s job.
- If the walkthrough surfaces a genuine bug or non-atomic bundle, fix or split it first — then re-run `/commit-prep`.
