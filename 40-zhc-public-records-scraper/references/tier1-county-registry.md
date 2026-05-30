# Tier 1 — Curated County Registry (Skill 40)

The Tier 1 curated registry: major U.S. counties with a known public-records
portal. Each entry carries the official portal domain(s), the record types the
portal exposes, and a `verified` flag (whether the domain was confirmed against
the county's own site during authoring). The auto-detect router
(`scripts/02-detect-and-route.sh`) reads this registry to decide Tier 1 vs the
adapter/config/honest-gap fallbacks.

HONESTY: portal URLs and even whether records are online change over time. The
router NEVER assumes a record exists. It points the agent at the verified portal
and the agent fetches LIVE; if the portal is unreachable, blocked, or the record
isn't online, the result is a Tier 4 HONEST GAP — never a fabricated record.

The machine-readable copy is `tier1-county-registry.tsv` (same data, tab-
separated: `state<TAB>county<TAB>domain<TAB>record_types<TAB>verified<TAB>note`).
Keep the two in sync.

## Registry (20 counties)

| State | County | Official portal domain(s) | Record types | Verified |
|---|---|---|---|---|
| IL | Cook | cookcountyassessor.com ; cookcountyclerkil.gov ; cookcountypropertyinfo.com | assessor, recorder, tax | partial (recorder merged into clerk) |
| CA | Los Angeles | portal.assessor.lacounty.gov ; assessor.lacounty.gov | assessor, parcel | yes |
| AZ | Maricopa | mcassessor.maricopa.gov ; recorder.maricopa.gov | assessor, recorder | yes |
| TX | Harris | hcad.org ; search.hcad.org ; public.hcad.org/records | appraisal, tax | yes |
| CA | San Diego | sdarcc.gov ; arcc-acclaim.sdcounty.ca.gov | assessor, recorder, official-records | yes |
| CA | Orange | ocrecorder.com ; cr.ocgov.com/recorderworks | recorder, grantor-grantee | yes |
| NY | Kings (Brooklyn) | a836-acris.nyc.gov ; www1.nyc.gov/site/finance | acris-recorder, tax | partial (NYC ACRIS citywide) |
| CA | Riverside | rivcoacr.org ; asrclkrec.com | assessor, recorder | partial |
| CA | San Bernardino | sbcounty.gov/arc | assessor, recorder | partial |
| WA | King | kingcounty.gov/depts/assessor ; blue.kingcounty.com/Assessor/eRealProperty | assessor, parcel | partial |
| NV | Clark | clarkcountynv.gov/assessor ; recorder.clarkcountynv.gov | assessor, recorder | partial |
| FL | Miami-Dade | miamidade.gov/pa ; onlineservices.miamidadeclerk.gov | property-appraiser, recorder | partial |
| TX | Dallas | dallascad.org ; dallascounty.org/government/county-clerk | appraisal, recorder | partial |
| TX | Tarrant | tad.org ; tarrantcounty.com/en/county-clerk | appraisal, recorder | partial |
| TX | Bexar | bcad.org ; gov.propertyinfo.com/tx-bexar | appraisal, recorder | partial |
| FL | Broward | bcpa.net ; officialrecords.broward.org | property-appraiser, official-records | partial |
| CA | Sacramento | assessor.saccounty.gov ; erecord.saccounty.gov | assessor, recorder | partial |
| CA | Santa Clara | sccassessor.org ; clerkrecorder.sccgov.org | assessor, recorder | partial |
| FL | Hillsborough | hcpafl.org ; pubrec3.hillsclerk.com | property-appraiser, official-records | partial |
| WA | Pierce | piercecountywa.gov/atr ; armsweb.co.pierce.wa.us | assessor-treasurer, recorder | partial |

## What "verified" / "partial" mean here
- **yes** — the official domain was confirmed against the county's own website at
  authoring time.
- **partial** — the domain follows the county's known official pattern but the
  exact record-search subpath should be confirmed live (the agent navigates from
  the listed domain). Treat record presence as LIVE-checked, never assumed.

## Record types vocabulary
- `assessor` / `property-appraiser` / `appraisal` — assessed value, characteristics, ownership of record
- `recorder` / `official-records` / `acris-recorder` / `grantor-grantee` — deeds, mortgages, liens, NOD/lis-pendens
- `tax` — tax bills + delinquency
- `parcel` — parcel maps / GIS

## Real-estate use-case mapping
- **Pre-foreclosure / NOD / lis pendens** → recorder/official-records search
- **Tax delinquency** → tax search
- **Comps / ownership** → assessor/appraisal search
- **Permits** → many counties expose these via the assessor or a separate
  building-dept portal (often a Tier 3 operator-config target)

## Adding / correcting a county
Edit BOTH `tier1-county-registry.md` and `tier1-county-registry.tsv`. Set
`verified` honestly. The router re-reads the TSV on every run — no code change
needed to add a county.
