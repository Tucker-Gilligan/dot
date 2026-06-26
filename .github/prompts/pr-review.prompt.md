---
description: Review someone else's pull request — structured comments grouped by file and severity. You draft, the human posts.
agent: agent
tools: [search/codebase, search, search/usages, execute/runInTerminal, read/problems, web/githubRepo]
---
Produce a structured code review for a pull request you did **not** author. The reviewer (the human running this prompt) posts the comments manually after editing — this prompt drafts them, it never posts to GitHub directly.

If it's ambiguous, ask the user for either a GitHub PR URL or a `<remote>/<branch>` ref to compare against its merge base.

## 1. Fetch the diff
Use the **diff-digest** skill ([#file:${userHome}/Library/Application Support/Code/User/prompts/skills/diff-digest/SKILL.md](${userHome}/Library/Application%20Support/Code/User/prompts/skills/diff-digest/SKILL.md)) to gather the changed files, stat, full diff, and risk-pattern scan. Adapt the base argument:

- **GitHub PR URL:** run `gh pr checkout <PR-number>` first (read-only — it just switches your local branch), then invoke diff-digest comparing against `origin/<base-branch>` from the PR metadata.
- **Remote branch (`<remote>/<branch>`):** invoke diff-digest comparing against the branch's merge base with its likely target (ask if unclear).

Do **not** modify the working tree beyond what `gh pr checkout` does. Never commit, push, amend, or run `git reset`.

## 2. Risk scan — same checklist as `/pr-prep`
You are the risk-surfacing layer for this review (no specialist agents in this fleet). Work the **Human-judgment review checklist** in the diff-digest skill — that section is the authoritative list, shared with `/pr-prep`. It covers:

- Auth / authorization, PII & student data (FERPA / COPPA), secrets, DB migrations, public API surface, performance, accessibility, debug / dev leftovers.

Confirm or dismiss each category; migrations touching student records (grades, rosters, attendance) get a louder callout. Fold the findings into the grouped, severity-tagged comments in step 3.

## 3. Produce review comments
Output structured review comments **to the chat** (no file written — the reviewer copy-pastes or feeds them to `gh pr review`). Group by file. For each comment include:

- **File + line(s):** `path/to/file.ts:L42` or `path/to/file.ts:L42-L58`.
- **Severity:** `blocker` (must fix before merge) / `nit` (preference, non-blocking) / `question` (need the author to explain).
- **Comment:** short, specific, actionable. Reference the exact line behavior if useful.

Example output shape:

```
### src/api/grades.ts
- **L88-L94 — blocker.** Removes the `requireTeacher` check before the grade-write endpoint. Was this intentional? If so, the new authorization gate isn't obvious from the diff.
- **L120 — nit.** Replace `SELECT *` with the four columns this loop actually reads.

### db/migrations/20260626_add_grade_history.sql
- **L1-L40 — blocker.** `ALTER TABLE grades ADD COLUMN history_id NOT NULL` with no default and no backfill will fail on the existing production table. Needs either a default or a two-step deploy.
```

Lead with blockers, then questions, then nits. Skip files with no comments — silence is fine.

## 4. Author questions
Separate from inline comments, surface **2–3 high-level questions** for the PR author — things the reviewer should ask in the PR conversation (not on a specific line). Examples:
- "Is this migration safe to run on the production `grades` table mid-quarter?"
- "Why drop the integration test for the rostering endpoint?"
- "What's the rollback plan if the new feature flag misfires?"

## 5. Summary line
End with one line the reviewer can paste as the overall PR review comment. Examples:
- "Two blockers around auth on the grade-write path; the migration needs a rollback plan. Otherwise looks good — left a few nits."
- "Looks good. Two questions and a nit; nothing blocking."

## What this prompt does NOT do
- **Post comments to GitHub.** The reviewer posts them. Even with `gh` available, the prompt only drafts.
- **Edit the PR's code.** Never. You're reviewing, not implementing.
- **Approve, request changes, or merge.** Reviewer-only actions stay with the reviewer.
- **Run tests on the PR.** Out of scope — surface missing test coverage as a comment instead.
