#!/usr/bin/env bash
# qc-zhc-tag-prefix.sh — machine-enforce the ZHC tag-prefix rule (v1.5.0).
#
# WHAT IT ENFORCES
# ----------------
# Every tag the agent CREATES programmatically must be prefixed `ZHC-` (per
# protocols/zhc-tag-prefix-protocol.md + MEMORY.md Rule 20). This gate proves the
# rule is documented and that the canonical PROGRAMMATIC tag EXAMPLES the skill
# ships all carry the `ZHC-` prefix — so a future edit can't quietly reintroduce a
# bare auto-created tag.
#
# CHECKS
#   1. The protocol file exists and states the rule (the prefix + "not retroactive").
#   2. The five F44/F45/F47/F50 canonical tag tokens are the ZHC- forms (the
#      feature protocols use them, and they must be prefixed):
#        ZHC-tension-detected ZHC-aggression-detected ZHC-bot-suspected
#        ZHC-interrupt-handled ZHC-faq-detoured ZHC-aggression-handled-and-resumed
#        ZHC-out-of-service-area ZHC-service-area-confirmed ZHC-service-area-flexible
#        ZHC-faq-answered
#   3. No "bare" programmatic-creation EXAMPLE survives: a create_tag(...) /
#      POST .../tags example whose name= / "name": value is a quoted literal must
#      use a ZHC- value (or a placeholder). This is the load-bearing assert — it
#      scans the create-tag mechanism docs (conversation-workflows-protocol.md +
#      workflow-ai-instructions-standard.md) and the v1.5.0 protocols.
#
# Pure BASH (grep/sed) — respects qc-static's ban on claude-/anthropic strings in
# .py. bash -n clean. set -uo pipefail.
#
# Exit 0 = clean; 1 = a violation (missing rule, missing ZHC- token, or a bare
# programmatic tag example).
#
# Usage:
#   bash scripts/qc-zhc-tag-prefix.sh
#   bash scripts/qc-zhc-tag-prefix.sh --skill-dir /path/to/38-conversational-ai-system

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

while [ $# -gt 0 ]; do
  case "$1" in
    --skill-dir) SKILL_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

FAIL=0
PROTO="$SKILL_DIR/protocols/zhc-tag-prefix-protocol.md"

echo "=== qc-zhc-tag-prefix: ZHC- programmatic tag-prefix guard ==="
echo "skill_dir : $SKILL_DIR"
echo ""

# --- 1. The protocol exists and states the rule. ---
if [ ! -f "$PROTO" ]; then
  echo "  [FAIL] missing protocols/zhc-tag-prefix-protocol.md"
  FAIL=1
else
  if grep -q 'ZHC-' "$PROTO" && grep -qi 'not retroactive' "$PROTO" && grep -qi 'prefix' "$PROTO"; then
    echo "  [PASS] zhc-tag-prefix-protocol.md states the rule (ZHC- prefix, not retroactive)"
  else
    echo "  [FAIL] zhc-tag-prefix-protocol.md does not clearly state the prefix + not-retroactive rule"
    FAIL=1
  fi
fi

# --- 2. The canonical ZHC- tag tokens appear (the feature protocols use them). ---
REQUIRED_TOKENS=(
  "ZHC-tension-detected"
  "ZHC-aggression-detected"
  "ZHC-bot-suspected"
  "ZHC-interrupt-handled"
  "ZHC-faq-detoured"
  "ZHC-aggression-handled-and-resumed"
  "ZHC-out-of-service-area"
  "ZHC-service-area-confirmed"
  "ZHC-service-area-flexible"
  "ZHC-faq-answered"
)
echo ""
for tok in "${REQUIRED_TOKENS[@]}"; do
  if grep -rqF -- "$tok" "$SKILL_DIR/protocols" 2>/dev/null; then
    echo "  [PASS] canonical tag present: $tok"
  else
    echo "  [FAIL] canonical ZHC- tag token missing from protocols/: $tok"
    FAIL=1
  fi
done

# --- 3. No bare programmatic-creation tag EXAMPLE. ---
# Scan the create-tag mechanism docs + the v1.5.0 protocols for create_tag(...)
# name= and "name": literals, and the POST .../tags body "name": literals that
# sit in a create-tag context. Any quoted literal value that is NOT a placeholder
# (<...> / $...) and NOT already ZHC-prefixed is a violation.
echo ""
SCAN_FILES=(
  "$SKILL_DIR/protocols/conversation-workflows-protocol.md"
  "$SKILL_DIR/references/workflow-ai-instructions-standard.md"
  "$SKILL_DIR/protocols/zhc-tag-prefix-protocol.md"
  "$SKILL_DIR/protocols/aggression-detection-protocol.md"
  "$SKILL_DIR/protocols/smart-playbook-switching-protocol.md"
  "$SKILL_DIR/protocols/geo-qualification-protocol.md"
  "$SKILL_DIR/protocols/smart-faq-tool-protocol.md"
)

# A "bare tag literal" = a CREATE-context name=  or  "name":  whose value is a
# double- or single-quoted string that does NOT start with ZHC- and is not a
# placeholder. We deliberately scope this to tag-CREATION lines only:
#   - create_tag(... name="...")
#   - POST .../tags ... "name": "..."  (a create-tag-body line)
# An Add-Tag / add_tag action APPLYING an operator's pre-existing tag (verbatim,
# by design — e.g. add_tag(name="vip")) is NOT a programmatic creation and is
# explicitly NOT flagged.
bare_hits=0
for f in "${SCAN_FILES[@]}"; do
  [ -f "$f" ] || continue
  # Pull candidate create-tag name literals from CREATE-context lines only.
  while IFS= read -r line; do
    # Skip apply/Add-Tag context (applying an existing tag verbatim is allowed).
    printf '%s\n' "$line" | grep -qiE 'add_tag|add-tag|apply' && continue
    # Extract the quoted value after name= or "name":
    val="$(printf '%s\n' "$line" | sed -nE 's/.*(name=|"name"[[:space:]]*:)[[:space:]]*"([^"]*)".*/\2/p')"
    [ -z "$val" ] && val="$(printf '%s\n' "$line" | sed -nE "s/.*name=[[:space:]]*'([^']*)'.*/\1/p")"
    [ -z "$val" ] && continue
    # Allowed: a placeholder (<...> or $...) or a ZHC- value.
    case "$val" in
      "<"*|"\$"*|ZHC-*) : ;;  # ok
      *)
        echo "  [FAIL] bare programmatic create-tag literal in $(basename "$f"): name=\"$val\" (must be ZHC- or a placeholder)"
        bare_hits=$((bare_hits+1))
        FAIL=1
        ;;
    esac
  done < <(grep -nE '(create_tag|/tags)' "$f" 2>/dev/null | grep -E '(name=|"name"[[:space:]]*:)' )
done
if [ "$bare_hits" -eq 0 ]; then
  echo "  [PASS] no bare programmatic create-tag examples (all are ZHC- or placeholders)"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — ZHC- tag-prefix rule documented; canonical tags prefixed; no bare programmatic tag example."
  exit 0
else
  echo "RESULT: FAIL — a ZHC- tag-prefix violation is present. See above."
  exit 1
fi
