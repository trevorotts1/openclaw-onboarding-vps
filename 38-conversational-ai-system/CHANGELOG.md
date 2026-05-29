# Skill 38 — Conversational AI System: Changelog

## [1.4.7] - 2026-05-29 - close the 2 QC gaps (trinity registry format + 23-key linter covers v6.0 playbook)

Closed the two remaining QC gaps so both machine-enforced linters reconcile against what the install
scripts actually produce — no silent no-ops, no unchecked corpora.

### Fixed
- **GAP 1 — trinity registry format mismatch.** `scripts/qc-trinity-registry.sh` parsed the
  conversation-workflows registry ONLY as a markdown TABLE, but
  `scripts/09-install-conversation-workflows.sh` writes the active-workflow list as BULLETS
  (`<workflow-id>: <one-line description>` under `## Active workflows`). On a real installed registry the
  reconciliation silently no-op'd. The validator now parses the **bullet form** as well as the table: each
  bullet's `<workflow-id>` is reconciled against `<id>.md` + `<id>--build-with-ai-prompt.md` on disk; a bullet
  with no Layer-1 column defaults to "Layer 1 needed" (prompt required) unless the description says
  `(uses existing inbound routing)` / `Layer 1: No`. Installer template and
  `protocols/conversation-workflows-protocol.md` §F updated so installer, validator, and docs agree end to end.
- **GAP 2 — 23-key linter blind to the v6.0 playbook (and to ```bash bodies elsewhere).**
  `scripts/qc-23-key-bodies.sh` explicitly excluded `references/v6.0-source-playbook.md` (~9,430 lines, the
  largest set of GHL RAW BODY examples) and its non-greedy fence regex desynced on mixed-language docs — it
  silently skipped real bodies inside ```bash fences (e.g. BOTH canonical bodies in
  `references/GHL-INBOUND-AND-PLAYBOOKS.md`). Removed the name exclusion and replaced fence pairing with a
  language-agnostic fence walker (opens/closes paired in document order). Scan now covers **22** object-A
  bodies across 5 files (was 9 across 3) — all PASS (23-key, flat, placeholder-free). The v6.0 playbook's 11
  per-channel bodies are scanned and pass; no body needed correcting and the fingerprint did not mis-flag any
  non-body block, so nothing was re-excluded.

### Added
- `scripts/qc-trinity-registry-test.sh` — fixture suite (7 cases) proving the reconciliation catches a
  **registered-but-missing-files** row and a **file-present-but-unregistered** slug on the real **bullet**
  format, plus table-form regressions. Wired into CI (`.github/workflows/qc-static.yml`) next to the 23-key
  linter so both run on every push/PR.

## [1.4.6] - 2026-05-29 - v6.0 clean comprehensive playbook; de-staled

Synced the CLEAN, conflict-free v6.0 comprehensive playbook into the skill so the repo carries NO stale or
self-contradicting playbook content.

### Changed
- **Renamed `references/v5.14-source-playbook.md` → `references/v6.0-source-playbook.md`** (git mv) and replaced
  its content with the clean v6.0 source playbook. Every GHL hook passage in v6.0 is reconciled to the single
  **23-key FLAT body** standard: no nested bodies, no `deliver:true`, no mapping-level `fallbacks`, in-body
  `messageTemplate` kept placeholder-free, server-mapping `sessionKey` is `"{{session_key}}"`.
- Updated every reference/link that pointed to the old `v5.14-source-playbook.md` filename to the new
  `v6.0-source-playbook.md` name across `INSTALL.md`, `INSTRUCTIONS.md`, `protocols/conversation-workflows-protocol.md`,
  six `references/*.md` pointer docs (stripe-coupons, stripe-webhooks, shopify-graphql, sales-frameworks,
  ghl-coupons, cloudflare-tunnel-troubleshooting, cloudflare-godaddy-setup-guide), and the load-bearing scripts
  `scripts/01-locate-master-files-folder.sh` (`PLAYBOOK_SRC`/`DEST_PLAYBOOK`) and `scripts/qc-23-key-bodies.sh`
  (`EXCLUDE_NAMES`).

### Fixed (surgical conflict sweep — contradictions with the corrected 23-key structure)
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14 CARDINAL RULE — corrected the stale "GHL Custom Webhook RAW BODY
  … must **NOT** contain a `messageTemplate`" line, which contradicted §14.1's canonical 23-key body (the body
  DOES carry a `messageTemplate` key, kept placeholder-free; only the *templated* `messageTemplate` is server-side-only).
