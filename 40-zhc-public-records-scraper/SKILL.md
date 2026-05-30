# Skill 40: ZHC Public Records Scraper

## MANDATORY — Teach Yourself Protocol (TYP)

**Before using this skill, complete the Teach Yourself Protocol (Skill 01) on this folder.**

Required read order:
1. SKILL.md (this file)
2. INSTALL.md — one-time setup: prerequisites + the numbered install scripts (`00`–`04`) + the `qc-no-personal-data.sh` linter
3. INSTRUCTIONS.md — the operator + runtime walkthrough (the four tiers, auto-detect, caching, rate/cost limits, compliance, the F52 log)
4. CORE_UPDATES.md — what gets appended to AGENTS.md (additive, marker-fenced)
5. references/compliance-and-tiers.md — the four tiers + the binding compliance rules
6. references/tier1-county-registry.md (+ .tsv) — the curated county registry
7. references/master-files-event-contract-F52.md — the `public-records-queries.jsonl` schema
8. CHANGELOG.md — change history

Per N3 ("read before act"), do not skip. Per N4, follow steps in declared order.

## Governing protocol (binding for this skill and all skills in the repo)

This skill is governed by `../QC-PROTOCOL.md` (repo root) — the Sub-Agent Handoff
and Mandatory QC Protocol. Every install, every PR, every multi-file change runs
the 10-category QC rubric (8.5 threshold) BEFORE declaring done. Sub-agents
receive full instructions (never summaries). See `QC-PROTOCOL.md` Part 5.

## What This Skill Is

**Skill 40 is a TIERED public-records lookup engine.** Given an address (or ZIP +
state, or explicit county+state), it resolves the jurisdiction and routes through
four tiers to find a lawful, attributed PUBLIC-records source — and when none
exists, it says so honestly instead of fabricating data.

It is most useful paired with **Skill 39 (Real Estate Playbook)**, whose
pre-foreclosure outreach protocol consumes the NOD / tax-delinquency signals this
skill sources. It also runs standalone.

## The four tiers (auto-detected: address/ZIP → county+state → T1? T2? T3? else T4)
- **Tier 1 — Curated scrapers** for 20 major counties (Cook IL, LA, Maricopa AZ,
  Harris TX, San Diego, Orange CA, and more) in
  `references/tier1-county-registry.tsv`.
- **Tier 2 — Platform-adapter FRAMEWORK** (one adapter per vendor). Two example
  adapters ship: Tyler Technologies (Eagle/EagleWeb) and GovOS/Landmark Web.
- **Tier 3 — Operator-buildable scraper CONFIG** (URL + search-form param +
  result selectors), VALIDATED (URL + robots.txt + required keys + ROBOTS_OK
  attestation) before it goes live.
- **Tier 4 — HONEST GAP** — no online DB / blocked / not wired → tell the
  operator, never fabricate.

## Cardinal rules
- **Never fabricate a record.** Unreachable / blocked / not-online → honest gap.
- **Respect robots.txt + each target's ToS.**
- **Attribute** source + retrieval timestamp on every record.
- **Rate limits** (per-day + per-target) and a **daily cost cap** with a **cost
  estimate before any bulk op** (operator confirms).
- **30-day cache** under `<MASTER_FILES_DIR>/public-records-cache/`
  (`--force-refresh` to bypass).

## Prerequisites
- `curl` — HARD (any live fetch).
- A browser fetch path (Skill 03 / playwright) — SOFT (JS-heavy portals).
- Skill 39 — Real Estate Playbook — SOFT (pre-foreclosure pairing).

`scripts/00-verify-prerequisites.sh` checks these; it never auto-installs.

## What This Skill Ships
- **6 scripts** + **2 example adapters** (idempotent, OS-aware Darwin + Linux):
  - `00-verify-prerequisites.sh` — curl HARD; browser + Skill 39 SOFT.
  - `01-locate-master-files-folder.sh` — resolve `<MASTER_FILES_DIR>` (reuses
    Skill 38/39's).
  - `02-detect-and-route.sh` — the ROUTER: auto-detect county+state → tier
    decision → cache check → rate/cost enforcement → F52 event.
  - `03-build-scraper-config.sh` — Tier 3 config builder + validator.
  - `04-update-agents-md.sh` — ADDITIVE, marker-fenced AGENTS.md block.
  - `qc-no-personal-data.sh` — universal-skill guard + Tier-1-registry +
    tier-vocabulary invariants.
  - `adapters/tyler-technologies.sh`, `adapters/govos-landmark.sh` — Tier 2
    example adapters (the adapter contract).
- **3 protocols:** adapter-authoring, pre-foreclosure sourcing, record-type routing.
- **4 references:** compliance-and-tiers, tier1-county-registry (.md + .tsv), the
  F52 event contract.
- **AGENTS.md update:** one additive marker-fenced block.

## MVP honesty — REAL vs STUB
- **REAL:** the tier router + auto-detect, the 20-county Tier 1 registry, the
  Tier 2 adapter framework + 2 example adapters, the Tier 3 config builder +
  validator (URL + robots.txt + required-keys + ROBOTS_OK), the 30-day cache, the
  rate limits + cost cap + estimate, the F52 event emission, and the Tier 4
  honest-gap path.
- **STUB / agent-driven:** the live per-county page FETCH + PARSE in Tier 1/3 is
  performed by the AGENT (curl/browser) following the emitted plan — the universal
  skill does not bundle brittle per-site HTML parsers it cannot keep current.
  Tier 2 adapters supply a vendor-level plan; the operator supplies the per-county
  base URL + confirmed coverage. This is a STUB *honestly*.

## What This Skill Does NOT Do
- Does NOT fabricate records — ever.
- Does NOT bundle licensed/paid data, scraped record dumps, a ZIP→county DB, or
  any client data.
- Does NOT bypass robots.txt or a target's ToS.
- Does NOT modify other skills (it appends only its own AGENTS.md block).

## When the Agent Should Invoke This Skill
When public-records data is needed for a property (especially pre-foreclosure /
tax-delinquency sourcing for Skill 39). Estimated install time: 15-25 minutes.
