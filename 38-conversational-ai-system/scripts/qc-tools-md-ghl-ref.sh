#!/usr/bin/env bash
# qc-tools-md-ghl-ref.sh — machine-enforce the GHL API quick-reference that
# scripts/24-update-tools-md.sh preloads into the CLIENT agent's TOOLS.md.
#
# WHAT THIS GUARDS (every condition below FAILs the gate):
#   1. Every listed OPERATION is present:
#        - messaging channel types: SMS, Email, FB, IG, Live_Chat (one /conversations/messages endpoint)
#        - calendars: list, get, create, free-slots
#        - appointments: book, reschedule, cancel
#        - invoices: send
#   1b. (v1.4.21) Corrected send/read shape — verified against GHL SendMessageBodyDto:
#        - channel-mirroring is documented (reply `type` mirrors the inbound channel; not hardcoded SMS)
#        - the send body uses contactId (GHL threads BY contactId)
#        - conversationId is NEVER on a send-shape line (it is the READ key only)
#        - the READ-thread-history path is present (GET /conversations/search + GET /conversations/<id>/messages)
#        - GMB is documented as inbound-only (not a valid send type)
#        - send `type`s use the short forms FB/IG/Live_Chat (no rejected long-forms Facebook/Instagram/Webchat)
#   2. Every required SCOPE is present:
#        conversations/message.write, conversations.readonly, calendars.readonly, calendars.write,
#        calendars/events.readonly, calendars/events.write, invoices.write
#   3. The canonical block stays CONCISE (size budget) so it does not bloat the core file.
#   4. NO personal/client identifier leaks in — only placeholders are allowed.
#
# TWO MODES:
#   (default)        scan references/ghl-api-quick-reference.md (the SOURCE that gets injected).
#                    This is what CI runs — it proves the injected block is complete/clean
#                    without needing a live install.
#   --tools-md FILE  scan the named client TOOLS.md: verify the marker block exists AND
#                    that the block content satisfies all the rules above. This is the LIVE
#                    post-install check.
#
# Pure BASH (respects the repo's ban on claude-/anthropic strings in .py).
# Exit 0 = clean; 1 = a rule failed; 3 = (live mode) TOOLS.md present but the marker block
#                                          is missing (install step was skipped).
#
# Usage:
#   bash scripts/qc-tools-md-ghl-ref.sh
#   bash scripts/qc-tools-md-ghl-ref.sh --ref-file references/ghl-api-quick-reference.md
#   bash scripts/qc-tools-md-ghl-ref.sh --tools-md /data/.openclaw/workspace/TOOLS.md

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REF_FILE="$SKILL_ROOT/references/ghl-api-quick-reference.md"
TOOLS_MD=""
MARKER="GHL_API_QUICK_REFERENCE"
# Concise size budget for the canonical block (lines). Keeps the core file lean;
# the current canonical reference is well under this. Bumping the budget is a
# deliberate decision, not a silent drift. v1.4.21: raised 160 -> 185 to fit the
# corrected MESSAGING section (channel-mirroring `type`, send body
# {type,contactId,locationId,message} with NO conversationId, GMB inbound-only
# note) + the new READ-thread-history block (GET /conversations/search + GET
# /conversations/<id>/messages, scope conversations.readonly). Still the fast
# canonical subset, not the whole API.
# F46 CRM-field fix: raised 185 -> 195 to fit the required new CUSTOM FIELDS
# section (GET + POST /locations/<id>/customFields, the dataType enum, the ZHC_
# create rule, Version 2021-07-28), kept to a 2-row table + one note. Same
# deliberate-bump rationale as the 160->185 change above.
MAX_LINES="${MAX_LINES:-195}"

while [ $# -gt 0 ]; do
  case "$1" in
    --ref-file)  REF_FILE="$2"; shift 2 ;;
    --tools-md)  TOOLS_MD="$2"; shift 2 ;;
    --max-lines) MAX_LINES="$2"; shift 2 ;;
    -h|--help)   sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

FAIL=0
report_fail() { echo "  [FAIL] $*"; FAIL=1; }
report_pass() { echo "  [PASS] $*"; }

# -----------------------------------------------------------------------------
# Pick the scan target + extract the block content into a temp file.
# -----------------------------------------------------------------------------
WORK="$(mktemp)"
trap 'rm -f "$WORK"' EXIT

