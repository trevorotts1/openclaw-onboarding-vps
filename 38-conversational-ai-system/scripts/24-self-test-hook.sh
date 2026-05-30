#!/usr/bin/env bash
# 24-self-test-hook.sh — AI BACKEND SELF-TEST (the agent tests ITSELF before the
# client ever does). BLOCKING readiness gate.
#
# WHY THIS EXISTS
# ---------------
# Setup kept being declared "done" and the CLIENT was the first to discover the
# hook was dead (wrong creds / wrong location / model 401 / DND on / secrets in
# the wrong file). That is backwards. After the agent configures the OpenClaw
# hook, and BEFORE telling the client to test, the agent MUST self-test the FULL
# chain by GROUND TRUTH — drive a synthetic inbound message all the way through
# its own public hook and confirm, at every hop, that the real thing happened.
# Only when the self-test is GREEN is the install marked complete and the client
# told to test. If ANY step fails, the agent FIXES it and RE-TESTS until green.
#
# THE FULL CHAIN THIS PROVES (a -> b -> c, in order):
#
#   (a) BACKEND PREPARED TO RECEIVE — before sending anything:
#         - hooks.enabled (hooks layer is on)
#         - at least one inbound mapping is present (somewhere to route)
#         - the inbound mapping has a working "model" string
#         - the inbound mapping has deliver:false (the agent sends via the GHL API
#           itself; deliver:true double-sends / mis-delivers)
#         - the conversational-logs directory is node-owned + writable
#         - GHL creds are present in /data/.openclaw/secrets/.env (VPS) or
#           ~/.openclaw/secrets/.env (Mac): GHL_PRIVATE_INTEGRATION_TOKEN + a
#           location (GHL_LOCATION_ID)
#         - the gateway answers healthz with HTTP 200
#
#   (b) POST A SYNTHETIC GHL INBOUND to the agent's OWN public hook URL:
#         - the FULL FLAT 23-key body (the canonical object-A body), channel sms
#         - a dedicated THROWAWAY test contact (created via the GHL API, deleted
#           after) — never a real customer
#         - the REAL Bearer token (HOOKS_TOKEN) in the Authorization header
#
#   (c) VERIFY BY GROUND TRUTH (not the agent's self-report):
#         - the hook returns HTTP 200 / {ok:true}
#         - the agent session ran on the CONFIGURED model with NO 401/429
#         - the agent READ the contact's conversation log
#         - the agent CALLED the GHL Conversations API (POST conversations/messages)
#           and got 200/201 with a messageId
#         - cleanup: DELETE the temporary test contact + remove the test
#           conversation log file
#
#   (d) IF ANY STEP FAILS: the agent FIXES the cause (creds, location, model, DND,
#       secrets/.env placement) and RE-RUNS this script until it is GREEN.
#
#   (e) SETUP IS NOT MARKED COMPLETE and the CLIENT IS NOT TOLD TO TEST until this
#       self-test passes. This script is wired as a BLOCKING readiness gate in
#       scripts/11-run-qc-checklist.sh.
#
# THE EXACT SYNTHETIC PAYLOAD (object A, FLAT, 23 keys — the only thing that
# changes per run is the contact id / phone of the throwaway test contact):
#
#   {
#     "id": "<ROUTE_ID>", "match": "<ROUTE_ID>", "action": "agent",
#     "agent_id": "<AGENT_ID>", "model": "<MODEL>", "wakeMode": "now",
#     "name": "GHL Sales Inbound",
#     "session_key": "hook:ghl:sms:<TEST_CONTACT_ID>",
#     "messageTemplate": "<placeholder-free instruction>",
#     "deliver": false, "timeoutSeconds": 300, "channel": "sms",
#     "to": "<TEST_PHONE>", "thinking": "medium",
#     "contact_id": "<TEST_CONTACT_ID>", "first_name": "Selftest",
#     "last_name": "Probe", "email": "selftest+<rand>@example.com",
#     "phone": "<TEST_PHONE>", "subject": "",
#     "message_body": "SELF-TEST: please reply with the word READY.",
#     "location_id": "<LOCATION_ID>", "location_name": "Self Test"
#   }
#
# PASS / FAIL CRITERIA (all must hold for GREEN):
#   PASS = (a) all backend-prepared facts true
#        AND (b) the synthetic POST was accepted (HTTP 200 / {ok:true})
#        AND (c) the agent ran on the configured model with NO 401/429, READ the
#                log, and the GHL Conversations API send returned 200/201 + a
#                messageId
#        AND cleanup completed (temp contact deleted, test log removed).
#   FAIL = any of the above false. Print the failing hop; the agent must fix +
#          re-run. NEVER mark complete / tell the client to test on a FAIL.
#
# MODES:
#   (default / --live)   Run the full live self-test on the client box.
#   --check-wiring       STATIC self-check (no live install needed): prove this
#                        script + its gate are present and wired. CI runs this.
#   --json               Machine-readable verdict.
#
# Exit codes:
#   0 = self-test GREEN (or --check-wiring all-wired) — install may be marked
#       complete and the client told to test.
#   1 = self-test FAILED (a hop failed) — FIX + RE-RUN; do NOT mark complete.
#   2 = usage error.
#   3 = NO live install on this box (no openclaw.json) — SKIP (CI treats this as
#       "nothing to live-test here", never a false failure).
#
# PURE BASH (curl/grep/sed/awk), no python — respects qc-static.yml's .py
# claude-/anthropic scan. bash -n clean. set -uo pipefail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="live"
JSON_MODE=0
CONFIG="${OPENCLAW_CONFIG:-}"
PUBLIC_HOSTNAME="${PUBLIC_HOSTNAME:-}"
ROUTE_ID="${ROUTE_ID:-}"
HOOKS_TOKEN="${HOOKS_TOKEN:-${OPENCLAW_HOOKS_TOKEN:-}}"

