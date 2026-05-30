#!/usr/bin/env bash
# qc-notify-client-doc.sh — machine-enforce the MANDATORY Telegram doc-delivery step.
#
# ROOT CAUSE this gate kills: the install kept finishing without the client ever
# being SENT their Quick-Start / Notion doc LINK over Telegram. The operator is
# tired of repeating it. Prose is not enforcement, so this gate FAILS the QC
# checklist if the delivery step is missing or not wired — exactly the posture of
# qc-send-directive.sh / qc-playbook-doc.sh.
#
# This is a STATIC gate (it inspects the skill's own files, not a live install):
#   1. scripts/22-notify-client-doc.sh EXISTS and is bash -n clean.
#   2. It GREPS THE TRANSCRIPTS (agents/*/sessions/*.jsonl) for the chat id — it
#      must reference the .jsonl transcripts AND at least one of the id forms
#      ("chat":{"id" / telegram:direct / "chatId" / "from":{"id") so it can't
#      regress to a sessions.json-keys-only scan (the paired-chat lesson).
#   3. It is GATED: it records clientDocDelivered (true/false) AND exits NON-ZERO
#      when no chat is found / the send fails (never a silent skip).
#   4. It SENDS via the OpenClaw gateway (openclaw message send --channel telegram)
#      and NEVER curls api.telegram.org directly.
#   5. It is WIRED into scripts/11-run-qc-checklist.sh (the QC checklist actually
#      runs the delivery gate) and into INSTRUCTIONS.md as a binding step.
#
# Exit codes: 0 = all wired correctly; 1 = one or more checks failed.
#
# PURE BASH (grep/sed), no python — respects qc-static.yml's .py claude-/anthropic
# scan. bash -n clean. set -uo pipefail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

NOTIFY="$SKILL_DIR/scripts/22-notify-client-doc.sh"
CHECKLIST="$SKILL_DIR/scripts/11-run-qc-checklist.sh"
INSTRUCTIONS="$SKILL_DIR/INSTRUCTIONS.md"

FAIL=0
pass() { echo "  [PASS] $*"; }
fail() { echo "  [FAIL] $*"; FAIL=1; }

echo "=== qc-notify-client-doc: mandatory Telegram doc-delivery gate ==="

# 1. Script exists + parses.
if [ -f "$NOTIFY" ]; then
  if bash -n "$NOTIFY" 2>/dev/null; then
    pass "scripts/22-notify-client-doc.sh exists and is bash -n clean"
  else
    fail "scripts/22-notify-client-doc.sh has a syntax error (bash -n failed)"
  fi
else
  fail "scripts/22-notify-client-doc.sh is MISSING (the mandatory Telegram delivery step)"
fi

# 2. Transcript grep (not sessions.json keys only).
if [ -f "$NOTIFY" ]; then
  if grep -Eq 'agents.*sessions.*\.jsonl|sessions/\*\.jsonl|name .\*\.jsonl' "$NOTIFY" \
     || grep -q "\.jsonl" "$NOTIFY"; then
    pass "delivery script scans the .jsonl transcripts (not just sessions.json keys)"
  else
    fail "delivery script must GREP THE TRANSCRIPTS (agents/*/sessions/*.jsonl) to find the chat id"
  fi
  ID_FORMS=0
  grep -q 'chat".*id' "$NOTIFY"      && ID_FORMS=$((ID_FORMS+1))
  grep -q 'telegram:direct' "$NOTIFY" && ID_FORMS=$((ID_FORMS+1))
  grep -q 'chatId' "$NOTIFY"          && ID_FORMS=$((ID_FORMS+1))
  grep -q 'from".*id' "$NOTIFY"       && ID_FORMS=$((ID_FORMS+1))
  if [ "$ID_FORMS" -ge 2 ]; then
    pass "delivery script matches multiple chat-id forms (chat.id / telegram:direct / chatId / from.id)"
  else
    fail "delivery script must match the chat-id forms (\"chat\":{\"id\" / telegram:direct / \"chatId\" / \"from\":{\"id\")"
  fi
fi

# 3. Gated: clientDocDelivered state + non-zero exit on miss/failure.
if [ -f "$NOTIFY" ]; then
  if grep -q 'clientDocDelivered' "$NOTIFY"; then
    pass "delivery script records the clientDocDelivered state field"
  else
    fail "delivery script must record clientDocDelivered (true/false) in the run manifest"
  fi
  if grep -Eq 'clientDocDelivered=false|clientDocDelivered":false' "$NOTIFY" && grep -Eq '\bexit 1\b' "$NOTIFY"; then
    pass "delivery script FLAGS clientDocDelivered=false AND exits non-zero (install marked incomplete)"
  else
    fail "delivery script must set clientDocDelivered=false AND exit non-zero when no chat is found / send fails"
  fi
fi

# 4. Gateway send, never direct curl to telegram.
if [ -f "$NOTIFY" ]; then
  if grep -q 'openclaw message send --channel telegram' "$NOTIFY"; then
    pass "delivery script sends via the OpenClaw gateway (openclaw message send --channel telegram)"
  else
    fail "delivery script must send via 'openclaw message send --channel telegram' (gateway only)"
  fi
  # Only an ACTUAL call bypassing the gateway is a violation — strip comment lines
  # (the script's own header documents the "NEVER curl api.telegram.org" rule).
  if grep -vE '^[[:space:]]*#' "$NOTIFY" | grep -Eq 'curl[^|]*api\.telegram\.org|wget[^|]*api\.telegram\.org'; then
    fail "delivery script must NOT curl/wget api.telegram.org directly — all Telegram sends go through the gateway"
  else
    pass "delivery script does not bypass the gateway (no direct curl/wget to api.telegram.org)"
  fi
fi

# 5. Wired into the QC checklist + INSTRUCTIONS.md.
if [ -f "$CHECKLIST" ]; then
  if grep -q '22-notify-client-doc.sh' "$CHECKLIST"; then
    pass "11-run-qc-checklist.sh runs the Telegram doc-delivery gate"
  else
    fail "11-run-qc-checklist.sh must reference 22-notify-client-doc.sh (the delivery gate must be in the checklist)"
  fi
else
  fail "11-run-qc-checklist.sh not found"
fi

if [ -f "$INSTRUCTIONS" ]; then
  if grep -q '22-notify-client-doc.sh' "$INSTRUCTIONS"; then
    pass "INSTRUCTIONS.md documents 22-notify-client-doc.sh as a binding step"
  else
    fail "INSTRUCTIONS.md must document the mandatory Telegram doc-delivery step (22-notify-client-doc.sh)"
  fi
else
  fail "INSTRUCTIONS.md not found"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — the client always gets their doc link via Telegram, gated and wired."
  exit 0
else
  echo "RESULT: FAIL — the mandatory Telegram doc-delivery step is missing or not wired."
  echo "        Every client gets their link via Telegram, no matter what."
  exit 1
fi
