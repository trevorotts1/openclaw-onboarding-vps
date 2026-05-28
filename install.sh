#!/usr/bin/env bash

# ============================================================
#  OpenClaw Onboarding Installer v10.14.0 — Hostinger Docker VPS
#  Run via: curl -fSL --progress-bar https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash
#
#  This installer is for the Hostinger Docker VPS deployment of OpenClaw.
#  It is NOT cross-platform. The Mac mini installer lives at:
#    https://github.com/trevorotts1/openclaw-onboarding
#
#  Canonical paths (per Hostinger /hostinger/server.mjs entrypoint):
#    /data/.openclaw/                   — config root
#    /data/.openclaw/openclaw.json      — main config
#    /data/.openclaw/workspace/         — agent workspace
#    /data/.openclaw/credentials/       — channel allowlists + pairing
#    /data/.openclaw/agents/main/agent/auth-profiles.json  — per-agent creds
#    /data/.openclaw/skills/            — skills install dir
#    /data/.openclaw/logs/              — audit + activity logs
#    /data/.openclaw/backups/           — install + config backups
#
#  Credential discovery: container env vars (printenv) +
#    /data/.openclaw/openclaw.json (models.providers.*.apiKey, env.vars block) +
#    /data/.openclaw/agents/main/agent/auth-profiles.json. No .env files.
# ============================================================

# ============================================================
# v10.14.0 — Hostinger Docker host auto-detect + container re-exec
# ============================================================
# DO NOT enable `set -euo pipefail` before this block. The auto-detect
# uses conditional commands that may fail (docker missing, no container)
# and that's fine — we want those to fall through silently, not abort.
#
# Why: Hostinger's Docker-Manager-deployed OpenClaw runs entirely INSIDE
# a container. The host has no /data, no openclaw CLI, no node/pip3. If
# this installer is run on the host (the documented "ssh + curl | bash"
# path), it would `mkdir -p /data/.openclaw` on the host root filesystem
# — a directory the container can't see — and silently land the entire
# install in the wrong place. This block detects that scenario and
# re-executes inside the container as the right user.
#
# Detection — ALL three must hold to trigger the re-exec:
#   1. /data does NOT exist on host filesystem
#   2. `docker` command IS available
#   3. At least one running container has "openclaw" in its name
#
# If any condition fails, the script falls through to the normal path
# (bare-metal VPS where the user is already on /data, or running INSIDE
# the container directly).
#
# Overrides:
#   OPENCLAW_NO_CONTAINER_REEXEC=1   — disable auto-detect entirely
#   OPENCLAW_CONTAINER_NAME=<name>   — specify a particular container
#   OPENCLAW_CONTAINER_USER=<user>   — specify the user to exec as
# ============================================================
if [ -z "${OPENCLAW_NO_CONTAINER_REEXEC:-}" ] \
   && [ ! -d /data ] \
   && command -v docker >/dev/null 2>&1; then

    _oc_container="${OPENCLAW_CONTAINER_NAME:-}"
    if [ -z "$_oc_container" ]; then
        # v10.14.1: detect multi-container false positives.
        # If more than one running container matches "openclaw", refuse to
        # guess and require OPENCLAW_CONTAINER_NAME=<name> to disambiguate.
        _oc_matches=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -E 'openclaw' || true)
        _oc_match_count=$(printf '%s\n' "$_oc_matches" | grep -c '.' || true)
        if [ "${_oc_match_count:-0}" -gt 1 ]; then
            echo "" >&2
            echo "ERROR: Multiple running OpenClaw containers detected on this host:" >&2
            printf '%s\n' "$_oc_matches" | sed 's/^/  - /' >&2
            echo "" >&2
            echo "Cannot auto-pick — would silently install into the wrong one." >&2
            echo "Re-run with the container name explicit:" >&2
            echo "  OPENCLAW_CONTAINER_NAME=<name-from-list-above> \\" >&2
            echo "    curl -fSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash" >&2
            exit 1
        fi
        _oc_container=$(printf '%s\n' "$_oc_matches" | head -1)
    fi

    if [ -n "$_oc_container" ] && docker ps --format '{{.Names}}' 2>/dev/null | grep -qF "$_oc_container"; then
        _oc_user="${OPENCLAW_CONTAINER_USER:-}"
        if [ -z "$_oc_user" ]; then
            _oc_user=$(docker inspect "$_oc_container" --format '{{.Config.User}}' 2>/dev/null)
            [ -z "$_oc_user" ] && _oc_user="node"
        fi

        echo ""
        echo "════════════════════════════════════════════════════════════"
        echo "  Hostinger Docker host detected — re-executing inside container"
        echo "════════════════════════════════════════════════════════════"
        echo "  Container: $_oc_container"
        echo "  User:      $_oc_user"
        echo "  Reason:    /data lives inside this container, not on the host."
        echo "             Installing on host would silently land in the wrong"
        echo "             place (host /data/.openclaw is invisible to the"
        echo "             OpenClaw runtime, which only sees its bind mount)."
        echo "  Overrides: OPENCLAW_NO_CONTAINER_REEXEC=1   — skip auto-detect entirely"
        echo "             OPENCLAW_CONTAINER_NAME=<name>   — target a different container"
        echo "             OPENCLAW_CONTAINER_USER=<user>   — exec as a different user"
        echo "════════════════════════════════════════════════════════════"
        echo ""

        # v10.14.6: Hostinger image baseline pre-installs openclaw at
        # /usr/local/bin/openclaw (pinned to whatever version was current at
        # image build time — often older than the gateway runtime). Then
        # NPM_CONFIG_PREFIX=/data/.npm-global means later `npm install -g`
        # calls put a newer CLI at /data/.npm-global/bin/openclaw. Result:
        # two CLI installations at different versions. PATH puts the new one
        # first so `openclaw` from a shell prompt is correct, but anything
        # that hardcodes /usr/local/bin/openclaw or uses npx with the wrong
        # package cache hits the stale one and gets "protocol mismatch"
        # rejected by the gateway. This silently breaks `openclaw cron
        # create` (Step 12), `openclaw message send` (Step 10/11), and any
        # skill that hardcodes /usr/local paths.
        #
        # Fix: detect + remove the stale /usr/local CLI BEFORE the install
        # runs. Must run as root (the OLD CLI is in root-owned paths). Done
        # here in the host-side auto-detect, as a separate `docker exec -u
        # root` step before the node-user install re-exec. Backs up to
        # /data/.openclaw/backups/cli-cleanup-<ts>/ for rollback.
        #
        # See INSTALL-GOTCHAS.md #13.
        docker exec -u root "$_oc_container" sh -c '
OLD=/usr/local/bin/openclaw
NEW=/data/.npm-global/bin/openclaw
if [ -e "$OLD" ] && [ -e "$NEW" ]; then
    OLD_VER=$("$OLD" --version 2>&1 | head -1)
    NEW_VER=$("$NEW" --version 2>&1 | head -1)
    if [ "$OLD_VER" != "$NEW_VER" ]; then
        echo "[install] CLI dual-install mismatch detected (Hostinger image baseline)" >&2
        echo "[install]   stale:   $OLD_VER at $OLD" >&2
        echo "[install]   current: $NEW_VER at $NEW (matches gateway)" >&2
        TS=$(date +%Y%m%d-%H%M%S)
        BAK=/data/.openclaw/backups/cli-cleanup-$TS
        mkdir -p "$BAK"
        cp -a "$OLD" "$BAK/openclaw.symlink" 2>/dev/null || true
        cp -a /usr/local/lib/node_modules/openclaw "$BAK/" 2>/dev/null || true
        rm -f "$OLD"
        rm -rf /usr/local/lib/node_modules/openclaw
        echo "[install] Removed stale CLI; backup at $BAK" >&2
    fi
fi
' 2>&1 || true

        # Re-fetch from GitHub inside the container. Inside, /data exists
        # so this same script's auto-detect will fall through and the
        # normal install path runs. Pass -i so any interactive prompts
        # (credential discovery, etc.) still work through the SSH session.
        # v10.14.10: forward OPENCLAW_* env vars from host SSH session into
        # the container so shared operator secrets (Podbean app credentials
        # etc.) reach inject_shared_operator_secrets after re-exec.
        # docker exec -e VAR (no value) reads VAR from the calling process's env.
        exec docker exec -i -u "$_oc_user" \
            -e OPENCLAW_OWNER_NAME \
            -e OPENCLAW_PODBEAN_CLIENT_ID \
            -e OPENCLAW_PODBEAN_CLIENT_SECRET \
            "$_oc_container" bash -c \
            "curl -fSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash"
    fi
fi

# v10.14.1: Pre-flight disk space check. Runs once we're confirmed to be
# in the right place (either inside the container or on a bare-metal VPS
# with /data already provisioned). Install needs ~2-3 GB minimum:
#   - 36 skill folders + onboarding metadata (~200 MB)
#   - Calibre via Linuxbrew (~500 MB-1 GB depending on deps cache state)
#   - google-genai + numpy + pdfplumber + other Python pkgs (~500 MB)
#   - Workspace + master-files copies (~200 MB)
#   - Headroom for log rotation, backups, build artifacts
# Refuse to start the install if less than 5 GB free — better to fail
# fast with a clear message than fail mid-Calibre with confusing errors.
if [ -d /data ]; then
    _free_kb=$(df -k /data 2>/dev/null | awk 'NR==2 {print $4}')
    if [ -n "${_free_kb:-}" ] && [ "$_free_kb" -lt 5242880 ]; then
        _free_mb=$((_free_kb / 1024))
        echo "ERROR: /data has only ${_free_mb} MB free." >&2
        echo "       This installer requires at least 5 GB free for skills + Calibre +" >&2
        echo "       Python packages. Free up space (clean up logs/backups in" >&2
        echo "       /data/.openclaw/backups/) or upgrade the VPS plan, then retry." >&2
        echo "" >&2
        echo "       Check: df -h /data" >&2
        exit 1
    fi
fi

# Safety belt: if we're still on a Docker host without /data AND an
# OpenClaw container exists but the auto-detect re-exec didn't happen
# (e.g., docker exec failed, or container is paused), HARD FAIL rather
# than silently installing to host /data/.openclaw.
if [ ! -d /data ] && command -v docker >/dev/null 2>&1 \
   && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qE 'openclaw'; then
    echo "ERROR: An OpenClaw container is configured on this host but the" >&2
    echo "       auto-detect re-exec did not complete. Refusing to install" >&2
    echo "       to host /data/.openclaw (the container cannot see it)." >&2
    echo "" >&2
    echo "       Diagnose: docker ps -a | grep openclaw" >&2
    echo "       Then either start the container and re-run, or run manually:" >&2
    echo "         docker exec -u node -i <container> bash -c \\" >&2
    echo "           'curl -fSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash'" >&2
    exit 1
fi

# v10.14.5: Pre-flight openclaw.json schema validation. Catches schema
# violations BEFORE Step 10/11/12 (which call `openclaw config get` and
# `openclaw cron list` — both validate config and exit non-zero if invalid).
# Previously a schema violation would silently crash the install mid-Step 10
# because `set -euo pipefail` propagates the CLI's non-zero exit. Now we
# detect the problem up front and tell the operator exactly how to fix it.
#
# Common schema violations we've seen:
#   - meta.ownerName added (meta is closed-schema; use channel-metadata.json
#     sidecar at /data/.openclaw/channel-metadata.json instead)
#   - channels.telegram.botName / .botUsername added (channels.telegram is
#     closed-schema; use channel-metadata.json sidecar instead)
#
# See INSTALL-GOTCHAS.md #6 and #11 for the full sidecar pattern.
if [ -f /data/.openclaw/openclaw.json ] && command -v openclaw >/dev/null 2>&1; then
    if ! _validate_out=$(openclaw config validate 2>&1); then
        echo "ERROR: /data/.openclaw/openclaw.json is invalid before install starts." >&2
        echo "       The install will fail mid-Step 10 if we proceed." >&2
        echo "" >&2
        echo "       Validator output:" >&2
        printf '         %s\n' "$_validate_out" | sed 's/^/         /' | head -10 >&2
        echo "" >&2
        echo "       Most likely cause: a custom key was added to meta.* or" >&2
        echo "       channels.telegram (both blocks are schema-strict)." >&2
        echo "       Fix: move owner/bot identity metadata to the sidecar at" >&2
        echo "         /data/.openclaw/channel-metadata.json" >&2
        echo "       See: $skills_dir/INSTALL-GOTCHAS.md (gotchas #6, #11)" >&2
        echo "       Or:   openclaw doctor --fix" >&2
        exit 1
    fi
fi

# v10.14.3: Pre-flight prereq check. Hard-fail if curl or python3 missing
# (these are mandatory — every fallback path in this installer relies on
# one or both). Soft-warn for unzip/wget/lsof which have built-in fallbacks
# documented in INSTALL-GOTCHAS.md. Runs after auto-detect re-exec so we
# check INSIDE the container (where the install actually happens), not on
# the bare-metal host.
for _required in curl python3; do
    command -v "$_required" >/dev/null 2>&1 || {
        echo "ERROR: $_required is required but not installed." >&2
        echo "       This installer cannot proceed without it." >&2
        echo "       Hostinger Docker containers ship with curl + python3 by default;" >&2
        echo "       if you see this error, the container has been heavily modified." >&2
        exit 1
    }
done

# Soft prereqs — present a single advisory line listing any missing
# helpers; install.sh has fallbacks for each. See INSTALL-GOTCHAS.md.
_missing_soft=""
for _soft in unzip wget lsof; do
    if ! command -v "$_soft" >/dev/null 2>&1; then
        _missing_soft="${_missing_soft}${_soft} "
    fi
done
if [ -n "$_missing_soft" ]; then
    echo "[install] Soft prereqs missing: ${_missing_soft}— using fallbacks (see INSTALL-GOTCHAS.md)" >&2
fi

set -euo pipefail

ONBOARDING_VERSION="v10.16.3"

# ----------------------------------------------------------
# Shared library — source if available (best-effort, never required).
# Provides detect_platform(), find_master_files(), and other helpers
# used by update-skills.sh / check-updates.sh / skills' QC scripts.
# Falls back to inlined definitions below if the file isn't present
# yet (e.g. first-time install before the repo has been cloned).
# ----------------------------------------------------------
_lib_shared_self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-shared.sh"
if [ -f "$_lib_shared_self" ]; then
  # shellcheck source=/dev/null
  source "$_lib_shared_self"
  export OPENCLAW_LIB_SHARED_SOURCED=1
fi

# ----------------------------------------------------------
# VPS canonical paths (hardcoded — no platform detect)
# ----------------------------------------------------------
OC_CONFIG="/data/.openclaw"
OC_JSON="/data/.openclaw/openclaw.json"
OC_SECRETS_ENV="/data/.openclaw/secrets/.env"
OC_WORKSPACE_DEFAULT="/data/.openclaw/workspace"
OC_CREDENTIALS="/data/.openclaw/credentials"
OC_AGENTS="/data/.openclaw/agents"
OC_SKILLS_DIR="/data/.openclaw/skills"
OC_LOGS="/data/.openclaw/logs"
OC_BACKUPS="/data/.openclaw/backups"
OC_INSTALL_LOG_DIR="/data/.openclaw/logs/install"
OC_AUTH_PROFILES="/data/.openclaw/agents/main/agent/auth-profiles.json"

# v10.10.0 P0-008: This installer is for Hostinger Docker VPS, but it should
# create $OC_CONFIG on a clean container instead of hard-failing. The hard
# fail used to assume the container provisioner created /data/.openclaw/
# before this script ran — that's not a safe assumption for fresh containers.
#
# Pre-flight check: is this a Mac (Darwin)? If yes, refuse and redirect to
# the Mac installer. Otherwise, create the dirs and proceed.
if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
    echo "ERROR: This is the VPS installer running on a Mac." >&2
    echo "Mac users: use https://github.com/trevorotts1/openclaw-onboarding" >&2
    exit 1
fi

# Auto-provision the OpenClaw config root + supporting directories on a
# clean Hostinger Docker container. Idempotent — safe to re-run.
if [ ! -d "$OC_CONFIG" ]; then
    echo "[install] $OC_CONFIG missing — auto-provisioning for clean VPS install"
    mkdir -p "$OC_CONFIG" "$OC_CONFIG/credentials" "$OC_CONFIG/agents/main/agent" \
             "$OC_CONFIG/skills" "$OC_CONFIG/logs" "$OC_CONFIG/backups" \
             "$OC_CONFIG/master-files" "$OC_CONFIG/secrets" 2>/dev/null || {
        echo "ERROR: Could not create $OC_CONFIG. Check filesystem permissions." >&2
        echo "Hostinger Docker should mount /data as writable for the container's user." >&2
        exit 1
    }
    echo "[install] Auto-provisioned: $OC_CONFIG and supporting dirs"
fi

# Workspace too — required by the installer's later steps and the runtime
mkdir -p "$OC_WORKSPACE_DEFAULT" 2>/dev/null

mkdir -p "$OC_BACKUPS" "$OC_INSTALL_LOG_DIR"

# Durable log location (v10.0.2): /tmp can be wiped on container rebuild.
# Persist install logs on the /data volume so they survive container restarts
# and can be referenced when reporting issues.
LOG_FILE="$OC_INSTALL_LOG_DIR/openclaw-install-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

# ----------------------------------------------------------
# Bash 3.2 Compatible UI Helpers
# ----------------------------------------------------------
step() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

success() {
    echo "  ✓ $1"
}

note() {
    echo "  ℹ️  $1"
}

warn() {
    echo "  ⚠️  $1"
}

error() {
    echo ""
    echo "  ✗ ERROR: $1"
    echo ""
}

# ----------------------------------------------------------
# Bash 3.2 Compatible Arrays (Indexed only)
# ----------------------------------------------------------
SKILLS_INSTALLED=""
SKILLS_UPDATED=""
SKILLS_SKIPPED=""
SKILL_COUNT=0

add_to_list() {
    local list_name="$1"
    local item="$2"
    case "$list_name" in
        installed) SKILLS_INSTALLED="$SKILLS_INSTALLED|$item" ;;
        updated) SKILLS_UPDATED="$SKILLS_UPDATED|$item" ;;
        skipped) SKILLS_SKIPPED="$SKILLS_SKIPPED|$item" ;;
    esac
}

count_list() {
    local list="$1"
    list="${list#|}"
    if [ -z "$list" ]; then
        echo "0"
    else
        echo "$list" | tr '|' '\n' | wc -l | tr -d ' '
    fi
}

# ----------------------------------------------------------
# Bulletproof VPS Telegram chat ID resolver (v10.0.0)
# ----------------------------------------------------------
# Hostinger Docker VPS canonical pairing always succeeds — clients never reach
# install without Telegram already paired. So if we DON'T find a chat ID, it's
# because we didn't look in the right place. This resolver searches 14
# locations in priority order, stops at first hit, logs which source matched.
#
# Tier 1 — canonical pairing records (where Hostinger's auto-pairing writes):
#   1. openclaw config get commands.ownerAllowFrom        (docs-canonical primary)
#   2. /data/.openclaw/credentials/telegram-*-allowFrom.json glob
#   3. /data/.openclaw/credentials/telegram-pairing.json  (pending+recent)
# Tier 2 — alternate schema locations:
#   4. openclaw config get channels.telegram.allowFrom
#   5. openclaw config get channels.telegram.groupAllowFrom
#   6. openclaw config get commands.allowFrom.telegram    (older schema)
#   7. openclaw config get plugins.entries.telegram.config.allowFrom
# Tier 3 — per-agent bindings:
#   8. agents.list[*].bindings.telegram.chatId in openclaw.json
#   9. agents.list[*].channels.telegram
# Tier 4 — runtime/CLI introspection:
#   10. openclaw channels telegram list / openclaw pairing list telegram
#   11. openclaw devices list --json paired entries
# Tier 5 — exhaustive last-resort:
#   12. Recursive walk of /data/.openclaw/ for any JSON with 6-20 digit numerics
#       under any telegram/chat/allow key
#   13. Container env vars: TELEGRAM_OWNER_ID, TELEGRAM_CHAT_ID, TG_CHAT_ID,
#       TELEGRAM_USER_ID, TELEGRAM_ALLOW_FROM
#   14. Audit log scan: /data/.openclaw/logs/*.jsonl for pairing.approved events
#
# Validation: chat ID must be 6-20 digits (optional leading -), must NOT be
# the bot's own ID (botToken prefix). Multi-account aware: account name
# comes from filename pattern or config block.

TELEGRAM_LAST_RESULT=""
TELEGRAM_TARGET_CACHED=""
TELEGRAM_ACCOUNT_CACHED=""
TELEGRAM_SOURCE_CACHED=""
TELEGRAM_RESOLVED=false

