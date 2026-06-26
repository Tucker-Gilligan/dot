---
description: Self-review the pending changes on this branch before requesting code review.
agent: agent
tools: [search/codebase, search, search/usages, edit/editFiles, execute/runInTerminal, execute/createAndRunTask, read/problems, web/githubRepo]
---
Prepare a developer self-review for the pending changes on the current branch. Put the burden of explaining the change on the author *before* a human reviewer ever sees the diff.

If it's ambiguous, ask me which base branch to compare against (e.g. `main`). Then run this flow:

## 1. Diff digest + self-review report
Use the **diff-digest** skill ([#file:${userHome}/Library/Application Support/Code/User/prompts/skills/diff-digest/SKILL.md](${userHome}/Library/Application%20Support/Code/User/prompts/skills/diff-digest/SKILL.md)) to gather the changed files, stat, and full diff against the base branch.

Write a self-review report to `./.pr-review/<branch-name>-<N>.md`, where `<N>` is the next available integer starting at `1` (so the first run is `<branch-name>-1.md`, the second `<branch-name>-2.md`, etc.). Never overwrite an existing report — always increment. Determine `<N>` by listing `./.pr-review/` and picking `max(existing <N> for this branch) + 1`, or `1` if none exist.

The report should cover:
- Summary of the change in plain English.
- File-by-file walkthrough of the diff.
- Risks. **You are the risk-surfacing layer** — there are no specialist review agents in this fleet, so be thorough. Work the **Human-judgment review checklist** in the diff-digest skill (auth, PII / student data, secrets, DB migrations, public API surface, performance, accessibility, debug leftovers) — that section is the authoritative list of what to scan for. Confirm or dismiss each category with a one-line reason; migrations touching student records get a louder callout.
- Test coverage assessment — what's tested, what isn't, what should be.
- Open questions for the reviewer.

Add `.pr-review/` to `.gitignore` if it isn't already.

## 2. Numbered step-comments in the code
Propose concise numbered comments (`// 1. …`, `// 2. …`) at the key change points in the diff that walk a reviewer through *why* each change exists. **Show me the proposed comments first; apply them only after I confirm.** They should be the kind of comments you'd be willing to leave in the code permanently, or strip out after review — your call.

## 3. Understanding check
Walk me through a quick Q&A on the change: pick 3–5 of the riskiest or least-obvious edits and ask me to explain in my own words *why* each one is there and what would break if it weren't. If I can't defend a change, that's a signal to revisit it before opening the PR.

## 4. Draft a PR description
Use the **commit-pr-writer** skill ([#file:${userHome}/Library/Application Support/Code/User/prompts/skills/commit-pr-writer/SKILL.md](${userHome}/Library/Application%20Support/Code/User/prompts/skills/commit-pr-writer/SKILL.md)) to read the repo's actual PR template (`PULL_REQUEST_TEMPLATE.md`, `CONTRIBUTING.md`) and fill it in from the diff. Prompt me for anything the diff can't supply: ticket number, rollout plan, testing notes, screenshots.

## When done
Summarize what you wrote (full `.pr-review/<branch-name>-<N>.md` path, comments added, PR description location) and what the author still needs to verify or fill in before opening the PR.
