#!/usr/bin/env bash
# 03-build-scraper-config.sh — Skill 40 (ZHC Public Records Scraper) — TIER 3.
#
# Lets an OPERATOR build a scraper CONFIG for a county that has no Tier 1 curated
# entry and no Tier 2 adapter. A Tier 3 config is a small declarative file:
#   - BASE_URL          the county portal search page
#   - SEARCH_METHOD     GET | POST
#   - SEARCH_PARAM      the query field name (e.g. address / parcel)
#   - RESULT_SELECTOR   a CSS/XPath-ish selector that locates result rows
#   - FIELD_*           selectors for the fields to extract
#   - ROBOTS_OK         operator attests robots.txt + ToS allow this use
#
# The config is VALIDATED before it goes live:
#   1. BASE_URL is well-formed (http/https) and reachable (HEAD, honoring robots).
#   2. robots.txt is fetched and the path is NOT disallowed (best-effort check;
#      operator still attests ROBOTS_OK=1).
#   3. Required keys are present.
# Only a config that passes validation gets VALIDATED=1 written — and only a
# VALIDATED config is used by the router (Tier 3). An invalid/unvalidated config
# NEVER goes live and NEVER produces fabricated records.
#
# Idempotent (re-running re-validates and overwrites the same key file). OS-aware.
# set -uo pipefail.
#
# Usage (interactive):   03-build-scraper-config.sh --county "Travis" --state TX
# Usage (file-driven):   03-build-scraper-config.sh --from /path/to/draft.conf
# Validate only:         03-build-scraper-config.sh --validate /path/to/key.conf

set -uo pipefail

OS="$(uname -s)"
case "$OS" in
  Darwin) DEFAULT_MFD="$HOME/Downloads" ;;
  Linux)  DEFAULT_MFD="/data" ;;
  *) DEFAULT_MFD="$HOME" ;;
esac
MFD="${MASTER_FILES_DIR:-$DEFAULT_MFD}"
CONFIG_DIR="$MFD/.skill-40-scraper-configs"
mkdir -p "$CONFIG_DIR" 2>/dev/null || true

COUNTY=""; STATE=""; FROM=""; VALIDATE_ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --county)   COUNTY="$2"; shift 2 ;;
    --state)    STATE="$2"; shift 2 ;;
    --from)     FROM="$2"; shift 2 ;;
    --validate) VALIDATE_ONLY="$2"; shift 2 ;;
    -h|--help)  sed -n '1,33p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

validate_conf() {  # validate_conf <file> -> 0 valid / 1 invalid (prints reasons)
  local f="$1" ok=1
  [ -f "$f" ] || { echo "  ✗ config file not found: $f"; return 1; }
  # shellcheck disable=SC1090
  local base method param result robots
  base="$(grep -E '^BASE_URL=' "$f" | head -1 | sed 's/^BASE_URL=//')"
  method="$(grep -E '^SEARCH_METHOD=' "$f" | head -1 | sed 's/^SEARCH_METHOD=//')"
  param="$(grep -E '^SEARCH_PARAM=' "$f" | head -1 | sed 's/^SEARCH_PARAM=//')"
  result="$(grep -E '^RESULT_SELECTOR=' "$f" | head -1 | sed 's/^RESULT_SELECTOR=//')"
  robots="$(grep -E '^ROBOTS_OK=' "$f" | head -1 | sed 's/^ROBOTS_OK=//')"

  if ! echo "$base" | grep -qE '^https?://[A-Za-z0-9.-]+'; then
    echo "  ✗ BASE_URL missing or malformed (need http(s)://...)"; ok=0
  fi
  [ -n "$method" ] || { echo "  ✗ SEARCH_METHOD missing (GET|POST)"; ok=0; }
  [ -n "$param" ]  || { echo "  ✗ SEARCH_PARAM missing"; ok=0; }
  [ -n "$result" ] || { echo "  ✗ RESULT_SELECTOR missing"; ok=0; }
  if [ "$robots" != "1" ]; then
    echo "  ✗ ROBOTS_OK is not 1 — operator must attest robots.txt + ToS allow this use"; ok=0
  fi

  # Best-effort robots.txt + reachability check (only if curl present + base ok)
  if [ "$ok" -eq 1 ] && command -v curl >/dev/null 2>&1; then
    local host scheme robots_url disallow
    scheme="$(echo "$base" | sed -E 's#^(https?)://.*#\1#')"
    host="$(echo "$base" | sed -E 's#^https?://([^/]+).*#\1#')"
    robots_url="$scheme://$host/robots.txt"
    disallow="$(curl -fsSL --max-time 10 "$robots_url" 2>/dev/null | grep -iE '^Disallow:' | sed 's/^[Dd]isallow:[[:space:]]*//' | tr -d '\r')"
    if [ -n "$disallow" ]; then
      local path d
      path="$(echo "$base" | sed -E 's#^https?://[^/]+##')"; [ -z "$path" ] && path="/"
      while IFS= read -r d; do
        [ -z "$d" ] && continue
        case "$path" in "$d"*) echo "  ✗ robots.txt Disallows '$d' which covers BASE_URL path '$path'"; ok=0;; esac
      done <<< "$disallow"
    fi
    # reachability (HEAD)
    if ! curl -fsSL -I --max-time 10 "$base" >/dev/null 2>&1; then
      echo "  ⚠️  BASE_URL did not return a successful HEAD (may need a browser/JS path — Tier 2/honest-gap)"
      # not a hard fail (some portals reject HEAD) but worth noting
    fi
  fi

  [ "$ok" -eq 1 ] && return 0 || return 1
}

