---
name: scout
description: Research across a large or multi-repo surface (read-only). Searches first, reads on a budget, returns findings with file/line references.
argument-hint: "[research query] (e.g. 'find all error handlers' or 'where is the auth middleware')"
---

# Scout

Research across a large or multi-repo surface (read-only). Searches first, reads on a budget, returns findings with file/line references.

## When to use

- **"Find all occurrences of X"** — across the entire codebase or multiple repos.
- **"How does the codebase do Y?"** — trace a pattern across many files.
- **"Where is feature Z?"** — locate related code in a large monorepo.
- **"Show me examples of X"** — find real patterns in the code rather than guessing.
- **Before designing**: research the current state before proposing changes.

## How to invoke

```
/scout find all error handlers in the codebase
```

```
/scout where is the auth middleware defined and how is it used
```

```
/scout search for all fetch/http calls and list patterns
```

## What it does

1. **Searches first**: uses regex and keyword patterns to locate candidate files.
2. **Reads on a budget**: pulls relevant snippets rather than the entire codebase.
3. **Correlates findings**: groups related patterns, finds common implementations.
4. **Returns a summary**:
   - Files found + line numbers.
   - Key patterns and examples.
   - Files ruled out (searched but irrelevant).
   - Open questions (if any leads are inconclusive).

## How to use the output

The output is **findings only** — use it to:
- **Understand the current state**: before you design a change, know what exists.
- **Find examples**: see how similar things are done in your codebase.
- **Answer architectural questions**: "where should this go?", "is there already a pattern for this?"

**You decide the next step**: the skill hands off to you or another agent (Planner for design, Implementer for changes).

## Notes

- **Read-only**: Scout never edits, runs tests, or proposes changes.
- **Multi-repo capable**: works across GitHub or local clones if configured.
- **Token-efficient**: uses search + targeted reads instead of loading entire files.
- **Hands off**: after research, you route elsewhere (Planner for design, Implementer for changes).
