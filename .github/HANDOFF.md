# Handoff & maintainer guide

For continuing this on your work machine — tweaking, adding agents/skills, and not breaking the
wiring. Read QUICKSTART.md first to get it running.

## Mental model (4 building blocks)

| Thing | File | What it is |
| --- | --- | --- |
| **Agent** | `.github/agents/<name>.agent.md` | A persona: model tier + allowed tools + handoffs + instructions. Selectable in the dropdown, dispatchable by the Router. |
| **Skill** | `.github/skills/<name>/SKILL.md` (+ `scripts/`) | Reusable know-how + optional scripts. Auto-loaded when a task matches its `description`; also a `/slash` command. |
| **Instructions** | `.github/copilot-instructions.md` | Always-on. The routing/token policy that applies even if no agent is selected. |
| **Prompt** | `.github/prompts/<name>.prompt.md` | A saved `/slash` command that targets an agent. |

The **Router** is the hub: it reads your request, classifies it with its rubric, and dispatches to
a specialist. Specialists bounce out-of-scope work back via handoff buttons. High-tier agents
offload file-finding to the low-tier **Researcher** to save tokens.

## The golden rule when you change anything
Run the validator. It catches every wiring mistake below:
```bash
bash .github/validate.sh
```
Also useful in VS Code: `/agents`, `/skills`, and right-click chat → **Diagnostics** to see what loaded and any errors.

## Change the model tiers
Models live in each agent's `model:` array (it tries them in order until one is available) and in
handoff `model:` lines. Current lineup (edit `AVAIL` in `validate.sh` if your org's changes):

- **HIGH** `['Claude Opus 4.7', 'GPT-5.5']` — Router, Planner, Implementer, PR Prep, Debugger, Code Reviewer, Security Reviewer, Performance Engineer
- **MID** `['Claude Sonnet 4.6', 'GPT-5.5']` — Test Writer, Accessibility Reviewer, Doc Writer, Observability Engineer
- **LOW** `['GPT-5 mini', 'Claude Sonnet 4.6']` — Researcher, Quick Fix

To swap a model everywhere:
```bash
grep -rl 'GPT-5 mini' .github | xargs sed -i '' 's/GPT-5 mini/<new-model>/g'   # macOS sed needs the ''
```
Then re-run `bash .github/validate.sh`. Handoff model strings use the qualified form `Model Name (copilot)`.

## Add a new agent (checklist)
1. Create `.github/agents/<your-agent>.agent.md`:
   ```markdown
   ---
   name: My Agent
   description: What it does and WHEN to use it (this is how the Router/menu match it).
   model: ['Claude Sonnet 4.6', 'GPT-5.5']     # pick a tier
   tools: ['search/codebase', 'edit', 'agent'] # least privilege; include 'agent' only if it delegates
   agents: ['Researcher']                       # subagents it may call — REQUIRES 'agent' in tools
   handoffs:
     - label: Back to Router
       agent: Router
       prompt: "Done (summary above). Route the next step."
       send: false
   ---
   # My Agent
   ...instructions, working rules, and a "Scope guardrails — escape hatch" section...
   ```
2. **Wire it into the Router** (`router.agent.md`) — three places:
   - add the name to the `agents:` array,
   - add a handoff button for it,
   - add a row to the **routing rubric** table.
3. Add a one-liner to `copilot-instructions.md` (the "route first" list) and to `agents/README.md` (tree + routing map).
4. `bash .github/validate.sh` — it will tell you if you missed step 2 or 3.

Tip: in VS Code you can scaffold one with `/create-agent`, then wire it in.

## Add a new skill
1. Create `.github/skills/<your-skill>/SKILL.md`. **The `name` MUST equal the folder name**, lowercase/digits/hyphens only — a mismatch makes it silently not load.
   ```markdown
   ---
   name: your-skill
   description: What it does AND when to use it (be specific — this drives auto-loading).
   # context: fork        # optional: run in a throwaway subagent, return only the result
   # user-invocable: false # optional: background knowledge, no /slash command
   ---
   # Your skill
   ...steps; reference scripts with a relative link: [scan](./scripts/scan.sh)...
   ```
2. Put scripts in `scripts/`. Reference them with `./scripts/...` links so they're discovered.
3. `chmod +x` the scripts and `bash .github/validate.sh`.

## Writing scan scripts — non-negotiable rules (macOS)
The work machine uses **BSD grep**. These break it silently (match nothing, no error):
- ❌ PCRE lookaheads `(?!...)` / `(?=...)`
- ❌ `\s` `\b` `\w` `\d`

Use instead:
- ✅ `[[:space:]]`, `[[:alnum:]_]`, `[0-9]`
- ✅ "element without attribute" → two-step grep: `grep -E '<img'` piped to `grep -vE 'alt='`
- ✅ keep scripts **read-only** (no commit/push/reset/checkout) — they analyze diffs, nothing more
- ✅ handle **untracked files** in uncommitted mode (the existing scripts append `git diff --no-index /dev/null <file>`)

The validator's regex check enforces the first two. Copy an existing script (e.g.
`security-privacy-review/scripts/scan.sh`) as a starting template — it already has the diff-range
resolution, untracked handling, and POSIX patterns.

## YAML gotcha
In frontmatter, an unquoted value can't contain a colon-then-space (`": "`) — it parses as a map and
the agent fails to load. Reword (use `—` or `;`) or quote the whole value. The validator catches this.

## Edit comfortably in VS Code
- Gear icon in Chat → **Agent Customizations editor** (Agents / Skills tabs) to create/edit/toggle.
- `/agents`, `/skills` to jump to the config menus.
- Changes take effect immediately — no reload needed for `.github/agents` and `.github/skills`.

## Commit & push your tweaks
```bash
bash .github/validate.sh          # green before you commit
git add .github
git commit -m "tweak: <what you changed>"
git push
```
If you installed at user level (QUICKSTART Option B by copy), re-copy after pulling so
`~/.copilot/...` matches the repo. Symlinks avoid this.

## Where things are
```
.github/
├── QUICKSTART.md            ← run it / use it
├── HANDOFF.md               ← this file (change it)
├── validate.sh             ← run after every edit
├── copilot-instructions.md  ← always-on routing/token policy
├── prompts/pr-prep.prompt.md
├── agents/                  ← 14 agents + README.md (full reference)
└── skills/                  ← 9 skills (SKILL.md + scripts/)
```
Full per-agent / per-skill reference: **agents/README.md**.
