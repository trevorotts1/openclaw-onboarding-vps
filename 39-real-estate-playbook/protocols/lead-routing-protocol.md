# Lead Routing by Agent Specialty Protocol (Skill 39)

Routes an inbound RE lead to the right human agent (or queue) based on lead type
and specialty. Universal — the operator configures their own specialty map.

## Specialty dimensions
- **Lead type** — buyer / seller / investor / pre-foreclosure / relocation.
- **Geography** — area, ZIP, or farm.
- **Tier** — standard / luxury (price threshold operator-defined).
- **Language** — if the operator's team is multilingual.

## How routing works
1. The lead is qualified (buyer/seller/investor protocols) and tagged with the
   matching `ZHC-*-lead` tag.
2. The agent reads the operator's specialty map (a simple operator-maintained
   table in the client's TOOLS.md or a GHL custom field — the operator supplies
   it; the skill ships NO roster).
3. The lead is assigned to the matching agent/queue via GHL (owner assignment /
   round-robin / specialty pool), routed through Skill 36 MCP when present, else
   Skill 29 REST.

## No roster shipped
This skill is UNIVERSAL and ships ZERO agent names or contact data. The operator
defines their own specialty map at install/runtime. If no map is configured, the
default behavior is "route to the operator" and surface that no specialty map is
set yet — never invent an assignee.

## Logging
Routing decisions are reflected in GHL (the system of record for assignment).
Property interactions during qualification log to
`<MASTER_FILES_DIR>/real-estate-events.jsonl`.
