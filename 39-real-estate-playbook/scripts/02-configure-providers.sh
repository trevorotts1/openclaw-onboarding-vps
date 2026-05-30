#!/usr/bin/env bash
# 02-configure-providers.sh — Skill 39 (Real Estate Playbook)
#
# Property-data provider abstraction + key discovery. Skill 39 NEVER fabricates
# property data: every property lookup goes through a named provider, and if no
# provider key is configured for a capability the lookup returns an HONEST gap.
#
# This script does NOT make network calls and does NOT collect keys interactively
# beyond reporting what it finds. It scans the operator's standard env locations
# (same order Skill 38 uses for CF tokens) for any provider key, records which
# capabilities are AVAILABLE vs HONEST-GAP, and writes a provider-status JSON next
# to the master files folder so the runtime knows what it may and may not answer.
#
# Provider keys are OPTIONAL and operator-supplied. The skill ships with the
# provider ABSTRACTION (references/property-providers.md) but ships NO keys and
# NO scraped data. MLS access in particular is licensed per-operator (RESO Web
# API / IDX vendor) — the skill documents the contract; the operator supplies it.
#
# Idempotent. OS-aware Darwin + Linux. set -uo pipefail (read-mostly).

set -uo pipefail

OS="$(uname -s)"
case "$OS" in
  Darwin) DEFAULT_MFD="$HOME/Downloads" ;;
  Linux)  DEFAULT_MFD="/data" ;;
  *) echo "Unsupported OS: $OS"; exit 2 ;;
esac
MFD="${MASTER_FILES_DIR:-$DEFAULT_MFD}"
OUT="$MFD/.skill-39-provider-status.json"

# Capability -> accepted env var names. ALL optional.
#   property_lookup : Zillow-adjacent / RentSpree / generic listing provider
#   mls             : RESO Web API token (licensed per-operator)
#   geocode         : address normalization + lat/long
#   street_view     : exterior image generation (Google Street View Static API)
#   comps           : comparable-sales provider
CAP_property_lookup=( "RENTSPREE_API_KEY" "RAPIDAPI_ZILLOW_KEY" "PROPERTY_API_KEY" )
CAP_mls=( "RESO_WEB_API_TOKEN" "MLS_API_TOKEN" "IDX_API_KEY" )
CAP_geocode=( "GOOGLE_GEOCODING_API_KEY" "MAPBOX_TOKEN" "GEOCODE_API_KEY" )
CAP_street_view=( "GOOGLE_STREET_VIEW_API_KEY" "GOOGLE_MAPS_API_KEY" )
CAP_comps=( "COMPS_API_KEY" "ATTOM_API_KEY" "PROPERTY_API_KEY" )

SEARCH_FILES=(
  "$HOME/.openclaw/.env"
  "$HOME/.openclaw/secrets.env"
  "$HOME/.openclaw/openclaw.env"
  "$MFD/.env"
  "$MFD/secrets.env"
  "$HOME/.zshrc"
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
)

find_key() {  # find_key VARNAME -> prints "1" if a non-empty value is present anywhere
  local name="$1" f line val
  # env first
  val="$(printenv "$name" 2>/dev/null || true)"
  if [ -n "$val" ]; then echo 1; return 0; fi
  for f in "${SEARCH_FILES[@]}"; do
    [ -f "$f" ] || continue
    line="$(grep -E "^[[:space:]]*(export[[:space:]]+)?${name}[[:space:]]*=" "$f" 2>/dev/null | tail -1 || true)"
    if [ -n "$line" ]; then
      val="$(echo "$line" | sed -E "s/^[[:space:]]*(export[[:space:]]+)?${name}[[:space:]]*=[[:space:]]*//" | sed -E 's/^"(.*)"$/\1/' | sed -E "s/^'(.*)'$/\1/" | tr -d '[:space:]')"
      if [ -n "$val" ]; then echo 1; return 0; fi
    fi
  done
  echo 0
}

cap_status() {  # cap_status capname VAR1 VAR2 ... -> AVAILABLE | HONEST_GAP (+ which var)
  local cap="$1"; shift
  local v hit=""
  for v in "$@"; do
    if [ "$(find_key "$v")" = "1" ]; then hit="$v"; break; fi
  done
  if [ -n "$hit" ]; then
    echo "AVAILABLE $hit"
  else
    echo "HONEST_GAP -"
  fi
}

echo "=== [skill 39] property-data provider status ==="
echo "    (keys are OPTIONAL + operator-supplied; absence => honest gap, never fabrication)"

declare -a ROWS=()
add_row() {  # add_row capname "VAR1 VAR2 ..."
  local cap="$1"; shift
  local res; res="$(cap_status "$cap" $@)"
  local state="${res%% *}" via="${res##* }"
  echo "  - $cap: $state${via:+ (via $via)}"
  ROWS+=("\"$cap\":{\"state\":\"$state\",\"via\":\"${via}\"}")
}

add_row "property_lookup" "${CAP_property_lookup[@]}"
add_row "mls"             "${CAP_mls[@]}"
add_row "geocode"         "${CAP_geocode[@]}"
add_row "street_view"     "${CAP_street_view[@]}"
add_row "comps"           "${CAP_comps[@]}"

# Write provider-status JSON (idempotent overwrite)
{
  printf '{\n  "generated": "%s",\n  "skill": "39-real-estate-playbook",\n  "capabilities": {\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local_i=0
  for r in "${ROWS[@]}"; do
    local_i=$((local_i+1))
    if [ "$local_i" -lt "${#ROWS[@]}" ]; then printf '    %s,\n' "$r"; else printf '    %s\n' "$r"; fi
  done
  printf '  }\n}\n'
} > "$OUT" 2>/dev/null || true

echo ""
echo "  provider status written: $OUT"
echo "  See references/property-providers.md for how to add each provider key."
exit 0
