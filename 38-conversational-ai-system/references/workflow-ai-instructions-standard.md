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

## 0. EVERY workflow-AI instruction set MUST INCLUDE ALL OF THE FOLLOWING (BINDING — NON-NEGOTIABLE)

> **STANDARDIZATION CONTRACT.** The workflow-AI output is NOT free-form. It is the SAME five-part
> structure, in the SAME order, EVERY run, for EVERY client. Two different installs of this skill must
> produce structurally identical workflow-AI instruction sets — only the substituted values
> (`<CLIENT_BUSINESS_NAME>`, `<PUBLIC_HOSTNAME>`, `<HOOKS_TOKEN>`, `<ROUTE_ID>`, `<AGENT_ID>`,
> `<DESIRED_OUTCOME>`) change. No improvising, no reordering, no dropping a part, no adding parts. If any
> one of the five mandatory inclusions below is missing, the instruction set is INVALID and the install is
> not complete. This is what `scripts/21-generate-client-reference-sheet.sh` and
> `templates/sms-workflow-ai-prompt-template.md` emit verbatim, and what `scripts/qc-reference-sheet.sh`
> machine-enforces (wired into `scripts/11-run-qc-checklist.sh` + CI).

EVERY workflow-AI instruction set MUST INCLUDE ALL OF THE FOLLOWING:

1. **Workflow name + PUBLISH.** A concrete workflow name AND the explicit instruction to PUBLISH when done
   (toggle to Published — never leave it as a draft).
2. **Trigger: type + sub-option + filters in EXACT order.** The trigger type (e.g. "Customer Replied"), its
   sub-option (e.g. "On Reply"), and every filter listed in the exact order they must be entered (e.g.
   Filter 1: Channel = SMS; Filter 2: Message Direction = Inbound).
3. **Settings → ALLOW RE-ENTRY = ON.** The workflow MUST be allowed to re-enter / fire repeatedly per
   contact — every inbound message must re-trigger it. (A workflow left at the default "allow re-entry =
   off" fires ONCE per contact and then silently never fires again, so the AI answers the first text and
   goes dead on every text after. Set **Settings → Allow Re-entry = ON**.)
4. **Custom Webhook — EVERY field (see §3), with the EXACT value to enter.** EVENT, METHOD, URL,
   AUTHORIZATION dropdown, both HEADERS (each a Key field + Value field), CONTENT-TYPE, and the FULL FLAT
   23-key RAW BODY — no hand-waving, no "configure the webhook", every value spelled out.
5. **Save → Publish toggle ON → Save.** The closing sequence: Save the action/workflow, flip the
   top-right Publish toggle to ON, then Save again so it goes live (not Draft).

These five are the floor. They appear in this exact order in every rendered prompt, every client reference
sheet, and every verification checklist this skill emits.

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

This is the §0 mandatory-inclusions contract restated as a tick-list. All five §0 items + the supporting
detail must be present:

- [ ] **(§0.1) Workflow name** + **PUBLISH instruction** ("publish when done — do not leave as draft").
- [ ] **(§0.2) Trigger** — type (e.g. "Customer Replied") + sub-option (e.g. "On Reply") + **filters**
      (e.g. Channel = SMS, Message Direction = Inbound), in exact order.
- [ ] **(§0.3) Settings → Allow Re-entry = ON** — the workflow must be allowed to re-enter / fire
      repeatedly per contact, so every inbound message re-triggers it (default "off" fires once then goes
      dead).
- [ ] **(§0.4) For EACH action, EVERY field spelled out.** No "configure the webhook" hand-waving.
- [ ] **(§0.4) Custom Webhook action — field by field (see §3).** Build-with-AI repeatedly fails to
      populate these; spell out all of them.
- [ ] **(§0.4) RAW BODY = the FULL 23-key flat JSON** (§3) via the Custom Values picker. Do NOT shorten to
      4 keys (or any sub-23 count). 23 is the MINIMUM.
