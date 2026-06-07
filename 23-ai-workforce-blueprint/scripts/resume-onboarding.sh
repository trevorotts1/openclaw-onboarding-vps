#!/usr/bin/env bash
# resume-onboarding.sh — autonomous install/wire/QC resume layer for onboarding
#
# v10.16.48 — FIX 1 (ONBOARDING HONESTY), modeled on resume-workforce-build.sh.
#
# WHY: install.sh copies skills + pastes prose; the agent is supposed to install,
# wire, and QC each skill from the AGENTS.md UPDATE PENDING flag. If that work
# dies mid-way (token limit, tool error, or the agent self-declaring "done"
# without verifying), the half-installed onboarding sits forever and the owner is
# told it succeeded. This cron reads .onboarding-state.json every 15 minutes and
# self-pings the agent to install/wire/QC any skill that is NOT yet verified-
# installed (status in pending|downloaded|wired|qc-failed).
#
# IT DOES NOT EXIT ON A SELF-DECLARED "done". The only terminal condition is the
# VERIFICATION GATE: every tracked skill is qc-passed OR interview-pending. A
# skill parked at interview-pending is a LEGITIMATE wait — we re-ping the OWNER
# on a slow backoff, we do NOT treat it as a failure or a terminal stop.
#
# Idempotent. 10-minute lockfile. NEVER-STOP run accounting + Rescue Rangers
# escalation (Rule 8), same shape as resume-workforce-build.sh.

set -u

# ---- platform detection (vps default; mac override) ----
if [[ -d /data/.openclaw ]]; then
  OC_ROOT=/data/.openclaw
elif [[ -d "$HOME/.openclaw" ]]; then
  OC_ROOT="$HOME/.openclaw"
else
  echo "[resume-onboarding] no OpenClaw root found; aborting" >&2
  exit 0
fi

STATE_FILE="$OC_ROOT/.onboarding-state.json"
LOCK_FILE="$OC_ROOT/.onboarding-resume.lock"
LOG_FILE="$OC_ROOT/.onboarding-resume.log"
RUN_COUNT_FILE="$OC_ROOT/.onboarding-resume-runs.count"
MAX_ATTEMPTS_DEFAULT=24
# NEVER-STOP: past this many fires we slow to ~2h backoff but do NOT self-remove
# on a run count. Only a REAL completion (verification gate) self-removes.
MAX_RUNS_BEFORE_BACKOFF=24

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG_FILE"; }

# ---- operator chat resolver (env -> config -> Trevor default) ----
resolve_operator_chat_id() {
  local v=""
  if command -v openclaw >/dev/null 2>&1; then
    v="$(openclaw config get env.vars.OPERATOR_TELEGRAM_CHAT_ID 2>/dev/null | tail -1 | tr -d '[:space:]')"
    case "$v" in ""|*"not found"*|*"Error"*) v="" ;; esac
  fi
  [[ -z "$v" && -n "${OPERATOR_TELEGRAM_CHAT_ID:-}" ]] && v="$OPERATOR_TELEGRAM_CHAT_ID"
  [[ -z "$v" && -n "${OPERATOR_HELP_CHAT_ID:-}" ]] && v="$OPERATOR_HELP_CHAT_ID"
  [[ -z "$v" && -n "${OPENCLAW_TREVOR_CHAT:-}" ]] && v="$OPENCLAW_TREVOR_CHAT"
  [[ -z "$v" ]] && v="5252140759"
  printf '%s' "$v"
}

find_self_cron_uuid() {
  command -v openclaw >/dev/null 2>&1 || { echo ""; return 0; }
  openclaw cron list 2>/dev/null \
    | awk '/onboarding-resume/ { for (i=1;i<=NF;i++) if ($i ~ /^[0-9a-fA-F-]{8,}$/) { print $i; exit } }' \
    | head -1
}

self_remove_cron() {
  local reason="$1" uuid
  uuid=$(find_self_cron_uuid)
  if [[ -z "$uuid" ]]; then
    log "self_remove_cron($reason): could not resolve onboarding-resume UUID — leaving cron in place"; return 0
  fi
  log "self_remove_cron($reason): removing cron $uuid"
  if openclaw cron rm "$uuid" 2>>"$LOG_FILE"; then
    log "self_remove_cron($reason): removed $uuid"; rm -f "$RUN_COUNT_FILE" 2>/dev/null || true
  else
    log "self_remove_cron($reason): openclaw cron rm $uuid FAILED"
  fi
}

# ---- preconditions ----
if [[ ! -f "$STATE_FILE" ]]; then
  log "no onboarding-state at $STATE_FILE — nothing to resume; exiting clean"; exit 0
fi
if ! command -v python3 >/dev/null 2>&1; then
  log "python3 not on PATH — cannot parse state; exiting"; exit 0
fi
if ! command -v openclaw >/dev/null 2>&1; then
  log "openclaw CLI not on PATH — cannot dispatch resume; exiting"; exit 0
