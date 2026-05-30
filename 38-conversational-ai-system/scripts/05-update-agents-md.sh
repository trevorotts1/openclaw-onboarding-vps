#!/usr/bin/env bash
# 05-update-agents-md.sh
#
# Idempotently inserts skill-38 marker blocks into the workspace AGENTS.md:
#   (a) INBOUND_WEBHOOK_CLASSIFICATION   — verbatim Step 7C block from v5.14 playbook lines 1537-1645
#   (b) SKILL38_RUNTIME_ROUTING          — skill-38 runtime routing steps (1.7 / 1.75 / 1.8 / 1.9 / 2.8)
#   (c) AGENTS.md Step 0.5               — Quiet Hours (Step 9.8 → quiet-hours-protocol.md)
#   (d) AGENTS.md Step 0.7               — Compliance Keywords (Step 9.9 → compliance-keyword-detection-protocol.md)
#   (e) AGENTS.md Step 1.85              — Workflow Builder trigger phrases (Step 9.20 → conversation-workflows-protocol.md)
#
# Each block is wrapped in BEGIN/END markers so this script is safe to run
# repeatedly. Existing content is preserved; missing blocks are appended.
# A timestamped backup is made before any write.
#
# OS-aware: Darwin → $HOME/clawd/AGENTS.md
#           Linux  → /data/clawd/AGENTS.md

set -euo pipefail

# -----------------------------------------------------------------------------
# Resolve AGENTS.md location (matches existing skill-38 convention)
# -----------------------------------------------------------------------------
OS_NAME="$(uname -s)"
if [[ "$OS_NAME" == "Darwin" ]]; then
  AGENTS_MD="${AGENTS_MD:-$HOME/clawd/AGENTS.md}"
else
  AGENTS_MD="${AGENTS_MD:-/data/clawd/AGENTS.md}"
fi

if [[ ! -f "$AGENTS_MD" ]]; then
  echo "[05-update-agents-md] AGENTS.md not found at: $AGENTS_MD" >&2
  echo "[05-update-agents-md] Set AGENTS_MD env var or create the file first." >&2
  exit 1
fi

# Backup (timestamped, only if not already backed up in the same second)
BACKUP="${AGENTS_MD}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -p "$AGENTS_MD" "$BACKUP"
echo "[05-update-agents-md] Backup written → $BACKUP"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
have_marker() {
  # $1 = marker name
  grep -q "<!-- BEGIN SKILL38: $1 -->" "$AGENTS_MD"
}

append_block() {
  # $1 = marker name, stdin = body content
  local name="$1"
  if have_marker "$name"; then
    echo "[05-update-agents-md] block '$name' already present — skipping"
    return 0
  fi
  {
    printf '\n<!-- BEGIN SKILL38: %s -->\n' "$name"
    cat
    printf '\n<!-- END SKILL38: %s -->\n' "$name"
  } >> "$AGENTS_MD"
  echo "[05-update-agents-md] block '$name' appended"
}

# -----------------------------------------------------------------------------
# (a) INBOUND_WEBHOOK_CLASSIFICATION — verbatim Step 7C from v5.14 lines 1537-1645
# -----------------------------------------------------------------------------
append_block "INBOUND_WEBHOOK_CLASSIFICATION" <<'BLOCK_A'

## Inbound Webhook Message Classification (added by OpenClaw GHL Webhook Playbook v5.4)

> **MANDATORY SEND RULE (binding base rule).** For ANY GHL inbound hook,
> SENDING the reply via the GHL Conversations API (POST conversations/messages,
> per TOOLS.md) is MANDATORY — a drafted-but-unsent reply is a failure, the
> customer receives nothing. Always make the send call and confirm a
> messageId/conversationId before ending the turn. Composing or drafting is NOT
> sending.

When you receive an isolated agent turn from `/hooks/ghl-inbound` (or any
`hook:ghl:*` session key), the message body in your prompt is the rendered
output of a server-side template containing the customer's actual message,
their contact ID, and their location ID.

### Step 1 — Classify before replying

Read the customer's message and silently classify it into ONE of these four
categories. Do NOT echo the classification to the customer.

1. **REPLY** — A genuine inbound from a human customer. The message asks a
   question, requests something, expresses an emotion that warrants a
   response, or continues a real conversation. Reply on the matching
   channel using the appropriate communication playbook.

