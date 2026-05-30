# Open House Automation Protocol (Skill 39)

Automates the open-house lifecycle: pre-event promotion, day-of sign-in capture,
and post-event follow-up. Universal — works for any listing.

## Phases
1. **Pre-event** — schedule reminder messages to the operator's farm / interested
   buyers (timeline, address, date/time). Sent through the operator's normal
   channels (humanized via Skill 19).
2. **Sign-in capture** — when a visitor signs in (GHL form / digital sign-in),
   the contact is created/updated in GHL and tagged `ZHC-buyer-lead` (or
   `ZHC-investor-lead` on investor signal). The agent does NOT fabricate
   visitor data — only what the visitor actually provides.
3. **Post-event follow-up** — within the operator's chosen window, the agent
   sends a personalized follow-up (thanks for visiting + next step) using
   Skill 38's follow-up cadence. Visitors who showed strong interest are flagged
   for the listing agent.

## Showing-rule respect
The open house itself still respects the listing's MLS + access rules
(`showing-scheduler-protocol.md`).

## Logging
The open house is recorded as a `showing` event (subtype open_house) per visitor
interaction in `<MASTER_FILES_DIR>/real-estate-events.jsonl`. No PII beyond the
existing GHL contact reference is written to the event log.

## Handoff
Cadence + send mechanics come from Skill 38; tone from Skill 19; GHL ops via
Skill 36 (preferred) or Skill 29 (fallback). This protocol orchestrates, it does
not duplicate those.