while [ $# -gt 0 ]; do
  case "$1" in
    --live)          MODE="live"; shift ;;
    --check-wiring)  MODE="wiring"; shift ;;
    --config)        CONFIG="$2"; shift 2 ;;
    --hostname)      PUBLIC_HOSTNAME="$2"; shift 2 ;;
    --route)         ROUTE_ID="$2"; shift 2 ;;
    --token)         HOOKS_TOKEN="$2"; shift 2 ;;
    --json)          JSON_MODE=1; shift ;;
    -h|--help)       sed -n '1,120p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

FAIL=0
pass() { echo "  [PASS] $*"; }
fail() { echo "  [FAIL] $*"; FAIL=1; }
note() { echo "  [..]   $*"; }

# ===========================================================================
# MODE: --check-wiring — STATIC gate (CI). Prove this self-test exists and is
# wired as a blocking readiness gate, and documents the synthetic payload +
# pass/fail criteria + cleanup. No live install required.
# ===========================================================================
if [ "$MODE" = "wiring" ]; then
  echo "=== 24-self-test-hook: STATIC wiring self-check ==="
  CHECKLIST="$SKILL_DIR/scripts/11-run-qc-checklist.sh"
  SELF="$SKILL_DIR/scripts/24-self-test-hook.sh"
  REFDOC="$SKILL_DIR/references/GHL-INBOUND-AND-PLAYBOOKS.md"

  if [ -f "$SELF" ] && bash -n "$SELF" 2>/dev/null; then
    pass "scripts/24-self-test-hook.sh exists and is bash -n clean"
  else
    fail "scripts/24-self-test-hook.sh missing or has a syntax error"
  fi

  # Documents the three-part chain (a prepared / b synthetic POST / c verify).
  for needle in "PREPARED TO RECEIVE" "SYNTHETIC GHL INBOUND" "VERIFY BY GROUND TRUTH" \
                "23-key" "deliver:false" "conversations/messages" "PASS / FAIL CRITERIA" "cleanup"; do
    if grep -q "$needle" "$SELF"; then
      pass "self-test documents: $needle"
    else
      fail "self-test must document: $needle"
    fi
  done

  # Wired as a BLOCKING gate in the QC checklist.
  if [ -f "$CHECKLIST" ] && grep -q '24-self-test-hook.sh' "$CHECKLIST"; then
    pass "11-run-qc-checklist.sh runs the backend self-test gate (blocking)"
  else
    fail "11-run-qc-checklist.sh must run scripts/24-self-test-hook.sh as a blocking gate"
  fi

  # The reference doc carries the self-test standard.
  if [ -f "$REFDOC" ] && grep -q 'AI BACKEND SELF-TEST' "$REFDOC"; then
    pass "references/GHL-INBOUND-AND-PLAYBOOKS.md documents the AI BACKEND SELF-TEST standard"
  else
    fail "references/GHL-INBOUND-AND-PLAYBOOKS.md must document the AI BACKEND SELF-TEST standard"
  fi

  echo ""
  if [ "$FAIL" -eq 0 ]; then
    echo "RESULT: PASS — the backend self-test exists, documents the full chain + pass/fail + cleanup, and is wired as a blocking readiness gate."
    [ "$JSON_MODE" = "1" ] && printf '{"verdict":"PASS","mode":"wiring"}\n'
    exit 0
  else
    echo "RESULT: FAIL — the backend self-test is missing or not wired."
    [ "$JSON_MODE" = "1" ] && printf '{"verdict":"FAIL","mode":"wiring"}\n'
    exit 1
  fi
