#!/usr/bin/env bash
# 04-update-agents-md.sh — Skill 40 (ZHC Public Records Scraper)
#
# Appends ONE additive, idempotent, marker-fenced block to the client agent's
# AGENTS.md telling the runtime WHEN to use the public-records engine, the TIER
# model, the compliance rules, and the NEVER-FABRICATE / honest-gap discipline.
#
# Does NOT edit any other skill's block. Idempotent (re-running refreshes the
# block in place). OS-aware Darwin + Linux. set -uo pipefail.
#
# Usage: 04-update-agents-md.sh [/path/to/AGENTS.md]

set -uo pipefail

OS="$(uname -s)"
case "$OS" in
  Darwin) OC_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}" ;;
  Linux)  OC_HOME="${OPENCLAW_HOME:-/data/.openclaw}" ;;
  *) OC_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}" ;;
esac

AGENTS_MD="${1:-}"
if [ -z "$AGENTS_MD" ]; then
  for cand in "$OC_HOME/agents/main/AGENTS.md" "$OC_HOME/AGENTS.md"; do
    if [ -f "$cand" ]; then AGENTS_MD="$cand"; break; fi
  done
fi
if [ -z "$AGENTS_MD" ]; then echo "ERROR: could not locate AGENTS.md (pass the path)." >&2; exit 1; fi
[ -f "$AGENTS_MD" ] || { echo "ERROR: AGENTS.md not found at $AGENTS_MD" >&2; exit 1; }

BEGIN="<!-- BEGIN SKILL40: PUBLIC_RECORDS_SCRAPER -->"
END="<!-- END SKILL40: PUBLIC_RECORDS_SCRAPER -->"

read -r -d '' BLOCK <<'BLOCK_EOF'
<!-- BEGIN SKILL40: PUBLIC_RECORDS_SCRAPER -->
## Public Records Scraper (Skill 40)

When you need PUBLIC-records data on a property (ownership, deeds, NOD/lis
pendens, tax delinquency, comps, permits, tax records), use the tiered engine:

```
40-zhc-public-records-scraper/scripts/02-detect-and-route.sh \
  --address "<addr>" --record-type <recorder|assessor|tax|parcel|permits>
```

It resolves county+state and routes:
- **Tier 1** — a curated portal exists (20-county registry); fetch the verified
  portal LIVE.
- **Tier 2** — a vendor adapter matches (Tyler / GovOS examples in
  `scripts/adapters/`).
- **Tier 3** — a VALIDATED operator-built config exists for the county.
- **Tier 4 — HONEST GAP** — none of the above, or the records aren't online /
  the target is blocked. Tell the operator plainly and **NEVER fabricate a
  record.**

CARDINAL RULES: respect robots.txt + each target's ToS; attribute SOURCE +
retrieval TIMESTAMP on every record; honor the per-day + per-target rate limits
and the daily cost cap (the router HOLDS for confirmation past a cap, and prints
a cost ESTIMATE before any `--bulk` op); results cache 30 days under
`<MASTER_FILES_DIR>/public-records-cache/` (use `--force-refresh` to bypass).

Pre-foreclosure / tax-delinquency signals feed Skill 39's pre-foreclosure
outreach (tag `ZHC-pre-foreclosure-prospect`).

Every query logs one JSONL event to
`<MASTER_FILES_DIR>/public-records-queries.jsonl` (F52 master-files event
contract).
<!-- END SKILL40: PUBLIC_RECORDS_SCRAPER -->
BLOCK_EOF

BLOCK_FILE="$(mktemp)"
printf '%s\n' "$BLOCK" > "$BLOCK_FILE"
TMP="$(mktemp)"

if grep -qF "$BEGIN" "$AGENTS_MD"; then
  awk -v b="$BEGIN" -v e="$END" '
    index($0, b) {skip=1; next}
    skip==1 && index($0, e) {skip=0; next}
    skip==0 {print}
  ' "$AGENTS_MD" > "$TMP"
  awk 'BEGIN{blanks=0} {if($0==""){blanks++} else {while(blanks>0){print "";blanks--} print $0}}' "$TMP" > "$TMP.2"
  {
    cat "$TMP.2"
    printf '\n'
    cat "$BLOCK_FILE"
  } > "$AGENTS_MD"
  rm -f "$TMP" "$TMP.2"
  echo "[skill 40] refreshed AGENTS.md block in place: $AGENTS_MD"
else
  {
    printf '\n'
    cat "$BLOCK_FILE"
  } >> "$AGENTS_MD"
  rm -f "$TMP"
  echo "[skill 40] appended AGENTS.md block: $AGENTS_MD"
fi
rm -f "$BLOCK_FILE"
exit 0
