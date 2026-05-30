<!-- OPERATOR HEADER -->
<!-- Skill 38 template: SMS Build-with-AI prompt — copy-paste-ready. Pasted into GHL Automations → "Build with AI". -->
<!-- Built from playbook v5.14 Step 9.20-D.2 (lines 4015-4069). -->
<!-- Substitution placeholders are listed below. Rendered per-client by scripts/21-generate-client-reference-sheet.sh. -->
<!-- The single fenced code block below is what the client pastes into GHL Automations → "Build with AI". -->

# Your First Workflow — SMS Inquiry Responder

This is the first conversation workflow we're wiring up for **<CLIENT_BUSINESS_NAME>**. When a contact texts you, this workflow fires, sends the message to your conversational AI, and lets the AI respond on your behalf — including, when the conversation is ready, helping the contact <DESIRED_OUTCOME>.

You don't have to build this workflow by hand. In Convert and Flow's **Automations** area, the **"Build with AI"** button (top-right of a new automation) constructs the entire workflow from a prompt. The prompt is below. Copy it once, paste it once, done.

## How to use this

1. Open your Convert and Flow account.
2. Click **Automations** on the left menu. (GHL Automations have NO API and NO MCP — the **Build with AI** button is the only programmatic path.)
3. Create a **new** automation/workflow → click **Build with AI** (top-right).
4. Copy the entire block below (the one starting with `Build a workflow for me with these exact specifications:`) and paste it into **Build with AI**.
5. Let Build with AI construct the SHAPE (trigger, filters, the Custom Webhook step).
6. Open the **Build-with-AI Verification Checklist** (Section 4 of this Notion page, or the matching `.md` file on your Mac) and verify each item before publishing. Build-with-AI populates the webhook fields poorly — verification is mandatory.

> **Standard:** the full field-by-field Custom Webhook spec + multi-action teaching live in
> `references/workflow-ai-instructions-standard.md`. This template is the rendered SMS case.

## This prompt always contains the same five mandatory parts

Every workflow-AI prompt this skill produces — for every client — contains ALL of these, in this exact
order (only the substituted values change). This is the standardization contract from
`references/workflow-ai-instructions-standard.md` §0:

1. **Workflow name + PUBLISH** (publish when done; never leave as draft).
2. **Trigger: type + sub-option + filters in exact order** (Customer Replied / On Reply / Channel = SMS /
   Message Direction = Inbound).
3. **Settings → Allow Re-entry = ON** (the workflow must be allowed to re-enter / fire repeatedly per
   contact, so every inbound text re-triggers it; default off fires once then goes dead).
4. **Custom Webhook — every field with the exact value** (EVENT, METHOD, URL, AUTHORIZATION dropdown, both
   HEADERS, CONTENT-TYPE, the full FLAT 23-key RAW BODY).
5. **Save → Publish toggle ON → Save** (the closing sequence that takes it live).

## The copy-paste prompt

```text
Build a workflow for me with these exact specifications:

CONTEXT:
This workflow is for <CLIENT_BUSINESS_NAME>, which operates in <INDUSTRY_CONTEXT>. The end goal for every conversation that flows through this workflow is to <DESIRED_OUTCOME>. Build the workflow exactly to the spec below — do not improvise or add steps.

TRIGGER:
- Type: Customer Replied
- Sub-option: On Reply
- Channel: SMS

FILTERS (in this exact order):
- Filter 1: Channel equals "SMS"
- Filter 2: Message Direction equals "Inbound"

SETTINGS:
- Allow Re-entry: ON  (the workflow must be allowed to re-enter / fire repeatedly per contact, so EVERY inbound text re-triggers it; if this is off it fires once per contact then silently never fires again)

ACTIONS (in this exact order):
- Action 1: Send Custom Webhook
  - EVENT: CUSTOM  (this is a Custom Webhook, not a templated/integration webhook)
  - METHOD: POST  (pick POST from the Method dropdown — not GET, not PUT)
  - URL: https://<PUBLIC_HOSTNAME>/hooks/<ROUTE_ID>  (paste this EXACT url — do NOT leave the Build-with-AI sample-url placeholder; no trailing slash, correct hostname + /hooks/ path)
  - AUTHORIZATION dropdown: None  (the token goes in Headers, NOT in the Authorization dropdown — leave the dropdown set to None)
  - HEADERS (click "Add item" once per header):
    - Add item → Key: Authorization, Value: Bearer <HOOKS_TOKEN>
    - Add item → Key: Content-Type, Value: application/json
  - CONTENT-TYPE dropdown: application/json
  - Body type: Raw JSON
  - RAW BODY — MUST be FLAT (no nested objects) and MUST contain ALL 23 keys (23 = minimum, no
    stripped/short bodies). The KEY names are what OpenClaw reads; insert the data VALUES via GHL's
    Custom Values picker (typed-as-text tokens send EMPTY). Keep `messageTemplate` placeholder-free
    (no `{{…}}`) so GHL never mangles it:
    {
      "id": "<ROUTE_ID>",
      "match": "<ROUTE_ID>",
      "action": "agent",
      "agent_id": "<AGENT_ID>",
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

PUBLISH: Save the workflow, flip the top-right Publish toggle to ON, then Save again. Don't leave it as draft.

RUN SCHEDULE: All Day (so the AI can respond at any hour the customer texts in).
```