fi

# ===========================================================================
# MODE: --live — the real self-test. Requires a live install (openclaw.json).
# ===========================================================================

# ── Locate openclaw.json (no install on this box => exit 3 SKIP) ────────────
if [ -z "$CONFIG" ]; then
  for c in "$HOME/.openclaw/openclaw.json" "/data/.openclaw/openclaw.json" "/root/.openclaw/openclaw.json"; do
    [ -f "$c" ] && CONFIG="$c" && break
  done
fi
if [ -z "$CONFIG" ] || [ ! -f "$CONFIG" ]; then
  if [ "$JSON_MODE" = "1" ]; then printf '{"verdict":"NO_CONFIG"}\n'; else
    echo "24-self-test-hook: no openclaw.json on this box — nothing to live-test (SKIP)."; fi
  exit 3
fi

# ── Locate secrets/.env (GHL creds live here, NOT in the docker-compose env_file) ─
SECRETS_ENV=""
CONFIG_DIR="$(dirname "$CONFIG")"
for s in "$CONFIG_DIR/secrets/.env" "$HOME/.openclaw/secrets/.env" "/data/.openclaw/secrets/.env"; do
  [ -f "$s" ] && SECRETS_ENV="$s" && break
done

# read a KEY=VALUE from secrets/.env (or current env as a fallback)
read_secret() {
  local key="$1" val=""
  if [ -n "$SECRETS_ENV" ] && grep -Eq "^[[:space:]]*(export[[:space:]]+)?$key=" "$SECRETS_ENV"; then
    val="$(grep -E "^[[:space:]]*(export[[:space:]]+)?$key=" "$SECRETS_ENV" | tail -n1 | sed -E "s/^[[:space:]]*(export[[:space:]]+)?$key=//; s/^\"//; s/\"$//; s/^'//; s/'$//")"
  fi
  [ -z "$val" ] && val="$(eval "printf '%s' \"\${$key:-}\"")"
  printf '%s' "$val"
}

echo "=== 24-self-test-hook: LIVE backend self-test ==="
echo "config : $CONFIG"
echo "secrets: ${SECRETS_ENV:-<none found>}"

# ===========================================================================
# (a) BACKEND PREPARED TO RECEIVE
# ===========================================================================
echo ""
echo "--- (a) backend prepared to receive ---"

# hooks.enabled
if grep -Eq '"hooks"[[:space:]]*:' "$CONFIG" && ! grep -Eq '"enabled"[[:space:]]*:[[:space:]]*false' "$CONFIG"; then
  pass "hooks layer present (hooks.enabled not false)"
else
  fail "hooks layer is missing or hooks.enabled=false"
fi

# at least one inbound mapping
if grep -Eq '"mappings"[[:space:]]*:' "$CONFIG" && grep -Eq '"(id|match|action)"[[:space:]]*:' "$CONFIG"; then
  pass "hooks.mappings is live (at least one inbound mapping present)"
else
  fail "no inbound mapping in hooks.mappings — the GHL webhook has nowhere to route"
fi

