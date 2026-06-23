# Copilot agent fleet — model-aware routing

A router-based Copilot setup that **delegates each request to the right specialist on the right
model tier**, to stay inside token limits *without* dumbing everything down to a cheap model.
The centerpiece is **PR Prep**, which forces authors to understand and de-risk their own diff
before a human reviews it.

Built for GitHub Copilot custom agents (VS Code `.agent.md` format). The same files are picked up
by Visual Studio 2026 and Copilot CLI/cloud agents.

> **New here?** Start with [`../QUICKSTART.md`](../QUICKSTART.md) (clone → running → daily use).
> Tweaking or extending the fleet? See [`../HANDOFF.md`](../HANDOFF.md). After any edit, run
> `bash .github/validate.sh`. This file is the full per-agent / per-skill reference.

## What's here

```
.github/
├── copilot-instructions.md      # Always-on fallback: routing + token policy for every chat
├── prompts/
│   └── pr-prep.prompt.md         # /pr-prep — one-shot PR self-review
├── agents/
│   ├── router.agent.md                # Default entry point — classifies & delegates
│   ├── researcher.agent.md            # LOW  — read-only, combs many files cheaply
│   ├── planner.agent.md               # HIGH — design / architecture / trade-offs (read-only)
│   ├── implementer.agent.md           # HIGH — writes & refactors production code
│   ├── test-writer.agent.md           # MID  — writes / repairs tests
│   ├── quick-fix.agent.md             # LOW  — trivial mechanical edits
│   ├── pr-prep.agent.md               # HIGH — pre-review self-review of YOUR diff
│   ├── debugger.agent.md              # HIGH — reproduce → root-cause → fix
│   ├── code-reviewer.agent.md         # HIGH — review SOMEONE ELSE's PR (read-only)
│   ├── security-reviewer.agent.md     # HIGH — security + FERPA/COPPA/PII (read-only)
│   ├── accessibility-reviewer.agent.md# MID  — WCAG 2.2 AA / Section 508 (read-only)
│   ├── doc-writer.agent.md            # MID  — READMEs, ADRs, runbooks, API docs
│   ├── performance-engineer.agent.md  # HIGH — N+1, slow queries, scaling for peak load
│   └── observability-engineer.agent.md# MID  — logging, metrics, traces, alerts (PII-safe)
└── skills/                            # Reusable know-how + scripts, auto-loaded by description
    ├── diff-digest/                   # Diff + risk scan (context:fork). Powers PR Prep.
    ├── repo-conventions/              # House style, auto-loaded when coding (fill this in!)
    ├── commit-pr-writer/              # Conventional commits + PR descriptions from the diff
    ├── security-privacy-review/       # PII/auth/egress scan + FERPA/COPPA lens. Powers Security Reviewer.
    ├── accessibility-audit/           # Static a11y scan + WCAG checklist. Powers Accessibility Reviewer.
    ├── migration-safety/              # DB-migration data-loss/downtime scan + safe-migration checklist.
    ├── perf-scan/                     # Static performance-smell scan. Powers Performance Engineer.
    ├── adr/                           # Architecture Decision Record template. Used by Doc Writer.
    └── edtech-integrations/           # LTI/SSO/OneRoster knowledge, auto-loaded for integration work.
```

## Skills (vs agents)

Agents decide **who works and on which model**. Skills are **reusable know-how + bundled scripts**
that any agent auto-loads when the task matches the skill's description — they load progressively
(name/description first, body only when relevant), so they're nearly free until used.

| Skill | What it does | Why it saves tokens / slop |
| --- | --- | --- |
| `diff-digest` | A script gathers the diff + runs a risk-pattern scan; the model only analyzes the digest. Runs in a forked context. | Mechanical diff-reading moves from model tokens to free shell work; risk scan is deterministic and consistent. |
| `repo-conventions` | Background house-style rules, auto-loaded when writing/reviewing code. **Fill it in for your repo.** | Code lands on-pattern the first time → fewer correction round-trips and review nitpicks. |
| `commit-pr-writer` | Conventional commits + PR descriptions from the real diff; reads the repo's PR template/CONTRIBUTING and fills the real template, prompting for gaps. | Script gathers context + standards for free; trims the tail end of PR friction. |
| `security-privacy-review` | PII/auth/egress/secret/injection scan + a FERPA/COPPA review lens. Powers Security Reviewer. | Deterministic scan; model reasons about data flows, not greps. |
| `accessibility-audit` | Static a11y scan of changed UI files (alt, labels, tabindex, focus, lang) + WCAG checklist. Powers Accessibility Reviewer. | Markup checks automated; model judges keyboard/SR/contrast. |
| `migration-safety` | Scans DB migrations for destructive/blocking ops + missing rollback; safe-migration checklist. | Catches data-loss/downtime risk before it ships. |
| `perf-scan` | Static scan for perf smells (N+1, SELECT *, unbounded queries, serial awaits). Powers Performance Engineer. | Surfaces hotspot leads cheaply; model measures + fixes the real one. |
| `adr` | Architecture Decision Record template + guidance. Used by Doc Writer. | Consistent, durable decision records. |
| `edtech-integrations` | LTI 1.3, SSO (SAML/OAuth/Clever/ClassLink), OneRoster/Ed-Fi knowledge. Auto-loaded for integration work. | Agents respect protocol + tenant-isolation + privacy constraints. |

