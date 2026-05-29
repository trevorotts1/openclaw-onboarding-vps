<!-- OPERATOR HEADER -->
<!-- Skill 38 reference/protocol doc: Workflow-AI Instructions Standard. -->
<!-- This is the FULL standard for the prompt pasted into GHL's "Build with AI" button. -->
<!-- AGENTS.md / TOOLS.md get only a 1-2 line pointer to this file — never the body inline. -->
<!-- Canonical 23-key body authority: references/GHL-INBOUND-AND-PLAYBOOKS.md §14 (verified LIVE 2026-05-29). -->
<!-- Companion: communications-playbook-standard.md, conversation-workflows-protocol.md (THE TRINITY). -->

# Workflow-AI Instructions Standard

A **workflow-AI prompt** is the natural-language instruction set the operator pastes into GHL's
**"Build with AI"** button to construct a GHL automation/workflow. GHL Automations have **NO API and
NO MCP** — the "Build with AI" button is the ONLY programmatic path to build one. This document is the
single standard for the MUST-APPEAR checklist, WHERE the prompt goes, the explicit field-by-field
Custom Webhook steps (the part Build-with-AI fails at most), and how to teach MULTI-ACTION workflows.

> **THE TRINITY.** A workflow-AI prompt never ships alone. It travels with its communications playbook
> and its GHL workflow. See `conversation-workflows-protocol.md` → "THE TRINITY".

---

## 1. WHERE the prompt goes (exact)

1. Open the client's GHL / Convert and Flow account.
2. Click **Automations** in the left menu.
3. Create a **new** automation/workflow → click **Build with AI** (top-right).
4. Paste the workflow-AI prompt (saved at
   `<MASTER_FILES_DIR>/conversation-workflows/<slug>--build-with-ai-prompt.md`).
5. Let Build-with-AI construct the SHAPE (trigger, filters, branches, tags, the Custom Webhook step).
6. Run the Build-with-AI Verification Checklist (§4) before publishing — Build-with-AI populates the
   webhook fields poorly, so verification is mandatory, not optional.

There is no GHL API and no MCP for Automations. Do not propose one. The "Build with AI" button is it.

---

## 2. MUST-APPEAR CHECKLIST (every workflow-AI instruction set)

- [ ] **Workflow name** + **PUBLISH instruction** ("publish when done — do not leave as draft").
- [ ] **Trigger** — type (e.g. "Customer Replied") + sub-option (e.g. "On Reply") + **filters**
      (e.g. Channel = SMS, Message Direction = Inbound), in exact order.
- [ ] **For EACH action, EVERY field spelled out.** No "configure the webhook" hand-waving.
- [ ] **Custom Webhook action — field by field (see §3).** Build-with-AI repeatedly fails to populate
      these; spell out all of them.
- [ ] **RAW BODY = the FULL 23-key flat JSON** (§3) via the Custom Values picker. Do NOT shorten to
      4 keys (or any sub-23 count). 23 is the MINIMUM.
- [ ] **MULTI-ACTION teaching where applicable (see §5)** — if/else branches, Add-Tag, tag-check
      conditions, and multiple sequential actions. If a tag is needed, CREATE the tag first via the
      GHL skill (before building the workflow), then reference it in the prompt.

---

## 3. CUSTOM WEBHOOK — explicit field-by-field (the part Build-with-AI gets wrong)

In the Build-with-AI prompt, specify the Custom Webhook action exactly like this. Each line maps to a
field in the GHL Custom Webhook action editor:

- **EVENT = `CUSTOM`** (the action is a Custom Webhook, not a templated/integration webhook).
- **METHOD = `POST`** — pick POST from the Method dropdown (not GET, not PUT).
- **URL = the EXACT hook URL** — `https://<PUBLIC_HOSTNAME>/hooks/<HOOK_NAME>`. Do **NOT** leave the
  Build-with-AI sample-url placeholder. Paste the real, character-for-character URL (no trailing slash,
  correct hostname + `/hooks/` path segment).