- `protocols/pre-handoff-qc-protocol.md` — corrected a QC checklist item that told the agent to verify a
  `fallbacks` chain "configured" on the `hooks.mappings` entry; `fallbacks` is NOT a valid `.strict()` mapping
  key. Now states fallback chains belong only on the model-routing config.

Standards (communications-playbook-standard, workflow-ai-instructions-standard) remain their own reference docs;
the playbook references them rather than duplicating them.

## [1.4.5] - 2026-05-29 - 8 rated improvements (push to 10): machine-enforced 23-key + TRINITY, Build-with-AI label fix, real self-counts, fleshed journeys, Skill 23 chain

Part of repo `v10.16.9`. Six of the eight rated improvements land in this skill; the other two
(cross-skill chain enforcement + library-gate status surfacing) land in Skill 23 but reference this skill.
No stripped GHL bodies introduced — the 9 embedded object-A bodies all pass the new linter (23-key, flat,
placeholder-free).

### Added
- `scripts/qc-23-key-bodies.sh` — machine-enforces the 23-key GHL RAW BODY rule across references/ +
  templates/ + scripts/ (exactly 23 flat keys, placeholder-free `messageTemplate`, no nesting, no `\n`).
  Wired into `scripts/11-run-qc-checklist.sh` and into CI (`.github/workflows/qc-static.yml`). Excludes the
  verbatim `v6.0-source-playbook.md` (narrative source, superseded by GHL-INBOUND §14); skips object-B server mappings.
- `scripts/qc-trinity-registry.sh` — machine-enforces THE TRINITY: a registry row with a communications
  playbook but no Build-with-AI prompt (or an orphan prompt) is flagged INCOMPLETE; honors the
  Layer-1-not-needed exemption. Wired into `11-run-qc-checklist.sh`; referenced from the verification
  checklist + standards.

### Changed
- **Mislabel fix (the failure this standard set out to kill):** `templates/sms-workflow-ai-prompt-template.md`,
  `templates/workflow-verification-checklist-template.md`, `scripts/21-generate-client-reference-sheet.sh`,
  `scripts/09-install-conversation-workflows.sh`, and `scripts/20-seed-design-principles.sh` now name the
  authoritative location — GHL **Automations → "Build with AI"** (top-right) on a NEW automation — instead
  of "Use Workflow AI" / "Create workflow → Workflow AI".
- **Real self-counts:** `SKILL.md` + `INSTALL.md` now state protocols=32, scripts=27, references=15,
  journeys=8 (was 31/9/10) with a `SELF-COUNTS` re-verify comment; a re-verification note was added to the
  repo `scripts/bump-version.sh`.
- **7 stub journey templates fleshed out** to ≥ coach depth with vertical-specific triggers / conversation
  phases / success actions: consulting, course-creator, e-commerce, real-estate, saas, service-provider,
  wellness (109–121 lines each).
- **Distinction-map table** added at the top of `protocols/conversation-workflows-protocol.md` (channel
  communication playbook vs communications playbook vs workflow-AI prompt vs GHL automation).
- **Skill 23 upstream cross-reference** added to `SKILL.md` + the protocol's TRINITY note (Skill 23's
  comms/sales/support build now hands off here via the enforced `commsAutomationStatus` chain).

### Version
- `skill-version.txt` → `1.4.5`.

## [1.4.4] - 2026-05-29 - THE TRINITY + communications-playbook & workflow-AI standards

Teaches the connection between a GHL workflow, its communications playbook, and its workflow-AI prompt
(THE TRINITY — one implies the other two, never ship one alone), and ships two standardized
reference/protocol docs with must-appear checklists. CORE md files stay lean: AGENTS.md gets only
concise pointers; full content lives in the reference docs. No stripped GHL bodies introduced — the
one embedded body is the full 23-key flat body (messageTemplate placeholder-free, no nesting).

### Added
- `references/communications-playbook-standard.md` — the FULL communications-playbook standard:
  must-appear checklist (slug/id, owner agent id, channel, trigger phrases/intent, goal, step-by-step
  flow, the GHL reply mechanism via the GHL Conversations API per TOOLS.md, cross-playbook transition
  rules, edge cases incl. frustration/refund/legal, on-success/tagging, tone, honesty floor), the
  canonical format skeleton, STORAGE (always under `conversation-workflows/` + register in
  `registry.md`), and the CLIENT-account STORAGE ORDER fallback chain (Notion → Google Docs → plain
  text, always in that order).