resolve_telegram_target_universal() {
    local result
    result=$(python3 - <<'PYEOF' 2>/dev/null
import json, os, glob, subprocess, re

OC_CONFIG = "/data/.openclaw"
OC_JSON = "/data/.openclaw/openclaw.json"
OC_CREDS = "/data/.openclaw/credentials"
OC_LOGS = "/data/.openclaw/logs"

def is_chat_id(v, bot_id=""):
    if not isinstance(v, (str, int)): return False
    s = str(v).strip().replace("telegram:", "").replace("tg:", "")
    if not s: return False
    digits = s.lstrip("-")
    if not (digits.isdigit() and 6 <= len(digits) <= 20): return False
    # Reject bot's own ID (would cause routing loop)
    if bot_id and s == bot_id: return False
    return s

def cli_get(path):
    try:
        r = subprocess.run(["openclaw", "config", "get", path],
                           capture_output=True, text=True, timeout=10)
        if r.returncode != 0 or not r.stdout.strip(): return None
        return r.stdout.strip()
    except Exception: return None

def parse_json_safe(s):
    try: return json.loads(s)
    except Exception: return None

# Load openclaw.json once for in-line strategies
cfg = {}
try:
    cfg = json.load(open(OC_JSON))
except Exception: pass

# Bot ID for validation — strip from botToken
bot_id = ""
bt = cfg.get("channels", {}).get("telegram", {}).get("botToken", "") or ""
if ":" in bt:
    bot_id = bt.split(":")[0]

result_chat = ""
result_account = ""
result_source = ""

def try_value(val, src, account_hint=""):
    global result_chat, result_account, result_source
    if result_chat: return
    if val is None: return
    cid = is_chat_id(val, bot_id)
    if cid:
        result_chat = cid
        result_account = account_hint
        result_source = src

def try_list(values, src, account_hint=""):
    if result_chat: return
    if not isinstance(values, list): return
    for v in values:
        cid = is_chat_id(v, bot_id)
        if cid:
            try_value(cid, src, account_hint); return

# ─── Strategy 1: commands.ownerAllowFrom (docs-canonical) ───
raw = cli_get("commands.ownerAllowFrom")
if raw:
    data = parse_json_safe(raw)
    if isinstance(data, list): try_list(data, "S1:commands.ownerAllowFrom (CLI)")
elif "ownerAllowFrom" in cfg.get("commands", {}):
    try_list(cfg["commands"]["ownerAllowFrom"], "S1:commands.ownerAllowFrom (json)")

# ─── Strategy 2: credentials/telegram-*-allowFrom.json ───
if not result_chat and os.path.isdir(OC_CREDS):
    try: fnames = sorted(os.listdir(OC_CREDS))
    except Exception: fnames = []
    # Prefer "default" account first
    fnames.sort(key=lambda f: ("default" not in f, f))
    for fname in fnames:
        m = re.match(r"^telegram-(.+)-allowFrom\.json$", fname)
        if not m: continue
        try: data = json.load(open(os.path.join(OC_CREDS, fname)))
        except Exception: continue
        try_list(data.get("allowFrom") or [], f"S2:credentials/{fname}", m.group(1))
        if result_chat: break

# ─── Strategy 3: credentials/telegram-pairing.json ───
if not result_chat:
    pp = os.path.join(OC_CREDS, "telegram-pairing.json")
    if os.path.isfile(pp):
        try: data = json.load(open(pp))
        except Exception: data = {}
        # Walk requests + any chat-id-ish fields
        def walk_pair(obj):
            if isinstance(obj, dict):
                for k, v in obj.items():
                    if "chat" in k.lower() or "user" in k.lower() or "owner" in k.lower():
                        cid = is_chat_id(v, bot_id)
                        if cid: return cid
                    r = walk_pair(v)
                    if r: return r
            elif isinstance(obj, list):
                for it in obj:
                    r = walk_pair(it)
                    if r: return r
            return None
        found = walk_pair(data)
        if found: try_value(found, "S3:credentials/telegram-pairing.json")

# ─── Strategy 4: channels.telegram.allowFrom ───
if not result_chat:
    raw = cli_get("channels.telegram.allowFrom")
    if raw:
        data = parse_json_safe(raw)
        if isinstance(data, list): try_list(data, "S4:channels.telegram.allowFrom (CLI)")
    if not result_chat:
        try_list(cfg.get("channels", {}).get("telegram", {}).get("allowFrom", []),
                 "S4:channels.telegram.allowFrom (json)")

# ─── Strategy 5: channels.telegram.groupAllowFrom ───
if not result_chat:
    try_list(cfg.get("channels", {}).get("telegram", {}).get("groupAllowFrom", []),
             "S5:channels.telegram.groupAllowFrom")

# ─── Strategy 6: commands.allowFrom.telegram (older schema) ───
if not result_chat:
    af = cfg.get("commands", {}).get("allowFrom", {})
    if isinstance(af, dict):
        try_list(af.get("telegram", []), "S6:commands.allowFrom.telegram")

# ─── Strategy 7: plugins.entries.telegram.config.allowFrom ───
if not result_chat:
    pte = cfg.get("plugins", {}).get("entries", {}).get("telegram", {})
    try_list(pte.get("config", {}).get("allowFrom", []),
             "S7:plugins.entries.telegram.config.allowFrom")

# ─── Strategy 8 + 9: per-agent bindings & channels ───
if not result_chat:
    for i, ag in enumerate(cfg.get("agents", {}).get("list", []) or []):
        if not isinstance(ag, dict): continue
        bind = (ag.get("bindings") or {}).get("telegram") or {}
        if isinstance(bind, dict):
            for key in ("chatId", "chatID", "userId", "id"):
                cid = is_chat_id(bind.get(key, ""), bot_id)
                if cid:
                    try_value(cid, f"S8:agents.list[{i}].bindings.telegram.{key}")
                    break
        if result_chat: break
        ch = (ag.get("channels") or {}).get("telegram") or {}
        if isinstance(ch, dict):
            for key in ("chatId", "userId", "allowFrom"):
                v = ch.get(key)
                if isinstance(v, list): try_list(v, f"S9:agents.list[{i}].channels.telegram.{key}")
                else:
                    cid = is_chat_id(v, bot_id)
                    if cid: try_value(cid, f"S9:agents.list[{i}].channels.telegram.{key}")
        if result_chat: break

# ─── Strategy 10: CLI live introspection ───
if not result_chat:
    for cmd in (["channels", "telegram", "list", "--json"],
                ["pairing", "list", "telegram", "--json"]):
        try:
            r = subprocess.run(["openclaw"] + cmd, capture_output=True, text=True, timeout=10)
            if r.returncode != 0: continue
            data = parse_json_safe(r.stdout) or []
            def walk_cmd(obj):
                if isinstance(obj, dict):
                    for k, v in obj.items():
                        if any(x in k.lower() for x in ("chat", "user", "owner", "allowfrom")):
                            cid = is_chat_id(v, bot_id)
                            if cid: return cid
                        r = walk_cmd(v)
                        if r: return r
                elif isinstance(obj, list):
                    for it in obj:
                        r = walk_cmd(it)
                        if r: return r
            found = walk_cmd(data)
            if found: try_value(found, f"S10:cli {' '.join(cmd)}")
            if result_chat: break
        except Exception: continue

# ─── Strategy 11: devices list paired entries ───
if not result_chat:
    try:
        r = subprocess.run(["openclaw", "devices", "list", "--json"],
                           capture_output=True, text=True, timeout=10)
        data = parse_json_safe(r.stdout) or {}
        for p in (data.get("paired") if isinstance(data, dict) else []) or []:
            for key in ("chatId", "telegramId", "userId", "chat"):
                cid = is_chat_id(p.get(key, ""), bot_id)
                if cid: try_value(cid, f"S11:devices.paired.{key}"); break
            if result_chat: break
    except Exception: pass

# ─── Strategy 12: exhaustive recursive walk of /data/.openclaw/ ───
if not result_chat:
    KEY_HINTS = ("telegram", "chat", "allowfrom", "owner", "user")
    def deep_walk(obj, under_tel=False):
        if isinstance(obj, dict):
            for k, v in obj.items():
                kl = str(k).lower()
                tel_branch = under_tel or "telegram" in kl
                key_hit = any(h in kl for h in KEY_HINTS)
                if (tel_branch or key_hit):
                    cid = is_chat_id(v, bot_id)
                    if cid: return cid
                    if isinstance(v, list):
                        for it in v:
                            cid = is_chat_id(it, bot_id)
                            if cid: return cid
                r = deep_walk(v, tel_branch)
                if r: return r
        elif isinstance(obj, list):
            for it in obj:
                r = deep_walk(it, under_tel)
                if r: return r
        return None
    # Walk every JSON under /data/.openclaw/ except node_modules/npm + workspace .git
    for root, dirs, files in os.walk(OC_CONFIG):
        dirs[:] = [d for d in dirs if d not in ("node_modules", "npm", ".git", "media", "logs")]
        for f in files:
            if not f.endswith(".json"): continue
            p = os.path.join(root, f)
            try: data = json.load(open(p))
            except Exception: continue
            found = deep_walk(data)
            if found:
                try_value(found, f"S12:walk:{os.path.relpath(p, OC_CONFIG)}")
                break
        if result_chat: break

# ─── Strategy 13: container env vars ───
if not result_chat:
    for var in ("TELEGRAM_OWNER_ID", "TELEGRAM_CHAT_ID", "TG_CHAT_ID",
                "TELEGRAM_USER_ID", "TELEGRAM_ALLOW_FROM"):
        v = (os.environ.get(var) or "").strip()
        if not v: continue
        cid = is_chat_id(v, bot_id)
        if cid: try_value(cid, f"S13:env.{var}"); break

# ─── Strategy 14: audit log scan ───
if not result_chat and os.path.isdir(OC_LOGS):
    for f in sorted(os.listdir(OC_LOGS), reverse=True):
        if not f.endswith(".jsonl"): continue
        try:
            for line in open(os.path.join(OC_LOGS, f)):
                if "pairing" in line.lower() and ("approved" in line.lower() or "accept" in line.lower()):
                    rec = parse_json_safe(line)
                    if not rec: continue
                    # Walk for chat ID
                    def walk_rec(o):
                        if isinstance(o, dict):
                            for k, v in o.items():
                                if any(x in str(k).lower() for x in ("chat", "user", "owner")):
                                    cid = is_chat_id(v, bot_id)
                                    if cid: return cid
                                r = walk_rec(v)
                                if r: return r
                        elif isinstance(o, list):
                            for it in o:
                                r = walk_rec(it)
                                if r: return r
                    found = walk_rec(rec)
                    if found: try_value(found, f"S14:logs/{f}"); break
            if result_chat: break
        except Exception: continue

print(f"{result_chat}|{result_account}|{result_source}")
PYEOF
)
    TELEGRAM_TARGET_CACHED=$(echo "$result" | cut -d'|' -f1)
    TELEGRAM_ACCOUNT_CACHED=$(echo "$result" | cut -d'|' -f2)
    TELEGRAM_SOURCE_CACHED=$(echo "$result" | cut -d'|' -f3-)
    TELEGRAM_RESOLVED=true
    if [ -n "$TELEGRAM_TARGET_CACHED" ]; then
        local acc_note=""
        [ -n "$TELEGRAM_ACCOUNT_CACHED" ] && acc_note=" (account=$TELEGRAM_ACCOUNT_CACHED)"
        note "Telegram target resolved: $TELEGRAM_TARGET_CACHED$acc_note via $TELEGRAM_SOURCE_CACHED"
    else
        warn "Telegram chat ID NOT FOUND in any of 14 search locations."
        warn "This should not happen on a paired Hostinger Docker VPS."
        warn "Dumping each source's actual state for debugging:"
        {
            echo "--- commands.ownerAllowFrom (CLI):"
            openclaw config get commands.ownerAllowFrom 2>&1 || true
            echo "--- credentials/ listing:"
            ls -la "$OC_CREDENTIALS/" 2>&1 || true
            echo "--- channels.telegram.allowFrom (CLI):"
            openclaw config get channels.telegram.allowFrom 2>&1 || true
            echo "--- env (telegram-related):"
            printenv | grep -iE "^(TELEGRAM_|TG_)" 2>&1 || true
        } | sed 's/^/    /' | head -50
    fi
}

send_telegram_progress() {
    local message="$1"
    TELEGRAM_LAST_RESULT="skipped"

    if ! command -v openclaw >/dev/null 2>&1; then
        TELEGRAM_LAST_RESULT="no-openclaw-cli"
        return 0
    fi

    # Resolve once, cache for subsequent calls
    if [ "$TELEGRAM_RESOLVED" != "true" ]; then
        resolve_telegram_target_universal
    fi

    if [ -z "$TELEGRAM_TARGET_CACHED" ]; then
        TELEGRAM_LAST_RESULT="no-telegram-target"
        return 0
    fi

    # v10.0.1 — direct send only, no scope manipulation.
    # Every paired client has operator.write (that's what their daily Telegram
    # usage requires). `openclaw message send` succeeds for them on the first
    # call. No retries, no rotation, no approval — just send.
    # Wrapped with `|| rc=$?` so `set -euo pipefail` doesn't kill the install
    # if anything unexpected happens.
    local out="" rc=0
    local send_args=(message send --channel telegram --target "$TELEGRAM_TARGET_CACHED" --message "$message")
    [ -n "$TELEGRAM_ACCOUNT_CACHED" ] && send_args+=(--account "$TELEGRAM_ACCOUNT_CACHED")

    out=$(openclaw "${send_args[@]}" 2>&1) || rc=$?
    echo "$out" >> "$LOG_FILE"
    if [ "$rc" -eq 0 ]; then
        TELEGRAM_LAST_RESULT="sent:$TELEGRAM_TARGET_CACHED"
        return 0
    fi

    # Send failed. Capture for end-of-install diagnostic. Don't retry, don't
    # touch device scopes, don't prompt the user. Their Telegram is already
    # paired and working; whatever this transient failure was, it shouldn't
    # change their setup.
    TELEGRAM_LAST_RESULT="failed:see-$LOG_FILE"
    return 0   # NEVER kill the install — Telegram is optional
}

# ----------------------------------------------------------
# v10.14.10: Shared Operator Secrets Injector (VPS)
# ----------------------------------------------------------
# Some credentials (Podbean OAuth app etc.) are operator-level — same for
# every client — and can't live in the public OpenClaw repo. Operator stores
# them as OPENCLAW_* env vars in ~/.zshrc on their host machine, which get
# forwarded into this container via `docker exec -e OPENCLAW_*` in the
# auto-detect re-exec block at the top of this file.
inject_shared_operator_secrets() {
    local injected_count=0
    local mode_oc_json_ready="no"
    [ -f "$OC_JSON" ] && mode_oc_json_ready="yes"

    mkdir -p "$(dirname "$OC_SECRETS_ENV")" 2>/dev/null || true
    if [ ! -f "$OC_SECRETS_ENV" ]; then
        touch "$OC_SECRETS_ENV"
        chmod 600 "$OC_SECRETS_ENV" 2>/dev/null || true
    fi

    _shared_write_env() {
        local var="$1"; local val="$2"
        grep -v "^${var}=" "$OC_SECRETS_ENV" > "$OC_SECRETS_ENV.tmp" 2>/dev/null || true
        mv "$OC_SECRETS_ENV.tmp" "$OC_SECRETS_ENV" 2>/dev/null || true
        printf '%s=%s\n' "$var" "$val" >> "$OC_SECRETS_ENV"
        chmod 600 "$OC_SECRETS_ENV" 2>/dev/null || true
    }

    _shared_write_ocjson() {
        local var="$1"; local val="$2"
        [ "$mode_oc_json_ready" != "yes" ] && return 0
        VAR="$var" VAL="$val" OC_JSON="$OC_JSON" python3 - <<'PYEOF' 2>/dev/null || true
import json, os
p = os.environ['OC_JSON']
v = os.environ['VAR']
val = os.environ['VAL']
try:
    d = json.load(open(p))
except Exception:
    d = {}
d.setdefault('env', {}).setdefault('vars', {})[v] = val
json.dump(d, open(p, 'w'), indent=2)
PYEOF
    }

    # Podbean shared OAuth app credentials
    if [ -n "${OPENCLAW_PODBEAN_CLIENT_ID:-}" ] && [ -n "${OPENCLAW_PODBEAN_CLIENT_SECRET:-}" ]; then
        _shared_write_env "PODBEAN_CLIENT_ID" "$OPENCLAW_PODBEAN_CLIENT_ID"
        _shared_write_env "PODBEAN_CLIENT_SECRET" "$OPENCLAW_PODBEAN_CLIENT_SECRET"
        _shared_write_ocjson "PODBEAN_CLIENT_ID" "$OPENCLAW_PODBEAN_CLIENT_ID"
        _shared_write_ocjson "PODBEAN_CLIENT_SECRET" "$OPENCLAW_PODBEAN_CLIENT_SECRET"
        success "Podbean shared OAuth app credentials injected from operator env (chmod 600)"
        injected_count=$((injected_count + 2))
    elif [ -n "${OPENCLAW_PODBEAN_CLIENT_ID:-}" ] || [ -n "${OPENCLAW_PODBEAN_CLIENT_SECRET:-}" ]; then
        warn "Only one of OPENCLAW_PODBEAN_CLIENT_ID / OPENCLAW_PODBEAN_CLIENT_SECRET set — both required. Skipping Podbean injection."
    fi

    if [ "$injected_count" -gt 0 ]; then
        note "Shared operator secrets: $injected_count value(s) written to $OC_SECRETS_ENV"
    else
        note "Shared operator secrets: none in env. Set OPENCLAW_PODBEAN_CLIENT_ID + _CLIENT_SECRET in ~/.zshrc on the host (before SSH/install) to inject."
    fi
}

# ----------------------------------------------------------
# Config Backup Protocol
# ----------------------------------------------------------
backup_config_file() {
    local file="$1"
    if [ -f "$file" ]; then
        mkdir -p "$OC_BACKUPS"
        local ts filename backup
        ts=$(date +%Y-%m-%d-%H%M%S)
        filename=$(basename "$file")
        backup="$OC_BACKUPS/${filename}-backup-${ts}.txt"
        cp "$file" "$backup"
        note "Backed up: $backup"
    fi
}

# ----------------------------------------------------------
# Bulletproof VPS Credential Discovery (v10.0.0)
# ----------------------------------------------------------
# Hostinger Docker injects credentials as container env vars. The Hostinger
# entrypoint (/hostinger/server.mjs) also writes inline keys into
# models.providers.<name>.apiKey. Some installs (Trevor's pattern) add an
# env.vars block inside openclaw.json. Per-agent OAuth/api_key creds live in
# /data/.openclaw/agents/main/agent/auth-profiles.json. There are NO .env
# files by default on Hostinger Docker.
#
# Sources searched (in order, first hit wins per credential):
#   1. Container env vars (printenv)        — Hostinger primary
#   2. /proc/1/environ                      — fallback if env wasn't inherited
#   3. models.providers.<name>.apiKey       — LLM keys baked into config
#   4. env.vars block in openclaw.json       — operator-added inline vars
#   5. plugins.entries.<plugin>.config.*     — plugin-level secrets
#   6. auth-profiles.json profiles.*.key     — per-agent api_key entries
#   7. /data/.openclaw/secrets.json          — official OpenClaw secrets file (if present)
#   8. /data/.openclaw/secrets/.env          — only if operator manually created
#   9. Recursive deep walk of openclaw.json for any field named apiKey|token|secret
#
# Alias map handles naming variants (Hostinger uses GHL_PRIVATE_INTEGRATION_TOKEN;
# our canonical name is GOHIGHLEVEL_API_KEY — same value, different name).

CREDS_FOUND_LIST=""

# get_alias_list <CANONICAL_VAR> — returns space-separated alias names.
# Includes Hostinger container env var names + alternates we've seen.
get_alias_list() {
    case "$1" in
        GOHIGHLEVEL_API_KEY)
            echo "GOHIGHLEVEL_API_KEY GHL_PRIVATE_INTEGRATION_TOKEN GHL_API_KEY GHL_PIT HIGHLEVEL_API_KEY HIGHLEVEL_TOKEN GHL_PRIVATE_TOKEN" ;;
        GOHIGHLEVEL_LOCATION_ID)
            echo "GOHIGHLEVEL_LOCATION_ID GHL_LOCATION_ID HIGHLEVEL_LOCATION_ID LOCATION_ID" ;;
        TELEGRAM_BOT_TOKEN)
            echo "TELEGRAM_BOT_TOKEN TG_BOT_TOKEN BOT_TOKEN" ;;
        GEMINI_API_KEY)
            echo "GEMINI_API_KEY GOOGLE_GEMINI_API_KEY" ;;
        GOOGLE_API_KEY)
            echo "GOOGLE_API_KEY GOOGLE_CLOUD_API_KEY" ;;
        OPENAI_API_KEY)
            echo "OPENAI_API_KEY OPENAI_TOKEN" ;;
        OPENROUTER_API_KEY)
            echo "OPENROUTER_API_KEY OR_API_KEY" ;;
        FISH_AUDIO_API_KEY)
            echo "FISH_AUDIO_API_KEY FISHAUDIO_API_KEY FISH_API_KEY" ;;
        FISH_AUDIO_VOICE_ID)
            echo "FISH_AUDIO_VOICE_ID FISHAUDIO_VOICE_ID" ;;
        PODBEAN_API_KEY|PODBEAN_CLIENT_ID)
            echo "PODBEAN_CLIENT_ID PODBEAN_API_KEY" ;;
        PODBEAN_API_SECRET|PODBEAN_CLIENT_SECRET)
            echo "PODBEAN_CLIENT_SECRET PODBEAN_API_SECRET" ;;
        PODBEAN_PODCAST_ID)
            echo "PODBEAN_PODCAST_ID PODBEAN_CHANNEL_ID PODCAST_ID" ;;
        TAVILY_API_KEY)
            echo "TAVILY_API_KEY TAVILY_KEY" ;;
        KIE_API_KEY)
            echo "KIE_API_KEY KIE_AI_API_KEY" ;;
        OLLAMA_API_KEY)
            echo "OLLAMA_API_KEY" ;;
        SUPABASE_SERVICE_ROLE_KEY)
            echo "SUPABASE_SERVICE_ROLE_KEY SUPABASE_SERVICE_KEY" ;;
        VERCEL_TOKEN)
            echo "VERCEL_TOKEN VERCEL_API_TOKEN AI_GATEWAY_API_KEY" ;;
        GITHUB_TOKEN)
            echo "GITHUB_TOKEN GH_TOKEN COPILOT_GITHUB_TOKEN" ;;
        ANTHROPIC_API_KEY)
            echo "ANTHROPIC_API_KEY CLAUDE_API_KEY" ;;
        CONTEXT7_API_KEY)
            echo "CONTEXT7_API_KEY CTX7_API_KEY" ;;
        AIRTABLE_TOKEN)
            echo "AIRTABLE_TOKEN AIRTABLE_API_KEY AIRTABLE_PAT" ;;
        *)
            echo "$1" ;;
    esac
}