fi

# ---- compute verification-gate status (NOT a self-declared 'done') ----
# Emits: VERIFIED|TOTAL|FAILED_CSV|PENDING_CSV|INTERVIEW_CSV
GATE=$(STATE_FILE="$STATE_FILE" python3 - <<'PYEOF' 2>/dev/null
import json, os
try: s=json.load(open(os.environ["STATE_FILE"]))
except Exception: print("0|0|||"); raise SystemExit
sk=s.get("skills",{})
verified=[k for k,v in sk.items() if v.get("status")=="qc-passed"]
failed=[k for k,v in sk.items() if v.get("status")=="qc-failed"]
interview=[k for k,v in sk.items() if v.get("status")=="interview-pending"]
pending=[k for k,v in sk.items() if v.get("status") in ("pending","downloaded","wired")]
print("%d|%d|%s|%s|%s"%(len(verified),len(sk),
      ",".join(sorted(failed)),",".join(sorted(pending)),",".join(sorted(interview))))
PYEOF
)
VERIFIED=$(printf '%s' "$GATE" | cut -d'|' -f1)
TOTAL=$(printf '%s' "$GATE" | cut -d'|' -f2)
FAILED_CSV=$(printf '%s' "$GATE" | cut -d'|' -f3)
PENDING_CSV=$(printf '%s' "$GATE" | cut -d'|' -f4)
INTERVIEW_CSV=$(printf '%s' "$GATE" | cut -d'|' -f5)
: "${VERIFIED:=0}" "${TOTAL:=0}"

# Anything that still needs install/wire/QC work:
NEEDS_WORK_CSV="$PENDING_CSV"
[[ -n "$FAILED_CSV" ]] && NEEDS_WORK_CSV="${NEEDS_WORK_CSV:+$NEEDS_WORK_CSV,}$FAILED_CSV"

# ---- TERMINAL (real completion only): all skills qc-passed or interview-pending ----
if (( TOTAL > 0 )) && [[ -z "$NEEDS_WORK_CSV" ]]; then
  if [[ -n "$INTERVIEW_CSV" ]]; then
    # Not a stop: a legitimate interview park. Re-ping owner on slow backoff,
    # keep the cron alive so when the owner answers, the gated skills finish.
    log "GATE: all non-interview skills verified ($VERIFIED/$TOTAL). INTERVIEW-PENDING: $INTERVIEW_CSV — re-pinging owner on backoff; NOT self-removing."
  else
    log "GATE: ALL $TOTAL skills verified-installed (qc-passed). Onboarding genuinely complete — self-removing cron."
    self_remove_cron "verification-gate-passed"
    exit 0
  fi
fi

# ---- NEVER-STOP run accounting (Rule 8) ----
mkdir -p "$(dirname "$RUN_COUNT_FILE")" 2>/dev/null || true
_run_count=0
[[ -f "$RUN_COUNT_FILE" ]] && _run_count=$(cat "$RUN_COUNT_FILE" 2>/dev/null | tr -dc '0-9' | head -c 6)
[[ -z "$_run_count" ]] && _run_count=0
_run_count=$((_run_count + 1))
echo "$_run_count" > "$RUN_COUNT_FILE" 2>/dev/null || true

_backoff_skip=0
if (( _run_count > MAX_RUNS_BEFORE_BACKOFF )); then
  _over=$(( _run_count - MAX_RUNS_BEFORE_BACKOFF ))
  if (( _over % 8 != 1 )); then
    log "NEVER-STOP: run #$_run_count past cap — 2h-backoff slow mode, skipping this fire. NOT self-removing."
    exit 0
  fi
  log "NEVER-STOP: run #$_run_count past cap — slow-retry fire; escalating to Rescue Rangers (once)."
  _already=$(STATE_FILE="$STATE_FILE" python3 -c "import json,os;print(json.load(open(os.environ['STATE_FILE'])).get('rescueRangersEscalated',False))" 2>/dev/null)
  if [[ "$_already" != "True" ]]; then
    # Escalate via the n8n Rescue Rangers webhook (NOT bot-to-bot Telegram —
    # bots can't read other bots, so the old group post never reached the rescue agent).
    _rr_webhook="${RESCUE_RANGERS_WEBHOOK_URL:-https://main.blackceoautomations.com/webhook/rescue-rangers}"
    if [[ -n "$_rr_webhook" ]] && command -v curl >/dev/null 2>&1; then
      _rr_msg="onboarding-resume on $(hostname) ran $_run_count times without all skills verified-installed. Verified $VERIFIED/$TOTAL. Failed: ${FAILED_CSV:-none}. Pending: ${PENDING_CSV:-none}. Now in 2h-backoff slow-retry (NOT stopped — Rule 8). State: $STATE_FILE. OpenClaw version: $(openclaw --version 2>/dev/null | head -1)"
      # JSON-encode via python (this script does not assume jq is present).
      _rr_payload=$(RR_HOST="$(hostname)" RR_MSG="$_rr_msg" python3 -c 'import json,os;print(json.dumps({"action":"escalate","client":os.environ["RR_HOST"],"agent":"main","message":os.environ["RR_MSG"]}))' 2>/dev/null)
      curl -s -X POST "$_rr_webhook" -H "Content-Type: application/json" -d "$_rr_payload" >>"$LOG_FILE" 2>&1 || true
    fi
    _op="$(resolve_operator_chat_id)"
    [[ -n "$_op" ]] && openclaw message send --channel telegram -t "$_op" \
      -m "⚠️ onboarding-resume on $(hostname) hit $_run_count runs without finishing. Verified $VERIFIED/$TOTAL skills. Failed: ${FAILED_CSV:-none}. Switched to 2h-backoff slow-retry; it KEEPS retrying until the verification gate passes (it does NOT stop). State: $STATE_FILE" 2>>"$LOG_FILE" || true
    STATE_FILE="$STATE_FILE" python3 - <<'PYEOF' 2>/dev/null || true
