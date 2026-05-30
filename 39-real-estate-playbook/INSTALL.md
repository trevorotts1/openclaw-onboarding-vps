# Skill 39 — Real Estate Playbook & Property Intelligence: Install Guide

## What this installs

The real-estate vertical brain on top of Skill 38 (Conversational AI System) and
Skill 29 (GHL Convert and Flow):

- 7 protocols (buyer qualification, seller qualification, showing scheduler,
  state disclosure compliance, lead routing by specialty, open-house automation,
  pre-foreclosure outreach).
- 6 scripts (`00`–`05` + `qc-no-personal-data.sh`), idempotent and OS-aware
  (Darwin + Linux).
- 3 references (property-provider abstraction, the additive Sales-Brain RE
  extension, the F52 `real-estate-events.jsonl` event contract).
- One ADDITIVE, marker-fenced AGENTS.md block.
- The ADDITIVE Sales-Brain RE extension dropped into Skill 38's
  `protocols/extensions/` (Skill 38 core is never modified).
- The 4 RE tags: `ZHC-buyer-lead`, `ZHC-seller-lead`, `ZHC-investor-lead`,
  `ZHC-pre-foreclosure-prospect`.

## Prerequisites

This skill checks (and HALTS on a missing HARD prerequisite) via
`scripts/00-verify-prerequisites.sh`. It NEVER auto-installs or modifies a
sibling skill.

- **HARD: Skill 29 — GHL Convert and Flow** (lead routing + tag writes).
- **HARD: Skill 38 — Conversational AI System** (the Sales-Brain core).
- SOFT: Skill 19 — Humanizer (outbound tone; graceful degrade if absent).
- SOFT: Skill 36 — GHL MCP Setup (preferred GHL access; falls back to Skill 29).

Property-data provider keys are OPTIONAL and operator-supplied. Their absence is
an HONEST capability gap, never a hard failure (the skill never fabricates data).

## Install order (run in this order; each is idempotent)

```bash
cd ~/.openclaw/skills/39-real-estate-playbook/scripts   # macOS
# (VPS: cd /data/.openclaw/skills/39-real-estate-playbook/scripts)

./00-verify-prerequisites.sh          # HARD: 29 + 38 present; SOFT: 19 + 36
./01-locate-master-files-folder.sh    # resolve <MASTER_FILES_DIR> (reuses Skill 38's)
./02-configure-providers.sh           # provider abstraction + key discovery → status JSON
./04-update-agents-md.sh              # ADDITIVE marker-fenced AGENTS.md block
./05-install-sales-brain-extension.sh # ADDITIVE Sales-Brain RE overlay into Skill 38
```

`03-property-lookup.sh` is the RUNTIME worker, not an install step — the agent
calls it per property at runtime:

```bash
./03-property-lookup.sh --address "123 Main St, Springfield, IL 62701"
```

## QC

```bash
./qc-no-personal-data.sh   # universal-skill identifier guard + required-tag invariant
```

This skill is governed by `../QC-PROTOCOL.md`. The full 10-category rubric
(8.5 threshold) is run before any PR.

## OS support

`darwin` (Mac operators) and `linux` (VPS operators). All scripts detect OS via
`uname -s`:
- **Darwin:** `$HOME/.openclaw/`, master files under `~/Downloads`/`~/Documents`/…
- **Linux:** `/data/.openclaw/`, master files under `/data`

## What this does NOT do
- Does NOT install or modify Skills 29, 38, 19, 36.
- Does NOT ship provider keys, scraped property data, or any agent roster.
- Does NOT fabricate property data.
- Does NOT render legal advice (disclosure compliance is a pointer).
- Does NOT scrape public records (that is Skill 40).

## Where to read next
- `INSTRUCTIONS.md` — the operator + runtime walkthrough.
- `references/property-providers.md` — how to add each provider key.
- `references/master-files-event-contract-F52.md` — the event-log schema.