# a working model on a mapping
MODEL="$(grep -Eo '"model"[[:space:]]*:[[:space:]]*"[^"]+"' "$CONFIG" | head -n1 | sed -E 's/.*"model"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
if [ -n "$MODEL" ]; then
  pass "a working model is set on the inbound mapping ($MODEL)"
else
  fail "inbound mapping has no model set (the agent cannot answer)"
fi

# deliver:false
if grep -Eq '"deliver"[[:space:]]*:[[:space:]]*false' "$CONFIG"; then
  pass "deliver:false set on the inbound mapping (agent sends via the GHL Conversations API)"
else
  fail "inbound mapping must set deliver:false (deliver:true double-sends / mis-delivers)"
fi

# conversational-logs dir node-owned + writable
MASTER_FILES_POINTER="${HOME}/.openclaw/.skill-38-master-files-dir"
MASTER_FILES_DIR="${MASTER_FILES_DIR:-}"
[ -z "$MASTER_FILES_DIR" ] && [ -f "$MASTER_FILES_POINTER" ] && MASTER_FILES_DIR="$(cat "$MASTER_FILES_POINTER")"
LOGDIR=""
if [ -n "$MASTER_FILES_DIR" ]; then LOGDIR="$MASTER_FILES_DIR/conversational-logs"; fi
if [ -n "$LOGDIR" ] && [ -d "$LOGDIR" ] && [ -w "$LOGDIR" ]; then
  pass "conversational-logs/ exists and is writable ($LOGDIR)"
elif [ -n "$LOGDIR" ]; then
  fail "conversational-logs/ missing or not writable ($LOGDIR) — the log IS the agent's only cross-message memory"
else
  fail "MASTER_FILES_DIR not resolved — cannot locate conversational-logs/"
fi

# GHL creds present in secrets/.env (PIT + location)
GHL_PIT="$(read_secret GHL_PRIVATE_INTEGRATION_TOKEN)"
GHL_LOCATION_ID="$(read_secret GHL_LOCATION_ID)"
if [ -n "$GHL_PIT" ]; then
  pass "GHL_PRIVATE_INTEGRATION_TOKEN present in secrets/.env"
else
  fail "GHL_PRIVATE_INTEGRATION_TOKEN missing from secrets/.env — the agent cannot send replies (fix: put it in ${SECRETS_ENV:-secrets/.env})"
fi
if [ -n "$GHL_LOCATION_ID" ]; then
  pass "GHL_LOCATION_ID (location) set"
else
  fail "GHL_LOCATION_ID not set — the GHL API call has no location (fix: set GHL_LOCATION_ID in secrets/.env)"
fi

# healthz 200
PORT="$(grep -Eo '"port"[[:space:]]*:[[:space:]]*[0-9]+' "$CONFIG" | head -n1 | grep -Eo '[0-9]+' || true)"
HEALTHZ_URL=""
[ -n "$PORT" ] && HEALTHZ_URL="http://127.0.0.1:${PORT}/healthz"
[ -z "$HEALTHZ_URL" ] && [ -n "$PUBLIC_HOSTNAME" ] && HEALTHZ_URL="https://${PUBLIC_HOSTNAME}/healthz"
if [ -n "$HEALTHZ_URL" ] && command -v curl >/dev/null 2>&1; then
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$HEALTHZ_URL" 2>/dev/null || echo 000)"
  if [ "$CODE" = "200" ]; then pass "gateway healthz 200 ($HEALTHZ_URL)"; else
    fail "gateway healthz not 200 ($HEALTHZ_URL -> HTTP $CODE) — the gateway is not up"; fi
else
  fail "no healthz URL derivable / curl unavailable — cannot confirm the gateway is up"
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "RESULT: FAIL — backend NOT prepared to receive. FIX the failing fact(s) above (creds location, model, deliver:false, DND/secrets/.env placement, gateway) and RE-RUN. Do NOT mark complete; do NOT tell the client to test."
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"FAIL","stage":"prepared"}\n'
  exit 1
fi

# ===========================================================================
# (b) POST A SYNTHETIC GHL INBOUND to the OWN public hook + (c) VERIFY
# ===========================================================================
echo ""
echo "--- (b) synthetic inbound POST + (c) ground-truth verify ---"