- **AUTHORIZATION dropdown = `None`** — the token goes in HEADERS, not in this dropdown. (Common
  Build-with-AI mistake: setting this to "Bearer Token" — leave it None.)
- **HEADERS** — click **"Add item"** and add, exactly. A GHL custom header is **TWO separate fields, a
  Key (name) field and a Value field**, so in the client doc each header is rendered as **two separate
  copy boxes** (key box + value box) — never one combined box. The VALUE box gets ONLY the value, with
  **no `Authorization:` prefix**:
  - **Key field** = `Authorization` &nbsp;|&nbsp; **Value field** = `Bearer <HOOKS_TOKEN>` (value box is
    ONLY `Bearer ` + the token — the word "Authorization" never appears in the value box)
  - **Key field** = `Content-Type` &nbsp;|&nbsp; **Value field** = `application/json`
  - (Add any other header the same way via "Add item" — always key into the Key field, value into the
    Value field, split into two copy boxes.)
- **CONTENT-TYPE = `application/json`** (the content-type dropdown).
- **RAW BODY = the FULL 23-key flat JSON below**, inserted via GHL's **Custom Values picker** (typed-
  as-text tokens send EMPTY). FLAT (no nesting — nesting makes every field arrive empty). Keep
  `messageTemplate` **placeholder-free** (no `{{…}}` in the body's messageTemplate, or GHL throws
  "Error while parsing the object to JSON"). Do NOT shorten to 4 keys — all 23 are required.

### The canonical 23-key body (embed this exactly; per-channel variants change only `channel` + the `session_key` prefix)

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
  "messageTemplate": "Respond as the Sales agent. MANDATORY — SEND, do not just draft: you MUST send your reply by calling the GHL Conversations API (POST conversations/messages) for this contact on this channel, per TOOLS.md. Composing or drafting a reply is NOT sending — the customer receives nothing unless you make the API call. Do NOT end your turn until the send call returns a messageId/conversationId.",
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
`location_name`. See `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14 for the cardinal rule, the per-channel
variant table, and the two-objects note (the GHL body = object A; the OpenClaw server `hooks.mappings`
entry = object B, which keeps its OWN templated `messageTemplate`).

---

## 3.5 MANDATORY — AFTER Build-with-AI runs, MANUALLY fill the Custom Webhook action yourself

> **GHL's "Build with AI" only builds the workflow SHAPE — the trigger, the filters, and an EMPTY
> Custom Webhook action. It does NOT reliably populate the URL, the Authorization/Bearer header, the
> Content-Type header, or the Raw Body JSON.** Build-with-AI will NOT fill these for you. You MUST open
> the Custom Webhook action and enter every value by hand, then Save + Publish.

After Build-with-AI finishes, do this — every time, no exceptions:

1. Open the workflow Build-with-AI created and click the **Custom Webhook** action to edit it.
2. **Method** — set to **`POST`** (Build-with-AI often leaves it blank or on GET).
3. **URL** — paste the EXACT hook URL: `https://<PUBLIC_HOSTNAME>/hooks/<HOOK_NAME>` (no trailing
   slash; do NOT leave the sample-url placeholder).
4. **AUTHORIZATION dropdown** — leave it on **`None`** (the token goes in HEADERS, not here).
5. **Headers** — click **"Add item"** and add each header by hand. Each header has a **Key field** and a
   **Value field** (two separate boxes) — paste the key into the Key field and the value into the Value
   field; the Value box gets ONLY the value, with **no `Authorization:` prefix**:
   - Key field `Authorization` → Value field `Bearer <HOOKS_TOKEN>`
   - Key field `Content-Type` → Value field `application/json`
6. **Content-Type dropdown** — set to **`application/json`**.
7. **Raw Body** — paste the FULL FLAT 23-key JSON from §3 (insert the data values via the Custom Values
   picker; keep `messageTemplate` placeholder-free).
8. **Save** the action, then **Publish** the workflow (not Draft).
9. **Verify every field above is non-empty before publishing** — an empty URL/header/body silently drops
   every inbound message.

