#!/usr/bin/env bash
# scan.sh — read-only static a11y scan over changed UI files.
# Catches common markup-level issues only. Keyboard flow, focus order, contrast,
# and screen-reader behavior still require manual / assistive-tech testing.
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

# Only look at UI-ish files.
UIRE='\.(html?|jsx?|tsx?|vue|svelte|erb|hbs|astro)$'
TRACKED_UI="$(git diff --name-only "$RANGE" 2>/dev/null | grep -iE "$UIRE" || true)"
UNTRACKED_UI=""
[ -z "$BASE" ] && UNTRACKED_UI="$(git ls-files --others --exclude-standard 2>/dev/null | grep -iE "$UIRE" || true)"
UI_FILES="$(printf '%s\n%s\n' "$TRACKED_UI" "$UNTRACKED_UI" | grep -v '^$' || true)"
echo "ACCESSIBILITY SCAN (markup-level)"
echo "Range: $LABEL"
if [ -z "$UI_FILES" ]; then
  echo "No UI files changed — nothing to scan."
  exit 0
fi
echo "UI files changed:"; printf '  %s\n' $UI_FILES

ADDED="$( { [ -n "$TRACKED_UI" ] && git diff "$RANGE" -- $TRACKED_UI 2>/dev/null; for f in $UNTRACKED_UI; do git diff --no-index /dev/null "$f" 2>/dev/null || true; done; } | grep -E '^\+' | grep -vE '^\+\+\+' || true)"

# POSIX-ERE only (portable across GNU and BSD/macOS grep): no lookaheads, no \s \b \w.
# flag_present <label> <regex> <wcag>      — flag added lines matching <regex>
flag_present() { local h; h="$(printf '%s\n' "$ADDED" | grep -nEi "$2" || true)"; [ -n "$h" ] && printf '\n[FLAG] %s (WCAG %s):\n%s\n' "$1" "$3" "$h"; }
# flag_absent  <label> <element> <attr> <wcag> — flag lines with <element> but lacking <attr>
flag_absent()  { local h; h="$(printf '%s\n' "$ADDED" | grep -nEi "$2" | grep -vEi "$3" || true)"; [ -n "$h" ] && printf '\n[FLAG] %s (WCAG %s):\n%s\n' "$1" "$4" "$h"; }

echo; echo "===== FLAGS (added lines in UI files) ====="
flag_absent  "<img> without alt attribute" '<img[ />]' 'alt=' "1.1.1"
flag_present "Click handler on non-interactive element (needs role + keyboard handler)" '<(div|span)[^>]*on[cC]lick' "2.1.1 / 4.1.2"
flag_present "Positive tabindex (breaks natural focus order)" 'tabindex="?[1-9]' "2.4.3"
flag_absent  "Anchor without href used as button" '<a[ >]' 'href=' "4.1.2"
flag_absent  "Input/select/textarea may lack a programmatic label" '<(input|select|textarea)[ />]' '(aria-label|aria-labelledby|[^a-z]id=)' "3.3.2 / 4.1.2"
flag_present "Button with no text (icon/empty button?)" '<button[^>]*>[[:space:]]*</button>' "4.1.2"
flag_present "dangerouslySetInnerHTML / v-html (verify semantics + safety)" '(dangerouslySetInnerHTML|v-html)' "4.1.1"
flag_present "Removal of focus outline" 'outline[[:space:]]*:[[:space:]]*(none|0)' "2.4.7"
flag_present "Fixed px font-size (prefer rem/em for zoom)" 'font-size[[:space:]]*:[[:space:]]*[0-9]+px' "1.4.4"
flag_absent  "<html> without lang (page-level)" '<html[ >]' 'lang=' "3.1.1"
flag_present "Media element — needs captions/transcript" '<(video|audio)[ >]' "1.2.x"
flag_present "role= used — confirm correct role + required states" 'role=' "4.1.2"

echo; echo "===== END OF SCAN ====="
echo "Manual/AT testing still required: keyboard flow, visible focus order, color contrast, screen-reader announcements, timed-assessment limits."
