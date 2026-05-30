#!/usr/bin/env bash
# qc-ghl-raw-body-standard.sh — machine-enforce the GHL Raw Body JSON Standard.
#
# WHY THIS EXISTS
# ---------------
# references/ghl-raw-body-json-standard.md is the single human-readable standard
# for the GHL Custom Webhook RAW BODY (object A): the FULL 23-key FLAT JSON. Prose
# is not enforcement — this gate asserts the standard doc still CARRIES its hard §0
# rule ("EVERY GHL RAW BODY MUST BE THE FULL 23-KEY FLAT JSON"), the FLAT rule, the
# placeholder-free messageTemplate rule, deliver:false, and the EXACT 23-key list.
#
# It then COMPOSES with scripts/qc-23-key-bodies.sh — the linter that scans every
# actual object-A body embedded in the skill and asserts exactly 23 flat
# placeholder-free keys. So this gate proves BOTH: (1) the standard is documented,
# and (2) every real body in the skill obeys it.
#
# Exit codes: 0 = standard documented + all real bodies pass; 1 = the standard doc
# is missing a mandatory element OR a real body violates the 23-key rule; 2 = bad
# usage.
#
# PURE BASH (grep) for the doc checks; delegates the body lint to
# qc-23-key-bodies.sh. Respects qc-static.yml's .py claude-/anthropic scan
# (this file has no python). bash -n clean. set -uo pipefail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

while [ $# -gt 0 ]; do
  case "$1" in
    --skill-dir) SKILL_DIR="$2"; shift 2 ;;
    -h|--help)   sed -n '1,30p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

DOC="$SKILL_DIR/references/ghl-raw-body-json-standard.md"

echo "=== qc-ghl-raw-body-standard: GHL Raw Body JSON Standard gate ==="
echo "doc: $DOC"

if [ ! -f "$DOC" ]; then
  echo "RESULT: FAIL — ghl-raw-body-json-standard.md is MISSING."
  exit 1
fi

FAIL=0
need() {  # need "<label>" "<grep -E pattern>"
  local label="$1" pat="$2"
  if grep -qE -- "$pat" "$DOC"; then
    echo "  [PASS] $label"
  else
    echo "  [FAIL] $label  (pattern: $pat)"
    FAIL=1
  fi
}

# The hard §0 rule headline.
need "§0 rule headline (FULL 23-key FLAT JSON)" 'EVERY GHL RAW BODY MUST BE THE FULL 23-KEY FLAT JSON'
need "23 = minimum AND standard, never fewer, never nested" '23 is the MINIMUM and the STANDARD|never fewer, never nested|23 = the MINIMUM'
need "FLAT rule (nested makes every field resolve empty)" 'nested.*resolve EMPTY|nesting .* EMPTY|FLAT — no nested'
need "messageTemplate placeholder-free stub (real one server-side)" 'placeholder-free stub'
need "deliver: false rule" 'deliver.{0,4}false|`deliver: false`'
need "per-channel variants change only channel + session_key prefix" 'channel.{0,3}\+.{0,3}.?session_key.? prefix|change ONLY .?channel.? \+ the .?session_key.? prefix'

# The EXACT 23 keys must all be present in the doc.
for k in id match action agent_id model wakeMode name session_key messageTemplate deliver \
         timeoutSeconds channel to thinking contact_id first_name last_name email phone \
         subject message_body location_id location_name; do
  if grep -qE -- "\`$k\`|\"$k\"" "$DOC"; then
    echo "  [PASS] documents key: $k"
  else
    echo "  [FAIL] MISSING key in 23-key list: $k"
    FAIL=1
  fi
done

# Reference to the source of truth + the enforcing linter.
need "references GHL-INBOUND-AND-PLAYBOOKS.md (source of truth)" 'GHL-INBOUND-AND-PLAYBOOKS.md'
need "references qc-23-key-bodies.sh (the enforcing linter)"     'qc-23-key-bodies.sh'

echo ""
echo "--- composing with qc-23-key-bodies.sh (lints every real object-A body) ---"
QC_23="$SCRIPT_DIR/qc-23-key-bodies.sh"
if [ -f "$QC_23" ]; then
  if bash "$QC_23" --skill-dir "$SKILL_DIR" >/dev/null 2>&1; then
    echo "  [PASS] all real object-A bodies are 23-key, flat, placeholder-free"
  else
    echo "  [FAIL] qc-23-key-bodies.sh found a body that violates the 23-key rule — run it directly"
    FAIL=1
  fi
else
  echo "  [FAIL] qc-23-key-bodies.sh not found (cannot compose)"
  FAIL=1
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — the GHL Raw Body JSON Standard is documented and every real body obeys it."
  exit 0
else
  echo "RESULT: FAIL — the GHL Raw Body JSON Standard is incomplete or a real body violates it (see above)."
  exit 1
fi