This is a manual step the client OWNS — there is no API, no MCP, and Build-with-AI will not do it. Every
client doc (the reference sheet, the SMS prompt template, the verification checklist) repeats this so the
client always knows: **paste these values into the Custom Webhook action yourself.**

---

## 4. BUILD-WITH-AI VERIFICATION CHECKLIST (run AFTER Build-with-AI finishes)

Build-with-AI populates poorly, so run this every time — even when the prompt "succeeded". (The
per-workflow rendered version lives at `<slug>--verification-checklist.md`; the canonical pattern is in
`templates/workflow-verification-checklist-template.md` and `references/GHL-INBOUND-AND-PLAYBOOKS.md` §4.)

> **For EACH item below: WHERE to go, WHAT you should SEE, WHAT to put if it's missing/wrong.** Walk all
> three for every item before publishing.

- [ ] **Trigger type + filter** are correct (e.g. "Customer Replied", filtered to the intended channel
      — not all channels).
      - **WHERE:** open the workflow → click the **trigger** node.
      - **WHAT YOU SHOULD SEE:** the correct trigger type + (if there is a tag filter) a REAL tag name.
      - **WHAT TO PUT IF WRONG:** fix the trigger type / channel filter.
- [ ] **TAG FILTER references a REAL, existing tag** (the Teresa gotcha — known live bug). If the trigger
      (or an If-Else) has a tag filter — `tag is` / `tag contains` / **`tag does not contain`** — confirm
      the referenced tag ACTUALLY EXISTS and is the intended one.
      - **WHERE:** the trigger/If-Else filter, cross-checked against **Settings → Tags**.
      - **WHAT YOU SHOULD SEE:** a real tag name (matching Settings → Tags) in the filter — NOT a blank.
      - **KNOWN BUG:** Build-with-AI created a `does not contain <tag>` filter where the referenced tag was
        **blank / never created**, so the trigger silently never matched and every inbound went nowhere.
      - **WHAT TO PUT IF BLANK/WRONG:** select (or create first, §5) the correct existing tag, or remove
        the bad filter.
- [ ] **Exactly the intended action(s)** exist — no extra actions, none missing (for multi-action
      workflows, every branch + Add-Tag + tag-check is present, §5).
- [ ] **Custom Webhook METHOD = POST.**
- [ ] **URL is the REAL hook URL** (`https://<PUBLIC_HOSTNAME>/hooks/<HOOK_NAME>`) — NOT the sample-url
      placeholder, no trailing slash, correct path.
- [ ] **AUTHORIZATION dropdown = None** (token is in Headers, not here).
- [ ] **HEADERS** (added via "Add item"; each is a Key field + a Value field — two separate boxes):
      Key `Authorization` / Value `Bearer <HOOKS_TOKEN>` (the value box holds ONLY `Bearer ` + the token —
      **no `Authorization:` prefix in the value box**) **and** Key `Content-Type` / Value
      `application/json`.
- [ ] **CONTENT-TYPE = application/json.**
- [ ] **RAW BODY = all 23 keys, FLAT** (no nesting), `messageTemplate` placeholder-free, no stripped/
      short body. Re-paste the full 23-key body if any key is missing.
- [ ] **SEND-directive on the OpenClaw server mapping** — the `hooks.mappings` server-mapping
      `messageTemplate` (object B — NOT the GHL body) ORDERS the agent to SEND via the GHL Conversations
      API (POST conversations/messages) and to NOT end its turn until a messageId/conversationId is
      returned. Drafting is NOT sending — without this clause the agent drafts a reply and the customer
      gets nothing. Machine-check: `scripts/qc-send-directive.sh` must PASS.
