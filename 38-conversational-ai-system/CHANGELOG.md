# Skill 38 — Conversational AI System: Changelog

## [1.4.0] - 2026-05-28 - GHL inbound hardening: Build-with-AI prompt, 4-token model, verified APIs, calendar-sync

### Why
Debugging a live client (Corey, Hostinger Docker VPS) surfaced a cluster of repeatable failures that
every future VPS client would otherwise hit: the four secrets in this system kept getting confused;
`deliver: true` on GHL API-reply hooks silently broke replies; the `cron.jobs` JSON format stopped
validating on current openclaw; the VPS wrapper resets `hooks.token` on every boot; and there was no
authoritative reference for the one-tunnel-many-hooks model, the Build-with-AI prompt (GHL's only
programmatic automation-build path), the verified channel→type enum, or the verified Calendar API.

### Added
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` (NEW) — the authoritative reference. Contains: the 4-token
  table (CF API token vs tunnel connector token vs HOOKS_TOKEN vs GHL PIT, with VPS specifics); the
  one-tunnel-many-hooks model (created once, reused; new automations = new hook paths, never recreate
  the tunnel); the copy-paste **Build-with-AI prompt** template (the only programmatic way to build a
  GHL automation) with placeholders; the post-build **verification checklist** (incl. the "GHL Test
  button sends empty merge fields → verify with a real inbound" gotcha); the **Reusable Tunnel Values**
  storage rule (AGENTS.md + TOOLS.md + client Notion, every time); the **one-value-per-key** JSON rule;
  the **verified channel→type enum** (SMS/Email/FB/IG/WhatsApp/Live_Chat valid; TikTok/Call/GMB and
  long-forms invalid); the GHL Conversations reply recipe + the verified Calendar recipe (free-slots is
  epoch-millis; book requires calendarId/locationId/contactId/startTime, endTime optional); and the
  ready **first conversation playbook = appointment booking** Layer 2 template.
- `scripts/skill38-calendar-sync.sh` (NEW) — weekly GHL calendar refresh. Maintains a
  `<!-- GHL_CALENDARS_START/END -->` marker block in TOOLS.md (adds new calendars, removes deleted).
  Generic across clients; reads PIT + GHL_LOCATION_ID from the client env file. Registered via
  `openclaw cron add` (Sunday 9am).

### Changed (surgical edits to `references/v5.14-source-playbook.md`)
- **Step 3C / Step 3.5G:** `deliver: true` → `deliver: false` on the GHL inbound hooks mapping, with
  the corrected rationale (deliver:false for any hook that replies via an external API; deliver:true
  only to echo the agent's final text to its own bound channel).
- **Step 3A:** added the 4-token disambiguation (pointer to the new ref doc) and the VPS rule — set
  `OPENCLAW_HOOKS_TOKEN` in host-level `/docker/<project>/.env` (the `/hostinger/server.mjs` wrapper
  rewrites `hooks.token` every boot), then `docker compose up -d --force-recreate`.
- **All cron registrations** (conversation-log-summarizer, system-health-heartbeat, weekly-tune-up,
  proactive-suggestions-scan, monthly-comprehensive-review, plus the new calendar-sync): replaced the
  `cron.jobs` JSON and the old positional `cron add` form with the supported flag-based CLI
  (`openclaw cron add --name … --cron … --agent … --message … --light-context --best-effort-deliver`),
  noting the JSON format no longer validates.
- **Step 6:** the Build-with-AI prompt is now the PRIMARY workflow-build method; the 20-step
  hand-build is demoted to a clearly-labeled FALLBACK. The verification checklist is required even on
  success. Added the Reusable Tunnel Values section + the Notion-doc quality spec (Reusable Tunnel
  Values → Build-with-AI prompt per channel → verification checklist). The base SMS install also
  creates the first appointment-booking playbook and wires the hook path to it (day-one round-trip).
- **Step 9.19:** added the verified GHL Calendar API recipe + the calendar-sync install + Sunday cron.
- **Step 9.20 D.2:** renamed "Workflow AI prompt" → "Build-with-AI prompt" and noted it is the SAME
  generator used for the base onboarding automation in Step 6 (one generator, two call sites).
- **Rules of Engagement:** added Rule 7 — one value per key (proper JSON structure).
- Standardized the outbound cred var to `GHL_PRIVATE_INTEGRATION_TOKEN` and Version `2021-04-15`;
  added WhatsApp to the verified send-type table and the invalid-types list.

### Source of truth
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — authoritative for GHL inbound + playbooks (this release).
- `references/v5.14-source-playbook.md` — the canonical playbook (surgically updated, pointers added).

## [1.0.0] - 2026-05-28 - Initial release (packages v5.14 playbook)

### Why
Christy's v5.14 conversational AI playbook (~8,800 lines, 14 version iterations) packaged as
an installable skill. Builds the conversational AI BRAIN on top of skill 29 (GHL Convert and Flow).

### Added
- 27 protocol files (humanizer NOT included; skill 19 owns it)
- 8 customer journey templates (coach fully detailed; 7 stubbed)
- 9 idempotent + OS-aware install scripts (00 prerequisites → 08 Shopify wizard)
- 7 reference documents including the FULL v5.14 source playbook + strategic roadmap
- SKILL.md, INSTALL.md, INSTRUCTIONS.md, EXAMPLES.md, CORE_UPDATES.md
- AGENTS.md Steps 1.7, 1.8, 1.9, 2.8; upgraded Step 1.75
- MEMORY.md design rules 6-14
- 4 cron jobs (Sunday 2am tune-up, Saturday 11pm proactive + 11:30pm model freshness, 1st-of-month review)

### Source of truth
- `references/v5.14-source-playbook.md` — the canonical 8,797-line playbook
- `references/conversational-ai-strategic-roadmap.md` — strategic context (✅ shipped vs 📋 pending)

### Out of scope (DEFERRED, not in this skill)
- F14 Voice/Phone Integration
- F15 Proactive Outreach Campaigns
- F16 A/B Testing of Reply Variants
- F17 Customer Segmentation Awareness
- F18 Webhook Chaining
- F21 Multi-Tenant Agent Isolation

The skill's structure (numbered scripts, protocols/ folder, references/) leaves room for
these to be added later without restructuring.
