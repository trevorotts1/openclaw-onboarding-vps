# Skill 40 — ZHC Public Records Scraper — Changelog

This skill has its OWN `skill-version.txt`, independent of the repo version and of
every other skill's version.

## v1.0.0 — initial release

A tiered public-records lookup engine. Resolves a county+state from an
address/ZIP and routes through four tiers to a lawful, attributed PUBLIC-records
source — and honest-gaps when none exists. Pairs with Skill 39 (Real Estate
Playbook).

Shipped:
- **6 scripts + 2 Tier 2 example adapters** (idempotent, OS-aware Darwin + Linux):
  - `00-verify-prerequisites.sh` — `curl` HARD; browser fetch path + Skill 39 SOFT.
  - `01-locate-master-files-folder.sh` — resolves `<MASTER_FILES_DIR>`; reuses
    Skill 38/39's selection when present.
  - `02-detect-and-route.sh` — the ROUTER: auto-detect county+state → Tier 1/2/3/4
    decision → 30-day cache check → per-day + per-target rate limits + daily cost
    cap + cost estimate → append one F52 event.
  - `03-build-scraper-config.sh` — Tier 3 config builder + validator (well-formed
    URL, robots.txt not disallowing the path, required keys, ROBOTS_OK
    attestation); only a VALIDATED config goes live.
  - `04-update-agents-md.sh` — ADDITIVE, marker-fenced AGENTS.md block
    (idempotent in-place refresh).
  - `qc-no-personal-data.sh` — universal-skill identifier guard + Tier-1-registry
    invariant (>=10 rows, 6 cols) + tier-vocabulary invariant.
  - `adapters/tyler-technologies.sh`, `adapters/govos-landmark.sh` — Tier 2
    example adapters implementing the adapter contract (`--covers`/`--plan`/`--vendor`).
- **3 protocols:** adapter-authoring, pre-foreclosure sourcing, record-type routing.
- **4 references:** compliance-and-tiers (the four tiers + binding compliance
  rules), the 20-county Tier 1 registry (`.md` + machine-readable `.tsv`), the F52
  `public-records-queries.jsonl` event contract.
- **AGENTS.md:** one additive marker-fenced block.

Tier 1 curated counties (20): Cook IL, Los Angeles, Maricopa AZ, Harris TX, San
Diego, Orange CA, Kings/Brooklyn NY, Riverside CA, San Bernardino CA, King WA,
Clark NV, Miami-Dade FL, Dallas TX, Tarrant TX, Bexar TX, Broward FL, Sacramento
CA, Santa Clara CA, Hillsborough FL, Pierce WA. (6 confirmed against the county's
own site at authoring time; the rest follow the county's known official pattern
and are confirmed LIVE by the agent — record presence is never assumed.)

Compliance (binding): robots.txt respected, each target's ToS referenced + an
operator ROBOTS_OK attestation for Tier 3, source + retrieval timestamp attributed
on every record, per-day + per-target rate limits, daily cost cap + estimate before
bulk ops, 30-day cache. NEVER fabricates a record — no source / blocked /
not-online → Tier 4 honest gap.

MVP honesty: the engine, routing, compliance, caching, and limits are REAL; the
live per-county FETCH + PARSE is wired to the agent's fetch tools (curl/browser)
via the emitted plan rather than bundled brittle per-site parsers. STUB *honestly*.

Independence: does not modify other skills (appends only its own AGENTS.md block);
ships no licensed/paid data, no scraped dumps, no ZIP→county DB, no client data.