- `references/workflow-ai-instructions-standard.md` — the FULL workflow-AI (Build-with-AI) standard:
  WHERE the prompt goes (GHL Automations → "Build with AI" button — no API, no MCP), the must-appear
  checklist, the explicit Custom Webhook field-by-field steps (EVENT=CUSTOM, METHOD=POST via dropdown,
  URL = the REAL hook url not the sample placeholder, AUTHORIZATION dropdown=None, HEADERS via
  "Add item" → Authorization Bearer token + Content-Type, CONTENT-TYPE=application/json, RAW BODY =
  the full 23-key flat body via the Custom Values picker — not shortened to 4 keys), the
  Build-with-AI VERIFICATION CHECKLIST, and MULTI-ACTION teaching (if/else branches, Add-Tag,
  tag-check, multiple sequential actions, create-tag-first via the GHL skill).

### Changed
- `protocols/conversation-workflows-protocol.md` — added the binding "THE TRINITY" section at the top;
  pointed §D.2 at the workflow-AI standard and §E at the communications-playbook standard +
  client-account storage-order fallback chain.
- `scripts/05-update-agents-md.sh` — AGENTS.md Step 1.85 block now carries a concise THE TRINITY
  pointer + pointers to both standard docs; Step 1.8 (BLOCK_B) points the active-playbook reader at
  the communications-playbook standard and the GHL-Conversations-API reply mechanism. Pointers only —
  no playbook bodies in AGENTS.md.
- `templates/sms-workflow-ai-prompt-template.md` — Custom Webhook action rewritten to the precise
  field-by-field format (EVENT=CUSTOM, METHOD dropdown, real URL not sample placeholder, HEADERS via
  "Add item", CONTENT-TYPE, RAW BODY via Custom Values); added a Multi-action note (if/else, Add-Tag,
  tag-check, multiple actions, create-tag-first). Renamed "Workflow AI" usage to "Build with AI" in
  the how-to. Body unchanged (still the 23-key flat body).
- `templates/workflow-verification-checklist-template.md` — prepended the concise BUILD-WITH-AI
  VERIFICATION CHECKLIST (trigger/filter, exact actions, METHOD=POST, real URL, AUTHORIZATION=None,
  headers via Add item, content-type, 23-key flat body, tags, Published) above the detailed
  click-by-click checklist.
- `skill-version.txt` bumped to `1.4.4`.

## [1.4.3] - 2026-05-29 - Enforce 23-key GHL body everywhere

Owner directive (non-negotiable): EVERY GHL Custom Webhook RAW BODY example in Skill 38 must contain
**all 23 keys** — 23 is the MINIMUM, no stripped/short (8/11/13-key) bodies are allowed anywhere in the
repo. Every previously-shorter (13-key) body was REPLACED with the full 23-key canonical body. The body
stays FLAT (no nesting), the body's `messageTemplate` value is kept **placeholder-free** (no `{{…}}`, or
GHL throws "Error while parsing the object to JSON"), and no `\n` appears inside any JSON example. The
23 keys (exact): `id`, `match`, `action`, `agent_id`, `model`, `wakeMode`, `name`, `session_key`,
`messageTemplate`, `deliver`, `timeoutSeconds`, `channel`, `to`, `thinking`, `contact_id`, `first_name`,
`last_name`, `email`, `phone`, `subject`, `message_body`, `location_id`, `location_name`. Per-channel
variants change only `channel` + the `session_key` prefix (sms / fb / instagram / whatsapp / live_chat /
email). The OpenClaw server `hooks.mappings` entry (object B) is unchanged — it keeps its own templated
`messageTemplate`; only the GHL Custom Webhook body (object A) is the 23-key payload.

### Changed
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — replaced the §3.1 Build-with-AI Raw Body and the §14.1
  canonical body with the full 23-key body; added the per-channel variants table (§14.1); stated the
  23-key rule plainly in §5 with the full key list and per-key explanation; updated the §4 verification
  checklist field list to all 23 keys and reframed the messageTemplate item to "placeholder-free" (instead
  of "no messageTemplate"); reconciled §14.2 (body messageTemplate must stay placeholder-free) and added a
  two-objects note after §14.4; updated the header warning, §13 quick-index items 4 & 11, and the §14 intro.
