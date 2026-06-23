#!/usr/bin/env bash
# gather.sh — read-only context for writing a commit message or PR description.
# Prints staged (or branch) changes plus recent commit-title style so generated
# messages match the repo's existing convention.
#
# Usage:
#   gather.sh            # staged changes (for a commit message)
#   gather.sh main       # branch vs origin/main (for a PR description)
set -uo pipefail

BASE="${1:-}"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not a git repo." >&2; exit 1; }

section() { printf '\n===== %s =====\n' "$1"; }

if [ -z "$BASE" ]; then
  echo "MODE: commit (staged changes)"
  section "STAGED STAT"
  git diff --cached --stat 2>/dev/null || echo "(nothing staged)"
  section "STAGED NAME-STATUS"
  git diff --cached --name-status 2>/dev/null || true
  section "STAGED DIFF (capped 600 lines)"
  git diff --cached 2>/dev/null | head -n 600
else
  if git rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then REF="origin/$BASE";
  elif git rev-parse --verify "$BASE" >/dev/null 2>&1; then REF="$BASE";
  else echo "ERROR: base '$BASE' not found." >&2; exit 1; fi
  echo "MODE: PR description (HEAD vs $REF)"
  section "BRANCH STAT"
  git diff --stat "$REF...HEAD" 2>/dev/null || echo "(none)"
  section "COMMITS ON THIS BRANCH"
  git log --oneline "$REF..HEAD" 2>/dev/null || true
  section "BRANCH DIFF (capped 800 lines)"
  git diff "$REF...HEAD" 2>/dev/null | head -n 800
fi

section "RECENT COMMIT TITLES (match this style)"
git log -15 --pretty=format:'%s' 2>/dev/null || echo "(no history)"
echo

# Surface the repo's PR standards so the description fills the REAL template, not a generic one.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
section "PR STANDARDS (fill this template / follow these rules if present)"
FOUND=0
for p in \
  "$ROOT/PULL_REQUEST_TEMPLATE.md" \
  "$ROOT/.github/PULL_REQUEST_TEMPLATE.md" \
  "$ROOT/docs/PULL_REQUEST_TEMPLATE.md" \
  "$ROOT/.github/pull_request_template.md"; do
  [ -f "$p" ] && { echo "----- ${p#$ROOT/} -----"; cat "$p"; echo; FOUND=1; }
done
if [ -d "$ROOT/.github/PULL_REQUEST_TEMPLATE" ]; then
  for p in "$ROOT/.github/PULL_REQUEST_TEMPLATE"/*; do
    [ -f "$p" ] && { echo "----- ${p#$ROOT/} -----"; cat "$p"; echo; FOUND=1; }
  done
fi
for p in "$ROOT/CONTRIBUTING.md" "$ROOT/.github/CONTRIBUTING.md"; do
  [ -f "$p" ] && { echo "----- ${p#$ROOT/} (PR-relevant excerpts) -----"; grep -iA3 -E 'pull request|description|review|checklist|guideline' "$p" | head -60; echo; FOUND=1; }
done
[ "$FOUND" -eq 0 ] && echo "(no PR template or CONTRIBUTING found — use the default PR format in SKILL.md)"
