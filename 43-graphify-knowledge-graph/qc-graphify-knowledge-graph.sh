#!/usr/bin/env bash
# Skill 43 — Graphify Knowledge Graph — Install QC
set -u
PASS=0; FAIL=0; WARN=0
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB="$SKILL_DIR/../lib-shared.sh"; [ -f "$LIB" ] && source "$LIB"
if ! command -v resolve_platform_paths >/dev/null 2>&1; then
  resolve_platform_paths() { export WORKSPACE="$HOME/clawd" SKILLS_DIR_DEFAULT="$HOME/.openclaw/skills"; }
fi
resolve_platform_paths
red(){ printf "\033[31m%s\033[0m\n" "$1"; }; green(){ printf "\033[32m%s\033[0m\n" "$1"; }; yellow(){ printf "\033[33m%s\033[0m\n" "$1"; }
assert(){ if eval "$2" >/dev/null 2>&1; then green "  ✓ PASS — $1"; PASS=$((PASS+1)); else red "  ✗ FAIL — $1"; FAIL=$((FAIL+1)); fi; }
warn_only(){ if eval "$2" >/dev/null 2>&1; then green "  ✓ PASS — $1"; PASS=$((PASS+1)); else yellow "  ⚠ WARN — $1"; WARN=$((WARN+1)); fi; }

GF_DIR="$SKILL_DIR"

echo ""
echo "═══ Skill 43 — Graphify Knowledge Graph — Install QC ═══"
echo ""

# ── Skill files (hard) ──
assert "SKILL.md present" "[ -f \"$GF_DIR/SKILL.md\" ]"
assert "INSTALL.md present" "[ -f \"$GF_DIR/INSTALL.md\" ]"
assert "INSTRUCTIONS.md present" "[ -f \"$GF_DIR/INSTRUCTIONS.md\" ]"
assert "CORE_UPDATES.md present" "[ -f \"$GF_DIR/CORE_UPDATES.md\" ]"
assert "EXAMPLES.md present" "[ -f \"$GF_DIR/EXAMPLES.md\" ]"
assert "CHANGELOG.md present" "[ -f \"$GF_DIR/CHANGELOG.md\" ]"
assert "skill-version.txt present" "[ -f \"$GF_DIR/skill-version.txt\" ]"
assert "skill-version.txt = 1.0.0" "[ \"\$(head -1 \"$GF_DIR/skill-version.txt\" | tr -d '[:space:]')\" = '1.0.0' ]"
assert "references/graphify-commands.md present" "[ -f \"$GF_DIR/references/graphify-commands.md\" ]"
assert "scripts/verify-graphify-install.sh present" "[ -f \"$GF_DIR/scripts/verify-graphify-install.sh\" ]"

# ── Content guarantees (the load-bearing facts must be present) ──
assert "INSTALL.md installs graphifyy[all]" "grep -q 'graphifyy\\[all\\]' \"$GF_DIR/INSTALL.md\""
assert "INSTALL.md registers OpenClaw skill (graphify install --platform claw)" "grep -q 'graphify install --platform claw' \"$GF_DIR/INSTALL.md\""
assert "INSTALL.md wires AGENTS.md (graphify claw install)" "grep -q 'graphify claw install' \"$GF_DIR/INSTALL.md\""
assert "INSTALL.md installs the free AST hook (graphify hook install)" "grep -q 'graphify hook install' \"$GF_DIR/INSTALL.md\""
assert "INSTALL.md maps on the CLIENT'S OWN model (--backend ollama)" "grep -q -- '--backend ollama' \"$GF_DIR/INSTALL.md\""
assert "SKILL.md states semantic pass is on-demand / owner-triggered" "grep -qiE 'on-demand|owner-triggered' \"$GF_DIR/SKILL.md\""
assert "SKILL.md states AST rebuild is free + automatic" "grep -qiE 'free.*automatic|automatic.*free|FREE' \"$GF_DIR/SKILL.md\""
assert "INSTRUCTIONS.md routes codebase questions through graphify query" "grep -q 'graphify query' \"$GF_DIR/INSTRUCTIONS.md\""
assert "no-comingling guardrail referenced (N29 / operator keys)" "grep -qiE 'N29|operator key|never operator|NO-COMINGLING' \"$GF_DIR/SKILL.md\" \"$GF_DIR/INSTRUCTIONS.md\""
assert "VPS apt-is-a-brew-shim warning present (no apt)" "grep -qiE 'apt.*shim|do NOT use apt|brew shim' \"$GF_DIR/INSTALL.md\""

# ── No working artifacts shipped ──
assert "no working artifacts shipped (.bak/.tmp/QC-READY.txt/graphify-out)" "[ \$(find \"$GF_DIR\" \\( -name '*.bak' -o -name '*.tmp' -o -name 'QC-READY.txt' -o -name 'graphify-out' \\) 2>/dev/null | wc -l | tr -d ' ') -eq 0 ]"

# ── Runtime (warnings — depend on install having run on the box) ──
warn_only "graphify binary on PATH (install step run)" "command -v graphify >/dev/null 2>&1"
warn_only "Skill 23 (AI Workforce) installed (recommended — gives a workforce to map)" "[ -d \"$SKILLS_DIR_DEFAULT/23-ai-workforce-blueprint\" ]"

echo ""
echo "═══ Result: $PASS passed | $FAIL failed | $WARN warnings ═══"
[ $FAIL -gt 0 ] && { red "Skill 43 QC FAILED"; exit 1; } || { green "Skill 43 QC PASS"; exit 0; }
