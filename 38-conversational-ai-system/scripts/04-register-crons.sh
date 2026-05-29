#!/usr/bin/env bash
# 04-register-crons.sh
# Registers the recurring OpenClaw cron jobs for the Conversational AI System.
# Idempotent: each job is gated by a presence check against `openclaw cron list`.
# Playbook v5.14 — Step 9 + Step 3.5H.
#
# CRON REGISTRATION (verified on openclaw 2026.5.27): crons MUST be registered
# via the gateway cron store using the CLI flag form below. The legacy
# `.cron.jobs` JSON config block does NOT validate on 2026.5.27 — `openclaw
# config validate` rejects it ("cron: Invalid input"). See
# references/GHL-INBOUND-AND-PLAYBOOKS.md §11 and references/v6.0-source-playbook.md.
#
#   openclaw cron add --name <NAME> --cron "<EXPR>" --agent main \
#     --message "<MSG>" --light-context --best-effort-deliver
set -euo pipefail

ROUTING_AGENT_ID="${ROUTING_AGENT_ID:-main}"

# Pull persisted tier selections (ASYNC_MODEL/BATCH_MODEL) if the secrets/state
# file from 15-configure-hooks-mappings.sh exists; BATCH_MODEL drives the batch crons.
SECRETS_ENV_FILE="${SECRETS_ENV_FILE:-$HOME/.openclaw/secrets.env}"
[[ -f "$SECRETS_ENV_FILE" ]] && set -a && . "$SECRETS_ENV_FILE" && set +a || true
BATCH_MODEL="${BATCH_MODEL:-openrouter/free}"

command -v openclaw >/dev/null 2>&1 || {
  echo "openclaw CLI not on PATH — cannot register crons via the gateway cron store." >&2
  echo "Install/expose the openclaw CLI and re-run. (Crons must NOT be written to .cron.jobs — that block does not validate on 2026.5.27.)" >&2
  exit 2
}

# Idempotency: is a cron with this name already in the gateway store?
has_cron() {
  openclaw cron list 2>/dev/null | grep -q "$1"
}

# Register a cron via the CLI flag form (idempotent).
#   $1 = name   $2 = cron expr   $3 = message
register_cron() {
  local name="$1" expr="$2" message="$3"
  if has_cron "$name"; then
    echo "cron $name already registered — skipping" >&2
    return 0
  fi
  if openclaw cron add --name "$name" --cron "$expr" --agent "$ROUTING_AGENT_ID" \
       --message "$message" --light-context --best-effort-deliver; then
    echo "registered cron: $name ($expr)" >&2
  else
    echo "ERROR: failed to register cron $name via 'openclaw cron add'" >&2
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Cron 1 — conversation-log-summarizer  (nightly 11:30 PM)
# Summarizes the day's per-contact conversation logs into rolling summaries.
# Playbook Step 9 (Step 3.5G references this cron). Uses the batch tier model.
# -----------------------------------------------------------------------------
register_cron "conversation-log-summarizer" "30 23 * * *" \
  "Run the daily conversation log summarization using the batch model ($BATCH_MODEL). For each file under <MASTER_FILES_DIR>/conversational-logs/ touched today, append a rolling 5-bullet summary to the top of the file. Skip files unchanged since yesterday."

# -----------------------------------------------------------------------------
# Cron 2 — analytics-weekly-digest  (Mondays 8 AM)
# Per Step 9.17 analytics-dashboard-protocol.md.
# -----------------------------------------------------------------------------
register_cron "analytics-weekly-digest" "0 8 * * 1" \
  "Generate the weekly analytics digest per protocols/analytics-dashboard-protocol.md — volume by channel, top topics, sentiment distribution, escalation rate, safeguard activations. Notify the operator per notification-routing-protocol.md."

# -----------------------------------------------------------------------------
# Cron 3 — weekly-tune-up  (Sundays 2 AM)
# Per Step 9.x weekly-tune-up-protocol.md.
# -----------------------------------------------------------------------------
register_cron "weekly-tune-up" "0 2 * * 0" \
  "Run the weekly tune-up per protocols/weekly-tune-up-protocol.md — review last 7 days of bug log, classification corrections, deferred items; surface acceptance/ignore patterns; propose minor improvements for operator approval."

# -----------------------------------------------------------------------------
# Cron 4 — proactive-suggestions-scan  (Saturdays 11 PM)
# Per Step 9.34 Proactive Features Suite. v5.14 also bundles Step 9.36
# Model Version Freshness Checker into this cron.
# -----------------------------------------------------------------------------
register_cron "proactive-suggestions-scan" "0 23 * * 6" \
  "Run the weekly proactive-suggestions-scan per protocols/proactive-features-suite-protocol.md — workflows, Knowledge Sources, tags, discount codes, workflow improvements, escalation patterns, sales opportunities. Also run the bundled Model Version Freshness Checker (Step 9.36) — Ollama Cloud catalog, Ollama local manifests, OpenRouter catalog, direct provider APIs, embedding-model freshness. Operator approves YES/DEFER/IGNORE/MODIFY. 30-day cool-down."

# -----------------------------------------------------------------------------
# Cron 5 — system-health-heartbeat  (1st of each month, 9 AM)  [NEW in v5.14]
# Per protocols/monthly-comprehensive-review-protocol.md — Step 9.35.
# Deep 30-day audit: playbooks, GHL workflows, knowledge bases, model
# configs, accumulated tune-ups, bug log.
# -----------------------------------------------------------------------------
register_cron "system-health-heartbeat" "0 9 1 * *" \
  "Run the Monthly Comprehensive Review per protocols/monthly-comprehensive-review-protocol.md — 30-day audit across (1) all Conversation Playbooks (performance, outdated refs, scope overlap, retirement candidates), (2) all GHL workflows (firing volume, webhook health, split candidates), (3) Typed Knowledge Bases (last updated, hit rate, stale sources, Dreaming consolidation pace), (4) model configurations (latency trends, fallback hit rates, cost), (5) accumulated weekly tune-ups (acceptance follow-through, deferred items ready, ignored-but-recurring patterns), (6) bug log (recurring failures, new error types). Save report to <MASTER_FILES_DIR>/tune-ups/comprehensive-review.md. Notify operator per notification-routing-protocol.md. Operator approves YES/DEFER/IGNORE per item."

# -----------------------------------------------------------------------------
# Validate config is still clean (best-effort) — registering crons via the CLI
# must NOT have introduced an invalid .cron.jobs block.
# -----------------------------------------------------------------------------
if command -v openclaw >/dev/null 2>&1; then
  openclaw config validate || { echo "openclaw config validate FAILED after cron registration" >&2; exit 5; }
fi

echo "OK: 5 crons registered via the gateway cron store (conversation-log-summarizer, analytics-weekly-digest, weekly-tune-up, proactive-suggestions-scan, system-health-heartbeat)." >&2
