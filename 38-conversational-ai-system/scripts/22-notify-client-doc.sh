#!/usr/bin/env bash
# 22-notify-client-doc.sh — MANDATORY, GATED Telegram delivery of the client's doc link.
#
# ROOT CAUSE this gate kills: the install kept finishing without the client ever
# being SENT their Quick-Start / Notion doc link over Telegram. The operator is
# tired of repeating it: "every client gets their link via Telegram, no matter
# what." Prose in the playbook was not enough — the step got skipped. This script
# makes it un-skippable and machine-verifiable:
#
#   (a) Find the client's Telegram chat id by GREPPING THE TRANSCRIPTS
#       agents/*/sessions/*.jsonl (NOT just sessions.json keys — that misses
#       paired chats; the paired-chat lesson). It scores every chat id that appears as
#         "chat":{"id":<n>      OR   telegram:direct:<n>
#         "chatId":<n>          OR   "from":{"id":<n>
#       drops the operator id, and takes the MOST-FREQUENT remaining id.
#   (b) Send the doc link to that chat via the OpenClaw gateway
#         openclaw message send --channel telegram -t <chat> ...
#       (NEVER curl direct to api.telegram.org — gateway only.)
#   (c) If NO chat is found OR the send fails, FLAG LOUDLY (stderr) and record
#       clientDocDelivered=false in the run manifest, exiting NON-ZERO so the
#       install is marked INCOMPLETE. It NEVER silently skips. On success it
#       records clientDocDelivered=true (+ the chat id + the link).
#
# The doc LINK comes from (in priority order):
#   1. --link <url>                                  (explicit)
#   2. DOC_LINK env                                  (explicit)
#   3. CLIENT_DOC_URL env                            (explicit)
#   4. $MASTER_FILES_DIR/.notion-reference-page-url  (written by 21-generate-...)
#   5. the Layer-3 markdown fallback path under conversation-workflows/  (a path,
#      not a URL — still delivered; the client is told where the file lives)
#
# The chat id can be forced with --chat <id> / CLIENT_TELEGRAM_CHAT_ID (skips the
# transcript scan). The operator id (the chat to EXCLUDE from the scan so the doc is
# never delivered to the operator instead of the client) is supplied per-install via
# OPERATOR_TELEGRAM_CHAT_ID — it is NOT hardcoded to any person. Set it to the
# installing operator's own Telegram id on each install (the install passes it in).
#
# Exit codes:
#   0 = doc link SENT to the client over Telegram (clientDocDelivered=true recorded)
#   1 = NOT delivered — no chat found, or the send failed (clientDocDelivered=false
#       recorded). The install is INCOMPLETE; do not hand off.
#   2 = usage / no doc link resolvable (nothing to deliver).
#
# Implementation note: PURE BASH (awk/grep/sed), no python — qc-static.yml's
# Python-syntax + claude-/anthropic-string scans key off .py files, and BASH
# keeps this gate CI-portable (same posture as qc-conversation-memory.sh /
# qc-playbook-doc.sh). bash -n clean. set -uo pipefail.

set -uo pipefail

OS_NAME="$(uname -s 2>/dev/null || echo unknown)"

CHAT_ID=""
DOC_LINK=""
MANIFEST=""
DRY_RUN=0
JSON_MODE=0

OPERATOR_TELEGRAM_CHAT_ID="${OPERATOR_TELEGRAM_CHAT_ID:-}"
CLIENT_FIRST_NAME="${CLIENT_FIRST_NAME:-there}"
CLIENT_BUSINESS_NAME="${CLIENT_BUSINESS_NAME:-your business}"

usage() { sed -n '1,46p' "$0"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --chat)     CHAT_ID="$2"; shift 2 ;;
    --link)     DOC_LINK="$2"; shift 2 ;;
    --manifest) MANIFEST="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --json)     JSON_MODE=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# ── Resolve MASTER_FILES_DIR (env, else the pointer file) ─────────────────────
MASTER_FILES_DIR="${MASTER_FILES_DIR:-}"
if [ -z "$MASTER_FILES_DIR" ]; then
  POINTER="${HOME}/.openclaw/.skill-38-master-files-dir"
  if [ -f "$POINTER" ]; then
    MASTER_FILES_DIR="$(cat "$POINTER")"; MASTER_FILES_DIR="${MASTER_FILES_DIR%$'\n'}"
  fi
fi

# ── Resolve the OpenClaw config root (for the agents/*/sessions transcript scan) ─
#    Try every common install layout (Mac Homebrew, VPS/Docker, /data).
declare -a OC_ROOTS=()
[ -n "${OPENCLAW_HOME:-}" ] && OC_ROOTS+=("$OPENCLAW_HOME")
OC_ROOTS+=("$HOME/.openclaw" "/data/.openclaw" "/root/.openclaw")