- [ ] **Conversation-MEMORY steps on the OpenClaw server mapping** — the same SERVER-mapping
      `messageTemplate` (object B) ALSO orders the agent to **READ** the contact's conversation log at
      `<MASTER_FILES_DIR>/conversational-logs/<contact_id>__<name>.md` BEFORE replying (continue any
      in-progress topic/booking; if missing, treat as new) and to **APPEND** the inbound + sent reply to
      that log AFTER sending. GHL inbound hook sessions are SINGLE-TURN / stateless, so the log IS the
      agent's only cross-message memory — dropping these steps is how the agent "forgets" mid-conversation.
      Machine-check: `scripts/qc-conversation-memory.sh` must PASS (and the installer is fail-closed if
      they're absent). Note: these steps live ONLY on the SERVER mapping (object B) — the GHL RAW BODY
      (object A) `messageTemplate` stays placeholder-free and is NOT where they go.
- [ ] **Any required tags created/applied** (created beforehand via the GHL skill).
      - **WHERE:** **Settings → Tags** (this is where tags live and where to confirm they exist).
      - **WHAT YOU SHOULD SEE:** every tag the workflow references, spelled exactly.
      - **WHAT TO PUT IF MISSING:** create the tag FIRST (§5), THEN reference it in the workflow.
- [ ] **Workflow Published** (not Draft).
      - **WHERE:** top-right of the workflow. **WHAT YOU SHOULD SEE:** "Published". **IF DRAFT:** toggle
        it to Published.

> **Machine-enforced.** Every GHL RAW BODY example in this skill (references/ + templates/ + scripts/) is
> scanned by `scripts/qc-23-key-bodies.sh`, which asserts exactly 23 flat keys, a placeholder-free
> `messageTemplate`, no nested objects, and no literal `\n` — and exits non-zero on any violation (it also
> runs in CI). The MANDATORY GHL **send-directive** on every inbound SERVER-mapping `messageTemplate`
> (SEND via the GHL Conversations API / drafting-is-NOT-sending / do-not-end-turn-until-messageId) is
> enforced by `scripts/qc-send-directive.sh` (also runs in CI) — drafting is not sending, so an inbound
> hook without it silently drops the reply. The MANDATORY **conversation-memory** read-before/append-after
> on every inbound SERVER-mapping `messageTemplate` is enforced by `scripts/qc-conversation-memory.sh`
> (also runs in CI) — hook sessions are single-turn, so a template without it makes the agent forget.
> THE TRINITY (this prompt ⇄ its communications playbook ⇄ its registry row) is enforced by
> `scripts/qc-trinity-registry.sh`. These are checks, not just human checklist items.

---

## 5. MULTI-ACTION workflows (not just one webhook)

A workflow-AI prompt must support **trigger + (optional if/else) + one-or-more actions** — not only a
single Custom Webhook. Teach the operator (and write the prompt) for:

- **if/else (if-else) branches** — additional filtering after the trigger (e.g. "If contact has tag
  `vip` → branch A; else → branch B"). Spell out each branch's condition and its actions.
- **Add-Tag actions** — apply a tag at a point in the flow (e.g. tag `pricing-interest` after the
  webhook fires).
- **tag-check conditions** — branch on whether a contact already has a tag.
- **multiple sequential actions** — e.g. Custom Webhook → wait → Add-Tag → if/else. Each action gets
  its full field spec, same rigor as §3 for any webhook in the chain.

**CREATE-TAG-FIRST rule (binding).** If the workflow uses ANY tag — a trigger/If-Else filter (`tag is` /
`tag contains` / `tag does not contain`) OR an Add-Tag action — the agent CREATES the tag FIRST via the
GHL skill (per conversation-workflows-protocol.md §D.1) BEFORE building the workflow, then references the
now-existing tag in the Build-with-AI prompt. **Why it matters:** Build-with-AI will happily build a
filter that references a tag that does not exist (it leaves it blank), and a blank/non-existent tag in a
`does not contain` filter silently never matches — so the workflow never fires (the Teresa gotcha). Do not
tell the operator to create tags by hand, and do not reference a tag that does not exist yet.

**WHERE tags live (tell the client).** Tags are managed in GHL under **Settings → Tags**. That is where
to confirm a tag exists before building the workflow, and what the client should see there: every tag the
workflow references, spelled exactly. The post-build verification (§4) re-checks that any tag in a filter
matches a real tag under Settings → Tags.

### Multi-action prompt skeleton

```
Build a workflow for me with these exact specifications:

WORKFLOW NAME: <name>

TRIGGER:
- Type: <e.g. Customer Replied>  Sub-option: <e.g. On Reply>
FILTERS (exact order):
- Filter 1: <Field> = <Value>
- Filter 2: <Field> = <Value>

IF/ELSE (optional):
- IF <condition, e.g. contact has tag `vip`>:
    - Action: <...>
- ELSE:
    - Action: <...>

ACTIONS (exact order):
- Action 1: Send Custom Webhook
    EVENT: CUSTOM
    METHOD: POST
    URL: https://<PUBLIC_HOSTNAME>/hooks/<HOOK_NAME>   (the REAL url — not the sample placeholder)
    AUTHORIZATION dropdown: None
    HEADERS (click "Add item" for each; Key field + Value field = two separate copy boxes):
      - Key: Authorization   | Value: Bearer <HOOKS_TOKEN>   (value box = ONLY "Bearer <token>", no "Authorization:" prefix)
      - Key: Content-Type    | Value: application/json
    CONTENT-TYPE: application/json
    RAW BODY (Custom Values picker; FLAT; ALL 23 keys; messageTemplate placeholder-free):
      <the full 23-key body from §3>
- Action 2: Add Tag — `<tag>` (tag already created via the GHL skill)
- Action 3 (optional): <...>

PUBLISH: Yes — publish when done. Do NOT leave it as a draft.
RUN SCHEDULE: <e.g. All Day>
```

---

## 6. "YOUR COMMUNICATION PLAYBOOKS" section in the client doc (MANDATORY, machine-enforced)

The generated client doc (`scripts/21-generate-client-reference-sheet.sh`) MUST carry a prominent
**Your Communication Playbooks** section, placed **AFTER the Quick Start** and **BEFORE the deep
how-it-works**. It answers the first question every client asks on their first test —
*"where are my workflows / communication playbooks?"* — and tells them how to get a NEW one. It must say,
prominently (callout / bold heading):

- **WHERE they live** — the working copies in the client's OpenClaw master-files `conversation-workflows/`
  folder; the human-facing copies in the client's **Notion** (Notion → Google Docs → text).
- A friendly, emoji-rich **"Want another communication playbook? Just ask me! 🚀"** call-to-action, with a
  concrete example the client can copy verbatim — e.g. say to your AI *"Help me build a missed-call
  follow-up playbook"* (and other examples: appointment-reminder 📅, lead-nurture 💬, review-request ✅).
- A walkthrough of **what the AI will do when they ask**: (1) 💬 **brainstorm it WITH you** using what it
  already knows about the business (a few smart questions — **NOT a 50-question interrogation/form**), (2)
  🛠️ **create the communication playbook**, (3) 🗂️ **store it** — working copy saved to
  `conversation-workflows/` and **mirrored to Notion**, (4) 📝 **build the matching Workflow AI prompt
  wired to the client's Convert and Flow (GoHighLevel) account** with exact paste-where steps, and (5) 🤖
  the AI **can take real actions in Convert and Flow on the client's behalf** — it can **create tags 🏷️,
  update the calendar 📅, create/book appointments 🗓️**, and similar automations.
- The explicit line: **"You have an AI that is connected to your Convert and Flow account and can do these
  things for you — just ask."** This also covers building **all 3 parts** (THE TRINITY): the
  **workflow-AI prompt** (this standard), the **conversation playbook**
  (`communications-playbook-standard.md`), and the **GHL automation**.

This is part of the standard so every client doc carries it. Machine-enforced by
`scripts/qc-reference-sheet.sh` (wired into `scripts/11-run-qc-checklist.sh` + CI): the gate FAILS if the
generated sheet is missing the "Want another communication playbook? Just ask me!" CTA, the concrete
copyable example, the `conversation-workflows/` + Notion (mirrored) location, the brainstorm /
not-a-50-question note, the Workflow-AI-prompt-wired-to-Convert-and-Flow step, the Convert-and-Flow
abilities (create tags / update calendar / book appointments), or the explicit "connected to your Convert
and Flow account — just ask" statement.
