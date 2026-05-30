#!/usr/bin/env bash
# 02-detect-and-route.sh — Skill 40 (ZHC Public Records Scraper) — the ROUTER.
#
# Given an address (or ZIP + state, or explicit --county/--state), this:
#   1. Resolves county + state (ZIP->county is operator-data-assisted; see notes)
#   2. Decides the TIER:
#        Tier 1 — a curated scraper exists for this county (tier1 registry)
#        Tier 2 — no T1, but a platform ADAPTER matches the county's vendor
#        Tier 3 — no T1/T2, but an operator-built scraper CONFIG exists + validates
#        Tier 4 — none of the above => HONEST GAP (tell the operator; never fabricate)
#   3. Checks the 30-day cache (force-refresh with --force-refresh)
#   4. Enforces rate limits + the cost cap (estimate before any bulk op)
#   5. Emits one F52 event to <MASTER_FILES_DIR>/public-records-queries.jsonl
#      (records: query, resolved county/state, tier, cache hit/miss, est. cost)
#
# This script RESOLVES + ROUTES + LOGS. It does NOT itself fetch a county page in
# T1 mode — it tells the agent the exact verified portal + record-type to fetch
# LIVE (through curl/browser), respecting robots.txt + ToS, attributing source +
# timestamp. The actual fetch+parse for T1/T3 is performed by the agent using the
# emitted plan; T2 adapters live in scripts/adapters/. This keeps the universal
# skill from bundling brittle per-site parsers it cannot keep current.
#
# Idempotent w.r.t. the cache (a cache hit returns the cached plan). The query
# log is append-only by design. OS-aware Darwin + Linux. set -uo pipefail.
#
# Usage:
#   02-detect-and-route.sh --address "123 Main St, Chicago, IL 60601" --record-type recorder
#   02-detect-and-route.sh --county "Maricopa" --state AZ --record-type tax
#   02-detect-and-route.sh --address "..." --force-refresh
#   02-detect-and-route.sh --address "..." --json

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$SKILL_ROOT/references/tier1-county-registry.tsv"
ADAPTER_DIR="$SCRIPT_DIR/adapters"

OS="$(uname -s)"
case "$OS" in
  Darwin) DEFAULT_MFD="$HOME/Downloads" ;;
  Linux)  DEFAULT_MFD="/data" ;;
  *) DEFAULT_MFD="$HOME" ;;
esac
MFD="${MASTER_FILES_DIR:-$DEFAULT_MFD}"
CACHE_DIR="$MFD/public-records-cache"
EVENTS="$MFD/public-records-queries.jsonl"
CONFIG_DIR="$MFD/.skill-40-scraper-configs"   # Tier 3 operator-built configs

# Rate-limit + cost-cap defaults (operator-overridable via env)
RL_PER_DAY="${SKILL40_MAX_QUERIES_PER_DAY:-200}"
RL_PER_TARGET="${SKILL40_MAX_QUERIES_PER_TARGET_PER_DAY:-50}"
COST_PER_QUERY="${SKILL40_COST_PER_QUERY_USD:-0.00}"   # default: free public portals
COST_CAP="${SKILL40_DAILY_COST_CAP_USD:-5.00}"
CACHE_TTL_DAYS="${SKILL40_CACHE_TTL_DAYS:-30}"

ADDRESS=""; COUNTY=""; STATE=""; ZIP=""; RECORD_TYPE="recorder"
FORCE_REFRESH=0; JSON=0; NO_LOG=0; BULK_COUNT=1

while [ $# -gt 0 ]; do
  case "$1" in
    --address)       ADDRESS="$2"; shift 2 ;;
    --county)        COUNTY="$2"; shift 2 ;;
    --state)         STATE="$2"; shift 2 ;;
    --zip)           ZIP="$2"; shift 2 ;;
    --record-type)   RECORD_TYPE="$2"; shift 2 ;;
    --force-refresh) FORCE_REFRESH=1; shift ;;
    --bulk)          BULK_COUNT="$2"; shift 2 ;;
    --json)          JSON=1; shift ;;
    --no-log)        NO_LOG=1; shift ;;
    -h|--help)       sed -n '1,46p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---------- 1. Resolve county + state ----------
