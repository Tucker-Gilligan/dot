#!/usr/bin/env bash
# collect-diff.sh — read-only diff digest + cheap risk scan for PR self-review.
#
# Does deterministic, token-free work so the model only has to *analyze* the result:
#   - git diff stat + changed-file list
#   - the full diff (capped, see MAX_DIFF_LINES)
#   - pattern-based risk flags (debug leftovers, secrets, removed auth, raw SQL,
#     ESLint suppressions, destructive migrations, dependency changes, generated
#     artifacts, broad changes)
#
# Usage:
#   collect-diff.sh                 # uncommitted changes (working tree + staged) vs HEAD
#   collect-diff.sh main            # this branch vs origin/main (or main) merge-base
#   collect-diff.sh <base-ref>
#
# Never mutates the repo. Only runs read-only git commands.
set -uo pipefail

MAX_DIFF_LINES="${MAX_DIFF_LINES:-4000}"
BASE="${1:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository." >&2
  exit 1
fi

# Resolve the diff range.
if [ -z "$BASE" ]; then
  # Uncommitted work: staged + unstaged vs HEAD. Fall back to empty-tree if no HEAD.
  if git rev-parse HEAD >/dev/null 2>&1; then
    RANGE="HEAD"
    LABEL="uncommitted changes (working tree + index) vs HEAD"
  else
    RANGE="$(git hash-object -t tree /dev/null)"
    LABEL="all files (no commits yet)"
  fi
  DIFF_CMD=(git diff "$RANGE")
  STAT_CMD=(git diff --stat "$RANGE")
  NAME_CMD=(git diff --name-status "$RANGE")
else
  # Branch comparison. Prefer origin/<base> if present, use merge-base (...) semantics.
  if git rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then
    REF="origin/$BASE"
  elif git rev-parse --verify "$BASE" >/dev/null 2>&1; then
    REF="$BASE"
  else
    echo "ERROR: base ref '$BASE' not found (tried origin/$BASE and $BASE)." >&2
    exit 1
  fi
  RANGE="$REF...HEAD"
  LABEL="HEAD vs $REF (merge-base)"
  DIFF_CMD=(git diff "$RANGE")
  STAT_CMD=(git diff --stat "$RANGE")
  NAME_CMD=(git diff --name-status "$RANGE")
fi

section() { printf '\n===== %s =====\n' "$1"; }

# Capture the diff once.
DIFF="$("${DIFF_CMD[@]}" 2>/dev/null)"

# In uncommitted mode, git diff omits brand-new (untracked) files. Append them as
# all-additions so the risk scan still sees them. Read-only (no index mutation).
UNTRACKED=""
if [ -z "$BASE" ]; then
  UNTRACKED="$(git ls-files --others --exclude-standard)"
  while IFS= read -r uf; do
    [ -n "$uf" ] && DIFF="$DIFF
$(git diff --no-index /dev/null "$uf" 2>/dev/null || true)"
  done <<< "$UNTRACKED"
fi
ADDED="$(printf '%s\n' "$DIFF" | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
REMOVED="$(printf '%s\n' "$DIFF" | grep -E '^-' | grep -vE '^---' || true)"

echo "DIFF DIGEST"
echo "Range: $LABEL"
echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"

section "CHANGE STAT"
"${STAT_CMD[@]}" 2>/dev/null || echo "(none)"

section "CHANGED FILES (name-status)"
"${NAME_CMD[@]}" 2>/dev/null || echo "(none)"
[ -n "${UNTRACKED:-}" ] && printf '%s\n' "$UNTRACKED" | sed 's/^/U\t/'

# ---- Risk scans (matched against ADDED lines unless noted) ----
scan() { # scan "<label>" "<regex>"
  local label="$1" regex="$2" hits
  hits="$(printf '%s\n' "$ADDED" | grep -nE "$regex" || true)"
  if [ -n "$hits" ]; then
    printf '\n[FLAG] %s:\n%s\n' "$label" "$hits"
  fi
}

section "RISK FLAGS (added lines)"
FLAGGED=0
_before="$(mktemp)"; : > "$_before"
{
  scan "Debug leftovers (console.log/print/debugger/pry/dump)" \
    '(console\.(log|debug)|debugger|System\.out\.print|fmt\.Print|binding\.pry|byebug|pdb\.set_trace|var_dump|dd\(|println!)'
  scan "TODO / FIXME / HACK / XXX" '(TODO|FIXME|HACK|XXX)'
  scan "Possible secrets (keys/tokens/passwords)" \
    '((api[_-]?key|secret|password|passwd|access[_-]?token|client[_-]?secret)[[:space:]]*[:=]|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{20,})'
  scan "Raw / concatenated SQL" \
    '(SELECT .*FROM|INSERT INTO|UPDATE .*SET|DELETE FROM).*(\+|\$\{|%s|f")'
  scan "Broad exception handling" '(except:|except Exception|catch[[:space:]]*\([[:space:]]*[[:alnum:]_]*[[:space:]]*\)[[:space:]]*\{?[[:space:]]*$|rescue[[:space:]]*=>|catch[[:space:]]*\(e\))'
  scan "Disabled tests / skips" '(\.skip\(|\.only\(|xit\(|xdescribe\(|@pytest\.mark\.skip|t\.Skip)'
  scan "Dependency manifest changes" '("dependencies"|requirements|go\.mod|Gemfile|Cargo\.toml|package\.json)'
} | tee "$_before"
if [ -s "$_before" ]; then FLAGGED=1; fi
rm -f "$_before"

