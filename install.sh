#!/usr/bin/env zsh
# Source of truth for Copilot agents, prompts, skills, and instructions.
# Maintain everything in this repo's .github/; this script projects it into the
# user-level locations each Copilot surface scans, so your customizations are
# available in EVERY workspace.
#
# Idempotent: safe to re-run after adding/removing agents, prompts, or skills.
#   ./install.sh           # create/refresh all symlinks
#   ./install.sh --dry-run # print what it would do, change nothing
#   ./install.sh --prune   # also remove stale prompt links whose source is gone
set -euo pipefail

DRY_RUN=0
PRUNE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --prune)   PRUNE=1 ;;
    *) print -u2 "unknown arg: $arg"; exit 2 ;;
  esac
done

REPO="${0:A:h}"
GH="$REPO/.github"
PROMPTS="$HOME/Library/Application Support/Code/User/prompts"  # VS Code Copilot Chat
COPILOT="$HOME/.copilot"                                       # Copilot CLI / coding agent

link() {  # link <target> <linkpath>
  local target="$1" linkpath="$2"
  if (( DRY_RUN )); then
    print "ln -sfn $target -> $linkpath"
    return
  fi
  ln -sfn "$target" "$linkpath"
}

remove() {  # remove <linkpath> (only if it's a symlink)
  local linkpath="$1"
  [[ -L "$linkpath" ]] || return 0
  if (( DRY_RUN )); then print "rm $linkpath"; return; fi
  rm "$linkpath"
}

(( DRY_RUN )) || mkdir -p "$PROMPTS" "$COPILOT"

# --- Agents: single canonical source = ~/.copilot/agents ---
# VS Code also scans this location, so one link serves both CLI and Chat.
link "$GH/agents" "$COPILOT/agents"
# Remove the DUPLICATE agents link in the prompts folder (was causing each
# agent to appear twice in VS Code's picker).
remove "$PROMPTS/agents"

# --- Global instructions + skills (whole-dir) ---
link "$GH/global.instructions.md" "$PROMPTS/global.instructions.md"
link "$GH/skills" "$PROMPTS/skills"

# --- Prompts: link EVERY *.prompt.md so new ones are picked up automatically ---
for f in "$GH"/prompts/*.prompt.md; do
  link "$f" "$PROMPTS/${f:t}"
done

# --- Optional: prune stale prompt links whose source no longer exists ---
if (( PRUNE )); then
  for l in "$PROMPTS"/*.prompt.md(N); do
    [[ -e "$l" ]] || { print "pruning stale: $l"; (( DRY_RUN )) || rm "$l"; }
  done
fi

print "Done. Reload VS Code (Developer: Reload Window) to re-scan."
