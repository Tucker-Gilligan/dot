---
name: repo-conventions
description: The house coding conventions for this repository — language/framework choices, project structure, naming, error handling, testing, and PR norms. Load automatically whenever writing, refactoring, or reviewing code in this repo so output matches existing patterns and avoids AI slop. Background knowledge; not a user command.
user-invocable: false
---

# Repository conventions

> Fill these in for your repo. Keep it short and specific — vague guidance produces vague code.
> Delete sections that don't apply. The goal: any agent writes code that looks like it was
> written by your team, so reviewers spend their time on logic, not style nitpicks.

## Stack & tooling
- **Languages / frameworks**: <!-- e.g. TypeScript + React 19, Python 3.12 + FastAPI -->
- **Package manager / build**: <!-- e.g. pnpm; uv; make targets -->
- **Lint / format (source of truth)**: <!-- e.g. eslint + prettier; ruff + black. Match these; don't hand-format. -->
- **Run/build/test commands**: <!-- e.g. `pnpm test`, `make check` -->

## Project structure
<!-- Where things live so new code lands in the right place.
e.g. feature code in src/features/<name>/, shared utils in src/lib/, tests colocated as *.test.ts -->

## Naming & style
- <!-- e.g. camelCase for vars/functions, PascalCase for components/types, SCREAMING_SNAKE for consts -->
- <!-- e.g. no default exports; one component per file -->

## Error handling
- <!-- e.g. throw typed errors from src/errors; never swallow with empty catch; log via logger, not console -->

## Testing
- **Framework**: <!-- e.g. vitest / pytest / go test -->
- **Conventions**: <!-- e.g. arrange-act-assert; test behavior not implementation; one assertion focus per test -->
- **What must be tested**: business logic, edge cases, and any auth/data/money path. Skip trivial getters.

## API / data / migrations
- <!-- e.g. all DB changes go through migrations in db/migrations; migrations must be reversible -->
- <!-- e.g. public API changes require updating the OpenAPI spec + a changelog entry -->

## PR norms
- <!-- e.g. small focused PRs; conventional commit titles; run diff-digest before requesting review -->
- <!-- e.g. business-logic changes must be called out explicitly in the PR description -->

## Anti-slop rules (always)
- Match the patterns of the file you're editing; read a neighbor before inventing a new approach.
- No speculative abstractions, dead code, or "while I'm here" changes.
- No leftover debug output, commented-out code, or unused imports/vars.
- Don't invent APIs — verify a symbol/library method exists before using it.
- If existing code already solves something, reuse it instead of duplicating.

## Maintenance
Keep this file current. When a convention is decided in review, add it here so the agents learn it
once and stop repeating the mistake.
