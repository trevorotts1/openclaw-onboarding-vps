# Skill 39 — Real Estate Playbook & Property Intelligence: Instructions

The operator + runtime walkthrough. Skill 39 adds a real-estate vertical brain on
top of Skill 38 (Conversational AI System). Read SKILL.md and INSTALL.md first.

## Phase 0 — Prerequisites + folder

1. `scripts/00-verify-prerequisites.sh` — confirms Skills 29 + 38 are present
   (HARD) and reports Skills 19 + 36 (SOFT). HALTS on a missing hard
   prerequisite, naming it. It NEVER auto-installs a sibling.
2. `scripts/01-locate-master-files-folder.sh` — resolves `<MASTER_FILES_DIR>`.
   It reuses Skill 38's selection if present, so both skills write under the
   same folder. This is where `real-estate-events.jsonl` lands.

## Phase 1 — Providers (the honest-gap foundation)

3. `scripts/02-configure-providers.sh` — scans the operator's standard env
   locations for provider keys and writes
   `<MASTER_FILES_DIR>/.skill-39-provider-status.json`, marking each capability
   (`property_lookup`, `mls`, `geocode`, `street_view`, `comps`) as AVAILABLE or
   HONEST_GAP.

   **The honest-gap discipline is the heart of this skill.** A capability with no
   configured key is NOT an error and is NOT worked around. At runtime, the agent
   says plainly: "I don't have a live data source connected for `<capability>` on
   this property. I will not guess." The operator can add a key any time (see
   `references/property-providers.md`) and re-run this script.

   Keys are OPTIONAL and operator-supplied. The skill ships ZERO keys and ZERO
   scraped data. MLS in particular is licensed per-operator (RESO Web API / IDX
   vendor) — supply the licensed token; the skill provides only the contract.

## Phase 2 — Wire the brain

4. `scripts/04-update-agents-md.sh` — appends ONE additive, marker-fenced block
   to the client agent's AGENTS.md telling the runtime WHEN to use the RE
   playbook, WHERE the tools live, and the NEVER-FABRICATE rule. Idempotent
   (re-running refreshes the block in place, never duplicates it).
5. `scripts/05-install-sales-brain-extension.sh` — installs the ADDITIVE RE
   Sales-Brain overlay into Skill 38's `protocols/extensions/` folder. This is a
   drop-in file (`real-estate-sales-brain.md`) carrying the RE objection
   patterns, the CMA pricing-reveal timing rule, and the SPICED-RE discovery
   frame. **Skill 38's core protocol files are never modified.** If Skill 38's
   `extensions/` folder doesn't exist yet, the script creates ONLY that subfolder.

## Phase 3 — Create the GHL tags

Create these tags in GHL FIRST (Settings → Tags) before any workflow filters on
them (a blank/non-existent tag in a "does not contain" filter is a known GHL
gotcha):
- `ZHC-buyer-lead`
- `ZHC-seller-lead`
- `ZHC-investor-lead`
- `ZHC-pre-foreclosure-prospect`

## Runtime — how the agent uses the skill

### Property lookup
```bash
scripts/03-property-lookup.sh --address "123 Main St, Springfield, IL 62701"
```
The script normalizes the address, resolves which capabilities are AVAILABLE,
prints the provider request shape for each AVAILABLE capability (the agent issues
the network call through its configured tool/MCP), prints the honest-gap line for
each gap, and appends a `property_lookup` event to
`<MASTER_FILES_DIR>/real-estate-events.jsonl`.

Limit capabilities with `--want comps,street_view`. Add `--json` for a compact
result. Add `--no-log` to skip the event append (testing only).

### Qualification
- Buyer intent → `protocols/buyer-qualification-protocol.md`, tag
  `ZHC-buyer-lead` (+ `ZHC-investor-lead` on investor signal).
- Seller intent → `protocols/seller-qualification-protocol.md`, tag
  `ZHC-seller-lead`; CMA via `03-property-lookup.sh --want comps`.

### Showings + open houses
- `protocols/showing-scheduler-protocol.md` (lockbox + MLS rules; never share a
  lockbox code in plain text).
- `protocols/open-house-automation-protocol.md` (promotion → sign-in → follow-up).

### Disclosure + routing
- `protocols/disclosure-compliance-protocol.md` (pointer, not legal advice;
  always surface lead-based paint for pre-1978 homes).
- `protocols/lead-routing-protocol.md` (operator-supplied specialty map; never
  invent an assignee).

### Pre-foreclosure (pairs with Skill 40)
- `protocols/pre-foreclosure-outreach-protocol.md`. Skill 40 sources the public
  NOD / tax-delinquency signals; this protocol does the compliant, empathetic
  outreach. Tag `ZHC-pre-foreclosure-prospect`. If Skill 40 is absent or a county
  is an honest gap, there is NO prospect list — say so, don't fabricate.

## The F52 event log
Every property lookup, showing, and CMA request emits one JSONL line to
`<MASTER_FILES_DIR>/real-estate-events.jsonl`. Schema:
`references/master-files-event-contract-F52.md`. The log carries property
interactions, not client PII beyond the entered address.

## QC before declaring done
Run `scripts/qc-no-personal-data.sh` and the full `../QC-PROTOCOL.md` rubric.
Below 8.5 → fix and loop.
