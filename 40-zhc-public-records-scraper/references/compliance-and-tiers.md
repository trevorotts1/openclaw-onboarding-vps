# Compliance & The Four Tiers (Skill 40)

## The four tiers

Skill 40 resolves a county+state from a query, then routes through four tiers in
order. The router is `scripts/02-detect-and-route.sh`.

- **Tier 1 — Curated scrapers.** 10-20 major counties with a known public-records
  portal, in `references/tier1-county-registry.tsv` (Cook IL, Los Angeles,
  Maricopa AZ, Harris TX, San Diego, Orange CA, and more). The router points the
  agent at the verified portal + record type; the agent fetches LIVE.
- **Tier 2 — Platform-adapter FRAMEWORK.** One adapter per vendor (not per
  county). Two example adapters ship: `scripts/adapters/tyler-technologies.sh`
  (Tyler Eagle/EagleWeb land records) and `scripts/adapters/govos-landmark.sh`
  (GovOS / Landmark Web official records). Each implements the adapter contract
  (`--covers`, `--plan`, `--vendor`). Coverage is operator-confirmed and EMPTY by
  default — a universal skill asserts no county runs a vendor it hasn't confirmed.
- **Tier 3 — Operator-buildable scraper CONFIG.** For a county with no T1 entry
  and no T2 adapter, the operator builds a declarative config (BASE_URL,
  search-form param, result selectors) with `scripts/03-build-scraper-config.sh`.
  The config is VALIDATED (well-formed URL, robots.txt not disallowing, required
  keys present, operator ROBOTS_OK attestation) BEFORE it goes live. Only a
  VALIDATED config is used.
- **Tier 4 — HONEST GAP.** No curated scraper, no adapter, no validated config —
  OR the records simply aren't online / the target is blocked. The agent tells
  the operator plainly: "I don't have a public-records source wired for this
  jurisdiction. I will NOT fabricate a record." Options: supply the county, build
  a Tier 3 config, or accept records may not be online there.

Auto-detect: address/ZIP → county+state → Tier 1? Tier 2? Tier 3? else Tier 4.

## Compliance rules (binding)

1. **robots.txt** — respected. Tier 3 validation fetches robots.txt and refuses
   to promote a config whose BASE_URL path is Disallowed. The agent honors
   robots.txt on every live fetch.
2. **Terms of Service** — each target's ToS is referenced; the operator attests
   (`ROBOTS_OK=1`) that automated access is permitted before a Tier 3 config goes
   live. If a target's ToS forbids automated access, it is a Tier 4 honest gap.
3. **Attribution** — every record carries its SOURCE (the portal) and a retrieval
   TIMESTAMP. No record is presented without provenance.
4. **No fabrication** — ever. Unreachable, blocked, or not-online => honest gap.
5. **Rate limits** — per-day (`SKILL40_MAX_QUERIES_PER_DAY`, default 200) and
   per-target (`SKILL40_MAX_QUERIES_PER_TARGET_PER_DAY`, default 50) caps. The
   router HOLDS and asks for operator confirmation when a cap is hit.
6. **Cost cap + estimate** — `SKILL40_DAILY_COST_CAP_USD` (default $5). The router
   prints a cost ESTIMATE before any bulk op and requires operator confirmation
   for bulk runs (`--bulk N`). Public portals are typically free
   (`SKILL40_COST_PER_QUERY_USD` default $0); paid data sources are operator-
   configured and counted against the cap.

## 30-day cache

Results are cached under `<MASTER_FILES_DIR>/public-records-cache/` keyed by
state|county|zip|address|record-type. Default TTL 30 days
(`SKILL40_CACHE_TTL_DAYS`). A cache HIT returns the cached plan with no live
fetch (politeness + cost). `--force-refresh` bypasses the cache.

## Real-estate use cases (prioritized)
- **Pre-foreclosure / NOD / lis pendens** → recorder/official-records (pairs with
  Skill 39's pre-foreclosure outreach protocol; tag `ZHC-pre-foreclosure-prospect`).
- **Tax delinquency** → tax search.
- **Comps / ownership** → assessor/appraisal search.
- **Permits** → assessor or a separate building-dept portal (often Tier 3).
- **Tax records** → tax search.

## MVP honesty — REAL vs STUB
- **REAL:** the tier router + auto-detect, the 20-county Tier 1 registry, the
  Tier 2 adapter framework + 2 example adapters, the Tier 3 config builder +
  validator (URL + robots.txt + required-keys + ROBOTS_OK), the 30-day cache,
  the rate limits + cost cap + estimate, the F52 event emission, and the Tier 4
  honest-gap path.
- **STUB / operator-driven:** the actual per-county page FETCH + PARSE in Tier 1/3
  is performed by the AGENT (curl/browser) following the emitted plan — the
  universal skill does not bundle brittle per-site HTML parsers it cannot keep
  current. Tier 2 adapters supply a vendor-level plan; the operator supplies the
  per-county base URL + confirmed coverage. This is a STUB *honestly*: the engine,
  routing, compliance, caching, and limits are real; the live extraction is wired
  to the agent's fetch tools, not hardcoded scrapers.