# ESLint suppressions need file-aware matching so examples in Markdown do not
# trigger the scan. Flag inline directives, ignored-file configuration, disabled
# rules in ESLint config files, and generated suppression baselines.
ESLINT_SUPPRESSIONS="$(
  printf '%s\n' "$DIFF" | awk '
    /^\+\+\+ b\// {
      file = substr($0, 7)
      next
    }
    /^\+/ && !/^\+\+\+/ {
      line = substr($0, 2)
      is_docs = file ~ /\.(md|mdx|rst|txt)$/
      is_eslint_config = file ~ /(^|\/)(eslint\.config\.[^\/]+|\.eslintrc(\.[^\/]+)?)$/
      is_ignore_file = file ~ /(^|\/)\.eslintignore$/
      is_suppression_file = file ~ /(^|\/)\.?eslint-suppressions\.json$/
      is_package = file ~ /(^|\/)package\.json$/

      if (!is_docs && line ~ /eslint-disab(le(-next-line|-line)?)/) {
        print file ": " line
      } else if (!is_docs && line ~ /eslint/ && line ~ /--(suppress-all|suppress-rule|suppressions-location|ignore-pattern|quiet)([[:space:]=]|$)/) {
        print file ": " line
      } else if (is_ignore_file || is_suppression_file) {
        print file ": " line
      } else if ((is_eslint_config || is_package) && line ~ /(eslintIgnore|ignorePatterns|globalIgnores|ignores)[[:space:]]*[:"(]/) {
        print file ": " line
      } else if ((is_eslint_config || is_package) && line ~ /:[[:space:]]*["\047]?(off|0)["\047]?[[:space:]]*[,}]/) {
        print file ": " line
      }
    }
  ' || true
)"
if [ -n "$ESLINT_SUPPRESSIONS" ]; then
  printf '\n[FLAG] New ESLint suppression — remove it and fix the underlying lint violation:\n%s\n' "$ESLINT_SUPPRESSIONS"
  FLAGGED=1
fi

# Destructive migrations: check changed file paths + destructive keywords in added lines.
MIGRATION_FILES="$(printf '%s\n' "$DIFF" | grep -iE '^\+\+\+ .*(migrat|schema)' || true)"
DESTRUCTIVE="$(printf '%s\n' "$ADDED" | grep -nEi '(DROP (TABLE|COLUMN|DATABASE)|TRUNCATE|ALTER TABLE .*DROP|remove_column|drop_table|drop_column)' || true)"
if [ -n "$MIGRATION_FILES" ] || [ -n "$DESTRUCTIVE" ]; then
  printf '\n[FLAG] Migration / destructive schema change — verify reversibility & rollback:\n'
  [ -n "$MIGRATION_FILES" ] && printf 'Touched migration files:\n%s\n' "$MIGRATION_FILES"
  [ -n "$DESTRUCTIVE" ] && printf 'Destructive statements:\n%s\n' "$DESTRUCTIVE"
  FLAGGED=1
fi

# Removed auth/permission checks (scan REMOVED lines).
AUTH_REMOVED="$(printf '%s\n' "$REMOVED" | grep -nEi '(authoriz|authenticat|permission|is_?admin|require_?(login|auth)|@login_required|can\?|ensure_|verify_token|check_access)' || true)"
if [ -n "$AUTH_REMOVED" ]; then
  printf '\n[FLAG] Auth/permission logic REMOVED — confirm this is intentional:\n%s\n' "$AUTH_REMOVED"
  FLAGGED=1
fi

# Oversized change heuristic.
TOTAL_CHANGED="$(printf '%s\n' "$ADDED$REMOVED" | grep -c . || true)"
if [ "${TOTAL_CHANGED:-0}" -gt 800 ]; then
  printf '\n[FLAG] Large change (~%s changed lines) — consider splitting into smaller PRs.\n' "$TOTAL_CHANGED"
  FLAGGED=1
fi

# Change-shape heuristics. These are prompts for author judgment, not verdicts.
CHANGED_FILE_COUNT="$(printf '%s\n' "$DIFF" | grep -E '^diff --git ' | wc -l | tr -d ' ')"
if [ "${CHANGED_FILE_COUNT:-0}" -gt 15 ]; then
  printf '\n[FLAG] Broad change (%s files) — classify each file as required, supporting, or incidental; consider splitting unrelated work.\n' "$CHANGED_FILE_COUNT"
  FLAGGED=1
fi

ARTIFACT_FILES="$(printf '%s\n' "$DIFF" | grep -E '^diff --git .*\.(min\.(js|css)|map|lock)$|^diff --git .*/(dist|build|coverage|vendor)/' || true)"
if [ -n "$ARTIFACT_FILES" ]; then
  printf '\n[FLAG] Generated/build artifacts changed — confirm they are required and reproducible from source:\n%s\n' "$ARTIFACT_FILES"
  FLAGGED=1
fi

[ "$FLAGGED" -eq 0 ] && echo "(no automated flags — still review manually)"

section "FULL DIFF (capped at $MAX_DIFF_LINES lines)"
printf '%s\n' "$DIFF" | head -n "$MAX_DIFF_LINES"
DIFF_LINES="$(printf '%s\n' "$DIFF" | wc -l | tr -d ' ')"
if [ "${DIFF_LINES:-0}" -gt "$MAX_DIFF_LINES" ]; then
  printf '\n... [diff truncated: %s of %s lines shown; raise MAX_DIFF_LINES or inspect specific files] ...\n' "$MAX_DIFF_LINES" "$DIFF_LINES"
fi
