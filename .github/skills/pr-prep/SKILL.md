---
name: pr-prep
description: Pre-review your own branch before requesting code review. Runs a diff digest, automated risk scan, produces a walkthrough with numbered comments, runs a Socratic understanding check, and drafts a PR description from your repo's template.
argument-hint: "[base-branch] (optional, e.g. main; auto-detects otherwise)"
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

## What it does

1. **Runs `/diff-digest`**: gathers the diff, surfaces automated risk patterns.
2. **Scans for risk** (auth, PII, secrets, migrations, debug leftovers, oversized changes).
3. **Produces a numbered walkthrough**: for each risky change, a comment explaining the intent.
4. **Socratic check**: asks you clarifying questions about your changes to confirm you understand them.
5. **Drafts a PR description**: fills your repo's actual `PULL_REQUEST_TEMPLATE.md` or generates a structured description.
6. **Prompts for missing details**: ticket links, rollout plans, screenshots, testing notes.

## How to use the output

1. **Review the walkthrough**: Does each change make sense? Are the risk assessments fair?
2. **Answer the Socratic questions**: Can you explain your changes confidently?
3. **Approve the PR description**: The skill drafts it; you finalize it.
4. **You own the explanation**: Before you push, you've thought through every line. That's the whole point.

## Risk checklist (automated + manual)

**Automated checks**: debug leftovers, secrets, auth changes, migrations, oversized diffs, disabled tests.

**Manual verification you must do**:
- Auth & permission logic changes
- PII & student data exposure
- Secrets committed
- DB migrations and rollback plans
- API surface changes (breaking changes)
- Performance implications (N+1, unbounded queries)
- Accessibility changes
- Any business-logic changes

## Notes

- **You own this**: The skill proposes; you confirm or reject. Never push a PR you can't explain.
- Use this **before** `git push` and **before** opening a PR.
- If the skill surfaces a genuine bug or design issue, fix it first — then re-run `/pr-prep`.