2. **CONFIRM_OUTBOUND** — The webhook is firing because the agent (or a
   teammate) just sent the customer something OUT. The "message" here is
   the agent's own outbound text being looped back. Acknowledge silently
   (no reply needed) and exit. Do NOT reply to your own outbound.

3. **AUTOMATED_NOISE** — System-generated noise: appointment reminder
   confirmations the customer didn't initiate, drip-campaign deliveries,
   bulk-blast acknowledgements, opt-in confirmations, "Your message has
   been received" auto-replies, payment receipts, calendar invitations the
   agent itself just sent, two-factor authentication codes echoing back,
   carrier delivery receipts, read receipts. Exit silently.

4. **NEEDS_HUMAN** — Anything explicitly requesting a human ("speak to a
   person," "is this a bot?", "stop messaging me," abusive language,
   legal threat, refund demand the agent can't fulfill, complex
   complaint, escalation language). Escalate to the operator via the
   configured operator-notify channel and exit without auto-replying to
   the customer.

### Classification heuristics

Use these signals when deciding the category:

- Direction: webhook payload `direction == "inbound"` is the first
  signal, but a real human-typed inbound can sit alongside outbound
  auto-replies in the same conversation thread. Don't trust direction
  alone — read the actual content.
- Customer-typed vs system-generated: short structured tokens (codes,
  one-letter responses to system prompts, "Y"/"N" without context) are
  often noise; conversational prose is usually a real reply.
- Self-echo: if the message content closely matches the agent's most
  recent outbound, treat it as CONFIRM_OUTBOUND.
- Escalation language: any of "speak to a human", "real person", "stop",
  "unsubscribe", "cancel", "lawyer", "report you", "refund me now",
  "this is unacceptable" → NEEDS_HUMAN.
- Channel norms: SMS short codes / opt-out keywords (STOP, HELP, etc.)
  → AUTOMATED_NOISE for STOP/HELP that the carrier handles, NEEDS_HUMAN
  for any other language matching escalation.

### Step 2 — If REPLY: choose the channel-specific communication playbook

The webhook payload tells you which channel the inbound came in on:
SMS, Email, FB Messenger, Instagram DM, GMB chat, GBP chat, WhatsApp,
or a generic "Conversations" inbound. Match the channel to the
corresponding communication playbook in `<MASTER_FILES_DIR>/communication-playbooks/`:

- `<MASTER_FILES_DIR>/communication-playbooks/sms-communication.md`
- `<MASTER_FILES_DIR>/communication-playbooks/email-communication.md`
- `<MASTER_FILES_DIR>/communication-playbooks/facebook-messenger-communication.md`
- `<MASTER_FILES_DIR>/communication-playbooks/instagram-dm-communication.md`
- `<MASTER_FILES_DIR>/communication-playbooks/gmb-chat-communication.md`
- `<MASTER_FILES_DIR>/communication-playbooks/gbp-chat-communication.md`
- `<MASTER_FILES_DIR>/communication-playbooks/whatsapp-communication.md`
- `<MASTER_FILES_DIR>/communication-playbooks/conversations-communication.md`

Read the matching playbook before drafting your reply. It contains the
tone, signature, escalation triggers, and brand voice for that channel.

### Step 3 — Send the reply via the GHL skill (drafting is NOT sending)

Use the installed GHL skill (`openclaw skills | grep ghl`) to SEND the
reply back on the same channel via the GHL Conversations API. Do NOT post
directly to the GHL API yourself — the skill handles auth, rate limits, and
retries. Drafting/composing a reply is NOT sending — you MUST make the send
call. Do NOT end your turn until the send returns a messageId/conversationId
(per the MANDATORY SEND RULE above).

### Pointers (always-read references)

- AGENTS.md (this file) — your behavioral OS.
- MEMORY.md — long-term memories the agent has learned.
- IDENTITY.md — who you are and how you communicate.
- TOOLS.md — every connected tool, with usage examples.
- USER.md — the operator's profile and preferences.
- SOUL.md — the agent's core mission and values.
- Communication Playbooks — `<MASTER_FILES_DIR>/communication-playbooks/`
- GHL skill — How to actually call the GHL Conversations, Calendars,
  and Payments APIs (installed on every client by default)

BLOCK_A

