#!/usr/bin/env bash
# qc-communications-playbook-standard.sh — machine-enforce the Communications
# Playbook Standard.
#
# WHY THIS EXISTS
# ---------------
# references/communications-playbook-standard.md is the BINDING standard for every
# per-channel/per-scenario communication playbook this skill emits. Prose is not
# enforcement — this gate asserts the doc still CARRIES its hard §0 mandatory
# checklist ("EVERY COMMUNICATION PLAYBOOK MUST INCLUDE ALL OF THE FOLLOWING") and
# every one of its required items, so a future edit that quietly drops a mandatory
# inclusion (the send rule, the conversation-memory protocol, quiet-hours, the
# ZHC- tag prefix, per-channel formatting, etc.) FAILS the build.
#
# It composes with the rest of the Trinity gates: the actual send-directive and
# conversation-memory STEPS on the live server mapping are enforced by
# qc-send-directive.sh + qc-conversation-memory.sh; this gate enforces that the
# STANDARD itself still mandates them.
#
# Exit codes: 0 = standard present + complete; 1 = the standard doc is missing or
# is missing a mandatory item; 2 = bad usage.
#
# PURE BASH (grep), no python — respects qc-static.yml's .py claude-/anthropic
# scan. bash -n clean. set -uo pipefail.

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

DOC="$SKILL_DIR/references/communications-playbook-standard.md"

echo "=== qc-communications-playbook-standard: Communications Playbook Standard gate ==="
echo "doc: $DOC"

if [ ! -f "$DOC" ]; then
  echo "RESULT: FAIL — communications-playbook-standard.md is MISSING."
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

# The hard mandatory-checklist headline (the §0 contract).
need "§0 mandatory-checklist headline" 'EVERY COMMUNICATION PLAYBOOK MUST INCLUDE ALL OF THE FOLLOWING'

# The nine mandatory inclusions (a)-(i).
need "(a) channel + persona / voice identity"        'persona ?/ ?voice identity|Channel \+ persona'
need "(b) opening behavior + how to greet"           'Opening behavior \+ how to greet|opening behavior|how the agent OPENS'
need "(c) conversation goal / desired outcome"        'Conversation goal / desired outcome|desired customer outcome'
need "(d) MANDATORY SEND rule (GHL Conversations API)" 'MANDATORY SEND rule'
need "(d) drafting is NOT sending"                    'rafting/composing is .?NOT.? sending|Drafting/composing is NOT sending|[Dd]rafting .?is.? NOT sending'
need "(d) mirror the inbound channel"                 'mirror'
need "(d) send by contactId / conversationId READ-only" 'contactId.*READ|READ key only|conversationId.*READ'
need "(e) conversation-memory READ-before + APPEND-after" 'READ that log BEFORE|onversation-MEMORY protocol|READ-before'
need "(f) escalation / handoff + honesty floor"       'Escalation / handoff rules \+ honesty floor|honesty floor'
need "(g) quiet-hours + compliance-keyword respect"   'Quiet-hours \+ compliance-keyword respect|quiet hours'
need "(h) ZHC- tag-prefix for programmatic tags"      'ZHC-'
need "(i) per-channel formatting constraints"         'Per-channel formatting constraints|per-channel formatting'

# The 8 channels the standard must name.
need "names the 8 channels (SMS / Email / Messenger / FB comments / IG DM / LinkedIn / Live Chat / All-in-One)" \
     'SMS, Email, Facebook Messenger, Facebook comments, Instagram DM,'

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — Communications Playbook Standard carries its §0 mandatory checklist and every required item."
  exit 0
else
  echo "RESULT: FAIL — the Communications Playbook Standard is missing a mandatory item (see above)."
  exit 1
fi
