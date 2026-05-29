#!/usr/bin/env bash
# qc-reference-sheet.sh — machine-enforce that the generated CLIENT REFERENCE
# SHEET always carries the two copy-paste artifacts a client cannot proceed
# without:
#
#   1. The Authorization header / BEARER TOKEN — a real, copy-paste-ready
#      `Authorization: Bearer <token>` (the literal word "Bearer" must appear).
#   2. The GHL Custom Webhook RAW BODY as a real ```json fenced code block
#      (copyable), plus the hook URL (`https://<host>/hooks/<id>`).
#
# ROOT CAUSE this gate kills: on a live client (Teresa) the generated reference
# sheet had NO bearer token and NO copyable ```json Raw Body. The client opened
# their reference doc, the token was missing, and there was no JSON to copy into
# GHL's Build-with-AI. That stranded the client. The reference sheet MUST contain
# both, ALWAYS — this is enforced, not optional.
#
# HOW IT CHECKS (two modes):
#   * --sheet <path>  → static-check an already-generated reference sheet file.
#   * (default)       → drive 21-generate-client-reference-sheet.sh in a sandbox
#                       (no `openclaw` on PATH, dummy env → Layer-3 markdown
#                       fallback, no network), then check the markdown it writes.
#     The default mode is what CI runs: it proves the GENERATOR emits both
#     artifacts, so a template/script regression that drops them fails the build.
#
# REQUIRED MARKERS (all must be present in the checked sheet):
#   - a literal "🚀 Quick Start" section (the sheet LEADS with the copy-paste items)
#   - a "Reference & explanation" section AFTER the Quick Start (Quick Start is NOT
#     an excuse to drop the explanation — both are required, in that order)
#   - the word "Bearer"
#   - SEPARATE Authorization header code blocks: one fenced block containing exactly
#     "Authorization" (the key) AND one fenced block whose content starts "Bearer "
#     (the value). They must NEVER be combined into a single "Authorization: Bearer"
#     block — 50+ clients copy each field individually, so each needs its own copy box.
#   - SEPARATE Content-Type header code blocks: one fenced block containing exactly
#     "Content-Type" AND one fenced block containing exactly "application/json".
#   - at least one ```json fenced code block (opening fence, line-anchored)
#   - a hook URL of the form https://.../hooks/<id>
#   - the manual Custom-Webhook fill instructions: "Custom Webhook" + (manually|paste)
#     + "Build with AI will not" (Build-with-AI only builds the SHAPE; the client
#     MUST manually fill the URL/headers/body — a sheet without this strands them)
#   - the create-tag-FIRST instruction pointing at "Settings -> Tags" (a tag used in
#     a filter/Add-Tag action must EXIST before the workflow is built)
#   - the POST-BUILD VERIFICATION section ("After Build with AI runs"/"VERIFY") that
#     covers the TRIGGER, the CUSTOM WEBHOOK, and PUBLISH (the Teresa gotcha: a blank/
#     non-existent tag in a "does not contain" filter)
#
# Exit codes: 0 = sheet carries all required markers;
#             1 = one or more markers missing;
#             2 = could not produce/locate a reference sheet to check (the
#                 generator failed or the scan target moved — treated as FAILURE,
#                 never a blind PASS).
#
# Usage:
#   bash scripts/qc-reference-sheet.sh                 # generate + check (CI)
#   bash scripts/qc-reference-sheet.sh --json          # machine output
#   bash scripts/qc-reference-sheet.sh --sheet FILE    # check an existing sheet
#   bash scripts/qc-reference-sheet.sh --skill-dir DIR # point at a skill root

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
JSON_MODE=0
SHEET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --skill-dir) SKILL_DIR="$2"; shift 2 ;;
    --sheet)     SHEET="$2"; shift 2 ;;
    --json)      JSON_MODE=1; shift ;;
    -h|--help)   sed -n '1,52p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

GEN_SCRIPT="$SKILL_DIR/scripts/21-generate-client-reference-sheet.sh"

# ---------------------------------------------------------------------------
# If no --sheet was passed, generate one in a sandbox and check that output.
# We strip `openclaw` from PATH so the generator takes the Layer-3 markdown
# fallback (no network, no Telegram sends) and writes a plain .md we can read.
# ---------------------------------------------------------------------------
TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT

