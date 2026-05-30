# Skill 38 — Conversational AI System: Operator Instructions

These instructions walk an operator through the v6.0 conversational AI setup on a fresh OpenClaw install. The full source playbook lives at `references/v6.0-source-playbook.md` (9,483 lines, the consolidated v6.0 of the conversational-AI work — v6.0 supersedes the v5.x line). Treat that file as the canonical source of truth. This INSTRUCTIONS.md is the navigational guide — it tells you which Phase to do when and which file owns the detail.

> **Read first:**
> 1. `SKILL.md` (you read it)
> 2. `INSTALL.md` (prerequisites + scripts run order)
> 3. `references/conversational-ai-strategic-roadmap.md` (✅ shipped vs 📋 pending)
> 4. `references/v6.0-source-playbook.md` — the entire thing, in order. Pay special attention to Phase 0 Self-orientation (Steps O.1-O.7), Phase 5 (Steps 9.5-9.36 — the bulk of the playbook), and the Phase 7 Checkpoint F final verification.
> 5. `CORE_UPDATES.md` (what gets appended to workspace AGENTS.md + MEMORY.md)
>
> Per N3, read before act. Per N4, follow steps in declared order. **Do NOT skip a step because "skill X already does something similar."** The skill owner has reviewed the existing skills and made the call: the v6.0 playbook's versions ship in full (see SKILL.md for the only intentional exception — humanizer-protocol.md is NOT shipped; skill 19 owns it).

---

## Phase 0 — Self-orientation (Steps O.1 through O.7)

Source: `references/v6.0-source-playbook.md` lines covering Phase 0 (Steps O.1-O.7).

Key automation in skill 38:

- `scripts/00-verify-prerequisites.sh` — Step O.1 prerequisite verification (skills 05, 10, 19, 29).
- `scripts/01-locate-master-files-folder.sh` — Step O.2 hardened semantic master-folder discovery. If multiple candidates exist, disambiguate; only CREATE a new folder as a last resort with operator approval.

After Phase 0: you have `MASTER_FILES_DIR` set, prerequisites verified, embeddings configured per O.6.

## Phase 1 — Build Network Plumbing (Steps 1-2)

Source: `references/v6.0-source-playbook.md` Steps 1-2 + `references/cloudflare-tunnel-troubleshooting.md` (failure-mode map).

- Step 1 — Create the Cloudflare tunnel via API (remotely-managed; per-tunnel connector token).
- Step 2 — Install cloudflared as a persistent system service (Mac: launchd via `sudo cloudflared service install <TOKEN>`. Linux: systemd post-install of apt package).
- Checkpoint B — tunnel verified end-to-end.

Skill 38 does NOT manage cloudflared installation; that's Phase 1 of the playbook itself. Skill 38 builds the BRAIN that sits behind the tunnel.

## Phase 2 — Configure OpenClaw (Steps 3 through 4)

Source: `references/v6.0-source-playbook.md` Steps 3, 3.5, 4.

- Step 3 — Configure OpenClaw's `hooks.mappings` for GHL inbound.
- Step 3.5 — Model selection wizard (REAL-TIME vs ASYNC tier). Recommend HIGHEST-REASONING available (DeepSeek V4 Pro thinking:max, Kimi 2.6+, etc. — see source playbook for the current recommendation list).
- Step 4 — End-to-end test through the public tunnel.
- Checkpoint C — OpenClaw responds to inbound webhooks.

## Phase 3 — Persist Credentials + Deliverables (Steps 5-6)

Source: `references/v6.0-source-playbook.md` Steps 5-6.

