# Conversational AI System — Strategic Feature Roadmap

This document tracks the features built into the Convert and Flow conversational AI system, plus the remaining features under consideration.

**Audience:** the system owner and their AI agents reading this for context on what's done, what's coming, and why.

**Status legend:**
- ✅ **Implemented** — feature is live and shipped (the per-feature "shipped in vX.Y" tags below record the playbook version each feature first landed in; all ✅ features are consolidated into the current v6.0 playbook)
- 📋 **Documented** — design is finalized, ready to build
- 💡 **Under consideration** — concept is sound, design pending

**Last updated:** May 30, 2026 (aligned with v6.x of the main playbook — the consolidated, conflict-free release that supersedes the v5.x line; now indexes the Round-3 wave: the ZHC- tag-prefix system rule + F44/F45/F46/F47/F49/F50/F52 + Skill 39 + Skill 40 + the 3 QC-enforced standards)

---

# Part 1 — Completed Features

All 18 features below are now implemented as setup steps in the main playbook (`openclaw-cloudflare-tunnel-prompt.md`).

## Round 1 — original strategic features (Features 1-13)

| # | Feature | Implemented in | Step |
|---|---|---|---|
| 1 | High-volume activity warning | v5.0 | 9.5 |
| 2 | Long-conversation pause with owner review | v5.0 | 9.5 |
| 3 | Bot-detection protocol | v5.0 | 9.5 |
| 4 | Sentiment monitoring and emotional escalation | v5.0 | 9.6 |
| 5 | PII scrubbing in conversation logs | v5.0 | 9.7 |
| 6 | Quiet hours | v5.0 | 9.8 |
| 7 | Compliance keyword detection | v5.0 | 9.9 |
| 8 | Multi-language detection and matching | v5.0 | 9.10 |
| 9 | Confidence threshold escalation | v5.0 | 9.11 |
| 10 | Conversation export on customer request | v5.0 | 9.12 |
| 11 | Conversational drift detection | v5.1 | 9.13 |
| 12 | Knowledge Sources system | v5.1 | 9.14 |
| 13 | Prompt injection protection | v5.2 | 9.15 |

## Round 2 features promoted to implemented in v5.3-5.4

| # | Feature | Implemented in | Step |
|---|---|---|---|
| 19 | Multi-channel operator notifications (Slack/Discord/Email/SMS/Webhook) | v5.3 | 9.16 |
| 20 | Conversation analytics dashboard (weekly + monthly) | v5.3 | 9.17 |
| 22 | Document generation actions (quotes/proposals/contracts) | v5.3 | 9.18 |
| 24 | Smart Booking system + calendar setup wizard (supersedes Feature 23) | v5.3 | 9.19 |
| 25 | Conversation Workflow Builder (3-layer architecture in v5.4) | v5.3 / v5.4 rebuild | 9.20 |

**Notes:**
- Feature 23 (Smart Unavailability) merged into Feature 24 (Smart Booking) in v5.3
- Feature 25 (Conversation Workflow Builder) was significantly upgraded in v5.4 to a 3-layer architecture covering Layer 0 (routing check), Layer 1 (GHL side with auto-tag creation + Workflow AI prompt + verification checklist), Layer 2 (OpenClaw playbook)

---

# Part 2 — Remaining Features (ordered by priority)

Sixteen features remain unimplemented. Build order reflects revenue impact and strategic value, with the Conversational Sales AI cluster slotted FIRST since sales-driven outcomes are the primary value driver for Convert and Flow's client base.

---

# Sales AI Cluster (Features 26-31) — TOP PRIORITY

## ✅ Feature 26 — Conversational Sales AI Best Practices Module (shipped in v5.7)

**Status:** Implemented in Step 9.23 of the main playbook.

**What it does:** The sales BRAIN. Six conversation phases (Open / Discover / Present / Handle Objections / Close / Follow Up). Three discovery frameworks (BANT, MEDDIC, SPICED) — operator picks per product. Six objection patterns with response templates. Buyer signal recognition. Pricing reveal timing rules. Trial-close phrasing. Honesty floor (never fabricate, never deceive, never false urgency). Reads client-specific content from `knowledgebases/sales/`. AGENTS.md Step 1.8 activates this layer when sales context detected.

