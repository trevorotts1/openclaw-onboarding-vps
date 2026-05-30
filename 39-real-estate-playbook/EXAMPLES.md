# Skill 39 — Examples

Worked examples. All addresses are GENERIC/fictional — no real client data.

## 1. Property lookup with mixed availability
```bash
$ scripts/03-property-lookup.sh --address "123 Main St, Springfield, IL 62701"
=== [skill 39] property lookup ===
  input:      123 Main St, Springfield, IL 62701
  normalized: street='123 Main St' city='Springfield' state='IL' zip='62701'

  [property_lookup] AVAILABLE — issue the provider request (see references/property-providers.md → property_lookup).
  [geocode] AVAILABLE — issue the provider request (see references/property-providers.md → geocode).
  [street_view] HONEST GAP — say to the lead/operator, verbatim:
      "I don't have a live data source connected for street_view on this property.
       I will not guess. Add a provider key (02-configure-providers.sh) and I'll pull it."
  [comps] HONEST GAP — say to the lead/operator, verbatim:
      "I don't have a live data source connected for comps on this property.
       I will not guess. Add a provider key (02-configure-providers.sh) and I'll pull it."

  F52 event appended: <MASTER_FILES_DIR>/real-estate-events.jsonl
```

## 2. Buyer qualification (conversational, not a form)
> **Lead:** "Hi, I'm looking for a 3-bed near downtown."
> **Agent:** "Love it — happy to help. When are you hoping to be in your new
> place? And will you be financing or paying cash?" *(timeline + financing)*
> ... *(neighborhood, must-haves, budget range)* ...
>
> Agent tags the contact `ZHC-buyer-lead`, routes per the specialty map.

## 3. Seller asks "what's my home worth?"
> **Agent:** runs `03-property-lookup.sh --address "..." --want comps`.
> If comps are an HONEST GAP: "I don't have a live comps source connected yet, so
> I won't guess at a number. I can run a manual CMA, or we can add a comps
> provider and I'll pull it instantly. Which would you prefer?"
>
> CMA pricing-reveal timing (Sales-Brain RE extension): acknowledge their number
> → present comps → let the data speak → land on a range. Never anchor first.

## 4. Pre-foreclosure (pairs with Skill 40)
> Skill 40 emits a public NOD record for a property. Skill 39 tags the homeowner
> `ZHC-pre-foreclosure-prospect` and uses the compliant, empathetic template:
> "Public records indicate a notice of default was filed on <date>. I may be
> wrong — I'd like to understand your situation and the options you may have."
> NEVER pressure, NEVER imply the agent is the lender/government.

## 5. The F52 event line
```json
{"ts":"2026-05-30T14:03:21Z","skill":"39-real-estate-playbook","event":"property_lookup","address":"123 Main St, Springfield, IL 62701","normalized":{"street":"123 Main St","city":"Springfield","state":"IL","zip":"62701"},"capabilities":{"property_lookup":"AVAILABLE","geocode":"AVAILABLE","street_view":"HONEST_GAP","comps":"HONEST_GAP"},"available":2,"honest_gaps":2}
```