# search_env_var_vps <CANONICAL_VAR> — bulletproof VPS-only lookup across 9
# sources. Prints stderr line showing which source/alias matched.
search_env_var_vps() {
    local CANONICAL="$1"
    local aliases
    aliases=$(get_alias_list "$CANONICAL")

    # Source 1: container environment vars (Hostinger primary)
    for VAR_NAME in $aliases; do
        local env_val
        env_val=$(printenv "$VAR_NAME" 2>/dev/null || true)
        if [ -n "$env_val" ]; then
            [ "$VAR_NAME" != "$CANONICAL" ] && echo "    [src: env.$VAR_NAME → $CANONICAL]" >&2
            echo "$env_val"
            return
        fi
    done

    # Source 2: /proc/1/environ (PID 1 — gateway process — in case shell env was reset)
    if [ -r /proc/1/environ ]; then
        for VAR_NAME in $aliases; do
            local p1val
            p1val=$(xargs -0 -L1 -a /proc/1/environ 2>/dev/null | grep "^${VAR_NAME}=" | head -1 | cut -d'=' -f2-)
            if [ -n "$p1val" ]; then
                echo "    [src: /proc/1/environ.$VAR_NAME]" >&2
                echo "$p1val"
                return
            fi
        done
    fi

    [ ! -f "$OC_JSON" ] && { echo ""; return; }

    # Sources 3 + 4 + 5 + 6 + 7 + 8 + 9 — single python pass over openclaw.json
    # + auth-profiles.json + optional secrets files for efficiency
    local result
    result=$(CANONICAL="$CANONICAL" ALIASES="$aliases" python3 - <<'PYEOF' 2>/dev/null
import json, os, re
CANONICAL = os.environ['CANONICAL']
ALIASES = os.environ['ALIASES'].split()
OC_JSON = "/data/.openclaw/openclaw.json"
AUTH = "/data/.openclaw/agents/main/agent/auth-profiles.json"
SECRETS_JSON = "/data/.openclaw/secrets.json"
SECRETS_ENV = "/data/.openclaw/secrets/.env"

cfg = {}
try: cfg = json.load(open(OC_JSON))
except Exception: pass

# Source 3: models.providers.<name>.apiKey (LLM keys baked in by Hostinger)
provider_map = {
    "OPENROUTER_API_KEY": "openrouter",
    "OPENAI_API_KEY": "openai",
    "GEMINI_API_KEY": "google",
    "GOOGLE_API_KEY": "google",
    "OLLAMA_API_KEY": "ollama",
    "ANTHROPIC_API_KEY": "anthropic",
}
pk = provider_map.get(CANONICAL)
if pk:
    val = cfg.get("models", {}).get("providers", {}).get(pk, {}).get("apiKey", "")
    if val:
        print(f"src=models.providers.{pk}.apiKey")
        print(val)
        raise SystemExit(0)

# Source 4: env.vars block inside openclaw.json (Trevor's pattern)
env_vars = cfg.get("env", {}).get("vars", {})
for alias in ALIASES:
    if alias in env_vars and env_vars[alias]:
        print(f"src=env.vars.{alias}")
        print(env_vars[alias])
        raise SystemExit(0)

# Source 5: plugins.entries.<plugin>.config.* — any field matching alias
for pname, p in (cfg.get("plugins", {}).get("entries", {}) or {}).items():
    pc = p.get("config", {}) if isinstance(p, dict) else {}
    for alias in ALIASES:
        if alias in pc and pc[alias]:
            print(f"src=plugins.entries.{pname}.config.{alias}")
            print(pc[alias]); raise SystemExit(0)
    # also scan apiKey/token/secret/key fields generically
    for fld in ("apiKey", "token", "secret", "key"):
        v = pc.get(fld, "")
        if v and CANONICAL.lower().replace("_","") in (pname + fld).lower().replace("_",""):
            print(f"src=plugins.entries.{pname}.config.{fld}")
            print(v); raise SystemExit(0)

# Source 6: auth-profiles.json
try:
    auth = json.load(open(AUTH))
    for prof_id, prof in (auth.get("profiles") or {}).items():
        if not isinstance(prof, dict): continue
        # Match provider name to canonical (openai:default -> OPENAI_API_KEY)
        provider = prof.get("provider", "").lower()
        canonical_provider = CANONICAL.replace("_API_KEY","").lower()
        if provider and provider == canonical_provider and prof.get("key"):
            print(f"src=auth-profiles.{prof_id}.key")
            print(prof["key"]); raise SystemExit(0)
except Exception: pass

# Source 7: /data/.openclaw/secrets.json (official OpenClaw secrets file)
if os.path.isfile(SECRETS_JSON):
    try:
        s = json.load(open(SECRETS_JSON))
        # Walk; common schemas: flat dict, or {"providers":{"openai":{"apiKey":...}}}
        def find(obj, target_aliases):
            if isinstance(obj, dict):
                for k, v in obj.items():
                    if k in target_aliases and isinstance(v, (str,int)) and v:
                        return (k, v)
                    if isinstance(v, (dict, list)):
                        r = find(v, target_aliases)
                        if r: return r
            elif isinstance(obj, list):
                for it in obj:
                    r = find(it, target_aliases)
                    if r: return r
            return None
        f = find(s, ALIASES)
        if f:
            print(f"src=secrets.json.{f[0]}"); print(f[1]); raise SystemExit(0)
    except Exception: pass

# Source 8: /data/.openclaw/secrets/.env (only if operator created it manually)
if os.path.isfile(SECRETS_ENV):
    try:
        for line in open(SECRETS_ENV):
            line = line.strip()
            if "=" not in line or line.startswith("#"): continue
            k, _, v = line.partition("=")
            if k in ALIASES and v:
                v = v.strip().strip('"').strip("'")
                print(f"src=secrets/.env.{k}"); print(v); raise SystemExit(0)
    except Exception: pass

# Source 9: deep recursive scan of openclaw.json for any field name matching
# this credential (rare schema variants)
def deep_find(obj, target_aliases, parent=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            full = f"{parent}.{k}" if parent else k
            if k in target_aliases and isinstance(v, (str,int)) and v:
                return (full, v)
            r = deep_find(v, target_aliases, full)
            if r: return r
    elif isinstance(obj, list):
        for i, it in enumerate(obj):
            r = deep_find(it, target_aliases, f"{parent}[{i}]")
            if r: return r
    return None
f = deep_find(cfg, ALIASES)
if f:
    print(f"src=deep:{f[0]}"); print(f[1]); raise SystemExit(0)
PYEOF
)
    if [ -n "$result" ]; then
        local src val
        src=$(echo "$result" | head -1 | sed 's/^src=//')
        val=$(echo "$result" | sed -n '2p')
        if [ -n "$val" ]; then
            echo "    [src: $src]" >&2
            echo "$val"
            return
        fi
    fi

    echo ""
}

discover_all_credentials() {
    step "Bulletproof Credential Discovery (v10.0.0 — Hostinger Docker VPS)"
    note "Lookup priority: env → /proc/1/environ → openclaw.json (providers, env.vars, plugins) → auth-profiles.json → secrets.json → secrets/.env → deep scan"

    local CRED_LIST="GOOGLE_API_KEY:Google"
    CRED_LIST="$CRED_LIST|GEMINI_API_KEY:Gemini"
    CRED_LIST="$CRED_LIST|OPENAI_API_KEY:OpenAI"
    CRED_LIST="$CRED_LIST|OPENROUTER_API_KEY:OpenRouter"
    CRED_LIST="$CRED_LIST|OLLAMA_API_KEY:Ollama Cloud"
    CRED_LIST="$CRED_LIST|ANTHROPIC_API_KEY:Anthropic Claude"
    CRED_LIST="$CRED_LIST|GOHIGHLEVEL_API_KEY:GHL (PIT — GoHighLevel Private Integration Token)"
    CRED_LIST="$CRED_LIST|GOHIGHLEVEL_LOCATION_ID:GHL Location ID"
    CRED_LIST="$CRED_LIST|FISH_AUDIO_API_KEY:Fish Audio"
    CRED_LIST="$CRED_LIST|FISH_AUDIO_VOICE_ID:Fish Audio Voice"
    # v10.14.10: Podbean client_id + client_secret are SHARED operator-level
    # credentials (Trevor's OAuth app — same for every client). Operator
    # injects via OPENCLAW_PODBEAN_CLIENT_ID + _CLIENT_SECRET env vars
    # (forwarded into the container via docker exec -e in the auto-detect
    # re-exec block at the top of this file).
    CRED_LIST="$CRED_LIST|PODBEAN_CLIENT_ID:Podbean App ID (shared)"
    CRED_LIST="$CRED_LIST|PODBEAN_CLIENT_SECRET:Podbean App Secret (shared)"
    CRED_LIST="$CRED_LIST|PODBEAN_PODCAST_ID:Podbean Podcast/Channel ID (per-client)"
    CRED_LIST="$CRED_LIST|TAVILY_API_KEY:Tavily Search"
    CRED_LIST="$CRED_LIST|KIE_API_KEY:KIE.ai (skill 27)"
    CRED_LIST="$CRED_LIST|TELEGRAM_BOT_TOKEN:Telegram Bot"
    CRED_LIST="$CRED_LIST|CONTEXT7_API_KEY:Context7 MCP"
    CRED_LIST="$CRED_LIST|GITHUB_TOKEN:GitHub"
    CRED_LIST="$CRED_LIST|VERCEL_TOKEN:Vercel"
    CRED_LIST="$CRED_LIST|SUPABASE_SERVICE_ROLE_KEY:Supabase"
    CRED_LIST="$CRED_LIST|AIRTABLE_TOKEN:Airtable"

    local found_count=0
    local missing_creds=""
    local creds="$CRED_LIST"

    while [ -n "$creds" ]; do
        local CRED_ENTRY
        if echo "$creds" | grep -q "|"; then
            CRED_ENTRY=$(echo "$creds" | cut -d'|' -f1)
            creds=$(echo "$creds" | cut -d'|' -f2-)
        else
            CRED_ENTRY="$creds"; creds=""
        fi
        local VAR_NAME SERVICE VALUE
        VAR_NAME=$(echo "$CRED_ENTRY" | cut -d':' -f1)
        SERVICE=$(echo "$CRED_ENTRY" | cut -d':' -f2-)
        VALUE=$(search_env_var_vps "$VAR_NAME")
        if [ -n "$VALUE" ]; then
            found_count=$((found_count + 1))
            success "Found $VAR_NAME — $SERVICE"
            CREDS_FOUND_LIST="$CREDS_FOUND_LIST|$VAR_NAME"
        else
            missing_creds="$missing_creds|$VAR_NAME ($SERVICE)"
        fi
    done

    note "$found_count credentials discovered."
    if [ -n "$missing_creds" ]; then
        warn "Not configured yet (some skills will skip or require these later):"
        echo "$missing_creds" | tr '|' '\n' | grep -v '^$' | sed 's/^/      /'
    fi
}

# Back-compat shim — older code calls search_env_var; new code calls search_env_var_vps
search_env_var() { search_env_var_vps "$@"; }

# has_cred <CANONICAL_VAR> — returns 0 if discover_all_credentials found it
has_cred() {
    case "|${CREDS_FOUND_LIST}|" in
        *"|$1|"*) return 0 ;;
        *) return 1 ;;
    esac
}

