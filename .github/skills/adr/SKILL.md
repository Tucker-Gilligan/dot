---
name: adr
description: Create an Architecture Decision Record (ADR) capturing a significant technical decision — its context, the decision, alternatives considered, and consequences. Use when asked to document a design decision, write an ADR, or record why an approach was chosen.
argument-hint: "[short title of the decision]"
---

# Architecture Decision Record

An ADR captures one significant decision so future engineers understand *why*, not just *what*.
Keep it short, factual, and immutable once accepted (supersede with a new ADR rather than editing).

This file is reference material — reference it from an agent body via `#file:.github/skills/adr/SKILL.md`. There is no script; the deliverable is the ADR file itself, produced by the active agent (typically **Doc Writer**) using `edit/editFiles`.

## How to use
1. Find existing ADRs (commonly `docs/adr/` or `docs/decisions/`). Match their numbering and format if present; otherwise create `docs/adr/NNNN-short-title.md` (zero-padded, incrementing).
2. Fill in the template below. Be concrete about alternatives and trade-offs — that's the part future readers need most.
3. Status starts `Proposed`; move to `Accepted` once agreed. Mark superseded ADRs with a link to the replacement.

## Template
```markdown
# NNNN. <Short decision title>

- Status: Proposed | Accepted | Superseded by [ADR-XXXX](xxxx-...)
- Date: YYYY-MM-DD
- Deciders: <names/roles>

## Context
What's the problem or force that requires a decision? Constraints, requirements, and any
ed-tech-specific factors (student-data privacy, accessibility, peak-load seasonality, SIS/LMS
integration constraints).

## Decision
The choice we're making, stated plainly in active voice: "We will …".

## Alternatives considered
- **Option A** — pros / cons / why not.
- **Option B** — pros / cons / why not.

## Consequences
- Positive: what gets better.
- Negative / costs: what we accept or take on.
- Follow-ups: migrations, deprecations, or future decisions this implies.
```

## Tips
- One decision per ADR. If you're tempted to record two, write two.
- Record the decision when it's made, while the reasoning is fresh.
- Link to relevant code, RFCs, or tickets, but keep the ADR self-contained enough to read alone.