if [ -n "$TOOLS_MD" ]; then
  echo "=== qc-tools-md-ghl-ref: LIVE mode — scanning $TOOLS_MD ==="
  if [ ! -f "$TOOLS_MD" ]; then
    report_fail "TOOLS.md not found: $TOOLS_MD"
    echo ""; echo "RESULT: FAIL"; exit 1
  fi
  if ! grep -q "<!-- BEGIN SKILL38: $MARKER -->" "$TOOLS_MD"; then
    echo "  [MISS] marker block '$MARKER' is absent — scripts/24-update-tools-md.sh was not run"
    echo ""
    echo "RESULT: SKIPPED-INCOMPLETE — TOOLS.md exists but the GHL quick-reference block is missing."
    echo "        Run scripts/24-update-tools-md.sh against this TOOLS.md, then re-check."
    exit 3
  fi
  # Extract just the marker block (exclusive of the marker lines themselves).
  awk -v b="<!-- BEGIN SKILL38: $MARKER -->" -v e="<!-- END SKILL38: $MARKER -->" '
    $0 ~ b {grab=1; next} $0 ~ e {grab=0} grab {print}' "$TOOLS_MD" > "$WORK"
else
  echo "=== qc-tools-md-ghl-ref: SOURCE mode — scanning $REF_FILE ==="
  if [ ! -f "$REF_FILE" ]; then
    report_fail "quick-reference source not found: $REF_FILE"
    echo ""; echo "RESULT: FAIL"; exit 1
  fi
  cp "$REF_FILE" "$WORK"
fi

# -----------------------------------------------------------------------------
# 1. Required OPERATIONS present.
# -----------------------------------------------------------------------------
echo ""
echo "-- operations --"

# need PATTERN LABEL — fixed-string (grep -F) presence check against the block.
need() {
  local pat="$1" label="$2"
  if grep -qF "$pat" "$WORK"; then
    report_pass "$label"
  else
    report_fail "missing operation/marker: $label  (expected to find: $pat)"
  fi
}

# Messaging — ONE endpoint, switch on type. Require the endpoint + each channel type.
need '/conversations/messages'            'messaging endpoint POST /conversations/messages'
need '"type":"SMS"'                        'messaging type SMS'
need '"type":"Email"'                      'messaging type Email'
need '"type":"FB"'                         'messaging type FB (Facebook Messenger)'
need '"type":"IG"'                         'messaging type IG (Instagram DM)'
need '"type":"Live_Chat"'                  'messaging type Live_Chat (Live Chat / Chat Widget)'
# All-in-One unified-inbox note must be documented.
if grep -qiE 'all-in-one|unified inbox' "$WORK"; then
  report_pass 'All-in-One / unified-inbox note present'
else
  report_fail 'missing the All-in-One / unified-inbox note (every channel = same endpoint, switch on type)'
fi

# v1.4.21 — corrected-send-shape invariants (verified against the GHL
# SendMessageBodyDto): the agent must MIRROR the inbound channel, SEND BY
# contactId (NOT conversationId), and read history via /conversations/search.
echo ""
echo "-- corrected send/read shape (v1.4.21) --"

# (a) channel-mirroring must be documented (reply on the inbound channel).
if grep -qiE 'mirror' "$WORK"; then
  report_pass 'channel-mirroring documented (reply on the inbound channel; do not hardcode SMS)'
else
  report_fail 'missing the channel-mirroring note (the reply `type` MUST mirror the inbound channel — not a hardcoded SMS)'
fi

# (b) the send body must use contactId.
if grep -qF 'contactId' "$WORK"; then
  report_pass 'send body uses contactId (GHL threads by contactId)'
else
  report_fail 'send body does not reference contactId (the send must be threaded BY contactId)'
fi

# (c) conversationId must NOT appear as a send-body field. It is the READ key only.
#     Guard: a send-shape JSON line is one that has BOTH "type": and "contactId"
#     on it; conversationId must never be on such a line.
if grep -E '"type":' "$WORK" | grep -qF 'conversationId'; then
  report_fail 'conversationId appears on a SEND-shape line ("type":… + conversationId) — the send body must NOT contain conversationId (it is the READ key only)'
else
  report_pass 'no conversationId on any send-shape line (send body is type/contactId/locationId/message)'
fi

# (d) conversationId MUST be documented as a READ key (the search→messages read path).
if grep -qF '/conversations/search' "$WORK" && grep -qiE 'conversationId' "$WORK"; then
  report_pass 'read-thread-history documented (GET /conversations/search + conversationId as the read key)'
else
  report_fail 'missing the read-thread-history path (GET /conversations/search to find the thread, then GET /conversations/<conversationId>/messages)'
fi

# (e) GMB documented as inbound-only (not a send type).
if grep -qiE 'gmb' "$WORK"; then
  report_pass 'GMB documented (inbound-only — not a valid send type)'
else
  report_fail 'missing the GMB inbound-only note (GMB cannot be replied to via the API send)'
fi

# (f) short-form send types only — the SEND-shape JSON lines must use FB/IG, never
#     the rejected long-forms "Facebook"/"Instagram"/"Webchat" as a send `type`.
if grep -E '"type":' "$WORK" | grep -qE '"type":"(Facebook|Instagram|Webchat)"'; then
  report_fail 'a SEND-shape line uses a rejected long-form type ("Facebook"/"Instagram"/"Webchat") — use the short forms FB/IG/Live_Chat'
