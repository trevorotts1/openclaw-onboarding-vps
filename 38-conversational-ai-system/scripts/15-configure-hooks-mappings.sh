#!/usr/bin/env bash
# 15-configure-hooks-mappings.sh
# Step 3 (hooks.mappings) + Step 3.5 (Model Selection Wizard) + Step 4 (E2E test).
# Playbook v5.14 lines 1089-1395. Idempotent.
set -euo pipefail

SECRETS_ENV_FILE="${SECRETS_ENV_FILE:-$HOME/.openclaw/secrets.env}"
CONFIG_FILE="${CONFIG_FILE:-$HOME/.openclaw/openclaw.json}"
GATEWAY_PORT="${GATEWAY_PORT:-18789}"

[[ -f "$SECRETS_ENV_FILE" ]] && set -a && . "$SECRETS_ENV_FILE" && set +a || true
[[ -f "$CONFIG_FILE" ]] || { echo "openclaw config not found: $CONFIG_FILE" >&2; exit 2; }

: "${ROUTE_ID:?ROUTE_ID missing — set in env or in secrets.env}"
: "${PUBLIC_HOSTNAME:?PUBLIC_HOSTNAME missing — run 13-create-cloudflare-tunnel.sh first}"
# NOTE: the GHL Raw Body is FLAT and MUST contain all 23 keys (23 = minimum, no stripped/short bodies;
# its messageTemplate value is placeholder-free) — see references/GHL-INBOUND-AND-PLAYBOOKS.md §14.
# The SERVER mapping below references the FLAT body key names ({{session_key}}, {{contact_id}}, {{message_body}}).
SESSION_KEY="${SESSION_KEY:-{{session_key}}}"

command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 3; }

append_secret() {
  local k="$1" v="$2"
  [[ -f "$SECRETS_ENV_FILE" ]] || { mkdir -p "$(dirname "$SECRETS_ENV_FILE")"; : > "$SECRETS_ENV_FILE"; chmod 600 "$SECRETS_ENV_FILE"; }
  if grep -qE "^${k}=" "$SECRETS_ENV_FILE" 2>/dev/null; then return 0; fi
  printf '%s=%s\n' "$k" "$v" >> "$SECRETS_ENV_FILE"
}

backup_config() {
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.${ts}"
  echo "config backup: ${CONFIG_FILE}.bak.${ts}" >&2
}

