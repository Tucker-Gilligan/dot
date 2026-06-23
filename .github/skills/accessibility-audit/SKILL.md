---
name: accessibility-audit
description: Audit UI changes for accessibility against WCAG 2.2 AA and Section 508. Runs a static scan for common markup issues (missing alt text, unlabeled inputs, non-interactive click handlers, positive tabindex, removed focus outlines, missing lang) and guides a manual review of keyboard, focus, contrast, and screen-reader behavior. Use for frontend/UI changes.
argument-hint: "[base-branch] (optional, e.g. main)"
context: fork
---

# Accessibility audit (WCAG 2.2 AA / Section 508)

Static scan + a structured manual checklist. The scan does the mechanical markup checks; the
reviewer judges everything automation can't. Powers the **Accessibility Reviewer** agent.

## How to run
Read-only.

```bash
bash .github/skills/accessibility-audit/scripts/scan.sh        # uncommitted vs HEAD
bash .github/skills/accessibility-audit/scripts/scan.sh main   # branch vs origin/main
```

Script: [scan.sh](./scripts/scan.sh). It only inspects changed UI files (`.html/.jsx/.tsx/.vue/.svelte/…`) and tags each flag with the relevant WCAG criterion.

## What the scan catches (markup only)
Missing `alt`; inputs/buttons without accessible names; click handlers on `<div>`/`<span>`;
positive `tabindex`; anchors-as-buttons; removed focus outlines; fixed-px fonts; missing `lang`;
`dangerouslySetInnerHTML`/`v-html`; media without captions; raw `role=` usage.

## What you must check manually (the scan can't)
- **Keyboard**: every interactive element reachable and operable; no traps; logical focus order; visible focus indicator.
- **Contrast**: 4.5:1 text / 3:1 large text & UI components; info not by color alone.
- **Screen reader**: meaningful names/roles/states; dynamic updates announced via live regions; headings/landmarks structure the page.
- **Ed-tech**: timed assessments offer adjustable/extended time; STEM/math uses accessible notation (MathML/MathJax); interactive learning content works with AT.
- **Motion/zoom**: respects reduced-motion; usable at 200% zoom and 320px reflow.

## Output
Findings with severity (🔴 blocker / 🟡 should-fix / 🟢 minor), WCAG success criterion, `file:line`,
user impact, and a concrete fix. Clearly separate automated flags from items needing manual/AT
verification. Hand fixes to the Implementer.

## Notes
`context: fork` keeps the scan output out of the main conversation (needs `github.copilot.chat.skillTool.enabled`; inline otherwise). For full conformance (e.g. a VPAT), pair this with real assistive-tech testing and an automated runtime checker (axe, Lighthouse) in CI.
