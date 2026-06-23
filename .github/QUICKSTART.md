# Quick start — get the agent fleet running

Goal: clone on your work machine and have all 14 agents + 9 skills working in GitHub Copilot,
out of the box. ~5 minutes.

## 0. Prerequisites
- **VS Code** with the **GitHub Copilot** + **Copilot Chat** extensions, signed in.
- These models enabled for your account/org (Copilot → model picker): **Claude Opus 4.7**,
  **Claude Sonnet 4.6**, **GPT-5 mini**, **GPT-5.5**. (If your lineup differs, see HANDOFF.md → "Change the model tiers".)
- macOS is assumed; the scan scripts are written to work with the system (BSD) `grep`.

## 1. Clone
```bash
git clone <your-repo-url> dot
cd dot
chmod +x .github/skills/*/scripts/*.sh .github/validate.sh   # make scripts runnable
bash .github/validate.sh                                      # should print ✅ ALL CHECKS PASSED
```

## 2. Make the agents/skills visible to Copilot — pick ONE

**Option A — Use them right here (developing/tweaking the fleet itself).**
Just open this `dot` folder in VS Code. VS Code auto-discovers `.github/agents`, `.github/skills`,
and `.github/prompts`. Nothing else to do.

**Option B — Use them in ALL your repos (recommended for daily work).**
Install at the user level so every workspace sees them:
```bash
mkdir -p ~/.copilot/agents ~/.copilot/skills
cp .github/agents/*.agent.md       ~/.copilot/agents/
cp -R .github/skills/*             ~/.copilot/skills/
```
(Re-run these after you pull updates. Or symlink instead of copy to stay in sync —
`ln -s "$PWD"/.github/agents/*.agent.md ~/.copilot/agents/`.)

**Option C — Point VS Code at this clone (no copying).**
In VS Code settings (JSON), add the cloned paths:
```jsonc
"chat.agentFilesLocations":  ["/absolute/path/to/dot/.github/agents"],
"chat.agentSkillsLocations": ["/absolute/path/to/dot/.github/skills"]
```

**Option D — Bake into a specific product repo.**
Copy `.github/agents`, `.github/skills`, `.github/prompts`, and `.github/copilot-instructions.md`
into that repo's `.github/` and commit. The whole team gets it.

> The scan scripts (diff-digest, security, etc.) read the diff of **whatever repo is open**, so they
> "just work" in any product repo as long as the skills are discoverable via one of the options above.

## 3. Turn on the one setting that matters
Enable forked-context skills (lets the scan skills run without bloating chat context):
- Settings → search **`github.copilot.chat.skillTool.enabled`** → check it.
- (Optional) Org-shared agents: **`github.copilot.chat.organizationCustomAgents.enabled`**.

Without this, the `context: fork` skills still work — they just run inline.

## 4. Make Router the default
Open Copilot Chat → the **agents dropdown** → pick **Router**. Your choice persists per workspace.
Even if you forget, `.github/copilot-instructions.md` makes any agent route first, so routing still happens.

## 5. Fill the two TODO skills (10 min, big payoff)
- `.github/skills/repo-conventions/SKILL.md` — your stack, project layout, test framework, error-handling. Makes coding agents match your patterns.
- `.github/skills/edtech-integrations/SKILL.md` — replace the `<!-- repo: ... -->` notes with how *your* codebase does LTI/SSO/rostering.

## 6. Verify it's live
- Type `/` in Copilot Chat → you should see `pr-prep` and the skills.
- Open the agents dropdown → you should see the 14 agents.
- Run `/pr-prep` on a branch with changes — you should get a digest + review.

---

# How to use it day to day

**Just describe what you want in the Router** and it dispatches to the right specialist on the
right model tier. Or pick a specific agent from the dropdown.

| You want to… | Say / use |
| --- | --- |
| Anything — let it route | Stay in **Router**, describe the task |
| Find/understand code | "where is… / how does… / trace…" → Researcher (low) |
| Plan a feature/refactor | "design / plan / trade-offs…" → Planner (high) |
| Write/refactor code | "implement / build / add…" → Implementer (high) |
| Tests | "write tests for…" → Test Writer (mid) |
| Tiny mechanical edit | "rename / bump / format…" → Quick Fix (low) |
| **Pre-review your own PR** | `/pr-prep` → PR Prep (high) |
| Debug something broken | paste the error → Debugger (high) |
| Review a teammate's PR | "review PR #N / this branch" → Code Reviewer (high) |
| Security / privacy / PII | "is this safe with student data?" → Security Reviewer (high) |
| Accessibility | "a11y / WCAG check" → Accessibility Reviewer (mid) |
| Docs / ADR / runbook | "document… / write an ADR" → Doc Writer (mid) |
| Perf / scaling | "this is slow / won't scale" → Performance Engineer (high) |
| Logging / metrics / alerts | "instrument… / add tracing" → Observability Engineer (mid) |

**Workflows chain via handoff buttons** that appear after a response: e.g. Planner → Implementer
→ Test Writer → PR Prep. Click to continue with context carried over.

**Before every PR:** run `/pr-prep`. It writes a review to `./.pr-review/`, proposes numbered
step-comments in your code (you confirm), walks you through an understanding check, and drafts a
PR description from your repo's template. Add `.pr-review/` to your `.gitignore`.

**Token discipline is automatic:** high-tier agents offload file-finding to the low-tier
Researcher, and the Router keeps cheap work on cheap models. You don't have to manage this.

See **HANDOFF.md** to modify or extend the fleet. Full reference: **agents/README.md**.