GEN_LOG=""
if [ -z "$SHEET" ]; then
  if [ ! -f "$GEN_SCRIPT" ]; then
    if [ "$JSON_MODE" = "1" ]; then
      printf '{"verdict":"NO_SHEET","reason":"generator not found: %s"}\n' "$GEN_SCRIPT"
    else
      echo "RESULT: NO SHEET — generator not found ($GEN_SCRIPT). Treating as FAIL."
    fi
    exit 2
  fi

  TMP="$(mktemp -d)"
  MASTER_FILES_DIR="$TMP/master-files"
  mkdir -p "$MASTER_FILES_DIR"

  # Sandbox PATH without `openclaw` so the generator stays offline (Layer 3).
  SANDBOX_PATH=""
  IFS=':' read -ra _parts <<< "$PATH"
  for p in "${_parts[@]}"; do
    [ -x "$p/openclaw" ] && continue
    if [ -z "$SANDBOX_PATH" ]; then SANDBOX_PATH="$p"; else SANDBOX_PATH="$SANDBOX_PATH:$p"; fi
  done
  [ -n "$SANDBOX_PATH" ] || SANDBOX_PATH="$PATH"

  GEN_LOG="$TMP/gen.log"
  set +e
  env -i \
    HOME="$TMP" \
    PATH="$SANDBOX_PATH" \
    MASTER_FILES_DIR="$MASTER_FILES_DIR" \
    PUBLIC_HOSTNAME="claw.qc-reference-sheet.example.com" \
    ROUTE_ID="QCREF" \
    HOOK_NAME="QCREF" \
    AGENT_ID="main" \
    ROUTING_AGENT_ID="main" \
    HOOKS_TOKEN="hooks_qc_reference_sheet_dummy_token" \
    CLIENT_BUSINESS_NAME="QC Reference Sheet Test Co" \
    CLIENT_TELEGRAM_CHAT_ID="0" \
    SKILL38_TEMPLATES_DIR="$SKILL_DIR/templates" \
    bash "$GEN_SCRIPT" >"$GEN_LOG" 2>&1
  GEN_RC=$?
  set -e 2>/dev/null || true

  # The Layer-3 fallback writes 01-client-reference-sheet.md under
  # <MASTER_FILES_DIR>/conversation-workflows/. Locate the rendered sheet.
  SHEET="$MASTER_FILES_DIR/conversation-workflows/01-client-reference-sheet.md"
  if [ ! -f "$SHEET" ]; then
    # Fallback: any reference-sheet markdown the generator staged.
    SHEET="$(find "$MASTER_FILES_DIR" -name '*reference-sheet*.md' -o -name '01-client-reference-sheet.md' 2>/dev/null | head -n1)"
  fi

  if [ -z "$SHEET" ] || [ ! -f "$SHEET" ]; then
    if [ "$JSON_MODE" = "1" ]; then
      printf '{"verdict":"NO_SHEET","generator_rc":%s,"reason":"generator produced no reference sheet"}\n' "$GEN_RC"
    else
      echo "=== qc-reference-sheet: generator output check ==="
      echo "generator rc: $GEN_RC"
      echo "generator log:"; sed 's/^/    /' "$GEN_LOG" 2>/dev/null || true
      echo "RESULT: NO SHEET — the generator produced no reference sheet to check. Treating as FAIL."
    fi
    exit 2
  fi
fi

if [ ! -f "$SHEET" ]; then
  if [ "$JSON_MODE" = "1" ]; then
    printf '{"verdict":"NO_SHEET","reason":"sheet not found: %s"}\n' "$SHEET"
  else
    echo "RESULT: NO SHEET — file not found ($SHEET). Treating as FAIL."
  fi
  exit 2
fi

# ---------------------------------------------------------------------------
# Marker checks (line-anchored for the ```json fence so a stray inline mention
# of "```json" in prose does not satisfy it).
# ---------------------------------------------------------------------------
MISSING=()

# --- Quick Start FIRST, then a full explanation AFTER it (both required) ---
# The sheet must LEAD with a literal "🚀 Quick Start" section and STILL carry a
# "Reference & explanation" section after it (Quick Start does not replace the
# explanation). Enforce both presence AND order.
grep -q '🚀 Quick Start' "$SHEET" || \
  MISSING+=('a literal "🚀 Quick Start" section leading the sheet')
grep -Eiq '^#{1,3}[[:space:]]+Reference (&|and) explanation' "$SHEET" || \
  MISSING+=('a "Reference & explanation" section (the full explanation, kept AFTER Quick Start)')
# Order: the Quick Start heading must appear BEFORE the Reference & explanation heading.
QS_LINE="$(grep -n '🚀 Quick Start' "$SHEET" | head -n1 | cut -d: -f1)"
REF_LINE="$(grep -Ein '^#{1,3}[[:space:]]+Reference (&|and) explanation' "$SHEET" | head -n1 | cut -d: -f1)"
if [ -n "$QS_LINE" ] && [ -n "$REF_LINE" ] && [ "$QS_LINE" -ge "$REF_LINE" ]; then
  MISSING+=('the "🚀 Quick Start" section must come BEFORE "Reference & explanation"')
fi

