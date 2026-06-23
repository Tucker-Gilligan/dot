---
name: security-privacy-review
description: Scan a change for security flaws and student-data privacy risk (FERPA, COPPA, state student-privacy laws). Runs a pattern scan for PII handling, auth/authz changes, data egress, secrets, and injection, then guides a FERPA/COPPA-aware review. Use when reviewing code that touches user data, authentication, permissions, or third-party/AI data sharing in an ed-tech product.
argument-hint: "[base-branch] (optional, e.g. main)"
context: fork
---

# Security & student-data privacy review

Deterministic scan + an ed-tech privacy lens, so the model spends tokens reasoning about data
flows rather than grepping. Powers the **Security Reviewer** agent.

## How to run
Read-only; never mutates the repo.

```bash
bash .github/skills/security-privacy-review/scripts/scan.sh        # uncommitted vs HEAD
bash .github/skills/security-privacy-review/scripts/scan.sh main   # branch vs origin/main
```

Script: [scan.sh](./scripts/scan.sh). It flags auth changes, PII/education-record fields, PII in
logs, outbound/third-party/AI calls, hardcoded secrets, and injection sinks. Every `[FLAG]` is a
**lead to verify**, not a verdict.

## Review lens (ed-tech)
Assume data includes minors' PII and education records. For each flagged area, reason about the
real data flow, not the single line:

- **FERPA** — education records (grades, attendance, discipline, IEP/504) need access control on a legitimate-educational-interest basis; disclosure to third parties needs a basis (e.g. school-official exception). Flag new sharing or broadened access.
- **COPPA** — for under-13 users: data minimization, parental-consent flows, and *no* behavioral advertising / unnecessary tracking. Flag new collection or trackers.
- **State laws (e.g. SOPIPA)** — no selling student data, no targeted ads, reasonable security, deletion on request.
- **AuthZ / tenant isolation** — can a user reach another student's/teacher's/school's data? Check ownership and tenant checks on every object access (IDOR).
- **Data egress** — does student PII leave to analytics, logs, or an LLM API? Is there a contractual/consent basis?
- **Secrets & injection** — standard AppSec: no hardcoded secrets, parameterized queries, safe deserialization, no SSRF/XSS.

## Output
Ranked findings with severity, `file:line`, the concrete risk, the relevant control/regulation,
and a recommended fix — then a ship / don't-ship call and the top 3 to fix first. Hand fixes to
the Implementer; the reviewer doesn't edit.

## Notes
- `context: fork` keeps the scan + diff out of the main conversation (needs `github.copilot.chat.skillTool.enabled`; runs inline otherwise).
- This is a first-pass aid, **not** a substitute for a formal security review or legal/compliance sign-off on high-risk changes.
