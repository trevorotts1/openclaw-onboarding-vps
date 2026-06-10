#!/usr/bin/env bash

# ============================================================
#  OpenClaw Skills Updater — VPS (Hostinger Docker) Version
#  v11.6.0
#  Updates skills from GitHub. Inside the OpenClaw container, $HOME=/data
#  so $HOME/.openclaw resolves to /data/.openclaw correctly.
# ============================================================

# ============================================================
# v10.14.0 — Hostinger Docker host auto-detect + container re-exec
# Mirror of install.sh's auto-detect. See install.sh for rationale.
# ============================================================
if [ -z "${OPENCLAW_NO_CONTAINER_REEXEC:-}" ] \
   && [ ! -d /data ] \
   && command -v docker >/dev/null 2>&1; then

    _oc_container="${OPENCLAW_CONTAINER_NAME:-}"
    if [ -z "$_oc_container" ]; then
        _oc_matches=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -E 'openclaw' || true)
        _oc_match_count=$(printf '%s\n' "$_oc_matches" | grep -c '.' || true)
        if [ "${_oc_match_count:-0}" -gt 1 ]; then
            echo "" >&2
            echo "ERROR: Multiple running OpenClaw containers detected on this host:" >&2
            printf '%s\n' "$_oc_matches" | sed 's/^/  - /' >&2
            echo "" >&2
            echo "Re-run with the container name explicit:" >&2
            echo "  OPENCLAW_CONTAINER_NAME=<name> \\" >&2
            echo "    curl -fSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/update-skills.sh | bash" >&2
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
        echo "  Script:    update-skills.sh"
        echo "  Overrides: OPENCLAW_NO_CONTAINER_REEXEC=1, OPENCLAW_CONTAINER_NAME=<name>"
        echo "════════════════════════════════════════════════════════════"
        echo ""

        exec docker exec -i -u "$_oc_user" "$_oc_container" bash -c \
            "curl -fSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/update-skills.sh | bash"
    fi
fi

# Safety belt
if [ ! -d /data ] && command -v docker >/dev/null 2>&1 \
   && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qE 'openclaw'; then
    echo "ERROR: An OpenClaw container is configured on this host but the" >&2
    echo "       auto-detect re-exec did not complete. Refusing to update" >&2
    echo "       host paths (the container cannot see them)." >&2
    echo "" >&2
    echo "       Run manually: docker exec -u node -i <container> bash -c \\" >&2
    echo "         'curl -fSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/update-skills.sh | bash'" >&2
    exit 1
fi

set -euo pipefail

ONBOARDING_VERSION="v11.6.0"

LOG_FILE="/tmp/openclaw-update-$(date +%Y%m%d-%H%M%S).log"

# v10.16.48 — FIX 1 (ONBOARDING HONESTY): source the state-machine + gate so the
# "Skills updated successfully!" banner + completion Telegram are CONDITIONAL on
# the verification gate, not on a file copy. lib-onboarding-state.sh is pulled
# fresh with the repo zip; the helpers fall back to no-ops if it isn't present.
OC_CONFIG="${OC_CONFIG:-/data/.openclaw}"
[ -d "$OC_CONFIG" ] || OC_CONFIG="$HOME/.openclaw"
OC_SKILLS_DIR="${OC_SKILLS_DIR:-$OC_CONFIG/skills}"
OC_WORKSPACE_DEFAULT="${OC_WORKSPACE_DEFAULT:-$OC_CONFIG/workspace}"
ONBOARDING_STATE_FILE="${ONBOARDING_STATE_FILE:-$OC_CONFIG/.onboarding-state.json}"
_us_lib_state="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/lib-onboarding-state.sh"
[ -f "$_us_lib_state" ] || _us_lib_state="$OC_CONFIG/onboarding/lib-onboarding-state.sh"
if [ -f "$_us_lib_state" ]; then
  # shellcheck source=/dev/null
  source "$_us_lib_state"
fi
command -v oc_state_seed          >/dev/null 2>&1 || oc_state_seed()          { :; }
command -v oc_state_set           >/dev/null 2>&1 || oc_state_set()           { :; }
command -v oc_onboarding_complete >/dev/null 2>&1 || oc_onboarding_complete() { return 1; }
command -v oc_state_summary       >/dev/null 2>&1 || oc_state_summary()       { OC_VERIFIED=0; OC_TOTAL=0; OC_FAILED_LIST=""; OC_PENDING_LIST=""; OC_INTERVIEW_LIST=""; }