if [ -z "$STATE" ] && [ -n "$ADDRESS" ]; then
  STATE="$(echo "$ADDRESS" | grep -oE '\b[A-Za-z]{2}\b' | tail -1 | tr '[:lower:]' '[:upper:]')"
fi
if [ -z "$ZIP" ] && [ -n "$ADDRESS" ]; then
  ZIP="$(echo "$ADDRESS" | grep -oE '\b[0-9]{5}(-[0-9]{4})?\b' | head -1)"
fi
# County resolution: explicit --county wins. Else try to read the city/county
# token from the address. ZIP->county requires operator-supplied crosswalk data
# (not bundled — universal skill ships no licensed ZIP DB); absent it, we honest-
# gap the county and ask the operator/agent to supply it.
if [ -z "$COUNTY" ] && [ -n "$ADDRESS" ]; then
  # naive: the city segment often equals or implies the county for major metros;
  # we do NOT guess a county from a city — we leave it empty and let the router
  # honest-gap if it can't match. (No fabrication.)
  :
fi

echo "=== [skill 40] public-records router ==="
echo "  query:       address='${ADDRESS}' county='${COUNTY}' state='${STATE}' zip='${ZIP}'"
echo "  record-type: ${RECORD_TYPE}"

# ---------- 2. Tier decision ----------
TIER="4"; PLAN=""; MATCH_DOMAIN=""; MATCH_VERIFIED=""; MATCH_NOTE=""

registry_lookup() {  # sets MATCH_* on a county+state hit in the TSV
  [ -f "$REGISTRY" ] || return 1
  [ -n "$COUNTY" ] && [ -n "$STATE" ] || return 1
  local line
  line="$(awk -F'\t' -v c="$COUNTY" -v s="$STATE" '
    NR==1 {next}
    {
      cc=tolower($2); sc=toupper($1);
      tc=tolower(c); ts=toupper(s);
      if (cc==tc && sc==ts) {print; exit}
    }' "$REGISTRY")"
  [ -n "$line" ] || return 1
  MATCH_DOMAIN="$(echo "$line" | awk -F'\t' '{print $3}')"
  RECTYPES="$(echo "$line" | awk -F'\t' '{print $4}')"
  MATCH_VERIFIED="$(echo "$line" | awk -F'\t' '{print $5}')"
  MATCH_NOTE="$(echo "$line" | awk -F'\t' '{print $6}')"
  return 0
}

