#!/usr/bin/env bash
# scan.sh — read-only static scan for common performance smells in a diff.
# POSIX ERE only (portable to BSD/macOS grep). Every hit is a LEAD to verify by
# measurement — static analysis cannot confirm a real bottleneck.
#
# Usage:
#   scan.sh            # uncommitted changes vs HEAD
#   scan.sh main       # branch vs origin/main
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

DIFF="$(git diff "$RANGE" 2>/dev/null)"
if [ -z "$BASE" ]; then
  while IFS= read -r uf; do
    [ -n "$uf" ] && DIFF="$DIFF
$(git diff --no-index /dev/null "$uf" 2>/dev/null || true)"
  done <<< "$(git ls-files --others --exclude-standard)"
fi
ADDED="$(printf '%s\n' "$DIFF" | grep -E '^\+' | grep -vE '^\+\+\+' || true)"

echo "PERFORMANCE SCAN (static smells)"
echo "Range: $LABEL"
echo "(Leads to verify by measurement — not confirmed bottlenecks.)"

flag() { local h; h="$(printf '%s\n' "$ADDED" | grep -nEi "$2" || true)"; [ -n "$h" ] && printf '\n[FLAG] %s:\n%s\n' "$1" "$h"; }

echo; echo "===== FLAGS (added lines) ====="
flag "SELECT * (fetches unneeded columns)" 'select[[:space:]]+\*'
flag "Unbounded query / fetch-all (add pagination/limit)" '(\.all\(\)|find_?all|\.find\(\)|findMany\(\{?\}?\)|\.scan\()'
flag "Sequential await inside a loop (consider batching/parallel)" '(for[[:space:](]|while[[:space:](]|forEach|\.map).*await'
flag "async callback in .map/.forEach (often N unawaited/serial calls)" '\.(map|forEach|filter)\([[:space:]]*async'
flag "Possible N+1 — query/ORM call that may run per-iteration" '(\.(find|where|query|get|fetch|select|load)\(|SELECT .*FROM).*'
flag "Nested loops (O(n^2)+ on large inputs)" '(for[[:space:]].*for[[:space:]]|forEach.*forEach)'
flag "Blocking sleep / sync I/O in request path" '(sleep\(|time\.sleep|Thread\.sleep|readFileSync|execSync)'
flag "Missing pagination on list endpoint" '(index|list|getAll|fetchAll)[[:space:]]*\('
flag "Large in-memory load / parse" '(JSON\.parse\(|\.read\(\)|readAll|load_all|\.to_a)'
flag "Cache opportunity / repeated compute (FYI)" '(memoize|cache|lru)'

echo; echo "===== END OF SCAN ====="
echo "Next: profile/benchmark the suspected hotspot, confirm it matters at peak load, then optimize the real one."