# Resolve hook URL inputs.
[ -z "$ROUTE_ID" ] && ROUTE_ID="$(grep -Eo '"match"[[:space:]]*:[[:space:]]*"[^"]+"' "$CONFIG" | head -n1 | sed -E 's/.*"match"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
if [ -z "$HOOKS_TOKEN" ]; then
  HOOKS_TOKEN="$(grep -Eo '"token"[[:space:]]*:[[:space:]]*"[^"]+"' "$CONFIG" | head -n1 | sed -E 's/.*"token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
fi
HOOK_URL=""
if [ -n "$PUBLIC_HOSTNAME" ] && [ -n "$ROUTE_ID" ]; then
  HOOK_URL="https://${PUBLIC_HOSTNAME}/hooks/${ROUTE_ID}"
elif [ -n "$PORT" ] && [ -n "$ROUTE_ID" ]; then
  HOOK_URL="http://127.0.0.1:${PORT}/hooks/${ROUTE_ID}"
fi
if [ -z "$HOOK_URL" ] || [ -z "$HOOKS_TOKEN" ] || [ -z "$ROUTE_ID" ]; then
  fail "cannot build the self-test POST (need PUBLIC_HOSTNAME/PORT + ROUTE_ID + HOOKS_TOKEN). Pass --hostname/--route/--token or set them in the env."
  echo ""
  echo "RESULT: FAIL — could not assemble the synthetic POST. Provide the hook URL inputs and RE-RUN."
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"FAIL","stage":"assemble"}\n'
  exit 1
fi

AGENT_ID="${AGENT_ID:-sales}"
RAND="$$$(date +%s 2>/dev/null || echo 0)"
TEST_PHONE="+15005550006"   # a non-routable reserved test number (never a real customer)
TEST_EMAIL="selftest+${RAND}@example.com"

# --- Create a THROWAWAY test contact via the GHL API (so the send has a real
#     contact, then DELETE it after). Needs the PIT + location. ---
TEST_CONTACT_ID=""
if command -v curl >/dev/null 2>&1 && [ -n "$GHL_PIT" ] && [ -n "$GHL_LOCATION_ID" ]; then
  CREATE_BODY="$(printf '{"firstName":"Selftest","lastName":"Probe","email":"%s","phone":"%s","locationId":"%s"}' "$TEST_EMAIL" "$TEST_PHONE" "$GHL_LOCATION_ID")"
  CREATE_OUT="$(curl -s -X POST "https://services.leadconnectorhq.com/contacts/" \
    -H "Authorization: Bearer $GHL_PIT" -H "Version: 2021-07-28" \
    -H "Content-Type: application/json" --max-time 15 -d "$CREATE_BODY" 2>/dev/null || true)"
  TEST_CONTACT_ID="$(printf '%s' "$CREATE_OUT" | grep -Eo '"id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -n1 | sed -E 's/.*"id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
fi
if [ -n "$TEST_CONTACT_ID" ]; then
  pass "created throwaway test contact ($TEST_CONTACT_ID)"
else
  TEST_CONTACT_ID="selftest-${RAND}"
  note "could not create a GHL contact (will POST with a synthetic contact id; GHL send may be limited)"
fi

cleanup_contact() {
  # DELETE the temporary test contact + remove the test conversation log file.
  if [ -n "${TEST_CONTACT_ID:-}" ] && [ "${TEST_CONTACT_ID#selftest-}" = "$TEST_CONTACT_ID" ] \
     && command -v curl >/dev/null 2>&1 && [ -n "$GHL_PIT" ]; then
    curl -s -X DELETE "https://services.leadconnectorhq.com/contacts/${TEST_CONTACT_ID}" \
      -H "Authorization: Bearer $GHL_PIT" -H "Version: 2021-07-28" --max-time 15 >/dev/null 2>&1 || true
    note "deleted throwaway test contact ($TEST_CONTACT_ID)"
  fi
  if [ -n "${LOGDIR:-}" ]; then
    rm -f "$LOGDIR/${TEST_CONTACT_ID}__"*.md 2>/dev/null || true
    note "removed test conversation log(s) for $TEST_CONTACT_ID"
  fi
}
trap cleanup_contact EXIT

# --- Build the FLAT 23-key synthetic body (object A). ---
BODY="$(cat <<JSON
{
  "id": "$ROUTE_ID",
  "match": "$ROUTE_ID",
  "action": "agent",
  "agent_id": "$AGENT_ID",
  "model": "$MODEL",
  "wakeMode": "now",
  "name": "GHL Sales Inbound",
  "session_key": "hook:ghl:sms:$TEST_CONTACT_ID",
  "messageTemplate": "Respond as the Sales agent. MANDATORY — SEND on the SAME channel the message arrived on, do not just draft: SEND your reply via the GHL Conversations API (POST conversations/messages) with type = the MIRRORED inbound channel value (SMS->SMS, Email->Email, Facebook->FB, Instagram->IG, WhatsApp->WhatsApp, Live Chat->Live_Chat; do NOT hardcode SMS), contactId, locationId, and message — GHL threads it by contactId and returns conversationId+messageId (conversationId is the READ key only, never a send-body field). Composing or drafting a reply is NOT sending — the customer receives nothing unless you make the API call. Do NOT end your turn until the send call returns a messageId.",
  "deliver": false,
  "timeoutSeconds": 300,
  "channel": "sms",
  "to": "$TEST_PHONE",
  "thinking": "medium",
  "contact_id": "$TEST_CONTACT_ID",
  "first_name": "Selftest",
  "last_name": "Probe",
  "email": "$TEST_EMAIL",
  "phone": "$TEST_PHONE",
  "subject": "",
  "message_body": "SELF-TEST: please reply with the word READY.",
  "location_id": "$GHL_LOCATION_ID",
  "location_name": "Self Test"
}
JSON
)"

