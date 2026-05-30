# Changelog - Skill 40: ZHC Public Records Scraper

## [1.0.1] - 2026-05-30 - Canonical reconciliation: adopt the canonical tiered build

Reconciles this repo's Skill 40 with the canonical sibling build (the
`openclaw-onboarding` Mac repo is the canonical base per the Round-3 QC decision).
This repo previously shipped a structurally DIFFERENT design (a monolithic
`scripts/02-detect-and-route.sh`, a 20-row `tier1-county-registry.tsv`, a single
coarse `records_query` event, and only `qc-no-personal-data.sh`). That divergent
feature logic is replaced with the canonical build so the two repos are
functionally equivalent (environment differences — Linux `/data` vs Darwin
`~/Downloads` — are handled OS-aware inside each script).

### Added (from the canonical build)
- Router split into helper libs: `scripts/lib-records.sh` (resolve → tier → cache
  → cost-cap → honest-gap), `scripts/lib-cost-cap.sh` (per-day cap + per-target
  rate limit + bulk cost estimate/confirm), `scripts/lib-pr-events.sh` (the
  append-one-line F52 emitter).
- Per-county Tier-1 configs under `references/tier1-counties/*.json` (each with
  `tos_url` + a selector contract), replacing the flat registry TSV.
- Three machine-enforced QC gates: `scripts/qc-no-fabrication.sh` (drives
  lib-records.sh in a sandbox and asserts the Tier-4 honest gap),
  `scripts/qc-compliance.sh` (asserts every Tier-1 config carries `tos_url` +
  robots gate + attribution), and `scripts/qc-no-personal-data.sh` (zero banned
  identifiers — now TSV-independent).
- Machine-readable event schema `templates/public-records-queries.schema.json`.
- Numbered install scripts `00`–`07` (verify, locate-MFD, init-cache,
  load-tier1, configure-caps, validate-target, build-tier3, update-core-files)
  + the four runtime protocols (tier-routing, compliance, cost-cap, cache).
- Tier-1 county UNION: the curated set is now **21** counties — the prior
  20-county registry set PLUS Wayne County MI (which was in the canonical set but
  missing here), reconciled so both repos ship the identical 21 per-county
  configs: Cook IL, Los Angeles CA, Maricopa AZ, Harris TX, San Diego CA,
  Orange CA, Miami-Dade FL, Kings NY, Dallas TX, King WA, Clark NV, Santa Clara
  CA, Tarrant TX, Riverside CA, Wayne MI, Broward FL, Bexar TX, Sacramento CA,
  San Bernardino CA (FIPS 06071), Hillsborough FL (FIPS 12057), Pierce WA
  (FIPS 53053).

### Fixed (PII)
- **Raw PII removed from the event log.** The old `02-detect-and-route.sh` and the
  old `master-files-event-contract-F52.md` wrote the raw input `address`/`zip`
  into `public-records-queries.jsonl`. The canonical build logs only opaque
  handles (`query_ref`/`target_ref`), record TYPES + counts, and cache/cost/
  compliance status — NEVER a raw address or raw record contents. The single log
  contract now matches `INSTRUCTIONS.md`, `SKILL.md`, and the machine-readable
  schema (event enum `cache_init`/`tier_decision`/`cache_hit`/`force_refresh`/
  `query`/`compliance_block`/`cost_estimate`/`cost_block`/`rate_limit_wait`/
  `honest_gap`).

### Kept
- The executable Tier-2 vendor adapters `scripts/adapters/tyler-technologies.sh`
  + `scripts/adapters/govos-landmark.sh` (byte-identical across both repos).

## [1.0.0] - 2026-05-30 - Initial release

First release of the tiered, compliance-first public-records intelligence layer —
the data SIBLING of Skill 39 (Real Estate Playbook). Skill 40 finds + attributes
+ caches + logs records; Skill 39 runs the outreach. The skill NEVER fabricates a
record (no source → Tier-4 honest gap). robots.txt respected, ToS referenced per
target, source + timestamp attribution; per-day + per-target rate limits + daily
cost cap + cost estimate before bulk ops; 30-day cache. Pairs with Skill 39 for
pre-foreclosure / NOD / tax-delinquency sourcing. Registered in `install.sh`
(`install_skill_40_zhc_public_records_scraper`) + the README skill catalog.