## What Build with AI will build

After you paste the prompt above, **Build with AI** should produce a workflow with:

- **One trigger node**: "Customer Replied" with sub-option "On Reply" and channel filter "SMS".
- **Two filter nodes** (in order): Channel = SMS, Message Direction = Inbound.
- **One action node**: "Send Custom Webhook" pointing at `https://<PUBLIC_HOSTNAME>/hooks/<ROUTE_ID>` with the two headers above and the Raw JSON body above.
- **Settings → Allow Re-entry**: ON (so every inbound text re-triggers the workflow).
- **Status**: Published (NOT draft).
- **Run schedule**: All Day.

If the workflow Build with AI produced doesn't match this shape, that's normal — Build with AI is a helper, not infallible. Use the verification checklist (Section 4) to fix the gaps.

## MANDATORY — after Build with AI runs, MANUALLY fill the Custom Webhook action yourself

**Build with AI only builds the SHAPE (the trigger, the filters, and an EMPTY Custom Webhook action). It
does NOT reliably fill in the URL, the Authorization/Bearer header, the Content-Type header, or the Raw
Body JSON. Build with AI will NOT fill these for you.** So after it finishes, you MUST open the Custom
Webhook action and enter these values by hand:

1. Open the workflow Build with AI made → click the **Custom Webhook** action to edit it.
2. **Method:** `POST`.
3. **URL:** paste this EXACTLY — `https://<PUBLIC_HOSTNAME>/hooks/<ROUTE_ID>` (no trailing slash; don't
   leave the sample-url placeholder).
4. **AUTHORIZATION dropdown:** leave on `None` (the token goes in Headers, not here).
5. **Headers** — click **"Add item"** and add, by hand:
   - `Authorization` → `Bearer <HOOKS_TOKEN>`
   - `Content-Type` → `application/json`
6. **Content-Type dropdown:** `application/json`.
7. **Raw Body:** paste the FULL FLAT 23-key JSON from the prompt above (the block beginning `{ "id": ... }`).
8. **Settings → Allow Re-entry:** open the workflow's **Settings** tab and set **Allow Re-entry** to **ON**
   so every inbound text re-triggers the workflow (default off fires once, then goes dead).
9. **Save** the action, flip the top-right **Publish** toggle **ON**, then **Save** again.
10. **Verify every field above is non-empty before you publish** — an empty URL, header, or body means
    every text silently goes nowhere.

There is no shortcut here: GHL Automations have no API and no MCP, and Build with AI won't paste these in.
This is your step — paste the values into the Custom Webhook action yourself, then verify and publish.

## Multi-action note (when this workflow needs more than one action)

This SMS template is the simplest case — one trigger, two filters, one Custom Webhook. Real workflows
often need **more than one action**. A Build-with-AI prompt can describe **trigger + (optional if/else)
+ one-or-more actions**:

