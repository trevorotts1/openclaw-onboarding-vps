#!/usr/bin/env bash
# 05-install-sales-brain-extension.sh — Skill 39 (Real Estate Playbook)
#
# Installs the VERTICAL Sales-Brain extension for real estate WITHOUT editing
# Skill 38's core. The hook is ADDITIVE by design:
#
#   - Skill 38's Sales-Brain reads every *.md it finds in its
#     protocols/extensions/ directory (an additive, drop-in extension folder).
#   - This script copies references/sales-brain-re-extension.md into that
#     extensions folder as `real-estate-sales-brain.md`.
#   - It does NOT modify, reorder, or delete any existing Skill 38 protocol file.
#   - If Skill 38's extensions/ folder does not exist (older Skill 38), it
#     creates ONLY that subfolder and drops the file there; the core is untouched.
#
# WHY additive: Skill 38 is a SIBLING, not ours to mutate. A destructive edit to
# its sales-best-practices-protocol.md would break Skill 38's own QC
# (qc-23-key-bodies / verbatim-protocol checks). The extension file carries the
# RE-specific objection patterns, the CMA pricing-reveal timing rule, and the
# SPICED-RE discovery frame as a SEPARATE, clearly-labeled add-on.
#
# Idempotent. OS-aware Darwin + Linux. set -uo pipefail.
#
# Usage: 05-install-sales-brain-extension.sh [<skills_dir>]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$SKILL_ROOT/references/sales-brain-re-extension.md"

OS="$(uname -s)"
case "$OS" in
  Darwin) DEFAULT_SKILLS_DIR="$HOME/.openclaw/skills" ;;
  Linux)  DEFAULT_SKILLS_DIR="/data/.openclaw/skills" ;;
  *) DEFAULT_SKILLS_DIR="$HOME/.openclaw/skills" ;;
esac
SKILLS_DIR="${1:-${OPENCLAW_SKILLS_DIR:-$DEFAULT_SKILLS_DIR}}"

S38="$SKILLS_DIR/38-conversational-ai-system"
EXT_DIR="$S38/protocols/extensions"
DEST="$EXT_DIR/real-estate-sales-brain.md"

if [ ! -f "$SRC" ]; then
  echo "ERROR: extension source missing: $SRC" >&2
  exit 1
fi

if [ ! -d "$S38" ]; then
  echo "⚠️  [skill 39] Skill 38 not found at $S38 — cannot install the Sales-Brain extension."
  echo "    The extension file is shipped at: $SRC"
  echo "    Install Skill 38 first, then re-run this script. (No core files were touched.)"
  exit 1
fi

# Create ONLY the additive extensions subfolder if needed (never touches core).
mkdir -p "$EXT_DIR"

# Idempotent: only copy if absent or changed.
if [ -f "$DEST" ] && cmp -s "$SRC" "$DEST"; then
  echo "[skill 39] Sales-Brain RE extension already current: $DEST"
  exit 0
fi

cp "$SRC" "$DEST"
echo "[skill 39] installed Sales-Brain RE extension (ADDITIVE — Skill 38 core untouched):"
echo "    $DEST"
echo "    Skill 38 reads protocols/extensions/*.md; no Skill 38 file was modified."
exit 0
