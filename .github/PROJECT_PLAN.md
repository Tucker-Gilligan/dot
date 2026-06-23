# Innovation Week — Model-Routing Agent Fleet + Shift-Left Quality

**Goal:** Take the Copilot agent fleet from "configured" to "validated, automated, and
measurably useful." Build it, prove it works with data, and shift quality/security/accessibility
checks *left* (earlier than code review) using the same scripts in the IDE, in git hooks, and in CI.

**Owner:** solo build. **Share-out:** Monday (deliverable produced by Friday).
**Stack:** GitHub Copilot custom agents (VS Code), GitHub Actions, macOS dev machine.

---

## The core idea that makes this a project, not a config

Every scan script (`diff-digest`, `security-privacy-review`, `accessibility-audit`,
`migration-safety`, `perf-scan`) is **bash + git — zero model tokens**. So one script powers
**two surfaces**:

| Surface | When it runs | Cost | Purpose |
| --- | --- | --- | --- |
| **Model agents** (IDE) | Developer asks, interactively | tokens | Judgment, fixes, explanations |
| **Deterministic gates** (git hooks + CI) | Automatically, every commit/PR | free | Catch the obvious stuff before a human looks |

Shift-left = move the cheap, deterministic checks as early as possible (commit → PR → review),
and reserve human + high-model attention for genuine judgment.

---

## Success metrics (define Day 1, measure Day 5)

1. **Routing accuracy** — % of a labeled prompt set routed to the expected agent (target ≥ 90%).
2. **Token efficiency** — relative spend per task type vs an "everything on the high model"
   baseline (the routing + low-tier savings; estimate from tier mix).
