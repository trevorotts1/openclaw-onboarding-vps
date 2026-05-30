<!-- OPERATOR HEADER -->
<!-- Skill 38 reference/protocol doc: GHL Raw Body JSON Standard. -->
<!-- This is the FULL standard for the GHL Custom Webhook RAW BODY (object A) — the FLAT 23-key JSON. -->
<!-- AGENTS.md / TOOLS.md / SKILL.md get only a 1-2 line pointer to this file — never the body inline. -->
<!-- §0 below is the BINDING "EVERY GHL RAW BODY MUST BE THE FULL 23-KEY FLAT JSON" rule, -->
<!-- machine-enforced by scripts/qc-ghl-raw-body-standard.sh (asserts the 23-key list + FLAT rule are -->
<!-- documented here) composed with scripts/qc-23-key-bodies.sh (lints every actual body in the skill). -->
<!-- Both are wired into scripts/11-run-qc-checklist.sh + .github/workflows/qc-static.yml. -->
<!-- Single source of truth for the body itself: references/GHL-INBOUND-AND-PLAYBOOKS.md §14 (the 23-key -->
<!-- section, verified LIVE 2026-05-29). This doc is the human-readable standard that codifies §14. -->
<!-- Companion: workflow-ai-instructions-standard.md §3 (where the body goes in Build-with-AI), -->
<!-- communications-playbook-standard.md (the per-channel voice that rides on the inbound this body delivers). -->

# GHL Raw Body JSON Standard

The **GHL Custom Webhook Raw Body** (a.k.a. "object A") is the JSON payload GHL POSTs to the OpenClaw
public hook on every inbound message. It is the FLAT 23-key body. This document is the single
human-readable standard for that body — the MUST-APPEAR rule, the exact 23 keys (purpose each), the FLAT
rule, the placeholder-free `messageTemplate` rule, `deliver:false`, and the per-channel variant rule. The
canonical body is shown ONCE below; copy it verbatim.

> **TWO OBJECTS — do not confuse them.** This standard is for **object A** = the body GHL sends (snake_case
> keys like `agent_id`, `contact_id`; a PLACEHOLDER-FREE `messageTemplate`). It is NOT the OpenClaw server
> `hooks.mappings` entry (**object B** = camelCase `agentId`, a nested `match: { path }`, and its own
> TEMPLATED `messageTemplate` carrying the SEND-directive + conversation-memory steps). Object B is not a
> 23-key flat body and is intentionally out of scope here. See `references/GHL-INBOUND-AND-PLAYBOOKS.md`
> §14 for both.

---

## 0. EVERY GHL RAW BODY MUST BE THE FULL 23-KEY FLAT JSON (BINDING — NON-NEGOTIABLE)

> **23 is the MINIMUM and the STANDARD — never fewer, never nested.** Every GHL Custom Webhook Raw Body
> this skill emits, references, or templates MUST be the FULL 23-key FLAT JSON. A sub-23-key body is a
> stripped body; a nested body makes EVERY field resolve EMPTY at the agent (proven live — even a hardcoded
> `"channel":"sms"` arrived blank when wrapped in a nested object). There is no "short" or "minimal"
> variant. This is what `scripts/qc-ghl-raw-body-standard.sh` asserts is documented here, and what
> `scripts/qc-23-key-bodies.sh` enforces against every actual body in the skill (both wired into
> `scripts/11-run-qc-checklist.sh` + CI).

EVERY GHL RAW BODY MUST satisfy ALL of the following:

1. **FULL 23 keys — exactly the canonical 23, no more, no fewer.** Never an 8-key, 11-key, or any sub-23
   body. 23 is the minimum AND the standard.
2. **FLAT — no nested objects, no nested arrays-of-objects.** Nesting (e.g. `contact:{…}` /
   `customer_message:{…}`) makes every field arrive EMPTY at the agent.
3. **`messageTemplate` in the BODY is a placeholder-free stub.** No `{{…}}` merge tokens inside the body's
   `messageTemplate` value, or GHL throws "Error while parsing the object to JSON" and SKIPS the webhook.
   The REAL, templated instruction (the SEND-directive + memory steps) lives ONLY on the server mapping
   (object B), never here.
4. **`deliver: false`.** The hook must NOT auto-deliver — the agent sends the reply itself via the GHL
   Conversations API. `deliver:true` double-sends / mis-sends.
5. **Single-line JSON values — no literal `\n` inside the JSON.**
6. **Per-channel variants change ONLY `channel` + the `session_key` prefix.** Everything else is identical
   across channels. (`channel`: `sms` / `email` / `facebook` / `instagram` / `whatsapp` / `live_chat`;
   `session_key`: `hook:ghl:<channel>:{{contact.id}}`.) Insert the data VALUES via GHL's **Custom Values
   picker** — typed-as-text tokens send empty.

If any one of these is violated, the body is INVALID and the install is not complete.

---

## 1. THE 23 KEYS (exact order, purpose each)

