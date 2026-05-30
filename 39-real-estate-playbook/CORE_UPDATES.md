# Skill 39 — Core File Updates

What Skill 39 changes in the client agent's core files. Everything is ADDITIVE
and marker-fenced; nothing existing is overwritten.

## AGENTS.md (additive, marker-fenced)

`scripts/04-update-agents-md.sh` appends ONE block between:

```
<!-- BEGIN SKILL39: REAL_ESTATE_PLAYBOOK -->
... real-estate playbook routing + the NEVER-FABRICATE rule + the 4 ZHC tags ...
<!-- END SKILL39: REAL_ESTATE_PLAYBOOK -->
```

Re-running the script refreshes the block IN PLACE (idempotent) — it never
appends a second copy. No other AGENTS.md content is touched.

## Skill 38 Sales-Brain extension (additive overlay — Skill 38 core untouched)

`scripts/05-install-sales-brain-extension.sh` drops ONE file:

```
38-conversational-ai-system/protocols/extensions/real-estate-sales-brain.md
```

Skill 38's Sales-Brain reads every `*.md` under `protocols/extensions/` as an
additive overlay. This is the documented HOOK: Skill 39 extends Skill 38's
Sales-Brain WITHOUT editing any Skill 38 core protocol file. The overlay carries:
- RE objection patterns (rates, Zillow estimate, overpricing, FSBO, commission),
- the CMA pricing-reveal TIMING rule (reveal only after motivation + comps),
- the SPICED-RE discovery frame.

If Skill 38's `protocols/extensions/` folder does not exist (older Skill 38), the
script creates ONLY that subfolder and drops the file. The Skill 38 core is never
modified — verified by the independence category of `../QC-PROTOCOL.md`.

## TOOLS.md / MEMORY.md
Skill 39 does NOT modify TOOLS.md or MEMORY.md directly. The operator's specialty
map for lead routing (if any) lives in TOOLS.md and is operator-maintained; the
skill ships no roster.

## Tags created in GHL (operator action, not a file edit)
`ZHC-buyer-lead`, `ZHC-seller-lead`, `ZHC-investor-lead`,
`ZHC-pre-foreclosure-prospect` — create in GHL Settings → Tags FIRST.
