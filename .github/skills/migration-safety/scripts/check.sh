#!/usr/bin/env bash
# check.sh — read-only scan of changed DB migration files for risky operations.
# Ed-tech data (grades, rosters, attendance, IEP) is unforgiving — destructive or
# blocking migrations can lose records or cause downtime at peak (semester start, exams).
#
# Usage:
#   check.sh            # uncommitted changes vs HEAD
#   check.sh main       # branch vs origin/main
set -uo pipefail

BASE="${1:-}"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not a git repo." >&2; exit 1; }

if [ -z "$BASE" ]; then RANGE="HEAD"; LABEL="uncommitted vs HEAD";
else
  if git rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then REF="origin/$BASE";
  elif git rev-parse --verify "$BASE" >/dev/null 2>&1; then REF="$BASE";
  else echo "ERROR: base '$BASE' not found." >&2; exit 1; fi
  RANGE="$REF...HEAD"; LABEL="HEAD vs $REF"
fi

MIGRE='(migrat|/schema|alembic|liquibase|flyway|knex|prisma/migrations)'
TRACKED_MIG="$(git diff --name-only "$RANGE" 2>/dev/null | grep -iE "$MIGRE" || true)"
UNTRACKED_MIG=""
[ -z "$BASE" ] && UNTRACKED_MIG="$(git ls-files --others --exclude-standard 2>/dev/null | grep -iE "$MIGRE" || true)"
MIG_FILES="$(printf '%s\n%s\n' "$TRACKED_MIG" "$UNTRACKED_MIG" | grep -v '^$' || true)"
echo "MIGRATION SAFETY CHECK"
echo "Range: $LABEL"
if [ -z "$MIG_FILES" ]; then echo "No migration files changed."; exit 0; fi
echo "Migration files:"; printf '  %s\n' $MIG_FILES

ADDED="$( { [ -n "$TRACKED_MIG" ] && git diff "$RANGE" -- $TRACKED_MIG 2>/dev/null; for f in $UNTRACKED_MIG; do git diff --no-index /dev/null "$f" 2>/dev/null || true; done; } | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
# flag <CLASS> <label> <regex>
flag() { local hits; hits="$(printf '%s\n' "$ADDED" | grep -nEi "$3" || true)"; [ -n "$hits" ] && printf '\n[%s] %s:\n%s\n' "$1" "$2" "$hits"; }

echo; echo "===== FINDINGS ====="
flag "DESTRUCTIVE" "Drops data (irreversible without backup)" '(DROP (TABLE|COLUMN|DATABASE|SCHEMA)|drop_table|drop_column|remove_column|TRUNCATE)'
flag "DESTRUCTIVE" "Renames (often interpreted as drop+add → data loss / app break)" '(RENAME (TABLE|COLUMN|TO)|rename_column|rename_table)'
flag "BLOCKING"    "Type change / NOT NULL — can rewrite table & lock at scale" '(ALTER (TABLE|COLUMN).*(TYPE|USING)|SET NOT NULL|change_column|ALTER COLUMN .* NOT NULL)'
flag "BLOCKING"    "Add column with non-null default — table rewrite on old engines" '(ADD COLUMN .* NOT NULL .* DEFAULT|add_column.*null:[[:space:]]*false.*default)'
# Index without CONCURRENTLY (POSIX: match index creation, then exclude concurrent ones).
IDX="$(printf '%s\n' "$ADDED" | grep -nEi '(CREATE (UNIQUE )?INDEX|add_index)' | grep -vEi 'concurrent' || true)"
[ -n "$IDX" ] && printf '\n[BLOCKING] %s:\n%s\n' "Index created without CONCURRENTLY — locks writes" "$IDX"
flag "REVIEW"      "Foreign key / constraint added — validate against existing data" '(ADD CONSTRAINT|FOREIGN KEY|add_foreign_key|REFERENCES)'
flag "REVIEW"      "Data backfill inside migration — can be slow / long txn" '(UPDATE .*SET|INSERT INTO|update_all|exec.*UPDATE)'

echo; echo "===== REVERSIBILITY ====="
if printf '%s\n' "$ADDED" | grep -qiE '(def down|down\(|migrate:down|undo|reverse|rollback)'; then
  echo "  A down/rollback path appears present — verify it actually restores state."
else
  echo "  [WARN] No obvious down/rollback path found in added lines — confirm the migration is reversible."
fi

echo; echo "===== END ====="
echo "Checklist: backup before destructive ops • expand/contract (deploy in phases) • online/concurrent index • test on prod-sized data • have a rollback plan."
