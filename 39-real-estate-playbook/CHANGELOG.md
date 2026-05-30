# Skill 39 — Real Estate Playbook & Property Intelligence — Changelog

This skill has its OWN `skill-version.txt`, independent of the repo version and of
every other skill's version.

## v1.0.0 — initial release

Real-estate vertical brain on top of Skill 38 (Conversational AI System) and
Skill 29 (GHL Convert and Flow).

Shipped:
- **6 scripts** (idempotent, OS-aware Darwin + Linux):
  - `00-verify-prerequisites.sh` — HARD: Skills 29 + 38; SOFT: Skills 19 + 36;
    halts on a missing hard prerequisite, never auto-installs a sibling.
  - `01-locate-master-files-folder.sh` — resolves `<MASTER_FILES_DIR>`; reuses
    Skill 38's selection when present.
  - `02-configure-providers.sh` — property-data provider abstraction + key
    discovery; writes the provider-status JSON. Keys are OPTIONAL +
    operator-supplied; absence = HONEST GAP, never fabrication.
  - `03-property-lookup.sh` — runtime worker: address normalization → provider
    resolution → honest-gap discipline → append one F52 event.
  - `04-update-agents-md.sh` — ADDITIVE, marker-fenced AGENTS.md block
    (idempotent in-place refresh).
  - `05-install-sales-brain-extension.sh` — ADDITIVE Sales-Brain RE overlay into
    Skill 38's `protocols/extensions/` (Skill 38 core untouched).
  - `qc-no-personal-data.sh` — universal-skill identifier guard + required ZHC-
    tag invariant.
- **7 protocols:** buyer qualification, seller qualification, showing scheduler
  (lockbox/MLS), state disclosure compliance (pointer, not legal advice), lead
  routing by specialty, open-house automation, pre-foreclosure outreach (pairs
  with Skill 40).
- **3 references:** property-provider abstraction, the additive Sales-Brain RE
  extension (RE objections + CMA reveal timing + SPICED-RE), the F52
  `real-estate-events.jsonl` event contract.
- **AGENTS.md:** one additive marker-fenced block.
- **Tags:** `ZHC-buyer-lead`, `ZHC-seller-lead`, `ZHC-investor-lead`,
  `ZHC-pre-foreclosure-prospect`.

MVP honesty: provider network calls, the Street View image fetch, and licensed
MLS access are STUBS *honestly* — the skill ships the contract + the honest-gap
path, not bundled paid keys or scraped data. It NEVER fabricates property data.

Independence: does NOT modify Skill 38 core, Skill 29, Skill 19, or Skill 36. The
Sales-Brain RE extension is installed ADDITIVELY (drop-in file only).