- `references/v5.14-source-playbook.md` — upgraded the localhost smoke-test body, the E2E test body, the
  Part 1 D.2 Build-with-AI body, the D.3 verification-checklist body reference, and all Part 3 channel Raw
  Body blocks to the full 23-key body (added a WhatsApp block; aligned facebook→fb, livechat→live_chat to
  the §7 verified send-type enum); updated the §3C corrected-structure callout to the 23-key standard.
- `scripts/15-configure-hooks-mappings.sh` — the Step 4 E2E test PAYLOAD is now the full 23-key body
  (validated as 23-key JSON); header comment updated to the 23-key rule. Server mapping unchanged.
- `templates/client-reference-sheet-template.md` — all channel Raw Body blocks upgraded to 23 keys (added
  WhatsApp); count references updated.
- `templates/sms-workflow-ai-prompt-template.md` — the SMS Raw Body upgraded to 23 keys; the Workflow-AI
  "common mistakes" list now flags placeholder-in-body-messageTemplate and sub-23-key (stripped) bodies.
- `templates/workflow-verification-checklist-template.md` — Raw Body checklist item now mandates all 23 keys.
- `protocols/conversation-workflows-protocol.md` — the D.2 Build-with-AI body and the verification-checklist
  Raw Body item upgraded to the 23-key standard.
- `skill-version.txt` bumped to `1.4.3`.

## [1.4.2] - 2026-05-29 - Corrected GHL inbound hook structure: FLAT body, no nesting, server-only messageTemplate

