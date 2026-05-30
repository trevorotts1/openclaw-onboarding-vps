# Skill 40 — Core File Updates

What Skill 40 changes in the client agent's core files. Everything is ADDITIVE
and marker-fenced; nothing existing is overwritten.

## AGENTS.md (additive, marker-fenced)

`scripts/04-update-agents-md.sh` appends ONE block between:

```
<!-- BEGIN SKILL40: PUBLIC_RECORDS_SCRAPER -->
... tier model + auto-detect usage + compliance rules + NEVER-FABRICATE / honest-gap ...
<!-- END SKILL40: PUBLIC_RECORDS_SCRAPER -->
```

Re-running refreshes the block IN PLACE (idempotent) — never a second copy. No
other AGENTS.md content is touched.

## TOOLS.md / MEMORY.md
Skill 40 does NOT modify TOOLS.md or MEMORY.md.

## Master-files artifacts (written at runtime under <MASTER_FILES_DIR>)
- `public-records-queries.jsonl` — the F52 query event log.
- `public-records-cache/` — the 30-day result cache.
- `.skill-40-scraper-configs/` — operator-built Tier 3 configs.
- `.skill-40-master-files-dir` (under `~/.openclaw/`) — the resolved MFD pointer.

## Tags
Skill 40 itself creates no tags. Pre-foreclosure prospects it sources are tagged
by Skill 39 (`ZHC-pre-foreclosure-prospect`).