# ----------------------------------------------------------
# Telegram Progress Notification (mirrors install.sh)
# ----------------------------------------------------------
TELEGRAM_LAST_RESULT=""
send_telegram_progress() {
  local message="$1"
  local OCJSON="$HOME/.openclaw/openclaw.json"
  local TELEGRAM_TARGET=""
  TELEGRAM_LAST_RESULT="skipped"

  if [ -f "$OCJSON" ] && command -v python3 >/dev/null 2>&1; then
    TELEGRAM_TARGET=$(python3 -c "
import json
try:
    cfg = json.load(open('$OCJSON'))
    allow = cfg.get('channels', {}).get('telegram', {}).get('allowFrom', [])
    if allow:
        print(allow[0])
except:
    pass
" 2>/dev/null)
  fi

  if ! command -v openclaw >/dev/null 2>&1; then
    TELEGRAM_LAST_RESULT="no-openclaw-cli"
    return 0
  fi
  if [ -z "$TELEGRAM_TARGET" ]; then
    TELEGRAM_LAST_RESULT="no-telegram-target"
    return 0
  fi
  if openclaw message send --channel telegram --target "$TELEGRAM_TARGET" --message "$message" >> "$LOG_FILE" 2>&1; then
    TELEGRAM_LAST_RESULT="sent:$TELEGRAM_TARGET"
  else
    TELEGRAM_LAST_RESULT="failed:see-$LOG_FILE"
  fi
}

# ----------------------------------------------------------
# Write UPDATE PENDING flag to AGENTS.md
# ----------------------------------------------------------
write_update_pending_flag() {
  local version="$1"
  local new_skills="$2"

  local WORKSPACE_DIR="$HOME/clawd"
  [ ! -d "$WORKSPACE_DIR" ] && WORKSPACE_DIR="$HOME/.openclaw/workspace"
  mkdir -p "$WORKSPACE_DIR"
  local AGENTS_FILE="$WORKSPACE_DIR/AGENTS.md"

  touch "$AGENTS_FILE"
  # v10.16.48 — FIX 1 (ONBOARDING HONESTY): FULL-SECTION dedupe (was a
  # line-based grep -v that left prior flag bodies behind → stacked duplicates).
  # Strip every prior "## …UPDATE PENDING…" section from its heading through the
  # "<!-- /UPDATE-PENDING-FLAG -->" end-marker (inclusive); fallback to
  # heading→next-H1/H2 for legacy markerless flags.
  AGENTS_FILE="$AGENTS_FILE" python3 - <<'PYEOF' 2>/dev/null || true
import re, os
p=os.environ["AGENTS_FILE"]
try: txt=open(p,errors="ignore").read()
except Exception: raise SystemExit
pat=re.compile(r'\n*##\s*🔴🔴🔴\s*UPDATE PENDING.*?<!--\s*/UPDATE-PENDING-FLAG\s*-->\n*',re.DOTALL)
new=pat.sub('\n',txt)
if new==txt:
    pat2=re.compile(r'\n*##\s*🔴🔴🔴\s*UPDATE PENDING.*?(?=\n##\s|\n#\s|\Z)',re.DOTALL)
    new=pat2.sub('\n',txt)
new=re.sub(r'\n{3,}','\n\n',new)
open(p,"w").write(new)
PYEOF

  local DATE_STAMP
  DATE_STAMP=$(date +%Y-%m-%d)

  cat >> "$AGENTS_FILE" <<FLAGCONTENT

## 🔴🔴🔴 UPDATE PENDING — SKILL UPDATE TO ${version}

**EXECUTION MODE: DO NOT ASK PERMISSION. EXECUTE IMMEDIATELY.**

A skill update was applied via update-skills.sh on ${DATE_STAMP}. Process the activation steps now.

### What changed in this update
- Onboarding version: ${version}
- New skills installed (require ACTIVATION): ${new_skills:-none — updates only}

### How to process each NEW skill (only NEW ones, updates are already in place)

For each new skill folder under \`~/.openclaw/skills/\`:
1. READ all files (Teach Yourself Protocol): SKILL.md, INSTALL.md, CORE_UPDATES.md, QC.md, plus any \`references/*.md\` files
2. CHECK prerequisites and search ALL standard credential locations (canonical: \`~/.openclaw/secrets/.env\` on Mac, \`/data/.openclaw/secrets/.env\` on VPS, plus \`openclaw.json\` env.vars). Skip asking the owner if values already exist.
3. EXECUTE the activation steps in INSTALL.md (read ≠ execute)
4. APPLY CORE_UPDATES.md surgically — add to AGENTS.md / TOOLS.md / MEMORY.md / SOUL.md only the sections explicitly labeled in that file
5. RUN the bundled QC checks; do not declare done until QC reaches a pass score (skills with a \`qc-*.sh\` script must exit 0)
6. SET this skill's status in \`/data/.openclaw/.onboarding-state.json\` to \`qc-passed\` ONLY when the VERIFICATION GATE holds: (a) \`openclaw skills info <registered-name>\` Ready/visible, (b) its CORE_UPDATES sentinel is present in the workspace files (if it ships CORE_UPDATES), (c) its \`qc-*.sh\` exits 0. Otherwise \`qc-failed\`. Owner-input-blocked → \`interview-pending\`.
7. REPORT to owner HONESTLY from the state file: "N/M verified-installed" — NEVER say installed/done/onboarded for a skill that is not \`qc-passed\`.

### Discipline (binding)
- Skills 22-23: MAIN ORCHESTRATOR ONLY, never delegate
- Tier order in any tiered skill (e.g. skill 36 GHL MCP): try Tier N before Tier N+1, no skipping
- Disclosure headers (e.g. \`[GHL tier used: N — tool_name]\`) required per any skill's SOUL-level rules
- No destructive shortcuts: no \`--force\`, no \`--no-verify\`, no \`--break-system-packages\` unless explicitly instructed
- The \`onboarding-resume\` cron re-fires this work every 15 min and only stops when the verification gate passes — a self-declared "done" will not stop it.

### When activation is complete (verification gate, not a feeling)
- Remove this entire UPDATE PENDING section from AGENTS.md ONLY after every skill in \`.onboarding-state.json\` is \`qc-passed\` or \`interview-pending\`. Prose-only steps you cannot mechanize stay at \`wired\` and are surfaced as a remaining GATED step — do NOT mark them \`qc-passed\`.
- Add to MEMORY.md under "## System Updates":
  "${version} update applied on ${DATE_STAMP}. [VERIFIED]/[TOTAL] skills verified-installed (per .onboarding-state.json). New skills: ${new_skills:-none}."

<!-- /UPDATE-PENDING-FLAG -->
FLAGCONTENT
  echo "  ✓ UPDATE PENDING flag written to $AGENTS_FILE"

  # Seed Core.md terminology into MEMORY.md (idempotent)
  local MEMORY_FILE="$WORKSPACE_DIR/MEMORY.md"
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
    echo "  ✓ Core.md terminology seeded into MEMORY.md"
  fi
}

# ----------------------------------------------------------
# v10.16.49 — ensure_skills_loader_source (REMOVED / NO-OP)
# The previous implementation wrote skills.path into openclaw.json,
# but skills.path is NOT a valid key on OpenClaw 2026.5.x — the
# gateway rejects it with "skills Unrecognized key path / skills
# Invalid input" and, under set -euo pipefail, this aborted the
# ENTIRE updater BEFORE writing .onboarding-version / running
# migrate / qc / cron-create (root cause of Corey + Maria
# deploy-breaking update failures, 2026-06-06).
#
# Numbered skills auto-discover from the default ~/.openclaw/skills
# root on 2026.5.x — no skills.path or skills.load.extraDirs
# registration is required. This function is kept as an explicit
# no-op so existing callers continue to compile under set -euo.
# ----------------------------------------------------------
ensure_skills_loader_source() {
  local SKILLS_DIR="$1"
  echo "  (skills loader-source: auto-discovered from ${SKILLS_DIR} — no openclaw.json write needed)"
}

# ----------------------------------------------------------
# v10.16.49 — safe_json_edit
# Harden any direct write to openclaw.json: back up, apply the
# python3 transform, validate with `openclaw config validate`,
# and ROLL BACK from the backup on failure so one bad key can
# never abort the updater under set -euo pipefail.
#
# Usage:
#   safe_json_edit OCJSON_PATH DESCRIPTION python3_heredoc_func
# where python3_heredoc_func is a bash function that:
#   - receives OCJSON_PATH as $1
#   - edits the file in-place
#   - exits 0 on success, non-zero on failure
#
# Because there are currently NO direct json.dump writes remaining
# in this script after the skills.path removal, this helper is
# provided for future edits and is not called inline yet.
# ----------------------------------------------------------
safe_json_edit() {
  local OCJSON="$1"
  local DESCRIPTION="${2:-openclaw.json edit}"
  local EDIT_FUNC="$3"

  if [ ! -f "$OCJSON" ]; then
    echo "  [safe_json_edit] $OCJSON not found — skipping $DESCRIPTION"
    return 0
  fi

  local BACKUP="${OCJSON}.bak-$(date +%Y%m%d-%H%M%S)"
  cp -f "$OCJSON" "$BACKUP" 2>/dev/null || {
    echo "  [safe_json_edit] WARN: could not create backup — skipping $DESCRIPTION"
    return 0
  }

  # Run the edit function
  if ! "$EDIT_FUNC" "$OCJSON"; then
    echo "  [safe_json_edit] WARN: edit function failed — rolling back $DESCRIPTION"
    cp -f "$BACKUP" "$OCJSON" 2>/dev/null || true
    rm -f "$BACKUP" 2>/dev/null || true
    return 0
  fi

  # Validate with the CLI if available
  if command -v openclaw >/dev/null 2>&1; then
    if ! openclaw config validate >> "$LOG_FILE" 2>&1; then
      echo "  [safe_json_edit] WARN: openclaw config validate FAILED after $DESCRIPTION — rolling back"
      cp -f "$BACKUP" "$OCJSON" 2>/dev/null || true
      rm -f "$BACKUP" 2>/dev/null || true
      return 0
    fi
  fi

  rm -f "$BACKUP" 2>/dev/null || true
  echo "  [safe_json_edit] $DESCRIPTION applied and validated OK"
}

# ----------------------------------------------------------
# v10.16.50 — link_shared_core_files (Zero-Human-Workforce file model)
# On every box, ALL of an account's agents + sub-agents SHARE that box's ONE
# canonical AGENTS.md / TOOLS.md / USER.md (symlinked, NOT duplicated). The
# per-agent files (IDENTITY.md / SOUL.md / MEMORY.md / HEARTBEAT.md) stay each
# agent's OWN real files and are never touched (except the additive content
# preservation into IDENTITY.md described below).
#
# CO-MINGLING GUARD (N29): the symlink target is ALWAYS the LOCAL box's own
# canonical workspace (agents.defaults.workspace). It is NEVER a hardcoded or
# cross-box path. A client box links to the CLIENT's own files (the client is
# the USER) — never to the operator's or another account's files.
#
# NESTED WORKFLOW AGENT EXEMPTION: any workspace path matching */workflows/*/agents/*
# (internal workflow micro-agents, e.g. workflows/bug-fix/agents/triager) is
# EXEMPT — its core files are NEVER modified.
#
# IDEMPOTENT: a second run makes no new backups and no churn. NON-DESTRUCTIVE:
# a real file is backed up to <file>.bak-unify-<ts> (never deleted) and any of
# its content not already present in the canonical file is APPENDED to the
# agent's own IDENTITY.md under a guarded marker before it is replaced by a
# symlink. Full rule: docs/SHARED-CORE-FILES.md + AGENTS.md N32.
#
# Optional $1 = explicit CANON_DIR (the install path passes the resolved
# workspace). If empty, resolve from openclaw.json agents.defaults.workspace.
# ----------------------------------------------------------
link_shared_core_files() {
  local CANON_OVERRIDE="${1:-}"
  local TS; TS="$(date +%Y%m%d-%H%M%S)"
  local LP="  [shared-core]"

  local OCJSON=""
  for cand in "${OC_JSON:-}" "/data/.openclaw/openclaw.json" "$HOME/.openclaw/openclaw.json"; do
    [ -n "$cand" ] && [ -f "$cand" ] && { OCJSON="$cand"; break; }
  done

  # CO-MINGLING GUARD: CANON_DIR is ALWAYS the LOCAL box's own default agent
  # workspace (agents.defaults.workspace). NEVER a hardcoded or cross-box path.
  local CANON_DIR="$CANON_OVERRIDE"
  if [ -z "$CANON_DIR" ] && [ -n "$OCJSON" ] && command -v python3 >/dev/null 2>&1; then
    CANON_DIR="$(python3 -c "
import json
try:
    cfg=json.load(open('$OCJSON'))
    print((cfg.get('agents',{}).get('defaults',{}) or {}).get('workspace','') or '')
except Exception:
    print('')
" 2>/dev/null)"
  fi
  [ -z "$CANON_DIR" ] && CANON_DIR="$HOME/clawd"

  if [ ! -d "$CANON_DIR" ]; then
    echo "$LP CANON_DIR '$CANON_DIR' does not exist — skipping (nothing to share against)."
    return 0
  fi
  local CANON_REAL; CANON_REAL="$(cd "$CANON_DIR" 2>/dev/null && pwd -P || echo "$CANON_DIR")"
  echo "$LP canonical workspace (CANON_DIR) = $CANON_DIR"
  local SHARED_FILES="AGENTS.md TOOLS.md USER.md"

  # --- Enumerate candidate agent workspaces (local box only) ---
  local WS_LIST=""
  if [ -n "$OCJSON" ] && command -v python3 >/dev/null 2>&1; then
    WS_LIST="$(python3 -c "
import json
try:
    cfg=json.load(open('$OCJSON'))
except Exception:
    cfg={}
seen=set()
def emit(w):
    if w and w not in seen:
        seen.add(w); print(w)
ag=cfg.get('agents',{}) or {}
for key in ('list','agents'):
    for a in (ag.get(key) or []):
        if isinstance(a,dict):
            emit(a.get('workspace',''))
" 2>/dev/null)"
  fi
  # On-disk scan of known agent-workspace roots + any */workflows/*/agents/*.
  # The workflow dirs are scanned ONLY so the nested workflow agent guard can positively
  # EXEMPT them (they are never modified).
  local SCAN_ROOTS="/data/.openclaw/agents $HOME/.openclaw/agents $CANON_DIR/agents"
  for root in $SCAN_ROOTS; do
    [ -d "$root" ] || continue
    for d in "$root"/*/; do
      [ -d "$d" ] && WS_LIST="$WS_LIST
${d%/}"
    done
  done
  for wfagent in "$CANON_DIR"/workflows/*/agents/*/ /data/.openclaw/workspace/workflows/*/agents/*/; do
    [ -d "$wfagent" ] && WS_LIST="$WS_LIST
${wfagent%/}"
  done
  WS_LIST="$(printf '%s\n' "$WS_LIST" | awk 'NF' | sort -u)"

  local linked=0 repointed=0 backed_up=0 preserved=0 skipped_canon=0 skipped_workflow_agent=0 noop=0
  local W
  while IFS= read -r W; do
    [ -n "$W" ] && [ -d "$W" ] || continue
    local W_REAL; W_REAL="$(cd "$W" 2>/dev/null && pwd -P || echo "$W")"

    # The canonical workspace OWNS the real files — never link it to itself.
    if [ "$W_REAL" = "$CANON_REAL" ]; then
      skipped_canon=$((skipped_canon+1)); continue
    fi
    # NESTED WORKFLOW AGENT EXEMPTION: */workflows/*/agents/* internal micro-agents — NEVER touch.
    case "$W_REAL" in
      */workflows/*/agents/*)
        echo "$LP nested workflow agent EXEMPT (untouched): $W_REAL"
        skipped_workflow_agent=$((skipped_workflow_agent+1)); continue ;;
    esac

    local agent_name; agent_name="$(basename "$W_REAL")"
    local f
    for f in $SHARED_FILES; do
      local target="$CANON_DIR/$f"
      local link="$W/$f"
      [ -e "$target" ] || continue   # canonical source must exist to link against

      if [ -L "$link" ]; then
        # Already a symlink — repoint ONLY if it points somewhere wrong.
        local cur; cur="$(readlink "$link" 2>/dev/null || echo "")"
        local cur_real; cur_real="$(cd "$W" 2>/dev/null && cd "$(dirname "$cur")" 2>/dev/null && pwd -P)/$(basename "$cur")"
        local want_real="$CANON_REAL/$f"
        if [ "$cur" = "$target" ] || [ "$cur_real" = "$want_real" ]; then
          noop=$((noop+1))
        else
          ln -sfn "$target" "$link"
          echo "$LP repointed symlink: $link -> $target (was -> $cur)"
          repointed=$((repointed+1))
        fi
        continue
      fi

      if [ -e "$link" ]; then
        # A REAL file. Back it up (NEVER delete), preserve unique content into
        # the agent's own IDENTITY.md additively, then replace with a symlink.
        local bak="$link.bak-unify-$TS"
        if [ -e "$bak" ]; then noop=$((noop+1)); continue; fi
        cp -p "$link" "$bak" 2>/dev/null || cp "$link" "$bak" 2>/dev/null || true
        echo "$LP backed up real $f -> $bak"
        backed_up=$((backed_up+1))

        if command -v python3 >/dev/null 2>&1; then
          local pres_rc
          pres_rc="$(IDENTITY="$W/IDENTITY.md" SRCFILE="$link" CANONFILE="$target" \
                     AGENT="$agent_name" FNAME="$f" TS="$TS" \
                     python3 - <<'PYEOF'
import os
identity=os.environ["IDENTITY"]; src=os.environ["SRCFILE"]; canon=os.environ["CANONFILE"]
agent=os.environ["AGENT"]; fname=os.environ["FNAME"]; ts=os.environ["TS"]
def rd(p):
    try: return open(p,errors="ignore").read().splitlines()
    except Exception: return []
src_lines=rd(src); canon_set=set(l.strip() for l in rd(canon))
# Unique = non-blank lines in the per-agent file NOT already in the canonical
# file. ADD only — never remove. Preserve original order.
unique=[l for l in src_lines if l.strip() and l.strip() not in canon_set]
if not unique: print("NONE"); raise SystemExit(0)
try: existing=open(identity,errors="ignore").read()
except Exception: existing=""
# Idempotency: never re-append if a marker for THIS agent+file already exists.
if f"PRESERVED FROM {agent} {fname} (unification" in existing:
    print("ALREADY"); raise SystemExit(0)
marker=f"<!-- PRESERVED FROM {agent} {fname} (unification {ts}) -->"
block="\n\n"+marker+"\n"+"\n".join(unique)+"\n<!-- /PRESERVED -->\n"
with open(identity,"a") as fh: fh.write(block)  # creates IDENTITY.md if absent
print("WROTE")
PYEOF
          )"
          if [ "$pres_rc" = "WROTE" ]; then
            echo "$LP preserved unique $f content -> $W/IDENTITY.md (guarded marker)"
            preserved=$((preserved+1))
          fi
        fi

        rm -f "$link"
        ln -sfn "$target" "$link"
        echo "$LP linked (was real file): $link -> $target"
        linked=$((linked+1))
        continue
      fi
      # Absent → leave absent (do NOT create a stray symlink the agent never had).
      noop=$((noop+1))
    done
  done <<< "$WS_LIST"

  echo "$LP done: linked=$linked repointed=$repointed backed_up=$backed_up preserved=$preserved canon-skipped=$skipped_canon workflow-agent-exempt=$skipped_workflow_agent noop=$noop"
}

# ----------------------------------------------------------
# v10.16.47 — wire_skill_core_updates
# Idempotently merge CORE_UPDATES.md sections into workspace
# AGENTS.md / TOOLS.md / MEMORY.md / SOUL.md.
# Guards: each section uses the first heading line as a sentinel
# so re-running never double-appends.
# ----------------------------------------------------------
merge_core_updates() {
  local SKILL_DIR="$1"   # absolute path to the installed skill folder
  local SKILL_NAME="$2"  # e.g. "36-ghl-mcp-setup"

  local CORE_FILE="$SKILL_DIR/CORE_UPDATES.md"
  [ -f "$CORE_FILE" ] || return 0

  local WORKSPACE_DIR="$HOME/clawd"
  [ ! -d "$WORKSPACE_DIR" ] && WORKSPACE_DIR="$HOME/.openclaw/workspace"
  mkdir -p "$WORKSPACE_DIR"

  # Extract and append labeled sections via python3 — handles multi-line blocks
  python3 - "$CORE_FILE" "$WORKSPACE_DIR" "$SKILL_NAME" <<'PYEOF'
import re, sys, os

core_path   = sys.argv[1]
workspace   = sys.argv[2]
skill_name  = sys.argv[3]

try:
    content = open(core_path).read()
except Exception:
    sys.exit(0)

# Map target-file keywords to filenames
target_map = {
    "AGENTS.md":  "AGENTS.md",
    "TOOLS.md":   "TOOLS.md",
    "MEMORY.md":  "MEMORY.md",
    "SOUL.md":    "SOUL.md",
}

# Split on section headers like:
#   ## AGENTS.md — UPDATE REQUIRED
#   ## TOOLS.md — UPDATE REQUIRED
#   ## MEMORY.md — NO UPDATE NEEDED
# Capture everything after the header until the next ## section or EOF.
sections = re.split(r'\n(?=## )', content)

for section in sections:
    header_match = re.match(r'## (AGENTS|TOOLS|MEMORY|SOUL)\.md', section)
    if not header_match:
        continue

    target_key = header_match.group(0).split('—')[0].strip().replace('## ', '')
    # e.g. "AGENTS.md", "MEMORY.md"

    # Skip NO UPDATE NEEDED sections
    if 'NO UPDATE NEEDED' in section.split('\n')[0]:
        continue

    target_file = os.path.join(workspace, target_key)

    # Extract the body (everything after the header line)
    body_lines = section.split('\n', 1)
    if len(body_lines) < 2:
        continue
    body = body_lines[1].strip()
    if not body:
        continue

    # Find a stable sentinel: the first ## heading inside the body,
    # or the first non-empty line if no heading exists.
    sentinel_match = re.search(r'^##\s+.+', body, re.MULTILINE)
    if sentinel_match:
        sentinel = sentinel_match.group(0).strip()
    else:
        sentinel = body.split('\n')[0].strip()

    if not sentinel:
        continue

    # Check if sentinel already present in the target file
    try:
        existing = open(target_file).read() if os.path.exists(target_file) else ""
    except Exception:
        existing = ""

    if sentinel in existing:
        print(f"  [{skill_name}] {target_key}: sentinel already present — skip", flush=True)
        continue

    # Append with a skill guard comment
    guard = f"\n<!-- skill:{skill_name} core-update -->\n"
    try:
        with open(target_file, 'a') as f:
            f.write(guard + body + "\n")
        print(f"  [{skill_name}] {target_key}: merged ({len(body)} chars)", flush=True)
    except Exception as e:
        print(f"  [{skill_name}] {target_key}: merge failed: {e}", flush=True)
PYEOF
}

# ----------------------------------------------------------
# v10.16.47 — wire_skill_shell_installers
# Run any idempotent *.sh installer the skill ships
# (install-*.sh / setup-*.sh / wire.sh in the skill root).
# Skips INSTALL.md (prose — agent reads it; script cannot).
# VPS path: /data/linuxbrew/.linuxbrew/bin/brew, never apt.
# ----------------------------------------------------------
wire_skill_shell_installers() {
  local SKILL_DIR="$1"
  local SKILL_NAME="$2"

  local FOUND_ANY="false"
  for installer in \
      "$SKILL_DIR/wire.sh" \
      "$SKILL_DIR/install.sh" \
      "$SKILL_DIR/setup.sh" \
      "$SKILL_DIR"/install-*.sh \
      "$SKILL_DIR"/setup-*.sh \
      "$SKILL_DIR"/qc-ghl-mcp-setup.sh; do
    # Glob may produce no match — guard with -f
    [ -f "$installer" ] || continue
    FOUND_ANY="true"
    local ins_name
    ins_name=$(basename "$installer")
    echo "  [$SKILL_NAME] Running $ins_name..."
    if bash "$installer" >> "$LOG_FILE" 2>&1; then
      echo "  [$SKILL_NAME] $ins_name: OK"
    else
      local rc=$?
      echo "  [$SKILL_NAME] $ins_name: exited $rc (see $LOG_FILE) — continuing"
    fi
  done

  if [ "$FOUND_ANY" = "false" ]; then
    echo "  [$SKILL_NAME] No shell installer found — CORE_UPDATES merge only"
  fi
}

# ----------------------------------------------------------
# v10.16.47 — wire_ghl_mcp
# Register GHL MCP under nested mcp.servers using openclaw mcp set
# (the canonical CLI that writes the nested form per MEMORY.md
# openclaw-mcp-schema-drift.md). Idempotent: `openclaw mcp set`
# is safe to re-run. Fires only if skill 36 is present.
# ----------------------------------------------------------
wire_ghl_mcp() {
  local SKILLS_DIR="$1"
  local SKILL36_DIR="$SKILLS_DIR/36-ghl-mcp-setup"

  [ -d "$SKILL36_DIR" ] || return 0
  command -v openclaw >/dev/null 2>&1 || { echo "  [36-ghl-mcp-setup] openclaw CLI not on PATH — MCP wiring deferred to agent"; return 0; }

  echo "  [36-ghl-mcp-setup] Registering GHL MCP under mcp.servers (idempotent)..."

  # Tier 2 Community MCP — local streamable-http server on :8765
  # (the canonical port per GHL MCP memory entry)
  if openclaw mcp set ghl-community-mcp \
      '{"type":"streamable-http","url":"http://localhost:8765/mcp"}' \
      >> "$LOG_FILE" 2>&1; then
    echo "  [36-ghl-mcp-setup] ghl-community-mcp registered under mcp.servers"
  else
    echo "  [36-ghl-mcp-setup] ghl-community-mcp registration returned non-zero (may already be set — see $LOG_FILE)"
  fi

  # v10.16.48 — FIX 3 (GHL MCP AUTOSTART): registration alone leaves the local
  # :8765 server DOWN, so the registered MCP resolves no tools. START it now
  # (idempotent — no double-start: start-ghl-mcp-server.sh no-ops if already
  # healthy). Container nohup supervision, NOT systemd/launchd. A :8765
  # healthcheck + auto-restart cron is installed by ensure_ghl_mcp_autostart_cron.
  # BUG FIX (v10.16.49): run NON-BLOCKING so the wiring loop + .onboarding-version
  # stamp always complete. Backgrounding is the safe cross-platform fix (no timeout
  # dependency). The MCP still starts; the updater no longer waits on it.
  local START_SCRIPT="$SKILL36_DIR/scripts/start-ghl-mcp-server.sh"
  if [ -f "$START_SCRIPT" ]; then
    chmod +x "$START_SCRIPT" 2>/dev/null || true
    echo "  [36-ghl-mcp-setup] Starting GHL Community MCP on :8765 in background (log: $LOG_FILE)..."
    ( bash "$START_SCRIPT" >> "$LOG_FILE" 2>&1 & )
    ensure_ghl_mcp_autostart_cron "$START_SCRIPT"
  else
    echo "  [36-ghl-mcp-setup] start-ghl-mcp-server.sh not present — server start deferred (older bundle)"
  fi
}

# ----------------------------------------------------------
# v10.16.48 — ensure_ghl_mcp_autostart_cron (FIX 3)
# Supervise the GHL Community MCP on :8765 so it auto-restarts if it dies.
# OpenClaw's cron model is agent-turn based (kind agentTurn / systemEvent via
# `openclaw cron create` with a --message) — there is NO verified shell-exec
# cron flag, so we do NOT invent one. We use the proven agent-message form,
# routed to the OPERATOR account/chat (FIX 2 — never the owner's chat), every
# 15 min: the agent runs the idempotent start/healthcheck script (no-op when
# :8765 is already healthy). Idempotent — never installs twice. The PRIMARY
# start is the synchronous call at wire-time; this cron is the supervisor.
# ----------------------------------------------------------
ensure_ghl_mcp_autostart_cron() {
  local START_SCRIPT="$1"
  command -v openclaw >/dev/null 2>&1 || return 0
  if openclaw cron list 2>/dev/null | grep -qi "ghl-mcp-autostart"; then
    echo "  [36-ghl-mcp-setup] ghl-mcp-autostart cron already installed (idempotent)"
    return 0
  fi

  # Operator escalation chat (FIX 2): keep this maintenance OFF the owner's chat.
  local OP_CHAT
  OP_CHAT="$(openclaw config get env.vars.OPERATOR_HELP_CHAT_ID 2>/dev/null | tail -1 | tr -d '[:space:]')"
  case "$OP_CHAT" in ""|*"not found"*|*"Error"*) OP_CHAT="${OPERATOR_HELP_CHAT_ID:-${OPERATOR_TELEGRAM_CHAT_ID:-5252140759}}" ;; esac

  local MSG="[GHL-MCP-SUPERVISOR — internal, operator-only] Run: bash $START_SCRIPT — it is idempotent and a no-op if :8765 is already healthy. If it reports NOT healthy, the GHL Community MCP died; this restarts it so the registered ghl-community-mcp tools resolve. Do NOT message the owner about this."

  local OK=0
  if openclaw cron create \
      --name "ghl-mcp-autostart" \
      --cron "*/15 * * * *" \
      --tz "America/New_York" \
      --channel telegram \
      --to "$OP_CHAT" \
      --account operator \
      --message "$MSG" >> "$LOG_FILE" 2>&1; then
    OK=1
  elif openclaw cron create \
      --name "ghl-mcp-autostart" \
      --cron "*/15 * * * *" \
      --tz "America/New_York" \
      --channel telegram \
      --to "$OP_CHAT" \
      --message "$MSG" >> "$LOG_FILE" 2>&1; then
    OK=1
  fi
  if [ "$OK" -eq 1 ]; then
    echo "  [36-ghl-mcp-setup] ghl-mcp-autostart cron installed (*/15 healthcheck + restart, operator-routed)"
  else
    echo "  [36-ghl-mcp-setup] ghl-mcp-autostart cron creation returned non-zero (see $LOG_FILE) — server still started this run"
  fi
}

# ----------------------------------------------------------
# v10.16.47 — install_imagemagick_vps
# VPS skill 25/28 require ImageMagick. On Hostinger containers
# apt is a brew shim NOT on PATH — always use linuxbrew directly.
# Idempotent: skips if ImageMagick already installed.
# ----------------------------------------------------------
install_imagemagick_vps() {
  local UPD_LBREW="/data/linuxbrew/.linuxbrew/bin/brew"

  if command -v convert >/dev/null 2>&1 || [ -x "/data/linuxbrew/.linuxbrew/bin/convert" ]; then
    echo "  ImageMagick: already installed"
    return 0
  fi

  echo "  ImageMagick: missing — installing via linuxbrew..."
  if [ -x "$UPD_LBREW" ]; then
    "$UPD_LBREW" install imagemagick >> "$LOG_FILE" 2>&1 \
      && echo "  ImageMagick: installed OK" \
      || echo "  ImageMagick: brew install returned non-zero (see $LOG_FILE) — continuing"
  else
    echo "  ImageMagick: linuxbrew not found at $UPD_LBREW — skipping (install manually)"
  fi
}

# ----------------------------------------------------------
# SKILLS DIRECTORY SECTION — Active-dir-first detection
# ----------------------------------------------------------
# Platform detection:
#   VPS  (Hostinger Docker) → active dir is /data/.openclaw/skills
#                             ($HOME=/data inside the container, so
#                              $HOME/.openclaw/skills resolves correctly)
#   Mac                     → active dir is ~/.openclaw/skills
# We ALWAYS prefer the directory the running agent actually loads,
# falling back to ~/Downloads/openclaw-master-files only when the
# active dir doesn't exist.  Updating a stale Downloads copy while
# the active dir is untouched is a silent no-op (the classic bug).
# ----------------------------------------------------------

# ----------------------------------------------------------
# Discover skills directory — active dir first
# ----------------------------------------------------------
discover_skills_dir() {
  # Detect platform: VPS container has /data, Mac does not.
  # Inside a Hostinger Docker container $HOME is already /data, so
  # $HOME/.openclaw/skills resolves to /data/.openclaw/skills correctly.
  # On a Mac $HOME is the user's home dir and ~/.openclaw/skills is active.
  if [ -d /data ]; then
    # VPS (Hostinger Docker) — active path is /data/.openclaw/skills
    local ACTIVE_DIR="/data/.openclaw/skills"
  else
    # Mac — active path is ~/.openclaw/skills
    local ACTIVE_DIR="$HOME/.openclaw/skills"
  fi

  # Use the active dir whenever it exists and is non-empty
  if [ -d "$ACTIVE_DIR" ]; then
    local SKILL_COUNT=$(ls -d "$ACTIVE_DIR"/[0-9]*/ 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SKILL_COUNT" -gt "0" ]; then
      echo "$ACTIVE_DIR"
      return
    fi
  fi

  # Active dir exists but is empty (first-install into it) — still prefer it
  if [ -d "$ACTIVE_DIR" ]; then
    echo "$ACTIVE_DIR"
    return
  fi

  # Fallback: check Downloads copy (legacy / pre-active-dir installs)
  local LEGACY_DIR="$HOME/Downloads/openclaw-master-files"
  if [ -d "$LEGACY_DIR" ]; then
    local SKILL_COUNT=$(ls -d "$LEGACY_DIR"/[0-9]*/ 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SKILL_COUNT" -gt "0" ]; then
      echo "$LEGACY_DIR"
      return
    fi
  fi

  # Fuzzy search for folders with "openclaw" and "master" in name (case-insensitive)
  local FUZZY_DIR=$(find "$HOME" -maxdepth 2 -type d -iname "*openclaw*" 2>/dev/null | grep -i "master" | head -1)
  if [ -n "$FUZZY_DIR" ] && [ -d "$FUZZY_DIR" ]; then
    local SKILL_COUNT=$(ls -d "$FUZZY_DIR"/[0-9]*/ 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SKILL_COUNT" -gt "0" ]; then
      echo "$FUZZY_DIR"
      return
    fi
  fi

  # Last resort: create and target the active dir (fresh install)
  echo "$ACTIVE_DIR"
}

# ----------------------------------------------------------
# UPDATE PENDING flag handling — search correct locations
# ----------------------------------------------------------
check_update_pending() {
  # Search Mac primary location first, then secondary
  local PENDING_PATHS=(
    "$HOME/Downloads/openclaw-master-files/.pending-setup.md"
    "$HOME/.openclaw/skills/.pending-setup.md"
    "$HOME/.openclaw/onboarding/.pending-setup.md"
  )

  for PENDING in "${PENDING_PATHS[@]}"; do
    if [ -f "$PENDING" ]; then
      echo "$PENDING"
      return
    fi
  done

  # Return empty if not found
  echo ""
}

# ----------------------------------------------------------
# Check .onboarding-version — search multiple paths
# Priority MUST match discover_skills_dir() (active dir first, legacy second)
# so the version we READ is the same location we WRITE to. If the legacy
# Downloads path is checked first the script sees the old stale marker even
# after a successful update → perpetual "needs update" false-positive (Bug B).
# ----------------------------------------------------------
get_current_version() {
  # Detect platform: VPS has /data, Mac does not.
  if [ -d /data ]; then
    local ACTIVE_VERSION_FILE="/data/.openclaw/skills/.onboarding-version"
  else
    local ACTIVE_VERSION_FILE="$HOME/.openclaw/skills/.onboarding-version"
  fi

  # Active dir first (mirrors discover_skills_dir priority)
  local VERSION_PATHS=(
    "$ACTIVE_VERSION_FILE"
    "$HOME/Downloads/openclaw-master-files/.onboarding-version"
    "$HOME/.openclaw/onboarding/.onboarding-version"
  )

  for VERSION_FILE in "${VERSION_PATHS[@]}"; do
    if [ -f "$VERSION_FILE" ]; then
      cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]'
      return
    fi
  done

  # Return empty if not found
  echo ""
}

# ----------------------------------------------------------
# Main update logic
# ----------------------------------------------------------
main() {
  # ----------------------------------------------------------
  # Parse CLI args: --only "05,06,35" installs only those skill folders
  # (number prefix matches skill folder name prefix)
  # ----------------------------------------------------------
  ONLY_SKILLS=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --only)
        shift
        ONLY_SKILLS="${1:-}"
        ;;
      --only=*)
        ONLY_SKILLS="${1#--only=}"
        ;;
      --help|-h)
        echo "Usage: update-skills.sh [--only \"05,06,35\"]"
        echo "  --only LIST   Install only skill folders whose number prefix matches LIST (comma-separated)"
        echo "                Example: --only \"05,06,36\" installs only skills 05-ghl-setup, 06-ghl-install-pages, 36-ghl-mcp-setup"
        echo "  (no flag)     Install/update all skills"
        exit 0
        ;;
    esac
    shift || true
  done

  echo "============================================"
  echo "   OpenClaw Skills Updater (VPS)"
  echo "   Version: ${ONBOARDING_VERSION}"
  if [ -n "$ONLY_SKILLS" ]; then
    echo "   Mode: SELECTIVE — only [$ONLY_SKILLS]"
  fi
  echo "============================================"
  echo ""

  # Discover skills directory
  SKILLS_DIR=$(discover_skills_dir)
  export SKILLS_DIR
  echo "  📂 Skills directory: $SKILLS_DIR"

  # ----------------------------------------------------------
  # Catchup check: if last weekly cron check is older than 7 days,
  # surface a note so the user knows the Sunday cron may have missed.
  # ----------------------------------------------------------
  if [ -f "$SKILLS_DIR/.last-update-check" ]; then
    LAST_CHECK_TS=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$(cat "$SKILLS_DIR/.last-update-check")" +%s 2>/dev/null || \
                    date -d "$(cat "$SKILLS_DIR/.last-update-check")" +%s 2>/dev/null || echo 0)
    NOW_TS=$(date +%s)
    if [ "$LAST_CHECK_TS" -gt 0 ]; then
      DAYS_SINCE=$(( (NOW_TS - LAST_CHECK_TS) / 86400 ))
      if [ "$DAYS_SINCE" -gt 7 ]; then
        echo "  ℹ️  Weekly Sunday check last ran ${DAYS_SINCE} days ago — your machine may have been asleep."
        echo "      This manual run will catch up."
      fi
    fi
  fi

  # Check for UPDATE PENDING flag
  PENDING_FILE=$(check_update_pending)
  if [ -n "$PENDING_FILE" ]; then
    echo "  ⚠️  UPDATE PENDING flag found at: $PENDING_FILE"
    echo "      Review this file before updating: cat $PENDING_FILE"
    echo ""
    if [ -t 0 ]; then
      read -p "Continue with update? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Update cancelled."
        exit 0
      fi
    else
      echo "  Non-interactive mode (curl | bash) — proceeding past UPDATE PENDING flag automatically."
    fi
  fi

  # Check current version
  CURRENT_VERSION=$(get_current_version)
  if [ -n "$CURRENT_VERSION" ]; then
    echo "  Current version: $CURRENT_VERSION"
    echo "  Latest version:  $ONBOARDING_VERSION"
    if [ "$CURRENT_VERSION" = "$ONBOARDING_VERSION" ]; then
      echo ""
      if [ -t 0 ]; then
        read -p "Already up to date. Force re-install? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "  Update cancelled."
          exit 0
        fi
      else
        echo "  Already up to date — non-interactive mode, skipping update."
        exit 0
      fi
    fi
  else
    echo "  No previous version found — fresh install"
  fi

  echo ""
  echo "  Downloading latest skills from GitHub..."

  # v10.16.17: clone instead of curl|unzip. Info-ZIP's `unzip` MANGLES UTF-8
  # filenames (the role-library has em-dash filenames like
  # `qc-specialist-—-sales.md` and `deep-research-role-—-openclaw-maintenance.md`)
  # and silently partial-writes them, so a zip-based update would drop or
  # corrupt those role docs. `git clone` preserves every filename byte-for-byte.
  TEMP_ZIP="/tmp/openclaw-onboarding-update.zip"
  TEMP_EXTRACT="/tmp/openclaw-onboarding-update"
  rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
  EXTRACTED_DIR=""

  if command -v git >/dev/null 2>&1; then
    if git clone --depth 1 "https://github.com/trevorotts1/openclaw-onboarding-vps.git" "$TEMP_EXTRACT" 2>/dev/null; then
      # HARD verify the remote is exactly the intended repo (no leftover-clone mix-up)
      _origin="$(git -C "$TEMP_EXTRACT" remote get-url origin 2>/dev/null)"
      case "$_origin" in
        https://github.com/trevorotts1/openclaw-onboarding-vps.git|https://github.com/trevorotts1/openclaw-onboarding-vps)
          EXTRACTED_DIR="$TEMP_EXTRACT" ;;
        *)
          echo "ERROR: cloned remote ($_origin) is NOT trevorotts1/openclaw-onboarding-vps — refusing to use it."
          rm -rf "$TEMP_EXTRACT"; EXTRACTED_DIR="" ;;
      esac
    fi
  fi

  # Fallback ONLY if git is unavailable or the clone failed: zip + python3
  # zipfile (handles UTF-8 filenames correctly; Hostinger containers may lack
  # both git and a UTF-8-safe unzip). Plain `unzip` is the last resort.
  if [ -z "$EXTRACTED_DIR" ]; then
    echo "  (git clone unavailable/failed — falling back to zip extraction)"
    curl -fSL --progress-bar "https://github.com/trevorotts1/openclaw-onboarding-vps/archive/refs/heads/main.zip" -o "$TEMP_ZIP"
    rm -rf "$TEMP_EXTRACT"; mkdir -p "$TEMP_EXTRACT"
    if command -v python3 >/dev/null 2>&1; then
      python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$TEMP_ZIP" "$TEMP_EXTRACT" 2>/dev/null || true
    else
      unzip -qo "$TEMP_ZIP" -d "$TEMP_EXTRACT" 2>/dev/null || true
    fi
    if [ -d "$TEMP_EXTRACT/openclaw-onboarding-vps-main" ]; then
      EXTRACTED_DIR="$TEMP_EXTRACT/openclaw-onboarding-vps-main"
    else
      EXTRACTED_DIR=$(find "$TEMP_EXTRACT" -maxdepth 1 -mindepth 1 -type d | head -1)
    fi
  fi

  if [ -z "$EXTRACTED_DIR" ] || [ ! -d "$EXTRACTED_DIR" ]; then
    echo "ERROR: Could not obtain the latest skills (git clone + zip fallback both failed)"
    rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
    exit 1
  fi

  # Backup existing skills
  if [ -d "$SKILLS_DIR" ] && [ "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
    BACKUP_DIR="$HOME/Downloads/openclaw-backups/skills-backup-$(date +%Y%m%d-%H%M%S)"
    echo "  Creating backup: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$SKILLS_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
  fi

  # Ensure skills directory exists
  mkdir -p "$SKILLS_DIR"

  # ----------------------------------------------------------
  # v10.16.47 — WIRED skill loop:
  # 1. COPY (same as before — idempotent, byte-for-byte)
  # 2. MERGE CORE_UPDATES.md into workspace files (idempotent sentinel)
  # 3. RUN per-skill shell installers (wire.sh / install-*.sh / setup-*.sh)
  # The printed activation recipe is KEPT for new skills so the agent
  # knows which skills still require INSTALL.md prose steps it must
  # execute (the script cannot run INSTALL.md — that remains agent-prose).
  # ----------------------------------------------------------
  echo "  Installing and wiring skills to $SKILLS_DIR..."
  NEW_SKILLS_CSV=""
  SKIPPED_COUNT=0
  WIRED_SKILLS_CSV=""
  for SKILL_DIR in "$EXTRACTED_DIR"/[0-9]*/; do
    [ -d "$SKILL_DIR" ] || continue
    SKILL_NAME=$(basename "$SKILL_DIR")

    # Skip archived skills
    case "$SKILL_NAME" in *ARCHIVED*) continue ;; esac

    # --only filter: if ONLY_SKILLS is set, install only matching prefixes
    if [ -n "$ONLY_SKILLS" ]; then
      SKILL_PREFIX=$(echo "$SKILL_NAME" | cut -d'-' -f1)
      MATCH="false"
      OIFS=$IFS; IFS=','
      for want in $ONLY_SKILLS; do
        want_trimmed=$(echo "$want" | tr -d '[:space:]')
        if [ "$SKILL_PREFIX" = "$want_trimmed" ]; then
          MATCH="true"
          break
        fi
      done
      IFS=$OIFS
      if [ "$MATCH" != "true" ]; then
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
      fi
    fi

    IS_NEW="false"
    # Check if this is a NEW skill (doesn't exist in current install)
    if [ ! -d "$SKILLS_DIR/$SKILL_NAME" ]; then
      IS_NEW="true"
      # Track for flag + Telegram
      if [ -z "$NEW_SKILLS_CSV" ]; then
        NEW_SKILLS_CSV="$SKILL_NAME"
      else
        NEW_SKILLS_CSV="$NEW_SKILLS_CSV, $SKILL_NAME"
      fi
      echo ""
      echo "  NEW SKILL DETECTED: $SKILL_NAME"
      echo "  ============================================"
      echo "  This skill requires ACTIVATION after install."
      echo "  Script has: copied files + merged CORE_UPDATES.md + run shell installers."
      echo "  The agent MUST ALSO do these remaining steps (script cannot run prose):"
      echo ""
      echo "  a. READ all files (Teach Yourself Protocol)"
      echo "     -> SKILL.md, INSTALL.md, CORE_UPDATES.md, QC.md"
      echo "     -> Plus any references/*.md files"
      echo ""
      echo "  b. CHECK prerequisites, search .env files"
      echo "     -> Verify API keys, credentials, software"
      echo "     -> Check /data/.openclaw/skills/ for dependencies"
      echo ""
      echo "  c. EXECUTE any INSTALL.md prose steps not covered by a shell installer"
      echo "     -> 'Teach Yourself' means READ. 'Activate' means EXECUTE."
      echo ""
      echo "  d. VERIFY CORE_UPDATES.md merge was complete (check sentinel lines)"
      echo "     -> Script merged what it could; agent verifies correctness"
      echo ""
      echo "  e. RUN QC.md checks"
      echo "     -> Verify all components work"
      echo "     -> Test API connections"
      echo ""
      echo "  f. TELL client what was set up"
      echo "     -> List activated features"
      echo "     -> Note any pending items"
      echo ""
      echo "  ============================================"
    fi

    # Remove old version if exists
    rm -rf "$SKILLS_DIR/$SKILL_NAME"

    # STEP 1: COPY
    # IMPORTANT: strip the trailing slash from SKILL_DIR before passing to cp.
    # The glob pattern [0-9]*/ always appends a trailing slash.
    # `cp -r "path/01-skill/" dest/` copies the CONTENTS of 01-skill/ flat
    # into dest/ (the dir itself is not created) — this is the root cause of
    # the "132 loose files dumped into ~/.openclaw/skills/" flatten bug.
    # `cp -r "path/01-skill" dest/` (no trailing slash) copies the dir as a
    # named subdirectory, producing dest/01-skill/ as intended.
    cp -r "${SKILL_DIR%/}" "$SKILLS_DIR/"
    echo "    Copied: $SKILL_NAME"

    # STEP 2: MERGE CORE_UPDATES.md into workspace (idempotent)
    merge_core_updates "$SKILLS_DIR/$SKILL_NAME" "$SKILL_NAME"

    # STEP 3: RUN per-skill shell installers (wire.sh / install-*.sh / setup-*.sh)
    wire_skill_shell_installers "$SKILLS_DIR/$SKILL_NAME" "$SKILL_NAME"

    # Track wired skills for summary
    if [ -z "$WIRED_SKILLS_CSV" ]; then
      WIRED_SKILLS_CSV="$SKILL_NAME"
    else
      WIRED_SKILLS_CSV="$WIRED_SKILLS_CSV, $SKILL_NAME"
    fi

    # Write per-skill wire state file (idempotent state machine)
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) wired $SKILL_NAME by update-skills.sh $ONBOARDING_VERSION" \
      >> "$SKILLS_DIR/.skill-wire-state" 2>/dev/null || true

    # v10.16.48 — FIX 1: record CORE_UPDATES-merged + installers-run as 'wired'
    # in .onboarding-state.json. NOT 'qc-passed' — registration + QC are the
    # agent's verification step (the gate), surfaced via the resume cron.
    case "$SKILL_NAME" in *ARCHIVED*) : ;; *) oc_state_set "$SKILL_NAME" wired ;; esac

    echo "    Wired: $SKILL_NAME"
  done

  # ----------------------------------------------------------
  # v10.16.49: Skills loader source — auto-discovery (no openclaw.json write).
  # skills.path was removed because 2026.5.x rejects it as an unrecognized key;
  # numbered skills auto-discover from ~/.openclaw/skills without any config entry.
  # ----------------------------------------------------------
  echo ""
  ensure_skills_loader_source "$SKILLS_DIR"

  # ----------------------------------------------------------
  # v10.16.47: Install ImageMagick via linuxbrew (required by skills
  # 25-video-creator and 28-cinematic-forge). Never via apt — on
  # Hostinger containers apt is a brew shim not on PATH.
  # ----------------------------------------------------------
  echo ""
  echo "  Checking ImageMagick (required by skills 25 + 28)..."
  install_imagemagick_vps

  # ----------------------------------------------------------
  # v10.16.47: Wire GHL MCP (skill 36) under nested mcp.servers.
  # Uses openclaw mcp set which writes the nested form per
  # MEMORY.md openclaw-mcp-schema-drift.md. Idempotent.
  # ----------------------------------------------------------
  echo ""
  echo "  Wiring GHL MCP (skill 36) under mcp.servers..."
  wire_ghl_mcp "$SKILLS_DIR"

  # ----------------------------------------------------------
  # v10.16.50: Shared-core-file unification (Zero-Human-Workforce model).
  # AFTER skills + workspaces are set up, share the box's ONE canonical
  # AGENTS.md / TOOLS.md / USER.md across every non-workflow-agent workspace
  # via symlinks. Idempotent + non-destructive (real files backed up, unique
  # content preserved into per-agent IDENTITY.md). CANON_DIR is resolved from
  # the LOCAL box's agents.defaults.workspace (co-mingling guard).
  # ----------------------------------------------------------
  echo ""
  echo "  Unifying shared core files (AGENTS/TOOLS/USER) across agent workspaces..."
  link_shared_core_files

  # ----------------------------------------------------------
  # v10.16.41: Run migrate-existing-workforce.sh so copied skills
  # actually install into the client's live department tree.
  # This script is idempotent and additive — it never deletes or
  # overwrites existing departments, only fills gaps.
  # ----------------------------------------------------------
  MIGRATE_SCRIPT="$SKILLS_DIR/23-ai-workforce-blueprint/scripts/migrate-existing-workforce.sh"
  if [ -x "$MIGRATE_SCRIPT" ]; then
    echo ""
    echo "  Running workforce migration (installs copied skills into department tree)..."
    if bash "$MIGRATE_SCRIPT" "$(hostname)" --apply >> "$LOG_FILE" 2>&1; then
      echo "  migrate-existing-workforce.sh: OK"
    else
      echo "  migrate-existing-workforce.sh: completed with warnings (see $LOG_FILE)"
    fi
  else
    echo "  (migrate-existing-workforce.sh not found or not executable — skipping)"
  fi

  # Write version file to active dir (the canonical location)
  echo "$ONBOARDING_VERSION" > "$SKILLS_DIR/.onboarding-version"

  # Sync version marker to legacy locations if they exist, so get_current_version
  # always reads the same value regardless of which path it finds first.
  # This prevents the stale-legacy-marker false-positive on re-runs (Bug B).
  for _LEGACY_MARKER in \
      "$HOME/Downloads/openclaw-master-files/.onboarding-version" \
      "$HOME/.openclaw/onboarding/.onboarding-version"; do
    if [ -f "$_LEGACY_MARKER" ]; then
      echo "$ONBOARDING_VERSION" > "$_LEGACY_MARKER" 2>/dev/null || true
    fi
  done

  # ----------------------------------------------------------
  # VERIFICATION: confirm the active dir was actually updated.
  # If SKILLS_DIR's .onboarding-version does not match what we
  # just wrote, something redirected writes away from the active
  # dir — fail loudly instead of reporting false success.
  # ----------------------------------------------------------
  VERIFY_VER=$(cat "$SKILLS_DIR/.onboarding-version" 2>/dev/null | tr -d '[:space:]')
  if [ "$VERIFY_VER" != "$ONBOARDING_VERSION" ]; then
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "  FAILURE: active skills dir was NOT updated!"
    echo "  Expected version : $ONBOARDING_VERSION"
    echo "  Found version    : ${VERIFY_VER:-<missing>}"
    echo "  Active dir       : $SKILLS_DIR"
    echo "  The running agent is still on the OLD skills."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
    exit 1
  fi
  VERIFY_SKILL_COUNT=$(ls -d "$SKILLS_DIR"/[0-9]*/ 2>/dev/null | wc -l | tr -d ' ')
  if [ "$VERIFY_SKILL_COUNT" -eq 0 ]; then
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "  FAILURE: no skill folders found in active dir after update!"
    echo "  Active dir : $SKILLS_DIR"
    echo "  The running agent is still on the OLD skills."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
    exit 1
  fi

  # Cleanup
  rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"

  # v10.16.48 — FIX 1 (ONBOARDING HONESTY): re-seed the state file so every
  # newly-pulled skill is tracked, then report HONESTLY. "Skills pulled +
  # wired" is true (files copied, CORE_UPDATES merged, installers run). But
  # "verified-installed" is the verification gate (registration + sentinel +
  # qc-*.sh exit 0), which is the agent's step — so the banner does NOT claim
  # "updated successfully" as a completion; it reports the gate state.
  oc_state_seed "$SKILLS_DIR" "$ONBOARDING_VERSION"
  oc_state_summary

  echo ""
  echo "============================================"
  echo "   Skills pulled + wired (CORE_UPDATES merged, installers run)"
  echo "   Version: $ONBOARDING_VERSION"
  echo "   Location: $SKILLS_DIR"
  echo "   On disk: $VERIFY_SKILL_COUNT skill folders confirmed in active dir"
  echo "   Verified-installed (gate passed): ${OC_VERIFIED:-0}/${OC_TOTAL:-0}"
  if [ -n "${OC_FAILED_LIST:-}" ]; then
    echo "   ⚠ qc-failed (need re-run): ${OC_FAILED_LIST}"
  fi
  if [ -n "${OC_PENDING_LIST:-}" ]; then
    echo "   ⏳ awaiting agent verify (pending/wired): ${OC_PENDING_LIST}"
  fi
  echo "   (A skill is 'installed' only when registered + CORE_UPDATES sentinel + qc-*.sh exit 0.)"
  if [ -n "$ONLY_SKILLS" ]; then
    echo "   Mode: SELECTIVE — only [$ONLY_SKILLS]"
    echo "   Skipped: $SKIPPED_COUNT other skills (not in --only list)"
  fi
  echo "============================================"

  # Mark the check timestamp so the catchup logic in future runs is accurate
  date -u +%Y-%m-%dT%H:%M:%SZ > "$SKILLS_DIR/.last-update-check" 2>/dev/null || true

  # ----------------------------------------------------------
  # v10.14.32: Backfill yt-dlp + whisper-cpp + ffmpeg for Skill 22
  # ----------------------------------------------------------
  # Existing clients running update-skills.sh need these tools the same as
  # fresh installs — install.sh's install_media_tools won't fire on update.
  # Mirror the same path priority (Linuxbrew → apt → pip).
  echo ""
  echo "  Checking Skill 22 media tools (yt-dlp + whisper-cpp + ffmpeg)..."
  UPD_LBREW="/data/linuxbrew/.linuxbrew/bin/brew"
  UPD_MEDIA_MISSING=""
  for tool in yt-dlp whisper-cpp ffmpeg; do
      if ! command -v "$tool" >/dev/null 2>&1 \
         && [ ! -x "/data/linuxbrew/.linuxbrew/bin/$tool" ]; then
          UPD_MEDIA_MISSING="$UPD_MEDIA_MISSING $tool"
      fi
  done
  if [ -n "$UPD_MEDIA_MISSING" ]; then
      echo "    Missing:$UPD_MEDIA_MISSING — attempting install..."
      if [ -x "$UPD_LBREW" ]; then
          for tool in $UPD_MEDIA_MISSING; do
              "$UPD_LBREW" install "$tool" >> "$LOG_FILE" 2>&1 \
                  && echo "    ✓ brew install $tool" \
                  || echo "    ⚠ brew install $tool failed (see $LOG_FILE)"
          done
      fi
      # pip fallback for yt-dlp + whisper (only if still missing)
      if ! command -v yt-dlp >/dev/null 2>&1 && [ ! -x "/data/linuxbrew/.linuxbrew/bin/yt-dlp" ]; then
          pip3 install --user yt-dlp --break-system-packages >> "$LOG_FILE" 2>&1 \
              || pip3 install --user yt-dlp >> "$LOG_FILE" 2>&1 || true
      fi
      if ! command -v whisper-cpp >/dev/null 2>&1 && ! command -v whisper >/dev/null 2>&1 \
         && [ ! -x "/data/linuxbrew/.linuxbrew/bin/whisper-cpp" ]; then
          pip3 install --user openai-whisper --break-system-packages >> "$LOG_FILE" 2>&1 \
              || pip3 install --user openai-whisper >> "$LOG_FILE" 2>&1 || true
      fi
  else
      echo "    ✓ All media tools already installed"
  fi

  # ----------------------------------------------------------
  # Ensure the Sunday weekly update-check cron exists (idempotent)
  # Existing clients on pre-v9.2.0 won't have it; running the updater
  # backfills it.
  # ----------------------------------------------------------
  if command -v openclaw >/dev/null 2>&1; then
    if openclaw cron list 2>/dev/null | grep -qi "weekly-onboarding-update"; then
      echo "  ✓ Sunday weekly update-check cron already installed"
    else
      OCJSON="$HOME/.openclaw/openclaw.json"
      [ -d "/data/.openclaw" ] && OCJSON="/data/.openclaw/openclaw.json"
      TG_TARGET=""
      if [ -f "$OCJSON" ]; then
        TG_TARGET=$(python3 -c "
import json
try:
    cfg=json.load(open('$OCJSON'))
    allow=cfg.get('channels',{}).get('telegram',{}).get('allowFrom',[])
    if allow: print(allow[0])
except: pass
" 2>/dev/null)
      fi
      if [ -n "$TG_TARGET" ]; then
        PROMPT_TMP="/tmp/openclaw-cron-prompt-$$.txt"
        REPO_URL="https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main"
        [ -d "/data/.openclaw" ] && REPO_URL="https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main"
        if curl -fsSL --max-time 15 "${REPO_URL}/cron-prompt.txt" -o "$PROMPT_TMP" 2>/dev/null && [ -s "$PROMPT_TMP" ]; then
          PROMPT_CONTENT=$(cat "$PROMPT_TMP")
          if openclaw cron create \
              --name "weekly-onboarding-update" \
              --description "Sunday 2am ET — check for OpenClaw onboarding + command-center updates and ask client permission before applying anything." \
              --cron "0 3 * * 0" \
              --tz "America/New_York" \
              --exact \
              --session isolated \
              --announce \
              --channel telegram \
              --to "$TG_TARGET" \
              --thinking high \
              --timeout-seconds 7200 \
              --message "$PROMPT_CONTENT" >/dev/null 2>&1; then
            echo "  ✓ Sunday weekly update-check cron installed (Sundays 2am ET → telegram $TG_TARGET)"
          else
            echo "  ⚠ Cron install failed — agent can retry manually"
          fi
          rm -f "$PROMPT_TMP"
        else
          echo "  ⚠ Could not fetch cron-prompt.txt — agent can install cron manually later"
        fi
      else
        echo "  ⚠ No telegram target configured — skipping cron install. Configure Telegram first then re-run."
      fi
    fi
  fi

  # ----------------------------------------------------------
  # Fleet standards: ensure sub-agents fully permitted + Telegram media 50MB
  # (idempotent — applied on every update, no-op if already canonical)
  # v10.16.47 fix: ONBOARDING_DIR is not defined in update-skills.sh;
  # use SKILLS_DIR (the installed skills root) which contains scripts/.
  # ----------------------------------------------------------
  echo ""
  echo "  Applying fleet standards (sub-agents fully permitted, Telegram media 50MB)..."
  FLEET_STANDARDS_SCRIPT="$SKILLS_DIR/scripts/apply-fleet-standards.sh"
  # Also check the skills root one level up (where scripts/ lives in the repo)
  [ -f "$FLEET_STANDARDS_SCRIPT" ] || FLEET_STANDARDS_SCRIPT="$(dirname "$SKILLS_DIR")/scripts/apply-fleet-standards.sh"
  if [ -f "$FLEET_STANDARDS_SCRIPT" ]; then
    bash "$FLEET_STANDARDS_SCRIPT" >/dev/null 2>&1 && echo "  Fleet standards applied" || echo "  Fleet standards application reported errors (update continues)"
  else
    echo "  Fleet standards script not found at $FLEET_STANDARDS_SCRIPT — skipping"
  fi

  # ----------------------------------------------------------
  # v10.16.4: Post-pull qc-completeness check. Read-only. Runs against the live
  # workforce after every successful skill pull. The script self-Telegrams the
  # operator on != PASS, so we just append the human-readable STATUS line to
  # the existing "update complete" Telegram for visibility.
  # ----------------------------------------------------------
  QC_COMPLETENESS_SCRIPT="$SKILLS_DIR/23-ai-workforce-blueprint/scripts/qc-completeness.sh"
  QC_STATUS_LINE=""
  QC_COMPLETENESS_RC=0
  if [ -x "$QC_COMPLETENESS_SCRIPT" ]; then
    echo ""
    echo "  Running qc-completeness.sh against live workforce..."
    # v10.16.48 — FIX 1: HONOR the exit code (it was discarded with `|| true`).
    QC_OUTPUT="$(bash "$QC_COMPLETENESS_SCRIPT" 2>&1)" || QC_COMPLETENESS_RC=$?
    QC_STATUS_LINE="$(printf '%s\n' "$QC_OUTPUT" | grep -E '^STATUS:' | tail -1)"
    echo "  ${QC_STATUS_LINE:-qc-completeness ran (no STATUS line captured)} (exit=$QC_COMPLETENESS_RC)"
    if [ "$QC_COMPLETENESS_RC" -ne 0 ]; then
      echo "  ⚠ qc-completeness reported a NON-PASS state (exit $QC_COMPLETENESS_RC) — the workforce is NOT fully built; this is reflected in the report below (not hidden)."
    fi
  fi

  # ----------------------------------------------------------
  # Post-update: write UPDATE PENDING flag + Telegram + backup block
  # ----------------------------------------------------------
  echo ""
  echo "  Writing UPDATE PENDING flag for agent activation..."
  write_update_pending_flag "$ONBOARDING_VERSION" "$NEW_SKILLS_CSV"

  # v10.16.48 — FIX 1 (HONEST REPORTING CONTRACT): the completion headline is
  # CONDITIONAL on the verification gate AND the qc-completeness exit code. We do
  # NOT lead with "✅ complete" unless every tracked skill is verified-installed
  # (or interview-pending) and qc-completeness passed. Otherwise we report the
  # truth: how many are verified, which still need work.
  oc_state_summary
  UPDATE_HEADLINE=""
  UPDATE_VERIFY_LINE=""
  if oc_onboarding_complete && [ "${QC_COMPLETENESS_RC:-0}" -eq 0 ]; then
    UPDATE_HEADLINE="✅ OpenClaw skill update ${ONBOARDING_VERSION}: verified complete."
    UPDATE_VERIFY_LINE="Verified-installed: ${OC_VERIFIED:-0}/${OC_TOTAL:-0} skills (gate passed).${OC_INTERVIEW_LIST:+ Awaiting your interview: ${OC_INTERVIEW_LIST}.}"
  else
    UPDATE_HEADLINE="🛠 OpenClaw skill update ${ONBOARDING_VERSION}: files pulled + wired — verification still in progress (NOT complete)."
    UPDATE_VERIFY_LINE="Verified-installed: ${OC_VERIFIED:-0}/${OC_TOTAL:-0}. Still need install/wire/QC: ${OC_FAILED_LIST:-}${OC_FAILED_LIST:+, }${OC_PENDING_LIST:-none}.${OC_INTERVIEW_LIST:+ Awaiting your interview: ${OC_INTERVIEW_LIST}.}"
  fi

  echo "  Sending Telegram notification..."
  send_telegram_progress "${UPDATE_HEADLINE}

New skills (need activation): ${NEW_SKILLS_CSV:-none — updates only}.
Skills pulled + wired (CORE_UPDATES merged + shell installers run): all pulled skills.
GHL MCP (skill 36): registered under mcp.servers + local server started.
ImageMagick: checked/installed.
Skills loader-source: auto-discovered (no openclaw.json write — 2026.5.x).

${UPDATE_VERIFY_LINE}
Workforce QC: ${QC_STATUS_LINE:-not run} (exit ${QC_COMPLETENESS_RC:-0}).

A skill counts INSTALLED only when registered + CORE_UPDATES sentinel present + qc-*.sh exit 0. Paste this to your agent:

▶ \"I just ran update-skills.sh. There is an UPDATE PENDING flag at the top of my AGENTS.md. CORE_UPDATES.md has been merged and shell installers have run. Install + wire + QC any skill still pending in /data/.openclaw/.onboarding-state.json. Mark each qc-passed ONLY when the gate holds. Report N/M verified-installed — never say done for un-verified skills. Send me a summary when the verification gate passes.\"

(If you didn't get THIS Telegram note, the same instructions are also printed in your Terminal.)"

  case "$TELEGRAM_LAST_RESULT" in
    sent:*)              echo "  ✓ Telegram sent to ${TELEGRAM_LAST_RESULT#sent:}" ;;
    no-openclaw-cli)     echo "  ⚠ Telegram skipped — openclaw CLI not on PATH" ;;
    no-telegram-target)  echo "  ⚠ Telegram skipped — no telegram.allowFrom configured in openclaw.json" ;;
    failed:*)            echo "  ⚠ Telegram FAILED — see $LOG_FILE (using backup block below)" ;;
  esac

  # Always print the backup block so client is never stranded
  cat <<'BACKUP_BLOCK'

╔════════════════════════════════════════════════════════════════════╗
║   BACKUP — IF YOU DID NOT GET A TELEGRAM NOTE                      ║
╠════════════════════════════════════════════════════════════════════╣
║                                                                    ║
║   Open whatever you use to talk to your OpenClaw agent (Telegram,  ║
║   web UI, terminal chat — whatever you have set up).               ║
║                                                                    ║
║   Paste this EXACT message to your agent (copy between the         ║
║   >>> and <<< markers):                                            ║
║                                                                    ║
║   >>>                                                              ║
║   I just ran update-skills.sh. There is an UPDATE PENDING flag     ║
║   at the top of my AGENTS.md describing what changed. Please       ║
║   follow the activation steps for any new skills listed in the     ║
║   flag. Run QC after each one. Send me a summary when complete.    ║
║   <<<                                                              ║
║                                                                    ║
║   Your agent will read the flag and walk through the activation    ║
║   for you. You don't need to type any other commands.              ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝

BACKUP_BLOCK
}

main "$@"
