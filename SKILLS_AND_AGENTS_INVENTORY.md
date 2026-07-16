# Copilot Customizations Inventory

**Updated:** 2026-07-10
**Repository:** Tucker-Gilligan/dot

> This inventory covers only Copilot customizations committed in this repository.
> It does not list built-in agents, skills, models, or tools supplied by a Copilot client.

## Installation

`install.sh` symlinks `.github/agents/` to `~/.copilot/agents/`, and links the
global instructions and skills into the VS Code prompts directory. There are no
project prompt files in `.github/prompts/`.

## Project Skills

These six skills live in `.github/skills/` and are symlinked by `install.sh`.

#### 1. **commit-pr-writer**
  - Reads repo's PR standards (PULL_REQUEST_TEMPLATE.md, CONTRIBUTING.md)
  - Fills real template matching repo's commit style
  - Prompts for missing information

#### 2. **commit-prep**
  - Runs a diff digest on the staged changes
  - Scans for risk and renders an IDE-style walkthrough: fenced code blocks with a clickable file/line header, correct language tag, surrounding context, and a sequenced annotation on each flagged line
  - Confirms the change is atomic (not bundling unrelated work)
  - Drafts the commit message via `commit-pr-writer`
  - Commit-scoped sibling of `/pr-prep` (one commit, not a whole branch)

#### 3. **diff-digest**
  - Shows stat, changed files, full diff
  - Automated risk scan: debug leftovers, new ESLint suppressions, secrets, removed auth, raw SQL, destructive migrations, generated artifacts, broad changes
  - Human review checklist for code smells, scope/bloat, data/state contracts, side effects, owning tests, and change-shape confidence
  - Pairs with `/pr-prep` skill

#### 4. **pr-prep**
  - Runs diff digest
  - Automated risk scan
  - Explicit scope and code-smell check with a `ready`, `ready with follow-up`, or `not ready` verdict
  - Proportionally traces cross-boundary or unclear behavior through producers, consumers, state, side effects, conditional work, and owning tests
  - Rejects new ESLint suppressions unless the user explicitly approves and documents an exceptional case
  - Requires `verified`, `finding`, or justified `not applicable` trace evidence and a closure gate before returning `ready`
  - Optional `--document` mode writes each outcome to a new timestamped `.pr-prep/*.md` report
  - Renders an IDE-style walkthrough: fenced code blocks with a clickable file/line header, correct language tag, surrounding context, and a sequenced annotation on each flagged line
  - Runs Socratic understanding check, with each question anchored to a clickable file/line link
  - Drafts PR description from repo template

#### 5. **pr-review**
  - Comprehensive PR review with the `/diff-digest` risk scan, scope and atomicity assessment, semantic dependency tracing, and lowest-layer test and lifecycle checks
  - Numbered IDE-style walkthrough with file-by-file, severity-ranked comments
  - Requires trace evidence, a readiness verdict, a closure gate, Socratic questions, and missing-details prompts
  - Surfaces auth/PII/migration concerns and requires automated-flag dispositions
  - Optional `--document` mode writes each review to a new branch-named Markdown file at the repository root

#### 6. **scout**
  - Searches first, reads on budget
  - Returns findings with file/line references

## Custom Agent

### `main`

**Source:** `.github/agents/main.agent.md`

Unified Copilot agent for inline coding tasks and project-skill routing. It
inherits `.github/global.instructions.md`, which defines the routing matrix,
model-tier guidance, and GitKraken-tool prohibition.

## Invocation

Invoke a skill directly or describe a matching task to the `main` agent:

```text
/commit-prep
/diff-digest
/pr-prep
/pr-review <PR URL or branch>
/pr-review <PR URL or branch> --document
/commit-pr-writer [base branch]
/scout <research question>
```
