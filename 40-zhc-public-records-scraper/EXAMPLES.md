# Skill 40 — Examples

Worked examples. All addresses are GENERIC/fictional — no real client data.
County names + government portal domains are PUBLIC reference data.

## 1. Tier 1 hit (curated county)
```bash
$ scripts/02-detect-and-route.sh --county "Maricopa" --state AZ --record-type recorder
=== [skill 40] public-records router ===
  query:       address='' county='Maricopa' state='AZ' zip=''
  record-type: recorder
  TIER:        1
  target:      mcassessor.maricopa.gov;recorder.maricopa.gov
  cache:       (miss)
  rate:        today=0/200  target=0/50
  cost est:    $0.00 for 1 query(ies) (cap $5.00/day)
  F52 event appended: <MASTER_FILES_DIR>/public-records-queries.jsonl

  PLAN: Tier 1 curated: navigate mcassessor.maricopa.gov;recorder.maricopa.gov for a 'recorder' search ...
```

## 2. Tier 4 honest gap (county not wired)
```bash
$ scripts/02-detect-and-route.sh --county "Smallville" --state KS --record-type recorder
  TIER:        4
  PLAN: Tier 4 HONEST GAP: no curated scraper, no matching adapter, and no validated
        operator config for county='Smallville' state='KS'. Tell the operator: I don't
        have a public-records source wired for this jurisdiction. I will NOT fabricate
        a record. Options: (a) supply the county..., (b) build a Tier 3 config..., (c)
        accept that records may not be online here.
```

## 3. Tier 2 adapter coverage (operator-confirmed)
```bash
$ scripts/adapters/tyler-technologies.sh --vendor
Tyler Technologies (Eagle / EagleWeb land records)

# coverage is EMPTY by default — operator confirms a county:
$ SKILL40_TYLER_COVERAGE="travis:TX" scripts/adapters/tyler-technologies.sh --covers "Travis" TX ; echo $?
0
$ scripts/adapters/tyler-technologies.sh --covers "Travis" TX ; echo $?   # no coverage set
1
```

## 4. Tier 3 config build + validate
```bash
$ scripts/03-build-scraper-config.sh --county "Travis" --state TX
=== [skill 40] Tier 3 draft scaffolded ===
  draft: <MASTER_FILES_DIR>/.skill-40-scraper-configs/tx-travis.draft.conf
# edit BASE_URL / selectors / set ROBOTS_OK=1, then:
$ scripts/03-build-scraper-config.sh --from <...>/tx-travis.draft.conf
  ✓ VALID — promoted (Tier 3 active for Travis, TX)
# an invalid config is NEVER promoted (stays Tier 4 honest gap)
```

## 5. Rate / cost hold on a bulk op
```bash
$ SKILL40_COST_PER_QUERY_USD=0.10 scripts/02-detect-and-route.sh --county "Harris" --state TX --bulk 100
  cost est:    $10.00 for 100 query(ies) (cap $5.00/day)
  ⚠️  HOLD: estimated cost $10.00 exceeds daily cap $5.00
      Operator confirmation required before proceeding ...
```

## 6. The F52 event line
```json
{"ts":"2026-05-30T14:10:02Z","date":"2026-05-30","skill":"40-zhc-public-records-scraper","event":"records_query","address":"","county":"Maricopa","state":"AZ","zip":"","record_type":"recorder","tier":1,"target":"mcassessor.maricopa.gov;recorder.maricopa.gov","cache_hit":false,"queries_today":0,"est_cost_usd":"0.00","blocked":false}
```
