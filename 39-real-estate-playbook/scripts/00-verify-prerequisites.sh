#!/usr/bin/env bash
# 00-verify-prerequisites.sh — Skill 39 (Real Estate Playbook & Property Intelligence)
#
# Verifies install prerequisites BEFORE any Skill 39 step runs.
#
# Governed by ../../QC-PROTOCOL.md (Sub-Agent Handoff + Mandatory QC Protocol).
# Category 10 of the rubric = presence + functional state checks for the
# sibling skills this skill builds on, with a clear halt naming the failure.
#
# Skill 39 is a brain EXTENSION on top of the conversational-AI stack. It does
# NOT modify any sibling skill; it only verifies they are present so its hooks
# land in a working environment.
#
# Prerequisites (presence-checked here; this skill REFUSES to claim "installed"
# until they are satisfied, but does NOT auto-install or modify them):
#   - Skill 29 — GHL Convert and Flow (lead routing + tag writes go through it)
#   - Skill 38 — Conversational AI System (the Sales-Brain core this extends)
#
# Soft prerequisites (warn-only — Skill 39 degrades gracefully without them):
#   - Skill 19 — Humanizer (used ALWAYS-ON for outbound copy if present)
#   - Skill 36 — GHL MCP Setup (preferred GHL access tier when present)
#
# Property-data provider keys are OPTIONAL and operator-supplied (see
# scripts/01-configure-providers.sh). Their ABSENCE is an honest capability gap,
# NOT a hard failure — the skill NEVER fabricates property data.
#
# Idempotent (read-only; never writes). Safe to re-run. OS-aware Darwin + Linux.

set -euo pipefail

OS="$(uname -s)"
case "$OS" in
  Darwin) DEFAULT_SKILLS_DIR="$HOME/.openclaw/skills" ;;
  Linux)  DEFAULT_SKILLS_DIR="/data/.openclaw/skills" ;;
  *) echo "Unsupported OS: $OS"; exit 2 ;;
esac
SKILLS_DIR="${OPENCLAW_SKILLS_DIR:-$DEFAULT_SKILLS_DIR}"

PREFIX="[skill 39][prereq]"
FAIL=0

echo "=== $PREFIX verifying prerequisites (OS: $OS, skills dir: $SKILLS_DIR) ==="

# ----------------------------------------------------------------------------
# Hard prerequisites — presence check (never auto-install, never modify)
# ----------------------------------------------------------------------------
check_hard() {
  local folder="$1" label="$2"
  if [ -d "$SKILLS_DIR/$folder" ]; then
    echo "  ✓ $label present ($folder)"
  else
    echo "  ✗ $label MISSING — expected $SKILLS_DIR/$folder"
    FAIL=1
  fi
}

check_hard "29-ghl-convert-and-flow" "Skill 29 (GHL Convert and Flow)"
check_hard "38-conversational-ai-system" "Skill 38 (Conversational AI System — Sales-Brain core)"

# ----------------------------------------------------------------------------
# Soft prerequisites — warn-only (graceful degradation)
# ----------------------------------------------------------------------------
check_soft() {
  local folder="$1" label="$2" note="$3"
  if [ -d "$SKILLS_DIR/$folder" ]; then
    echo "  ✓ $label present ($folder)"
  else
    echo "  ⚠️  $label not installed — $note"
  fi
}

check_soft "19-humanizer" "Skill 19 (Humanizer)" "outbound copy will not be auto-humanized"
check_soft "36-ghl-mcp-setup" "Skill 36 (GHL MCP Setup)" "GHL ops fall back to Skill 29 REST API"

# ----------------------------------------------------------------------------
# Provider keys — OPTIONAL, operator-supplied (honest-gap, never a hard fail)
# ----------------------------------------------------------------------------
echo "  ℹ️  Property-data provider keys are OPTIONAL and operator-supplied."
echo "      Configure them with scripts/01-configure-providers.sh. If a provider"
echo "      key is absent the matching lookup returns an HONEST capability gap"
echo "      (never fabricated property data)."

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — all hard prerequisites present. Proceed with Skill 39 install."
  exit 0
else
  echo "RESULT: FAIL — a hard prerequisite is missing (named above). Install/verify it"
  echo "        FIRST, then re-run this script. Skill 39 does NOT auto-install siblings."
  exit 1
fi
