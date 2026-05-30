#!/usr/bin/env bash
# qc-no-personal-data.sh — UNIVERSAL-SKILL guard: FAIL if any personal / client
# identifier appears anywhere in Skill 38 OR in the doc it generates.
#
# WHY THIS EXISTS
# ---------------
# Skill 38 is a UNIVERSAL skill — it installs the SAME conversational-AI brain for
# any client. The templates and the source playbook were originally authored using
# a specific operator + a specific client as the worked example, so real names and
# client data leaked into the generated client Notion docs (a client opened "their"
# doc and saw someone else's name). That is unacceptable. This gate makes "no real
# names or client data anywhere" machine-enforced: it FAILS if any forbidden
# identifier appears in (1) the skill's own tree, or (2) the doc the generator emits.
#
# WHAT IT SCANS
#   (1) The whole 38-conversational-ai-system/ tree (*.md + *.sh), EXCLUDING this
#       gate itself (its forbidden-identifier list is defined here on purpose).
#   (2) The GENERATED client reference sheet — it drives
#       21-generate-client-reference-sheet.sh in an offline sandbox (no `openclaw`
#       on PATH → Layer-3 markdown) and scans the markdown it writes, so a future
#       template/script regression that reintroduces a name fails the build.
#
# FORBIDDEN IDENTIFIERS (case-insensitive whole-token where sensible):
#   people:   Trevor, Teresa, Keez, Christy, Candace, Angeleen, Beverly, Evelyn,
#             Monique, Lyric, Kofi, Pelham
#   clients/  Grants Boutique, Explore Growth, thewinningformulacourse,
#   brands:   growthriveprosper, blackceo, zerohumanworkforce, marico
#   contacts: trevelynotts (a real personal email local-part), 5252140759 (a real
#             personal Telegram id)
#   NOTE: "Maria"/"Corey" are common first names; they are matched as standalone
#   words to catch the specific client refs that leaked, without false-flagging
#   unrelated prose. If a legitimate future use needs one of these tokens, add a
#   narrow, commented allow-exception here — do NOT weaken the whole gate.
#
# Exit codes: 0 = clean (no identifier anywhere); 1 = a forbidden identifier was
#             found (the skill or its output leaks personal/client data).
#
# PURE BASH (grep/sed), no python — respects qc-static.yml's .py claude-/anthropic
# scan. bash -n clean. set -uo pipefail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SELF="$SCRIPT_DIR/qc-no-personal-data.sh"
JSON_MODE=0
EXTRA_SHEET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json)        JSON_MODE=1; shift ;;
    --skill-dir)   SKILL_DIR="$2"; shift 2 ;;
    --sheet)       EXTRA_SHEET="$2"; shift 2 ;;   # also scan an explicit sheet
    -h|--help)     sed -n '1,52p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Forbidden identifiers. Word-boundary tokens for common-ish names; substring for
# the obviously-unique brands/handles/ids.
PATTERNS=(
  '\bTrevor\b' '\bTeresa\b' '\bKeez\b' '\bChristy\b' '\bCandace\b'
  '\bAngeleen\b' '\bBeverly\b' '\bEvelyn\b' '\bMonique\b' '\bLyric\b'
  '\bKofi\b' '\bPelham\b' '\bCorey\b' '\bMaria\b'
  'Grants Boutique' 'Explore Growth' 'thewinningformulacourse'
  'growthriveprosper' 'blackceo' 'zerohumanworkforce' 'marico'
  'trevelynotts' '5252140759'
)

FAIL=0
HITS=()

scan_file() {
  local f="$1"
  # never scan this gate (it intentionally lists the identifiers)
  [ "$(cd "$(dirname "$f")" && pwd)/$(basename "$f")" = "$SELF" ] && return 0
  local pat
  for pat in "${PATTERNS[@]}"; do
    if grep -nEi -- "$pat" "$f" >/dev/null 2>&1; then
      while IFS= read -r line; do
        HITS+=("$f: $line")
      done < <(grep -nEi -- "$pat" "$f" 2>/dev/null | sed 's/[[:space:]]\{1,\}/ /g' | cut -c1-160)
      FAIL=1
    fi
  done
}

echo "=== qc-no-personal-data: universal-skill identifier guard ==="

# (1) Scan the whole tree (*.md + *.sh).
while IFS= read -r f; do
  scan_file "$f"
done < <(find "$SKILL_DIR" \( -name '*.md' -o -name '*.sh' \) -type f 2>/dev/null)

# (2) Scan the GENERATED reference sheet (offline sandbox, Layer-3 markdown).
GEN_SCRIPT="$SKILL_DIR/scripts/21-generate-client-reference-sheet.sh"
TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT
if [ -f "$GEN_SCRIPT" ]; then
  TMP="$(mktemp -d)"
  MFD="$TMP/master-files"; mkdir -p "$MFD"
  SANDBOX_PATH=""
  IFS=':' read -ra _parts <<< "$PATH"
  for p in "${_parts[@]}"; do
    [ -x "$p/openclaw" ] && continue
    if [ -z "$SANDBOX_PATH" ]; then SANDBOX_PATH="$p"; else SANDBOX_PATH="$SANDBOX_PATH:$p"; fi
  done
  [ -n "$SANDBOX_PATH" ] || SANDBOX_PATH="$PATH"
  env -i HOME="$TMP" PATH="$SANDBOX_PATH" MASTER_FILES_DIR="$MFD" \
    PUBLIC_HOSTNAME="claw.example.com" ROUTE_ID="QCREF" HOOK_NAME="QCREF" \
    AGENT_ID="main" ROUTING_AGENT_ID="main" HOOKS_TOKEN="hooks_dummy" \
    CLIENT_BUSINESS_NAME="Acme Co" CLIENT_TELEGRAM_CHAT_ID="0" \
    SKILL38_TEMPLATES_DIR="$SKILL_DIR/templates" \
    bash "$GEN_SCRIPT" >/dev/null 2>&1 || true
  GEN_SHEET="$MFD/conversation-workflows/01-client-reference-sheet.md"
  [ -f "$GEN_SHEET" ] || GEN_SHEET="$(find "$MFD" -name '*reference-sheet*.md' 2>/dev/null | head -n1)"
  if [ -n "$GEN_SHEET" ] && [ -f "$GEN_SHEET" ]; then
    scan_file "$GEN_SHEET"
    echo "  scanned generated sheet: $GEN_SHEET"
  else
    echo "  [WARN] generator produced no sheet to scan (still scanned the tree)"
  fi
fi

# Optional explicit sheet (e.g. a real rendered client doc).
[ -n "$EXTRA_SHEET" ] && [ -f "$EXTRA_SHEET" ] && scan_file "$EXTRA_SHEET"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — no personal/client identifiers anywhere in the skill or its generated output."
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"PASS"}\n'
  exit 0
else
  echo "RESULT: FAIL — personal/client identifier(s) found (this is a UNIVERSAL skill — genericize every one):"
  for h in "${HITS[@]}"; do echo "  - $h"; done
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"FAIL","hits":%s}\n' "${#HITS[@]}"
  exit 1
fi