| # | Key | Purpose (one line) |
|---|-----|--------------------|
| 1 | `id` | Route id — identifies which OpenClaw `hooks.mappings` entry this inbound matches. |
| 2 | `match` | The match value the server mapping keys on (mirrors `id` for a direct route). |
| 3 | `action` | What the hook does — `agent` (route the inbound to an agent run). |
| 4 | `agent_id` | The OpenClaw agent id that handles this inbound (e.g. `sales`, `support`, `main`). |
| 5 | `model` | The model the agent run uses (e.g. `ollama/deepseek-v4-flash:cloud`). |
| 6 | `wakeMode` | When the run fires — `now` (process the inbound immediately). |
| 7 | `name` | Human-readable label for the inbound route (e.g. `GHL Sales Inbound`). |
| 8 | `session_key` | The conversation session key — `hook:ghl:<channel>:{{contact.id}}` (one of the two per-channel-variable fields). |
| 9 | `messageTemplate` | PLACEHOLDER-FREE stub instruction (the real templated one is server-side / object B only). |
| 10 | `deliver` | MUST be `false` — the agent sends the reply itself; the hook does not auto-deliver. |
| 11 | `timeoutSeconds` | Max seconds the agent run may take before timing out (e.g. `300`). |
| 12 | `channel` | The inbound channel — `sms` / `email` / `facebook` / `instagram` / `whatsapp` / `live_chat` (the second per-channel-variable field; hardcoded — there is no GHL merge tag for channel). |
| 13 | `to` | The destination address for the channel (e.g. `{{contact.phone}}`). |
| 14 | `thinking` | The agent's thinking budget for the run (e.g. `medium`). |
| 15 | `contact_id` | GHL contact id — `{{contact.id}}` — the thread key for sending + the conversation-log filename. |
| 16 | `first_name` | Contact first name — `{{contact.first_name}}`. |
| 17 | `last_name` | Contact last name — `{{contact.last_name}}`. |
| 18 | `email` | Contact email — `{{contact.email}}`. |
| 19 | `phone` | Contact phone — `{{contact.phone}}`. |
| 20 | `subject` | Inbound message subject (Email) — `{{message.subject}}`. |
| 21 | `message_body` | The inbound message text — `{{message.body}}` (what the customer actually wrote). |
| 22 | `location_id` | GHL location id — `{{location.id}}` — required to thread/send via the Conversations API. |
| 23 | `location_name` | GHL location name — `{{location.name}}`. |

---

## 2. THE CANONICAL 23-KEY BODY (embed this EXACTLY)

Per-channel variants change ONLY `channel` + the `session_key` prefix. Insert the data values via GHL's
Custom Values picker; keep `messageTemplate` placeholder-free.

```json
{
  "id": "ghl-sales",
  "match": "ghl-sales",
  "action": "agent",
  "agent_id": "sales",
  "model": "ollama/deepseek-v4-flash:cloud",
  "wakeMode": "now",
  "name": "GHL Sales Inbound",
  "session_key": "hook:ghl:sms:{{contact.id}}",
  "messageTemplate": "Respond as the Sales agent. MANDATORY — SEND on the SAME channel the message arrived on, do not just draft: SEND your reply via the GHL Conversations API (POST conversations/messages) with type = the MIRRORED inbound channel value (SMS->SMS, Email->Email, Facebook->FB, Instagram->IG, WhatsApp->WhatsApp, Live Chat->Live_Chat; do NOT hardcode SMS), contactId, locationId, and message — GHL threads it by contactId and returns conversationId+messageId (conversationId is the READ key only, never a send-body field). Composing or drafting a reply is NOT sending — the customer receives nothing unless you make the API call. Do NOT end your turn until the send call returns a messageId.",
  "deliver": false,
  "timeoutSeconds": 300,
  "channel": "sms",
  "to": "{{contact.phone}}",
  "thinking": "medium",
  "contact_id": "{{contact.id}}",
  "first_name": "{{contact.first_name}}",
  "last_name": "{{contact.last_name}}",
  "email": "{{contact.email}}",
  "phone": "{{contact.phone}}",
  "subject": "{{message.subject}}",
  "message_body": "{{message.body}}",
  "location_id": "{{location.id}}",
  "location_name": "{{location.name}}"
}
```

The 23 keys (exact, in order): `id`, `match`, `action`, `agent_id`, `model`, `wakeMode`, `name`,
`session_key`, `messageTemplate`, `deliver`, `timeoutSeconds`, `channel`, `to`, `thinking`,
`contact_id`, `first_name`, `last_name`, `email`, `phone`, `subject`, `message_body`, `location_id`,
`location_name`.

---

## 3. SOURCE OF TRUTH + ENFORCEMENT

- **Source of truth for the body:** `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14 (the 23-key section) —
  the cardinal rule, the per-channel variant table, and the two-objects note (A vs B). This standard
  codifies §14 into a single human-readable standard; if they ever disagree, §14 wins and this doc is
  corrected.
- **Where the body goes:** `workflow-ai-instructions-standard.md` §3 (the Custom Webhook RAW BODY field in
  the Build-with-AI prompt) and the generated client reference sheet (`scripts/21-generate-client-reference-sheet.sh`).
- **Machine enforcement:** `scripts/qc-23-key-bodies.sh` scans every object-A body embedded in the skill
  (`references/` + `templates/` + `scripts/`) and asserts exactly 23 flat keys, a placeholder-free
  `messageTemplate`, no nested objects, and no literal `\n` — exiting non-zero on any violation.
  `scripts/qc-ghl-raw-body-standard.sh` asserts THIS standard documents the FLAT rule + the full 23-key
  list. Both are wired into `scripts/11-run-qc-checklist.sh` + `.github/workflows/qc-static.yml`.
