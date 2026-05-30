# Skill 40 — ZHC Public Records Scraper: Instructions

The operator + runtime walkthrough. Read SKILL.md and INSTALL.md first.

## Phase 0 — Prerequisites + folder
1. `scripts/00-verify-prerequisites.sh` — confirms `curl` (HARD); reports a
   browser fetch path + Skill 39 (SOFT). Always prints the compliance reminder.
2. `scripts/01-locate-master-files-folder.sh` — resolves `<MASTER_FILES_DIR>`
   (reuses Skill 38/39's selection). This is where the query log, the 30-day
   cache, and any Tier 3 configs live.

## Phase 1 — Wire the brain
3. `scripts/04-update-agents-md.sh` — appends ONE additive, marker-fenced block
   to AGENTS.md (the tier model + compliance + honest-gap discipline). Idempotent
   (re-running refreshes in place).

## Runtime — the router

```bash
scripts/02-detect-and-route.sh --address "123 Main St, Phoenix, AZ 85003" --record-type recorder
```

The router:
1. **Auto-detects** county + state (and ZIP) from the query. (County is not
   guessed from a city — pass `--county` if it can't be resolved; an unresolved
   county simply routes to Tier 4 honest gap.)
2. **Decides the tier:**
   - **Tier 1** if the county is in `references/tier1-county-registry.tsv` →
     emits a plan pointing at the verified portal + record type to fetch LIVE.
   - **Tier 2** if a `scripts/adapters/*.sh` adapter `--covers` the county →
     emits the vendor adapter's plan.
   - **Tier 3** if a VALIDATED operator config exists for the county →
     emits the config-driven plan.
   - **Tier 4 — HONEST GAP** otherwise → tells the operator plainly; NEVER
     fabricates a record.
3. **Checks the 30-day cache** (`--force-refresh` to bypass). A cache HIT returns
   the cached plan with no live fetch.
4. **Enforces rate limits + the cost cap** and prints a **cost estimate**. Past a
   cap (or for `--bulk N`), it HOLDS and asks for operator confirmation.
5. **Emits one F52 event** to `<MASTER_FILES_DIR>/public-records-queries.jsonl`.

The agent then EXECUTES the emitted plan LIVE (curl/browser), respecting
robots.txt + ToS, attributing source + timestamp. The router routes + logs; the
agent fetches.

### Record types
`recorder` (deeds/NOD/lis pendens), `assessor` (ownership/value/comps), `tax`
(bills/delinquency), `parcel` (GIS), `permits` (often Tier 3/4). See
`protocols/record-type-routing-protocol.md`.

## Tier 2 — add an adapter
A Tier 2 adapter covers a whole VENDOR (many counties). Two ship as examples
(Tyler, GovOS). To author a new one, follow
`protocols/adapter-authoring-protocol.md` (copy an example, change VENDOR +
coverage + `--plan`). Coverage is operator-confirmed and EMPTY by default — set
e.g. `SKILL40_TYLER_COVERAGE="travis:TX"` once you've CONFIRMED that county runs
on Tyler.

## Tier 3 — build a county config
For a county with no T1 entry and no T2 adapter:
```bash
scripts/03-build-scraper-config.sh --county "Travis" --state TX   # scaffolds a draft
# edit the draft (BASE_URL / SEARCH_PARAM / RESULT_SELECTOR / set ROBOTS_OK=1)
scripts/03-build-scraper-config.sh --from "<MASTER_FILES_DIR>/.skill-40-scraper-configs/tx-travis.draft.conf"
```
The config is VALIDATED (well-formed URL, robots.txt not disallowing the path,
required keys present, ROBOTS_OK attestation) BEFORE it is promoted. Only a
VALIDATED config is used by the router. An invalid config never goes live and the
county stays Tier 4 (honest gap) — never fabrication.

## Tier 4 — honest gap
When the router returns Tier 4, the agent says (verbatim intent): "I don't have a
public-records source wired for this jurisdiction. I will not fabricate a record."
Then offers: supply the county, build a Tier 3 config, or accept records may not
be online there.

## Pre-foreclosure pairing (Skill 39)
Use `--record-type recorder` (NOD/lis pendens) or `--record-type tax`
(delinquency). Matched distressed properties feed Skill 39's pre-foreclosure
outreach protocol (tag `ZHC-pre-foreclosure-prospect`). See
`protocols/pre-foreclosure-sourcing-protocol.md`. If Skill 40 returns Tier 4,
there is NO list — say so.

## The F52 event log
Every query (including cache hits and honest gaps) logs one JSONL line to
`<MASTER_FILES_DIR>/public-records-queries.jsonl`. Schema:
`references/master-files-event-contract-F52.md`. The `date` field also powers the
per-day rate-limit + cost counters.

## QC before declaring done
Run `scripts/qc-no-personal-data.sh` and the full `../QC-PROTOCOL.md` rubric.
Below 8.5 → fix and loop.
