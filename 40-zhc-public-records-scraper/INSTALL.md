# Skill 40 — ZHC Public Records Scraper: Install Guide

## What this installs

A tiered public-records lookup engine that resolves a county+state from an
address/ZIP and routes through four tiers (curated → adapter → operator-config →
honest gap) to a lawful, attributed PUBLIC-records source. Pairs with Skill 39
(Real Estate Playbook).

- 6 scripts (`00`–`04` + `qc-no-personal-data.sh`) + 2 Tier 2 example adapters —
  idempotent, OS-aware (Darwin + Linux).
- 3 protocols (adapter-authoring, pre-foreclosure sourcing, record-type routing).
- 4 references (compliance-and-tiers, the 20-county Tier 1 registry .md + .tsv,
  the F52 `public-records-queries.jsonl` event contract).
- One ADDITIVE, marker-fenced AGENTS.md block.

## Prerequisites
Checked by `scripts/00-verify-prerequisites.sh` (never auto-installs):
- **HARD: `curl`** — any live fetch.
- SOFT: a browser fetch path (Skill 03 / playwright) — JS-heavy portals.
- SOFT: Skill 39 — Real Estate Playbook (pre-foreclosure pairing).

## Install order (run in this order; each is idempotent)

```bash
cd ~/.openclaw/skills/40-zhc-public-records-scraper/scripts   # macOS
# (VPS: cd /data/.openclaw/skills/40-zhc-public-records-scraper/scripts)

./00-verify-prerequisites.sh         # curl HARD; browser + Skill 39 SOFT
./01-locate-master-files-folder.sh   # resolve <MASTER_FILES_DIR> (reuses 38/39)
./04-update-agents-md.sh             # ADDITIVE marker-fenced AGENTS.md block
```

`02-detect-and-route.sh` (the router) and `03-build-scraper-config.sh` (Tier 3
builder) are RUNTIME tools, not install steps:

```bash
./02-detect-and-route.sh --address "123 Main St, Phoenix, AZ 85003" --record-type recorder
./03-build-scraper-config.sh --county "Travis" --state TX     # scaffold a Tier 3 draft
```

## QC

```bash
./qc-no-personal-data.sh   # universal guard + Tier-1-registry + tier-vocabulary invariants
```

Governed by `../QC-PROTOCOL.md` (10-category rubric, 8.5 threshold) before any PR.

## Compliance (binding — read before first use)
- robots.txt respected; Tier 3 validation refuses a config whose path is Disallowed.
- Each target's ToS referenced; operator attests `ROBOTS_OK=1` for Tier 3.
- Source + retrieval timestamp attributed on every record.
- Per-day + per-target rate limits; daily cost cap; cost estimate before bulk ops.
- 30-day cache; `--force-refresh` to bypass.
- NEVER fabricate a record. No source / blocked / not-online → Tier 4 honest gap.

Operator-overridable env knobs: `SKILL40_MAX_QUERIES_PER_DAY` (200),
`SKILL40_MAX_QUERIES_PER_TARGET_PER_DAY` (50), `SKILL40_DAILY_COST_CAP_USD` (5.00),
`SKILL40_COST_PER_QUERY_USD` (0.00), `SKILL40_CACHE_TTL_DAYS` (30).

## OS support
`darwin` (Mac) and `linux` (VPS). Scripts detect OS via `uname -s`. Master files
+ cache + query log live under `<MASTER_FILES_DIR>` (resolved by `01-`).

## What this does NOT do
- Does NOT fabricate records.
- Does NOT bundle licensed/paid data, scraped dumps, a ZIP→county DB, or client data.
- Does NOT bypass robots.txt / ToS.
- Does NOT modify other skills (appends only its own AGENTS.md block).

## Where to read next
- `INSTRUCTIONS.md` — the operator + runtime walkthrough.
- `references/compliance-and-tiers.md` — the four tiers + compliance rules.
- `references/tier1-county-registry.md` — the curated counties + how to add more.