GHL inbound-hook correction verified LIVE on Corey / Explore Growth (OpenClaw 2026.5.27). The GHL Custom
Webhook RAW BODY is now documented as **FLAT** (no nested `contact:{}` / `customer_message:{}` objects — a
nested body makes EVERY field resolve EMPTY at the hook) and **data-only** (it must NOT contain a
`messageTemplate` — a templated messageTemplate in the body makes GHL throw "Error while parsing the object
to JSON" and Skip the webhook). The `messageTemplate` lives ONLY on the server `hooks.mappings` entry,
references the FLAT body key names, and MUST include the reply-via-GHL-API instruction (or the agent drafts
a reply but never sends it). `deliver:false`; `agentId` is hardcoded per hook path (NOT templatable);
`fallbacks` is not a valid mappings key (`.strict()` schema); `GHL_LOCATION_ID` env is the API credential,
not the body `location_*` fields. `skill-version.txt` bumped to `1.4.2`.

### Changed
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — replaced the nested Build-with-AI Raw Body (§3.1) with the
  canonical FLAT body; rewrote §5 (FLAT body rule, with a labeled ❌ NESTED counter-example); updated the
  §4 verification checklist (FLAT body + no in-body messageTemplate); added a header warning pointing to the
  new section; added **§14 "CORRECTED GHL HOOK STRUCTURE (2026-05-29)"** capturing the full SPEC (cardinal
  rule, flat body, server-only messageTemplate with the GHL-API reply instruction, `deliver:false`, sessionKey
  gating, agentId not templatable / `/hooks/agent`, `fallbacks` invalid, `GHL_LOCATION_ID` is the credential,
  valid `.strict()` mappings keys).
- `references/v5.14-source-playbook.md` — converted the canonical `hooks.mappings` messageTemplate/sessionKey
  to FLAT body keys (added the reply-via-GHL-API instruction; `timeoutSeconds` 180→300), flattened the
  localhost smoke-test body, the E2E test body, the D.2 Build-with-AI prompt body, and all six Part 3 channel
  Raw Body JSONs; added a CORRECTED-structure call-out + updated the "Why these settings" prose.
- `scripts/15-configure-hooks-mappings.sh` — `messageTemplate` now references FLAT body keys and explicitly
  instructs the agent to actually send via the GHL API; `deliver` true→**false**; `timeoutSeconds` 180→300;
  `sessionKey` now pulls the flat `{{session_key}}` body key; the Step 4 E2E test PAYLOAD is now a FLAT body.
- `scripts/21-generate-client-reference-sheet.sh` — added `HOOK_NAME` and `AGENT_ID` to the template
  placeholder substitution (so the flattened templates render with concrete values).
- `templates/sms-workflow-ai-prompt-template.md` — flattened the Raw JSON body; added the FLAT/data-only
  rule, the "nests the body" + "adds messageTemplate to body" failure modes, and `<AGENT_ID>` to placeholders.
- `templates/client-reference-sheet-template.md` — flattened all six channel Raw Body JSONs (Part 3); updated
  the Part 3 intro (FLAT, data-only, Custom Values picker) and the "adding other services" note.
- `protocols/conversation-workflows-protocol.md` — flattened the Build-with-AI prompt Raw JSON body and
  clarified the server-only messageTemplate rule.

## [1.4.1] - 2026-05-28 - Hostinger Docker env-discovery + conversation-playbook builder + CF/GoDaddy Notion-offer

Patch release on top of the 1.4.0 GHL hardening: the Hostinger Docker env-discovery layer, the
conversation-playbook builder hardening, and the CF/GoDaddy prereq-halt Notion-offer (when a client has
no Cloudflare API token, the agent OFFERS a Notion doc in the client's OWN workspace from
`references/cloudflare-godaddy-setup-guide.md` + link, or a manual step-by-step walkthrough — never a
bare `cat` for the operator to read on the box). `skill-version.txt` is bumped to `1.4.1`.

### Added
- `references/HOSTINGER-DOCKER-ENV.md` (NEW) — bulletproof Hostinger Docker VPS env-discovery. Documents where the
  environment lives (host `/docker/<project>/.env` = canonical `env_file`; container mirror `/data/.openclaw/.env`
  via the `volumes: ./data:/data` bind mount; live `docker exec <container> printenv`), the EXACT copy-paste
  discovery sequence (`docker ps` → derive `<project>` → `cat /docker/<project>/.env` → `docker exec … printenv |
  grep API_KEY`), THE HARD RULE (never report a key "missing" before running that sequence — if other keys like
  `ANTHROPIC_API_KEY` are visible you're in the right place; add the missing key there, don't claim you can't find
  it), the canonical add-a-key procedure (append host + mirror container + `docker compose up -d --force-recreate`;
  plain `restart` does NOT reload `env_file`), and the `/hostinger/server.mjs` `hooks.token` rewrite gotcha.

### Changed
- `references/v5.14-source-playbook.md` Step O.5 — added a Hostinger Docker pointer (env is `/docker/<project>/.env`;
  run the discovery sequence + HARD RULE in HOSTINGER-DOCKER-ENV.md before reporting any key missing).
- `scripts/00-verify-prerequisites.sh` "CLOUDFLARE API KEY NOT FOUND" halt — added a prominent Hostinger Docker
  block (the env is `/docker/<project>/.env`, run discovery before reporting missing) and made the
  `cloudflare-godaddy-setup-guide.md` pointer clearly the path for getting a domain into Cloudflare + creating the
  CF API token; the "save your key" step now shows the Hostinger host-`.env` + force-recreate path.
- Step 9.20 (Conversation Workflow Builder) — now explicitly a **3-PART build** every time: Part 1 (Build-with-AI
  prompt + manual-build fallback + verification checklist — nails the funnel SHAPE, operator pastes token/URL/Raw
  values), Part 2 (the Layer 2 conversation playbook in `conversation-workflows/`, registered in `registry.md`; the
  hook path wires the two halves), Part 3 (the brainstorm trigger — FRIENDLY proactive Q&A, NOT 50 questions; uses
  Typed Knowledge Bases + USER.md + MEMORY.md, asks only smart gaps, regurgitates a concise "is this what you want?"
  summary; on YES builds Part 1 → Part 2 → pointer → NEW Notion doc → register). USP framing added
  (communication-driven funnels / automations, beats CloseBot). Cross-references to Step 9.33 (Intelligent Playbook
  Routing) and Step 9.34 (Proactive Features Suite) added at all three steps so builder → router → proactive engine
  are explicitly one loop. Mirrored into `protocols/conversation-workflows-protocol.md` and `scripts/05-update-agents-md.sh`
  (Step 1.85). Removed ambiguous "Workflow AI" usage — renamed to "Build-with-AI" throughout (artifact files
  `<id>--build-with-ai-prompt.md`); fixed the operator-instruction block that still said "Use Workflow AI".
- `scripts/06-append-memory-rules.sh` + `CORE_UPDATES.md` — added MEMORY.md design rules 15-18 (GHL/automation
  terminology = GHL Automations workflow; GHL Automations have NO API/NO MCP, only the "Build with AI" button; the
  3-part build checklist; communication-driven-funnels + brainstorm-not-50-questions). Written under a separate
  `v1.4.0` marker so existing v5.14 installs get rules 15-18 on upgrade without re-appending 6-14 (idempotent +
  upgrade-safe, verified).

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
