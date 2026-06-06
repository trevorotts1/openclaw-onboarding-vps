---
name: real-estate-playbook
description: >
  Real estate property intelligence and playbook — provider configuration, property brain wiring, honest-gap discipline, F52 event log, and public-records-driven lead research.
---

# Skill 39: Real Estate Playbook & Property Intelligence

## MANDATORY — Teach Yourself Protocol (TYP)

**Before using this skill, complete the Teach Yourself Protocol (Skill 01) on this folder.**

Required read order:
1. SKILL.md (this file)
2. INSTALL.md — one-time setup: prerequisites + the numbered install scripts (`00`–`05`) + the `qc-no-personal-data.sh` linter in `scripts/`
3. INSTRUCTIONS.md — the operator + runtime walkthrough (configure providers, wire the brain, the honest-gap discipline, the F52 event log)
4. CORE_UPDATES.md — what gets appended to AGENTS.md (additive, marker-fenced) + the Sales-Brain extension hook
5. references/property-providers.md — the property-data provider abstraction (operator-supplied keys)
6. references/sales-brain-re-extension.md — the ADDITIVE Sales-Brain overlay (RE objections, CMA reveal timing, SPICED-RE)
7. references/master-files-event-contract-F52.md — the `real-estate-events.jsonl` schema
8. CHANGELOG.md — change history

Per N3 ("read before act"), do not skip. Per N4, follow steps in declared order.

## Governing protocol (binding for this skill and all skills in the repo)

This skill is governed by `../QC-PROTOCOL.md` (repo root) — the Sub-Agent Handoff
and Mandatory QC Protocol. Every install, every PR, every multi-file change runs
the 10-category QC rubric (8.5 threshold) BEFORE declaring done. Sub-agents
receive full instructions (never summaries). See `QC-PROTOCOL.md` Part 5.

## What This Skill Is

**Skill 39 is the real-estate vertical brain that runs on top of Skill 38
(Conversational AI System) and Skill 29 (GHL Convert and Flow).** It adds
property intelligence and the real-estate sales/qualification playbook to the
conversational agent: property lookup, address normalization + geocoding,
Street View image generation, comps/CMA, buyer + seller + investor
qualification, showing scheduling (lockbox/MLS rules), state disclosure
compliance pointers, lead routing by specialty, open-house automation, and a
pre-foreclosure outreach playbook that pairs with **Skill 40 (ZHC Public Records
Scraper)**.

Skill 38 is the BRAIN; Skill 39 is the real-estate VERTICAL on top of it. They
are siblings — Skill 39 does NOT modify Skill 38 destructively. The RE
Sales-Brain extension is installed ADDITIVELY (a drop-in file in Skill 38's
`protocols/extensions/` folder).

## Cardinal rule — NEVER fabricate property data

Every property fact (price, beds/baths, sqft, status, comps, owner) comes from a
named, operator-configured provider. If the provider for a capability is not
configured, the answer is an explicit HONEST GAP — the agent says "I don't have a
live data source for X" and offers to pull it once a key is added. The skill
ships ZERO keys and ZERO scraped data.

## Prerequisites
- **Skill 29 — GHL Convert and Flow** (lead routing + tag writes) — HARD.
- **Skill 38 — Conversational AI System** (the Sales-Brain core) — HARD.
- Skill 19 — Humanizer (always-on outbound tone) — SOFT (graceful degrade).
- Skill 36 — GHL MCP Setup (preferred GHL access tier) — SOFT.

`scripts/00-verify-prerequisites.sh` checks these and halts on a missing hard
prerequisite (it never auto-installs or modifies a sibling).

## What This Skill Ships
- **6 scripts** under `scripts/` (idempotent, OS-aware Darwin + Linux): the
  numbered install scripts `00`–`05` plus the `qc-no-personal-data.sh` universal
  guard.
  - `00-verify-prerequisites.sh` — prerequisite gate (hard 29/38, soft 19/36).
  - `01-locate-master-files-folder.sh` — resolve `<MASTER_FILES_DIR>` (reuses
    Skill 38's selection if present).
  - `02-configure-providers.sh` — provider abstraction + key discovery; writes
    the provider-status JSON.
  - `03-property-lookup.sh` — the runtime property worker: normalize → resolve
    providers → honest-gap discipline → append the F52 event.
  - `04-update-agents-md.sh` — ADDITIVE, marker-fenced AGENTS.md block.
  - `05-install-sales-brain-extension.sh` — ADDITIVE Sales-Brain overlay into
    Skill 38's `protocols/extensions/` (Skill 38 core untouched).
  - `qc-no-personal-data.sh` — universal-skill identifier guard + required-tag
    invariant.
- **7 protocol files** under `protocols/`: buyer qualification, seller
  qualification, showing scheduler, disclosure compliance, lead routing,
  open-house automation, pre-foreclosure outreach.
- **3 reference documents** under `references/`: property providers, the
  Sales-Brain RE extension, the F52 event contract.
- **AGENTS.md update:** one additive marker-fenced block (Skill 39).
- **RE tags:** `ZHC-buyer-lead`, `ZHC-seller-lead`, `ZHC-investor-lead`,
  `ZHC-pre-foreclosure-prospect`.

## MVP honesty — what is REAL vs STUB
- **REAL:** provider abstraction + key discovery + capability status, address
  normalization (heuristic), the honest-gap discipline, the F52 event emission,
  the 7 protocols, the additive AGENTS.md block, the additive Sales-Brain
  extension, the 4 ZHC RE tags, and the universal-data QC guard.
- **STUB / operator-supplied:** the actual provider network calls (the agent
  issues them through its configured tool/MCP using the documented request
  shapes), the Street View image fetch (documented Static API URL), and licensed
  MLS access (RESO Web API token — operator-licensed). These are STUBS *honestly*
  — the skill ships the contract + the honest-gap path, not bundled paid keys.

## What This Skill Does NOT Do
- Does NOT modify Skill 38 core, Skill 29, Skill 19, or Skill 36. The RE
  Sales-Brain extension is ADDITIVE (drop-in file), never a destructive edit.
- Does NOT ship provider keys, scraped property data, or any agent roster.
- Does NOT fabricate property data — ever.
- Does NOT render legal advice; disclosure compliance is a POINTER that routes
  specifics to the operator's broker/attorney.
- Does NOT scrape public records itself — that is Skill 40's job (the
  pre-foreclosure protocol consumes Skill 40's output).

## When the Agent Should Invoke This Skill
After Skills 29 + 38 are installed and the operator runs a real-estate business
(or a vertical that needs property intelligence). Estimated install time:
20-30 minutes.
