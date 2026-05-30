#!/usr/bin/env bash
# 24-update-tools-md.sh
#
# Idempotently preloads the CLIENT agent's TOOLS.md with the concise, verified
# GHL Convert-and-Flow API quick-reference (canonical request shapes) so the agent
# has the exact method/URL/headers/body/scope for every messaging + calendar +
# appointment + invoice operation in its CORE context — and answers fast at runtime
# instead of digging through the dense per-module references.
#
# WHERE + WHY: this writes to TOOLS.md (NOT AGENTS.md). AGENTS.md = WHAT-TO-DO
# (rules/behavior); TOOLS.md = WHERE-THINGS-LIVE (tools, endpoints, API reference).
# API request shapes belong in TOOLS.md.
#
# The block content is the SINGLE source of truth in
#   references/ghl-api-quick-reference.md
# (verified against references/GHL-INBOUND-AND-PLAYBOOKS.md §7-§9 + Skill 29
# references/{conversations,calendars,payments}.md). This script wraps that file's
# body in BEGIN/END markers so it is safe to run repeatedly.
#
# IDEMPOTENT: if the marker block is already present, this script does nothing
# (it does NOT duplicate, and does NOT rewrite an existing block).
#
# UNIVERSAL / ZERO personal data: the injected block carries only placeholders
# (<CONTACT_ID>, <CAL_ID>, <LOCATION_ID>, $GHL_PRIVATE_INTEGRATION_TOKEN). The
# client's real PUBLIC_HOSTNAME, if set, is written ONLY as a one-line comment for
# operator orientation — never a real token, never client data.
#
# OS-aware (matches skill38-calendar-sync.sh / the workspace TOOLS.md convention):
#   Linux   → /data/.openclaw/workspace/TOOLS.md
#   Darwin  → $HOME/.openclaw/workspace/TOOLS.md
# Override with the TOOLS_MD env var or a positional arg.

set -euo pipefail

MARKER="GHL_API_QUICK_REFERENCE"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REF_FILE="${REF_FILE:-$SKILL_ROOT/references/ghl-api-quick-reference.md}"

# -----------------------------------------------------------------------------
# Resolve the CLIENT workspace TOOLS.md
# -----------------------------------------------------------------------------
TOOLS_MD="${1:-${TOOLS_MD:-}}"
if [[ -z "$TOOLS_MD" ]]; then
  OS_NAME="$(uname -s 2>/dev/null || echo unknown)"
  if [[ "$OS_NAME" == "Darwin" ]]; then
    TOOLS_MD="$HOME/.openclaw/workspace/TOOLS.md"
  else
    TOOLS_MD="/data/.openclaw/workspace/TOOLS.md"
  fi
  # Probe the common alternates if the primary is absent.
  if [[ ! -f "$TOOLS_MD" ]]; then
    for cand in \
      "/data/.openclaw/workspace/TOOLS.md" \
      "$HOME/.openclaw/workspace/TOOLS.md" \
      "$HOME/clawd/TOOLS.md" \
      "/data/clawd/TOOLS.md"; do
      [[ -f "$cand" ]] && TOOLS_MD="$cand" && break
    done
  fi
fi

if [[ ! -f "$REF_FILE" ]]; then
  echo "[24-update-tools-md] quick-reference source not found: $REF_FILE" >&2
  exit 1
fi

if [[ ! -f "$TOOLS_MD" ]]; then
  echo "[24-update-tools-md] TOOLS.md not found at: $TOOLS_MD" >&2
  echo "[24-update-tools-md] Set TOOLS_MD env var (or pass it as arg 1) to the client workspace TOOLS.md, or create the file first." >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Idempotency: skip entirely if the marker block is already present.
# -----------------------------------------------------------------------------
if grep -q "<!-- BEGIN SKILL38: $MARKER -->" "$TOOLS_MD"; then
  echo "[24-update-tools-md] block '$MARKER' already present in $TOOLS_MD — skipping (idempotent)"
  exit 0
fi

# Timestamped backup before any write (only made when we are actually writing).
BACKUP="${TOOLS_MD}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -p "$TOOLS_MD" "$BACKUP"
echo "[24-update-tools-md] Backup written → $BACKUP"

# Optional operator-orientation comment: the client's real PUBLIC_HOSTNAME, if the
# operator exported it. This is a COMMENT only — never a token, never client data.
HOST_COMMENT=""
if [[ -n "${PUBLIC_HOSTNAME:-}" ]]; then
  HOST_COMMENT="> _This client's public hook host: \`https://${PUBLIC_HOSTNAME}/hooks/…\` (inbound webhooks land here; the agent REPLIES via the API below)._"
fi

# -----------------------------------------------------------------------------
# Append the marker-wrapped block. Body = the canonical quick-reference file.
# -----------------------------------------------------------------------------
{
  printf '\n<!-- BEGIN SKILL38: %s -->\n\n' "$MARKER"
  if [[ -n "$HOST_COMMENT" ]]; then
    printf '%s\n\n' "$HOST_COMMENT"
  fi
  cat "$REF_FILE"
  printf '\n<!-- END SKILL38: %s -->\n' "$MARKER"
} >> "$TOOLS_MD"

echo "[24-update-tools-md] GHL API quick-reference block appended to $TOOLS_MD"
echo "[24-update-tools-md] The client agent now has the canonical GHL request shapes in its core context."