- [ ] **(§0.5) Save → Publish toggle ON → Save** — the closing sequence that takes it live.
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
- **SETTINGS → ALLOW RE-ENTRY = `ON`** — open the workflow's **Settings** tab and set **Allow Re-entry**
  to **ON / Enabled**. The workflow must be allowed to re-enter / fire repeatedly per contact so EVERY
  inbound message re-triggers it. Left at the default (off), the workflow fires ONCE per contact and then
  silently never fires again — the AI answers the first text and goes dead on every text afterward.

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
8. **Settings → Allow Re-entry** — open the workflow's **Settings** tab and set **Allow Re-entry** to
   **ON** so every inbound message re-triggers the workflow (default off fires once, then goes dead).
9. **Save** the action, then flip the top-right **Publish** toggle **ON**, then **Save** again (not Draft).
10. **Verify every field above is non-empty before publishing** — an empty URL/header/body silently drops
    every inbound message.

This is a manual step the client OWNS — there is no API, no MCP, and Build-with-AI will not do it. Every
client doc (the reference sheet, the SMS prompt template, the verification checklist) repeats this so the
client always knows: **paste these values into the Custom Webhook action yourself.**

---

## 3.6 CRITICAL DESIGN PATTERN — one send endpoint, mirror the channel, send by contactId

How the agent actually replies to a GHL inbound (verified against the GHL SendMessageBodyDto — do not
re-derive). Four rules:

1. **ONE send endpoint.** Every channel replies through `POST /conversations/messages` (scope
   `conversations/message.write`). There is no per-channel send endpoint.
2. **MIRROR the inbound channel into `type`.** Read the inbound channel (the hook payload `{{channel}}` /
   `messageType`) and set the send `type` to its MIRRORED value: SMS→`SMS`, Email→`Email`, Facebook
   Messenger→`FB`, Instagram DM→`IG`, WhatsApp→`WhatsApp`, Live Chat / Chat Widget→`Live_Chat`. **Do NOT
   hardcode `SMS`** — reply on the SAME channel the customer used. (GMB is inbound-only — it has NO send
   `type`; reply to a GMB inbound via a GHL workflow automation, not this API.)
3. **Send BY `contactId` — GHL threads automatically.** The send body is
   `{type, contactId, locationId, message}` (Email swaps `message` for `subject`+`html`+`emailFrom`+
   `emailTo`). The body carries **NO `conversationId`** — GHL threads the reply into the contact's
   conversation by `contactId` and returns `conversationId`+`messageId` in the response.
4. **`conversationId` is READ-ONLY (thread history).** To read prior history, `GET /conversations/search?
   locationId=&contactId=` to find the thread, then `GET /conversations/<conversationId>/messages` (scope
   `conversations.readonly`). `conversationId` is never a send-body field.

The exact request shapes live in `references/ghl-api-quick-reference.md` (preloaded into the client agent's
TOOLS.md) and `references/GHL-INBOUND-AND-PLAYBOOKS.md` §7–§8.

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
- [ ] **TAG FILTER references a REAL, existing tag** (the blank-tag gotcha — a known live bug). If the trigger
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
- [ ] **SETTINGS → ALLOW RE-ENTRY = ON** — open the workflow **Settings** tab; Allow Re-entry must be ON
      so every inbound message re-triggers the workflow.
      - **WHERE:** the workflow's **Settings** tab. **WHAT YOU SHOULD SEE:** Allow Re-entry = ON/Enabled.
      - **IF OFF:** toggle it ON (off = fires once per contact then silently never again).
- [ ] **RAW BODY = all 23 keys, FLAT** (no nesting), `messageTemplate` placeholder-free, no stripped/
      short body. Re-paste the full 23-key body if any key is missing.