## ✅ Feature 27 — Product Knowledge Layer (subsumed by Feature 38 in v5.6)

**Status:** Implemented as the `products/` typed knowledge base inside Feature 38 (Step 9.22).

## ✅ Feature 28 — Discount Code Generation (GHL + Stripe) (shipped in v5.10)

**Status:** Implemented in Step 9.26.

## ✅ Feature 29 — Intelligent Follow-up (shipped in v5.9)

**Status:** Implemented in Step 9.25.

## ✅ Feature 30 — Stripe Integration (full) (shipped in v5.10)

**Status:** Implemented in Step 9.27.

## ✅ Feature 31 — Shopify Integration (shipped in v5.12)

**Status:** Implemented in Step 9.31.

---

# Cross-Cutting Conversational AI Features (Features 32-34)

## ✅ Feature 32 — Humanizer Skill Integration (shipped in v5.5)

**Status:** Implemented in Step 9.21. ALWAYS-ON via skill 19. Bans Tier 1 AI vocabulary (delve, tapestry, vibrant, crucial, robust, seamless, etc.). Bypassed for compliance messages and pure technical communications. Skill 38 does NOT ship its own humanizer; references skill 19.

## ✅ Feature 33 — Intelligent Playbook Routing (shipped in v5.13)

**Status:** Implemented in Step 9.33. Cosine similarity 0.3 advantage to switch. Max 3 switches per conversation.

## ✅ Feature 34 — Proactive Features Suite (shipped in v5.13)

**Status:** Implemented in Step 9.34. Seven sub-features on a single Saturday 11pm cron.

---

# System Health & Tuning Cluster (Features 35-37)

## ✅ Feature 35 — Weekly Conversation AI Tune-up (shipped in v5.12)

**Status:** Implemented in Step 9.32. Sunday 2am cron.

## ✅ Feature 36 — Monthly Comprehensive Playbook Review (shipped in v5.14)

**Status:** Implemented in Step 9.35. 1st-of-month 9am audit.

## ✅ Feature 37 — Model Version Freshness Checker (shipped in v5.14)

**Status:** Implemented in Step 9.36. Bundled into Saturday 11pm.

---

# Knowledge Architecture Cluster (Features 38-39)

## ✅ Feature 38 — Typed Knowledge Bases (shipped in v5.6)

**Status:** Implemented in Step 9.22. Four bases: business/, products/, sales/, conversations/.

## ✅ Feature 39 — Web Scraper for Knowledge Base Building (shipped in v5.8)

**Status:** Implemented in Step 9.24. Default extraction model: minimax/minimax-2.7. Cost-estimated; hard cap $5 double-confirm, $25 refused.

---

# Customer Experience Cluster (Features 40-42)

## ✅ Feature 40 — Customer Service & Support Playbooks (dual-mode) (shipped in v5.12)

**Status:** Implemented in Step 9.30.

## ✅ Feature 41 — Business-Logic Workflow Suggestions (shipped in v5.11)

**Status:** Implemented in Step 9.29.

## ✅ Feature 42 — Customer Journey Templates Library (shipped in v5.11)

**Status:** Implemented in Step 9.28. 8 business types; coach fully detailed; others stubbed.

---

# Round 3 — Conversational Depth + Verticals (Features 44-52, shipped in skill 38 v1.5.x / playbook v6.x)

This wave adds conversational *depth* (always-listening interrupts, inline FAQ, aggression handling, geo-qualification, type-aware CRM writes), a cross-cutting tagging convention, a per-client visitor pixel, an external analytics consumer, and two vertical skills (real estate + public-records sourcing). Each entry below traces to the in-repo protocol/skill file named under **Source**; the prose is expanded from that file so the roadmap is a faithful, traceable spec (no edge cases stripped). All five new behavioral features (F44/F45/F46/F47/F50) ALSO emit the F52 JSONL data contract and are seeded by `scripts/25-seed-round3-feature-files.sh`.