else
  report_pass 'send `type`s use the short forms (FB/IG/Live_Chat) — no rejected long-forms'
fi

# Calendars
need '/calendars/?locationId'                                'calendars list (GET /calendars/?locationId=…)'
need '/calendars/<calendarId>'                                'calendars get (GET /calendars/<calendarId>)'
need 'POST /calendars/'                                       'calendars create (POST /calendars/)'
need '/free-slots'                                            'calendars free-slots'

# Appointments
need '/calendars/events/appointments'                        'appointment book (POST /calendars/events/appointments)'
need 'PUT /calendars/events/appointments/<eventId>'          'appointment reschedule (PUT …/<eventId>)'
need 'DELETE /calendars/events/<eventId>'                    'appointment cancel (DELETE /calendars/events/<eventId>)'

# Invoices
need '/invoices/<invoiceId>/send'                            'send invoice (POST /invoices/<invoiceId>/send)'
need 'POST /invoices/'                                        'create invoice (POST /invoices/)'

# -----------------------------------------------------------------------------
# 2. Required SCOPES present.
# -----------------------------------------------------------------------------
echo ""
echo "-- scopes --"
for scope in \
  'conversations/message.write' \
  'conversations.readonly' \
  'calendars.readonly' \
  'calendars.write' \
  'calendars/events.readonly' \
  'calendars/events.write' \
  'invoices.write'; do
  if grep -qF "$scope" "$WORK"; then
    report_pass "scope $scope"
  else
    report_fail "missing required scope: $scope"
  fi
done

# -----------------------------------------------------------------------------
# 3. Concise size budget (avoid core-file bloat).
# -----------------------------------------------------------------------------
echo ""
echo "-- size budget --"
LINES="$(wc -l < "$WORK" | tr -d '[:space:]')"
if [ "$LINES" -le "$MAX_LINES" ]; then
  report_pass "block is concise: $LINES lines (budget $MAX_LINES)"
else
  report_fail "block too large: $LINES lines exceeds the $MAX_LINES-line concise budget (this is the canonical fast subset, not the whole API)"
fi

# -----------------------------------------------------------------------------
# 4. ZERO personal/client identifier leakage — only placeholders allowed.
# -----------------------------------------------------------------------------
echo ""
echo "-- no personal/client data --"
LEAK=0
leak() { echo "      ↳ $*"; LEAK=1; }

# Real bearer tokens / PITs (GHL PITs look like pit-<uuid> or eyJ… JWTs). The block
# must reference the ENV VAR ($GHL_PRIVATE_INTEGRATION_TOKEN / <PRIVATE_INTEGRATION_TOKEN>),
# never a literal token value.
if grep -qE 'Bearer[[:space:]]+(pit-[0-9a-fA-F-]{8,}|eyJ[A-Za-z0-9_-]{10,})' "$WORK"; then
  leak "a literal Bearer token (pit-… / JWT) is present — use \$GHL_PRIVATE_INTEGRATION_TOKEN"
fi
# Email addresses (placeholders like <CONTACT_ID> have no @). Allow none.
if grep -qiE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$WORK"; then
  leak "an email address is present — the block must be universal (no client emails)"
fi
# Phone numbers (E.164-ish: a +<10+ digits> run). Placeholders use <…>, not digits.
if grep -qE '\+[0-9]{10,15}' "$WORK"; then
  leak "a phone number is present — the block must be universal (no client phone numbers)"
fi
# Real GHL location/contact ids are 20+ char alnum tokens. The block must use
# placeholders (<LOCATION_ID>, <CONTACT_ID>, <CAL_ID>, <eventId>, <invoiceId>) — never a
# concrete id. Flag any standalone 20+ char alphanumeric run.
if grep -qE '(^|[^A-Za-z0-9_<>])[A-Za-z0-9]{20,}([^A-Za-z0-9_>]|$)' "$WORK"; then
  leak "a 20+ char alphanumeric token (looks like a real GHL location/contact id) is present — use placeholders"
fi

if [ "$LEAK" -eq 0 ]; then
  report_pass "no client identifiers (tokens / emails / phones / real ids) — placeholders only"
else
  report_fail "personal/client identifier(s) detected in the block (see ↳ above) — the block MUST be universal"
fi

# -----------------------------------------------------------------------------
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — GHL API quick-reference block is complete (all operations + scopes), concise ($LINES lines), and contains zero personal/client data."
  exit 0
else
  echo "RESULT: FAIL — the GHL API quick-reference block is incomplete, oversized, or leaks client data. See [FAIL] above."
  exit 1
fi