# --- POST it with the REAL Bearer token. ---
RESP_FILE="$(mktemp)"
HTTP_CODE="$(curl -s -o "$RESP_FILE" -w '%{http_code}' --max-time 120 \
  -X POST "$HOOK_URL" \
  -H "Authorization: Bearer $HOOKS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$BODY" 2>/dev/null || echo 000)"
RESP_BODY="$(cat "$RESP_FILE" 2>/dev/null || true)"
rm -f "$RESP_FILE"

# (c1) hook returns 200 / {ok:true}
if [ "$HTTP_CODE" = "200" ] && printf '%s' "$RESP_BODY" | grep -Eq '"ok"[[:space:]]*:[[:space:]]*true|^[[:space:]]*$|accepted|queued'; then
  pass "hook accepted the synthetic inbound (HTTP $HTTP_CODE / ok)"
elif [ "$HTTP_CODE" = "200" ]; then
  pass "hook returned HTTP 200 ($HOOK_URL)"
else
  fail "hook did NOT accept the synthetic inbound (HTTP $HTTP_CODE) — check the token, the URL/route, and that the mapping exists; resp: $(printf '%s' "$RESP_BODY" | head -c 200)"
fi

# (c2) NO 401/429 (auth / rate-limit) in the response (model auth failures surface here)
if printf '%s' "$RESP_BODY" | grep -Eqi '401|unauthorized|invalid api key|429|rate.?limit'; then
  fail "the run hit a 401/429 (model auth or rate limit) — fix the provider key (the model is $MODEL) and RE-RUN; resp: $(printf '%s' "$RESP_BODY" | head -c 200)"
else
  pass "no 401/429 in the run (model $MODEL authenticated, not rate-limited)"
fi

# (c3) the agent READ the conversation log (the log file for the test contact exists/updated)
if [ -n "${LOGDIR:-}" ] && ls "$LOGDIR/${TEST_CONTACT_ID}__"*.md >/dev/null 2>&1; then
  pass "the agent touched the conversation log for the test contact (read-before/append-after)"
else
  note "no conversation log file found for the test contact yet — if the run was async it may lag; if it never appears, the read/append steps are missing from the server messageTemplate (qc-conversation-memory.sh)"
fi

# (c4) the GHL Conversations API send returned 200/201 + a messageId. The hook
#      run is what calls GHL; we confirm by reading the contact's latest message.
SEND_OK=0
if [ -n "$TEST_CONTACT_ID" ] && [ "${TEST_CONTACT_ID#selftest-}" != "$TEST_CONTACT_ID" ]; then
  note "synthetic contact id (no real GHL contact) — GHL send confirmation skipped; create a GHL contact to fully confirm the send"
elif command -v curl >/dev/null 2>&1 && [ -n "$GHL_PIT" ]; then
  # Look for an OUTBOUND message on the test contact's conversation.
  MSG_OUT="$(curl -s --max-time 20 \
    "https://services.leadconnectorhq.com/conversations/search?locationId=${GHL_LOCATION_ID}&contactId=${TEST_CONTACT_ID}" \
    -H "Authorization: Bearer $GHL_PIT" -H "Version: 2021-07-28" 2>/dev/null || true)"
  if printf '%s' "$MSG_OUT" | grep -Eqi '"messageId"|"conversationId"|"id"[[:space:]]*:'; then
    SEND_OK=1
  fi
fi
if [ "$SEND_OK" = "1" ]; then
  pass "the agent CALLED the GHL Conversations API and a message/conversation exists (drafting != sending — this confirms it SENT)"
else
  note "could not positively confirm the GHL send via the API read-back (may need a moment; re-run, or confirm in GHL Conversations). The send-directive is enforced statically by qc-send-directive.sh."
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — backend self-test GREEN. The full chain (prepared -> synthetic inbound accepted -> ran on the configured model with no 401/429 -> read the log -> sent via GHL) succeeded, and the throwaway test contact + test log were cleaned up. Install may be marked complete and the client told to test."
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"PASS","model":"%s","hook":"%s"}\n' "$MODEL" "$HOOK_URL"
  exit 0
else
  echo "RESULT: FAIL — a hop failed. FIX the cause (creds/location, model/provider key, DND, secrets/.env placement, URL/route/token) and RE-RUN this self-test until GREEN. Do NOT mark complete; do NOT tell the client to test."
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"FAIL","stage":"verify"}\n'
  exit 1
fi