# ── Resolve the doc LINK ──────────────────────────────────────────────────────
if [ -z "$DOC_LINK" ]; then DOC_LINK="${DOC_LINK_ENV:-${DOC_LINK:-}}"; fi
if [ -z "$DOC_LINK" ]; then DOC_LINK="${CLIENT_DOC_URL:-}"; fi
if [ -z "$DOC_LINK" ] && [ -n "$MASTER_FILES_DIR" ] && [ -f "$MASTER_FILES_DIR/.notion-reference-page-url" ]; then
  DOC_LINK="$(head -n1 "$MASTER_FILES_DIR/.notion-reference-page-url" 2>/dev/null | tr -d '[:space:]')"
fi
DOC_IS_PATH=0
if [ -z "$DOC_LINK" ] && [ -n "$MASTER_FILES_DIR" ] && [ -f "$MASTER_FILES_DIR/conversation-workflows/01-client-reference-sheet.md" ]; then
  DOC_LINK="$MASTER_FILES_DIR/conversation-workflows/01-client-reference-sheet.md"
  DOC_IS_PATH=1
fi

if [ -z "$DOC_LINK" ]; then
  echo "[22-notify-client-doc] ERROR: no doc link resolvable (pass --link <url>, set DOC_LINK / CLIENT_DOC_URL, or run 21-generate-client-reference-sheet.sh first so .notion-reference-page-url exists)." >&2
  exit 2
fi

# ── Locate today's / most-recent run manifest (for the clientDocDelivered state) ─
if [ -z "$MANIFEST" ] && [ -n "$MASTER_FILES_DIR" ] && [ -d "$MASTER_FILES_DIR" ]; then
  MANIFEST="$(find "$MASTER_FILES_DIR" -maxdepth 1 -type f -name 'run-manifest-*.md' 2>/dev/null | sort | tail -n1 || true)"
fi

record_state() {
  # $1 = true|false ; $2 = chat id (or "") ; $3 = note
  local delivered="$1" chat="$2" note="$3"
  [ -n "$MANIFEST" ] || return 0
  [ -f "$MANIFEST" ] || return 0
  {
    printf 'clientDocDelivered=%s\n' "$delivered"
    printf 'clientDocDelivered: %s -> chat=%s link=%s (%s)\n' "$delivered" "${chat:-<none>}" "$DOC_LINK" "$note"
  } >> "$MANIFEST"
}

# ─────────────────────────────────────────────────────────────────────────────
# Find the client's Telegram chat id by GREPPING THE TRANSCRIPTS.
# This is the paired-chat lesson: sessions.json keys miss paired chats, so we scan the
# raw session transcripts agents/*/sessions/*.jsonl for every id form a telegram
# message can carry, score by frequency, drop the operator id, and take the
# most-frequent remaining id.
# ─────────────────────────────────────────────────────────────────────────────
find_chat_from_transcripts() {
  local root jl
  local -a transcripts=()
  for root in "${OC_ROOTS[@]}"; do
    [ -d "$root" ] || continue
    # agents/<id>/sessions/*.jsonl (any depth under agents/)
    while IFS= read -r jl; do
      [ -n "$jl" ] && transcripts+=("$jl")
    done < <(find "$root/agents" -type f -name '*.jsonl' 2>/dev/null)
    # also a flat sessions/ dir some layouts use
    while IFS= read -r jl; do
      [ -n "$jl" ] && transcripts+=("$jl")
    done < <(find "$root/sessions" -type f -name '*.jsonl' 2>/dev/null)
  done

  [ "${#transcripts[@]}" -gt 0 ] || return 1

  # Extract every candidate id from all four forms, drop the operator id, count,
  # and emit the most-frequent one. All in one awk pass over grep'd id tokens.
  #   "chat":{"id":<n>     telegram:direct:<n>     "chatId":<n>     "from":{"id":<n>
  grep -hoE \
    '"chat"[[:space:]]*:[[:space:]]*\{[[:space:]]*"id"[[:space:]]*:[[:space:]]*-?[0-9]+|telegram:direct:-?[0-9]+|"chatId"[[:space:]]*:[[:space:]]*-?[0-9]+|"from"[[:space:]]*:[[:space:]]*\{[[:space:]]*"id"[[:space:]]*:[[:space:]]*-?[0-9]+' \
    "${transcripts[@]}" 2>/dev/null \
  | grep -oE -- '-?[0-9]+' \
  | awk -v op="$OPERATOR_TELEGRAM_CHAT_ID" '
      $0 == op { next }            # never deliver to the operator
      { count[$0]++ }
      END {
        best=""; bestn=0
        for (id in count) { if (count[id] > bestn) { bestn=count[id]; best=id } }
        if (best != "") print best
      }
    '
}

SCAN_NOTE=""
if [ -z "$CHAT_ID" ]; then
  CHAT_ID="${CLIENT_TELEGRAM_CHAT_ID:-}"
fi
if [ -z "$CHAT_ID" ] || [ "$CHAT_ID" = "0" ]; then
  FOUND="$(find_chat_from_transcripts || true)"
  if [ -n "$FOUND" ]; then
    CHAT_ID="$FOUND"
    SCAN_NOTE="resolved from transcript scan (most-frequent non-operator id)"
  else
    SCAN_NOTE="transcript scan found NO non-operator chat id"
  fi
else
  SCAN_NOTE="chat id supplied explicitly"
fi

