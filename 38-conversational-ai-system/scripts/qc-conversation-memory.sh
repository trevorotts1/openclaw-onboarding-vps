#!/usr/bin/env bash
# qc-conversation-memory.sh — machine-enforce the conversation-MEMORY logic on
# every GHL inbound SERVER-mapping messageTemplate.
#
# ROOT CAUSE this gate kills: GHL inbound hook sessions are SINGLE-TURN /
# stateless — every hook run is a fresh session (user-turns=1) with NO chat
# history. The agent's ONLY memory of a contact across messages is the
# per-contact conversation log under conversational-logs/. The agent must READ
# that log BEFORE replying and APPEND to it AFTER replying. If the SERVER-mapping
# messageTemplate drops either step, the agent has zero memory and "forgets"
# mid-conversation (the Corey incident: the canonical template was simplified
# during testing and lost the read/append steps → the agent didn't remember an
# in-progress booking). qc-send-directive.sh did NOT catch this because it only
# checks the SEND clause. This gate makes the conversation-memory logic
# un-droppable, enforced exactly like the send-directive.
#
# WHAT IT SCANS (same load-bearing carrier as qc-send-directive.sh = the OpenClaw
# `hooks.mappings` SERVER mapping messageTemplate, a.k.a. object B):
#   1. The INSTALLER canonical template — the messageTemplate the installer
#      WRITES in scripts/15-configure-hooks-mappings.sh (NEW_MAPPING). It must
#      NOT be possible to install a GHL hook whose messageTemplate lacks the
#      conversation-log read/append steps, so this file is checked explicitly
#      and is REQUIRED.
#   2. Every canonical server-mapping messageTemplate embedded in references/ +
#      templates/ + scripts/ — detected by the canonical inbound signature
#      "INBOUND MESSAGE FROM GOHIGHLEVEL" (the server mapping that actually
#      builds the agent prompt). Each such template must carry both steps.
#
# WHY NOT THE GHL BODY messageTemplate: the GHL Custom Webhook RAW BODY (object
# A, 23 keys, placeholder-free) carries an INERT messageTemplate that the server
# mapping OVERRIDES at runtime — the instructions that actually reach the agent
# live on the SERVER mapping. (The body's 23-key rule is enforced separately by
# qc-23-key-bodies.sh; the send-directive by qc-send-directive.sh.)
#
# REQUIRED ELEMENTS (all must be present in each server-mapping messageTemplate;
# wording may vary but every element is mandatory):
#   - a READ-before step that names the conversation log (the token
#     "conversational-logs" AND the imperative "read") before drafting/replying
#   - an APPEND-after step (the imperative "append") that writes the inbound +
#     reply back to the conversation log
#
# Exit codes: 0 = all server-mapping templates carry the read-before AND
#                 append-after conversation-memory steps;
#             1 = one or more violations (missing element, or installer template
#                 missing/lacking the steps);
#             2 = no server-mapping templates found (the scan target moved — the
#                 linter went blind; treated as FAILURE).
#
# Usage:
#   bash scripts/qc-conversation-memory.sh                 # human output
#   bash scripts/qc-conversation-memory.sh --json          # machine output
#   bash scripts/qc-conversation-memory.sh --skill-dir /path/to/38-conversational-ai-system
#
# Implementation note: PURE BASH (awk/grep/sed), no python — qc-static.yml's
# Python-syntax + anthropic-string scans key off .py files, and BASH keeps this
# gate trivially CI-portable.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
JSON_MODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --skill-dir) SKILL_DIR="$2"; shift 2 ;;
    --json) JSON_MODE=1; shift ;;
    -h|--help) sed -n '1,72p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

SCAN_DIRS=("references" "templates" "scripts")

# The canonical server-mapping (object B) signature. The installer + the v6.0
# playbook open the server template with this exact phrase.
SERVER_SIGNATURE="INBOUND MESSAGE FROM GOHIGHLEVEL"

# The installer file whose written messageTemplate MUST carry the steps.
INSTALLER_REL="scripts/15-configure-hooks-mappings.sh"

# ── Counters / accumulators ──────────────────────────────────────────────────
server_templates=0
installer_seen=0
installer_ok=0
violations=0
# Lines of human output buffered so the summary can precede details if needed.
declare -a REPORT_LINES=()
declare -a VIOLATION_FILES=()

