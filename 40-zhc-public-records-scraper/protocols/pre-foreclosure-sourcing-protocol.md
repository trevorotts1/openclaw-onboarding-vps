# Pre-Foreclosure Sourcing Protocol (Skill 40)

How Skill 40 sources pre-foreclosure / distressed-property signals from PUBLIC
records, feeding Skill 39's pre-foreclosure outreach protocol.

## Signals (all from public records)
- **Notice of Default (NOD)** — recorded in the county recorder/official-records.
- **Lis pendens** — recorded notice of a pending lawsuit (judicial-foreclosure
  states).
- **Notice of Trustee Sale / Notice of Sale** — recorder.
- **Tax delinquency** — county tax/treasurer delinquent list.

## Flow
1. Route the query through `02-detect-and-route.sh` with `--record-type recorder`
   (NOD/lis pendens) or `--record-type tax` (delinquency).
2. If Tier 1/2/3 resolves, the agent fetches LIVE per the plan (robots.txt + ToS
   respected; source + timestamp attributed).
3. Matched distressed properties become prospects. Hand to Skill 39 (tag
   `ZHC-pre-foreclosure-prospect`); Skill 39's pre-foreclosure outreach protocol
   governs the compliant, empathetic outreach.
4. If Tier 4 (no source / blocked / not online), there is NO list. Say so. Do NOT
   fabricate distressed-property leads.

## Compliance + ethics
- Pre-foreclosure data is sensitive. Sourcing it from PUBLIC records is lawful;
  USING it for outreach is governed by Skill 39's compliance rules (DNC/TCPA,
  empathetic tone, no impersonation of the lender/government, immediate opt-out).
- Attribute provenance: every prospect carries the public-record source +
  retrieval timestamp from `public-records-queries.jsonl`.

## Cost + rate
Bulk distressed-list pulls are exactly where the cost estimate + rate limits
matter. Use `--bulk N`; the router prints the estimate and HOLDS for operator
confirmation past the caps.