3. **Scan quality** — precision/recall of each scan against a labeled fixture diff set
   (target: high recall on 🔴 criticals, false-positive rate low enough that devs don't ignore it).
4. **Shift-left catch rate** — issues caught at commit/CI vs. issues that reach human review,
   measured on the real PRs you dogfood during the week.
5. **Readiness** — fleet-lint green, docs complete, demo runs end-to-end.

> Capture a **baseline** on Day 1 (current token use per task, current PR pain) so Friday's
> numbers have something to compare against.

---

## Day-by-day

### Day 1 — Foundation, baseline, eval harness
- [ ] Push and clone on the work machine; select **Router** in the Copilot dropdown; smoke-test each of the 14 agents on a real task.
- [ ] Write down success metrics + capture the baseline (token use per task type today; 2–3 recent real PRs to use as test cases all week).
- [ ] **Build the routing eval harness**: a labeled set of ~40 prompts → expected agent (`tests/routing/cases.tsv`) and a runner that records what the Router picks, scoring accuracy. This is your headline metric.
- [ ] Dogfood immediately: run **PR Prep** on a real recent diff; run every scan on the real repo and note the false-positive rate (raw material for Day 2 tuning).

### Day 2 — Test & harden (make it trustworthy)
- [ ] **Fixture tests for the scan scripts**: `tests/fixtures/` with sample diffs + an `expected-flags` file per case; a runner that diffs actual vs expected and reports precision/recall. (Reuse the smoke-test pattern already proven on the scripts.)
- [ ] **Tune patterns to your real stack** to cut false positives (e.g. your ORM's N+1 idioms, your logger's API, your migration tool).
- [ ] **Formalize the fleet-lint validator** (`scripts/lint-fleet.py`) — frontmatter valid, all agent/skill references resolve, models match the org lineup, scripts pass `bash -n` + POSIX-portability grep.
- [ ] Fill in **`repo-conventions`** and the `<!-- repo: -->` notes in **`edtech-integrations`** from the actual codebase (use the **Researcher** agent to gather, **Doc Writer** to write).
- [ ] Manually exercise handoff chains + escape hatches; fix the routing rubric from any eval misses.

### Day 3 — Shift-left: CI + git hooks (the core expansion)
- [ ] **GitHub Action: shift-left PR scan** (`.github/workflows/shift-left.yml`) — see design below. Non-blocking first; sticky PR comment.
- [ ] **GitHub Action: fleet-lint** on changes to `.github/**` (runs `scripts/lint-fleet.py`).
- [ ] **Git pre-push hook** (`.githooks/pre-push` + `git config core.hooksPath .githooks`) running the same scans locally so issues are caught before they ever reach a PR.
- [ ] **PR template** (`.github/pull_request_template.md`) seeded with the PR Prep / Definition-of-Done checklist.
- [ ] Confirm the scripts are the single source of truth for IDE skills, hooks, and CI.

### Day 4 — Expand coverage (shift further left + ed-tech depth)
Pick the **1–2 highest-value** items from the backlog (don't sprawl):
- [ ] **threat-model / design-review** skill — shift security to *design time*, before code exists.
- [ ] **dependency / CVE triage** agent or skill — supply-chain risk on manifest changes.
- [ ] **release / deploy checklist** + rollback runbook (pairs with migration-safety).
- [ ] **flaky-test quarantine** workflow.
- [ ] **i18n / localization** check (ed-tech multi-language) and/or **data-retention / PII-inventory** skill (FERPA).
- [ ] Tune the Router rubric + fleet-lint for anything new.

### Day 5 — Measure, document, package for Monday
- [ ] Re-run the eval harness + fixture tests; compile **before/after metrics**.
- [ ] Write the share-out: problem (token limits + AI slop) → approach (router + tiers + shift-left two-surface design) → what you built → metrics → live demo flow → rollout recommendation.
- [ ] Polish: `SETUP.md`, a `CHANGELOG`/version, and a short `CONTRIBUTING` for how to add an agent/skill.
- [ ] Dry-run the demo end-to-end.

---

## The shift-left CI job (design)

`.github/workflows/shift-left.yml`, triggered `on: pull_request`:

1. `actions/checkout` with `fetch-depth: 0` (need base history for `origin/<base>...HEAD`).
2. Detect changed paths to decide which scans to run (always: diff-digest + security + perf; conditionally: accessibility if UI files changed, migration-safety if migrations changed).
3. Run each relevant `scan.sh "$GITHUB_BASE_REF"`, capture output.
4. Aggregate into one Markdown report; post/update a **sticky comment** on the PR (e.g. via `marocchino/sticky-pull-request-comment` or the `gh` CLI keyed on a marker).
5. **Gating policy (graduated):**
   - Week 1: always pass; comment only (build trust, measure signal/noise).
   - Then: fail the check only on 🔴 criticals (hardcoded secret, destructive migration without a rollback path, removed auth check) — a *soft gate* with a documented override.

**Why deterministic-only in CI:** it's free, fast, and runs on every PR with no token budget.
The model-powered narrative (PR Prep) stays in the IDE where the author is in the loop; if you
want it in CI later, add it as an optional, token-budgeted job.

**Pre-push hook** mirrors the PR scan locally so the feedback arrives before the push — the
earliest practical point. Keep it fast and non-blocking (warn, allow override) so it doesn't
become something people disable.

---

## Expansion backlog (beyond the week)
- Org-level agents (`github.copilot.chat.organizationCustomAgents.enabled`) so the team shares one fleet.
- A metrics dashboard (parse CI comment history for catch trends).
- Auto-generated VPAT/accessibility-conformance evidence from the a11y scans.
- Routing eval in CI to prevent rubric regressions.
- Per-team `repo-conventions` in a monorepo via parent-repo discovery.

---

## Monday share-out — recommended format
A **live demo + one-page writeup** is the most convincing for a quick share-out:
- 90-second demo: ask the Router something ambiguous → watch it route + dispatch; run `/pr-prep` on a real diff; open a PR and show the shift-left comment fire.
- One-pager: the problem, the two-surface design, the metrics table (routing accuracy, token mix, scan precision/recall, shift-left catches), and a one-line rollout ask.

I can generate the one-pager and the demo script from your Day 5 metrics when you get there.