- **if/else (if-else) branches** — additional filtering after the trigger (e.g. "IF contact has tag
  `vip` → branch A; ELSE → branch B"). Spell out each branch's condition + its actions.
- **Add-Tag actions** — apply a tag at a point in the flow (e.g. tag `pricing-interest` after the webhook).
- **tag-check conditions** — branch on whether a contact already has a tag.
- **multiple sequential actions** — e.g. Custom Webhook → Add-Tag → if/else; each webhook in the chain
  gets the SAME full field-by-field spec as Action 1 above.

**Create the tag FIRST.** If a workflow references a tag — a trigger/If-Else filter (`tag is` /
`tag contains` / `tag does not contain`) OR an Add-Tag action — the agent creates that tag via the GHL
skill BEFORE building the workflow, then references the now-existing tag in the prompt. Never tell the
operator to create tags by hand, and never reference a tag that doesn't exist yet. **Where tags live:**
**Settings → Tags** — that's where to confirm a tag exists (you should see every tag the workflow
references, spelled exactly). **Why this is mandatory:** Build-with-AI will build a filter against a tag
that doesn't exist (leaving it blank), and a blank/non-existent tag in a `does not contain` filter
silently never matches — so the workflow never fires. Full multi-action skeleton + standard:
`references/workflow-ai-instructions-standard.md` §5.

## Common Build with AI mistakes to verify against the checklist

Build with AI is helpful but has known failure modes. The most common ones:

- Puts the bearer token in the **AUTHORIZATION dropdown** instead of in the **Headers** section. The dropdown must be "None" — the `Authorization: Bearer <HOOKS_TOKEN>` line goes in Headers.
- Adds a trailing slash to the webhook URL, or drops the `/hooks/` path segment.
- Uses single curly-brace variables (`{contact.id}`) instead of GHL double-brace syntax (`{{contact.id}}`).
- **NESTS the body** (`contact: {…}`, `customer_message: {…}`) instead of keeping it FLAT — a nested
  body makes EVERY field arrive EMPTY at the hook. The body must be flat, top-level keys only.
- **Puts `{{…}}` placeholders inside the body's `messageTemplate` value** — the body's `messageTemplate`
  must stay PLACEHOLDER-FREE (a templated messageTemplate in the body makes GHL throw "Error while parsing
  the object to JSON" and the webhook is Skipped). Keep it the plain instruction string shown above.
- **Builds a trigger/If-Else tag filter (`does not contain` / `contains`) that references a BLANK or
  non-existent tag** — a known live bug (the blank-tag gotcha). A blank tag in a `does not contain` filter
  silently never matches, so the workflow never fires. Verify the filter shows a REAL tag name that exists
  under **Settings → Tags**; if blank/wrong, select (or create first) the correct tag, or remove the bad
  filter.
- **Leaves Settings → Allow Re-entry OFF** — the workflow then fires ONCE per contact and silently never
  fires again, so the AI answers the first text and goes dead on every text after. Set **Allow Re-entry =
  ON**.
- Saves the workflow as **Draft** instead of **Published**.
- **Ships a stripped/short body (fewer than 23 keys)** — the body MUST contain ALL 23 keys. Build with AI
  most often drops `id`, `model`, `to`, `thinking`, `location_id`, or `session_key`. Re-paste the full
  23-key body if any key is missing.
- Sets the wrong run schedule (e.g., business hours only when you wanted 24/7).

Each of these failure modes is covered in **Section 4 — Workflow Verification Checklist** with the exact click-by-click fix. Run the checklist top-to-bottom after Build with AI finishes. Don't publish until every item is checked.

## Placeholders used in this template

When this template is rendered for a real client, the following placeholders are substituted with concrete values:

- `<CLIENT_BUSINESS_NAME>` — the client's business name (e.g., a generic "Acme Co")
- `<CLIENT_FIRST_NAME>` — the client's first name
- `<PUBLIC_HOSTNAME>` — the client's public tunnel hostname, e.g., `claw.<client-domain>.com`
- `<ROUTE_ID>` — e.g., `ghl-sales` (the hooks.mappings key / `match.path` configured in Step 3; also the
  body's `match` value)
- `<AGENT_ID>` — the target agent id for this hook path, e.g., `sales` (body data only; the real routing
  `agentId` is hardcoded on the server mapping — agentId is NOT templatable, see GHL-INBOUND §14.9)
- `<HOOKS_TOKEN>` — the bearer token from `SECRETS_ENV_FILE`
- `<INDUSTRY_CONTEXT>` — the client's industry, e.g., "real estate", "coaching", "med spa"
- `<DESIRED_OUTCOME>` — e.g., "book a 15-minute discovery call on your calendar", "set up a free consultation"