- Step 5 — Save secrets to the env file (per the v6.0 playbook block).
- Step 6 — Generate the Client Reference Sheet (Notion-first; fall back to markdown if no Notion) via `scripts/21-generate-client-reference-sheet.sh`. The generated doc LEADS with the **🚀 Quick Start** copy-paste block and ALSO carries the **Your Communication Playbooks** section (where the client's workflows live + how to ask for a NEW one) AND the **⚙️ Things to consider when installing: VPS (Hostinger Docker) vs Mac mini** section (mirrored from `references/VPS-VS-MAC-INSTALL.md`) — both AFTER the Quick Start, BEFORE the deep Reference & explanation (see Hard rules).
- Step 6.5 — **MANDATORY Telegram doc-delivery (GATED, un-skippable).** Run `scripts/22-notify-client-doc.sh`. It finds the client's Telegram chat id by GREPPING THE TRANSCRIPTS (`agents/*/sessions/*.jsonl`, NOT just `sessions.json` keys — the paired-chat lesson), sends the client their doc LINK via `openclaw message send --channel telegram`, and records `clientDocDelivered=true` in the run manifest. If NO chat is found or the send fails, it FLAGS LOUDLY (stderr) + records `clientDocDelivered=false` and exits non-zero — the install is INCOMPLETE; NEVER silently skip. **The install is not complete until the client has been sent their doc link via Telegram.** Machine-enforced by `scripts/qc-notify-client-doc.sh` (wired into Step 11 QC + CI).
- Checkpoint D — operator has copy-paste materials AND the client has been sent their doc link via Telegram (`clientDocDelivered=true`).

## Phase 4 — Install Agent Behavior (Steps 7-9)

Source: `references/v6.0-source-playbook.md` Steps 7, 8, 9.

- Step 7 — Install inbound message classification rules into AGENTS.md (skill 38's `scripts/05-update-agents-md.sh` handles part of this; the channel-classifying body is in the playbook).
- Step 7.5 — **Preload the CLIENT agent's TOOLS.md with the verified GHL API quick-reference.** Run `scripts/24-update-tools-md.sh`. It idempotently injects the concise, verified GHL Convert-and-Flow API quick-reference (exact method/URL/3 headers/body/scope for every messaging channel type + calendar + appointment + invoice op) into the workspace `TOOLS.md`, so the agent has the canonical request shapes in its **core context** and responds fast at runtime instead of digging through the dense per-module references. WHERE/WHY: shapes belong in **TOOLS.md** (WHERE-THINGS-LIVE), NOT AGENTS.md (WHAT-TO-DO). It is universal (placeholders only — the client's real `PUBLIC_HOSTNAME`, if exported, is written ONLY as an orientation comment, never a token, never client data) and skips cleanly if the marker block is already present. Source of truth: `references/ghl-api-quick-reference.md`. **Machine-enforced** by `scripts/qc-tools-md-ghl-ref.sh` (wired into Step 11 QC + `.github/workflows/qc-static.yml`) — it FAILs if the block is missing any operation/scope, exceeds the concise size budget, or contains any personal/client identifier.
- Step 8 — Scaffold the eight channel communication playbooks in Notion (SMS, Email, FB DM, FB Comments, Instagram DM, LinkedIn, Live Chat, All-in-One Chat).
- Step 9 — Set up the conversation log system. Owned by `protocols/conversation-log-protocol.md` (verbatim from playbook).

## Phase 5 — Install Advanced Features (Steps 9.5 through 9.36) — THE BULK OF THE PLAYBOOK

This is where the bulk of the 32 protocols ship. The mapping table:

| Step | Protocol file in `protocols/` |
|---|---|
| 9.5  | `conversational-safeguards.md` (high-volume, long-conversation pause, bot-detection) |
| 9.6  | `sentiment-monitoring-protocol.md` |
| 9.7  | `pii-scrubbing-protocol.md` |
| 9.8  | `protocols/quiet-hours-protocol.md` (verbatim from playbook lines 2327-2401); AGENTS.md Step 0.5 inserted by `scripts/05-update-agents-md.sh` |
| 9.9  | `protocols/compliance-keyword-detection-protocol.md` (verbatim from playbook lines 2403-2497, FCC STOP/UNSUB + email unsubscribe + GDPR + HIPAA + FINRA/SEC blocks); AGENTS.md Step 0.7 inserted by `scripts/05-update-agents-md.sh` |
| 9.10 | `protocols/multi-language-detection-protocol.md` (verbatim from playbook lines 2499-2545); also `protocols/conversation-log-protocol.md` adds the `preferred_language` header field; also surfaced as Section 7 of `templates/agent-capabilities-playbook-template.md` |
| 9.11 | `confidence-threshold-protocol.md` |
| 9.12 | `conversation-export-protocol.md` |
| 9.13 | `drift-detection-protocol.md` |
| 9.14 | `knowledge-source-protocol.md` (older v5.1; preserved alongside v5.6's typed-knowledge-bases-protocol.md) |
| 9.15 | `prompt-injection-protection-protocol.md` |
| 9.16 | `notification-routing-protocol.md` |
| 9.17 | `conversation-analytics-protocol.md` |
| 9.18 | `document-generation-protocol.md` |
| 9.19 | `smart-booking-protocol.md` |
| 9.20 | `protocols/conversation-workflows-protocol.md` (verbatim 3-Layer architecture from playbook lines 3857-4322); registry scaffolded by `scripts/09-install-conversation-workflows.sh`; trigger phrases wired into AGENTS.md Step 1.85 by `scripts/05-update-agents-md.sh`. **BINDING — per-playbook human-facing doc:** `scripts/09-install-conversation-workflows.sh` ALSO creates, for every conversation playbook (starting with the appointment-booking starter), a human-facing copy in the CLIENT's account following the fallback chain **Notion → Google Docs → plain text** and records its URL/path on the registry row + the run-manifest `playbookDocs[]`. This is machine-enforced by `scripts/qc-playbook-doc.sh` (wired into Step 11 QC + CI) — see the BINDING rule below. |
| 9.21 | **Humanizer** — skill 19 (NOT shipped here; ALWAYS-ON via skill 38's AGENTS.md Step 2.8) |
| 9.22 | `typed-knowledge-bases-protocol.md` |
| 9.23 | `sales-best-practices-protocol.md` + `references/sales-frameworks-deep-dive.md` |
| 9.24 | `web-scraper-protocol.md` |
| 9.25 | `intelligent-followup-protocol.md` (the 10 touchpoints; first 5 in first 72 hours) |
| 9.26 | `discount-code-protocol.md` + `references/ghl-coupons-api.md` + `references/stripe-coupons-api.md` |
| 9.27 | `stripe-integration-protocol.md` + `references/stripe-webhooks-reference.md` (operator opt-in via `scripts/07-stripe-setup-wizard.sh`) |
| 9.28 | Customer Journey Templates — `templates/journey-templates/` (coach + 7 stubs + `registry.md`) |
| 9.29 | `business-logic-workflow-suggestions-protocol.md` |
| 9.30 | `customer-service-support-protocol.md` (dual-mode) |
| 9.31 | `shopify-integration-protocol.md` + `references/shopify-graphql-reference.md` (operator opt-in via `scripts/08-shopify-setup-wizard.sh`) |
| 9.32 | `weekly-tune-up-protocol.md` (Sunday 2am cron via `scripts/04-register-crons.sh`) |
| 9.33 | `intelligent-routing-protocol.md` |
| 9.34 | `proactive-suggestions-protocol.md` (Saturday 11pm cron) |
| 9.35 | `monthly-comprehensive-review-protocol.md` (1st-of-month cron) |
| 9.36 | `model-version-freshness-protocol.md` (bundled into Saturday 11:30pm cron) |

### Round-3 Queue-A feature wave (Steps 9.37–9.41, shipped v1.5.0)

These five behavioral steps extend Phase 5. Each owns a `protocols/<name>-protocol.md`, a new AGENTS.md step (inserted ONLY by `scripts/05-update-agents-md.sh` marker blocks), and an `openclaw.json` toggle and/or a JSONL log (the F52 data contract, documented below). The cross-cutting **ZHC- tag-prefix rule** governs every programmatic tag any of them creates (`protocols/zhc-tag-prefix-protocol.md`, MEMORY.md Rule 20, AGENTS.md marker `STEP_TAG_PREFIX`); CRM custom fields the agent creates use the parallel `ZHC_` prefix.

| Step | Protocol | AGENTS.md | openclaw.json toggle | JSONL log |
|---|---|---|---|---|
| 9.37 | `aggression-detection-protocol.md` (F50 — EXTENDS the Safeguard family / Step 9.5; bot detection NOT rebuilt) | Step 1.35 (PRE-routing, pre-LLM-spend; marker `STEP_1_35_AGGRESSION`) | `aggression_detection.enabled` (default `true`), `aggression_detection.sensitivity` (`lenient`\|`standard`\|`strict`, default `standard`) | `aggression-detection-log.jsonl` (+ `aggression-detection-log.md`) |
| 9.38 | `smart-playbook-switching-protocol.md` (F44 — DETOUR-AND-RETURN; DISTINCT from F33 route-and-stay at Step 9.33) | Step 2.0 (always-listening layer; marker `STEP_2_0_INTERRUPTS`) | — | `interrupt-log.jsonl` |
| 9.39 | `geo-qualification-protocol.md` (F45 — HINTS only, ALWAYS confirm before disqualifying) | Step 2.5 (marker `STEP_2_5_GEO`) | `geo_qualification.enabled` (default `false`/OFF) | `geo-qualification-log.jsonl` |
| 9.40 | `crm-field-write-protocol.md` (F46 — type-aware write + create-if-missing `ZHC_…`; operator-approved allow-list, never customer-invoked) | tag/field note (marker `STEP_TAG_PREFIX`) | — | `crm-field-writes-log.jsonl` |
| 9.41 | `smart-faq-tool-protocol.md` (F47 — lightweight sibling of F44: a SENTENCE, not a sub-flow) | Step 2.0 (same always-listening layer; marker `STEP_2_0_INTERRUPTS`) | — | `faq-detour-log.jsonl` |

Supporting data files (seeded idempotently by `scripts/25-seed-round3-feature-files.sh`, never overwriting operator content): `KnowledgeBases/sales/service-areas.md` (F45, per-product ZIP/county/state/radius), `KnowledgeBases/business/faqs.md` (F47, Q/A pairs; per-workflow scope in `conversation-workflows/<id>/faq-scope.md`), `crm-field-mappings.md` (F46, per-workflow field map).

#### F52 data contract — JSONL log schemas (centralized)

Every Round-3 feature emits a JSONL log (one JSON object per line) at the documented `<MASTER_FILES_DIR>` path. Every line carries `timestamp` (ISO-8601 UTC) + `event_type` + the event's data. The full per-field schema for each lives in its protocol; the index of path → `event_type`(s):

| JSONL path (under `<MASTER_FILES_DIR>`) | `event_type`(s) | owning protocol |
|---|---|---|
| `aggression-detection-log.jsonl` | `aggression_detected` (Tier 2), `tension_detected` (Tier 1) | `aggression-detection-protocol.md` |
| `interrupt-log.jsonl` | `interrupt_detour` | `smart-playbook-switching-protocol.md` |
| `geo-qualification-log.jsonl` | `geo_qualification` | `geo-qualification-protocol.md` |
| `crm-field-writes-log.jsonl` | `crm_field_write` | `crm-field-write-protocol.md` |
| `faq-detour-log.jsonl` | `faq_answered` | `smart-faq-tool-protocol.md` |

These logs feed F52 analytics and the F35 weekly tune-up (which also reviews `ZHC_`-field usage per F46). The data contract is machine-enforced by `scripts/qc-feature-logs.sh` (path + timestamp+event_type example documented in the protocol AND here, and seeded by script 25); the ZHC- tag-prefix rule is machine-enforced by `scripts/qc-zhc-tag-prefix.sh` (both wired into `scripts/11-run-qc-checklist.sh` + CI).

## Phase 6 — Document Agent Capabilities (Step 10)

Source: `references/v6.0-source-playbook.md` Step 10.

Generates the agent-capabilities-playbook.md the operator references during day-to-day use.

## Phase 7 — Full QC + Hand-off (Step 11)

Source: `references/v6.0-source-playbook.md` Step 11 (Checkpoint F).

Full pre-handoff QC checklist. Do NOT declare done until every item passes. Refer to the playbook for the checklist contents — verbatim, no summarization, no condensation.

- Step 11.5 — **AI BACKEND SELF-TEST (BLOCKING — the agent tests ITSELF before the client).** Run `bash scripts/24-self-test-hook.sh --live`. It (a) confirms the backend is prepared to receive (hooks.enabled, an inbound mapping with a working model, `deliver:false`, node-owned `conversational-logs/`, GHL creds in `secrets/.env`, gateway healthz 200), (b) POSTs a SYNTHETIC FLAT 23-key GHL inbound (channel sms, a dedicated throwaway test contact) to its OWN public hook with the real Bearer token, and (c) VERIFIES by ground truth: the hook returns 200/{ok:true}, the run used the configured model with NO 401/429, the agent READ the conversation log, and the GHL Conversations API send returned a messageId — then DELETES the temp contact + test log. If ANY step fails, the agent FIXES the cause (creds/location, model/provider key, DND, `secrets/.env` placement, URL/route/token) and RE-RUNS until GREEN. **Setup is NOT marked complete and the client is NOT told to test until this self-test passes.** Wired as a blocking gate in `scripts/11-run-qc-checklist.sh`; the standard is documented in `references/GHL-INBOUND-AND-PLAYBOOKS.md` §4.5.

---

## Cron schedule shipped by skill 38

| Cron | Schedule | What it runs |
|---|---|---|
| `weekly-tune-up` | `0 2 * * 0` (Sunday 2am) | `protocols/weekly-tune-up-protocol.md` |
| `proactive-suggestions-scan` | `0 23 * * 6` (Saturday 11pm) | `protocols/proactive-suggestions-protocol.md` |
| `model-version-freshness` | `30 23 * * 6` (Saturday 11:30pm) | `protocols/model-version-freshness-protocol.md` |
| `monthly-comprehensive-review` | `0 3 1 * *` (1st of month 3am) | `protocols/monthly-comprehensive-review-protocol.md` |

Sunday 2am is intentional: it runs BEFORE Dreaming's 3am nightly pass, so the tune-up gets the freshest week of data without conflicting with consolidation.

---

## Hard rules (NON-NEGOTIABLE)

- **Per-playbook human-facing DOC (BINDING — state-gated, un-skippable).** When a communications/conversation playbook is created (the base install creates the FIRST one — appointment booking), the install is **NOT complete** until that playbook's human-facing doc has been created in the **CLIENT's own account** following the fallback order **Notion → Google Docs → plain text**, and its URL/path is **recorded** as a `playbookDocs[]` entry in the run manifest (and on the playbook's registry row). This mirrors the send-directive / conversation-memory gates: prose is not enforcement, so it is enforced by a **state field** (`playbookDocs[]`) + a **verify/resume self-check** + a **QC gate**. **Verify/resume self-check:** before declaring the conversation-workflows step (Step 9.20) or the whole install done, run `bash scripts/qc-playbook-doc.sh`; if it exits non-zero (a playbook has NO recorded doc) or exits 2 (no playbook exists yet though one was expected), the doc step was skipped — **re-run `scripts/09-install-conversation-workflows.sh` to create+record the missing doc, then re-check.** Do NOT proceed to hand-off until it exits 0. A skipped doc strands the customer (no human-facing reference of what was set up) and is a hand-off blocker, not a warning. Machine-enforced by `scripts/qc-playbook-doc.sh` (wired into `scripts/11-run-qc-checklist.sh` + `.github/workflows/qc-static.yml`).
- **MANDATORY Telegram doc-delivery (BINDING — state-gated, un-skippable).** The install is **NOT complete** until the client has been **sent their Quick-Start / Notion doc LINK via Telegram** (`openclaw message send --channel telegram -t <chat>`). Prose is not enforcement: this is gated by the `clientDocDelivered` state field in the run manifest + the `scripts/22-notify-client-doc.sh` step + the `scripts/qc-notify-client-doc.sh` QC gate (wired into `scripts/11-run-qc-checklist.sh` + CI). The delivery script finds the client's chat id by **grepping the transcripts** (`agents/*/sessions/*.jsonl`, scoring the most-frequent non-operator id — NOT just `sessions.json` keys, which miss paired chats; the paired-chat lesson). If NO chat is found or the send fails, it FLAGS LOUDLY and records `clientDocDelivered=false` and the install is marked incomplete — **NEVER silently skip.** **Every client gets their link via Telegram, no matter what.**
- **Completion gates — doc exists AND backend ready, BEFORE testing (BINDING).** The install is not "complete" until BOTH: (1) the client doc exists with the **FLAT 23-key** body + **Quick-Start** structure (machine-enforced by `scripts/qc-reference-sheet.sh` — the generator emits the canonical 23-key flat body and `scripts/qc-23-key-bodies.sh` asserts exactly 23 flat placeholder-free keys), AND (2) the backend is **ready to RECEIVE** — `hooks.mappings` live + `deliver:false` + a working `model` + gateway `healthz` 200 (machine-enforced by `scripts/qc-backend-ready.sh`, wired into Step 11 QC). **Testing only happens after both pass.**
- **"Your Communication Playbooks" section in the client doc (BINDING).** The generated client doc (`scripts/21-generate-client-reference-sheet.sh`) MUST include a prominent **Your Communication Playbooks** section placed AFTER the Quick Start and BEFORE the deep how-it-works. It tells the client (a) WHERE their playbooks live — their OpenClaw master-files `conversation-workflows/` folder + the human-facing copies in Notion (Notion → Google Docs → text), and (b) in BIG BOLD, **"Want a NEW communications playbook? Start here:"** — just tell your AI "help me build a [purpose] playbook" and it brainstorms with you and builds all 3 parts (the workflow-AI prompt, the conversation playbook, the GHL automation). It ALSO explains (c) the personal **trigger word** (🔑 voice-assistant style — "like Alexa/Hey Siri", e.g. *"Playbook time!"*), (d) the **"I Do / You Do" process** (🤝 who does what) and that a good playbook takes **~15-30 minutes** (⏱️), and (e) the **brainstorm "things to think about"** (🧠 goal / audience / channel / offer / tone / timing / win action — "if you're unsure, that's what I'm here to brainstorm"). Same standard appears in `references/workflow-ai-instructions-standard.md` + `references/communications-playbook-standard.md`. The matching AGENT BEHAVIOR (offer+confirm+remember the trigger word, present I-Do/You-Do, run the brainstorm) is in `protocols/conversation-workflows-protocol.md` Section A.0/A.1/A.2 + Part 3. Machine-enforced by `scripts/qc-reference-sheet.sh`.
- **"⚙️ VPS-vs-Mac install considerations" section in the client doc (BINDING).** The generated client doc (`scripts/21-generate-client-reference-sheet.sh`) MUST include a **⚙️ Things to consider when installing: VPS (Hostinger Docker) vs Mac mini** section, placed AFTER the Quick Start and BEFORE the deep Reference & explanation. It carries (a) the VPS points — host `/docker/<project>/.env` + `docker compose up -d --force-recreate` (plain restart ignores `env_file`), GHL/provider creds ALSO in the container `/data/.openclaw/secrets/.env`, the `/hostinger/server.mjs` wrapper rewriting `hooks.token` each boot UNLESS `OPENCLAW_HOOKS_TOKEN` is set in the host `.env`, the gateway port often NOT being 18789, cloudflared-via-PM2 / Traefik, and `apt` being a brew shim — and (b) the Mac points — provider keys in the `openclaw.json` top-level `env` block (the launchd service-env / `~/.openclaw/.env` alone are insufficient), GHL creds in `~/.openclaw/secrets/.env`, restart via `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway`, Cloudflare-tunnel + Access-token remote access, and `sudo cloudflared service install <token>` — plus the COMMON-to-both invariants (23-key FLAT body, node-owned `conversational-logs/`, GHL creds in `secrets/.env`, `deliver:false`, Ollama Cloud `:cloud` `maxTokens` capped at 65536). The single source is `references/VPS-VS-MAC-INSTALL.md` (edit both in lockstep). Machine-enforced by `scripts/qc-reference-sheet.sh` (also via the `--require-manual-fill` flag) — it FAILs the generated doc if the section is missing OR if either the VPS (force-recreate / container `secrets/.env` / `OPENCLAW_HOOKS_TOKEN`) or Mac (`openclaw.json` env block / `launchctl kickstart`) points are absent.
- **Workflow-AI STANDARDIZATION (BINDING — same output every run).** Every workflow-AI instruction set this skill emits MUST contain ALL FIVE mandatory inclusions, in this exact order, for EVERY client (only the substituted values change): (1) workflow name + PUBLISH; (2) Trigger: type + sub-option + filters in exact order; (3) **Settings → Allow Re-entry = ON** (the workflow must be allowed to re-enter / fire repeatedly per contact, or it fires once then goes dead); (4) Custom Webhook — every field with the exact value (EVENT/METHOD/URL/AUTHORIZATION dropdown/both HEADERS as Key+Value/CONTENT-TYPE/full FLAT 23-key RAW BODY); (5) Save → Publish toggle ON → Save. The single standard is `references/workflow-ai-instructions-standard.md` §0; `scripts/21-generate-client-reference-sheet.sh` + `templates/sms-workflow-ai-prompt-template.md` emit it verbatim; machine-enforced by `scripts/qc-reference-sheet.sh` (Allow Re-entry marker included).
- **Client SELF-TEST section in the doc (BINDING).** The generated client doc MUST carry a **🧪 How to test your system** section: Contacts (left menu) → search your own name → open your own contact record → send yourself a text → reply from your phone → Automations → open the workflow → **Execution Logs** → every step green (ESPECIALLY the Custom Webhook); anything red = failure (re-run the verification checklist / contact support). Machine-enforced by `scripts/qc-reference-sheet.sh`.
- **AI BACKEND SELF-TEST before the client (BINDING — blocking gate).** See Phase 7 Step 11.5. The agent self-tests the full inbound→reply chain by ground truth (synthetic 23-key POST to its own hook → hook 200 → configured model with no 401/429 → read the log → GHL send returned a messageId → cleanup) and FIXES + RE-TESTS until green BEFORE marking complete or telling the client to test. Executable gate `scripts/24-self-test-hook.sh`; standard in `references/GHL-INBOUND-AND-PLAYBOOKS.md` §4.5; wired into `scripts/11-run-qc-checklist.sh` + CI.
- **UNIVERSAL skill — NO personal/client data (BINDING).** This skill installs the SAME brain for any client. No real names or client data (operator names, client names, real hostnames, real tokens, real location ids, real phone/email, real Telegram ids) may appear ANYWHERE in the skill or in the doc it generates — use generic placeholders (`<CLIENT_BUSINESS_NAME>`, `<PUBLIC_HOSTNAME>`, `<HOOKS_TOKEN>`, `<LOCATION_ID>`, "the operator", "your setup admin"). Machine-enforced by `scripts/qc-no-personal-data.sh`, which scans the whole tree AND the generated reference sheet and FAILS (and is negative-tested) on any forbidden identifier (wired into `scripts/11-run-qc-checklist.sh` + CI).
- **ZHC- tag namespace + ZHC_ field namespace (BINDING — v1.5.0).** Every tag the agent CREATES programmatically MUST be `ZHC-` prefixed; every CRM custom field it creates MUST be `ZHC_` prefixed. NOT retroactive — never rename operator/human/3rd-party tags or fields. CRM field writes/creates are an OPERATOR-APPROVED allow-list action, NEVER customer-invoked. Source: `protocols/zhc-tag-prefix-protocol.md` + `protocols/crm-field-write-protocol.md` + MEMORY.md Rule 20. Machine-enforced by `scripts/qc-zhc-tag-prefix.sh`.
- **Aggression: ALL CAPS ALONE never fires; geo: ALWAYS confirm before disqualifying (BINDING — v1.5.0).** F50 (`aggression-detection-protocol.md`, Step 1.35, PRE-routing) is a two-tier classifier that EXTENDS the Safeguard family — it does NOT rebuild bot detection; an all-caps message with no profanity/threat/other signal is not aggression. F45 (`geo-qualification-protocol.md`, opt-in via `geo_qualification.enabled`, default OFF) treats location signals as HINTS and NEVER disqualifies a customer without confirming their actual service location first. F44 (`smart-playbook-switching-protocol.md`, Step 2.0) is DETOUR-AND-RETURN and is DISTINCT from F33 route-and-stay (Step 9.33).
- **F52 data contract (BINDING — v1.5.0).** Each Round-3 feature emits a JSONL log (timestamp + event_type + event data) at its documented `<MASTER_FILES_DIR>` path; the schema is documented in the protocol AND in INSTRUCTIONS.md, and the sink is seeded by `scripts/25-seed-round3-feature-files.sh`. Machine-enforced by `scripts/qc-feature-logs.sh`.
- **Honesty floor** (per `sales-best-practices-protocol.md` + `customer-service-support-protocol.md`): never fabricate, never deceive, never false urgency, never promise refunds/exceptions without operator approval.
- **Cost caps** (per `web-scraper-protocol.md`): scrapes estimated over $5 require double-confirmation; over $25 are refused.
- **Operator approval requirements** (per `model-version-freshness-protocol.md`): never auto-update primary models. Always surface, always ask, always wait for YES/NO/DEFER.
- **Allow-list actions** (numbered 1-17 in the playbook): the agent's actions are gated to this list. Adding a new action requires updating both AGENTS.md and the relevant protocol file.

## Room for future features (per the strategic roadmap)

The roadmap shows 6 features pending after the v6.0 playbook (F14 Voice, F15 Proactive Outreach Campaigns, F16 A/B Testing, F17 Segmentation, F18 Webhook Chaining, F21 Multi-Tenant Isolation). The skill's structure is designed to absorb them without restructuring:

- `scripts/` folder is numbered 00-24 with room to grow (a new numbered script slots in at the next free index; the QC linters live alongside them as `qc-*.sh`).
- `protocols/` folder lists by name, not number — new protocols slot in alphabetically without reflow.
- `references/` accommodates new deep-dives without disturbing existing ones.
- `CORE_UPDATES.md` is semver-tagged so future versions land naturally.

Do NOT try to implement any of the pending features inside skill 38. They are explicitly out of scope for the v6.0 playbook.
