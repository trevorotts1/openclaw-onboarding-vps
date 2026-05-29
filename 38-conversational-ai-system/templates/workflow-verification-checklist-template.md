<!-- OPERATOR HEADER -->
<!-- Skill 38 template: Build-with-AI verification checklist (from playbook v5.14 Step 9.20-D.3, lines 4069-4170; operator-instruction location corrected to Automations → "Build with AI"). -->
<!-- The pattern: every checklist item names the failure mode + the click-by-click fix. -->
<!-- Substitution placeholders: <PUBLIC_HOSTNAME>, <ROUTE_ID>, <CHANNEL>, <HOOKS_TOKEN>. -->
<!-- Rendered per-workflow by scripts/21-generate-client-reference-sheet.sh. -->
<!-- Standard: references/workflow-ai-instructions-standard.md §4. -->

## BUILD-WITH-AI VERIFICATION CHECKLIST (run AFTER Build-with-AI finishes — concise)

> **FIRST — MANUALLY FILL THE CUSTOM WEBHOOK ACTION.** Build-with-AI only builds the SHAPE (trigger +
> filters + an EMPTY Custom Webhook action). It does NOT reliably fill the URL, the Authorization/Bearer
> header, the Content-Type header, or the Raw Body JSON — Build with AI will NOT fill these for you. After
> Build-with-AI runs, open the **Custom Webhook** action and MANUALLY enter:
> **Method = POST**; the **URL** (`https://<PUBLIC_HOSTNAME>/hooks/<ROUTE_ID>`); Headers via **Add item →**
> `Authorization: Bearer <HOOKS_TOKEN>` and `Content-Type: application/json`; the **Raw Body JSON** (full
> flat 23-key). Then **Save + Publish**. **Verify every field is non-empty before publishing.** The
> checklist below confirms each of those fields was filled correctly.

GHL's Build-with-AI populates the webhook poorly, so run this every time, even when the prompt
"succeeded". Open the workflow and confirm EACH item before publishing:

- [ ] **Trigger type + filter** correct (e.g. "Customer Replied", filtered to `<CHANNEL>` — not all channels).
- [ ] **Exactly the intended action(s)** exist — none missing, none extra (for multi-action: every
      if/else branch + Add-Tag + tag-check present).
- [ ] **Custom Webhook METHOD = POST.**
- [ ] **URL is the REAL hook URL** `https://<PUBLIC_HOSTNAME>/hooks/<ROUTE_ID>` — NOT the sample-url
      placeholder, no trailing slash, correct path.
- [ ] **AUTHORIZATION dropdown = None** (token lives in Headers).
- [ ] **HEADERS contain** `Authorization: Bearer <HOOKS_TOKEN>` (added via "Add item") **and**
      `Content-Type: application/json`.
- [ ] **CONTENT-TYPE = application/json.**
- [ ] **RAW BODY = all 23 keys, FLAT** (no nesting), `messageTemplate` placeholder-free, no stripped body.
      (The skill's body EXAMPLES are machine-checked by `scripts/qc-23-key-bodies.sh` — run it if you
      edit any embedded body.)
- [ ] **SEND-directive present on the OpenClaw server mapping** — the `hooks.mappings` server-mapping
      `messageTemplate` (NOT the GHL body) ORDERS the agent to SEND via the GHL Conversations API
      (POST conversations/messages) and to NOT end the turn until a messageId/conversationId is
      returned. Drafting is NOT sending — without this clause the agent composes a reply and stops and
      the customer gets nothing. Verify in `~/.openclaw/openclaw.json`. Machine-check:
      `scripts/qc-send-directive.sh` must PASS.
- [ ] **Any required tags created/applied** (created beforehand via the GHL skill).
- [ ] **Workflow Published** (not Draft).
- [ ] **THE TRINITY complete** — this workflow has its communications playbook (`<slug>.md`) AND its
      Build-with-AI prompt (`<slug>--build-with-ai-prompt.md`) AND a row in `registry.md`. Machine-check:
      `scripts/qc-trinity-registry.sh` must PASS.

The detailed, click-by-click failure-mode version follows below (verbatim from the playbook).

---