# Extract every messageTemplate VALUE from a file. Mirrors the proven
# qc-send-directive.sh regex `"?messageTemplate"?\s*:\s*"((?:[^"\\]|\\.)*)"` —
# the key "messageTemplate" must be IMMEDIATELY followed (only an optional
# closing quote + whitespace) by a colon, then whitespace, then the opening
# quote of the value. This adjacency requirement is what prevents the bare word
# "messageTemplate" in prose/comments (e.g. inside the QC scripts themselves)
# from being mis-parsed as a template. Handles JSON / jq style:
#   "messageTemplate": "...."   or   messageTemplate:"...."
# Emits each value on its own NUL-delimited record so embedded newlines/quotes
# survive. Single-pass awk tokenizer over the whole file.
extract_templates() {
  # $1 = file path; prints each messageTemplate value followed by a NUL byte.
  awk '
    { lines[NR] = $0 }
    END {
      # Reconstruct the full text with real newlines between lines.
      text = ""
      for (i = 1; i <= NR; i++) text = text lines[i] "\n"
      n = length(text)
      i = 1
      while (i <= n) {
        idx = index(substr(text, i), "messageTemplate")
        if (idx == 0) break
        pos = i + idx - 1 + length("messageTemplate")   # 1-based char AFTER the key
        rest = substr(text, pos)
        # Require: ["]? \s* : \s* " — strictly adjacent, no skipping over text.
        k = 1
        rn = length(rest)
        # optional single closing quote of the key
        if (substr(rest, k, 1) == "\"") k++
        # optional whitespace
        while (k <= rn && (substr(rest, k, 1) == " " || substr(rest, k, 1) == "\t")) k++
        # MUST be a colon now, else this is not a key:value form
        if (substr(rest, k, 1) != ":") { i = pos; continue }
        k++
        # optional whitespace after colon
        while (k <= rn && (substr(rest, k, 1) == " " || substr(rest, k, 1) == "\t" || substr(rest, k, 1) == "\n")) k++
        # MUST be the opening quote of the value
        if (substr(rest, k, 1) != "\"") { i = pos; continue }
        k++   # now at first char of value
        # Scan for the closing unescaped double-quote.
        out = ""
        while (k <= rn) {
          ch = substr(rest, k, 1)
          if (ch == "\\") { out = out substr(rest, k, 2); k += 2; continue }
          if (ch == "\"") break
          out = out ch
          k++
        }
        printf "%s%c", out, 0
        i = pos + k        # advance past this value
      }
    }
  ' "$1"
}

contains_ci() {
  # $1 = haystack, $2 = needle (literal). Case-insensitive substring test.
  local hay low_hay low_needle
  hay="$1"
  low_hay="$(printf '%s' "$hay" | tr '[:upper:]' '[:lower:]')"
  low_needle="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"
  case "$low_hay" in
    *"$low_needle"*) return 0 ;;
    *) return 1 ;;
  esac
}

check_memory() {
  # $1 = template value. Echoes a space-prefixed list of missing-element labels;
  # empty echo == both steps present.
  local t="$1" missing=""
  # READ-before step: names the log dir AND uses the imperative "read".
  if ! contains_ci "$t" "conversational-logs"; then
    missing="$missing|missing the conversation-log path (\"conversational-logs/<contact_id>\")"
  fi
  if ! contains_ci "$t" "read"; then
    missing="$missing|missing the READ-before step (\"read ... conversation log\" before replying)"
  fi
  # APPEND-after step.
  if ! contains_ci "$t" "append"; then
    missing="$missing|missing the APPEND-after step (\"append ... to the conversation log\" after sending)"
  fi
  printf '%s' "$missing"
}