## ✅ System Rule — ZHC Tag-Prefix Convention (shipped in skill 38 v1.5.0)

**Status:** Implemented. Step 9.42 / MEMORY Rule 20 / AGENTS.md marker `SKILL38_ZHC_TAG_PREFIX`.

Every tag the agent creates PROGRAMMATICALLY (via the GHL skill `create_tag`, or the fallback `POST /locations/{locationId}/tags` — the SAME CREATE-TAG-FIRST mechanism in `conversation-workflows-protocol.md` §D.1 / `workflow-ai-instructions-standard.md` §6, REUSED not replaced; only the NAME changes) MUST carry the `ZHC-` prefix (e.g. `ZHC-pricing-interest`, `ZHC-discovery-scheduled`), so agent-created tags are instantly distinguishable from operator-created ones in Settings → Tags. The single test is "did the AGENT create this tag?" — if yes, `ZHC-`. **NOT retroactive:** never rename or migrate an existing/operator-owned tag; applying a pre-existing tag uses its name verbatim. The bot-detection tag is created as `ZHC-bot-suspected` going forward (the legacy `bot-detected` is honored as-is). Companion rule: CRM custom FIELDS the agent creates use the parallel `ZHC_` (underscore) prefix — fields and tags are different GHL objects, so the prefix punctuation differs. **Source:** `protocols/zhc-tag-prefix-protocol.md`. QC: `scripts/qc-zhc-tag-prefix.sh` (rule documented + not-retroactive, the canonical F44/F45/F47/F50 tag tokens are the ZHC- forms, the D.1 + Section-6 examples updated, and no bare create-tag literal survives).

## ✅ Feature 50 — Aggression & Bot Detection (shipped in skill 38 v1.5.0)

**Status:** Implemented. Step 9.37 / MEMORY Rule 21 / AGENTS.md Step 1.35 (marker `STEP_1_35_AGGRESSION_PRE_ROUTING`).

EXTENDS the bot/abuse safeguard family (Safeguard 3/4, Step 9.5) — it does NOT rebuild bot detection — with a two-tier aggression classifier that runs PRE-routing: AFTER the Step 0.7 compliance hard-gate and the Step 1.4 safeguard check, but BEFORE Step 1.75 workflow match and BEFORE any reply-drafting LLM spend (a cheap keyword/pattern pass, no model call). **Tier 1 — Tension (LOW):** multiple irritation words in one message, OR sustained irritation across 3+ consecutive messages (read the log), OR `!!!`/`???` → tag `ZHC-tension-detected`, continue the normal reply path with heightened attention (slow down, lead with empathy, nothing dismissive), do NOT reroute, do NOT notify the operator. **Tier 2 — Aggression (HIGH):** profanity directed AT the agent/business, OR a threat (legal/physical/public), OR ALLCAPS+profanity+direct-address, OR 3+ aggression signals in one message → tag `ZHC-aggression-detected`, ROUTE to the aggression-handler workflow as an F44 detour (save state, de-escalate, return → `ZHC-aggression-handled-and-resumed`), and NOTIFY the operator (contact id + channel + triggering message + signals). **CRITICAL — ALL CAPS ALONE never fires** either tier at any sensitivity. NEW bot-suspicion firings tag `ZHC-bot-suspected`. Sensitivity (`lenient`/`standard`/`strict`, default `standard`) tunes the thresholds; toggle `skill38.aggression_detection.{enabled (default true), sensitivity}`. Every firing logs to `aggression-detection-log.md` (human-readable) AND `aggression-detection-log.jsonl` (`event_type` `tension_detected`/`aggression_detected`). **Source:** `protocols/aggression-detection-protocol.md` + `protocols/conversational-safeguards.md` (Safeguard 4).

## ✅ Feature 44 — Smart Playbook Switching / Always-Listening Interrupts (shipped in skill 38 v1.5.0)

**Status:** Implemented. Step 9.38 / MEMORY Rule 22 / AGENTS.md Step 1.42 (marker `STEP_1_42_INTERRUPTS_AND_FAQ`).

