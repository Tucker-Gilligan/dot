#!/usr/bin/env bash
# scan.sh — read-only security & student-data-privacy scan over a diff.
# Heuristic pattern matcher: every hit is a LEAD to verify, not a verdict.
#
# Usage:
#   scan.sh            # uncommitted changes vs HEAD
#   scan.sh main       # branch vs origin/main
set -uo pipefail

BASE="${1:-}"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not a git repo." >&2; exit 1; }

if [ -z "$BASE" ]; then
  RANGE="HEAD"; LABEL="uncommitted vs HEAD"
else
  if git rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then REF="origin/$BASE";
  elif git rev-parse --verify "$BASE" >/dev/null 2>&1; then REF="$BASE";
  else echo "ERROR: base '$BASE' not found." >&2; exit 1; fi
  RANGE="$REF...HEAD"; LABEL="HEAD vs $REF"
fi

DIFF="$(git diff "$RANGE" 2>/dev/null)"
# Include brand-new (untracked) files in uncommitted mode — git diff omits them. Read-only.
if [ -z "$BASE" ]; then
  while IFS= read -r uf; do
    [ -n "$uf" ] && DIFF="$DIFF
$(git diff --no-index /dev/null "$uf" 2>/dev/null || true)"
  done <<< "$(git ls-files --others --exclude-standard)"
fi
ADDED="$(printf '%s\n' "$DIFF" | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
REMOVED="$(printf '%s\n' "$DIFF" | grep -E '^-' | grep -vE '^---' || true)"

echo "SECURITY & PRIVACY SCAN"
echo "Range: $LABEL"
echo "(Every [FLAG] is a lead to confirm or dismiss with a reason — not a verdict.)"

flag() { # flag "<label>" "<lines>"
  [ -n "$2" ] && printf '\n[FLAG] %s:\n%s\n' "$1" "$2"
}
add_scan()  { printf '%s\n' "$ADDED"   | grep -nEi "$1" || true; }
rem_scan()  { printf '%s\n' "$REMOVED" | grep -nEi "$1" || true; }

echo; echo "===== AUTH / AUTHORIZATION ====="
flag "Auth/permission logic REMOVED — confirm intentional" \
  "$(rem_scan '(authoriz|authenticat|permission|is_?admin|require_?(login|auth)|@login_required|can\?|ensure_|verify_token|check_access|role)')"
flag "Auth/permission logic added/changed — verify boundary is correct" \
  "$(add_scan '(authoriz|permission|is_?admin|role[[:space:]]*[:=]|current_user|tenant|@login_required|require_?auth|guard|policy)')"
flag "Possible IDOR — object lookup by id from request without ownership check" \
  "$(add_scan '(find(_by)?\(|findById|get_object_or_404|\.get\(.*id|where\(.*id).*(params|req\.(query|params|body)|request\.)')"

echo; echo "===== STUDENT PII / EDUCATION RECORDS ====="
flag "PII / education-record fields touched — verify access control + minimization" \
  "$(add_scan '(first_?name|last_?name|full_?name|dob|date_of_birth|birth|ssn|email|phone|address|grade|gpa|score|iep|504|disab|disciplin|guardian|parent|student_?id|roster|enrollment|attendance|geoloc|lat(itude)?|lng|device_?id)')"
flag "PII possibly written to logs — never log student PII" \
  "$(add_scan '(console\.(log|info|debug)|logger?\.(info|debug|warn|log)|print\(|fmt\.Print|System\.out).*(name|email|student|dob|ssn|grade|password|token|user)')"

echo; echo "===== DATA EGRESS / THIRD PARTIES ====="
flag "Outbound network / third-party call — does student data leave the system?" \
  "$(add_scan '(https?://|fetch\(|axios|requests\.(get|post)|http\.(get|post)|HttpClient|urllib|net/http|new URL\()')"
flag "Analytics / tracking / AI call — confirm no minor data sent / consent basis" \
  "$(add_scan '(segment|mixpanel|amplitude|google-?analytics|gtag|datadog|sentry|posthog|openai|anthropic|bedrock|gemini|\.track\()')"

echo; echo "===== SECRETS & CONFIG ====="
flag "Hardcoded secret / key / token" \
  "$(add_scan '((api[_-]?key|secret|password|passwd|access[_-]?token|client[_-]?secret|private[_-]?key)[[:space:]]*[:=][[:space:]]*[\"'\''][^\"'\'' ]{6,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)')"

echo; echo "===== INJECTION / UNSAFE INPUT ====="
flag "Raw / concatenated SQL" \
  "$(add_scan '(SELECT .*FROM|INSERT INTO|UPDATE .*SET|DELETE FROM).*(\+|\$\{|%s|f\"|concat)')"
flag "Command / eval / deserialization sinks" \
  "$(add_scan '(eval\(|exec\(|child_process|os\.system|subprocess|Runtime\.getRuntime|pickle\.loads|yaml\.load\(|Marshal\.load|deserialize)')"
flag "Possible SSRF — request built from user input" \
  "$(add_scan '(fetch|get|post|open)\(.*(req\.|request\.|params|input|user)')"
flag "Possible XSS — raw HTML render of dynamic content" \
  "$(add_scan '(dangerouslySetInnerHTML|innerHTML[[:space:]]*=|v-html|\|[[:space:]]*safe|render_to_string.*params|Markup\()')"

echo; echo "===== END OF SCAN ====="
echo "Reminder: the scanner cannot judge data-flow correctness, tenant isolation, or consent basis — the reviewer must."