# ── Scan ─────────────────────────────────────────────────────────────────────
for sub in "${SCAN_DIRS[@]}"; do
  d="$SKILL_DIR/$sub"
  [ -d "$d" ] || continue
  while IFS= read -r -d '' f; do
    case "$f" in
      *.md|*.sh|*.txt) : ;;
      *) continue ;;
    esac
    rel="${f#$SKILL_DIR/}"
    is_installer=0
    [ "$rel" = "$INSTALLER_REL" ] && is_installer=1
    # Read every messageTemplate value in this file.
    while IFS= read -r -d '' val; do
      # Only the SERVER-mapping inbound templates carry the signature.
      contains_ci "$val" "$SERVER_SIGNATURE" || continue
      server_templates=$((server_templates + 1))
      miss="$(check_memory "$val")"
      if [ "$is_installer" -eq 1 ]; then
        installer_seen=1
        [ -z "$miss" ] && installer_ok=1
      fi
      if [ -n "$miss" ]; then
        violations=$((violations + 1))
        VIOLATION_FILES+=("$rel")
        REPORT_LINES+=("  [FAIL] $rel ($([ "$is_installer" -eq 1 ] && echo installer || echo reference) server template)")
        IFS='|' read -r -a parts <<< "${miss#|}"
        for p in "${parts[@]}"; do
          [ -n "$p" ] && REPORT_LINES+=("          - $p")
        done
      else
        REPORT_LINES+=("  [PASS] $rel ($([ "$is_installer" -eq 1 ] && echo installer || echo reference) server template)")
      fi
    done < <(extract_templates "$f")
  done < <(find "$d" -type f -print0 2>/dev/null)
done

# ── Installer hard requirement ───────────────────────────────────────────────
installer_error=""
if [ "$installer_seen" -ne 1 ]; then
  installer_error="INSTALLER GATE FAILED: no server-mapping messageTemplate found in ${INSTALLER_REL} (the canonical template the installer writes is missing or no longer matches the '${SERVER_SIGNATURE}' signature)."
elif [ "$installer_ok" -ne 1 ]; then
  installer_error="INSTALLER GATE FAILED: ${INSTALLER_REL} writes a server-mapping messageTemplate that lacks the conversation-memory read-before and/or append-after steps."
fi

failed=0
[ "$violations" -gt 0 ] && failed=1
[ "$server_templates" -eq 0 ] && failed=1
[ -n "$installer_error" ] && failed=1

# ── Output ───────────────────────────────────────────────────────────────────
if [ "$JSON_MODE" -eq 1 ]; then
  verdict="PASS"
  if [ "$server_templates" -eq 0 ]; then
    verdict="NO_TEMPLATES"
  elif [ "$failed" -eq 1 ]; then
    verdict="FAIL"
  fi
  printf '{\n'
  printf '  "scanned_server_templates": %s,\n' "$server_templates"
  printf '  "installer_template_present": %s,\n' "$([ "$installer_seen" -eq 1 ] && echo true || echo false)"
  printf '  "installer_template_has_steps": %s,\n' "$([ "$installer_ok" -eq 1 ] && echo true || echo false)"
  printf '  "installer_error": %s,\n' "$([ -n "$installer_error" ] && printf '"%s"' "$installer_error" || echo null)"
  printf '  "violation_count": %s,\n' "$violations"
  printf '  "verdict": "%s"\n' "$verdict"
  printf '}\n'
else
  echo "=== qc-conversation-memory: GHL inbound conversation-MEMORY linter ==="
  echo "skill_dir : $SKILL_DIR"
  echo "scanned   : $server_templates server-mapping inbound messageTemplate(s)"
  echo "installer : $INSTALLER_REL ($([ "$installer_seen" -eq 1 ] && echo present || echo MISSING); $([ "$installer_ok" -eq 1 ] && echo 'read+append OK' || echo 'read/append ABSENT'))"
  echo ""
  for line in "${REPORT_LINES[@]}"; do
    echo "$line"
  done
  if [ -n "$installer_error" ]; then
    echo ""
    echo "  $installer_error"
  fi
  echo ""
  if [ "$server_templates" -eq 0 ]; then
    echo "RESULT: NO SERVER TEMPLATES FOUND — the scan target moved; the linter is blind. Treating as FAIL."
  elif [ "$failed" -eq 1 ]; then
    n=$violations
    [ -n "$installer_error" ] && n=$((n + 1))
    echo "RESULT: FAIL — $n conversation-memory violation(s). A hook session is single-turn; without read-before + append-after the agent has no memory. Fix the template(s)."
  else
    echo "RESULT: PASS — all $server_templates GHL server-mapping messageTemplate(s) carry the conversation-memory read-before AND append-after steps."
  fi
fi

if [ "$server_templates" -eq 0 ]; then
  exit 2
fi
[ "$failed" -eq 1 ] && exit 1
exit 0
