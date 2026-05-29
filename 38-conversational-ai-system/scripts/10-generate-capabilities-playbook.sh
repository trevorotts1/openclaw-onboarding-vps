#!/usr/bin/env bash
# 10-generate-capabilities-playbook.sh
#
# Reads the skill's templates/agent-capabilities-playbook-template.md,
# substitutes placeholders with values pulled from openclaw.json and
# company-config.json, and writes the result to
# $MASTER_FILES_DIR/agent-capabilities-playbook.md.
#
# Substitution map (extend as needed):
#   <CLIENT_NAME>           ← $MASTER_FILES_DIR/company-config.json .name (else "this client")
#   <MODEL_TIER_REAL_TIME>  ← openclaw.json .agents.list[id=main].model
#   <MODEL_TIER_ASYNC>      ← $ASYNC_MODEL from secrets.env (else "(same as real-time)")
#   <MODEL_TIER_BATCH>      ← $BATCH_MODEL from secrets.env (else "(same as real-time)")
#       (async/batch are NOT config keys — agents.defaults.async/.batch fail
#        `openclaw config validate` on 2026.5.27; they are persisted to the
#        secrets/state env by 15-configure-hooks-mappings.sh)
#   <CHANNELS_ENABLED>      ← derived from openclaw.json .hooks.mappings (comma-separated)
#   <INSTALL_TIMESTAMP>     ← date -u +%Y-%m-%dT%H:%M:%SZ
#
# Idempotent: if the output file already exists, it is backed up to
# <output>.bak.<ts> before being overwritten.

set -euo pipefail

# -----------------------------------------------------------------------------
# Locate skill folder (this script lives at <skill>/scripts/, template at <skill>/templates/)
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$SKILL_DIR/templates/agent-capabilities-playbook-template.md"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "[10-generate-capabilities-playbook] template missing: $TEMPLATE" >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Resolve MASTER_FILES_DIR
# -----------------------------------------------------------------------------
POINTER_FILE="${HOME}/.openclaw/.skill-38-master-files-dir"
if [[ ! -f "$POINTER_FILE" ]]; then
  echo "[10-generate-capabilities-playbook] pointer file missing: $POINTER_FILE" >&2
  echo "[10-generate-capabilities-playbook] run 01-locate-master-files-folder.sh first." >&2
  exit 1
fi
MASTER_FILES_DIR="$(cat "$POINTER_FILE")"
MASTER_FILES_DIR="${MASTER_FILES_DIR%$'\n'}"

OUTPUT="$MASTER_FILES_DIR/agent-capabilities-playbook.md"

# -----------------------------------------------------------------------------
# Resolve openclaw.json
# -----------------------------------------------------------------------------
OS_NAME="$(uname -s)"
if [[ "$OS_NAME" == "Darwin" ]]; then
  OPENCLAW_JSON="${OPENCLAW_JSON:-$HOME/.openclaw/openclaw.json}"
else
  OPENCLAW_JSON="${OPENCLAW_JSON:-/data/.openclaw/openclaw.json}"
fi

COMPANY_CONFIG="$MASTER_FILES_DIR/company-config.json"

# Source the secrets/state env so the persisted ASYNC_MODEL/BATCH_MODEL tier
# selections (written by 15-configure-hooks-mappings.sh) are available.
SECRETS_ENV_FILE="${SECRETS_ENV_FILE:-$HOME/.openclaw/secrets.env}"
[[ -f "$SECRETS_ENV_FILE" ]] && set -a && . "$SECRETS_ENV_FILE" && set +a || true

# -----------------------------------------------------------------------------
# Pull substitution values
# -----------------------------------------------------------------------------
get_json() {
  # $1 = file, $2 = jq filter, $3 = fallback
  local file="$1" filter="$2" fallback="${3:-}"
  if [[ -f "$file" ]] && command -v jq >/dev/null 2>&1; then
    local val
    val="$(jq -r "$filter // empty" "$file" 2>/dev/null || true)"
    if [[ -n "$val" && "$val" != "null" ]]; then
      printf '%s' "$val"
      return
    fi
  fi
  printf '%s' "$fallback"
}

CLIENT_NAME="$(get_json "$COMPANY_CONFIG" '.name' 'this client')"
# Real-time tier lives on the agent (agents.list[main].model — the only supported
# per-agent model key on 2026.5.27). The async/batch TIERS are NOT config keys
# (writing agents.defaults.async/.batch fails config validate), so 15-configure-
# hooks-mappings.sh persists them to the secrets/state env as ASYNC_MODEL/BATCH_MODEL.
# Read those env vars here, falling back to "(same as real-time)" if unset.
MODEL_TIER_REAL_TIME="$(get_json "$OPENCLAW_JSON" '(.agents.list[]? | select(.id=="main") | .model)' 'unknown')"
MODEL_TIER_ASYNC="${ASYNC_MODEL:-(same as real-time)}"
MODEL_TIER_BATCH="${BATCH_MODEL:-(same as real-time)}"

CHANNELS_ENABLED='unknown'
if [[ -f "$OPENCLAW_JSON" ]] && command -v jq >/dev/null 2>&1; then
  derived="$(jq -r '.hooks.mappings // {} | keys | join(", ")' "$OPENCLAW_JSON" 2>/dev/null || true)"
  [[ -n "$derived" && "$derived" != "null" ]] && CHANNELS_ENABLED="$derived"
fi

INSTALL_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# -----------------------------------------------------------------------------
# Backup existing output if present
# -----------------------------------------------------------------------------
if [[ -f "$OUTPUT" ]]; then
  BAK="${OUTPUT}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cp -p "$OUTPUT" "$BAK"
  echo "[10-generate-capabilities-playbook] existing file backed up → $BAK"
fi

# -----------------------------------------------------------------------------
# Render template (strip operator-header HTML comments, then substitute)
# -----------------------------------------------------------------------------
# Use awk to drop the leading 5-line operator header (lines starting with '<!--')
# plus the blank line that follows, then sed to substitute placeholders.
awk 'BEGIN{skipped=0} /^<!--/ && skipped<6 {skipped++; next} /^$/ && skipped>=1 && skipped<7 {skipped++; next} {print}' "$TEMPLATE" \
  | sed \
      -e "s|<CLIENT_NAME>|${CLIENT_NAME}|g" \
      -e "s|<MODEL_TIER_REAL_TIME>|${MODEL_TIER_REAL_TIME}|g" \
      -e "s|<MODEL_TIER_ASYNC>|${MODEL_TIER_ASYNC}|g" \
      -e "s|<MODEL_TIER_BATCH>|${MODEL_TIER_BATCH}|g" \
      -e "s|<CHANNELS_ENABLED>|${CHANNELS_ENABLED}|g" \
      -e "s|<INSTALL_TIMESTAMP>|${INSTALL_TIMESTAMP}|g" \
  > "$OUTPUT"

echo "[10-generate-capabilities-playbook] wrote → $OUTPUT"
echo "[10-generate-capabilities-playbook] substituted: CLIENT_NAME='$CLIENT_NAME' REAL_TIME='$MODEL_TIER_REAL_TIME' ASYNC='$MODEL_TIER_ASYNC' BATCH='$MODEL_TIER_BATCH' CHANNELS='$CHANNELS_ENABLED'"