- [ ] **SEND-directive on the OpenClaw server mapping** — the `hooks.mappings` server-mapping
      `messageTemplate` (object B — NOT the GHL body) ORDERS the agent to SEND via the GHL Conversations
      API (POST conversations/messages), **mirroring the inbound channel** into the send `type` (not a
      hardcoded SMS), **threaded by `contactId`** (the send body is `{type, contactId, locationId,
      message}` — no `conversationId` on send), and to NOT end its turn until a messageId is returned.
      Drafting is NOT sending — without this clause the agent drafts a reply and the customer gets
      nothing. Machine-check: `scripts/qc-send-directive.sh` must PASS.
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
- **Add-Tag actions** — apply a tag at a point in the flow (e.g. tag `ZHC-discovery-scheduled` after
  the webhook fires; agent-created tags carry the `ZHC-` prefix per MEMORY Rule 20 /
  `zhc-tag-prefix-protocol.md`).
- **tag-check conditions** — branch on whether a contact already has a tag.
- **multiple sequential actions** — e.g. Custom Webhook → wait → Add-Tag → if/else. Each action gets
  its full field spec, same rigor as §3 for any webhook in the chain.

**CREATE-TAG-FIRST rule (binding).** If the workflow uses ANY tag — a trigger/If-Else filter (`tag is` /
`tag contains` / `tag does not contain`) OR an Add-Tag action — the agent CREATES the tag FIRST via the
GHL skill (per conversation-workflows-protocol.md §D.1) BEFORE building the workflow, then references the
now-existing tag in the Build-with-AI prompt. **Every tag the agent creates programmatically carries the
`ZHC-` prefix** (e.g. `ZHC-discovery-scheduled`) per MEMORY Rule 20 — only the NAME changes; the
mechanism is unchanged. **Why it matters:** Build-with-AI will happily build a
filter that references a tag that does not exist (it leaves it blank), and a blank/non-existent tag in a
`does not contain` filter silently never matches — so the workflow never fires (the blank-tag gotcha). Do not
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

SETTINGS:
- Allow Re-entry: ON   (the workflow must be allowed to re-enter / fire repeatedly per contact, so every inbound message re-triggers it)

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

PUBLISH: Save the workflow, flip the top-right Publish toggle to ON, then Save again. Do NOT leave it as a draft.
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

---

## 7. NEW-PLAYBOOK CREATION FLOW — agent behavior (trigger word + "I Do / You Do" + brainstorm)

A workflow-AI prompt is one third of THE TRINITY, so it is built during the same playbook-CREATION flow.
That flow's agent behavior is defined in full in `conversation-workflows-protocol.md` (Section A.0 / A.1 /
A.2 + Part 3) and mirrored in `communications-playbook-standard.md` §8. Do NOT duplicate the flow here —
this is the pointer so the prompt builder honors it:

- **A.0 — personal TRIGGER WORD (FIRST build only).** Before the brainstorm, the agent OFFERS the client a
  voice-assistant-style trigger word (*"like 'Alexa' or 'Hey Siri'"*; e.g. *"Playbook time!"*), confirms
  it, and REMEMBERS it (USER.md + `conversation-workflows/registry.md` header + AGENTS.md trigger set) so
  later builds recognize it without re-offering.
- **A.1 — "I Do / You Do" overview (every build start).** The agent presents the 8-step who-does-what map
  (YOU trigger → I brainstorm → YOU answer → I draft → YOU review → I finalize+store+build THIS Workflow AI
  prompt wired to Convert and Flow → I wire the tag/calendar/appointment actions → YOU approve, go live)
  and sets the **~15-30 minute** expectation up front.
- **A.2 — brainstorm prep.** The agent's job is to BRAINSTORM the perfect playbook WITH the client, telling
  them the things to think about (goal, audience, channel, offer/hook, tone, timing/cadence, win action)
  and reassuring *"if you're unsure, that's what I'm here to brainstorm"* — then asking only smart-gap
  questions, never a 50-question form.

The CLIENT-FACING explanation (trigger word + I-Do/You-Do + ~15-30 min) is in the generated client doc —
see §6 above + `scripts/21-generate-client-reference-sheet.sh`, machine-enforced by
`scripts/qc-reference-sheet.sh`.