# ---- validate-only mode ----
if [ -n "$VALIDATE_ONLY" ]; then
  echo "=== [skill 40] validating Tier 3 config: $VALIDATE_ONLY ==="
  if validate_conf "$VALIDATE_ONLY"; then
    echo "  ✓ VALID"
    exit 0
  else
    echo "  RESULT: INVALID — not promoted. Fix the issues above and re-validate."
    exit 1
  fi
fi

# ---- build from a draft file ----
if [ -n "$FROM" ]; then
  [ -f "$FROM" ] || { echo "draft not found: $FROM" >&2; exit 1; }
  COUNTY="${COUNTY:-$(grep -E '^COUNTY=' "$FROM" | head -1 | sed 's/^COUNTY=//')}"
  STATE="${STATE:-$(grep -E '^STATE=' "$FROM" | head -1 | sed 's/^STATE=//')}"
  [ -n "$COUNTY" ] && [ -n "$STATE" ] || { echo "draft must include COUNTY= and STATE= (or pass --county/--state)" >&2; exit 1; }
  KEY="$(echo "${STATE}-${COUNTY}" | tr '[:upper:] ' '[:lower:]-')"
  DEST="$CONFIG_DIR/$KEY.conf"
  echo "=== [skill 40] building + validating Tier 3 config for $COUNTY, $STATE ==="
  cp "$FROM" "$DEST.tmp"
  if validate_conf "$DEST.tmp"; then
    # stamp VALIDATED=1 (replace any prior value)
    grep -v '^VALIDATED=' "$DEST.tmp" > "$DEST"
    echo "VALIDATED=1" >> "$DEST"
    rm -f "$DEST.tmp"
    echo "  ✓ VALID — promoted to: $DEST (Tier 3 active for $COUNTY, $STATE)"
    exit 0
  else
    rm -f "$DEST.tmp"
    echo "  RESULT: INVALID — NOT promoted. The router will Tier-4 honest-gap this county"
    echo "          until a valid config exists. (No fabrication.)"
    exit 1
  fi
fi

# ---- interactive scaffold (writes a draft the operator fills in) ----
[ -n "$COUNTY" ] && [ -n "$STATE" ] || { echo "Provide --county and --state (or --from/--validate)." >&2; exit 2; }
KEY="$(echo "${STATE}-${COUNTY}" | tr '[:upper:] ' '[:lower:]-')"
DRAFT="$CONFIG_DIR/$KEY.draft.conf"
cat > "$DRAFT" <<DRAFT_EOF
# Tier 3 scraper config — $COUNTY, $STATE
# Fill these in, then run:
#   03-build-scraper-config.sh --from "$DRAFT"
COUNTY=$COUNTY
STATE=$STATE
BASE_URL=https://CHANGE-ME.example.gov/search
SEARCH_METHOD=GET
SEARCH_PARAM=address
RESULT_SELECTOR=table.results tr
FIELD_owner=td.owner
FIELD_parcel=td.parcel
FIELD_status=td.status
# Operator attests robots.txt + Terms of Service permit this automated use:
ROBOTS_OK=0
DRAFT_EOF
echo "=== [skill 40] Tier 3 draft scaffolded ==="
echo "  draft: $DRAFT"
echo "  Edit it (BASE_URL / selectors / set ROBOTS_OK=1 after checking robots.txt + ToS),"
echo "  then: 03-build-scraper-config.sh --from \"$DRAFT\""
exit 0
