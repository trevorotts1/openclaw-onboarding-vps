#!/usr/bin/env bash
# install-hardening.sh — defensive checks/fixes hardened from 2-day forensics
# (2026-05-23 / 2026-05-24). Source-able from install.sh OR runnable standalone.
#
# Each function is independently safe (idempotent, no-op when already correct).
# All functions return 0 unconditionally — hardening is best-effort. The
# install must NOT fail because hardening can't apply a defense.
#
# Discovered findings this script implements:
#   #10  Hostinger docker-compose.yml `command:` pin detection (warn-only)
#   #12  PORT env var leak — unset PORT before any pm2 invocation
#   #13  hooks.token auto-generate when hooks.enabled is true without one
#   #14  Cloudflared wrapper-script pattern (inline pm2 start fails)
#   #15  Fresh-VPS CLI scope auto-approval (pending.json persistent ids)
#   #17  SSL_CERT_FILE phantom Linuxbrew path → write canonical Debian path
#   #18  Missing Python deps (google-genai/httpx/requests/certifi) backfill
set -uo pipefail  # NOTE: no -e — we never want to abort install for hardening

_oc_root() {
    if [[ -d /data/.openclaw ]]; then
        echo /data/.openclaw
    elif [[ -d "$HOME/.openclaw" ]]; then
        echo "$HOME/.openclaw"
    else
        echo ""
    fi
}

_log() { echo "[install-hardening] $*"; }

# ─── #10: Hostinger docker-compose.yml `command:` pin detection ──────────────
# When the operator updates a Hostinger OpenClaw VPS, sometimes a hardcoded
# `command: ... npm install openclaw@X.Y.Z ...` in /docker/<project>/docker-
# compose.yml pins the install to an OLD version. Result: openclaw doesn't
# actually upgrade and you chase phantom config bugs for an hour.
# This check WARNS only — we don't auto-rewrite the operator's compose file.
harden_check_compose_pin() {
    local compose_glob="/docker/*/docker-compose.yml"
    local f
    for f in $compose_glob; do
        [ -f "$f" ] || continue
        # Look for hardcoded "npm install openclaw@<ver>"
        if grep -E 'npm install (.*-g )?openclaw@[0-9]' "$f" >/dev/null 2>&1; then
            local pinned
            pinned=$(grep -oE 'openclaw@[0-9][0-9.]+' "$f" | head -1)
            _log "WARNING: docker-compose.yml at $f has a HARDCODED openclaw version pin: $pinned"
            _log "WARNING: 'openclaw update' or this install.sh CANNOT upgrade past that pin."
            _log "WARNING: Edit $f and either remove the pin or update it to match the current ONBOARDING_VERSION."
        fi
    done
    return 0
}

# ─── #12: PORT env var leak ──────────────────────────────────────────────────
# Hostinger's Node image exports `PORT=80` (or similar) which makes pm2-started
# OpenClaw plugins bind to 80 instead of their configured ports. Unset it
# defensively so child processes get a clean slate.
harden_unset_port() {
    if [ -n "${PORT:-}" ]; then
        _log "Unsetting inherited PORT=$PORT env var (Hostinger image leak)"
        unset PORT
    fi
    # Also unset HTTP_PORT / SERVICE_PORT — common variants.
    [ -n "${HTTP_PORT:-}" ] && unset HTTP_PORT || true
    [ -n "${SERVICE_PORT:-}" ] && unset SERVICE_PORT || true
    return 0
}

