#!/usr/bin/env zsh
# Project the shared skills into OpenCode's global configuration.
# The canonical sources remain in ../.github so Copilot and OpenCode use the
# same workflow files.
set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) print -u2 "unknown arg: $arg"; exit 2 ;;
  esac
done

REPO="${0:A:h:h}"
GH="$REPO/.github"
OPENCODE="$HOME/.config/opencode"

link() {
  local target="$1" linkpath="$2"
  if (( DRY_RUN )); then
    print "ln -sfn $target -> $linkpath"
    return
  fi
  ln -sfn "$target" "$linkpath"
}

(( DRY_RUN )) || mkdir -p "$OPENCODE"

# OpenCode discovers skills below its global config directory.
link "$GH/skills" "$OPENCODE/skills"

# The Copilot agent files use VS Code-specific frontmatter and are not
# compatible with OpenCode. Remove the old shared-agent link if present.
if [[ -L "$OPENCODE/agents" && "$(readlink "$OPENCODE/agents")" == "$GH/agents" ]]; then
  if (( DRY_RUN )); then
    print "rm $OPENCODE/agents"
  else
    rm "$OPENCODE/agents"
  fi
fi

print "Done. Restart OpenCode to re-scan its global configuration."