# -----------------------------------------------------------------------------
# (a2) CONVERSATION_MEMORY_PROTOCOL — base rule making the per-contact
#      conversation log un-droppable. GHL inbound hook sessions are SINGLE-TURN
#      (every hook run = a fresh stateless session, user-turns=1); the agent's
#      ONLY memory across messages is the per-contact log file. Pointer-style,
#      no bloat — the full rules live in conversation-log-protocol.md.
# -----------------------------------------------------------------------------
append_block "CONVERSATION_MEMORY_PROTOCOL" <<'BLOCK_A2'

## Conversation Memory Protocol (binding base rule)

> GHL inbound hook sessions are SINGLE-TURN / stateless — every inbound is a
> fresh session with no chat history. Your ONLY memory of a contact across
> messages is the per-contact conversation log. There is nothing else to fall
> back on, so treat the log as mandatory, not optional.

On EVERY GHL inbound, in this order:

1. **READ BEFORE replying.** Read this contact's log at
   `<MASTER_FILES_DIR>/conversational-logs/<contact_id>__<name>.md`. It holds the
   full prior conversation plus any in-progress booking/topic. If the file is
   missing, treat this as a new contact.
2. **CONTINUE, don't restart.** Reply continuing whatever the log shows is
   in-progress — don't re-ask what the log already answers (e.g. a booking
   half-finished must be resumed, not started over).
3. **APPEND AFTER sending.** After the GHL send returns a messageId/conversationId,
   append BOTH the inbound message and your sent reply to the same log file
   (create it if missing) per `conversation-log-protocol.md`.

A reply that ignores the log, or that fails to update it after sending, is a
FAILURE — it is how the agent "forgets" mid-conversation. Full retention/format
rules: `<MASTER_FILES_DIR>/conversation-log-protocol.md`.

BLOCK_A2

# -----------------------------------------------------------------------------
# (b) SKILL38_RUNTIME_ROUTING — preserves the existing 53-line script's content
#     (Steps 1.7 / 1.75 / 1.8 / 1.9 / 2.8) inside a single marker block
# -----------------------------------------------------------------------------
append_block "SKILL38_RUNTIME_ROUTING" <<'BLOCK_B'

## Skill-38 Runtime Routing (added by skill-38 installer)

### Step 1.7 — Channel auto-detection

Before drafting any reply, inspect the inbound webhook payload's channel
field (sms / email / facebook / instagram / gmb / gbp / whatsapp /
conversations). Bind it to `$REPLY_CHANNEL` for the rest of the turn.
If the channel cannot be determined, escalate to NEEDS_HUMAN per Step 7C
classification rather than guessing.

### Step 1.75 — Read the per-channel communication playbook

Open the matching playbook in `<MASTER_FILES_DIR>/communication-playbooks/`
(see Step 7C list). Apply its tone, signature, and escalation triggers as
the baseline for every reply on this channel.

### Step 1.8 — Apply the active Conversation Workflow (if any)

If the inbound matches a trigger in `<MASTER_FILES_DIR>/conversation-workflows/registry.md`,
follow that workflow's `<workflow-id>.md` (a communications playbook — format/standard:
references/communications-playbook-standard.md) for phase-specific behavior. The
workflow's instructions override the channel playbook for the duration of
that scenario. Always honor the channel playbook's baseline tone/signature.
Reply via the GHL Conversations API per TOOLS.md. These playbooks belong to
THE TRINITY (workflow + communications playbook + workflow-AI prompt) —
protocols/conversation-workflows-protocol.md.

### Step 1.9 — Log the turn after sending

After the GHL skill confirms delivery, append BOTH the inbound and
outbound to the contact's log file per `conversation-log-protocol.md`.
Never log before sending; never claim delivery without the skill's
confirmation.

### Step 2.8 — Cross-channel formatting

For every outbound, apply the channel-specific formatting rules from
`<MASTER_FILES_DIR>/agent-capabilities-playbook.md` Section 3
(SMS = no markdown / short paragraphs; Email = subject lines + signature;
DMs = short paragraphs, no formal sign-off; Voice channels = plain text
that reads aloud naturally).

BLOCK_B

# -----------------------------------------------------------------------------
# (c) STEP_0_5_QUIET_HOURS
# -----------------------------------------------------------------------------
append_block "STEP_0_5_QUIET_HOURS" <<'BLOCK_C'

## Step 0.5 — Quiet Hours