# ─── #13: hooks.token auto-generate ──────────────────────────────────────────
# If openclaw.json has hooks.enabled=true but no hooks.token, the gateway
# fails closed and refuses to fire any hook. We generate one if missing.
harden_hooks_token() {
    local oc_root
    oc_root="$(_oc_root)"
    [ -z "$oc_root" ] && return 0
    local cfg="$oc_root/openclaw.json"
    [ -f "$cfg" ] || return 0

    python3 - "$cfg" <<'PYEOF' || true
import json, sys, secrets, os
p = sys.argv[1]
try:
    d = json.load(open(p))
except Exception as e:
    print(f"[install-hardening] hooks.token check: cannot parse {p}: {e}", file=sys.stderr)
    sys.exit(0)
hooks = d.get("hooks") or {}
if not hooks.get("enabled"):
    sys.exit(0)
if hooks.get("token"):
    sys.exit(0)
hooks["token"] = secrets.token_hex(32)
d["hooks"] = hooks
tmp = p + ".tmp-hardening"
with open(tmp, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
os.replace(tmp, p)
print(f"[install-hardening] hooks.enabled=true but hooks.token was missing — generated one (64 hex chars).")
PYEOF
    return 0
}

# ─── #14: Cloudflared wrapper-script pattern ─────────────────────────────────
# `pm2 start "cloudflared tunnel run --token X"` as an inline command string
# fails because pm2 mis-parses the quoted command. The fix is a wrapper
# script. Ship one and let the operator point pm2 at it.
harden_cloudflared_wrapper() {
    local oc_root
    oc_root="$(_oc_root)"
    [ -z "$oc_root" ] && return 0
    local wrapper="$oc_root/scripts/cloudflared-tunnel-run.sh"
    if [ -f "$wrapper" ]; then
        return 0
    fi
    mkdir -p "$(dirname "$wrapper")" 2>/dev/null || return 0
    cat > "$wrapper" <<'WRAPEOF'
#!/usr/bin/env bash
# cloudflared-tunnel-run.sh — pm2-safe wrapper for `cloudflared tunnel run`.
#
# Why this wrapper exists:
#   pm2 start "cloudflared tunnel run --token <X>" --name cloudflared
# silently breaks. pm2 string-parses the command, mangles the spaces around
# --token, and cloudflared exits with "unrecognized argument". The fix
# documented in 2-day forensics: ALWAYS wrap cloudflared invocations in a
# shell script so pm2 only execs one binary.
#
# Usage:
#   pm2 start /data/.openclaw/scripts/cloudflared-tunnel-run.sh --name cloudflared
#
# Token source order: $CLOUDFLARED_TOKEN env, then $1 positional.
set -euo pipefail
TOKEN="${CLOUDFLARED_TOKEN:-${1:-}}"
if [ -z "$TOKEN" ]; then
    echo "[cloudflared-tunnel-run] ERROR: no token. Set CLOUDFLARED_TOKEN env or pass as arg." >&2
    exit 2
fi
if ! command -v cloudflared >/dev/null 2>&1; then
    echo "[cloudflared-tunnel-run] ERROR: cloudflared not on PATH." >&2
    exit 3
fi
exec cloudflared tunnel run --token "$TOKEN"
WRAPEOF
    chmod +x "$wrapper" 2>/dev/null || true
    _log "Wrote cloudflared pm2-safe wrapper → $wrapper"
    return 0
}

# ─── #15: Fresh-VPS CLI scope auto-approval ──────────────────────────────────
# On a fresh VPS, openclaw CLI commands fail with "scope upgrade pending
# approval" because /data/.openclaw/devices/pending.json contains a
# persistent requestId that the install.sh-spawned CLI has no way to
# self-approve. The ephemeral requestId in connect-failure errors is a
# RED HERRING — we must approve the persistent one in pending.json.
harden_cli_scope_approve() {
    local oc_root
    oc_root="$(_oc_root)"
    [ -z "$oc_root" ] && return 0
    local pending="$oc_root/devices/pending.json"
    [ -f "$pending" ] || return 0
    if ! command -v openclaw >/dev/null 2>&1; then return 0; fi
    local token="${OPENCLAW_GATEWAY_TOKEN:-}"
    if [ -z "$token" ]; then
        # Try to read from secrets/.env
        local env_file="$oc_root/secrets/.env"
        if [ -f "$env_file" ]; then
            token=$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' "$env_file" | head -1 | cut -d= -f2- | tr -d '"' || true)
        fi
    fi
    [ -z "$token" ] && return 0

    # Extract persistent request IDs from pending.json
    local req_ids
    req_ids=$(python3 -c "
import json, sys
try:
    d = json.load(open('$pending'))
    items = d if isinstance(d, list) else d.get('pending', [])
    for it in items:
        rid = it.get('requestId') or it.get('id')
        if rid: print(rid)
except Exception:
    pass
" 2>/dev/null || true)

    if [ -z "$req_ids" ]; then return 0; fi
    local rid
    while IFS= read -r rid; do
        [ -z "$rid" ] && continue
        _log "Auto-approving persistent CLI scope requestId: $rid"
        openclaw devices approve --token "$token" "$rid" >/dev/null 2>&1 || true
    done <<< "$req_ids"
    return 0
}

# ─── #17: SSL_CERT_FILE phantom path ─────────────────────────────────────────
# Python's ssl default points at /data/linuxbrew/.linuxbrew/etc/openssl@3/
# cert.pem which DOES NOT EXIST on the Hostinger image. Result: every
# Python HTTPS call (google-genai, httpx, requests) fails with SSL verify
# errors. Fix: write the canonical Debian CA bundle path to secrets/.env.
harden_ssl_cert_file() {
    local oc_root
    oc_root="$(_oc_root)"
    [ -z "$oc_root" ] && return 0
    local env_file="$oc_root/secrets/.env"
    # Only apply on VPS (the Debian path is Linux-specific)
    if [ "$(uname -s)" != "Linux" ]; then return 0; fi
    if [ ! -f /etc/ssl/certs/ca-certificates.crt ]; then return 0; fi
    mkdir -p "$(dirname "$env_file")" 2>/dev/null || return 0
    touch "$env_file" 2>/dev/null || return 0

    _harden_set_env_var() {
        local key="$1" value="$2" file="$3"
        if grep -qE "^${key}=" "$file" 2>/dev/null; then
            # already set — leave it alone (operator may have a reason)
            return 0
        fi
        printf '%s=%s\n' "$key" "$value" >> "$file"
        _log "Set $key in $file (was missing — Python ssl phantom path fix)"
    }
    _harden_set_env_var SSL_CERT_FILE    /etc/ssl/certs/ca-certificates.crt "$env_file"
    _harden_set_env_var SSL_CERT_DIR     /etc/ssl/certs                     "$env_file"
    _harden_set_env_var REQUESTS_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt "$env_file"
    return 0
}

# ─── #18: Missing Python deps backfill ───────────────────────────────────────
# google-genai/httpx/requests/certifi aren't pre-installed in the Hostinger
# image. Skill 22/23/35 all call them. install.sh already pip-installs
# google-genai (Step 6); we also need httpx, requests, certifi.
harden_python_deps() {
    local pkg
    for pkg in httpx requests certifi; do
        if ! python3 -c "import $pkg" 2>/dev/null; then
            _log "Installing missing Python dep: $pkg"
            python3 -m pip install --user "$pkg" --break-system-packages 2>/dev/null \
              || python3 -m pip install --user "$pkg" 2>/dev/null \
              || _log "WARN: failed to install $pkg (continuing)"
        fi
    done
    return 0
}

# ─── Composite entrypoint ────────────────────────────────────────────────────
# ─── v10.14.36 #19: Stuck *-resume cron sweep ────────────────────────────────
# Fleet-wide safety net for the v10.14.16–v10.14.35 workforce-build-resume
# self-stop bug (Lyric/Evelyn 2026-05-24 incident: cron looped every 15 min
# for 6+ hours burning DeepSeek-V4-Pro tokens on a completed build).
#
# Sweeps `openclaw cron list` for any cron whose name ends in `-resume` AND
# whose last_fired (if reported) is >24h old AND whose created (if reported)
# is >7d old. Those crons are almost certainly stuck pings against a
# long-finished state file. We remove them.
#
# Idempotent: when there's nothing to sweep, exits silently. Never blocks.
# Conservative: only touches names ending in `-resume` so we don't disturb
# anything else the operator set up.
harden_check_cron_loops() {
    command -v openclaw >/dev/null 2>&1 || return 0
    local listing
    listing=$(openclaw cron list 2>/dev/null) || return 0
    [ -z "$listing" ] && return 0

    # Try the JSON shape first (newer openclaw). Falls back to plaintext.
    local json
    json=$(openclaw cron list --json 2>/dev/null || true)
    if [ -n "$json" ] && command -v python3 >/dev/null 2>&1; then
        local candidates
        candidates=$(python3 - "$json" <<'PY'
import json, sys, datetime as dt
raw = sys.argv[1]
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)
items = data if isinstance(data, list) else data.get("crons") or data.get("items") or []
now = int(dt.datetime.utcnow().timestamp())
def to_epoch(s):
    if not s: return None
    try:
        return int(dt.datetime.fromisoformat(str(s).replace("Z","+00:00")).timestamp())
    except Exception:
        return None
for c in items:
    name = c.get("name") or ""
    if not name.endswith("-resume"):
        continue
    uuid = c.get("id") or c.get("uuid") or name
    lf = to_epoch(c.get("lastFiredAt") or c.get("last_fired") or c.get("lastRunAt"))
    cr = to_epoch(c.get("createdAt") or c.get("created") or c.get("createdOn"))
    # Conservative: require BOTH last_fired > 24h AND created > 7d. Missing
    # data means "we don't know" — skip to avoid a false-positive remove.
    if lf is None or cr is None:
        continue
    age_h = (now - lf) // 3600
    age_d = (now - cr) // 86400
    if age_h > 24 and age_d > 7:
        print(f"{uuid}|{name}|{age_h}")
PY
)
        if [ -n "$candidates" ]; then
            while IFS='|' read -r uuid name age_h; do
                [ -z "$uuid" ] && continue
                _log "harden_check_cron_loops: removing stale resume cron $name ($uuid, last fired ${age_h}h ago)"
                if openclaw cron rm "$uuid" >/dev/null 2>&1; then
                    _log "harden_check_cron_loops: removed $uuid"
                else
                    _log "harden_check_cron_loops: rm $uuid FAILED (continuing)"
                fi
            done <<<"$candidates"
            return 0
        fi
    fi

    # Plaintext fallback (older openclaw without --json). Conservative:
    # only acts when we can parse a clear "Nd" age token next to a -resume
    # name. If the format is ambiguous, we no-op rather than risk removing
    # a healthy cron.
    local line uuid days_token days
    while IFS= read -r line; do
        [[ "$line" =~ -resume ]] || continue
        uuid=$(echo "$line" | awk '{ for (i=1;i<=NF;i++) if ($i ~ /^[0-9a-fA-F-]{8,}$/) { print $i; exit } }')
        [ -z "$uuid" ] && continue
        days_token=$(echo "$line" | grep -oE '[0-9]+d' | head -1)
        [ -z "$days_token" ] && continue
        days="${days_token%d}"
        if [ "$days" -ge 7 ]; then
            _log "harden_check_cron_loops (plaintext): removing stale resume cron $uuid (${days}d old)"
            if openclaw cron rm "$uuid" >/dev/null 2>&1; then
                _log "harden_check_cron_loops: removed $uuid"
            else
                _log "harden_check_cron_loops: rm $uuid FAILED (continuing)"
            fi
        fi
    done <<<"$listing"
    return 0
}

run_install_hardening() {
    _log "Running install hardening (2-day forensics from 2026-05-23/24)..."
    harden_check_compose_pin
    harden_unset_port
    harden_hooks_token
    harden_cloudflared_wrapper
    harden_cli_scope_approve
    harden_ssl_cert_file
    harden_python_deps
    harden_check_cron_loops
    _log "Install hardening complete (best-effort; non-blocking)."
    return 0
}

# Standalone-runnable: if invoked directly (not sourced), run all hardening.
if [ "${BASH_SOURCE[0]}" = "${0:-}" ]; then
    run_install_hardening
fi