# ----------------------------------------------------------
# Directory Discovery
# ----------------------------------------------------------
discover_skills_dir() {
    # VPS canonical skills location is /data/.openclaw/skills/. Fallbacks
    # include the onboarding stage dir (where this installer extracts to)
    # and a few sibling layouts seen across Hostinger images.
    local CANDIDATES="$OC_SKILLS_DIR"
    CANDIDATES="$CANDIDATES|$OC_CONFIG/onboarding"
    CANDIDATES="$CANDIDATES|/data/openclaw-onboarding"
    CANDIDATES="$CANDIDATES|/data/Downloads/openclaw-master-files"

    local dirs="$CANDIDATES"
    while [ -n "$dirs" ]; do
        local DIR
        if echo "$dirs" | grep -q "|"; then
            DIR=$(echo "$dirs" | cut -d'|' -f1)
            dirs=$(echo "$dirs" | cut -d'|' -f2-)
        else
            DIR="$dirs"; dirs=""
        fi
        if [ -d "$DIR" ]; then
            local SKILL_COUNT
            SKILL_COUNT=$(find "$DIR" -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$SKILL_COUNT" -gt "0" ]; then
                echo "$DIR"
                return
            fi
        fi
    done

    echo "$OC_SKILLS_DIR"
}

discover_skills() {
    local base_dir="${1:-$OC_CONFIG/onboarding}"
    local numbered_count
    numbered_count=$(find "$base_dir" -maxdepth 1 -type d -name "[0-9][0-9]-*" 2>/dev/null | wc -l | tr -d ' ')
    local skill_md_count
    skill_md_count=$(find "$base_dir" -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
    
    local max_count=$numbered_count
    if [ "$skill_md_count" -gt "$max_count" ] 2>/dev/null; then
        max_count=$skill_md_count
    fi
    echo "$max_count"
}

# ----------------------------------------------------------
# Concurrency Configuration
# ----------------------------------------------------------
configure_concurrency_LEGACY_UNUSED() {
    step "Configuring Sub-Agent Concurrency"
    
    local OPENCLAW_JSON="$OC_JSON"

    if [ ! -f "$OPENCLAW_JSON" ]; then
        warn "openclaw.json not found - skipping concurrency config"
        return
    fi

    backup_config_file "$OPENCLAW_JSON"

    OPENCLAW_JSON="$OPENCLAW_JSON" python3 << 'PYEOF'
import json, os, sys

path = os.environ['OPENCLAW_JSON']
try:
    with open(path) as f:
        config = json.load(f)

    agents = config.setdefault('agents', {})
    defaults = agents.setdefault('defaults', {})
    sub = defaults.setdefault('subagents', {})
    
    # v8.7.0 concurrency settings
    sub['maxConcurrent'] = 50
    sub['maxQueue'] = 10
    sub['maxDepth'] = 4
    
    defaults['subagents'] = sub
    agents['defaults'] = defaults
    config['agents'] = agents
    
    with open(path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print("  ✓ Set maxConcurrent=50, maxQueue=10, maxDepth=4")
except Exception as e:
    print(f"  ✗ Could not update concurrency: {e}", file=sys.stderr)
PYEOF
}

# ----------------------------------------------------------
# Bookkeeping: install dir + stale-state cleanup (v10.5.5)
# ----------------------------------------------------------
# Self-healing: we do NOT downgrade ONBOARDING_VERSION to whatever the
# previous install wrote to disk. The constant in THIS script is the
# truth. Any stale /data/.openclaw/onboarding/version file from a prior
# install is informational only — it will be rewritten at end of run.
#
# We also auto-clear .install-in-progress if it's older than 1 hour
# (i.e. a previous run crashed). No more "rm to clear" tax on clients.
ONBOARDING_DIR="$OC_CONFIG/onboarding"
mkdir -p "$ONBOARDING_DIR"
INSTALL_FLAG="$ONBOARDING_DIR/.install-in-progress"

# Capture prior version for purely informational logging
PRIOR_VERSION=""
if [ -f "$ONBOARDING_DIR/version" ] 2>/dev/null; then
    PRIOR_VERSION=$(cat "$ONBOARDING_DIR/version" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$PRIOR_VERSION" ] && [ "$PRIOR_VERSION" != "$ONBOARDING_VERSION" ]; then
        note "Upgrading from $PRIOR_VERSION → $ONBOARDING_VERSION"
    fi
fi

# Stale-lock auto-clear: if the lock file exists but is > 60 minutes old,
# the previous run crashed mid-install. Wipe it instead of blocking.
if [ -f "$INSTALL_FLAG" ]; then
    LOCK_AGE_MINS=$(( ( $(date +%s) - $(stat -f %m "$INSTALL_FLAG" 2>/dev/null || stat -c %Y "$INSTALL_FLAG" 2>/dev/null || echo 0) ) / 60 ))
    if [ "$LOCK_AGE_MINS" -gt 60 ] 2>/dev/null; then
        warn "Stale install lock detected (${LOCK_AGE_MINS} min old) — auto-clearing and continuing"
        rm -f "$INSTALL_FLAG"
    else
        step "Installation Already In Progress"
        error "Another installation is running (started ${LOCK_AGE_MINS} min ago)."
        error "If you know it crashed, run: rm $INSTALL_FLAG"
        exit 0
    fi
fi

touch "$INSTALL_FLAG"
trap 'rm -f "$INSTALL_FLAG"' EXIT

# ----------------------------------------------------------
# Main Header
# ----------------------------------------------------------
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     OpenClaw Onboarding Installer        ║"
echo "║              ${ONBOARDING_VERSION}                      ║"
echo "╚══════════════════════════════════════════╝"
echo ""
note "Log file: $LOG_FILE"

# ----------------------------------------------------------
# CLI Scope Auto-Repair (v10.0.3)
# ----------------------------------------------------------
# Per Mac client (Floyd) reproduction: fresh OpenClaw pairings can leave the
# CLI device with [operator.read, operator.pairing] only — missing
# operator.write/admin. Result: `openclaw message send` + `openclaw cron create`
# fail with "scope upgrade pending approval" and gateway status reports
# "Capability: read-only".
#
# Detection: `openclaw gateway status --verbose | grep "Capability:"`
# Healthy = "admin-capable" | "write-capable". Broken = "read-only".
#
# Auto-repair strategy:
#   PLAN A: openclaw devices rotate --token <master> (sanctioned CLI path)
#   PLAN B: direct edit of /data/.openclaw/devices/paired.json (proven approach)
# Both end with `openclaw gateway restart` + Capability verification.

get_master_token() {
    python3 -c "
import json, os, sys
try:
    cfg = json.load(open('$OC_JSON'))
    print(cfg.get('gateway',{}).get('auth',{}).get('token','') or '')
except Exception: pass
" 2>/dev/null
}

get_gateway_capability() {
    openclaw gateway status --verbose 2>/dev/null | grep -E "^Capability:" | awk '{print $2}' | head -1
}

auto_repair_cli_scopes() {
    local capability master_token cli_id paired_file pending_file

    capability=$(get_gateway_capability)
    if [ -z "$capability" ]; then
        note "Gateway capability check skipped (could not query)."
        return 0
    fi
    if [ "$capability" != "read-only" ]; then
        success "Gateway capability OK: $capability — no scope repair needed."
        return 0
    fi

    warn "Gateway reports Capability: read-only — CLI device is missing operator.write."
    warn "This blocks Telegram, cron, and every CLI-side gateway call. Auto-repairing..."

    master_token=$(get_master_token)
    if [ -z "$master_token" ]; then
        warn "Cannot read gateway.auth.token from $OC_JSON — auto-repair not possible."
        warn "Manual fix: see https://github.com/trevorotts1/openclaw-onboarding-vps/blob/main/docs/scope-repair.md"
        return 1
    fi

    cli_id=$(openclaw devices list --token "$master_token" --json 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    paired = d.get('paired', []) if isinstance(d, dict) else (d if isinstance(d, list) else [])
    for p in paired:
        if not isinstance(p, dict): continue
        if p.get('clientId') != 'cli': continue
        scopes = set(p.get('scopes', []) or [])
        if 'operator.write' not in scopes and 'operator.admin' not in scopes:
            print(p.get('deviceId') or ''); break
except Exception: pass
" 2>/dev/null)

    # ─── PLAN A: CLI rotate + approve with master token ───
    if [ -n "$cli_id" ]; then
        note "Plan A: trying CLI rotate with master token for device ${cli_id:0:20}..."
        local rotate_out=""
        rotate_out=$(openclaw devices rotate --device "$cli_id" --role operator \
            --scope operator.read --scope operator.write --scope operator.admin \
            --scope operator.pairing --scope operator.approvals \
            --token "$master_token" 2>&1)
        echo "$rotate_out" >> "$LOG_FILE"
        sleep 2

        local pending_id=""
        pending_id=$(openclaw devices list --token "$master_token" --json 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get('pending', []) or []
    for it in items:
        if not isinstance(it, dict): continue
        rid = it.get('requestId') or it.get('id')
        if rid: print(rid); break
except Exception: pass
" 2>/dev/null)

        if [ -n "$pending_id" ]; then
            note "Plan A: pending request $pending_id created — approving with master token..."
            if openclaw devices approve "$pending_id" --token "$master_token" >> "$LOG_FILE" 2>&1; then
                openclaw gateway restart >> "$LOG_FILE" 2>&1
                sleep 5
                capability=$(get_gateway_capability)
                if [ "$capability" != "read-only" ] && [ -n "$capability" ]; then
                    success "Plan A succeeded — capability now: $capability"
                    return 0
                fi
            fi
        fi
        warn "Plan A insufficient. Falling through to Plan B."
    fi

    # ─── PLAN B: direct paired.json edit (Floyd's proven approach) ───
    note "Plan B: editing /data/.openclaw/devices/paired.json directly..."
    paired_file="/data/.openclaw/devices/paired.json"
    pending_file="/data/.openclaw/devices/pending.json"

    if [ ! -f "$paired_file" ]; then
        warn "$paired_file not found — cannot auto-repair."
        return 1
    fi

    cp "$paired_file" "$paired_file.bak-$(date +%Y%m%d-%H%M%S)"
    note "Backed up paired.json"

    PAIRED_FILE="$paired_file" python3 - <<'PYEOF'
import json, os, sys
paired_file = os.environ['PAIRED_FILE']
TARGET = {'operator.read', 'operator.write', 'operator.admin', 'operator.pairing', 'operator.approvals'}

try:
    with open(paired_file) as f:
        data = json.load(f)
except Exception as e:
    print(f"READ_ERR:{e}"); sys.exit(0)

def upgrade(device):
    if device.get('clientId') != 'cli': return False
    changed = False
    for field in ('scopes', 'approvedScopes'):
        cur = set(device.get(field, []) or [])
        if not TARGET.issubset(cur):
            device[field] = sorted(cur | TARGET); changed = True
    tokens = device.get('tokens', {})
    op_token = tokens.get('operator', {}) if isinstance(tokens, dict) else {}
    if isinstance(op_token, dict):
        cur = set(op_token.get('scopes', []) or [])
        if not TARGET.issubset(cur):
            op_token['scopes'] = sorted(cur | TARGET); changed = True
    return changed

fixed_count = 0
if isinstance(data, dict):
    for did, device in data.items():
        if isinstance(device, dict) and upgrade(device): fixed_count += 1
elif isinstance(data, list):
    for device in data:
        if isinstance(device, dict) and upgrade(device): fixed_count += 1

if fixed_count:
    with open(paired_file, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"FIXED:{fixed_count}")
else:
    print("NO_CHANGE")
PYEOF

    if [ -f "$pending_file" ]; then
        cp "$pending_file" "$pending_file.bak-$(date +%Y%m%d-%H%M%S)"
        echo '{}' > "$pending_file"
        note "Cleared pending.json"
    fi

    note "Restarting gateway to apply scope repair..."
    openclaw gateway restart >> "$LOG_FILE" 2>&1
    sleep 6

    capability=$(get_gateway_capability)
    if [ "$capability" = "read-only" ] || [ -z "$capability" ]; then
        warn "Auto-repair completed but capability check returned '$capability'."
        warn "Manual fix: https://docs.openclaw.ai/gateway/operator-scopes"
        return 1
    fi
    success "Plan B succeeded — capability now: $capability"
    return 0
}

auto_repair_cli_scopes || warn "Scope auto-repair did not complete successfully — Telegram/cron may fail (install will continue)."

send_telegram_progress "Starting OpenClaw Onboarding install ${ONBOARDING_VERSION}..."

# ----------------------------------------------------------
# Step 0: Bootstrap — orchestrator model + sub-agent config + state carryover
# ----------------------------------------------------------
step "Step 0: Bootstrap (model selection + sub-agent config)"

# 0.1 — Recommend /new session for fresh context (not required)
note "Recommendation: if you are over 5 minutes into the current session, start a fresh session with /new BEFORE continuing. The install will pick up where you left off via the state-carryover file at ~/.openclaw/.install-resume.json."
note "This is a recommendation only — the install will proceed either way."

# 0.2 — Write/refresh the state-carryover file
OCJSON="$OC_JSON"
RESUME_FILE="$OC_CONFIG/.install-resume.json"
mkdir -p "$(dirname "$RESUME_FILE")"
cat > "$RESUME_FILE" <<RESUME_JSON
{
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "${ONBOARDING_VERSION}",
  "phase": "A",
  "wave": "1",
  "completed_skills": [],
  "active_skills": [],
  "pending_skills": [],
  "owner_decisions": {},
  "next_step": "Step 0 bootstrap complete — proceeding to credential discovery"
}
RESUME_JSON
success "State carryover initialized at $RESUME_FILE"

# 0.3 — Canonical sub-agent + bootstrap config (v9.7.8)
# Hard-overwrites the numeric limits (these are protocol gates, not preferences).
# Preserves agents.defaults.subagents.model.fallbacks if a client has customized it.
# Sets allowAgents=["*"] on every agents.list entry (wildcard subagent permission).
note "Configuring canonical sub-agent + bootstrap settings (v9.7.8 spec)..."
backup_config_file "$OCJSON"

python3 << PYEOF
import json, os, sys

path = "$OCJSON"
if not os.path.exists(path):
    print(f"  ⚠  {path} does not exist yet — Step 0 will be retried after CLI install", file=sys.stderr)
    sys.exit(0)

with open(path) as f:
    cfg = json.load(f)

agents = cfg.setdefault('agents', {})
defaults = agents.setdefault('defaults', {})
sub = defaults.setdefault('subagents', {})

# Hard-overwrite numeric limits (protocol gates)
sub['maxChildrenPerAgent'] = 20
sub['maxSpawnDepth']       = 4
# maxConcurrent: hard-overwrite to 100, with a min-clamp of 50 (never less)
prev_concurrent = sub.get('maxConcurrent', 100)
try:
    prev_concurrent = int(prev_concurrent)
except (TypeError, ValueError):
    prev_concurrent = 100
sub['maxConcurrent'] = max(100, prev_concurrent) if prev_concurrent >= 50 else 100
# Hard set thinking level
sub['thinking'] = 'high'

# PRESERVE model fallbacks if already set; only seed if missing
model_block = sub.get('model')
if not isinstance(model_block, dict) or 'fallbacks' not in model_block:
    sub['model'] = {
        'fallbacks': [
            'ollama/kimi-k2.6:cloud',
            'openrouter/xiaomi/mimo-v2.5-pro',
            'deepseek/deepseek-v4-pro'
        ]
    }
    print("  ✓ subagents.model.fallbacks seeded (was missing)")
else:
    print("  ℹ  subagents.model.fallbacks preserved (already customized)")

# Bootstrap character limits — hard overwrite
prev_max   = defaults.get('bootstrapMaxChars')
prev_total = defaults.get('bootstrapTotalMaxChars')
defaults['bootstrapMaxChars']       = 200000
defaults['bootstrapTotalMaxChars']  = 400000

print(f"  ✓ bootstrapMaxChars: {prev_max} → 200000")
print(f"  ✓ bootstrapTotalMaxChars: {prev_total} → 400000")
print(f"  ✓ subagents.maxChildrenPerAgent → 20")
print(f"  ✓ subagents.maxConcurrent → {sub['maxConcurrent']} (min-clamp 50)")
print(f"  ✓ subagents.maxSpawnDepth → 4")
print(f"  ✓ subagents.thinking → high")

# Wildcard allowAgents on every agents.list entry
agent_list = agents.get('list', [])
updated_entries = 0
for entry in agent_list:
    if not isinstance(entry, dict):
        continue
    entry_sub = entry.setdefault('subagents', {})
    prev_allow = entry_sub.get('allowAgents', None)
    if prev_allow != ['*']:
        entry_sub['allowAgents'] = ['*']
        updated_entries += 1
print(f"  ✓ allowAgents=['*'] applied to {updated_entries} agents.list entries (wildcard subagent permission)")

cfg['agents'] = agents
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)
print("  ✓ openclaw.json written")
PYEOF
success "Canonical sub-agent + bootstrap config applied"

# 0.4 — Model selection (advisory; agent picks at runtime based on what's available)
note "Master orchestrator model priority (per INSTALL-CONTRACT.md Rule 10):"
note "  1. Subscription / OAuth (no per-call cost): codex/gpt-5.5, openai-codex/gpt-5.5"
note "  2. Ollama cloud (very low cost): ollama/kimi-k2.6:cloud (orchestrator), ollama/deepseek-v4-pro:cloud (sub-agents)"
note "  3. OpenRouter (priced per token): openrouter/moonshot/kimi-k2.6 thinking=high"
note "  FORBIDDEN by default: claude-opus-*, claude-sonnet-*, openai/* (too expensive — explicit owner consent required)"
note "If the agent cannot determine available models, it must ASK the owner (per Rule 10)."

# ----------------------------------------------------------
# Step 1: Check OpenClaw CLI
# ----------------------------------------------------------
step "Step 1: Verifying OpenClaw CLI"

if ! command -v openclaw >/dev/null 2>&1; then
    error "OpenClaw CLI not found in PATH"
    echo "  Install with: npm install -g openclaw"
    send_telegram_progress "ERROR: OpenClaw CLI not found. Install failed."
    exit 1
fi

success "OpenClaw CLI found: $(command -v openclaw)"

# ----------------------------------------------------------
# Step 1.5: Inject shared operator secrets (v10.14.10+)
# ----------------------------------------------------------
step "Step 1.5: Injecting shared operator secrets (Podbean app credentials etc.)"
inject_shared_operator_secrets

# ----------------------------------------------------------
# Step 2: Silent Credential Discovery
# ----------------------------------------------------------
discover_all_credentials

# ----------------------------------------------------------
# Step 3: Download Package
# ----------------------------------------------------------
step "Step 3: Downloading Onboarding Package"

SKILLS_DIR=$(discover_skills_dir)
export SKILLS_DIR

note "Source: $ONBOARDING_DIR"
note "Destination: $SKILLS_DIR/"

TEMP_ZIP="/tmp/openclaw-onboarding-pkg.zip"
TEMP_EXTRACT="/tmp/openclaw-onboarding-extract"

curl -fSL --progress-bar "https://github.com/trevorotts1/openclaw-onboarding-vps/archive/refs/heads/main.zip" -o "$TEMP_ZIP"
if [ ! -f "$TEMP_ZIP" ]; then
    error "Failed to download onboarding package"
    send_telegram_progress "ERROR: Download failed. Install aborted."
    exit 1
fi

success "Downloaded to $TEMP_ZIP"
send_telegram_progress "Downloaded onboarding package ${ONBOARDING_VERSION}"

# ----------------------------------------------------------
# Step 4: Extract Package
# ----------------------------------------------------------
step "Step 4: Extracting Package"

rm -rf "$TEMP_EXTRACT"

# v10.14.2: Hostinger's hvps-openclaw image doesn't ship with unzip — fall back
# to python3's stdlib zipfile module. Python 3 is always present in the container
# (it's how the Hostinger entrypoint and credential-discovery scripts run).
if command -v unzip >/dev/null 2>&1; then
    unzip -qo "$TEMP_ZIP" -d "$TEMP_EXTRACT"
elif command -v python3 >/dev/null 2>&1; then
    note "unzip not available; falling back to python3 zipfile extraction"
    mkdir -p "$TEMP_EXTRACT"
    python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" \
        "$TEMP_ZIP" "$TEMP_EXTRACT" || {
        error "python3 zipfile extraction failed"
        rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
        send_telegram_progress "ERROR: Extract failed. Neither unzip nor python3 zipfile worked."
        exit 1
    }
else
    error "Neither unzip nor python3 is available — cannot extract package"
    rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
    send_telegram_progress "ERROR: Extract failed. Install unzip or python3."
    exit 1
fi

if [ ! -d "$TEMP_EXTRACT/openclaw-onboarding-vps-main" ]; then
    error "Unexpected archive structure"
    rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
    send_telegram_progress "ERROR: Extract failed. Archive structure unexpected."
    exit 1
fi

cp -r "$TEMP_EXTRACT/openclaw-onboarding-vps-main/"* "$ONBOARDING_DIR/"
rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"

success "Extracted to $ONBOARDING_DIR"

SKILL_COUNT=$(discover_skills "$ONBOARDING_DIR")
success "Skills found: $SKILL_COUNT"

# ----------------------------------------------------------
# Step 5: Install Skills
# ----------------------------------------------------------
step "Step 5: Installing Skills"

mkdir -p "$SKILLS_DIR"

for SKILL_DIR in "$ONBOARDING_DIR"/[0-9]*/; do
    [ -d "$SKILL_DIR" ] || continue
    
    SKILL_NAME=$(basename "$SKILL_DIR")
    
    # Skip archived skills
    case "$SKILL_NAME" in
        *ARCHIVED*) note "Skipped (archived): $SKILL_NAME"; continue ;;
    esac
    
    mkdir -p "$SKILLS_DIR/$SKILL_NAME"
    
    for ITEM in "$SKILL_DIR"/*; do
        ITEM_NAME=$(basename "$ITEM")
        case "$ITEM_NAME" in
            AGENTS.md|MEMORY.md|SOUL.md|USER.md|IDENTITY.md|HEARTBEAT.md|TOOLS.md)
                # Skip core .md files - handled surgically
                ;;
            *)
                if [ -d "$ITEM" ]; then
                    cp -r "$ITEM" "$SKILLS_DIR/$SKILL_NAME/"
                else
                    cp "$ITEM" "$SKILLS_DIR/$SKILL_NAME/"
                fi
                ;;
        esac
    done
    
    add_to_list "installed" "$SKILL_NAME"
    SKILL_COUNT=$((SKILL_COUNT + 1))
done

success "$SKILL_COUNT skills installed"

# Copy root files (v10.13.0: added AGENTS.md, INSTALL-CONTRACT.md,
# ONBOARDING-TRIGGERS.md, direct-to-agent-install.md so the workspace
# has CEO_DEFERRAL + N1-N27 + N22 semantics on a fresh install).
for ROOT_FILE in \
    "Start Here.md" \
    README.md \
    CHANGELOG.md \
    version \
    AGENTS.md \
    INSTALL-CONTRACT.md \
    ONBOARDING-TRIGGERS.md \
    direct-to-agent-install.md; do
    if [ -f "$ONBOARDING_DIR/$ROOT_FILE" ]; then
        cp "$ONBOARDING_DIR/$ROOT_FILE" "$SKILLS_DIR/../"
    fi
done

# Copy scripts folder
if [ -d "$ONBOARDING_DIR/scripts" ]; then
    cp -r "$ONBOARDING_DIR/scripts" "$SKILLS_DIR/../"
fi

# v10.5.1: Install shared-utils to skills root for v2.1 helper imports
if [ -d "$ONBOARDING_DIR/shared-utils" ]; then
    mkdir -p "$SKILLS_DIR/shared-utils"
    cp -r "$ONBOARDING_DIR/shared-utils/." "$SKILLS_DIR/shared-utils/"
    chmod +x "$SKILLS_DIR/shared-utils/"*.sh 2>/dev/null || true
    chmod +x "$SKILLS_DIR/shared-utils/"*.py 2>/dev/null || true
    success "shared-utils installed to $SKILLS_DIR/shared-utils"
fi

# ----------------------------------------------------------
# Step 6: Install Gemini Scripts
# ----------------------------------------------------------
step "Step 6: Installing Gemini Engine Scripts"

SCRIPTS_DIR="$OC_CONFIG/scripts"
mkdir -p "$SCRIPTS_DIR"

for SCRIPT in gemini-indexer.py gemini-search.py; do
    if [ -f "$ONBOARDING_DIR/scripts/$SCRIPT" ]; then
        cp "$ONBOARDING_DIR/scripts/$SCRIPT" "$SCRIPTS_DIR/"
        chmod +x "$SCRIPTS_DIR/$SCRIPT"
        success "Installed: $SCRIPT"
    fi
done

# Install google-genai if needed
if ! python3 -c "import google.genai" 2>/dev/null; then
    note "Installing google-genai package..."
    pip3 install google-genai --break-system-packages 2>/dev/null || \
        pip3 install google-genai 2>/dev/null || \
        warn "google-genai install failed - manual install required"
else
    success "google-genai already installed"
fi

# ----------------------------------------------------------
# v10.3.0: Install Calibre (ebook-convert) for Skill 22 book extraction
# ----------------------------------------------------------
# On Hostinger Docker VPS, Calibre is installed via Linuxbrew (already at
# /data/linuxbrew/.linuxbrew/bin) OR the official Calibre Linux installer.
# Without Calibre, Skill 22 silently skips MOBI/AZW/AZW3/KFX formats and
# only processes PDF/EPUB. Auto-install here so it's ready by Wave 5.
if command -v ebook-convert >/dev/null 2>&1; then
    success "Calibre (ebook-convert) already installed: $(ebook-convert --version 2>&1 | head -1)"
else
    note "Installing Calibre (ebook-convert) for Skill 22 ebook extraction..."

    # v10.14.3: Skip Linuxbrew on Linux — the calibre formula refuses Linux
    # ("macOS is required for this software"). Go directly to the official
    # installer with curl (wget is missing from Hostinger's image; curl is
    # always present). Install to a user-writable path so we don't need sudo
    # or /usr/local/bin. Symlink into /data/.npm-global/bin which is already
    # on the node user's PATH per the container's PATH env.
    if [ "$(uname -s)" = "Darwin" ] && [ -x /opt/homebrew/bin/brew ]; then
        # Mac path (not used in VPS install but kept for cross-platform safety)
        note "Mac detected — trying Homebrew install..."
        /opt/homebrew/bin/brew install --cask calibre >> "$LOG_FILE" 2>&1 || true
    fi

    if ! command -v ebook-convert >/dev/null 2>&1; then
        if command -v curl >/dev/null 2>&1; then
            note "Running official Calibre Linux installer via curl..."
            mkdir -p /data/.openclaw/calibre
            CAL_LOG="$OC_INSTALL_LOG_DIR/calibre-install-$(date +%Y%m%d-%H%M%S).log"
            if curl -fsSL https://download.calibre-ebook.com/linux-installer.sh -o /tmp/calibre-installer.sh 2>>"$CAL_LOG"; then
                sh /tmp/calibre-installer.sh install_dir=/data/.openclaw/calibre isolated=y >> "$CAL_LOG" 2>&1 || true
                # Symlink to a user-writable PATH location (no sudo needed)
                CAL_BIN="/data/.openclaw/calibre/calibre/ebook-convert"
                if [ -x "$CAL_BIN" ]; then
                    mkdir -p /data/.npm-global/bin
                    ln -sf "$CAL_BIN" /data/.npm-global/bin/ebook-convert 2>>"$CAL_LOG" || true
                    success "Calibre installed via official Linux installer: $(/data/.npm-global/bin/ebook-convert --version 2>&1 | head -1)"
                else
                    warn "Official Calibre installer ran but $CAL_BIN is missing. Skill 22 ebook extraction limited to PDF/EPUB. See $CAL_LOG."
                fi
                rm -f /tmp/calibre-installer.sh
            else
                warn "curl could not fetch the Calibre installer. Skill 22 ebook extraction limited to PDF/EPUB."
            fi
        else
            warn "Neither curl nor wget available — cannot run Calibre installer. Skill 22 ebook extraction limited to PDF/EPUB."
        fi
    fi
fi

# ----------------------------------------------------------
# v10.14.32: Install yt-dlp + whisper-cpp + ffmpeg for Skill 22 YouTube/video → persona
# ----------------------------------------------------------
# Pre-v10.14.32 add-persona-from-source.sh's YouTube branch shelled out to a
# `summarize` CLI (Skill 16) that never existed as an executable on any VPS
# install. Track-I forensic (2026-05-23) traced every YouTube persona failure
# to that branch. Fix: rewire the script to call yt-dlp + whisper-cpp directly,
# and bake those dependencies into the installer so they're guaranteed present.
#
# Path priority (Hostinger Docker VPS — runs as `node` user inside the container):
#   1. /data/linuxbrew/.linuxbrew (already on the image, no sudo needed)
#   2. apt-get  (fallback — needs root, will usually fail in container; non-fatal)
#   3. pip3 install --user yt-dlp + openai-whisper (final fallback)
install_media_tools() {
    step "Step 6.5: Installing yt-dlp + whisper-cpp + ffmpeg (Skill 22 YouTube/video)"

    local LBREW="/data/linuxbrew/.linuxbrew/bin/brew"
    local MISSING_TOOLS=""

    for tool in yt-dlp whisper-cpp ffmpeg; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            # Also check linuxbrew's bin (may not be on PATH yet)
            if [ ! -x "/data/linuxbrew/.linuxbrew/bin/$tool" ]; then
                MISSING_TOOLS="$MISSING_TOOLS $tool"
            fi
        fi
    done

    if [ -z "$MISSING_TOOLS" ]; then
        success "yt-dlp + whisper-cpp + ffmpeg already installed — skipping"
        return 0
    fi

    note "Missing tools:$MISSING_TOOLS"

    # ── Attempt 1: Linuxbrew (preferred — no sudo needed on Hostinger image) ──
    if [ -x "$LBREW" ]; then
        note "Installing missing tools via Linuxbrew at /data/linuxbrew..."
        for tool in $MISSING_TOOLS; do
            if "$LBREW" install "$tool" >> "$LOG_FILE" 2>&1; then
                success "  brew install $tool ✓"
            else
                warn "  brew install $tool failed (see $LOG_FILE)"
            fi
        done
    else
        note "Linuxbrew not found at $LBREW — skipping brew path"
    fi

    # ── Attempt 2: apt (only if missing tools remain and we have root) ──
    local STILL_MISSING=""
    for tool in $MISSING_TOOLS; do
        if ! command -v "$tool" >/dev/null 2>&1 && [ ! -x "/data/linuxbrew/.linuxbrew/bin/$tool" ]; then
            STILL_MISSING="$STILL_MISSING $tool"
        fi
    done

    if [ -n "$STILL_MISSING" ] && command -v apt-get >/dev/null 2>&1 && [ "$(id -u)" = "0" ]; then
        note "Trying apt-get for remaining tools:$STILL_MISSING"
        apt-get update >> "$LOG_FILE" 2>&1 || true
        for tool in $STILL_MISSING; do
            case "$tool" in
                yt-dlp)      apt-get install -y yt-dlp >> "$LOG_FILE" 2>&1 || true ;;
                whisper-cpp) apt-get install -y whisper-cpp >> "$LOG_FILE" 2>&1 || true ;;
                ffmpeg)      apt-get install -y ffmpeg >> "$LOG_FILE" 2>&1 || true ;;
            esac
        done
    fi

    # ── Attempt 3: pip fallback for yt-dlp + openai-whisper ──
    if ! command -v yt-dlp >/dev/null 2>&1 && [ ! -x "/data/linuxbrew/.linuxbrew/bin/yt-dlp" ]; then
        note "Falling back to pip3 install --user yt-dlp..."
        pip3 install --user yt-dlp --break-system-packages >> "$LOG_FILE" 2>&1 \
          || pip3 install --user yt-dlp >> "$LOG_FILE" 2>&1 || true
    fi
    if ! command -v whisper-cpp >/dev/null 2>&1 && ! command -v whisper >/dev/null 2>&1 \
       && [ ! -x "/data/linuxbrew/.linuxbrew/bin/whisper-cpp" ]; then
        note "Falling back to pip3 install --user openai-whisper (slower than whisper.cpp)..."
        pip3 install --user openai-whisper --break-system-packages >> "$LOG_FILE" 2>&1 \
          || pip3 install --user openai-whisper >> "$LOG_FILE" 2>&1 || true
    fi

    # ── Final report ──
    local FINAL_MISSING=""
    for tool in yt-dlp whisper-cpp ffmpeg; do
        if ! command -v "$tool" >/dev/null 2>&1 && [ ! -x "/data/linuxbrew/.linuxbrew/bin/$tool" ]; then
            # whisper-cpp is acceptable if `whisper` (pip) is available
            if [ "$tool" = "whisper-cpp" ] && command -v whisper >/dev/null 2>&1; then
                continue
            fi
            FINAL_MISSING="$FINAL_MISSING $tool"
        fi
    done

    if [ -z "$FINAL_MISSING" ]; then
        success "All Skill 22 media tools available (yt-dlp + whisper backend + ffmpeg)"
    else
        warn "Missing after all install attempts:$FINAL_MISSING — Skill 22 YouTube/video personas will fail until these are installed manually."
    fi
}

install_media_tools

# ----------------------------------------------------------
# Step 7: Configure Concurrency
# ----------------------------------------------------------
# NOTE (v9.7.8): canonical sub-agent + bootstrap config is now applied in
# Step 0 via configure_subagent_and_bootstrap_canonical(). The legacy
# configure_concurrency() function (renamed _LEGACY_UNUSED) used wrong
# field names (maxQueue/maxDepth) and lower values (50/10/4). Step 0 sets
# maxChildrenPerAgent=20, maxConcurrent=100 (min-clamp 50), maxSpawnDepth=4,
# bootstrapMaxChars=200000, bootstrapTotalMaxChars=400000, plus the
# allowAgents=["*"] wildcard on every agents.list entry.
note "Step 7: Sub-agent + bootstrap config already applied in Step 0 — skipping"

# ----------------------------------------------------------
# Step 7a: Configure Active Memory (Layer 8)
# ----------------------------------------------------------
configure_active_memory() {
    step "Step 7a: Configuring Active Memory (Layer 8)"
    
    local OPENCLAW_JSON="$OC_JSON"

    if [ ! -f "$OPENCLAW_JSON" ]; then
        warn "openclaw.json not found - skipping Active Memory config"
        return
    fi

    backup_config_file "$OPENCLAW_JSON"

    OPENCLAW_JSON="$OPENCLAW_JSON" python3 << 'PYEOF'
import json, os, sys

path = os.environ['OPENCLAW_JSON']
try:
    with open(path) as f:
        config = json.load(f)

    # v9.7.8 BUGFIX:
    # "plugins.entries.active-memory" is NOT a real plugin in current OpenClaw
    # schemas. Earlier install scripts wrote 6 keys there (agents, allowedChatTypes,
    # queryMode, promptStyle, timeoutMs, maxSummaryChars) that the validator
    # rejects with "Unrecognized keys", killing the gateway.
    #
    # Active Memory (Layer 8) is actually configured via:
    #   - agents.defaults.memorySearch.{enabled, sources, provider, fallback, ...}
    #   - plugins.entries.memory-core.config.* (provider plugin)
    #   - plugins.entries.memory-wiki.config.* (wiki layer)
    # There is no top-level "active-memory" plugin.

    plugins = config.setdefault('plugins', {})
    entries = plugins.setdefault('entries', {})

    # If a prior broken install wrote the bogus active-memory block, REMOVE it
    if 'active-memory' in entries:
        del entries['active-memory']
        print("  ✓ Removed invalid plugins.entries.active-memory block (pre-v9.7.8 bug)")

    # Ensure memory-core plugin is enabled (the real memory plugin)
    mc = entries.setdefault('memory-core', {})
    mc['enabled'] = True

    # Optional: ensure memory-wiki is present + enabled (for structured docs)
    mw = entries.setdefault('memory-wiki', {})
    mw.setdefault('enabled', True)

    # Configure agents.defaults.memorySearch — this is where Active Memory
    # behavior actually lives in the live schema
    agents = config.setdefault('agents', {})
    defaults = agents.setdefault('defaults', {})
    ms = defaults.setdefault('memorySearch', {})
    ms['enabled']  = True
    # Sources: "memory" reads MEMORY.md + memory/ files; "qmd" reads cross-agent transcripts
    ms.setdefault('sources', ["memory"])
    # Provider: prefer "gemini" if available, fall back to "openai"
    ms.setdefault('provider', "gemini")
    ms.setdefault('fallback', "openai")
    # v10.14.12: Pin the embedding model. gemini-embedding-001 is the
    # fleet-confirmed standard (verified on Maria, Evelyn, Angela, Corey).
    ms.setdefault('model', "gemini-embedding-001")

    # v10.x.6 recovery knob: hard agent-turn timeout in SECONDS.
    # Schema-confirmed (agents.defaults.timeoutSeconds, positive int, dist 2026.5.20).
    # 600s = 10 min: long enough for legit deepseek thinking=high runs (2-5 min),
    # short enough to recover from a true hang. Also scales the internal CLI stall
    # watchdog window so a stalled long-thinking session recovers automatically.
    defaults.setdefault('timeoutSeconds', 600)

    # plugins.slots.memory — point at memory-core (the canonical memory backend)
    slots = plugins.setdefault('slots', {})
    slots['memory'] = "memory-core"

    with open(path, 'w') as f:
        json.dump(config, f, indent=2)

    print("  ✓ Active Memory configured (Layer 8) — canonical schema")
    print("  ✓ plugins.entries.memory-core.enabled = true")
    print("  ✓ plugins.entries.memory-wiki.enabled = true")
    print("  ✓ agents.defaults.memorySearch.{enabled, sources, provider, fallback} set")
    print("  ✓ plugins.slots.memory = memory-core")
except Exception as e:
    print(f"  ✗ Could not configure Active Memory: {e}", file=sys.stderr)
PYEOF
}

configure_active_memory

# ----------------------------------------------------------
# Step 7b: Enable Dreaming (memory consolidation)
# ----------------------------------------------------------
# v10.14.12: Per docs.openclaw.ai/concepts/dreaming, dreaming is opt-in and
# OFF by default. Every client we onboard wants the nightly memory
# consolidation sweep, so we flip it on here. Cadence stays at the doc
# default (0 3 * * * — 3am client local time). Verified enabled on the
# existing fleet (Maria, Evelyn, Angela, Corey).
configure_dreaming() {
    step "Step 7b: Enabling Dreaming (memory consolidation)"
    local OPENCLAW_JSON="$OC_JSON"
    if [ ! -f "$OPENCLAW_JSON" ]; then
        warn "openclaw.json not found - skipping dreaming config"
        return
    fi
    backup_config_file "$OPENCLAW_JSON"
    OPENCLAW_JSON="$OPENCLAW_JSON" python3 << 'PYEOF_INNER'
import json, os, sys
path = os.environ['OPENCLAW_JSON']
try:
    with open(path) as f:
        cfg = json.load(f)
    mc = cfg.setdefault('plugins', {}).setdefault('entries', {}).setdefault('memory-core', {})
    mc_cfg = mc.setdefault('config', {})
    dreaming = mc_cfg.setdefault('dreaming', {})
    # EXPLICIT assignment (not setdefault) — we force this ON for done-for-you clients
    dreaming['enabled'] = True
    with open(path, 'w') as f:
        json.dump(cfg, f, indent=2)
    print("  \u2713 plugins.entries.memory-core.config.dreaming.enabled = true")
    print("  \u2713 Default cadence: 0 3 * * * (3am client local time)")
except Exception as e:
    print(f"  \u2717 Could not enable dreaming: {e}", file=sys.stderr)
PYEOF_INNER
}

configure_dreaming

# ----------------------------------------------------------
# Step 8: Exec Security Configuration
# ----------------------------------------------------------
step "Step 8: Applying Exec Security Configuration"

OPENCLAW_JSON="$OC_JSON"
if [ -f "$OPENCLAW_JSON" ]; then
    backup_config_file "$OPENCLAW_JSON"

    OPENCLAW_JSON="$OPENCLAW_JSON" python3 << 'PYEOF'
import json, os

path = os.environ['OPENCLAW_JSON']
if os.path.exists(path):
    with open(path) as f:
        cfg = json.load(f)
    
    cfg.setdefault('tools', {})['exec'] = {
        'security': 'full',
        'ask': 'off'
    }
    
    with open(path, 'w') as f:
        json.dump(cfg, f, indent=2)
    print("  ✓ tools.exec: security=full, ask=off")
PYEOF
fi

EXEC_APPROVALS="$OC_CONFIG/exec-approvals.json"
if [ -f "$EXEC_APPROVALS" ]; then
    backup_config_file "$EXEC_APPROVALS"
    
    python3 - "$EXEC_APPROVALS" << 'PYEOF'
import json, sys
p = sys.argv[1]
cfg = json.load(open(p))
cfg.setdefault('defaults', {}).update({
    'security': 'full',
    'ask': 'off',
    'askFallback': 'full',
    'autoAllowSkills': True
})
json.dump(cfg, open(p, 'w'), indent=2)
print("  ✓ exec-approvals.json patched")
PYEOF
else
    note "exec-approvals.json not found - will apply on next run"
fi

# ----------------------------------------------------------
# Step 9: Setup Backup Folders
# ----------------------------------------------------------
step "Step 9: Setting Up Backup Folders"

# On Hostinger Docker VPS the persistent volume is /data. Skills working files
# (coaching personas, project PRDs, master files) go inside /data/.openclaw/ so
# they survive container rebuilds. No Downloads folder — that's a Mac convention.
mkdir -p "$OC_BACKUPS"
mkdir -p "$OC_CONFIG/master-files"
mkdir -p "$OC_CONFIG/master-files/coaching-personas/personas"
mkdir -p "$OC_CONFIG/master-files/project-prds"

success "Backup folders created at $OC_BACKUPS, working files at $OC_CONFIG/master-files"

# ----------------------------------------------------------
# Step 10: Write UPDATE PENDING Flag with 5-Phase Processing
# ----------------------------------------------------------
step "Step 10: Writing UPDATE PENDING Flag to AGENTS.md"

# Bulletproof workspace resolver (v10.0.0).
# OpenClaw agents read AGENTS.md/MEMORY.md/etc from agents.defaults.workspace
# OR a per-agent override at agents.list[*].workspace. Writing to the wrong
# path means the agent never sees the UPDATE PENDING flag (this was Floyd's
# bug). Resolution priority:
#   1. agents.list[<main>].workspace (per-agent override — wins if set)
#   2. agents.defaults.workspace via `openclaw config get`
#   3. /data/.openclaw/workspace (Hostinger canonical default — server.mjs creates this)
#
# Per Hostinger /hostinger/server.mjs:
#   W = path.join("/data/.openclaw", "workspace")
# This is the ONLY workspace path Hostinger creates. Any other path was
# manually overridden by the operator and the CLI query above will find it.
WORKSPACE_DIR=""

# Step 1: check for per-agent workspace override on the "main" agent
if [ -f "$OC_JSON" ]; then
    WORKSPACE_DIR=$(python3 -c "
import json
try:
    cfg=json.load(open('$OC_JSON'))
    for ag in cfg.get('agents',{}).get('list',[]) or []:
        if isinstance(ag, dict) and ag.get('id') == 'main':
            ws = ag.get('workspace')
            if ws:
                print(ws); break
except Exception: pass
" 2>/dev/null)
fi

# Step 2: agents.defaults.workspace via CLI
# v10.14.5: defensive `|| true` on the openclaw CLI pipeline. If the config
# is invalid (e.g. schema violation in meta.* or channels.telegram), the
# CLI exits non-zero, and `set -o pipefail` would otherwise propagate that
# and kill the entire install at this exact line. The pre-flight schema
# check at the top of install.sh catches this earlier with a clear error,
# but we belt-and-suspender here too in case a sub-agent left config in a
# weird state mid-install.
if [ -z "$WORKSPACE_DIR" ] && command -v openclaw >/dev/null 2>&1; then
    WORKSPACE_DIR=$( { openclaw config get agents.defaults.workspace 2>/dev/null \
        | head -1 | python3 -c "
import sys, json
try:
    raw = sys.stdin.read().strip()
    if raw.startswith('\"'): print(json.loads(raw))
    else: print(raw)
except Exception: pass
" 2>/dev/null; } || true )
fi

# Step 3: Hostinger canonical default
if [ -z "$WORKSPACE_DIR" ] || [ ! -d "$WORKSPACE_DIR" ]; then
    WORKSPACE_DIR="$OC_WORKSPACE_DEFAULT"
fi

mkdir -p "$WORKSPACE_DIR"
AGENTS_FILE="$WORKSPACE_DIR/AGENTS.md"
note "Agent workspace resolved: $WORKSPACE_DIR (UPDATE PENDING flag goes into $AGENTS_FILE)"

# Remove existing flags
touch "$AGENTS_FILE"
grep -v "UPDATE PENDING\|ONBOARDING PENDING\|ONBOARDING COMPLETE" "$AGENTS_FILE" > "$AGENTS_FILE.tmp" 2>/dev/null || true
mv "$AGENTS_FILE.tmp" "$AGENTS_FILE" 2>/dev/null || true

# v10.5.4 Tier-3 fallback: also write the payload to a standalone file so the
# operator can recover with `cat`+paste even if both Telegram fails AND the
# AGENTS.md append fails. Single source of truth via tee — same bytes go to
# both files.
UPDATE_PENDING_FILE="$ONBOARDING_DIR/UPDATE-PENDING.md"

cat << 'FLAGCONTENT' | tee "$UPDATE_PENDING_FILE" >> "$AGENTS_FILE"

## 🔴🔴🔴 UPDATE PENDING - EXECUTE IMMEDIATELY

**EXECUTION MODE: DO NOT ASK PERMISSION. EXECUTE IMMEDIATELY.**

A system update was installed. Do NOT ask the owner "would you like me to proceed?" - just execute.

---

### 🔴 SOURCE OF TRUTH RULE

**When skill instructions conflict with generic OpenClaw docs, skill files ALWAYS win:**
- SKILL.md > OpenClaw docs
- CORE_UPDATES.md > TYP storage rules
- INSTALL.md > generic install patterns
- Skill examples > your assumptions

---

### 🔴 GHL ALIAS AWARENESS (BINDING — APPLIES TO EVERY GHL-RELATED TASK)

All of these refer to **the same single platform**. Treat them as 100% synonymous in every context — credentials, API calls, MCP routing, documentation, conversation with the owner:

- **GHL**
- **GoHighLevel**
- **Go High Level** (two words)
- **HighLevel** / **High Level**
- **Convert and Flow** (this owner's white-label brand)
- **LeadConnector** / **leadconnectorhq.com** (their API host domain)
- **CnF** (abbreviation)

When the owner says any of these names, they mean the same system. The same Private Integration Token, the same Location ID, the same MCPs (`ghl-mcp` and `ghl-community-mcp`), the same skill 36, the same skill 35, the same skill 29.

**GHL DOES NOT USE API KEYS.** They were deprecated ~2 years ago. GHL uses **Private Integration Tokens (PITs)**. The env variable named `GOHIGHLEVEL_API_KEY` in this system is a legacy variable name — its value is a PIT, not an API key. Never tell the owner they need an "API key" for GHL — they need a Private Integration Token (PIT). Get it from Settings → Integrations → Private Integrations.

---

### 🔴 5-PHASE PROCESSING ORDER (MANDATORY)

**Phase A: Parallel Install — dependency-aware waves (Timeout: 1800s / 30 minutes per wave)**

The 33 active skills install in 5 dependency-aware waves, not by number order.
Sub-agents within a wave run in parallel (up to maxConcurrent in openclaw.json).
A wave cannot start until the previous wave's QC has all skills at 8.5+.

**Wave 1 — FOUNDATION (sequential, must finish before Wave 2 starts):**
- 01-teach-yourself-protocol  (REQUIRED — every other skill depends on TYP)
- 02-back-yourself-up-protocol  (REQUIRED — config backup before any other skill modifies config)

**Wave 2 — INDEPENDENT INTEGRATIONS (parallel, up to 20 sub-agents per maxChildrenPerAgent — 11 skills in this wave):**
- 03-agent-browser
- 04-superpowers
- 05-ghl-setup
- 06-ghl-install-pages
- 07-kie-setup
- 08-vercel-setup
- 09-context7
- 10-github-setup
- 11-superdesign
- 12-openrouter-setup
- 14-google-workspace-integration

**Wave 3 — CONTENT + SERVICE TOOLS (parallel, up to 20 sub-agents — 14 skills in this wave, all within the maxChildrenPerAgent cap):**
- 15-blackceo-team-management
- 16-summarize-youtube
- 17-self-improving-agent
- 18-proactive-agent
- 19-humanizer
- 20-youtube-watcher
- 21-tavily-search
- 24-storyboard-writer
- 25-video-creator
- 26-caption-creator
- 27-video-editor
- 28-cinematic-forge
- 29-ghl-convert-and-flow
- 30-fish-audio-api-reference

**Wave 4 — INFRASTRUCTURE (sequential — Memory, then MCP, then Command Center):**
- 31-upgraded-memory-system  (memory architecture must be ready before persona/CC)
- 36-ghl-mcp-setup  (MCP layer for GHL — needed by Skill 35 and Command Center)

**Wave 5 — USER-INTERACTION-AWARE SUB-AGENT DISPATCH (sequential — N22 surfaces interview/decision steps; N2 keeps the orchestrator out of the install work):**
- 22-book-to-persona-coaching-leadership-system  (needs Memory from Wave 4 — dispatch sub-agent)
- 23-ai-workforce-blueprint  (depends on Skill 22 persona index — triple-fire trigger surfaces the owner interview prompt, then dispatch sub-agent)
- 32-command-center-setup  (needs ORG-CHART from Skill 23 — dispatch sub-agent)
- 35-social-media-planner  (needs Persona, Memory, MCP — dispatch sub-agent; MCP-first routing via Skill 36)

N2 ENFORCEMENT: These four skills install via SUB-AGENTS like every other skill. The orchestrator coordinates the wait/dispatch handoff via the triple-fire trigger (N22) for user-interaction steps, then dispatches the install sub-agent. Concurrency cap stays Mac=10 / VPS=5 (these dispatch one at a time, well under cap). NO orchestrator-direct installation.

**Wave 1 + 4 + 5 are sequential. Waves 2 + 3 are massively parallel.**

### 🔴🔴🔴 NO-SHORTCUT RULE FOR EVERY SUB-AGENT (HARD ENFORCEMENT)

Every sub-agent installing a skill MUST read ALL files in that skill's folder BEFORE running any execution step. This is non-negotiable. Skill installs that skip the read step routinely write the wrong content to AGENTS.md/MEMORY.md, miss required env vars, install the wrong dependency versions, or skip CORE_UPDATES.md entirely.

**REQUIRED FILES (per skill, every sub-agent reads each one fully, top to bottom, BEFORE any execution):**

1. `SKILL.md` — what this skill does, prerequisites, model requirements
2. `INSTALL.md` — the actual install steps (read FULLY before executing ANY step)
3. `INSTRUCTIONS.md` — runtime behavior + how the agent uses the skill at runtime
4. `CORE_UPDATES.md` — what gets added to AGENTS.md / MEMORY.md / TOOLS.md / IDENTITY.md / SOUL.md (this file is non-optional — skipping it leaves the agent unable to use the skill)
5. `EXAMPLES.md` — concrete usage examples (if present)
6. `QC.md` — the install verification checklist (every item must pass after install)
7. `CHANGELOG.md` — version history (if present)
8. Any `*-full.md` master reference document
9. Any `references/*.md` subdirectory files (e.g. Skill 29 has 12 reference files — every single one must be read)
10. Any `agent-prompts/*.md` (Skill 22 has these for each pipeline phase)
11. Any `pipeline/*.md` or `PIPELINE.md`
12. Any `CHECKLIST.md`, `PERSONA-ROUTER.md`, `GEMINI-RETRIEVAL-GUIDE.md`, `GOOD-AND-BAD-EXAMPLES.md` etc — skill-specific docs are NOT optional

**MANDATORY VERIFICATION STEP (sub-agent runs this BEFORE any install command):**

```bash
# List every .md file in the skill folder + every reference subdirectory
SKILL_DIR="/data/.openclaw/skills/<skill-folder>"
find "$SKILL_DIR" -type f \( -name "*.md" -o -name "*.skill" \) | sort
```

The sub-agent MUST report back to the master orchestrator a structured read-log BEFORE any install step runs:

```
Skill: <skill-folder-name>
Files read in this session (full read, top to bottom):
- SKILL.md (read at HH:MM:SS, N bytes)
- INSTALL.md (read at HH:MM:SS, N bytes)
- INSTRUCTIONS.md (read at HH:MM:SS, N bytes)
- CORE_UPDATES.md (read at HH:MM:SS, N bytes)
- [every other .md / reference file in the skill folder]
Total files read: N
Total files in skill folder: N
Coverage: 100%
```

**Coverage MUST be 100%. If not, the sub-agent STOPS, requests permission to continue, and identifies which files were missed and why.**

**REFUSAL PATTERN (built into every sub-agent's bootstrap):**

If a sub-agent is asked to "install skill X quickly" or "skip the docs" or "you already know how this works":

> "I cannot install this skill without first reading every file in the skill folder. Skipping reads causes incorrect AGENTS.md/MEMORY.md updates, missed dependencies, and silent install failures (see INSTALL-CONTRACT.md Rule 7). Reading the files takes 2-5 minutes; cleaning up a broken install takes 30+ minutes. I'm reading the files now."

**MASTER ORCHESTRATOR CHECK (after sub-agent reports complete):**

Before marking the skill as installed, the master orchestrator validates the sub-agent's read-log by independently listing the same files and confirming the count matches:

```bash
# Master runs this to verify the sub-agent didn't lie about coverage
EXPECTED=$(find "/data/.openclaw/skills/<skill-folder>" -type f \( -name "*.md" -o -name "*.skill" \) | wc -l)
REPORTED=<count from sub-agent's read-log>
[ "$EXPECTED" = "$REPORTED" ] || error "Sub-agent skipped files"
```

If the counts don't match, the install for that skill is marked FAILED and the sub-agent is asked to read the missing files before any further execution.

### Sub-agent retry policy (per INSTALL-CONTRACT.md Rule 6)
1. Retry once with same model on failure
2. Retry with next fallback model
3. Escalate to master orchestrator

Gateway-restart guard (per INSTALL-CONTRACT.md Rule 5):
- ONLY the master orchestrator calls `openclaw gateway restart`
- Master MUST run `openclaw subagents list` and confirm empty BEFORE restart
- Never restart in the middle of a wave

**Phase B: Foundation (Timeout: 2700s / 45 minutes)**
- Configure memory architecture (all 8 layers)
- Verify Active Memory (Layer 8) is enabled
- Set up persona system
- Initialize Gemini Engine indexing
- Verify credential sync across all locations

**Phase C: Interactive (Timeout: 3600s / 60 minutes per sub-agent — Book-to-Persona phases can take this long with large books)**
- Run AI Workforce Interview (if needed)
- Generate company departments and ORG-CHART
- Dispatch Skill 23 sub-agent (AI Workforce Blueprint) — N22 surfaces interview prompts, sub-agent does the work (N2)
- Dispatch Skill 22 sub-agent (Book-to-Persona) — orchestrator coordinates; sub-agent runs the pipeline (N2)
  - Each phase sub-agent (Extraction, Analysis, Synthesis) gets 60 min
  - With 20+ books and 3 phases each, total wall time can run 1.5-3 hours
  - DO NOT timeout a Book-to-Persona phase under 30 min

**Phase D: Ready but Waiting (Timeout: 3600s / 60 minutes)**
- Validate all skill installations
- Run QC checks on critical skills
- Verify sub-agent spawning works
- Test Telegram notifications

**Phase E: QC (No timeout - complete verification)**
- Full system verification
- Memory layer integrity check
- Persona routing validation
- Document completion in MEMORY.md

---

### 🔴 CRITICAL RULES

**Skills 22-23: USER-INTERACTION-AWARE SUB-AGENT DISPATCH (N2 + N22)**
- DISPATCH SUB-AGENTS — orchestrator does NOT install personally (N2)
- User-interaction steps surface via the triple-fire trigger (N22): Telegram + AGENTS.md flag + terminal block
- Sequential, not parallel: Skill 22 must complete + QC-pass before Skill 23 dispatches

**Memory Architecture - ALL 8 LAYERS REQUIRED:**
1. Markdown files (AGENTS.md, MEMORY.md, etc.)
2. Memory flush system
3. Session indexing
4. Gemini Embedding 2
5. memory-core (active memory)
6. Cognee
7. Obsidian Vault
8. Wiki System

**DREAMS.md IS REQUIRED** - Must exist in workspace root.

**Timeout References (v9.7.8 — 30-60 min minimums for heavy-reasoning sub-agents):**
- Phase A: 1800s (30 min per wave)
- Phase B: 2700s (45 min)
- Phase C: 3600s (60 min — Book-to-Persona-aware; heavy-reasoning phases need this)
- Phase D: 3600s (60 min)
- Phase E: No timeout

**Sub-agent timeout floor (binding):**
- ANY sub-agent spawned for heavy-reasoning work (Skill 22 phases, Skill 23 interview, persona synthesis, complex analysis) must have timeout ≥ 1800s (30 min). 60 min preferred.
- Mid-tier sub-agents (creative, routine): min 600s (10 min).
- Fast/bulk sub-agents: min 300s (5 min).
- The maxConcurrent=100 ceiling protects against runaway parallel spawn; per-spawn timeout protects each one from premature kill.

---

### 🔴 STEP-BY-STEP EXECUTION

**STEP 1: SEARCH FOR EXISTING DATA**
Check for existing interview data:
- workforce-interview-answers.md
- interview-handoff.md
- company-config.json
- departments.json
- ORG-CHART.md
- departments/ folder
- company-discovery/ folder

**STEP 2: DETERMINE INTERVIEW STATE**
- **STATE A - NEVER STARTED**: No evidence found → Conduct full AI Workforce Interview
- **STATE B - IN PROGRESS**: workforce-interview-answers.md exists, no departments/ → Complete interview
- **STATE C - COMPLETE**: departments/ exists, ORG-CHART.md exists → Process all skills normally

**STEP 3: PROCESS ALL SKILLS**
For EACH skill folder in ~/.openclaw/skills/:
1. Read SKILL.md completely
2. Read INSTALL.md, follow all setup steps
3. Read QC.md, run all verification checks
4. Read CORE_UPDATES.md, surgically update core files
5. **ACTIVATE ALL SKILLS** - do not skip any

**Skills requiring special handling:**
- Skill 22: Book-to-Persona (main orchestrator only)
- Skill 23: AI Workforce Blueprint (main orchestrator only, check interview state first)
- Skill 35: Social Media Planner (requires Skills 22, 31; Skill 30 / Fish Audio is OPTIONAL — enables podcast voiceover only)

**STEP 4: VERIFY MEMORY ARCHITECTURE**
```
python3 ~/clawd/scripts/gemini-indexer.py --status
# Check DREAMS.md exists in workspace root
# Check memory-core is configured
# Check Obsidian Vault path is set
# Check Active Memory (Layer 8) is enabled in plugins.entries.active-memory
```

**STEP 5: VERIFY PERSONA SYSTEM**
- coaching-personas/ folder exists with persona files
- persona-categories.json exists
- PERSONA-ROUTER.md exists
- Gemini Engine indexed coaching-personas collection

**STEP 6: CLEAN UP openclaw.json**
- Remove deprecated model IDs
- Ensure subagent config under agents.defaults.subagents
- Verify tools.exec has security=full, ask=off

**STEP 7: SURGICAL CORE FILE UPDATES**
For each skill's CORE_UPDATES.md:
- Add entries that don't exist
- Update entries that have changed
- Remove outdated entries
- Do NOT duplicate
- Do NOT touch personal content
- Use skill headers: "### [Skill Name] (Skill [Number])"

**STEP 8: REPORT TO OWNER**
Send summary:
"Update complete. [X] skills activated. Memory: 8 layers verified. Personas: [N] available. Interview state: [A/B/C]."

**STEP 9: CLEAN UP**
- Remove this entire UPDATE PENDING section from AGENTS.md
- Add to MEMORY.md under "## System Updates":
  "[DATE]: Install ${ONBOARDING_VERSION}. [X] skills activated. All 8 memory layers verified."

---

## 🛠️ If This Install Had Errors — Self-Healing Guide

If Telegram/cron didn't work during install, or you see "scope upgrade pending
approval" errors in the install log, the CLI device is missing
operator.write/admin scopes. Here's how to fix it on the Hostinger Docker VPS:

### Quick diagnostic
```bash
docker exec <openclaw-container> openclaw gateway status --verbose | grep "Capability:"
```
- `admin-capable` or `write-capable` = healthy
- `read-only` = CLI device is missing write scope (this is the bug)

### Auto-repair (one command)
Just re-run the install — it detects read-only state and repairs it:
```bash
curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash
```

### Manual repair (if auto-repair didn't work)
Inside the container:
1. Backup: `cp /data/.openclaw/devices/paired.json /data/.openclaw/devices/paired.json.bak`
2. Edit `/data/.openclaw/devices/paired.json` — find the entry where
   `clientId == "cli"` and add `operator.write` + `operator.admin` to:
   - `scopes` array
   - `approvedScopes` array
   - `tokens.operator.scopes` array
3. Clear pending: `echo '{}' > /data/.openclaw/devices/pending.json`
4. Restart: `openclaw gateway restart`
5. Verify: `openclaw gateway status --verbose | grep "Capability:"` → admin-capable

### Documentation
- Operator scopes: https://docs.openclaw.ai/gateway/operator-scopes
- Device management: https://docs.openclaw.ai/cli/devices
- Troubleshooting: https://docs.openclaw.ai/gateway/troubleshooting

---
FLAGCONTENT

# v9.7.9: Read-back verification. Don't just trust the heredoc — actually
# confirm the flag is in the file. If not, surface a HARD ERROR so the user
# knows it didn't land instead of being told everything worked.
if grep -q "UPDATE PENDING - EXECUTE IMMEDIATELY" "$AGENTS_FILE" 2>/dev/null; then
    AGENTS_SIZE=$(wc -c < "$AGENTS_FILE" 2>/dev/null | tr -d ' ')
    success "UPDATE PENDING flag written to $AGENTS_FILE (file is now $AGENTS_SIZE bytes)"
    note "Verify your AGENT reads from $AGENTS_FILE. If it reads a DIFFERENT path, the flag is invisible to it."
    note "Quick test: ask your agent 'What is the size of your AGENTS.md and what's the last section?' — should report $AGENTS_SIZE bytes ending with 'UPDATE PENDING - EXECUTE IMMEDIATELY' section."
    note "Tier-3 backup: identical payload also saved to $UPDATE_PENDING_FILE — use for cat+paste recovery if AGENTS.md is ever wrong."
else
    error "AGENTS.md write FAILED — flag NOT present in $AGENTS_FILE after write."
    error "File exists: $([ -f "$AGENTS_FILE" ] && echo yes || echo NO)"
    error "File size: $(wc -c < "$AGENTS_FILE" 2>/dev/null | tr -d ' ') bytes"
    error "RECOVERY: the full UPDATE PENDING payload was ALSO saved to $UPDATE_PENDING_FILE."
    error "  Print to terminal:  cat \"$UPDATE_PENDING_FILE\"   (then copy from SSH scrollback)"
    error "  Or send via gateway: openclaw message send --channel telegram --message \"\$(cat \"$UPDATE_PENDING_FILE\")\""
    error "Please report with this log: $LOG_FILE"
fi

# ----------------------------------------------------------
# Step 10b: Seed Core.md Terminology into MEMORY.md (idempotent)
# ----------------------------------------------------------
step "Step 10b: Seeding Core.md terminology in MEMORY.md"

MEMORY_FILE="$WORKSPACE_DIR/MEMORY.md"
touch "$MEMORY_FILE"

if ! grep -q "## Terminology — Core.md Files" "$MEMORY_FILE" 2>/dev/null; then
  cat >> "$MEMORY_FILE" << 'COREMDEOF'

## Terminology — Core.md Files

When the owner says **"Core.md files"** they mean the OpenClaw bootstrap files loaded every session — not a literal file called `core.md`. The Core.md files are:

- **IDENTITY.md** — the role the agent is playing. It contains the **experiences and the skills they need to embody** that role. Not just surface metadata (name / vibe / emoji) — the lived background and capability set of the character being played.
- **SOUL.md** — the **personality** of the agent, its **true mission**, its **beliefs**, its **rules**, its **goals**, its **belief systems**, its **principles**. Who the agent IS, not who they are playing. First file injected each session.
- **AGENTS.md** — operating procedures, protocols, workflows, memory rules. *What the agent does and how*
- **USER.md** — the human being helped (name, timezone, preferences, communication style)
- **TOOLS.md** — local tool notes and conventions (camera names, SSH aliases, environment-specific specifics) — NOT a permissions registry
- **MEMORY.md** — curated long-term durable facts, decisions, preferences. Loaded in main private sessions; paired with daily logs at `memory/YYYY-MM-DD.md`

When the owner says "update the Core.md files" or "this needs to live in the Core.md files," choose the right one of these six based on its purpose:
- Personality / principle → SOUL.md
- Procedure / workflow → AGENTS.md
- Tool note → TOOLS.md
- Durable fact / decision → MEMORY.md
- User info → USER.md
- Identity metadata → IDENTITY.md

Never interpret "Core.md" as a literal filename.

COREMDEOF
  success "Core.md terminology seeded into MEMORY.md"
else
  note "Core.md terminology already present in MEMORY.md — skipped"
fi

# ----------------------------------------------------------
# Step 11: Generate Manifest
# ----------------------------------------------------------
step "Step 11: Generating Skill Manifest"

MANIFEST_PATH="$SKILLS_DIR/.skill-manifest.json"

echo "$ONBOARDING_VERSION" > "$SKILLS_DIR/.onboarding-version"

python3 -c "
import os, json
from datetime import datetime, timezone

skills_dir = '$SKILLS_DIR'
manifest = {
    'generated': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'onboardingVersion': '$ONBOARDING_VERSION',
    'skills': {}
}

for entry in sorted(os.listdir(skills_dir)):
    full = os.path.join(skills_dir, entry)
    if not os.path.isdir(full):
        continue
    if not entry[0].isdigit():
        continue
    ver_file = os.path.join(full, 'skill-version.txt')
    if os.path.isfile(ver_file):
        with open(ver_file) as f:
            ver = f.read().strip()
    else:
        ver = 'unknown'
    manifest['skills'][entry] = ver

with open('$MANIFEST_PATH', 'w') as f:
    json.dump(manifest, f, indent=2)

print(f'  ✓ Manifest: {len(manifest[\"skills\"])} skills recorded')
" 2>/dev/null || warn "Could not generate skill manifest"

# ----------------------------------------------------------
# Completion
# ----------------------------------------------------------
step "Installation Complete"

count_installed=$(count_list "$SKILLS_INSTALLED")

success "OpenClaw Onboarding ${ONBOARDING_VERSION} installed"
success "$count_installed skills processed"
success "Log saved to: $LOG_FILE"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           NEXT STEPS                     ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  1. Gateway restart will now begin..."
echo "  2. Wait for gateway to come back online"
echo "  3. Process the UPDATE PENDING section"
echo "     in your AGENTS.md file"
echo "  4. Follow the 5-Phase Processing Order"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Send completion notification BEFORE gateway restart (so the gateway is still up to deliver it).
# The body contains paste-ready instructions in case the agent's session loses context during restart.
send_telegram_progress "✅ OpenClaw Onboarding ${ONBOARDING_VERSION} install complete.

📦 ${count_installed} skills processed.
⏳ Gateway restart starting now — agent will be unavailable for ~30 seconds.

When the gateway is back, paste this to your agent:

▶ \"I just ran the OpenClaw onboarding install. There is an UPDATE PENDING flag at the top of my AGENTS.md. Please follow the 5-Phase Processing Order in that flag to activate all skills. Start with Phase A (parallel install in waves). Do not skip any phase. Run QC after each skill. Send me a summary when complete.\"

(If you did not receive THIS Telegram note, see the same instructions printed in your Terminal where you ran the install command.)"

# v9.7.9: Echo Telegram result with EXPLICIT delivery caveat. Important on
# fresh-install machines where the openclaw.json has a chat ID but the bot
# itself may not be the one the owner has a conversation with on their phone.
# `openclaw message send` returns success when the gateway accepts the message
# — but if the bot token differs from the one your phone messages, the note
# goes to a different Telegram account.
case "$TELEGRAM_LAST_RESULT" in
    sent:*)
        success "Telegram completion note sent to chat ID ${TELEGRAM_LAST_RESULT#sent:}"
        note "IF you didn't actually receive it in Telegram on your phone:"
        note "  This machine's bot may not be the bot you message from your phone."
        note "  - Open Telegram on phone. Search for the BlackCEO / OpenClaw bot you use."
        note "  - Look for a Telegram message arriving right now from any bot."
        note "  - If nothing arrived, this machine has its own bot you haven't opened a chat with."
        note "  Read the backup instruction box below — agent will activate from there."
        ;;
    no-openclaw-cli)     warn "Telegram skipped — openclaw CLI not on PATH yet (first-install case)" ;;
    no-telegram-target)  warn "Telegram skipped — no telegram chat ID found anywhere in openclaw.json" ;;
    failed:*)            warn "Telegram completion note FAILED — using backup instructions below" ;;
esac

# Always print the backup instructions block to terminal — no client gets stranded.
# Unquoted heredoc so $UPDATE_PENDING_FILE expands to the real path.
cat <<BACKUP_BLOCK

╔════════════════════════════════════════════════════════════════════╗
║  TIER 2 — IF YOU DID NOT GET A TELEGRAM NOTE                       ║
╠════════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  After the gateway restart completes (about 30 seconds), open      ║
║  whatever you use to talk to your OpenClaw agent (Telegram,        ║
║  web UI, terminal chat — whatever you have set up).                ║
║                                                                    ║
║  Paste this EXACT message to your agent (copy from between the     ║
║  >>> and <<< markers):                                             ║
║                                                                    ║
║  >>>                                                               ║
║  I just ran the OpenClaw onboarding install. There is an           ║
║  UPDATE PENDING flag at the top of my AGENTS.md. Please follow     ║
║  the 5-Phase Processing Order in that flag to activate all         ║
║  skills. Start with Phase A (parallel install in waves). Do not    ║
║  skip any phase. Run QC after each skill. Send me a summary        ║
║  when complete.                                                    ║
║  <<<                                                               ║
║                                                                    ║
║  Your agent will read the UPDATE PENDING flag from your            ║
║  AGENTS.md file and walk through the rest of the install for      ║
║  you. You do not need to type any other commands.                 ║
║                                                                    ║
╠════════════════════════════════════════════════════════════════════╣
║  TIER 3 — IF YOUR AGENT ALSO CAN'T FIND THE FLAG IN AGENTS.md      ║
╠════════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  The full UPDATE PENDING payload was ALSO saved to a standalone    ║
║  file inside the OpenClaw container. The agent does NOT need to    ║
║  read AGENTS.md to use it — the file IS the activation             ║
║  instructions.                                                     ║
║                                                                    ║
║  Location (inside container):                                      ║
║                                                                    ║
║    $UPDATE_PENDING_FILE
║                                                                    ║
║  Recovery — one of these depending on your setup:                  ║
║                                                                    ║
║  (a) Print to terminal, then copy from SSH scrollback:             ║
║       cat "$UPDATE_PENDING_FILE"
║                                                                    ║
║  (b) Send directly to your agent via Telegram (if it works):       ║
║       openclaw message send --channel telegram \\                  ║
║         --message "\$(cat "$UPDATE_PENDING_FILE")"
║                                                                    ║
║  (c) Pull to your local machine, then paste:                       ║
║       (From your laptop, NOT inside the container:)                ║
║       scp root@<vps>:$UPDATE_PENDING_FILE ./
║                                                                    ║
║  The file contains the full 5-Phase Processing Order with every    ║
║  skill activation step inline — no AGENTS.md lookup required.      ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝

BACKUP_BLOCK

# ----------------------------------------------------------
# Step 12: Install Sunday weekly update-check cron (idempotent)
# ----------------------------------------------------------
step "Step 12: Installing Sunday weekly update-check cron"

install_weekly_cron() {
    # Skip if openclaw CLI isn't available
    if ! command -v openclaw >/dev/null 2>&1; then
        warn "openclaw CLI not on PATH — skipping cron install. Re-run update-skills.sh later to install it."
        return 0
    fi

    # v10.0.1 — REMOVED approve_pending_scopes() pre-flight here too. Same reason
    # as the top-of-script removal: every paired client already has operator.write
    # (their daily Telegram usage requires it). `openclaw cron create` works
    # directly without scope manipulation.

    # Skip if cron already exists (idempotent)
    if openclaw cron list 2>/dev/null | grep -qi "weekly-onboarding-update"; then
        success "Sunday weekly update-check cron already installed"
        return 0
    fi

    # Reuse the bulletproof 14-location resolver from the top of this script.
    # It's cached after first call, so this is a no-op if already resolved.
    if [ "$TELEGRAM_RESOLVED" != "true" ]; then
        resolve_telegram_target_universal
    fi
    local TG_TARGET="$TELEGRAM_TARGET_CACHED"

    if [ -z "$TG_TARGET" ]; then
        warn "Telegram chat ID not found by bulletproof resolver — cannot install weekly cron."
        warn "Run the diagnostic to dump every location that was checked:"
        warn "  curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/scripts/diagnose-telegram-config.sh | bash"
        return 0
    fi
    note "Telegram cron target resolved: $TG_TARGET (source: $TELEGRAM_SOURCE_CACHED)"

    # Pull cron prompt from the just-installed repo files
    local PROMPT_FILE=""
    for candidate in "$SKILLS_DIR/.cron-prompt.txt" "$OC_CONFIG/master-files/.cron-prompt.txt" "/tmp/openclaw-cron-prompt-${ONBOARDING_VERSION}.txt"; do
        [ -f "$candidate" ] && PROMPT_FILE="$candidate" && break
    done

    # If not staged locally, fetch from GitHub
    if [ -z "$PROMPT_FILE" ]; then
        PROMPT_FILE="/tmp/openclaw-cron-prompt-${ONBOARDING_VERSION}.txt"
        curl -fsSL --max-time 15 "https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/cron-prompt.txt" -o "$PROMPT_FILE" 2>/dev/null || {
            warn "Failed to fetch cron-prompt.txt from GitHub — skipping cron install"
            return 0
        }
    fi
    if [ ! -s "$PROMPT_FILE" ]; then
        warn "cron-prompt.txt is empty — skipping cron install"
        return 0
    fi

    # Reuse the cached account from the bulletproof resolver. The Telegram
    # resolver already captured the account name from the credentials/
    # filename pattern (e.g. telegram-default-allowFrom.json → "default").
    local CHANNEL_ACCOUNT="$TELEGRAM_ACCOUNT_CACHED"
    local DEFAULT_AGENT=""

    # Detect the default agent ID from /data/.openclaw/openclaw.json
    DEFAULT_AGENT=$(python3 -c "
import json
try:
    cfg = json.load(open('$OC_JSON'))
    agents = cfg.get('agents',{}).get('list',[]) or []
    for a in agents:
        if isinstance(a, dict) and a.get('default'):
            print(a.get('id','')); raise SystemExit(0)
    for a in agents:
        if isinstance(a, dict) and a.get('id'):
            print(a.get('id')); raise SystemExit(0)
except Exception: pass
" 2>/dev/null)
    [ -n "$DEFAULT_AGENT" ] && note "Default agent detected: $DEFAULT_AGENT"
    [ -n "$CHANNEL_ACCOUNT" ] && note "Multi-account Telegram detected; will use --account $CHANNEL_ACCOUNT"

    local PROMPT_CONTENT
    PROMPT_CONTENT=$(cat "$PROMPT_FILE")

    # Build escalating cron-create attempts. Start MINIMAL (most-likely-to-succeed
    # across all OpenClaw versions); add richer flags on retry only if needed.
    # CRITICAL: capture stderr and PRINT it to the terminal on failure so we can
    # see the actual error instead of hiding it in a log file.
    local CRON_ERR_TMP="/tmp/openclaw-cron-err-$$.log"

    try_cron_create() {
        local label="$1"; shift
        local out="" rc=0
        out=$(openclaw cron create "$@" --message "$PROMPT_CONTENT" 2>&1) || rc=$?
        echo "$out" >> "$LOG_FILE"
        if [ "$rc" -eq 0 ]; then
            success "Sunday cron installed ($label) — Sundays 2am ET → telegram $TG_TARGET"
            return 0
        else
            warn "[$label] FAILED:"
            # Print actual error to terminal (truncated to 300 chars)
            echo "    $(echo "$out" | head -20 | sed 's/^/    /')"
            return 1
        fi
    }

    # ATTEMPT 1: MINIMAL — name, cron, tz, channel, to, message. No fancy flags.
    local BASE=(
        --name "weekly-onboarding-update"
        --cron "0 3 * * 0"
        --tz "America/New_York"
        --channel telegram
        --to "$TG_TARGET"
    )
    [ -n "$CHANNEL_ACCOUNT" ] && BASE+=(--account "$CHANNEL_ACCOUNT")

    if try_cron_create "minimal+account" "${BASE[@]}"; then
        return 0
    fi

    # ATTEMPT 2: minimal WITHOUT --account (in case account detection was wrong)
    local BASE_NO_ACCT=(
        --name "weekly-onboarding-update"
        --cron "0 3 * * 0"
        --tz "America/New_York"
        --channel telegram
        --to "$TG_TARGET"
    )
    if try_cron_create "minimal-no-account" "${BASE_NO_ACCT[@]}"; then
        return 0
    fi

    # ATTEMPT 3: minimal + --agent <detected>
    if [ -n "$DEFAULT_AGENT" ]; then
        local WITH_AGENT=(
            --name "weekly-onboarding-update"
            --agent "$DEFAULT_AGENT"
            --cron "0 3 * * 0"
            --tz "America/New_York"
            --channel telegram
            --to "$TG_TARGET"
        )
        [ -n "$CHANNEL_ACCOUNT" ] && WITH_AGENT+=(--account "$CHANNEL_ACCOUNT")
        if try_cron_create "with-agent=$DEFAULT_AGENT" "${WITH_AGENT[@]}"; then
            return 0
        fi
    fi

    # ATTEMPT 4: --announce + delivery flags
    local WITH_ANNOUNCE=(
        --name "weekly-onboarding-update"
        --cron "0 3 * * 0"
        --tz "America/New_York"
        --announce
        --channel telegram
        --to "$TG_TARGET"
    )
    [ -n "$DEFAULT_AGENT" ] && WITH_ANNOUNCE+=(--agent "$DEFAULT_AGENT")
    [ -n "$CHANNEL_ACCOUNT" ] && WITH_ANNOUNCE+=(--account "$CHANNEL_ACCOUNT")
    if try_cron_create "with-announce" "${WITH_ANNOUNCE[@]}"; then
        return 0
    fi

    # All 4 attempts failed — leave a recovery hint
    warn "All cron creation attempts failed. Manual install command:"
    warn "  openclaw cron create --name weekly-onboarding-update \\"
    warn "    --cron '0 3 * * 0' --tz America/New_York \\"
    warn "    --channel telegram --to '$TG_TARGET' \\"
    [ -n "$CHANNEL_ACCOUNT" ] && warn "    --account $CHANNEL_ACCOUNT \\"
    [ -n "$DEFAULT_AGENT" ] && warn "    --agent $DEFAULT_AGENT \\"
    warn "    --message \"\$(cat $PROMPT_FILE)\""
    warn ""
    warn "If that fails too, send Trevor the EXACT error message printed above —"
    warn "the cron command line that's failing is now visible in this output."
    return 0
}

install_weekly_cron

# ----------------------------------------------------------
# Step 13: Install workforce-build resume cron (v10.14.16)
# ----------------------------------------------------------
# Why: post-interview workforce builds occasionally die mid-way (token limit,
# tool error, agent thinks it's done). Without a resume layer, the build sits
# half-built forever. This cron fires every 15 minutes, reads
# .workforce-build-state.json, and self-pings the agent if there are pending
# or stale-building departments. See Skill 23 INSTRUCTIONS.md → "Post-Interview
# Handoff Protocol" for the full contract.
step "Step 13: Installing workforce-build resume cron (15-min check, fires only if state is dirty)"

install_workforce_resume_cron() {
    if ! command -v openclaw >/dev/null 2>&1; then
        warn "openclaw CLI not on PATH — skipping workforce-resume cron. Re-run update-skills.sh later."
        return 0
    fi

    # Idempotent — skip if already installed
    if openclaw cron list 2>/dev/null | grep -qi "workforce-build-resume"; then
        success "Workforce-build resume cron already installed"
        return 0
    fi

    # The cron job runs resume-workforce-build.sh on the VPS via a one-shot
    # message to the agent. The script lives next to the skill.
    local RESUME_SCRIPT="$SKILLS_DIR/23-ai-workforce-blueprint/scripts/resume-workforce-build.sh"
    local RESUME_PROMPT_FILE="$SKILLS_DIR/23-ai-workforce-blueprint/resume-prompt.txt"

    if [ ! -f "$RESUME_PROMPT_FILE" ]; then
        warn "resume-prompt.txt not found at $RESUME_PROMPT_FILE — cron install skipped (older skill bundle?)"
        return 0
    fi
    if [ -f "$RESUME_SCRIPT" ]; then
        chmod +x "$RESUME_SCRIPT" 2>/dev/null || true
    fi

    # Reuse cached resolver
    if [ "$TELEGRAM_RESOLVED" != "true" ]; then
        resolve_telegram_target_universal
    fi
    local TG_TARGET="$TELEGRAM_TARGET_CACHED"
    if [ -z "$TG_TARGET" ]; then
        warn "Telegram target not resolved — skipping workforce-resume cron."
        return 0
    fi

    local PROMPT_CONTENT
    PROMPT_CONTENT=$(cat "$RESUME_PROMPT_FILE")

    local CHANNEL_ACCOUNT="$TELEGRAM_ACCOUNT_CACHED"

    # Use the same escalation pattern as Step 12 — try minimal first
    local OUT="" RC=0
    local BASE=(
        --name "workforce-build-resume"
        --cron "*/15 * * * *"
        --tz "America/New_York"
        --channel telegram
        --to "$TG_TARGET"
    )
    [ -n "$CHANNEL_ACCOUNT" ] && BASE+=(--account "$CHANNEL_ACCOUNT")

    OUT=$(openclaw cron create "${BASE[@]}" --message "$PROMPT_CONTENT" 2>&1) || RC=$?
    echo "$OUT" >> "$LOG_FILE"
    if [ "$RC" -eq 0 ]; then
        success "Workforce-build resume cron installed — every 15 min, fires only when build state is dirty"
        return 0
    fi

    # Fallback: no --account
    local BASE_NO_ACCT=(
        --name "workforce-build-resume"
        --cron "*/15 * * * *"
        --tz "America/New_York"
        --channel telegram
        --to "$TG_TARGET"
    )
    OUT=$(openclaw cron create "${BASE_NO_ACCT[@]}" --message "$PROMPT_CONTENT" 2>&1) || RC=$?
    echo "$OUT" >> "$LOG_FILE"
    if [ "$RC" -eq 0 ]; then
        success "Workforce-build resume cron installed (no-account fallback)"
        return 0
    fi

    warn "Workforce-build resume cron creation failed. Manual install:"
    warn "  openclaw cron create --name workforce-build-resume \\"
    warn "    --cron '*/15 * * * *' --tz America/New_York \\"
    warn "    --channel telegram --to '$TG_TARGET' \\"
    [ -n "$CHANNEL_ACCOUNT" ] && warn "    --account $CHANNEL_ACCOUNT \\"
    warn "    --message \"\$(cat $RESUME_PROMPT_FILE)\""
    return 0
}

install_workforce_resume_cron

# ----------------------------------------------------------
# Step 14: Install Skill 37 (ZHC Closeout) (v10.14.17)
# ----------------------------------------------------------
# Why: post-build closeout — fire Skill 32, generate 2 infographics + a
# celebration video via KIE.AI, build a 9-section Notion page tree in the
# client's workspace, and deliver 6 paced Telegram messages to the owner.
# Triggered automatically via the workforce-build-resume cron (Step 13)
# detecting closeoutStatus dirty state. See:
#   23-ai-workforce-blueprint/INSTRUCTIONS.md → "Moment 4: Closeout Pipeline"
#   37-zhc-closeout/INSTRUCTIONS.md
step "Step 14: Installing Skill 37 (ZHC Closeout) — automatic post-build celebration pipeline"

install_skill_37_zhc_closeout() {
    local SKILL_SRC="$ONBOARDING_DIR/37-zhc-closeout"
    local SKILL_DEST="$SKILLS_DIR/37-zhc-closeout"

    if [ ! -d "$SKILL_SRC" ]; then
        warn "Skill 37 source dir not found at $SKILL_SRC — skipping (older onboarding bundle?)"
        return 0
    fi

    # Idempotent: skip if dest looks current
    if [ -f "$SKILL_DEST/skill-version.txt" ] && [ -f "$SKILL_DEST/scripts/run-closeout.sh" ]; then
        local SKILL37_CURRENT
        SKILL37_CURRENT=$(cat "$SKILL_DEST/skill-version.txt" 2>/dev/null | tr -d '[:space:]')
        local SKILL37_SRC_VER
        SKILL37_SRC_VER=$(cat "$SKILL_SRC/skill-version.txt" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$SKILL37_CURRENT" ] && [ "$SKILL37_CURRENT" = "$SKILL37_SRC_VER" ]; then
            success "Skill 37 already installed at v${SKILL37_CURRENT}"
            # Still chmod +x in case perms drifted
            chmod +x "$SKILL_DEST/scripts/"*.sh 2>/dev/null || true
            return 0
        fi
        note "Skill 37 present at v${SKILL37_CURRENT:-?}, source is v${SKILL37_SRC_VER:-?} — refreshing"
    fi

    # Copy the skill (recursive, preserve perms where possible)
    mkdir -p "$SKILL_DEST"
    cp -R "$SKILL_SRC/." "$SKILL_DEST/" 2>>"$LOG_FILE" || {
        warn "Failed to copy Skill 37 from $SKILL_SRC → $SKILL_DEST"
        return 0
    }
    chmod +x "$SKILL_DEST/scripts/"*.sh 2>/dev/null || true

    # Env-var preflight (warn-only — Skill 37 no-ops cleanly without these)
    if [ -z "${KIE_API_KEY:-}" ]; then
        warn "KIE_API_KEY not set in current env — Skill 37 will no-op when triggered. Set it in the container env to enable closeout."
    else
        success "KIE_API_KEY present — Skill 37 image+video generation enabled"
    fi
    if [ -z "${NOTION_API_TOKEN:-}" ]; then
        warn "NOTION_API_TOKEN not set in current env — Skill 37's Notion step will fail. Set it in the container env to enable closeout docs."
    else
        success "NOTION_API_TOKEN present — Skill 37 Notion page-tree creation enabled"
    fi

    # Ownership fix (mirror Step 13 / update-skills pattern)
    chown -R node:node "$SKILL_DEST" 2>/dev/null || true

    success "Skill 37 (ZHC Closeout) installed → $SKILL_DEST"
    note "Skill 37 fires automatically via the workforce-build-resume cron (Step 13) when buildCompletedAt is set + closeoutStatus is dirty. No separate cron needed."
    return 0
}

install_skill_37_zhc_closeout

# ----------------------------------------------------------
# Step 14b: Installing Skill 38 (Conversational AI System v5.14)
# ----------------------------------------------------------
# Why: skill 38 is the conversational AI BRAIN that runs ON TOP of skill 29
# (GHL Convert and Flow). It packages the v5.14 playbook (~8,800 lines, 14
# version iterations) as 27 protocols + 8 journey templates + 9 install
# scripts + 7 references. Requires skills 05, 10, 19, 29 as prerequisites
# (checked at runtime by the skill's own 00-verify-prerequisites.sh).
# Idempotent. VPS-specific: skill works on Linux paths /data/.openclaw/* via
# the skill's OS-aware scripts; no VPS-vs-Mac branching needed here.
step "Step 14b: Installing Skill 38 (Conversational AI System v5.14) — sales brain + intelligent follow-up + dual-mode CS+support + typed KBs + weekly tune-up + model version freshness"

install_skill_38_conversational_ai_system() {
    local SKILL_SRC="$ONBOARDING_DIR/38-conversational-ai-system"
    local SKILL_DEST="$SKILLS_DIR/38-conversational-ai-system"

    if [ ! -d "$SKILL_SRC" ]; then
        warn "Skill 38 source dir not found at $SKILL_SRC — skipping (older onboarding bundle?)"
        return 0
    fi

    # Idempotent: skip if dest version matches src
    if [ -f "$SKILL_DEST/skill-version.txt" ] && [ -d "$SKILL_DEST/protocols" ]; then
        local SKILL38_CURRENT
        SKILL38_CURRENT=$(cat "$SKILL_DEST/skill-version.txt" 2>/dev/null | tr -d '[:space:]')
        local SKILL38_SRC_VER
        SKILL38_SRC_VER=$(cat "$SKILL_SRC/skill-version.txt" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$SKILL38_CURRENT" ] && [ "$SKILL38_CURRENT" = "$SKILL38_SRC_VER" ]; then
            success "Skill 38 already installed at v${SKILL38_CURRENT}"
            chmod +x "$SKILL_DEST/scripts/"*.sh 2>/dev/null || true
            return 0
        fi
        note "Skill 38 present at v${SKILL38_CURRENT:-?}, source is v${SKILL38_SRC_VER:-?} — refreshing"
    fi

    mkdir -p "$SKILL_DEST"
    cp -R "$SKILL_SRC/." "$SKILL_DEST/" 2>>"$LOG_FILE" || {
        warn "Failed to copy Skill 38 from $SKILL_SRC -> $SKILL_DEST"
        return 0
    }
    chmod +x "$SKILL_DEST/scripts/"*.sh 2>/dev/null || true

    success "Skill 38 (Conversational AI System v5.14) installed -> $SKILL_DEST"
    note "Skill 38 brings 27 protocols, 8 journey templates, 9 install scripts, 7 references."
    note "After this install completes, run: $SKILL_DEST/scripts/00-verify-prerequisites.sh"
    note "  then 01..08 in order. Skills 05, 10, 19, 29 must be installed FIRST."
    return 0
}

install_skill_38_conversational_ai_system

# ----------------------------------------------------------
# Step 15: Register Skill 32's materialize-dept-agents.sh (v10.14.19)
# ----------------------------------------------------------
# Why: pre-v10.14.19 Skill 23 marked depts "done" purely on file presence,
# Skill 32 Phase 4 was prose-not-code, and Skill 37 closeout sent a
# celebration claiming an N-dept M-role workforce was LIVE while the
# OpenClaw runtime saw exactly one agent (the default "main"). The new
# materialize-dept-agents.sh actually mutates openclaw.json agents.list[]
# so dept workspace folders become real runtime agents. Skill 37 v10.14.19
# invokes it as a binding preflight in Step 1 (Command Center) — this step
# just guarantees the script is present, executable, and discoverable.
step "Step 15: Registering Skill 32 materialize-dept-agents.sh (the materialize-dept-agents binding contract)"

install_materialize_dept_agents() {
    local SRC="$ONBOARDING_DIR/32-command-center-setup/scripts/materialize-dept-agents.sh"
    local DEST_DIR="$SKILLS_DIR/32-command-center-setup/scripts"
    local DEST="$DEST_DIR/materialize-dept-agents.sh"

    if [ ! -f "$SRC" ]; then
        warn "materialize-dept-agents.sh not found in onboarding bundle at $SRC — skipping (older bundle?)"
        warn "Skill 37 closeout will REFUSE to mark commandCenterStatus=done without this script — onboarding is incomplete."
        return 0
    fi

    mkdir -p "$DEST_DIR"
    cp "$SRC" "$DEST" 2>>"$LOG_FILE" || {
        warn "Failed to copy materialize-dept-agents.sh → $DEST"
        return 1
    }
    chmod +x "$DEST" 2>/dev/null || true
    chown -R node:node "$DEST_DIR" 2>/dev/null || true

    # Sanity-check: script must be executable and pass bash -n
    if [ ! -x "$DEST" ]; then
        warn "materialize-dept-agents.sh installed but not executable at $DEST"
        return 1
    fi
    if ! bash -n "$DEST" 2>>"$LOG_FILE"; then
        warn "materialize-dept-agents.sh installed but failed bash syntax check"
        return 1
    fi

    success "Skill 32 materialize-dept-agents.sh installed → $DEST"
    note "Skill 37 closeout's Step 1 will invoke this script automatically and verify agents.list[].length >= 2 before marking commandCenterStatus=done."
    return 0
}

install_materialize_dept_agents

# ----------------------------------------------------------
# Telegram diagnostic note (v10.0.1)
# ----------------------------------------------------------
# Surfaces just the Telegram-specific outcome — the full install summary
# below will also show any errors/warnings from the entire run.
case "$TELEGRAM_LAST_RESULT" in
    sent:*|"") : ;;
    *)
        warn "Telegram progress messages didn't all go through (this install's notifications only — your daily Telegram chats are unaffected)."
        ;;
esac

# ----------------------------------------------------------
# v10.14.20: proactive config heal before gateway-boot check.
# ----------------------------------------------------------
# The Telegram/whatsapp plugin auto-config-append step (which fires inside
# the gateway on every container restart) can write deprecated field names
# (e.g. messages.groupChat.unmentionedInbound) that fail validation against
# the current OpenClaw schema. When that happens the gateway exits 0 on
# next start and the entire bot goes silent — confirmed on Lyric's VPS
# 2026-05-23, gateway exited with "Invalid config at /data/.openclaw/openclaw.json.
# messages.groupChat: Unrecognized key: 'unmentionedInbound'".
#
# `openclaw doctor --fix` strips deprecated/unknown keys cleanly. Idempotent
# and safe — no-op when config is already clean. We run it BEFORE the
# gateway-health probe so the health probe sees a valid config to begin with.
if command -v openclaw >/dev/null 2>&1; then
    step "Running openclaw doctor --fix to strip any stale plugin-injected config keys"
    openclaw doctor --fix 2>&1 | tail -5 || warn "doctor --fix had issues — continuing anyway (gateway may complain at start)"
fi

# ----------------------------------------------------------
# v10.14.34: 2-day-learnings install hardening bundle
# ----------------------------------------------------------
# Findings discovered Sat 2026-05-23 + Sun 2026-05-24, encoded as defensive
# install-time checks/fixes so the next fresh install gets them automatically:
#   #10 Hostinger compose `command:` pin detection
#   #12 PORT env var leak — unset before any pm2 invocation
#   #13 hooks.token auto-generate when hooks.enabled but no token
#   #14 Cloudflared pm2-safe wrapper script ships in scripts/
#   #15 Fresh-VPS CLI scope auto-approval (devices/pending.json)
#   #17 SSL_CERT_FILE phantom Linuxbrew path → canonical Debian path
#   #18 Python deps backfill (httpx, requests, certifi)
# Idempotent + non-blocking — every defense is best-effort.
_hardening_self="$ONBOARDING_DIR/scripts/install-hardening.sh"
if [ -f "$_hardening_self" ]; then
    step "Step 16: Running install hardening (2-day-learnings defenses)"
    # shellcheck source=/dev/null
    bash "$_hardening_self" 2>&1 | tail -30 || warn "install-hardening returned non-zero (treated as informational)"
else
    note "install-hardening.sh not in bundle — skipping (older onboarding bundle, harmless)"
fi

# ----------------------------------------------------------
# Final: Conditional gateway restart (v10.14.3 — idempotent)
# ----------------------------------------------------------
# The previous version always called `openclaw gateway restart` which:
#   - depends on `lsof` for stale-pid scan (missing on Hostinger's image)
#   - prints misleading "Gateway service disabled" output because systemd
#     isn't available inside the container (gateway is supervised via nohup)
#   - can fail outright on scope-upgrade-pending state
# Only restart when actually needed: the gateway will pick up AGENTS.md
# changes on the next session naturally (Hostinger's entrypoint hot-reloads
# config on file change), so a restart is only required when the install
# rewrote agent-binding identity, which it doesn't.
if command -v openclaw >/dev/null 2>&1; then
    note "Checking gateway health (gateway hot-reloads AGENTS.md; restart only if unhealthy)..."
    gw_status_out=$(openclaw gateway status 2>&1 | head -20 || true)
    if echo "$gw_status_out" | grep -qE "Capability: write-capable|Connectivity probe: ok"; then
        success "Gateway healthy — no restart needed. Your agent will pick up AGENTS.md on next session."
    else
        note "Gateway unhealthy — attempting restart (may fail safely if scope upgrade is pending)..."
        openclaw gateway restart 2>>"$LOG_FILE" || warn "Gateway restart returned non-zero (likely scope-upgrade-pending; not blocking install completion)."
    fi
else
    warn "openclaw command not found - restart manually if needed: openclaw gateway restart"
fi

# ----------------------------------------------------------
# v10.14.12: Auto-kickoff Stage 2 / Wave execution
# ----------------------------------------------------------
# BMW-off-the-lot fix: previously the owner had to paste the kickoff text
# block to their bot to trigger Wave 1-5 execution. Now install.sh schedules
# a one-shot cron that fires ~3 minutes after install completes, delivering
# the kickoff synthetically. The agent receives it, reads AGENTS.md's
# UPDATE PENDING block, and starts Wave 1 autonomously. Owner only needs
# to engage at Wave 5 (the AI Workforce interview, which requires owner
# input that can't be delegated).
#
# Bulletproof design:
# - 3-minute buffer absorbs gateway restart latency
# - Idempotent: skips if an auto-kickoff cron already exists from a prior run
# - Self-cleanup: the kickoff message instructs the agent to delete the cron
#   after firing Wave 1, so it never fires twice
# - Graceful fallback: if cron creation fails for ANY reason (gateway down,
#   scope upgrade pending, schema rejected), the existing manual-paste
#   completion notice flow remains and the owner can still paste the kickoff
# - Failure does NOT block install completion (always exits 0 for this step)
# --- Mechanism A: openclaw cron one-shot (preferred) ---
_kickoff_mech_a_cron() {
    local chat_id="$1"
    local kickoff_msg="$2"

    if ! command -v openclaw >/dev/null 2>&1; then
        return 1
    fi

    # Idempotency: skip if a prior install already scheduled the kickoff
    if openclaw cron list 2>/dev/null | grep -qE "auto-kickoff-"; then
        note "Auto-kickoff cron already present from a prior install — skipping mechanism A (treat as success)."
        return 0
    fi

    # Compute target fire time (3 minutes from now, next minute boundary).
    # Use UTC to avoid host/container TZ drift. Handle both GNU and BSD date.
    local target_ts target_min target_hour target_day target_month
    if date -u -d '+3 minutes' '+%s' >/dev/null 2>&1; then
        target_ts=$(date -u -d '+3 minutes' '+%s')
    else
        target_ts=$(date -u -v+3M '+%s' 2>/dev/null)
    fi
    [ -z "$target_ts" ] && return 1

    target_min=$(date -u -d "@$target_ts" '+%M' 2>/dev/null || date -u -r "$target_ts" '+%M' 2>/dev/null)
    target_hour=$(date -u -d "@$target_ts" '+%H' 2>/dev/null || date -u -r "$target_ts" '+%H' 2>/dev/null)
    target_day=$(date -u -d "@$target_ts" '+%d' 2>/dev/null || date -u -r "$target_ts" '+%d' 2>/dev/null)
    target_month=$(date -u -d "@$target_ts" '+%m' 2>/dev/null || date -u -r "$target_ts" '+%m' 2>/dev/null)

    local cron_expr="$target_min $target_hour $target_day $target_month *"
    local cron_name="auto-kickoff-${ONBOARDING_VERSION}-$(date +%s)"
    local full_msg
    full_msg="$kickoff_msg

IMPORTANT — Cron self-cleanup (do this BEFORE Wave 1): install.sh scheduled this kickoff via a one-shot cron named '$cron_name'. Delete it NOW so it does not fire again:

  openclaw cron delete --name '$cron_name'

Then proceed with Wave 1."

    if openclaw cron create \
         --name "$cron_name" \
         --cron "$cron_expr" \
         --tz UTC \
         --channel telegram \
         --to "$chat_id" \
         --agent main \
         --message "$full_msg" >> "$LOG_FILE" 2>&1; then
        success "Auto-kickoff (mechanism A: cron) scheduled — Wave 1 starts in ~3 min (cron '$cron_name' @ '$cron_expr' UTC)."
        return 0
    fi
    return 1
}

# --- Mechanism B: Direct Telegram ingress-spool write (fallback) ---
# When mechanism A (cron) fails, we drop a synthetic inbound Telegram update
# directly into the gateway's spool. The gateway processes it as if it came
# from the owner via Telegram — agent receives an inbound message, reads
# AGENTS.md UPDATE PENDING, starts Wave 1. No cron needed, no self-cleanup
# required (the spool message is processed once and moves to processed/).
_kickoff_mech_b_spool() {
    local chat_id="$1"
    local kickoff_msg="$2"

    local spool_dir="/data/.openclaw/telegram/ingress-spool-default"
    local offset_file="/data/.openclaw/telegram/update-offset-default.json"
    local bot_info="/data/.openclaw/telegram/bot-info-default.json"

    if [ ! -d "$spool_dir" ]; then
        note "Mechanism B unavailable: spool dir '$spool_dir' missing."
        return 1
    fi

    # Pick an updateId that is HIGHER than the bot's last-seen offset
    # so the gateway considers it new. Fall back to a current-time-based id.
    local last_offset new_update_id
    last_offset=$(python3 -c "import json,sys;d=json.load(open('$offset_file'));print(d.get('offset',0))" 2>/dev/null)
    if [ -n "$last_offset" ] && [ "$last_offset" -gt 0 ] 2>/dev/null; then
        new_update_id=$((last_offset + 100))
    else
        new_update_id=$(date +%s)
    fi
    local now_sec=$(date +%s)
    local now_ms=$((now_sec * 1000))
    local spool_file
    spool_file=$(printf "%s/%016d.json" "$spool_dir" "$new_update_id")

    OC_KICKOFF_MSG="$kickoff_msg" CHAT_ID="$chat_id" UPDATE_ID="$new_update_id" \
    NOW_SEC="$now_sec" NOW_MS="$now_ms" SPOOL_FILE="$spool_file" \
    python3 - << 'PYEOF_INNER' 2>>"$LOG_FILE"
import json, os
payload = {
    "version": 1,
    "updateId": int(os.environ["UPDATE_ID"]),
    "receivedAt": int(os.environ["NOW_MS"]),
    "update": {
        "update_id": int(os.environ["UPDATE_ID"]),
        "message": {
            "message_id": int(os.environ["UPDATE_ID"]),
            "from": {
                "id": int(os.environ["CHAT_ID"]),
                "is_bot": False,
                "first_name": "Owner",
                "language_code": "en",
            },
            "chat": {
                "id": int(os.environ["CHAT_ID"]),
                "first_name": "Owner",
                "type": "private",
            },
            "date": int(os.environ["NOW_SEC"]),
            "text": os.environ["OC_KICKOFF_MSG"],
        }
    }
}
with open(os.environ["SPOOL_FILE"], "w") as f:
    json.dump(payload, f)
os.chmod(os.environ["SPOOL_FILE"], 0o600)
print(f"  spool file written: {os.environ['SPOOL_FILE']}")
PYEOF_INNER

    local rc=$?
    if [ "$rc" -eq 0 ] && [ -f "$spool_file" ]; then
        success "Auto-kickoff (mechanism B: spool write) injected — gateway will pick it up within ~30s as if owner sent the kickoff via Telegram."
        return 0
    fi
    return 1
}

# --- Auto-kickoff orchestrator: try A, fall back to B, then manual ---
schedule_auto_kickoff() {
    local chat_id="$1"

    # Gate on a usable chat target
    if [ -z "$chat_id" ] || [ "$chat_id" = "skipped" ] || [ "$chat_id" = "no-openclaw-cli" ] || [ "$chat_id" = "no-telegram-target" ] || [ "${chat_id#failed:}" != "$chat_id" ]; then
        warn "Auto-kickoff skipped — no Telegram chat target resolved ('$chat_id'). Owner can still paste the kickoff manually from the completion notice below."
        return 0
    fi
    chat_id="${chat_id#sent:}"

    local kickoff_msg="I just ran the OpenClaw onboarding install. There is an UPDATE PENDING flag at the top of my AGENTS.md. Please follow the 5-Phase Processing Order in that flag to activate all skills. Start with Phase A (parallel install in waves). Do not skip any phase. Run QC after each skill. Send me a summary when complete."

    note "Auto-kickoff: trying mechanism A (openclaw cron one-shot)..."
    if _kickoff_mech_a_cron "$chat_id" "$kickoff_msg"; then
        note "Owner does NOT need to paste the kickoff. The bot will begin Wave 1 autonomously and send progress updates."
        return 0
    fi

    warn "Mechanism A (cron) failed. Falling back to mechanism B (direct spool write)..."
    if _kickoff_mech_b_spool "$chat_id" "$kickoff_msg"; then
        note "Owner does NOT need to paste the kickoff. The bot will begin Wave 1 autonomously and send progress updates."
        return 0
    fi

    warn "Both mechanisms A and B failed (see $LOG_FILE). Owner CAN still paste the kickoff manually from the completion notice — that path remains supported."
    return 0
}

# Schedule the auto-kickoff. Failure here never blocks install completion.
schedule_auto_kickoff "$TELEGRAM_LAST_RESULT" || true

# ----------------------------------------------------------
# Install summary (v10.0.2) — scan log for warnings/errors, print actionable
# report block right in the terminal so issues are visible without scrolling.
# ----------------------------------------------------------
print_install_summary() {
    local err_pat='^  ✗ ERROR:|GatewayClientRequestError|GatewayTransportError|gateway connect failed|scope upgrade pending|pairing required'
    local warn_pat='^  ⚠️'

    local err_count warn_count
    err_count=$(grep -cE "$err_pat" "$LOG_FILE" 2>/dev/null | head -1)
    warn_count=$(grep -cE "$warn_pat" "$LOG_FILE" 2>/dev/null | head -1)
    err_count=${err_count:-0}
    warn_count=${warn_count:-0}

    echo ""
    echo "══════════════════════════════════════════════════════════════════════"
    if [ "$err_count" -eq 0 ] && [ "$warn_count" -eq 0 ]; then
        echo "  ✅ INSTALL COMPLETED CLEANLY — no warnings or errors detected"
        echo ""
        echo "     Log (durable, survives container restart):"
        echo "       $LOG_FILE"
        echo "══════════════════════════════════════════════════════════════════════"
        return 0
    fi

    echo "  ⚠️  PLEASE REPORT THE FOLLOWING TO THE TRACKER"
    echo "     ${err_count} error(s), ${warn_count} warning(s) detected during install."
    echo ""
    echo "  ─── First 10 issues (most recent first) ──────────────────────────────"
    grep -nE "$err_pat|$warn_pat" "$LOG_FILE" 2>/dev/null | tail -10 | sed 's/^/     /'
    echo ""
    echo "  ─── Full log (durable, survives container restart) ───────────────────"
    echo "     $LOG_FILE"
    echo ""
    echo "  ─── To print the full log for reporting ──────────────────────────────"
    echo "     cat \"$LOG_FILE\""
    echo ""
    echo "  ─── Report at ────────────────────────────────────────────────────────"
    echo "     https://github.com/trevorotts1/openclaw-onboarding-vps/issues/new"
    echo "     (paste the log contents into the issue body)"
    echo "══════════════════════════════════════════════════════════════════════"
}
print_install_summary

# ============================================================
#  v10.8.0 — P0-9 Triple-Fire Install Kickoff Trigger (N22)
#  Same as the Mac repo's install.sh — N22 enforcement: Telegram +
#  AGENTS.md flag + terminal fallback. All three fire on every kickoff.
# ============================================================
fire_install_kickoff_triplet() {
    local plat
    if [ -d "/data/.openclaw" ]; then plat="vps"; else plat="mac"; fi
    local agents_md skills_dir openclaw_json
    if [ "$plat" = "vps" ]; then
        agents_md="/data/.openclaw/AGENTS.md"
        skills_dir="/data/.openclaw/skills"
        openclaw_json="/data/.openclaw/openclaw.json"
    else
        agents_md="$HOME/.openclaw/AGENTS.md"
        skills_dir="$HOME/.openclaw/skills"
        openclaw_json="$HOME/.openclaw/openclaw.json"
    fi

    # v10.14.5: Resolve the owner's first name for personalized greeting.
    # Read priority CHANGED in v10.14.5 to fix the meta.ownerName schema
    # violation discovered during Maria's install:
    #
    #   1. OPENCLAW_OWNER_NAME env var (set via -e flag on docker exec)
    #   2. /data/.openclaw/channel-metadata.json `ownerName` (sidecar — NEW
    #      canonical location; outside openclaw.json schema validation, so
    #      writing this never breaks the config)
    #   3. openclaw.json meta.ownerName / owner.name / wizard.ownerName /
    #      meta.owner.name / owner.firstName — LEGACY fallback ONLY for
    #      backward compat. DO NOT write to these — they're schema-strict.
    #      Reading is safe; writing would trigger the same crash that
    #      ate Maria's Step 10/11/12.
    #   4. Fall back to "there" (generic but warm).
    #
    # See INSTALL-GOTCHAS.md #11 for the full rationale.
    local owner_name sidecar_path
    if [ "$plat" = "vps" ]; then
        sidecar_path="/data/.openclaw/channel-metadata.json"
    else
        sidecar_path="$HOME/.openclaw/channel-metadata.json"
    fi
    owner_name=$(python3 -c "
import json, os, sys
candidates = []
# 1. Env var
env_name = os.environ.get('OPENCLAW_OWNER_NAME','').strip()
if env_name: candidates.append(env_name)
# 2. Sidecar (NEW canonical location)
try:
    s = json.load(open('$sidecar_path'))
    n = s.get('ownerName','')
    if isinstance(n, str) and n.strip(): candidates.append(n.strip())
except Exception:
    pass
# 3. openclaw.json (LEGACY read-only fallback — never write here)
try:
    d = json.load(open('$openclaw_json'))
    for path in (('meta','ownerName'), ('owner','name'), ('wizard','ownerName'),
                 ('meta','owner','name'), ('owner','firstName')):
        cur = d
        for k in path:
            cur = cur.get(k, {}) if isinstance(cur, dict) else {}
        if isinstance(cur, str) and cur.strip():
            candidates.append(cur.strip())
            break
except Exception:
    pass
for n in candidates:
    print(n.split()[0]); sys.exit(0)
" 2>/dev/null)
    owner_name="${owner_name:-there}"

    local tg_fired="false" flag_fired="false"
    local tg_reason="" flag_reason=""

    # 1. Telegram message — UNCONDITIONAL attempt (N22).
    #
    # v10.14.7 (P0, discovered live during Maria + Angela T onboardings):
    # The previous Telegram message TOLD THE OWNER TO LOOK IN THE TERMINAL.
    # That's wrong — the owner doesn't have terminal access, only the
    # operator does. The message must CONTAIN the paste block directly so
    # the owner can copy from Telegram and paste back in the same chat.
    #
    # v10.14.7 also switches the SEND MECHANISM from `openclaw message send`
    # (which keeps failing because cron + outbound message scopes require
    # operator.admin approval) to a DIRECT Telegram Bot API call via curl.
    # The bot token is in $TELEGRAM_BOT_TOKEN (always set on Hostinger
    # image), the chat ID comes from $TELEGRAM_TARGET_CACHED. This bypasses
    # the openclaw gateway scope-pending issue entirely — Telegram's API
    # accepts the send as long as the chat exists and the bot has messaged
    # that chat at least once (which it has, via pairing).
    #
    # The `openclaw message send` path remains as a FALLBACK after the Bot
    # API call, in case the Bot API somehow fails (rare).
    local tg_msg_template tg_msg
    # Use a quoted heredoc marker ('TGMSG_EOF') so the heredoc content is
    # LITERAL — no variable expansion, no quote parsing, no edge cases.
    # We then substitute placeholders via bash parameter expansion below.
    # This avoids the heredoc-inside-$(...) edge case that broke v10.14.7
    # syntax during development.
    tg_msg_template=$(cat <<'TGMSG_EOF'
Hi __OWNER_NAME__! 👋

Your AI workforce is ready to set up. There is just ONE thing you need to do to start.

📋 Copy the entire message below (everything between the scissor lines), paste it back to me in this chat, and hit Send. That is the only step — I take over from there.

✂️━━━━━━━━━ COPY EVERYTHING BELOW THIS LINE ━━━━━━━━━✂️

Start the OpenClaw onboarding process. Follow this procedure exactly.

DEPLOYMENT PLATFORM — READ THIS BEFORE ANYTHING ELSE:
This is a VPS install (Hostinger Docker container). All paths under /data/.openclaw/. When you read INSTALL-CONTRACT.md, START HERE.md, or any other doc that mentions BOTH "Mac mini" AND "VPS" sections side-by-side, USE ONLY THE VPS SECTION. Skip every "Mac mini" reference — those are for an alternate deployment that does not apply here. Specifically:
- Wave concurrency cap: 5 helpers max (NOT 10 — that is the Mac mini cap)
- File paths: /data/.openclaw/ (NOT $HOME/.openclaw or ~/.openclaw — those are Mac)
- Backups: /data/.openclaw/backups/ (NOT ~/Downloads/openclaw-backups — that is Mac)
- Process supervision: container nohup + openclaw cron create (NOT macOS launchd)

If you find yourself uncertain whether a doc section applies, default to the VPS interpretation. Do NOT ask the owner ("are you a Mac or VPS?") — the answer is always VPS for this install.

PHASE 1 — Read the docs first (do not skip):
1. Read __OC_CONFIG__/Start Here.md end to end. (At config root /data/.openclaw/, NOT under skills/.)
2. Read __OC_CONFIG__/INSTALL-CONTRACT.md end to end. (Also at config root.) Non-negotiable rules: Rule 0 (wave concurrency cap = 5), Rule 1 (read every .md before acting), Rule 16 (read INSTALL-GOTCHAS.md).
3. Run web research pre-flight: bash __OC_CONFIG__/scripts/web-research-preflight.sh
4. Settings: maxChars=200000, maxTotalChars=400000, maxSpawnDepth=4, maxChildren=20, maxConcurrent=100, thinking=high.
5. Set up workspace files (USER.md, AGENTS.md, TOOLS.md at workspace root, symlinked into per-role workspaces).

PHASE 2 — Install skills in waves, with PROGRESS UPDATES to __OWNER_NAME__:
Before each wave, send __OWNER_NAME__ a Telegram message in PLAIN ENGLISH (no jargon): Starting Wave 2 of 5 — about to set up X skills, ~Y minutes.
After each wave: Wave 2 done. X skills working. Now starting Wave 3.
Gate each wave: bash __OC_CONFIG__/scripts/check-wave-concurrency.sh --proposed N --reason wave-N
Skill folders live at __OC_CONFIG__/skills/01-... through __OC_CONFIG__/skills/36-... (33 active + 3 archived).
Per skill: read all .md + scripts, execute INSTALL.md in order, score >= 8.5/10, up to 5 retry loops.

PHASE 3 — Verify:
6. Run __OC_CONFIG__/scripts/qc-system-integrity.sh — must exit 0.
7. Message __OWNER_NAME__: All skills installed. Ready for the 30-question business interview? About 35 min of your focused time — your answers shape your entire AI team. Reply yes when ready.
Wait for confirmation before proceeding.

PHASE 4 — Build the workforce:
8. Run AI Workforce Interview (Skill 23) with __OWNER_NAME__.
9. After interview, run __OC_CONFIG__/skills/23-ai-workforce-blueprint/scripts/create_role_workspaces.py to write per-department governing-personas.md.
10. Message __OWNER_NAME__ confirming workforce is built and listing departments created.

PHASE 5 — Wrap up:
11. Walk __OWNER_NAME__ through Telegram supergroup setup (Skill 32 INSTALL.md Phase 2 — 7 manual phone steps, one at a time).
12. Final summary in plain English: what was installed, what is working, what did not work.

HARD RULES:
- No shortcuts. No self-QC.
- All helpers use non-Anthropic models (Ollama Cloud primary, OpenRouter fallback).
- Persona governance on every non-mechanical task.
- Master Orchestrator only dispatches; never does work directly.
- Telegram progress updates between waves are mandatory (N28 binding).
- Gateway restarts: agents may restart themselves when needed (v10.14.7 lifted the no-self-restart restriction). Do NOT ask the owner to type /restart.
- Speak to __OWNER_NAME__ in plain English. NO jargon (QC, sub-agent, manifest).

✂️━━━━━━━━━ COPY EVERYTHING ABOVE THIS LINE ━━━━━━━━━✂️

Once you paste that back to me here and hit Send, I will respond within a minute and start setting up your team. Total setup takes about an hour, including a 30-question business interview in the middle. I will keep you posted as I work. 🚀
TGMSG_EOF
)
    tg_msg="${tg_msg_template//__OWNER_NAME__/$owner_name}"
    # v10.14.9: paste block now uses __OC_CONFIG__ (the openclaw config ROOT
    # at /data/.openclaw/) for canonical .md docs and the /scripts/ subfolder
    # for orchestration scripts. The previous __SKILLS_DIR__ substitution
    # pointed at /data/.openclaw/skills/ which is ONLY for skill folders
    # (01-... through 36-...), not the orchestration files. Maria's bot
    # correctly reported "Start Here.md not found" because we sent it the
    # wrong path. OC_CONFIG is exported earlier in install.sh.
    tg_msg="${tg_msg//__OC_CONFIG__/$OC_CONFIG}"
    # Legacy alias kept for any references that still use __SKILLS_DIR__:
    tg_msg="${tg_msg//__SKILLS_DIR__/$skills_dir}"

    # Try Bot API direct first (most reliable — sidesteps gateway scope issues).
    local tg_target_for_send="${TELEGRAM_TARGET_CACHED:-}"
    local tg_chat_id
    tg_chat_id="${tg_target_for_send#telegram:}"  # strip "telegram:" prefix if present

    if [ -n "$tg_chat_id" ] && [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
        if curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
               --data-urlencode "chat_id=${tg_chat_id}" \
               --data-urlencode "text=${tg_msg}" 2>/dev/null \
           | grep -q '"ok":true'; then
            tg_fired="true"
        else
            tg_reason="Telegram Bot API direct call failed (will try openclaw CLI fallback)"
        fi
    fi

    # Fallback: openclaw CLI (only fires if Bot API didn't succeed)
    if [ "$tg_fired" != "true" ] && command -v openclaw >/dev/null 2>&1; then
        if [ -n "$tg_target_for_send" ] && [ "${tg_target_for_send#telegram:}" = "$tg_target_for_send" ]; then
            tg_target_for_send="telegram:$tg_target_for_send"
        fi
        if [ -n "$tg_target_for_send" ]; then
            if openclaw message send -t "$tg_target_for_send" -m "$tg_msg" 2>/dev/null; then
                tg_fired="true"
                tg_reason=""
            else
                tg_reason="${tg_reason:+$tg_reason; }openclaw CLI fallback also failed (scope-pending or transport issue)"
            fi
        fi
    fi

    if [ "$tg_fired" != "true" ] && [ -z "$tg_reason" ]; then
        tg_reason="no TELEGRAM_BOT_TOKEN env var and no openclaw CLI on PATH — Telegram kickoff deferred"
    fi

    # 2. AGENTS.md flag — UNCONDITIONAL attempt (N22). Create the parent dir
    #    if needed; only skip if mkdir + write both fail.
    mkdir -p "$(dirname "$agents_md")" 2>/dev/null || true
    local flag_marker
    flag_marker="<!-- OPENCLAW_ONBOARDING_KICKOFF:${ONBOARDING_VERSION:-?} -->"
    if [ -f "$agents_md" ] && grep -qF "$flag_marker" "$agents_md" 2>/dev/null; then
        flag_fired="true"
    else
        {
            echo ""
            echo "$flag_marker"
            echo "## OpenClaw onboarding kickoff: ${ONBOARDING_VERSION:-?}"
            echo "Triggered at $(date -u +%Y-%m-%dT%H:%M:%SZ) via install.sh on platform=$plat."
            echo ""
            echo "The bash install.sh has finished bootstrapping repo files at $skills_dir."
            echo "Read the terminal kickoff block (printed at install.sh end) and execute"
            echo "those instructions in order. Begin with: read $skills_dir/Start\\ Here.md"
            echo "and $skills_dir/INSTALL-CONTRACT.md end to end before any work."
            echo "<!-- OPENCLAW_ONBOARDING_KICKOFF_END -->"
        } >> "$agents_md" 2>/dev/null && flag_fired="true" \
                                        || flag_reason="could not write $agents_md (mkdir -p $(dirname "$agents_md") also tried)"
    fi

    cat <<TERMEOF

═══════════════════════════════════════════════════════════════════════
  ✓ All set, ${owner_name}! Your AI workforce is installed.
═══════════════════════════════════════════════════════════════════════

  Version: ${ONBOARDING_VERSION:-?}
  Installed on: $plat ($(date +%Y-%m-%d at %H:%M))

═══════════════════════════════════════════════════════════════════════
  📋  WHAT TO DO NEXT — JUST ONE STEP
═══════════════════════════════════════════════════════════════════════

  Open your Telegram bot (the one your agent runs on) and paste in the
  long block of text below. That message tells your bot exactly what to
  do — it'll take it from there and keep you posted along the way.

  Step-by-step:
    1. Open Telegram on your phone or computer
    2. Find your bot (the AI agent you talk to)
    3. Highlight everything between the two long lines below
       (between "COPY EVERYTHING BELOW" and "COPY EVERYTHING ABOVE")
    4. Copy it (Cmd+C on Mac, Ctrl+C on Windows)
    5. Paste it into the chat with your bot
    6. Hit Send

  Your bot will reply within 30 seconds.

────────── 📋 COPY EVERYTHING BELOW THIS LINE 📋 ──────────

Hi! Please start the OpenClaw onboarding process now. Here's the procedure
to follow exactly:

PHASE 1 — Read the docs first (don't skip):
  1. Read $skills_dir/Start\ Here.md end to end.
  2. Read $skills_dir/INSTALL-CONTRACT.md end to end. Rules that are
     non-negotiable: Rule 0 (max 5 helpers running at once on VPS),
     Rule 1 (read every .md file in a skill before doing anything),
     Rule 16 (read INSTALL-GOTCHAS.md for Hostinger Docker edge cases).
  3. Run the web research pre-flight to make sure model and pricing
     info is current:
        bash $skills_dir/web-research-preflight.sh
  4. Confirm settings: maxChars=200000, maxTotalChars=400000,
     maxSpawnDepth=4, maxChildren=20, maxConcurrent=100, thinking=high.
  5. Set up canonical workspace files (USER.md, AGENTS.md, TOOLS.md
     at workspace root, symlinked into every per-role workspace).

PHASE 2 — Install the skills in waves, with PROGRESS UPDATES:

  This is mandatory in v10.14.4+: tell me (the owner) what you're doing
  in PLAIN ENGLISH before and after each wave. Keep it short and warm.
  Average owner is non-technical and may be over 60 — no jargon, no
  acronyms ("QC", "sub-agent", "manifest"), no technical paths.

  BEFORE each wave, send a Telegram message like:
    "Starting on Wave 2 of 5 now. About to set up 18 utility skills
     in parallel — this should take about 10 minutes."

  AFTER each wave, send a Telegram message like:
    "Wave 2 is done. 18 skills are working. Now starting Wave 3."

  If anything goes wrong in a wave, message me with what broke and
  what you're going to try next, in plain English.

  Wave gating command (use before each wave):
      bash $skills_dir/check-wave-concurrency.sh --proposed <N> --reason "wave-N"

  Per skill: read all of the skill's .md files and scripts, execute
  its INSTALL.md in order, score it ≥ 8.5/10, up to 5 retry loops.

PHASE 3 — Verify everything:
  6. Run skills/qc-system-integrity.sh — must exit 0.
  7. Send me a Telegram message:
       "All skills installed and verified. Now we're going to do the
        most important step: a 30-question interview about your
        business. This will take about 35 minutes of your time. Your
        answers shape your entire AI team — please block out
        uninterrupted time. Ready to start?"
     Wait for "yes" or equivalent before proceeding.

PHASE 4 — Build the AI workforce:
  8. Run the AI Workforce Interview (Skill 23) to build the company
     structure from my answers.
  9. After the interview, run create_role_workspaces.py to write
     per-department governing-personas.md.
  10. Send me a Telegram message confirming the workforce is built
      and which departments were created.

PHASE 5 — Wrap up:
  11. Walk me through the Telegram supergroup setup (Skill 32 INSTALL.md
      Phase 2 — 7 manual steps on my phone, one at a time, with
      screenshots if you can describe them in words).
  12. Final summary in plain English: "Here's what I installed,
      here's what's ready to use today, here's anything that didn't
      work and why."

HARD RULES (v10.14.4+):
  • No shortcuts. No self-QC.
  • All helpers (sub-agents) use non-Anthropic models — Ollama Cloud
    primary, OpenRouter fallback.
  • Persona governance applies to every non-mechanical task.
  • Master Orchestrator does NO work directly — only dispatches and
    reports.
  • Send Telegram progress updates between waves (N28 binding).
  • Speak to the owner in plain English. NO jargon. They're paying
    you to make this easy.

────────── 📋 COPY EVERYTHING ABOVE THIS LINE 📋 ──────────

═══════════════════════════════════════════════════════════════════════
  ⏱  WHAT YOU'LL SEE — APPROXIMATE TIMELINE
═══════════════════════════════════════════════════════════════════════

  Minute 0:        Your bot starts reading the docs (silent)
  Minute 5:        Bot messages you "Starting Wave 1"
  Minute 15:       Bot messages you "Wave 1 done, starting Wave 2"
  Minute 30:       Bot messages you "Wave 2 done, starting Wave 3"
  Minute 40-45:    Bot says "Now we need to interview you about your
                   business — ready for 35 min of focused time?"
  Minute 45-80:    The 30-question interview happens — this is YOUR
                   active time. Best answers = best AI workforce.
  Minute 80-90:    Bot builds your departments and helps you set up
                   the Telegram supergroup.

  Total: about an hour and a half. Half of that is reading the
  interview questions and answering them.

═══════════════════════════════════════════════════════════════════════
  ℹ️  IF SOMETHING SEEMS OFF
═══════════════════════════════════════════════════════════════════════

  • If you don't hear from your bot within 2 minutes of pasting the
    block above, paste it once more.
  • If the bot says "Calibre didn't install" — that's expected on
    Hostinger Docker servers and doesn't block anything. Your books
    will still work as PDF or EPUB files.
  • If the bot asks for "admin permission" or "scope upgrade" approval,
    reply "approve" or "yes". This is a one-time thing for the
    automatic Sunday updates.
  • Full troubleshooting guide: $skills_dir/INSTALL-GOTCHAS.md

═══════════════════════════════════════════════════════════════════════

  Backup safety net: if anything goes wrong, your old setup is saved
  as a Docker snapshot. Tell whoever installed this for you and they
  can restore in under a minute.

═══════════════════════════════════════════════════════════════════════
TERMEOF
}
fire_install_kickoff_triplet