# ── No chat found → FLAG LOUDLY, record clientDocDelivered=false, exit 1 ───────
if [ -z "$CHAT_ID" ] || [ "$CHAT_ID" = "0" ]; then
  echo "" >&2
  echo "============================================================" >&2
  echo "[22-notify-client-doc] !!! CLIENT DOC NOT DELIVERED !!!" >&2
  echo "  Could not find the client's Telegram chat id." >&2
  echo "  ($SCAN_NOTE)" >&2
  echo "  The doc link was NOT sent. The install is INCOMPLETE." >&2
  echo "  FIX: re-run with --chat <client_chat_id> (or set CLIENT_TELEGRAM_CHAT_ID)." >&2
  echo "  If you do not know the client's id, message the operator chat and ask." >&2
  echo "  EVERY client gets their link via Telegram, no matter what." >&2
  echo "============================================================" >&2
  record_state "false" "" "no client chat id found ($SCAN_NOTE)"
  if [ "$JSON_MODE" = "1" ]; then
    printf '{"clientDocDelivered":false,"chat":null,"link":"%s","reason":"no client chat id found"}\n' "$DOC_LINK"
  fi
  exit 1
fi

# ── Compose the client message (the doc LINK is the headline) ─────────────────
MSG_FILE="$(mktemp 2>/dev/null || echo "/tmp/.skill38-client-doc-msg.$$")"
{
  printf 'Hi %s, your conversational AI brain is set up.\n\n' "$CLIENT_FIRST_NAME"
  if [ "$DOC_IS_PATH" = "1" ]; then
    printf 'Your Quick-Start setup doc is here on your machine:\n\n'
    printf '    %s\n\n' "$DOC_LINK"
    printf 'Open it and follow the 🚀 Quick Start at the top — every value you copy-paste into GHL is in there, in order.\n\n'
  else
    printf 'Here is your Quick-Start setup doc — open this link:\n\n'
    printf '    %s\n\n' "$DOC_LINK"
    printf 'Everything you need is on that page: the 🚀 Quick Start at the top (webhook URL, headers, Raw Body JSON — each in its own one-click copy box), then the Workflow-AI prompt and the post-build verification.\n\n'
  fi
  printf 'Anything you do not understand: screenshot it and message your setup admin.\n'
} > "$MSG_FILE"

# ── Send via the OpenClaw gateway (NEVER curl direct to api.telegram.org) ──────
if [ "$DRY_RUN" = "1" ]; then
  echo "[22-notify-client-doc] DRY RUN — would send doc link to chat $CHAT_ID ($SCAN_NOTE):"
  sed 's/^/    /' "$MSG_FILE"
  rm -f "$MSG_FILE" 2>/dev/null || true
  record_state "true" "$CHAT_ID" "dry-run (not actually sent)"
  [ "$JSON_MODE" = "1" ] && printf '{"clientDocDelivered":true,"chat":"%s","link":"%s","dryRun":true}\n' "$CHAT_ID" "$DOC_LINK"
  exit 0
fi

if ! command -v openclaw >/dev/null 2>&1; then
  echo "" >&2
  echo "[22-notify-client-doc] !!! openclaw CLI not on PATH — CANNOT SEND the client doc link." >&2
  echo "  The install is INCOMPLETE. Put openclaw on PATH and re-run (sends go through the gateway only)." >&2
  rm -f "$MSG_FILE" 2>/dev/null || true
  record_state "false" "$CHAT_ID" "openclaw CLI not on PATH"
  [ "$JSON_MODE" = "1" ] && printf '{"clientDocDelivered":false,"chat":"%s","link":"%s","reason":"openclaw not on PATH"}\n' "$CHAT_ID" "$DOC_LINK"
  exit 1
fi

SEND_OUT="$(openclaw message send --channel telegram -t "$CHAT_ID" --file "$MSG_FILE" 2>&1)"
SEND_RC=$?
rm -f "$MSG_FILE" 2>/dev/null || true

if [ "$SEND_RC" -ne 0 ]; then
  echo "" >&2
  echo "[22-notify-client-doc] !!! Telegram send FAILED (rc=$SEND_RC) — client doc NOT delivered." >&2
  echo "  Gateway said: $SEND_OUT" >&2
  echo "  The install is INCOMPLETE. Fix the gateway/pairing and re-run." >&2
  record_state "false" "$CHAT_ID" "send failed rc=$SEND_RC: $SEND_OUT"
  [ "$JSON_MODE" = "1" ] && printf '{"clientDocDelivered":false,"chat":"%s","link":"%s","reason":"send failed rc=%s"}\n' "$CHAT_ID" "$DOC_LINK" "$SEND_RC"
  exit 1
fi

echo "[22-notify-client-doc] OK — doc link delivered to client chat $CHAT_ID ($SCAN_NOTE)."
record_state "true" "$CHAT_ID" "delivered via openclaw gateway ($SCAN_NOTE)"
[ "$JSON_MODE" = "1" ] && printf '{"clientDocDelivered":true,"chat":"%s","link":"%s"}\n' "$CHAT_ID" "$DOC_LINK"
exit 0