grep -q "Bearer" "$SHEET" || MISSING+=('the word "Bearer" (Authorization: Bearer <token>)')

# --- SEPARATE header code blocks (one copy box per copyable value) ---
# Extract the trimmed content of every fenced code block and check that the
# header KEY and VALUE each live in their OWN block, never combined. A single
# block containing "Authorization: Bearer ..." fails this — clients copy each
# field individually, so each needs its own copy button.
#   awk emits one line per code block: the block body with internal newlines
#   replaced by a single space, then leading/trailing space trimmed.
CODEBLOCKS="$(awk '
  /^[[:space:]]*```/ { infence = !infence; if (infence) { buf=""; first=1 } else { print buf } ; next }
  infence { if (first) { buf=$0; first=0 } else { buf = buf " " $0 } }
' "$SHEET")"

# A block that is EXACTLY the header key "Authorization" (own copy box).
printf '%s\n' "$CODEBLOCKS" | grep -Eq '^[[:space:]]*Authorization[[:space:]]*$' || \
  MISSING+=('a code block containing ONLY "Authorization" (the header key in its own copy box)')
# A block whose value STARTS with "Bearer " (the header value, own copy box) and
# is NOT combined with the "Authorization:" key.
printf '%s\n' "$CODEBLOCKS" | grep -Eq '^[[:space:]]*Bearer[[:space:]]+[^[:space:]]' || \
  MISSING+=('a code block containing ONLY the "Bearer <token>" header value (own copy box)')
# The key and value must NEVER be combined in one block.
if printf '%s\n' "$CODEBLOCKS" | grep -Eq '^[[:space:]]*Authorization:[[:space:]]*Bearer'; then
  MISSING+=('the Authorization key and "Bearer <token>" value must be in SEPARATE code blocks, never combined as "Authorization: Bearer ..."')
fi
# Content-Type key + value, each its own copy box.
printf '%s\n' "$CODEBLOCKS" | grep -Eq '^[[:space:]]*Content-Type[[:space:]]*$' || \
  MISSING+=('a code block containing ONLY "Content-Type" (the header key in its own copy box)')
printf '%s\n' "$CODEBLOCKS" | grep -Eq '^[[:space:]]*application/json[[:space:]]*$' || \
  MISSING+=('a code block containing ONLY "application/json" (the Content-Type value in its own copy box)')

# A real opening ```json fence on its own line (optional leading whitespace).
grep -Eq '^[[:space:]]*```json[[:space:]]*$' "$SHEET" || \
  MISSING+=('a ```json fenced code block (copyable GHL Raw Body)')

# A hook URL of the form https://.../hooks/<id>
grep -Eq 'https://[^[:space:]]+/hooks/[A-Za-z0-9._-]+' "$SHEET" || \
  MISSING+=('a hook URL (https://<host>/hooks/<id>)')

# The MANUAL Custom-Webhook fill instructions — "Build with AI" only builds the
# SHAPE; the client MUST manually fill the URL/headers/body. Require all three
# signal phrases so the sheet can never ship without the "do it yourself" steps:
#   - "Custom Webhook" (names the action to fill)
#   - "manually" OR "paste" (the action the client must take)
#   - "Build with AI will not" (the explicit "it won't fill it for you" warning)
grep -q "Custom Webhook" "$SHEET" || \
  MISSING+=('the manual-fill instructions must name the "Custom Webhook" action')
grep -Eiq 'manually|paste' "$SHEET" || \
  MISSING+=('the manual-fill instructions must tell the client to manually enter / paste the values')
grep -Eiq 'Build with AI will not' "$SHEET" || \
  MISSING+=('the manual-fill instructions must state "Build with AI will not" fill these for you')

# --- CREATE-TAG-FIRST + where to check (Settings -> Tags) ---
# A tag used in a filter/Add-Tag action must EXIST before the workflow is built.
# Require both the "create first" instruction AND the "Settings -> Tags" location.
grep -Eiq 'create (it|the tag|them) first|tag(s)? .*(first|before you build)|create-tag-first' "$SHEET" || \
  MISSING+=('the create-tag-FIRST instruction (a tag must exist before the workflow is built)')
grep -Eiq 'Settings[[:space:]]*-+>[[:space:]]*Tags|Settings[[:space:]]*→[[:space:]]*Tags' "$SHEET" || \
  MISSING+=('where to check tags: "Settings -> Tags"')

# --- POST-BUILD VERIFICATION (the Teresa gotcha) ---
# After Build-with-AI runs the client MUST verify TRIGGER + CUSTOM WEBHOOK +
# PUBLISH. Require the verification section header and all three covered items,
# plus the blank/non-existent-tag-in-a-filter known bug.
grep -Eiq 'After Build with AI runs|VERIFY before you publish|post-build verif' "$SHEET" || \
  MISSING+=('a post-build verification section ("After Build with AI runs — VERIFY before you publish")')