Before sending any proactive outbound (drip, follow-up, scheduled
notification, operator alert that isn't tagged urgent), consult the
quiet-hours protocol:

  <MASTER_FILES_DIR>/quiet-hours.md
  Skill reference: protocols/quiet-hours-protocol.md

Reactive replies to a customer-initiated message bypass quiet hours.
Proactive sends during a quiet window queue for the next valid send
window. Per-customer override: if a contact has explicitly asked for
24/7 contact, honor that.

BLOCK_C

# -----------------------------------------------------------------------------
# (d) STEP_0_7_COMPLIANCE_KEYWORDS
# -----------------------------------------------------------------------------
append_block "STEP_0_7_COMPLIANCE_KEYWORDS" <<'BLOCK_D'

## Step 0.7 — Compliance Keywords (regulatory hard-gate)

Before any other processing on an inbound, scan the customer's message
against the compliance keyword list:

  <MASTER_FILES_DIR>/compliance-keywords.md
  Skill reference: protocols/compliance-keyword-detection-protocol.md

If any compliance trigger fires (FCC STOP/UNSUB, email unsubscribe,
GDPR data-access/data-deletion request, HIPAA mention of protected
health information, FINRA/SEC investment-advice block), follow the
specified action for that trigger and exit. Compliance overrides every
other rule — including reply, escalation, and channel routing.

BLOCK_D

# -----------------------------------------------------------------------------
# (e) STEP_1_85_WORKFLOW_BUILDER_TRIGGERS
# -----------------------------------------------------------------------------
append_block "STEP_1_85_WORKFLOW_BUILDER_TRIGGERS" <<'BLOCK_E'

## Step 1.85 — Conversation Workflow Builder trigger phrases

If the operator (NOT a customer) sends the agent a message matching any
of these intent phrases, route the request into the Conversation Workflow
Builder protocol at:

  protocols/conversation-workflows-protocol.md

Trigger phrases (case-insensitive, fuzzy match):

- "Help me build a conversation playbook"
- "Help me build a conversation workflow"
- "Build me a workflow for <X>"
- "Build me a playbook for <X>"
- "Create a workflow for <X>"
- "Create a playbook for <X>"
- "Set up a conversation flow for <X>"
- "I want a workflow that does <X>"
- "Walk me through building a workflow"

When triggered, hand control to the Workflow Builder subagent walkthrough
(Section B / "THE 3-PART BUILD" of the protocol). Run a FRIENDLY brainstorm
— do NOT dump 50 questions: use what you already know about this client
(Typed Knowledge Bases + USER.md + MEMORY.md), ask ONLY the smart gaps, then
regurgitate a concise "is this what you want to happen?" summary as the final
confirmation before building.

On YES, produce ALL THREE parts (never stop after one):
  Part 1 — Build-with-AI prompt (+ manual-build fallback + verification
           checklist). GHL Automations have NO API and NO MCP — the only
           programmatic path is GHL's "Build with AI" button; the prompt
           nails the funnel SHAPE, operator pastes token/URL/Raw-Body values.
  Part 2 — the Layer 2 conversation playbook (conversation-workflows/<id>.md),
           registered in conversation-workflows/registry.md.
  Part 3 — the human-facing doc for the playbook in the CLIENT's account
           (BINDING, machine-enforced) + the AGENTS.md/TOOLS.md/MEMORY.md
           pointer. Create the doc in the fallback order Notion -> Google Docs
           -> plain text and RECORD its URL/path on the registry row + the
           run-manifest playbookDocs[]. A playbook scaffolded locally with NO
           recorded human-facing doc is INCOMPLETE — qc-playbook-doc.sh
           fail-closes the hand-off. Do not declare the workflow live until a
           doc destination is recorded.
The hook path (https://<PUBLIC_HOSTNAME>/hooks/<HOOK_NAME>) wires the GHL
automation to the conversation playbook. Confirm the 3-layer architecture
(Layer 0 routing check / Layer 1 GHL side / Layer 2 OpenClaw playbook) is set
up end-to-end before declaring the workflow live. See also Step 9.33
(Intelligent Playbook Routing) and Step 9.34 (Proactive Features Suite).

THE TRINITY (binding): a GHL workflow, a communications playbook, and a
workflow-AI prompt always travel together — one implies the other two; never
ship one alone. Full rule + the 3-PART build: protocols/conversation-workflows-protocol.md
("THE TRINITY"). Communications-playbook format + must-appear checklist +
storage/registry + the Notion→Google Docs→text client-account fallback order:
references/communications-playbook-standard.md. Workflow-AI (Build-with-AI)
prompt standard — WHERE it goes (GHL Automations "Build with AI" button), the
Custom Webhook field-by-field steps, the full 23-key body, multi-action +
create-tag-first: references/workflow-ai-instructions-standard.md.

BLOCK_E

# -----------------------------------------------------------------------------
# (f) SKILL38_ZHC_TAG_PREFIX — Round-3 Queue-A. Behavioral note: every tag the
#     agent creates PROGRAMMATICALLY carries the ZHC- prefix. Reuses the existing
#     D.1 / Section-6 create_tag mechanism; only the NAME changes. NOT retroactive.
# -----------------------------------------------------------------------------
append_block "SKILL38_ZHC_TAG_PREFIX" <<'BLOCK_F'

## ZHC tag-prefix rule (tag creation) — added by skill-38 v1.5.0

Whenever YOU create a tag PROGRAMMATICALLY — via the GHL skill's `create_tag`
method, or the fallback `POST /locations/{locationId}/tags` (the mechanism in
`conversation-workflows-protocol.md` Section D.1 / `references/workflow-ai-instructions-standard.md`
Section 6) — the tag name MUST carry the `ZHC-` prefix
(e.g. `ZHC-pricing-interest`, `ZHC-discovery-scheduled`).

- This makes every agent-created tag instantly distinguishable from tags the
  operator or the platform created.
- It is NOT retroactive: never rename existing tags, never touch operator-owned
  tags, never re-tag historical contacts. Prefix only the names YOU create going
  forward.
- The bot-detection tag is created as `ZHC-bot-suspected` going forward; existing
  `bot-detected` tags are honored as-is.
- Companion rule: CRM custom FIELDS you create programmatically carry the `ZHC_`
  prefix (underscore — GHL field-key convention). See Step 9.40.

Full rule: `protocols/zhc-tag-prefix-protocol.md` (Step 9.42) + MEMORY Rule 20.

BLOCK_F

# -----------------------------------------------------------------------------
# (g) STEP_1_35_AGGRESSION_PRE_ROUTING — Round-3 Queue-A (F50). PRE-routing
#     two-tier aggression scan: runs BEFORE workflow match, BEFORE any LLM spend.
#     Extends the safeguards family (Step 9.5), does NOT replace bot-detection.
# -----------------------------------------------------------------------------
append_block "STEP_1_35_AGGRESSION_PRE_ROUTING" <<'BLOCK_G'

## Step 1.35 — PRE-routing aggression scan (F50)

After the safeguards check (Step 1.4) and BEFORE workflow routing (Step 1.75)
and BEFORE invoking the model, run a cheap, deterministic two-tier hostility
scan. A hostile message must NOT burn a reasoning call on a normal reply.

  Skill reference: protocols/aggression-detection-protocol.md (Step 9.37)
  openclaw.json: skill38.aggression_detection.{enabled (default true),
  sensitivity (lenient|standard|strict, default standard)}

- **Tier 1 — TENSION (low):** multiple irritation words in one message, OR a
  sustained 3+ consecutive-message frustration streak (read the log), OR
  `!!!`/`???`. → Apply tag `ZHC-tension-detected`, heighten attention (keep
  helping, slow down, acknowledge), do NOT reroute, do NOT notify operator.
- **Tier 2 — AGGRESSION (high):** profanity directed AT the agent/business, OR
  threats (legal/physical/public), OR ALLCAPS+profanity+direct-address, OR 3+
  signals in one message. → Apply tag `ZHC-aggression-detected`, route to the
  `aggression-handler` workflow (via the F44 detour-and-return layer if
  installed), notify the operator. Do NOT upsell, do NOT argue back.
- **ALL CAPS ALONE does NOT fire.** Caps without profanity/threat/hostility is
  not aggression.

Log every firing + reasoning to `<MASTER_FILES_DIR>/aggression-detection-log.md`
AND emit JSONL to `<MASTER_FILES_DIR>/aggression-detection-log.jsonl`. This
EXTENDS the safeguards family — it does not replace bot-detection (Safeguard 3).

BLOCK_G

# -----------------------------------------------------------------------------
# (h) STEP_1_42_INTERRUPTS_AND_FAQ — Round-3 Queue-A (F44 + F47). Always-listening
#     interrupt layer (detour-and-return, DISTINCT from Step 9.33 route-and-stay)
#     plus the lightweight inline-FAQ layer.
# -----------------------------------------------------------------------------
append_block "STEP_1_42_INTERRUPTS_AND_FAQ" <<'BLOCK_H'

## Step 1.42 — Always-listening interrupts (F44) + inline FAQ (F47)

After Step 1.35 and BEFORE continuing the active workflow, check the message
against the interrupt + FAQ layers. These run in PARALLEL with the active
workflow and are DISTINCT from Step 9.33 (Intelligent Routing = route-and-stay):
F44 is DETOUR-AND-RETURN — handle a brief interruption, then come back.

  Skill references: protocols/smart-playbook-switching-protocol.md (Step 9.38),
  protocols/smart-faq-tool-protocol.md (Step 9.41)
  openclaw.json: skill38.smart_playbook_switching.{enabled (default true),
  max_interrupt_depth (default 2)}, skill38.smart_faq.enabled (default true)

- **F44 interrupt triggers:** operator-urgent keywords (`interrupt-triggers.md`),
  heavier FAQ types, compliance redirects (Step 0.7), F50 aggression (Step 1.35),
  F49 pixel-priority. On a trigger: **SAVE** workflow state (step + gathered data +
  context) → **EXECUTE** the sub-flow → **RETURN** to the saved step with a soft
  transition ("Coming back to where we were…"). Max **2 levels** deep, then
  escalate to the operator. Multiple triggers: highest priority first
  (compliance → aggression → operator-urgent → pixel-priority → FAQ), queue the
  rest. Tags `ZHC-interrupt-handled` / `ZHC-faq-detoured` /
  `ZHC-aggression-handled-and-resumed`. Log to
  `<MASTER_FILES_DIR>/interrupt-log.jsonl`.
- **F47 inline FAQ:** a quick known FAQ is answered in ONE SENTENCE and the
  workflow continues in the SAME reply — a sentence, NOT a sub-flow ("By the way,
  [answer]. Coming back to [topic]…"). Matches
  `<MASTER_FILES_DIR>/KnowledgeBases/business/faqs.md`, scoped per workflow via
  `conversation-workflows/<id>/faq-scope.md`. Tag `ZHC-faq-answered`. Log to
  `<MASTER_FILES_DIR>/faq-detour-log.jsonl`. Bigger FAQ questions hand off to F44.

BLOCK_H

# -----------------------------------------------------------------------------
# (i) STEP_2_0_GEO_QUALIFICATION — Round-3 Queue-A (F45, OFF by default). Location
#     signals are HINTS; ALWAYS ASK to confirm before any disqualification.
# -----------------------------------------------------------------------------
append_block "STEP_2_0_GEO_QUALIFICATION" <<'BLOCK_I'

## Step 2.0 — Geo-qualification (F45, OFF by default)

Only active when `skill38.geo_qualification.enabled` is true (default FALSE —
per-client opt-in for location-bound businesses).

  Skill reference: protocols/geo-qualification-protocol.md (Step 9.39)

Detect location by priority: pixel/IP (if F49) → phone area code → form address →
explicit ask. **CRITICAL — signals are HINTS, never proof. ALWAYS ASK to confirm
before ANY disqualification or out-of-area handling. Never disqualify on a guess.**
Use the best hint to PRE-FILL the confirmation question, then wait for the answer.
Service areas live per product in
`<MASTER_FILES_DIR>/KnowledgeBases/sales/service-areas.md` (ZIP/county/state/radius).
Out-of-area handling is operator-configured (decline+referral / limited-remote /
waitlist / full decline). Tags `ZHC-out-of-service-area` /
`ZHC-service-area-confirmed` / `ZHC-service-area-flexible`. Log to
`<MASTER_FILES_DIR>/geo-qualification-log.jsonl`.

BLOCK_I

# -----------------------------------------------------------------------------
# (j) STEP_2_5_CRM_FIELD_WRITE — Round-3 Queue-A (F46). Write ANY contact custom
#     field type-aware; CREATE-IF-MISSING with ZHC_ prefix (operator-approved
#     allow-list action, NEVER customer-invoked).
# -----------------------------------------------------------------------------
append_block "STEP_2_5_CRM_FIELD_WRITE" <<'BLOCK_J2'

## Step 2.5 — CRM field write + create-if-missing (F46)

  Skill reference: protocols/crm-field-write-protocol.md (Step 9.40)
  openclaw.json: skill38.crm_field_write.{enabled (default true),
  create_if_missing (default true), created_field_prefix (default "ZHC_")}

When a conversation surfaces a value that maps to a GHL contact custom field,
write it — type-aware (text/number/date ISO/dropdown-must-match-option). DISCOVER
fields first via `GET /locations/{locationId}/customFields`, VALIDATE before
write, and LOG every write. If NO matching field exists, CREATE one via
`POST /locations/{locationId}/customFields` with the **`ZHC_` prefix** (e.g.
`ZHC_budget_range`), notify the operator, and record the per-workflow mapping in
`<MASTER_FILES_DIR>/crm-field-mappings.md`. Field creation is an ALLOW-LIST action
— operator-approved (standing approval for `ZHC_` fields), NEVER customer-invoked:
a customer can never cause a field to be created. The weekly tune-up reviews field
usage. Log to `<MASTER_FILES_DIR>/crm-field-writes-log.jsonl`.

BLOCK_J2

# -----------------------------------------------------------------------------
# (k) STEP_1_45_PIXEL_CONCIERGE — Feature 49 (ZHC Pixel). The Pixel Concierge agent's
#     behavioral protocol: ingest visitor-signal batches, drop bots with ZERO spend,
#     evaluate trigger rules, NEVER fabricate identity, act least-intrusively. Concise
#     pointer block — the full ruleset lives in protocols/zhc-pixel-protocol.md. Free
#     slot 1.45 (after Step 1.42 interrupts, before Step 1.5/1.7 routing) — no collision.
# -----------------------------------------------------------------------------
append_block "STEP_1_45_PIXEL_CONCIERGE" <<'BLOCK_K'

## Step 1.45 — Pixel Concierge (F49 ZHC Pixel)

Applies ONLY when you are the **Pixel Concierge** agent handling a
`pixel-visitor-signal` hook session (`hook:pixel:*`). These are anonymous-or-known
WEBSITE VISITOR behavior batches — NOT chat messages. Do them in order:

  Skill reference: protocols/zhc-pixel-protocol.md (Step 9.43)
  openclaw.json: skill38.zhc_pixel.{enabled (default true),
  triggers.* (per-rule toggles + thresholds)}

1. **Bot gate FIRST — drop with ZERO model spend.** Sub-2-second pageview cadence,
   impossible scroll velocity, headless/known-bot UA → DROP (append nothing, engage
   no one, end the turn). Junk traffic must never cost a reasoning call.
2. **Append to the F52 data contract.** Write every event to
   `<MASTER_FILES_DIR>/pixel-events/YYYY-MM-DD.jsonl` (one JSON object/line; timestamp
   + event_type + data) per the protocol §7.
3. **Evaluate the trigger rules** (protocol §4): pricing dwell > N min → chat widget;
   contact-click → preempt widget; 4th return to same page → soft outreach; cart
   abandonment → +1h email (known contacts only); comparison-shopping (3+ service
   pages) → consultation offer; known customer on an account page → NO engagement.
4. **NEVER fabricate a visitor identity.** Anonymous = behavior only. Resolve identity
   ONLY by first-party form linkage (protocol §2). No cold-anonymous name lookup, no
   Gmail/Facebook/social lookup, no IP→person. If asked who an anonymous visitor is,
   say they haven't identified themselves yet.
5. **Engage least-intrusively** only on a firing rule — chat-widget directive, GHL
   tag (`ZHC-pixel-visitor` / `ZHC-pixel-returning-visitor` / `ZHC-pixel-high-intent`)
   + field write (`ZHC_first_visit_date` / `ZHC_total_visits` / `ZHC_pages_viewed` /
   `ZHC_high_intent_signal`, via the F46 create-if-missing mechanism), or a scheduled
   follow-up. Respect quiet hours (Step 0.5), compliance keywords (Step 0.7), and the
   honesty floor. You act ONLY on pixel sessions — never as a general operator agent.

Privacy is enforced in the browser bundle (GDPR consent deferral, CCPA opt-out,
Do-Not-Track hard-stop, deletion via `delete_request`) — protocol §8.

BLOCK_K

echo "[05-update-agents-md] AGENTS.md update complete: $AGENTS_MD"