> "✓ Build-with-AI prompt ready. Two things to do:
>
> 1. Open your Convert and Flow account
> 2. Click **Automations** on the left menu (GHL Automations have no API
>    and no MCP — the **Build with AI** button is the only programmatic path)
> 3. Create a **new** automation/workflow → click **Build with AI** (top-right)
> 4. Paste the prompt I saved at:
>    `<MASTER_FILES_DIR>/conversation-workflows/<workflow-id>--build-with-ai-prompt.md`
> 5. Let Build with AI build it
>
> Once it's built, come back and tell me. I'll give you a verification
> checklist — sometimes Build with AI gets the scaffolding right but
> misses critical pieces."

#### D.3 — Generate the brutally-specific verification checklist

The agent writes a verification checklist tailored to the EXACT specifications the prompt was supposed to produce. Saved as: `<MASTER_FILES_DIR>/conversation-workflows/<workflow-id>--verification-checklist.md`.

The checklist follows this pattern — every item names the specific failure mode and the specific fix:

```markdown
# Verification Checklist — <Workflow Name>

After Build with AI builds the workflow, open it and check EACH item below.
If any item is wrong, the fix is listed right there.

## Trigger

- [ ] Trigger is set to EXACTLY "<exact trigger name>"
  - WRONG VALUES TO WATCH FOR: <common Build with AI mistakes>
  - FIX IF WRONG: Click the trigger node → change to "<exact value>"

## Filters

- [ ] Filter 1: <field> equals "<exact value>"
  - WRONG VALUES TO WATCH FOR: <variants Build with AI may pick>
  - FIX IF WRONG: <specific click-by-click fix>

- [ ] Filter 2: <field> equals "<exact value>"
  - WRONG VALUES TO WATCH FOR: ...
  - FIX IF WRONG: ...

## Webhook Action

- [ ] Webhook URL is EXACTLY: `https://<PUBLIC_HOSTNAME>/hooks/<HOOK_NAME>`
  - Common mistake: Build with AI adds trailing slash or wrong path
  - FIX IF WRONG: Click the webhook action → URL field → paste exact URL

- [ ] Method is POST (not GET, not PUT)
  - FIX IF WRONG: Change Method dropdown to POST

- [ ] AUTHORIZATION dropdown is set to "None" (NOT "Bearer Token" — the
       token goes in Headers, not in this dropdown — common Build with AI
       mistake)
  - FIX IF WRONG: AUTHORIZATION dropdown → None

- [ ] Headers section contains TWO headers:
       Header 1: Authorization = Bearer <HOOKS_TOKEN>
       Header 2: Content-Type = application/json
  - FIX IF WRONG: Add missing header(s) in the Headers section

- [ ] Content-Type dropdown is "application/json"
  - FIX IF WRONG: Change dropdown

- [ ] Raw Body matches the full 23-key JSON from the D.2 prompt EXACTLY
       (whitespace doesn't matter, but every field, every quote, every
       brace must match — the body MUST contain ALL 23 keys, no
       stripped/short body):

```json
{
  "id": "<HOOK_NAME>",
  ... [the full 23-key body from the D.2 prompt; 23 = minimum] ...
  "location_name": "{{location.name}}"
}
```
  - Common Build with AI mistake: ships a stripped/short body (fewer than 23
    keys — most often drops `id`, `model`, `to`, `thinking`, or
    `session_key`), or uses wrong variable syntax (e.g., `{contact.id}`
    instead of `{{contact.id}}`)
  - FIX IF WRONG: Click Raw Body → replace entirely with the full 23-key
    JSON above

## Publish

- [ ] Workflow status is "Published" (NOT "Draft" — Build with AI often
       saves as draft)
  - FIX IF WRONG: Click the toggle at top right of the workflow → Publish

- [ ] Workflow has a "When should this workflow run" setting that
       includes the times you want (e.g., All Day, or specific business
       hours)
  - FIX IF WRONG: Click workflow settings → adjust schedule

## End-to-end test

- [ ] Trigger the workflow manually (e.g., reply to your test SMS)
- [ ] Watch the workflow execution log in Convert and Flow — should
       show "Webhook sent successfully" with a 2xx status
- [ ] Check your conversation log file — should show the new message
       arrived in the AI's log

If end-to-end test passes, the workflow is fully wired and live.

If end-to-end test fails, copy the error from the Convert and Flow
execution log and bring it back to the agent.
```

Each verification item is generated from the same source-of-truth as the prompt — so they're guaranteed to match.