DETOUR-AND-RETURN — **DISTINCT from F33** (Intelligent Routing, Step 9.33, which is route-and-stay and permanently switches the active workflow). F44 handles a quick aside without abandoning the customer's real goal. While ANY workflow is active, an always-listening layer runs in parallel on every inbound; on an interrupt trigger — operator-urgent keywords (operator-defined in `interrupt-triggers.md`), heavier FAQ types, compliance redirects (Step 0.7), F50 Tier-2 aggression, F49 pixel-priority — it **SAVES** the workflow state (`active_workflow_id`, `active_step`, `gathered_data`, one-line context) → **EXECUTES** the sub-flow → **RETURNS** to the saved step with a soft transition ("Coming back to where we were…") so nothing is re-asked. **Max 2 levels deep**, then escalate to a human (notify operator); never nest a third. Multiple triggers in one inbound: handle the HIGHEST priority first (compliance → F50 aggression → operator-urgent → F49 pixel → FAQ), queue the rest and fire after the current detour returns (subject to the 2-level cap). Tags `ZHC-interrupt-handled` / `ZHC-faq-detoured` / `ZHC-aggression-handled-and-resumed`. Toggle `skill38.smart_playbook_switching.{enabled (default true), max_interrupt_depth (default 2)}`. Logs to `interrupt-log.jsonl` (`event_type` `interrupt_detour`; `gathered_data_keys` only, never the values — PII stays out). **Source:** `protocols/smart-playbook-switching-protocol.md`.

## ✅ Feature 45 — Geo-Qualification (shipped in skill 38 v1.5.0)

**Status:** Implemented. Step 9.39 / MEMORY Rule 23 / AGENTS.md Step 2.0 (marker `STEP_2_0_GEO_QUALIFICATION`). Toggle `skill38.geo_qualification.enabled` — default **OFF** (most businesses serve everyone; opt-in for location-bound businesses).

When ON, the agent gathers a location HINT in priority order — pixel/IP (if F49) → phone area code → form address → explicit ask — and uses the best hint to PRE-FILL its confirmation question ("Looks like you might be near [city] — is that right?"), then checks the confirmed location against per-product service areas in `KnowledgeBases/sales/service-areas.md` (ZIP / county / state / radius; a product with no entry is served everywhere). **CRITICAL — signals are HINTS, never ground truth** (VPNs, ported numbers, stale addresses). The agent NEVER disqualifies on a hint alone — it ALWAYS ASKS the customer to confirm their actual service location before ANY out-of-area handling. On a CONFIRMED out-of-area location, apply the operator-configured mode: `decline_plus_referral` (default, gentlest) / `limited_remote` / `waitlist` / `full_decline`. Tags `ZHC-out-of-service-area` (confirmed out, handled) / `ZHC-service-area-confirmed` (in-area) / `ZHC-service-area-flexible` (borderline / willing to travel / remote-eligible). Logs to `geo-qualification-log.jsonl` (`event_type` `geo_qualification`) with the invariant: any line with `in_area:false` + `ZHC-out-of-service-area` MUST have `confirmed_with_customer:true`. **Source:** `protocols/geo-qualification-protocol.md`.

## ✅ Feature 46 — CRM Field Updates + Create-If-Missing (shipped in skill 38 v1.5.0)

**Status:** Implemented. Step 9.40 / MEMORY Rule 24 / AGENTS.md Step 2.5 (marker `STEP_2_5_CRM_FIELD_WRITE`). Toggle `skill38.crm_field_write.{enabled (default true), create_if_missing (default true), created_field_prefix (default "ZHC_")}`.