import json,os
sf=os.environ["STATE_FILE"]
try: s=json.load(open(sf))
except Exception: raise SystemExit
s["rescueRangersEscalated"]=True
json.dump(s,open(sf,"w"),indent=2)
PYEOF
  fi
fi

# ---- heal config before any gateway interaction ----
openclaw doctor --fix >/dev/null 2>&1 || true

# ---- lock (prevent concurrent self-pings) ----
if [[ -f "$LOCK_FILE" ]]; then
  lock_mtime=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)
  now=$(date +%s); lock_age=$(( now - lock_mtime ))
  if (( lock_age < 600 )); then
    log "lock held for ${lock_age}s (< 600s) — another resume in flight; exiting"; exit 0
  fi
  log "stale lock (age ${lock_age}s) — clearing"
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# ---- resolve target chat (owner preferred; operator fallback) ----
OWNER_CHAT=$(STATE_FILE="$STATE_FILE" python3 -c "import json,os;print(json.load(open(os.environ['STATE_FILE'])).get('ownerChat','') or '')" 2>/dev/null)
if [[ -n "$OWNER_CHAT" && "$OWNER_CHAT" != "null" ]]; then
  TARGET_CHAT="$OWNER_CHAT"
else
  TARGET_CHAT="$(resolve_operator_chat_id)"
fi
[[ -z "$TARGET_CHAT" ]] && { log "no usable target chat — cannot dispatch resume"; exit 0; }

# ---- compose + dispatch ----
if [[ -z "$NEEDS_WORK_CSV" && -n "$INTERVIEW_CSV" ]]; then
  # Owner-facing nudge for the interview that is genuinely blocking completion.
  msg="[ONBOARDING — your input needed] Your AI workforce is ready to finish setup, but it's waiting on you for: ${INTERVIEW_CSV//,/, }. When you have ~35 focused minutes, reply 'ready' and we'll do the business interview that shapes your whole team. (This is the only thing standing between you and a fully verified install.)"
  log "INTERVIEW re-ping to $TARGET_CHAT (interview=$INTERVIEW_CSV, verified=$VERIFIED/$TOTAL)"
else
  msg="[ONBOARDING-RESUME] The onboarding is NOT yet verified-complete. Verified-installed: $VERIFIED/$TOTAL. Still needs install/wire/QC: ${NEEDS_WORK_CSV:-none}. ${INTERVIEW_CSV:+(Parked on owner interview, do NOT auto-complete: $INTERVIEW_CSV.) }DO THIS for EACH skill listed in 'needs work': (1) read EVERY file in /data/.openclaw/skills/<skill>/ (SKILL.md, INSTALL.md, INSTRUCTIONS.md, CORE_UPDATES.md, QC.md); (2) execute its INSTALL.md / shell installers; (3) merge its CORE_UPDATES.md into workspace AGENTS.md/TOOLS.md/MEMORY.md/SOUL.md (idempotent — check sentinel first); (4) run its qc-*.sh until it EXITS 0; (5) confirm 'openclaw skills info <registered-name>' shows it Ready. Update /data/.openclaw/.onboarding-state.json: set that skill's status to qc-passed ONLY when registration + CORE_UPDATES sentinel + qc-*.sh(exit 0) all hold — otherwise qc-failed. NEVER report 'installed' or 'done' for a skill that is not qc-passed. Do NOT message the owner about this — the resume is internal. This cron keeps firing until the verification gate passes; a self-declared 'done' does not stop it."
  log "RESUME dispatch to $TARGET_CHAT (needs_work=$NEEDS_WORK_CSV; verified=$VERIFIED/$TOTAL; interview=$INTERVIEW_CSV)"
fi

if openclaw message send --channel telegram -t "$TARGET_CHAT" -m "$msg" 2>>"$LOG_FILE"; then
  log "resume dispatch ok"
else
  log "resume dispatch FAILED — see errors above"
fi
exit 0