adapter_lookup() {  # Tier 2: a vendor adapter that declares it covers county+state
  [ -d "$ADAPTER_DIR" ] || return 1
  local a
  for a in "$ADAPTER_DIR"/*.sh; do
    [ -f "$a" ] || continue
    # An adapter answers `--covers <county> <state>` with exit 0 if it handles it.
    if bash "$a" --covers "$COUNTY" "$STATE" >/dev/null 2>&1; then
      MATCH_DOMAIN="$(basename "$a")"
      return 0
    fi
  done
  return 1
}

config_lookup() {  # Tier 3: an operator-built, validated scraper config
  [ -d "$CONFIG_DIR" ] || return 1
  [ -n "$COUNTY" ] && [ -n "$STATE" ] || return 1
  local key cfg
  key="$(echo "${STATE}-${COUNTY}" | tr '[:upper:] ' '[:lower:]-')"
  cfg="$CONFIG_DIR/$key.conf"
  if [ -f "$cfg" ] && grep -q '^VALIDATED=1' "$cfg" 2>/dev/null; then
    MATCH_DOMAIN="$(grep -E '^BASE_URL=' "$cfg" | head -1 | sed 's/^BASE_URL=//')"
    return 0
  fi
  return 1
}

if registry_lookup; then
  TIER="1"
  PLAN="Tier 1 curated: navigate ${MATCH_DOMAIN} for a '${RECORD_TYPE}' search on the property; fetch LIVE (curl/browser), respect robots.txt + ToS, attribute source+timestamp. verified=${MATCH_VERIFIED}. note: ${MATCH_NOTE}"
elif adapter_lookup; then
  TIER="2"
  PLAN="Tier 2 adapter: run scripts/adapters/${MATCH_DOMAIN} for ${COUNTY}, ${STATE} (vendor-platform adapter)."
elif config_lookup; then
  TIER="3"
  PLAN="Tier 3 operator-config: validated scraper config for ${COUNTY}, ${STATE} -> ${MATCH_DOMAIN}."
else
  TIER="4"
  PLAN="Tier 4 HONEST GAP: no curated scraper, no matching adapter, and no validated operator config for county='${COUNTY}' state='${STATE}'. Tell the operator: I don't have a public-records source wired for this jurisdiction. I will NOT fabricate a record. Options: (a) supply the county if it wasn't resolved, (b) build a Tier 3 config (scripts/03-build-scraper-config.sh), or (c) accept that records may not be online here."
fi

echo "  TIER:        $TIER"
[ -n "$MATCH_DOMAIN" ] && echo "  target:      $MATCH_DOMAIN"

# ---------- 3. Cache check ----------
mkdir -p "$CACHE_DIR" 2>/dev/null || true
cache_key() {
  printf '%s' "${STATE}|${COUNTY}|${ZIP}|${ADDRESS}|${RECORD_TYPE}" | tr ' /' '__' | tr -cd '[:alnum:]_|-' | sed 's/|/-/g'
}
CK="$(cache_key)"
CACHE_FILE="$CACHE_DIR/${CK}.json"
CACHE_HIT="false"
if [ "$FORCE_REFRESH" -eq 0 ] && [ -f "$CACHE_FILE" ]; then
  # fresh if newer than TTL days
  if [ -n "$(find "$CACHE_FILE" -mtime "-${CACHE_TTL_DAYS}" 2>/dev/null)" ]; then
    CACHE_HIT="true"
    echo "  cache:       HIT (${CACHE_FILE}, < ${CACHE_TTL_DAYS}d old) — returning cached plan; no live fetch needed"
  else
    echo "  cache:       STALE (> ${CACHE_TTL_DAYS}d) — will refresh on live fetch"
  fi
else
  [ "$FORCE_REFRESH" -eq 1 ] && echo "  cache:       BYPASSED (--force-refresh)"
fi

# ---------- 4. Rate limits + cost cap ----------
TODAY="$(date -u +%Y-%m-%d)"
queries_today=0
target_today=0
if [ -f "$EVENTS" ]; then
  queries_today="$(grep -c "\"date\":\"$TODAY\"" "$EVENTS" 2>/dev/null || echo 0)"
  if [ -n "$MATCH_DOMAIN" ]; then
    target_today="$(grep "\"date\":\"$TODAY\"" "$EVENTS" 2>/dev/null | grep -cF "\"target\":\"$MATCH_DOMAIN\"" 2>/dev/null || echo 0)"
  fi
fi
queries_today=${queries_today:-0}; target_today=${target_today:-0}

RATE_BLOCK=""
if [ "$queries_today" -ge "$RL_PER_DAY" ]; then
  RATE_BLOCK="per-day cap reached ($queries_today/$RL_PER_DAY)"
elif [ -n "$MATCH_DOMAIN" ] && [ "$target_today" -ge "$RL_PER_TARGET" ]; then
  RATE_BLOCK="per-target cap reached for $MATCH_DOMAIN ($target_today/$RL_PER_TARGET)"
fi

# cost estimate (for bulk especially)
EST_COST="$(awk -v n="$BULK_COUNT" -v c="$COST_PER_QUERY" 'BEGIN{printf "%.2f", n*c}')"
echo "  rate:        today=$queries_today/$RL_PER_DAY  target=$target_today/$RL_PER_TARGET"
echo "  cost est:    \$$EST_COST for $BULK_COUNT query(ies) (cap \$$COST_CAP/day)"

COST_BLOCK=""
if awk -v e="$EST_COST" -v cap="$COST_CAP" 'BEGIN{exit !(e>cap)}'; then
  COST_BLOCK="estimated cost \$$EST_COST exceeds daily cap \$$COST_CAP"
fi

if [ -n "$RATE_BLOCK" ] || [ -n "$COST_BLOCK" ]; then
  echo "  ⚠️  HOLD: ${RATE_BLOCK}${RATE_BLOCK:+; }${COST_BLOCK}"
  echo "      Operator confirmation required before proceeding (raise the cap via the"
  echo "      SKILL40_* env vars, or wait until tomorrow). No fetch was performed."
fi
if [ "$BULK_COUNT" -gt 1 ]; then
  echo "  ℹ️  BULK op ($BULK_COUNT): operator must confirm the \$$EST_COST estimate before running."
fi

# ---------- 4b. Cache write ----------
# Persist the resolved routing PLAN so an identical query within the TTL is a
# cache HIT (politeness + cost). We do NOT cache when this was already a hit,
# when --force-refresh re-resolved (we refresh the cache then), when blocked by a
# cap, or on a Tier 4 honest gap (nothing useful to cache). The cached artifact
# is the routing plan + tier/target — the agent caches the actual fetched record
# separately when it executes the plan.
if [ "$CACHE_HIT" != "true" ] && [ -z "$RATE_BLOCK$COST_BLOCK" ] && [ "$TIER" != "4" ]; then
  mkdir -p "$CACHE_DIR" 2>/dev/null || true
  c_esc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '"%s"' "$s"; }
  {
    printf '{"cached":%s,"county":%s,"state":%s,"record_type":%s,"tier":%s,"target":%s,"plan":%s}\n' \
      "$(c_esc "$(date -u +%Y-%m-%dT%H:%M:%SZ)")" \
      "$(c_esc "$COUNTY")" "$(c_esc "$STATE")" "$(c_esc "$RECORD_TYPE")" \
      "$TIER" "$(c_esc "$MATCH_DOMAIN")" "$(c_esc "$PLAN")"
  } > "$CACHE_FILE" 2>/dev/null || true
  [ -f "$CACHE_FILE" ] && echo "  cache:       WROTE ($CACHE_FILE, TTL ${CACHE_TTL_DAYS}d)"
fi

# ---------- 5. F52 event append ----------
if [ "$NO_LOG" -eq 0 ]; then
  mkdir -p "$MFD" 2>/dev/null || true
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # JSON-escape a string and ALWAYS emit a quoted value (works on empty strings).
  jq_str() {
    local s="$1"
    s="${s//\\/\\\\}"   # backslash first
    s="${s//\"/\\\"}"   # then double-quote
    printf '"%s"' "$s"
  }
  blocked="false"; [ -n "$RATE_BLOCK$COST_BLOCK" ] && blocked="true"
  printf '{"ts":"%s","date":"%s","skill":"40-zhc-public-records-scraper","event":"records_query","address":%s,"county":%s,"state":%s,"zip":%s,"record_type":%s,"tier":%s,"target":%s,"cache_hit":%s,"queries_today":%d,"est_cost_usd":%s,"blocked":%s}\n' \
    "$ts" "$TODAY" \
    "$(jq_str "$ADDRESS")" "$(jq_str "$COUNTY")" "$(jq_str "$STATE")" "$(jq_str "$ZIP")" \
    "$(jq_str "$RECORD_TYPE")" "$TIER" "$(jq_str "$MATCH_DOMAIN")" "$CACHE_HIT" \
    "$queries_today" "$(jq_str "$EST_COST")" "$blocked" >> "$EVENTS"
  echo "  F52 event appended: $EVENTS"
fi

# ---------- output the plan ----------
echo ""
echo "  PLAN: $PLAN"
if [ "$JSON" -eq 1 ]; then
  printf '{"tier":%s,"target":%s,"cache_hit":%s,"blocked":%s}\n' \
    "$TIER" "$(printf '%s' "$MATCH_DOMAIN" | sed 's/"/\\"/g; s/^/"/; s/$/"/')" "$CACHE_HIT" \
    "$([ -n "$RATE_BLOCK$COST_BLOCK" ] && echo true || echo false)"
fi
exit 0
