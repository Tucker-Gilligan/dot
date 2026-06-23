#!/usr/bin/env bash
# validate.sh — sanity-check the agent fleet after edits.
# Checks: YAML frontmatter, model names against the org lineup, Router coverage,
# skill name==dir, referenced scripts exist, bash syntax, and POSIX-portable regex
# (no PCRE lookaheads or \s \b \w \d — they break on macOS/BSD grep).
#
# Run from the repo root:  bash .github/validate.sh
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
FAIL=0

echo "== making scan scripts executable =="
chmod +x .github/skills/*/scripts/*.sh 2>/dev/null || true

echo "== bash syntax =="
for s in .github/skills/*/scripts/*.sh; do
  if bash -n "$s"; then echo "  ok  $s"; else echo "  FAIL $s"; FAIL=1; fi
done

echo "== POSIX-portable regex (macOS/BSD grep safe) =="
if grep -rnE '\(\?[!=]|\\s|\\b|\\w|\\d' .github/skills/*/scripts/ | grep -v ':#'; then
  echo "  FAIL: non-portable regex above (use [[:space:]], [[:alnum:]_], two-step grep instead)"; FAIL=1
else
  echo "  ok  no lookaheads / \\s \\b \\w \\d"
fi

echo "== frontmatter + wiring =="
python3 - <<'PY' || exit 1
import glob, re, os, sys
try:
    import yaml
except ImportError:
    print("  (PyYAML not installed — run: pip3 install pyyaml — skipping deep checks)"); sys.exit(0)
errors=[]; names={}; parsed={}
AVAIL={"Claude Opus 4.7","Claude Sonnet 4.6","GPT-5 mini","GPT-5.5"}  # edit to match your org
def fm(path):
    m=re.match(r"^---\n(.*?)\n---\n", open(path).read(), re.S)
    if not m: errors.append(f"{path}: no YAML frontmatter"); return None
    try: return yaml.safe_load(m.group(1))
    except Exception as e: errors.append(f"{path}: YAML error: {e}"); return None
for f in sorted(glob.glob(".github/agents/*.agent.md")):
    d=fm(f)
    if not d: continue
    parsed[f]=d; names[d.get("name")]=f
    for mdl in (d.get("model") or []):
        if mdl not in AVAIL: errors.append(f"{f}: model '{mdl}' not in org lineup {sorted(AVAIL)}")
    for h in (d.get("handoffs") or []):
        hm=(h.get("model") or "").replace(" (copilot)","")
        if hm and hm not in AVAIL: errors.append(f"{f}: handoff model '{hm}' not in org lineup")
valid=set(names)|{"agent"}
for f,d in parsed.items():
    for a in (d.get("agents") or []):
        if a not in valid: errors.append(f"{f}: agents[] references unknown agent '{a}'")
    for h in (d.get("handoffs") or []):
        if h.get("agent") not in valid: errors.append(f"{f}: handoff to unknown agent '{h.get('agent')}'")
        if not h.get("label"): errors.append(f"{f}: a handoff is missing 'label'")
    if d.get("agents") and "agent" not in (d.get("tools") or []):
        errors.append(f"{f}: declares agents[] but 'agent' tool is not in tools")
if "Router" in names:
    R=parsed[names["Router"]]
    miss_a=set(names)-set(R.get("agents",[]))-{"Router"}
    miss_h=set(names)-{h["agent"] for h in R.get("handoffs",[])}-{"Router"}
    if miss_a: errors.append(f"Router agents[] missing: {sorted(miss_a)}")
    if miss_h: errors.append(f"Router handoffs missing buttons for: {sorted(miss_h)}")
else:
    errors.append("No Router agent found")
for f in glob.glob(".github/skills/*/SKILL.md"):
    d=fm(f)
    if not d: continue
    nm=d.get("name",""); dirn=os.path.basename(os.path.dirname(f))
    if nm!=dirn: errors.append(f"{f}: name '{nm}' must equal directory '{dirn}'")
    if not re.fullmatch(r"[a-z0-9-]{1,64}", nm or ""): errors.append(f"{f}: name '{nm}' invalid (lowercase/digits/hyphens only)")
    if not d.get("description"): errors.append(f"{f}: missing description")
    for rel in re.findall(r"\]\(\.\/([^)]+)\)", open(f).read()):
        if not os.path.exists(os.path.join(os.path.dirname(f), rel)): errors.append(f"{f}: referenced file missing ./{rel}")
print(f"  agents: {len(names)} | skills: {len(glob.glob('.github/skills/*/SKILL.md'))}")
if errors:
    print("  ISSUES:")
    for e in errors: print("   !", e)
    sys.exit(1)
print("  ok  frontmatter + wiring valid")
PY
PYEXIT=$?
[ $PYEXIT -ne 0 ] && FAIL=1

echo
if [ $FAIL -eq 0 ]; then echo "✅ ALL CHECKS PASSED"; else echo "❌ CHECKS FAILED — see above"; fi
exit $FAIL
