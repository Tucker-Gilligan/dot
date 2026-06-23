---
name: migration-safety
description: Review database migrations for data-loss and downtime risk before they ship. Scans changed migration files for destructive ops (drop/rename/truncate), blocking changes (type changes, NOT NULL, non-concurrent indexes), backfills, and missing rollback paths. Use whenever a change includes a DB migration, especially for student records (grades, rosters, attendance).
argument-hint: "[base-branch] (optional, e.g. main)"
context: fork
---

# Migration safety

Student data is unforgiving: a bad migration can lose grades/rosters or lock tables during peak
load (semester start, exam windows). This skill scans changed migration files and applies a
safe-migration checklist. Read-only.

## How to run
```bash
bash .github/skills/migration-safety/scripts/check.sh        # uncommitted vs HEAD
bash .github/skills/migration-safety/scripts/check.sh main   # branch vs origin/main
```

Script: [check.sh](./scripts/check.sh). It classifies findings as **DESTRUCTIVE** (data loss),
**BLOCKING** (locks/downtime at scale), or **REVIEW**, and warns when no rollback path is visible.

## Safe-migration principles
- **Expand / contract**: add new schema → backfill → switch reads/writes → remove old, across separate deploys. Never drop-and-replace in one step while the app depends on it.
- **Backwards compatible**: the migration must be safe with both the old and new app version running (rolling deploys).
- **Online operations**: create indexes concurrently; avoid long-locking `ALTER`s; batch backfills outside the schema migration.
- **Reversible**: provide and test a `down`/rollback, or document why it's a one-way door and how to recover from backup.
- **Destructive ops gated**: drops/truncates need a verified backup and a deliberate two-phase rollout (stop using the column first, drop it later).
- **Test on prod-sized data**: timing and lock behavior differ wildly from a tiny dev DB.

## Output
For each finding: classification, `file:line`, the risk, and the safer approach. End with a
go/no-go for shipping as-is and the rollout steps required. Hand fixes to the Implementer.

## Notes
`context: fork` keeps output out of the main conversation (needs `github.copilot.chat.skillTool.enabled`; inline otherwise). The script reads only migration files; it can't judge data semantics — pair with the Security Reviewer for anything touching PII columns.