write_config() {
  local new="$1"
  echo "$new" | jq '.' > "${CONFIG_FILE}.tmp"
  mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

# =============================================================================
# STEP 3 — hooks.mappings (idempotent)
# =============================================================================
echo "==> Step 3: hooks.mappings for route_id=$ROUTE_ID" >&2

# Generate / reuse HOOKS_TOKEN
if [[ -z "${HOOKS_TOKEN:-}" ]]; then
  HOOKS_TOKEN="$(openssl rand -base64 32 | tr -d '\n=' | head -c 43)"
  append_secret "HOOKS_TOKEN" "$HOOKS_TOKEN"
  echo "generated HOOKS_TOKEN (length=${#HOOKS_TOKEN})" >&2
else
  echo "reusing existing HOOKS_TOKEN" >&2
fi

# Refuse to reuse gateway token
GATEWAY_TOKEN="$(jq -r '.gateway.auth.token // empty' "$CONFIG_FILE" 2>/dev/null || true)"
if [[ -n "$GATEWAY_TOKEN" && "$GATEWAY_TOKEN" == "$HOOKS_TOKEN" ]]; then
  echo "HOOKS_TOKEN equals gateway.auth.token — refused (per OpenClaw config-reference)." >&2
  exit 4
fi

# Is a mapping with this id already in place?
HAS_MAPPING="$(jq --arg id "$ROUTE_ID" '.hooks.mappings? // [] | map(.id == $id) | any' "$CONFIG_FILE")"

if [[ "$HAS_MAPPING" == "true" ]]; then
  echo "hooks.mappings entry id=$ROUTE_ID already present — skipping merge" >&2
else
  backup_config
  ROUTING_AGENT_ID="${ROUTING_AGENT_ID:-main}"
  NEW_MAPPING="$(jq -n \
    --arg id "$ROUTE_ID" \
    --arg path "$ROUTE_ID" \
    --arg agent "$ROUTING_AGENT_ID" \
    --arg sk "$SESSION_KEY" \
    '{
      id:$id, match:{path:$path}, action:"agent", agentId:$agent,
      wakeMode:"now", name:"GHL Inbound", sessionKey:$sk,
      messageTemplate:"INBOUND MESSAGE FROM GOHIGHLEVEL — {{channel}} channel From: {{first_name}} {{last_name}} Phone: {{phone}} Email: {{email}} Contact ID: {{contact_id}} Location ID: {{location_id}} Location name: {{location_name}} Customer message subject: {{subject}} Customer message body: {{message_body}} MEMORY — READ FIRST (this is a SINGLE-TURN hook session; your only memory of this contact is the conversation log file): BEFORE drafting anything, read this contact'\''s conversation log at <MASTER_FILES_DIR>/conversational-logs/{{contact_id}}__<name>.md for the full prior conversation and any in-progress booking/topic; if the file is missing, treat this as a new contact. CONTINUE: reply continuing any in-progress topic/booking found in the log — do not restart or re-ask what the log already answered. MANDATORY — SEND, do not just draft: You MUST send your reply by calling the GHL Conversations API (POST conversations/messages) for contact {{contact_id}} on the {{channel}} channel, per TOOLS.md (use your installed GHL skill, typically skill #50s). Composing or drafting a reply is NOT sending — the customer receives nothing unless you make the API call. Do NOT end your turn until the send call returns a messageId/conversationId. APPEND — LOG AFTER SENDING: append this inbound message AND your sent reply to <MASTER_FILES_DIR>/conversational-logs/{{contact_id}}__<name>.md (create the file if missing) per the conversation-log protocol — a reply that fails to update the log is a failure (see AGENTS.md for the full conversation-memory protocol).",
      deliver:false, timeoutSeconds:300
    }')"

  # Fail-closed guard: refuse to write a hook config whose messageTemplate lacks
  # the conversation-memory READ-before and APPEND-after steps. GHL inbound hook
  # sessions are SINGLE-TURN — without these two steps the agent has zero memory
  # across messages (root cause of the Corey "didn't remember anything" incident).
  # Needles are case-insensitive: "conversational-logs", "read", "append".
  GUARD_TMPL="$(jq -r '.messageTemplate' <<<"$NEW_MAPPING")"
  GUARD_LC="$(printf '%s' "$GUARD_TMPL" | tr '[:upper:]' '[:lower:]')"
  GUARD_MISSING=""
  case "$GUARD_LC" in *conversational-logs*) : ;; *) GUARD_MISSING="$GUARD_MISSING conversational-logs" ;; esac
  case "$GUARD_LC" in *read*) : ;; *) GUARD_MISSING="$GUARD_MISSING read" ;; esac
  case "$GUARD_LC" in *append*) : ;; *) GUARD_MISSING="$GUARD_MISSING append" ;; esac
  if [[ -n "$GUARD_MISSING" ]]; then
    echo "REFUSED: GHL inbound messageTemplate is missing conversation-memory element(s):${GUARD_MISSING}." >&2
    echo "GHL hook sessions are single-turn; the template MUST tell the agent to READ conversational-logs/<contact_id> before replying and APPEND after. Not writing config." >&2
    exit 8
  fi
  # NOTE: jq 1.7 REJECTS a leading `.hooks //= {};` statement (the `;` top-level
  # separator is a syntax error). Use `.hooks = (.hooks // {})` piped with `|`
  # instead — same "default-then-merge" semantics, valid jq 1.7.
  UPDATED="$(jq \
    --arg tok "$HOOKS_TOKEN" \
    --arg agent "$ROUTING_AGENT_ID" \
    --argjson mapping "$NEW_MAPPING" \
    '.hooks = (.hooks // {}) |
     .hooks.enabled = true |
     .hooks.token = $tok |
     .hooks.path = (.hooks.path // "/hooks") |
     .hooks.maxBodyBytes = (.hooks.maxBodyBytes // 262144) |
     .hooks.defaultSessionKey = (.hooks.defaultSessionKey // "hook:ghl:default") |
     .hooks.allowRequestSessionKey = true |
     .hooks.allowedSessionKeyPrefixes = ((.hooks.allowedSessionKeyPrefixes // []) + ["hook:ghl:"] | unique) |
     .hooks.allowedAgentIds = ((.hooks.allowedAgentIds // []) + [$agent, "main"] | unique) |
     .hooks.mappings = ((.hooks.mappings // []) + [$mapping])' "$CONFIG_FILE")"
  write_config "$UPDATED"
  echo "hooks.mappings entry id=$ROUTE_ID merged into config" >&2
fi

# Validate (best-effort — non-fatal if CLI absent)
if command -v openclaw >/dev/null 2>&1; then
  openclaw config validate || { echo "openclaw config validate FAILED — restore from .bak.*" >&2; exit 5; }
fi

# =============================================================================
# STEP 3.5 — Model Selection Wizard
# =============================================================================
echo "==> Step 3.5: Model Selection Wizard" >&2

# Skip if all three tiers already set.
# IMPORTANT — schema note (verified on openclaw 2026.5.27): there is NO
# `agents.defaults.async` / `agents.defaults.batch` key in the config schema —
# writing them makes `openclaw config validate` FAIL ("Invalid input"). The
# real-time model lives on the agent (agents.list[main].model, supported). The
# async/batch TIER selections are NOT config keys; they are downstream-consumer
# values (cron BATCH_MODEL, the capabilities playbook), so we persist them to
# the secrets/state env file (ASYNC_MODEL / BATCH_MODEL) instead of the config.
RT_SET="$(jq -r '(.agents.list // []) | map(select(.id=="main")) | .[0].model // empty' "$CONFIG_FILE")"
ASYNC_SET="${ASYNC_MODEL:-}"
BATCH_SET="${BATCH_MODEL:-}"

if [[ -n "$RT_SET" && -n "$ASYNC_SET" && -n "$BATCH_SET" ]]; then
  echo "all three tiers already configured — skipping wizard (rt=$RT_SET async=$ASYNC_SET batch=$BATCH_SET)" >&2
else
  pick_model() {
    local tier="$1"; shift
    local prompt="$1"; shift
    local default="$1"; shift
    local -a opts=("$@")
    {
      echo ""
      echo "── $tier tier ──"
      echo "$prompt"
      local i=1
      for opt in "${opts[@]}"; do echo "  $i) $opt"; ((i++)); done
      echo "  (Enter = $default)"
      printf "Choice: "
    } >&2
    local choice
    read -r choice </dev/tty || choice=""
    if [[ -z "$choice" ]]; then echo "$default"; return; fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#opts[@]} )); then
      # Strip trailing " — comment" if present
      echo "${opts[choice-1]%% — *}"
    else
      echo "$choice"
    fi
  }

  RT_OPTS=(
    "deepseek/deepseek-v4-pro:thinking-max — highest-reasoning real-time"
    "google/gemini-3.1-flashlight — fast + near-free (RECOMMENDED for high volume)"
    "kimi/kimi-2.6 — strong long-context reasoning"
    "openai/gpt-5.5 — balanced"
    "openrouter/free — cheapest, slower"
  )
  ASYNC_OPTS=(
    "deepseek/deepseek-v4-pro:thinking-max — highest-reasoning"
    "google/gemini-3.1-flashlight — balanced"
    "openrouter/free — free + perfect for email"
    "anthropic/claude-opus-4-7 — premium quality"
    "same-as-realtime"
  )
  BATCH_OPTS=(
    "openrouter/free — free, batch-only (RECOMMENDED)"
    "deepseek/deepseek-v4-flash — small cost, better quality"
    "google/gemini-3.1-flashlight — balanced"
    "same-as-realtime"
  )

  if [[ -z "$RT_SET" ]]; then
    RT_SET="$(pick_model "REAL-TIME" "SMS / Messenger / IG / Live Chat — speed matters" \
      "google/gemini-3.1-flashlight" "${RT_OPTS[@]}")"
  fi
  if [[ -z "$ASYNC_SET" ]]; then
    ASYNC_SET="$(pick_model "ASYNC" "Email / LinkedIn — minutes are fine" \
      "openrouter/free" "${ASYNC_OPTS[@]}")"
    [[ "$ASYNC_SET" == "same-as-realtime" ]] && ASYNC_SET="$RT_SET"
  fi
  if [[ -z "$BATCH_SET" ]]; then
    BATCH_SET="$(pick_model "BATCH" "Nightly summarization — no real-time pressure" \
      "openrouter/free" "${BATCH_OPTS[@]}")"
    [[ "$BATCH_SET" == "same-as-realtime" ]] && BATCH_SET="$RT_SET"
  fi

  # Verify provider key
  needs_key() {
    case "$1" in
      openrouter/*|google/*|deepseek/*|kimi/*|openai/gpt-*|qwen/*) echo "OPENROUTER_API_KEY" ;;
      anthropic/*) echo "ANTHROPIC_API_KEY" ;;
      ollama-cloud/*) echo "OLLAMA_API_KEY" ;;
      *) echo "" ;;
    esac
  }
  for m in "$RT_SET" "$ASYNC_SET" "$BATCH_SET"; do
    k="$(needs_key "$m")"
    [[ -z "$k" ]] && continue
    if ! grep -qE "^${k}=" "$SECRETS_ENV_FILE" 2>/dev/null && [[ -z "${!k:-}" ]]; then
      echo "STOP: model $m needs $k — add it to $SECRETS_ENV_FILE and re-run." >&2
      exit 6
    fi
  done

  backup_config
  # Write ONLY the supported key: the real-time model on agents.list[main].model.
  # (jq 1.7-safe: use `.agents = (.agents // {})` not `.agents //= {}`.) We do NOT
  # write agents.defaults.async/.batch — those keys are not in the 2026.5.27 schema
  # and would fail `openclaw config validate`.
  UPDATED="$(jq \
    --arg rt "$RT_SET" \
    '.agents = (.agents // {}) |
     .agents.list = (.agents.list // []) |
     (if (.agents.list | map(.id == "main") | any) then
        .agents.list |= map(if .id == "main" then .model = $rt else . end)
      else
        .agents.list += [{id:"main", model:$rt}]
      end)' "$CONFIG_FILE")"
  write_config "$UPDATED"
  # Persist the async/batch TIER selections to the secrets/state env file so the
  # downstream consumers (04-register-crons.sh BATCH_MODEL, the capabilities
  # playbook) can read them — without polluting the config with invalid keys.
  append_secret "REALTIME_MODEL" "$RT_SET"
  append_secret "ASYNC_MODEL" "$ASYNC_SET"
  append_secret "BATCH_MODEL" "$BATCH_SET"
  echo "models saved: realtime=$RT_SET (config) async=$ASYNC_SET batch=$BATCH_SET (persisted to $SECRETS_ENV_FILE)" >&2
fi

# System Health Heartbeat cron (idempotent)
# Crons MUST be registered via the gateway cron store (`openclaw cron add`) — the
# legacy `.cron.jobs` config block does NOT validate on openclaw 2026.5.27
# (`openclaw config validate` rejects it). See references/GHL-INBOUND-AND-PLAYBOOKS.md §11.
SHH_MSG="Run the Monthly Comprehensive Review per protocols/monthly-comprehensive-review-protocol.md — 30-day audit across playbooks, GHL workflows, knowledge bases, model configs, tune-ups, bug log."
if command -v openclaw >/dev/null 2>&1; then
  if openclaw cron list 2>/dev/null | grep -q "system-health-heartbeat"; then
    echo "cron system-health-heartbeat already registered — skipping" >&2
  else
    openclaw cron add --name system-health-heartbeat --cron "0 9 1 * *" --agent main \
      --message "$SHH_MSG" --light-context --best-effort-deliver \
      && echo "registered cron: system-health-heartbeat (0 9 1 * *)" >&2 \
      || echo "WARN: failed to register cron system-health-heartbeat via CLI" >&2
  fi
else
  echo "WARN: openclaw CLI not on PATH — skipping system-health-heartbeat cron registration" >&2
fi

# =============================================================================
# STEP 4 — End-to-end test through the public tunnel
# =============================================================================
echo "==> Step 4: end-to-end test" >&2
# FLAT body — MUST contain ALL 23 keys (23 = minimum, no stripped/short bodies); the body's
# messageTemplate is placeholder-free — see references/GHL-INBOUND-AND-PLAYBOOKS.md §14.
PAYLOAD="{\"id\":\"${ROUTE_ID}\",\"match\":\"${ROUTE_ID}\",\"action\":\"agent\",\"agent_id\":\"${ROUTING_AGENT_ID:-main}\",\"model\":\"ollama/deepseek-v4-flash:cloud\",\"wakeMode\":\"now\",\"name\":\"GHL Sales Inbound\",\"session_key\":\"hook:ghl:sms:e2e-test-001\",\"messageTemplate\":\"Respond as the Sales agent. MANDATORY — SEND, do not just draft: you MUST send your reply by calling the GHL Conversations API (POST conversations/messages) for this contact on this channel, per TOOLS.md. Composing or drafting a reply is NOT sending — the customer receives nothing unless you make the API call. Do NOT end your turn until the send call returns a messageId/conversationId.\",\"deliver\":false,\"timeoutSeconds\":300,\"channel\":\"sms\",\"to\":\"+15555550100\",\"thinking\":\"medium\",\"contact_id\":\"e2e-test-001\",\"first_name\":\"E2E\",\"last_name\":\"Test\",\"email\":\"e2e@example.com\",\"phone\":\"+15555550100\",\"subject\":\"\",\"message_body\":\"End-to-end setup verification.\",\"location_id\":\"e2e-loc-001\",\"location_name\":\"E2E Test Location\"}"

HTTP_CODE="$(curl -sS -o /tmp/.hooks-e2e-body.$$ -w '%{http_code}' \
  --max-time 30 \
  -X POST "https://${PUBLIC_HOSTNAME}/hooks/${ROUTE_ID}" \
  -H "Authorization: Bearer ${HOOKS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" || echo "000")"
BODY="$(cat /tmp/.hooks-e2e-body.$$ 2>/dev/null || true)"
rm -f /tmp/.hooks-e2e-body.$$

case "$HTTP_CODE" in
  2*) echo "E2E PASS — HTTP $HTTP_CODE" >&2; echo "$BODY" | head -c 400 >&2; echo >&2 ;;
  *)  echo "E2E FAIL — HTTP $HTTP_CODE" >&2; echo "$BODY" | head -c 400 >&2; echo >&2; exit 7 ;;
esac

echo "OK: hooks + models + cron configured; E2E pass." >&2
