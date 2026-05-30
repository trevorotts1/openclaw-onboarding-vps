# Showing Scheduler Protocol (Skill 39)

How the agent schedules a property showing, respecting lockbox and MLS rules.

## Inputs needed
- Property address (normalize via `scripts/03-property-lookup.sh`).
- Requesting party (buyer + buyer's agent if any).
- Proposed date/time window.

## Rules the agent MUST respect
1. **MLS showing instructions** — many listings carry MLS showing instructions
   (appointment required, 24-hour notice, courtesy call, tenant-occupied
   restrictions, pet/alarm notes). The agent surfaces these BEFORE confirming.
   If the MLS capability is an HONEST GAP, the agent says it cannot read live MLS
   showing instructions and asks the listing agent — it does NOT assume "go
   ahead."
2. **Lockbox / access** — note the access method (electronic lockbox / combo /
   listing-agent-accompanied / appointment service). Never share a lockbox code
   in a public/unsecured channel.
3. **Occupied properties** — owner- or tenant-occupied homes require advance
   notice per local law and MLS rules; confirm the notice window.
4. **Double-booking** — check the operator's calendar (Skill 38 calendar sync /
   GHL calendar) before confirming a slot.

## Booking
Use the operator's existing GHL / OpenClaw calendar tooling (Skill 38's calendar
helpers, or Skill 29 appointment endpoints). This protocol does not implement its
own calendar — it standardizes the RE rules around the booking.

## Logging
Each confirmed showing logs a `showing` event to
`<MASTER_FILES_DIR>/real-estate-events.jsonl` (address, date/time, requesting
party) per the F52 master-files event contract.

## Confirmation message
Send via the agent's normal channel (humanized, Skill 19). Include the date,
time, address, and any access/notice notes — never a lockbox code in plain text.