grep -Eiq 'TRIGGER' "$SHEET" || \
  MISSING+=('the post-build verification must cover the TRIGGER')
grep -Eiq 'PUBLISH' "$SHEET" || \
  MISSING+=('the post-build verification must cover PUBLISH (Published, not Draft)')
grep -Eiq 'does not contain|blank|never created|non-existent tag' "$SHEET" || \
  MISSING+=('the post-build verification must call out the blank/non-existent tag-in-a-filter bug')

# --- YOUR COMMUNICATION PLAYBOOKS section (after Quick Start, before deep how-it-works) ---
# The first question every client asks on their first test: "where are my
# workflows / communication playbooks?" — answered prominently, with WHERE they
# live AND how to ask for a NEW one.
grep -Eiq 'Communication Playbooks' "$SHEET" || \
  MISSING+=('a "Your Communication Playbooks" section (where the client'"'"'s playbooks live)')
grep -Eiq 'Want a NEW communications playbook' "$SHEET" || \
  MISSING+=('the prominent "Want a NEW communications playbook? Start here:" call to action')
# WHERE they live: master-files conversation-workflows/ + Notion (human-facing).
grep -Eiq 'conversation-workflows' "$SHEET" || \
  MISSING+=('the playbooks-location must name the master-files "conversation-workflows/" folder')
grep -Eiq 'Notion' "$SHEET" || \
  MISSING+=('the playbooks-location must name where the human-facing copies live (Notion)')
# The "tell your AI ..." instruction + all 3 parts it builds.
grep -Eiq 'help me build a' "$SHEET" || \
  MISSING+=('the "just tell your AI: help me build a [purpose] playbook" instruction')
grep -Eiq 'all 3 parts|all three parts|3 parts' "$SHEET" || \
  MISSING+=('the section must say the AI builds all 3 parts (workflow-AI prompt + conversation playbook + GHL automation)')

if [ "$JSON_MODE" = "1" ]; then
  miss_json="["
  first=1
  for m in "${MISSING[@]:-}"; do
    [ -z "$m" ] && continue
    esc="${m//\"/\\\"}"
    if [ "$first" = "1" ]; then miss_json="$miss_json\"$esc\""; first=0
    else miss_json="$miss_json,\"$esc\""; fi
  done
  miss_json="$miss_json]"
  if [ "${#MISSING[@]}" -eq 0 ]; then
    printf '{"sheet":"%s","verdict":"PASS","missing":%s}\n' "$SHEET" "$miss_json"
  else
    printf '{"sheet":"%s","verdict":"FAIL","missing":%s}\n' "$SHEET" "$miss_json"
  fi
else
  echo "=== qc-reference-sheet: client reference sheet copy-paste-artifact gate ==="
  echo "sheet : $SHEET"
  echo ""
  if [ "${#MISSING[@]}" -eq 0 ]; then
    echo "  [PASS] 🚀 Quick Start section leads the sheet, Reference & explanation follows"
    echo "  [PASS] Bearer token present"
    echo "  [PASS] separate Authorization key + Bearer value code blocks (own copy boxes)"
    echo "  [PASS] separate Content-Type key + application/json value code blocks"
    echo "  [PASS] copyable \`\`\`json Raw Body present"
    echo "  [PASS] hook URL present"
    echo "  [PASS] manual Custom-Webhook fill instructions present"
    echo "  [PASS] create-tag-FIRST + Settings -> Tags present"
    echo "  [PASS] post-build verification (Trigger/Custom Webhook/Publish + blank-tag bug) present"
    echo ""
    echo "RESULT: PASS — the reference sheet leads with 🚀 Quick Start (separate copy boxes per field), carries the bearer token + copyable JSON Raw Body + hook URL + manual-fill steps + create-tag-first + post-build verification, and keeps the full explanation after."
  else
    grep -q "Bearer" "$SHEET" && echo "  [PASS] Bearer token present" || echo "  [FAIL] bearer token MISSING"
    grep -Eq '^[[:space:]]*```json[[:space:]]*$' "$SHEET" && echo "  [PASS] copyable \`\`\`json Raw Body present" || echo "  [FAIL] copyable \`\`\`json Raw Body MISSING"
    grep -Eq 'https://[^[:space:]]+/hooks/[A-Za-z0-9._-]+' "$SHEET" && echo "  [PASS] hook URL present" || echo "  [FAIL] hook URL MISSING"
    echo ""
    echo "RESULT: FAIL — the reference sheet is missing required copy-paste artifact(s):"
    for m in "${MISSING[@]}"; do echo "          - $m"; done
  fi
fi

[ "${#MISSING[@]}" -eq 0 ]
