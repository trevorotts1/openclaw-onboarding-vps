#!/usr/bin/env bash
# 00-verify-prerequisites.sh — Skill 40 (ZHC Public Records Scraper)
#
# Verifies install prerequisites BEFORE any Skill 40 step runs.
#
# Governed by ../../QC-PROTOCOL.md (Sub-Agent Handoff + Mandatory QC Protocol).
#
# Skill 40 is a TIERED public-records lookup engine. It has NO hard sibling-skill
# prerequisite — it can run standalone — but it is most useful paired with
# Skill 39 (Real Estate Playbook), whose pre-foreclosure protocol consumes the
# NOD / tax-delinquency signals Skill 40 produces.
#
# Tooling prerequisites (checked; soft unless noted):
#   - curl        — REQUIRED for any live fetch (Tier 1/2/3). HARD.
#   - A fetch path — at least one of: curl reachable network, or a configured
#                    browser tool (Playwright via Skill 03/agent-browser). The
#                    skill warns if neither is obviously available; it NEVER
#                    fabricates records when it cannot fetch (Tier 4 honest gap).
#
# Soft (pairing) prerequisite:
#   - Skill 39 — Real Estate Playbook (consumes Skill 40 output). Warn-only.
#
# Idempotent (read-only). OS-aware Darwin + Linux. set -uo pipefail.

set -uo pipefail

OS="$(uname -s)"
case "$OS" in
  Darwin) DEFAULT_SKILLS_DIR="$HOME/.openclaw/skills" ;;
  Linux)  DEFAULT_SKILLS_DIR="/data/.openclaw/skills" ;;
  *) echo "Unsupported OS: $OS"; exit 2 ;;
esac
SKILLS_DIR="${OPENCLAW_SKILLS_DIR:-$DEFAULT_SKILLS_DIR}"

PREFIX="[skill 40][prereq]"
FAIL=0

echo "=== $PREFIX verifying prerequisites (OS: $OS) ==="

# HARD: curl
if command -v curl >/dev/null 2>&1; then
  echo "  ✓ curl present ($(command -v curl))"
else
  echo "  ✗ curl MISSING — required for any live public-records fetch."
  FAIL=1
fi

# SOFT: a browser fetch path (some county sites need JS / forms)
if [ -d "$SKILLS_DIR/03-agent-browser" ] || command -v playwright >/dev/null 2>&1; then
  echo "  ✓ a browser fetch path appears available (Skill 03 / playwright)"
else
  echo "  ⚠️  no obvious browser fetch path — JS-heavy county portals may be an honest gap"
fi

# SOFT: Skill 39 pairing
if [ -d "$SKILLS_DIR/39-real-estate-playbook" ]; then
  echo "  ✓ Skill 39 (Real Estate Playbook) present — pre-foreclosure pairing enabled"
else
  echo "  ⚠️  Skill 39 not installed — Skill 40 still runs standalone, but the"
  echo "      pre-foreclosure outreach pairing is unavailable until Skill 39 is added."
fi

# Compliance reminder (always printed)
echo "  ℹ️  COMPLIANCE: Skill 40 respects robots.txt, references each target's ToS,"
echo "      attributes source + timestamp on every record, and NEVER fabricates a"
echo "      record. No online DB / blocked target => Tier 4 HONEST GAP (told to operator)."

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — proceed with Skill 40 install."
  exit 0
else
  echo "RESULT: FAIL — a hard prerequisite is missing (named above). Fix it, then re-run."
  exit 1
fi