Skills with `context: fork` (`diff-digest`, `security-privacy-review`, `accessibility-audit`,
`migration-safety`) need `github.copilot.chat.skillTool.enabled` in VS Code; without it they run
inline. All bundled scripts are **read-only** (no commit/push/reset).

> **Two skills to fill in for full value:** `repo-conventions` (your stack/structure/testing) and
> the `<!-- repo: ... -->` notes in `edtech-integrations` (how *your* codebase does each integration).

## Routing map

| Request looks like… | Agent | Model tier |
| --- | --- | --- |
| find / trace / audit / "where is" (read-only, many files) | Researcher | LOW |
| design / plan / architecture / trade-offs | Planner | HIGH |
| build / implement / refactor (non-trivial) | Implementer | HIGH |
| write / fix tests | Test Writer | MID |
| rename / typo / version bump / formatting | Quick Fix | LOW |
| prep **my** PR / what's risky in my diff (before I push) | PR Prep | HIGH |
| debug / failing test / stack trace / flaky / regression | Debugger | HIGH |
| review **someone else's** PR / branch | Code Reviewer | HIGH |
| security / privacy / PII / FERPA / COPPA / auth / data egress | Security Reviewer | HIGH |
| accessibility / WCAG / 508 / screen reader / keyboard / contrast | Accessibility Reviewer | MID |
| docs / README / ADR / runbook / API docs | Doc Writer | MID |
| slow / N+1 / won't scale / optimize / capacity | Performance Engineer | HIGH |
| logging / metrics / tracing / alerts / instrument | Observability Engineer | MID |

The **Router** runs on a **high** model on purpose: routing accuracy is high-leverage (a
mis-route wastes far more than the router costs) and it only reads a short prompt to classify —
it doesn't churn through files or context, so it's cheap to run despite the tier. Everything else
uses the cheapest tier that does the job *well* — high for reasoning/quality, mid for structured
work, low for volume/mechanical work.

## The two efficiency mechanisms

**1. Routing.** The Router (or the always-on `copilot-instructions.md` fallback) sends each
request to the right tier. No more running Opus to fix a typo, or a cheap model to design a
migration.

**2. Subagent offloading.** High-tier agents (Planner, Implementer, Test Writer, PR Prep) can
spin up the **Researcher** (low model) as a subagent for pure file-finding — so expensive tokens
go to judgment and code, not to combing the repo.

## Escape hatch: agents bounce work back to the Router

Every specialist has a **scope guardrail**. If, mid-task, an agent hits work outside its lane, it
**stops, summarizes what's done / what's needed, and hands back** — either to the Router (which
re-routes) or directly to the right specialist via a handoff button. Examples:

- Quick Fix realizes a "rename" actually changes behavior → bounces to Router.
- Implementer hits an architecture decision with no plan → bounces to Router → Planner.
- Researcher is asked to edit → hands findings to Implementer.
- Implementer finishes a feature → hands off to Test Writer, then PR Prep.

This keeps each agent focused and stops cheap models from quietly doing risky work.

## Make the Router the default

1. Open the Copilot Chat view in VS Code (with this repo open).
2. In the agents dropdown, pick **Router**. Your selection persists per workspace.
3. Even if someone forgets, `.github/copilot-instructions.md` makes *any* agent route first — so the behavior is foolproof.

To share across all repos in your org, define these at the GitHub org level and enable
`github.copilot.chat.organizationCustomAgents.enabled`.

## Using it on your work machine

This lives in the repo, so:

```bash
git add .github
git commit -m "Add Copilot model-routing agent fleet"
git push
# on the work machine
git clone <repo> && code <repo>   # agents appear in the Copilot agents dropdown automatically
```

VS Code auto-discovers `.github/agents/*.agent.md` and `.github/prompts/*.prompt.md` — no install step.

## Tuning the model tiers

Model names are set in each agent's `model:` frontmatter (a prioritized array — VS Code tries each
until one is available) and summarized in `copilot-instructions.md`. Current defaults:

- **HIGH**: `Claude Opus 4.7` → `GPT-5.5`
- **MID**: `Claude Sonnet 4.6` → `GPT-5.5`
- **LOW**: `GPT-5 mini` → `Claude Sonnet 4.6`

Swap these to match the models your org has enabled. If you leave `model:` out entirely, the agent
uses whatever you've picked in the model dropdown.

## Quick reference

- Start any request in **Router** and let it dispatch.
- Type `/pr-prep` before opening a PR.
- Switch agents anytime via the dropdown; use the **handoff buttons** that appear after a response to move through a workflow (research → plan → implement → test → PR prep).