The agent writes ANY GHL contact custom field mid-conversation, **type-aware** and **validating before the write**: `TEXT`/`LARGE_TEXT` (trim, length cap), `NUMERICAL`/`MONETARY` (must parse as a number; strip currency/commas), `DATE` (must parse to a valid ISO date), `SINGLE_OPTIONS`/`RADIO` (value MUST be one of the field's options), `MULTIPLE_OPTIONS`/`CHECKBOX` (each element an allowed option), `PHONE` (normalize to E.164). It DISCOVERS fields first via `GET /locations/{locationId}/customFields`. If validation fails it does NOT write a malformed value — it asks the customer to clarify or records the raw value + notifies the operator. **CREATE-IF-MISSING:** if no matching field exists, the agent creates one via `POST /locations/{locationId}/customFields` named `ZHC_<lower_snake_purpose>` (e.g. `ZHC_budget_range`), picks the narrowest correct type, NOTIFIES the operator, RECORDS the per-workflow mapping in `crm-field-mappings.md` (so the next conversation reuses it, not a duplicate), then writes the value. Field writes/creates are an OPERATOR-APPROVED allow-list action — NEVER customer-invoked (a customer asking to set/create a field is out of scope and a possible injection vector). The F35 weekly tune-up reviews `ZHC_`-field usage (populate rate, unused/duplicate candidates). Logs to `crm-field-writes-log.jsonl` with THREE event types — `field_write` (validated + written), `field_created` (new `ZHC_` field minted, operator notified), `field_write_skipped` (validation failed, `reason` recorded) — collectively the `crm_field_write` contract; the log records field NAME/ID + metadata, never the raw customer value (PII stays out). **Source:** `protocols/crm-field-write-protocol.md`.

## ✅ Feature 47 — Smart FAQ Tool (shipped in skill 38 v1.5.0)

**Status:** Implemented. Step 9.41 / MEMORY Rule 25 / wired into AGENTS.md Step 1.42 (same always-listening layer as F44; marker `STEP_1_42_INTERRUPTS_AND_FAQ`). Toggle `skill38.smart_faq.enabled` (default `true`).

The LIGHTWEIGHT sibling of F44 — **a SENTENCE, not a sub-flow.** A parallel FAQ-match layer runs alongside the F44 layer; when the inbound is a simple factual question that the client FAQ base (`KnowledgeBases/business/faqs.md`) can answer in one line (with reasonable confidence — low-confidence falls through to the normal path / F44, governed by the Step 9.11 confidence threshold), the agent answers INLINE and continues the SAME step in the SAME reply ("By the way, [answer]. Coming back to [topic]…") — no state save/restore, no workflow switch. Each workflow can scope which FAQs are in-bounds via `conversation-workflows/<id>/faq-scope.md` (default: all FAQs in-scope as one-liners), so a booking workflow doesn't inline a deep pricing-negotiation answer that belongs to the sales workflow (that is an F33 route or an F44 detour). Bigger FAQ questions hand off to F44. Tag `ZHC-faq-answered`. Logs to `faq-detour-log.jsonl` (`event_type` `faq_answered`; records `faq_topic`, `in_scope`, `returned_to_step`). **Source:** `protocols/smart-faq-tool-protocol.md`.

## ✅ Feature 49 — ZHC Pixel (shipped in skill 38 v1.5.x)

**Status:** Implemented (code ships; the live per-client CF deploy is scope-GATED). Step 9.43 / AGENTS.md Step 1.45 (marker `STEP_1_45_PIXEL_CONCIERGE`). Toggle `skill38.zhc_pixel.{enabled (default true), triggers.*}`.

Every client gets THEIR OWN private pixel that POSTs anonymous-but-persistent visitor signals (pages / time / scroll / clicks / return-visits) to THEIR OpenClaw via THEIR existing CF tunnel (`pixel.<CLIENT_DOMAIN>` → tunnel → hook `pixel-visitor-signal`), NOT a shared service. The pixel JS template `templates/zhc-pixel/zhc-pixel.template.js` (first-party cookie + persistent `visitor_id` + batched `sendBeacon`/`fetch` POST) is rendered per-client by `scripts/27-render-pixel-js.sh` (placeholders → their tunnel URL / `<SITE_ID>` / `<AGENT_ID>`). The `pixel-visitor-signal` hook (`deliver:false`, bot-gate-first `messageTemplate`) routes to the **Pixel Concierge** — a NEW scoped agent acting ONLY on `hook:pixel:*` sessions, registered by `scripts/28-configure-pixel-hook.sh`. The Concierge: (1) **bot-gates FIRST with ZERO model spend** (sub-2s pageview cadence / impossible scroll velocity / headless UA → DROP); (2) appends every event to the F52 contract `pixel-events/YYYY-MM-DD.jsonl`; (3) evaluates trigger rules (pricing dwell → chat widget; contact-click → preempt widget; 4th return → soft outreach; cart abandonment → +1h email for known contacts; comparison-shopping 3+ service pages → consultation offer; known customer on account page → NO engagement); (4) **NEVER fabricates identity** (anonymous = behavior only; resolve identity ONLY by first-party form linkage — no cold-anonymous/Gmail/social/IP→person lookup); (5) engages least-intrusively with `ZHC-pixel-visitor`/`-returning-visitor`/`-high-intent` tags + `ZHC_first_visit_date`/`ZHC_total_visits`/`ZHC_pages_viewed`/`ZHC_high_intent_signal` fields (via the F46 create-if-missing mechanism), respecting quiet hours (Step 0.5) + compliance (Step 0.7) + the honesty floor. Privacy is enforced in the browser bundle (GDPR consent deferral, CCPA opt-out, Do-Not-Track hard-stop, `delete_request` deletion). The CF deploy `scripts/29-deploy-pixel-cloudflare.sh` is GATED on the precheck `scripts/26-verify-pixel-prerequisites.sh` (HALTs if Pages:Edit / Workers Scripts:Edit / Workers Routes:Edit scopes are missing, pointing the operator at the token-instructions doc). **Source:** `protocols/zhc-pixel-protocol.md` + `templates/zhc-pixel/`. QC: `scripts/qc-zhc-pixel.sh` (+ `qc-zhc-pixel.test.sh`).

## ✅ Feature 52 — Command Center Live Analytics Dashboard (shipped EXTERNALLY in the Command Center app)

**Status:** Implemented externally in the operator's Command Center application — NOT in this repo. Indexed here as the CONSUMER of the F52 JSONL **data contract** this skill produces.

The Command Center dashboard reads the five skill-38 JSONL sinks — `aggression-detection-log.jsonl`, `interrupt-log.jsonl`, `geo-qualification-log.jsonl`, `crm-field-writes-log.jsonl`, `faq-detour-log.jsonl` — plus the pixel-events JSONL (`pixel-events/YYYY-MM-DD.jsonl`). **The data contract:** one JSON object per line, each carrying at minimum `timestamp` + `event_type` + the event's data; the sinks are seeded (idempotent, never-overwrite) by `scripts/25-seed-round3-feature-files.sh`; the contract is machine-enforced by `scripts/qc-feature-logs.sh` (each protocol documents its JSONL path + a `timestamp`+`event_type` example + the event_type value, INSTRUCTIONS.md documents the path+event_type centrally in the Phase-5 data-contract table, and the seeder seeds the sink). Because the producer (this skill) and the consumer (the external dashboard) share only this line-oriented contract, the dashboard can ship independently. **Source:** the JSONL schemas in each Round-3 protocol + `INSTRUCTIONS.md` Phase-5 data-contract table.

## ✅ Skill 39 — Real Estate Playbook & Property Intelligence (separate top-level skill)

**Status:** Implemented as the separate top-level skill folder `39-real-estate-playbook/` (a sibling of Skill 38, building the real-estate vertical on top of it; pairs with Skill 40 for pre-foreclosure sourcing).

A real-estate conversational vertical: property lookup / comps / Street View (provider-gated, with an HONEST MVP gap table — REAL vs PROVIDER-GATED vs STUB — so the agent never fabricates property data it cannot source), buyer + seller qualification, a showing scheduler, disclosure/fair-housing compliance, lead routing, open-house handling, and pre-foreclosure outreach (which consumes Skill 40's records). Fair-housing guardrails and the state-disclosure matrix keep the agent compliant; the F52 event contract carries its activity. **Source:** `39-real-estate-playbook/SKILL.md` + `INSTRUCTIONS.md`.

## ✅ Skill 40 — ZHC Public Records Scraper (separate top-level skill)

**Status:** Implemented as the separate top-level skill folder `40-zhc-public-records-scraper/` (feeds Skill 39's pre-foreclosure outreach).

A tiered, compliance-first public-records sourcing engine: **Tier 1** curated counties → **Tier 2** vendor adapters → **Tier 3** operator-buildable scraper config → **Tier 4** honest gap (say so when a record cannot be sourced). It NEVER fabricates a record — compliance and the honesty floor come first, with cost-cap and cache controls so sourcing stays bounded and cheap. **Source:** `40-zhc-public-records-scraper/SKILL.md` + `INSTRUCTIONS.md`.

## Round-3 QC-enforced standards

Three cross-cutting standards are documented references + machine-enforced gates (each wired into `scripts/11-run-qc-checklist.sh` + `.github/workflows/qc-static.yml`):

- **Communication-Playbook standard** — every communications playbook carries the §0 mandatory checklist (channel/persona, opening, goal, the SEND rule, conversation-memory read/append, escalation/honesty, quiet-hours/compliance, the ZHC- tag prefix, per-channel formatting, the 8 channels). Reference `references/communications-playbook-standard.md`; gate `scripts/qc-communications-playbook-standard.sh`.
- **GHL-Raw-Body-JSON standard** — the FLAT 23-key GHL Custom-Webhook Raw Body rule + the exact 23 keys. Reference `references/ghl-raw-body-json-standard.md`; gate `scripts/qc-ghl-raw-body-standard.sh` (composes `qc-23-key-bodies.sh`).
- **Notion-Client-Doc standard** — the ordered mandatory structure of the client-facing doc (Quick-Start first, split Authorization/Content-Type code blocks, FLAT 23-key body, tags-first + manual-fill + Build-with-AI-shape-only + post-build VERIFY, the Communication Playbooks section, how-it-works LAST, Telegram delivery, universal/no-personal-data). Reference `references/notion-client-doc-standard.md`; gate `scripts/qc-notion-doc-standard.sh` (composes `qc-reference-sheet.sh`).

---

# Remaining Round 2 Features (lower priority — DEFERRED, NOT in the v6.0 playbook)

## 📋 Feature 14 — Voice/Phone Integration
## 📋 Feature 15 — Proactive Outreach Campaigns
## 📋 Feature 16 — A/B Testing of Reply Variants
## 📋 Feature 17 — Customer Segmentation Awareness
## 📋 Feature 18 — Webhook Chaining (downstream triggers)
## 📋 Feature 21 — Multi-Tenant Agent Isolation

These six are explicitly NOT implemented in the v6.0 playbook and NOT in skill 38. The skill's structure
(numbered scripts, protocols/ folder, references/) leaves room for them to be added later
without restructuring.

---

# Part 3 — What's NOT on the roadmap

- Customer satisfaction surveys (low signal; sentiment monitoring covers this)
- Chatbot-style FAQ matcher (Convert and Flow snippets cover this)
- In-conversation upselling without consent (bad UX)
- Auto-translation of agent's reply (superseded by Feature 8)

---

# Implementation status (skill 38)

**Shipped in skill 38 (packages playbook v6.x):** All ✅ features above, including the Round-3 wave — the **ZHC- tag-prefix system rule** (Step 9.42) + **F44** (smart playbook switching / interrupts) + **F45** (geo-qualification) + **F46** (CRM field write + create-if-missing) + **F47** (smart FAQ) + **F49** (ZHC Pixel) + **F50** (aggression detection) + the **F52** JSONL data contract (consumed by the external Command Center analytics dashboard) — plus the two sibling vertical skills **Skill 39** (real estate) and **Skill 40** (public-records scraper). Skill 38 packages 39 protocol files (humanizer-protocol.md intentionally NOT shipped — skill 19 owns it).

**Pending (NOT in skill 38):** F14, F15, F16, F17, F18, F21.

---

# Portability statement

All features are platform-neutral. The protocols are markdown instruction documents. If
a client migrates from OpenClaw to another conversational AI platform, these protocols
travel intact.
