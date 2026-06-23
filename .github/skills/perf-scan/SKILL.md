---
name: perf-scan
description: Scan a change for common performance smells — N+1 queries, SELECT *, unbounded/unpaginated queries, sequential awaits in loops, nested loops, blocking I/O in the request path, and large in-memory loads. Use when reviewing code for performance or scalability, or when something is slow. Powers the Performance Engineer agent.
argument-hint: "[base-branch] (optional, e.g. main)"
context: fork
---

# Performance scan

Fast static pass for performance smells so the Performance Engineer can focus on measuring and
fixing the real bottleneck. Read-only.

## How to run
```bash
bash .github/skills/perf-scan/scripts/scan.sh        # uncommitted vs HEAD
bash .github/skills/perf-scan/scripts/scan.sh main   # branch vs origin/main
```

Script: [scan.sh](./scripts/scan.sh).

## Important caveat
Static analysis **cannot** confirm a bottleneck — these are leads. A `SELECT *` on a 10-row
config table doesn't matter; an N+1 on a class roster at term start does. Always:
1. Confirm the flagged code is on a hot path (high frequency or large input).
2. **Measure** (profile/benchmark/query log) before changing anything.
3. Optimize the one that actually moves your target metric at *peak* load.

## What it flags
`SELECT *`; fetch-all/unbounded queries; sequential `await` in loops; `async` callbacks in
`.map/.forEach`; possible N+1 ORM calls; nested loops; blocking sleep/sync I/O in request paths;
list endpoints without pagination; large in-memory parses/loads; cache opportunities.

## Notes
`context: fork` keeps output out of the main conversation (needs `github.copilot.chat.skillTool.enabled`; inline otherwise). For real numbers, pair with a profiler and a load test sized to peak (semester start / exam windows), not average traffic.
