# Pre-Foreclosure Outreach Protocol (Skill 39)

Sensitive, compliance-bound outreach to homeowners in distress (notice of
default / NOD, tax delinquency, lis pendens). Pairs with **Skill 40 (ZHC Public
Records Scraper)**, which sources the pre-foreclosure / NOD / tax-delinquency
signals. Tag matched prospects `ZHC-pre-foreclosure-prospect`.

## Where the data comes from
This protocol does NOT scrape anything itself. It consumes signals that Skill 40
produced from PUBLIC records (NOD filings, tax-delinquency lists). If Skill 40 is
not installed or a county is an HONEST GAP, there is NO prospect list — the agent
says so and does not fabricate leads.

## Hard compliance rules (the agent MUST follow)
1. **Respect DNC + consent** — do NOT cold-text or cold-call numbers without a
   lawful basis. SMS in particular is heavily regulated (TCPA). Route channel
   choice to the operator's compliant configuration; default to mail / the
   operator's approved channel.
2. **Tone: help, not predation** — the messaging frame is empathetic and
   options-oriented (the homeowner may have options: reinstatement, sale,
   short sale, loan modification). NEVER pressure, NEVER imply the agent is from
   the lender or government, NEVER promise to "stop the foreclosure."
3. **No legal/financial advice** — the agent surfaces that the homeowner should
   speak with a HUD-approved housing counselor / attorney, and offers to help
   explore a sale if that's the homeowner's choice.
4. **Honor opt-out immediately** and suppress the contact.

## Flow
1. Skill 40 emits matched pre-foreclosure / tax-delinquency records (public).
2. Each becomes a prospect tagged `ZHC-pre-foreclosure-prospect`.
3. Outreach uses the operator's approved channel + a compliant, empathetic
   template (humanized via Skill 19).
4. Interested homeowners convert to `ZHC-seller-lead` and follow the seller
   qualification protocol (handled with extra care).

## Logging
Each outreach + any property lookup logs to
`<MASTER_FILES_DIR>/real-estate-events.jsonl`. The public-records provenance
(source + timestamp) for each prospect is carried by Skill 40's own
`public-records-queries.jsonl` — the two logs are complementary.

## Honesty floor
If the agent cannot verify a homeowner's situation from public records, it does
NOT assert it. "Public records indicate a notice of default was filed on
<date>; I may be wrong — I'd like to understand your situation" is the frame.
