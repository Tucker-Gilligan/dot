# OpenCode setup

This installer exposes the repository's shared skills to OpenCode
using its global configuration directory:

```text
~/.config/opencode/skills -> <repo>/.github/skills
```

From this directory, run:

```bash
./install.sh
```

Use `./install.sh --dry-run` to preview the links. The Copilot-specific global
instructions are intentionally not linked because OpenCode uses `AGENTS.md`
for instructions and the existing file contains Copilot-specific metadata and
tool guidance.

OpenCode uses its own agent format, so the Copilot agent files are intentionally not installed; their VS Code-specific frontmatter is incompatible.
