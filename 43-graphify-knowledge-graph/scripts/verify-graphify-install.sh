#!/usr/bin/env bash
# Skill 43 — verify-graphify-install.sh
# Lightweight structural check that the skill landed AND (best-effort) that the
# graphify binary + graph artifacts are present. Exits 1 on any missing skill
# file; runtime/binary checks are warnings (they depend on the install step
# having been run on the box). Exits 0 when the skill folder is complete.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FAIL=0
ok(){ printf "  [OK]   %s\n" "$1"; }
bad(){ printf "  [FAIL] %s\n" "$1"; FAIL=$((FAIL+1)); }
warn(){ printf "  [WARN] %s\n" "$1"; }

echo ""
echo "Graphify Knowledge Graph — install verification"
echo ""

# ── 1. Skill files present (hard) ──
SKILL_FILES=(
  "SKILL.md" "INSTALL.md" "INSTRUCTIONS.md" "CORE_UPDATES.md"
  "EXAMPLES.md" "CHANGELOG.md" "skill-version.txt"
  "qc-graphify-knowledge-graph.sh" "scripts/verify-graphify-install.sh"
  "references/graphify-commands.md"
)
for f in "${SKILL_FILES[@]}"; do
  if [ -f "$GF_DIR/$f" ]; then ok "skill file $f present"; else bad "skill file $f MISSING"; fi
done

# skill-version.txt == 1.0.0
if [ "$(head -1 "$GF_DIR/skill-version.txt" 2>/dev/null | tr -d '[:space:]')" = "1.0.0" ]; then
  ok "skill-version.txt = 1.0.0"
else
  bad "skill-version.txt is not 1.0.0"
fi

# ── 2. Runtime (best-effort — warnings only) ──
if command -v graphify >/dev/null 2>&1; then
  ok "graphify binary on PATH"
else
  warn "graphify not on PATH yet — run INSTALL.md §2 (uv tool install \"graphifyy[all]\")"
fi

# Resolve the workspace to look for graph artifacts.
if [ -d "/data/.openclaw/workspace" ]; then
  WS="/data/.openclaw/workspace"
else
  WS="$HOME/.openclaw/workspace"
fi
if [ -f "$WS/graphify-out/graph.json" ]; then
  ok "graph.json present at $WS/graphify-out/"
else
  warn "no graph yet at $WS/graphify-out/graph.json — run INSTALL.md §5 (map the workforce ONCE on the client's own model)"
fi

echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "Result: FAILED ($FAIL missing skill file(s))"
  exit 1
fi
echo "Result: PASS (skill folder complete)"
exit 0
