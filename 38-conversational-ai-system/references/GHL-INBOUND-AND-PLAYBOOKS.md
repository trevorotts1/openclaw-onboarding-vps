# GHL Inbound + Conversation Playbooks — Authoritative Reference (Skill 38)

> **What this document is.** The single source of truth for wiring GoHighLevel (Convert and Flow)
> inbound conversations into OpenClaw and replying via the GHL API. It disambiguates the four
> secrets, defines the one-tunnel-many-hooks model, ships the copy-paste **Build-with-AI prompt**
> (the only programmatic way to build a GHL automation), a post-build verification checklist, the
> reusable-assets storage rule, the verified channel→type enum, the Conversations + Calendar API
> recipes, and the **first conversation playbook (appointment booking)**.
>
> **Scope: VPS / Hostinger-Docker installs.** Paths use `/data/…`, secrets live in host-level
> `/docker/<project>/.env`, cloudflared runs via pm2. See the "VPS specifics" call-outs throughout.
>
> Everything here was verified against a live client build (Corey, Hostinger Docker VPS) and probed
> against the live GHL API. Where a value was probed, it is marked **VERIFIED**.
>
> **⚠️ READ §14 FIRST — "CORRECTED GHL HOOK STRUCTURE (2026-05-29)".** The GHL Custom Webhook Raw Body
> is **FLAT** (no nested objects) and **data-only** (NO `messageTemplate`); the `messageTemplate` lives
> **only** on the server `hooks.mappings` entry and **must** include the reply-via-GHL-API instruction.
> §14 supersedes any older nested-body or in-body-messageTemplate example anywhere in this skill.

---

## 1. The four tokens — keep these disambiguated EVERYWHERE

There are **four distinct secrets** in this system. Confusing any two of them is the most common
cause of a broken install. Never collapse them, never reuse one in another's slot.

| # | Token | Example format | Purpose | Direction | Create-once vs reuse |
|---|---|---|---|---|---|
| 1 | **`CLOUDFLARE_API_TOKEN`** (a.k.a. "Cloudflare API key" — SAME secret) | `cfut_…` | The client creates it in their Cloudflare account. The agent uses it **once** to build the tunnel + DNS CNAME, then never again. | Agent → Cloudflare API (build-time only) | Create once per client; used once, then idle |
| 2 | **Tunnel connector token** | `eyJ…` (long JWT) | Returned when the tunnel is created. `cloudflared` uses it to **run** the tunnel (connect the VPS to Cloudflare's edge). | cloudflared → Cloudflare edge (runtime, always) | Created once with the tunnel; reused for the life of the tunnel |
| 3 | **`HOOKS_TOKEN`** | 64-hex e.g. `527cef27…` | GHL sends it as `Authorization: Bearer` on **inbound** webhooks. OpenClaw's hooks layer verifies it. **Shared by ALL hook paths** on this client; does not change. **This is the header token that goes in the Build-with-AI prompt.** | GHL → OpenClaw (inbound, every message) | Created once per client; reused by every hook path |
| 4 | **`GHL_PRIVATE_INTEGRATION_TOKEN`** (PIT) | `pit-9f…` | The agent (e.g. "Candace") uses it as `Bearer` to call GHL's API to **send** replies and book appointments (outbound). | OpenClaw → GHL API (outbound, every reply/booking) | Created once per client (their GHL sub-account); reused for all outbound calls |

**Mnemonic:**
- Token **1** *builds* the road (one-time).
- Token **2** *keeps the road open* (cloudflared runtime).
- Token **3** *lets GHL drive INTO* OpenClaw (inbound auth).
- Token **4** *lets OpenClaw drive OUT TO* GHL (outbound auth).

### VPS specifics for the tokens

- **`HOOKS_TOKEN` MUST be set as `OPENCLAW_HOOKS_TOKEN` in host-level `/docker/<project>/.env`.**
  The Hostinger wrapper at `/hostinger/server.mjs` runs on **every container boot** and rewrites
  `hooks.token` in `openclaw.json` to `$OPENCLAW_HOOKS_TOKEN || hooks_${OPENCLAW_GATEWAY_TOKEN}`.
  If you only write the token into `openclaw.json`, the next force-recreate **resets it** and GHL
  starts getting `401`. After editing the `.env`, apply with:
  ```bash
  cd /docker/<project> && docker compose up -d --force-recreate
  ```
  (`docker compose restart` does **not** reload `env_file` changes — you must `up --force-recreate`.)
- Secrets live in **both** the canonical host-level `/docker/<project>/.env` (visible in
  `docker exec <ctr> printenv`) **and** mirrored into container-side `/data/.openclaw/.env`
  (some scripts grep the container copy). Keep them in sync.
- `cloudflared` is run via **pm2** on the VPS (`pm2 start … && pm2 save`), **not** systemd.

---

## 2. One tunnel, many hooks — created ONCE, reused forever

The networking layer is built **once per client** and then **reused** for every future automation:

- **Created once (never recreate):**
  - the Cloudflare **tunnel** (token #2, the connector token),
  - the **public hostname** (e.g. `hooks.acmecoaching.com`),
  - the **`HOOKS_TOKEN`** (token #3).
- **Added per automation (cheap, repeatable):**
  - a new **hook PATH** on the same hostname, e.g.
    `/hooks/ghl-inbound`, `/hooks/ghl-inbound-sales`, `/hooks/ghl-inbound-support`, …
  - each path routes to a different **agent and/or playbook**.

So a second, third, tenth conversation type does **NOT** mean a new tunnel or a new token. It means
**one more entry in `hooks.mappings`** (a new `id` + `match.path`) on the same hostname, authenticated
by the same shared `HOOKS_TOKEN`, and a new GHL automation whose Custom Webhook posts to that new path.

> **Binding rule: never recreate the tunnel.** If the agent finds an existing tunnel + hostname +
> connector token + `HOOKS_TOKEN` for this client (see §6 Reusable Tunnel Values), it MUST reuse them
> and only add a new hook path. Recreating the tunnel breaks every existing automation pointing at the
> old hostname.

Hook URL shape (always): `https://<PUBLIC_HOSTNAME>/hooks/<HOOK_PATH>`

---

## 3. The Build-with-AI prompt (PRIMARY method to build a GHL automation)

GHL has **no public API or MCP to build automations** programmatically. The **only** programmatic
path is GHL's own **"Build with AI"** feature (Automations → new workflow → Build with AI). The
operator pastes the prompt below, GHL's AI builds the workflow, then the operator runs the
verification checklist in §4.

This is the **primary** method. The 20-step click-by-click hand-build is the **fallback** (used only
if Build-with-AI fails — see the playbook Step 6 FALLBACK section).

### 3.1 Copy-paste TEMPLATE (generic, with placeholders)

Replace every `{{…}}` placeholder before handing it to the operator:

- `{{PUBLIC_HOSTNAME}}` — the client's tunnel hostname, e.g. `hooks.acmecoaching.com`
- `{{HOOK_PATH}}` — the hook path for THIS automation, e.g. `ghl-inbound` (no leading slash)
- `{{HOOKS_TOKEN}}` — the shared 64-hex `HOOKS_TOKEN` (token #3)
- `{{CHANNEL}}` — the exact channel this automation is filtered to, e.g. `SMS`, `Email`, `FB`, `IG`,
  `WhatsApp`, `Live_Chat` (see §7 for the verified enum)
- `{{AGENT_ID}}` — the target agent id for this hook path, e.g. `sales` (data only; agentId is set on
  the server mapping, NOT templatable there — see §14.9)

```text
Build a GoHighLevel workflow for me with these EXACT specifications. Do not add, remove, or
reorder anything. When finished, PUBLISH the workflow — do not leave it as a draft.

WORKFLOW NAME:
  OpenClaw Inbound — {{CHANNEL}}

TRIGGER:
  - Type: "Customer Replied"
  - Filter the trigger to the channel: {{CHANNEL}}
    (i.e. only fire this workflow when the reply comes in on the {{CHANNEL}} channel)

ACTION (exactly one action):
  - Type: "Custom Webhook"
  - Method: POST
  - URL: https://{{PUBLIC_HOSTNAME}}/hooks/{{HOOK_PATH}}
  - Headers (add BOTH, exactly as written):
      Authorization: Bearer {{HOOKS_TOKEN}}
      Content-Type: application/json
  - Body type: Raw / JSON
  - Raw Body (use this EXACT JSON — it MUST be FLAT, NO nested objects. The KEY names are what
    OpenClaw reads/maps; the VALUES are GHL merge tokens inserted via GHL's Custom Values picker —
    do not invent extra fields, do not drop any, do NOT add a messageTemplate here):
    {
      "channel": "{{CHANNEL}}",
      "contact_id": "{{contact.id}}",
      "first_name": "{{contact.first_name}}",
      "last_name": "{{contact.last_name}}",
      "email": "{{contact.email}}",
      "phone": "{{contact.phone}}",
      "subject": "{{message.subject}}",
      "message_body": "{{message.body}}",
      "match": "{{HOOK_PATH}}",
      "session_key": "hook:ghl:{{CHANNEL}}:{{contact.id}}",
      "agent_id": "{{AGENT_ID}}",
      "location_id": "{{location.id}}",
      "location_name": "{{location.name}}"
    }

PUBLISH:
  - Yes — publish the workflow when done. Do NOT leave it as a draft.
```

### 3.2 Notes for whoever fills the template

- **The Raw Body is FLAT and data-only — it must NOT contain a `messageTemplate`.** See §14 for the
  cardinal rule and the full corrected structure (verified LIVE 2026-05-29).
- One automation = one channel. Build a separate automation (and a separate hook path) per channel the
  client actually uses (there is no GHL merge tag for channel — hardcode it, see §14.6).
- Insert the Raw Body VALUES via GHL's **Custom Values picker** — typed-as-text tokens send empty (§14.7).
- The Raw Body's `channel` value should match the verified enum in §7 so the downstream reply uses a
  valid GHL send `type`.
- The `Authorization` header value is `Bearer ` + the **`HOOKS_TOKEN`** (token #3) — **not** the PIT,
  **not** the gateway token, **not** the Cloudflare token.

---

## 4. Post-build VERIFICATION CHECKLIST (run AFTER GHL's AI finishes)

GHL's Build-with-AI often gets the scaffolding right but quietly misses a header, mangles the URL, or
leaves the workflow in Draft. **Always** run this checklist, even when the prompt "succeeded." For each
item: open the published workflow in GHL and confirm by clicking into the trigger and the Custom Webhook
action.

- [ ] **Trigger** is "Customer Replied" and is **filtered to `{{CHANNEL}}`** (not all channels).
- [ ] **Action** is a single **Custom Webhook**.
- [ ] **Method** is **POST** (not GET).
- [ ] **URL** is **exactly** `https://{{PUBLIC_HOSTNAME}}/hooks/{{HOOK_PATH}}` — character-for-character,
      no trailing slash, no typo in the hostname or path.
- [ ] **Authorization header** is present and equals `Bearer {{HOOKS_TOKEN}}` (correct token, no extra
      spaces, no quotes around the value).
- [ ] **Content-Type header** is present and equals `application/json`.
- [ ] **Raw Body** is **FLAT** (NO nested `contact:{}` / `customer_message:{}` objects — nesting makes
      every field resolve EMPTY at the hook) and matches the template JSON **field-for-field**:
      `channel`, `contact_id`, `first_name`, `last_name`, `email`, `phone`, `subject`, `message_body`,
      `match`, `session_key`, `agent_id`, `location_id`, `location_name` — and the merge VALUES were
      inserted via GHL's **Custom Values picker** so they actually resolve (not literal `{{message.body}}`,
      not typed-as-text tokens which send empty).
- [ ] **Raw Body contains NO `messageTemplate`** — the messageTemplate lives ONLY on the server mapping
      (a templated `messageTemplate` in the GHL body makes GHL try to expand `{{contact_id}}`/`{{message_body}}`
      as its own merge fields, mangle them to `##{}##`, drop the closing quote, and throw
      "Error while parsing the object to JSON" → the webhook is Skipped).
- [ ] Workflow status is **Published**, not Draft.

**Then send a REAL inbound and confirm end-to-end:**

- [ ] From a real customer channel (or a test contact), send a real inbound message on `{{CHANNEL}}`.
- [ ] Confirm OpenClaw's hooks endpoint returns **HTTP 200** (check gateway logs:
      `openclaw logs --tail 30` / `docker logs <ctr> --tail 30`).
- [ ] Confirm the agent's **reply actually lands in the GHL conversation** for that contact.

> **Do NOT trust GHL's "Test" button.** GHL's built-in webhook test sends **empty merge fields**
> (`contact.id`, `message.body` come through blank), so a 200 from the Test button proves the URL/auth
> only — it does NOT prove the body maps correctly. **Use a real inbound message** to verify the full
> path.

---

## 5. The JSON structure rule (BINDING)

**One value per key, and the GHL Raw Body MUST be FLAT (no nested objects).** Each field gets its own
top-level key, so the payload stays clean, parseable, and — critically — actually resolves at the hook.

- ✅ FLAT: `{"channel": "sms", "contact_id": "...", "first_name": "...", "phone": "...", "message_body": "..."}`
- ❌ NESTED: `{"contact": {"id": "...", "first_name": "..."}, "customer_message": {"body": "..."}}` — a
  nested body makes EVERY field resolve **EMPTY** at the hook (proven LIVE 2026-05-29: even a hardcoded
  `"channel":"sms"` arrived blank when wrapped in nesting). See §14.
- ❌ Stuffing a long tutorial, multiple IDs, or a free-text blob into one `messageTemplate` /
  `message` / `body` string.

This applies to the hook Raw Body (FLAT, data-only, NO messageTemplate) and any reusable-values record
you store. The `hooks.mappings[].messageTemplate` lives ONLY on the server mapping — never in the GHL
body. If you find yourself concatenating distinct facts into one string, split them into keys.

---

## 6. Reusable-assets storage rule (BINDING — must happen EVERY time)

**Every time a tunnel or a hook path is created, store the reusable values in BOTH the agent-facing
files AND the client-facing Notion doc**, under a clearly-marked **"Reusable Tunnel Values"** section,
and keep it updated as new hook paths are added.

Store in **all three** locations:

1. **`AGENTS.md`** (agent-facing) — so the agent reuses, never recreates.
2. **`TOOLS.md`** (agent-facing) — so the agent knows the live endpoints + token var names.
3. **The client's own Notion doc** (client-facing) — so the operator can wire new GHL automations
   without asking.

> Each client gets their **own** Notion page / GHL location / tunnel / token. Never co-mingle one
> client's reusable values into another client's workspace.

### "Reusable Tunnel Values" section — required fields

```markdown
## Reusable Tunnel Values (created once — REUSE, never recreate)

- Public hostname:        <PUBLIC_HOSTNAME>            (e.g. hooks.acmecoaching.com)
- HOOKS_TOKEN:            <stored as env var OPENCLAW_HOOKS_TOKEN — value in /docker/<project>/.env>
- Tunnel ID:             <TUNNEL_ID>
- Connector token:        <stored in /docker/<project>/.env as CLOUDFLARE_TUNNEL_TOKEN — do not print>
- Hook-path registry:
  | Hook path            | Routes to (agent / playbook)        | Channel(s)   |
  |----------------------|-------------------------------------|--------------|
  | /hooks/ghl-inbound   | main / appointment-booking          | SMS          |
  | /hooks/ghl-inbound-... | ...                               | ...          |
```

When you add a new automation, **append a row to the hook-path registry** in all three places. The
HOOKS_TOKEN and connector token are secrets — store the **env-var name and location**, never the raw
value, in Notion; the raw values live only in `/docker/<project>/.env`.

---

## 7. Verified channel → GHL send `type` enum

GHL's Conversations API switches send behavior on the `type` field. These were **probed against the
live GHL API**:

**VALID send `type` values (API accepts):**

| Channel | `type` value |
|---|---|
| SMS | `SMS` |
| Email | `Email` |
| Facebook Messenger | `FB` |
| Instagram DM | `IG` |
| WhatsApp | `WhatsApp` |
| Live Chat | `Live_Chat` |

**INVALID (API REJECTS — do not use):**
- `TikTok`, `Call`, `GMB`
- long-forms: `Instagram`, `Facebook`, `Webchat`

> **TikTok caveat:** TikTok **inbound** triggers exist in GHL, but TikTok is **not** an API send
> `type`. To reply to a TikTok inbound you must use a **GHL workflow automation** to send, not the
> Conversations API. Do not attempt `type: "TikTok"` — it 4xx's.

---

## 8. GHL Conversations reply recipe (OUTBOUND)

**Endpoint:** `POST https://services.leadconnectorhq.com/conversations/messages`

**Headers (all three required):**
```
Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN
Version: 2021-04-15
Content-Type: application/json
```

Credential var: **`GHL_PRIVATE_INTEGRATION_TOKEN`** (token #4, the PIT). Version: **`2021-04-15`**.

**Per-channel body** (`type` from the §7 enum):

```bash
# SMS
curl -s -X POST https://services.leadconnectorhq.com/conversations/messages \
  -H "Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN" \
  -H "Version: 2021-04-15" -H "Content-Type: application/json" \
  -d '{"type":"SMS","contactId":"<CONTACT_ID>","message":"<reply text>"}'

# Email
curl -s -X POST https://services.leadconnectorhq.com/conversations/messages \
  -H "Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN" \
  -H "Version: 2021-04-15" -H "Content-Type: application/json" \
  -d '{"type":"Email","contactId":"<CONTACT_ID>","subject":"<subj>","html":"<html body>"}'

# Facebook Messenger
curl -s -X POST https://services.leadconnectorhq.com/conversations/messages \
  -H "Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN" \
  -H "Version: 2021-04-15" -H "Content-Type: application/json" \
  -d '{"type":"FB","contactId":"<CONTACT_ID>","message":"<reply text>"}'

# Instagram DM
curl -s -X POST https://services.leadconnectorhq.com/conversations/messages \
  -H "Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN" \
  -H "Version: 2021-04-15" -H "Content-Type: application/json" \
  -d '{"type":"IG","contactId":"<CONTACT_ID>","message":"<reply text>"}'

# WhatsApp
curl -s -X POST https://services.leadconnectorhq.com/conversations/messages \
  -H "Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN" \
  -H "Version: 2021-04-15" -H "Content-Type: application/json" \
  -d '{"type":"WhatsApp","contactId":"<CONTACT_ID>","message":"<reply text>"}'

# Live Chat
curl -s -X POST https://services.leadconnectorhq.com/conversations/messages \
  -H "Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN" \
  -H "Version: 2021-04-15" -H "Content-Type: application/json" \
  -d '{"type":"Live_Chat","contactId":"<CONTACT_ID>","message":"<reply text>"}'
```

---

## 9. GHL Calendar recipe (check / book / reschedule / cancel) — VERIFIED LIVE

Same auth as §8: `Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN`, `Version: 2021-04-15`.

> **Dates are epoch MILLISECONDS** on the calendar API (not seconds, not ISO).

### 9.1 Check availability (free slots)
```
GET https://services.leadconnectorhq.com/calendars/{calendarId}/free-slots?startDate={epochMillis}&endDate={epochMillis}
```
```bash
curl -s "https://services.leadconnectorhq.com/calendars/$CALENDAR_ID/free-slots?startDate=$START_MS&endDate=$END_MS" \
  -H "Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN" -H "Version: 2021-04-15"
```

### 9.2 Book an appointment
```
POST https://services.leadconnectorhq.com/calendars/events/appointments
```
**REQUIRED fields:** `calendarId`, `locationId`, `contactId`, `startTime`.
**OPTIONAL:** `endTime` (GHL derives it from the calendar's slot length if omitted).
```bash
curl -s -X POST https://services.leadconnectorhq.com/calendars/events/appointments \
  -H "Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN" \
  -H "Version: 2021-04-15" -H "Content-Type: application/json" \
  -d '{"calendarId":"<CAL_ID>","locationId":"<LOC_ID>","contactId":"<CONTACT_ID>","startTime":"<ISO or slot start>"}'
```
The response returns the appointment **`id`** — this `id` **is the `eventId`** for reschedule/cancel.

### 9.3 Reschedule
```
PUT https://services.leadconnectorhq.com/calendars/events/appointments/{eventId}
```

### 9.4 Cancel
```
DELETE https://services.leadconnectorhq.com/calendars/events/{eventId}
```

---

## 10. The FIRST conversation playbook = APPOINTMENT BOOKING

The base SMS automation install **must** also create the client's **first OpenClaw conversation
playbook** and wire its hook path to that playbook, so the GHL workflow and the OpenClaw playbook are
**demonstrably working together on day one**. The first playbook is a simple appointment-booking flow
built on the Calendar recipe (§9).

Save as a Layer 2 playbook markdown at:
`<MASTER_FILES_DIR>/conversation-workflows/appointment-booking.md`

### Ready template (Layer 2 playbook)

```markdown
# Conversation Playbook — Appointment Booking

**When this fires:** an inbound customer message routed via /hooks/ghl-inbound whose intent is to
book, schedule, or ask about availability for an appointment.

**Goal:** get the customer booked on the calendar with the fewest possible messages, then confirm.

## Flow

1. **Understand the request.** Greet by first name (from the hook payload `contact.first_name`).
   Identify that they want to book (or proactively offer to book if intent is ambiguous but
   booking-adjacent).

2. **Check availability.** Call the Calendar free-slots endpoint (Skill 38 ref §9.1) for the
   configured BOOKING_CALENDAR_ID over the next 5-7 business days:
   GET /calendars/{calendarId}/free-slots?startDate={epochMillis}&endDate={epochMillis}
   (dates are epoch MILLISECONDS).

3. **Offer 2-3 concrete slots.** Pick 2-3 of the returned free slots that fit the customer's stated
   preference (morning/afternoon, this week/next). Offer them in plain language
   ("I've got Tue 10:00am, Wed 2:00pm, or Thu 4:30pm — which works?"). Never dump the whole list.

4. **Book the chosen slot.** When the customer picks one, book it (ref §9.2):
   POST /calendars/events/appointments with REQUIRED { calendarId, locationId, contactId, startTime }.
   endTime is OPTIONAL (GHL derives it). Capture the returned appointment `id` (= eventId) for any
   later reschedule/cancel.

5. **Confirm.** Reply confirming the date/time in the customer's words, and what happens next
   (reminder, location/link). Reply on the SAME channel the message came in on (use the channel from
   the hook payload + the §7 verified send type).

6. **Log it.** Append the booking (slot, eventId) to the contact's conversation log per the
   conversation-log protocol.

## Reschedule / cancel
- Reschedule: PUT /calendars/events/appointments/{eventId} (ref §9.3).
- Cancel: DELETE /calendars/events/{eventId} (ref §9.4).

## Guardrails
- Never offer a slot that wasn't returned by free-slots.
- If no slots are available in the window, widen the window once, then offer to take a callback.
- Never expose internal IDs or tokens to the customer.
```

> **Day-one wiring requirement:** the SMS automation built via the Build-with-AI prompt (§3) posts to
> `/hooks/ghl-inbound`; that hook path's `hooks.mappings` entry routes to the agent running this
> appointment-booking playbook. Verify the round-trip (§4) before declaring the base install done.

---

## 11. Cron registration on current OpenClaw — use the CLI, not JSON

The playbook's `cron.jobs` JSON format does **NOT** validate on openclaw 2026.5.27 (fails with
`cron: Invalid input`). Register crons via the **CLI** instead:

```bash
openclaw cron add --name <NAME> --cron "<CRON_EXPR>" --agent main \
  --message "<MESSAGE>" --light-context --best-effort-deliver
```

Example (weekly calendar sync, see `scripts/skill38-calendar-sync.sh`):
```bash
openclaw cron add --name skill38-calendar-sync --cron "0 9 * * 0" --agent main \
  --light-context --best-effort-deliver \
  --message "run /data/clawd/scripts/skill38-calendar-sync.sh /data/.openclaw/workspace/TOOLS.md and report calendar count"
```

---

## 12. `deliver: false` for API-reply hooks (do NOT use `deliver: true`)

For any hook that replies via an **external API** (GHL Conversations), the `hooks.mappings` entry MUST
set **`"deliver": false`**.

**Why `deliver: true` breaks replies:** with `deliver: true`, the gateway tries to publish the agent's
final text to its **default channel** (typically Telegram). A hook session has **no `chatId`**, so the
run errors with *"Delivering to Telegram requires target <chatId>"* and the customer reply never sends.

Use `"deliver": true` **only** if you actually want the agent's final text echoed back to its own
bound channel (e.g. an internal admin echo) — never for GHL API-reply hooks.

---

## 13. Quick index of the binding rules

1. Keep the **four tokens** disambiguated everywhere (§1).
2. **Never recreate the tunnel** — one tunnel/hostname/HOOKS_TOKEN per client; new automations = new
   hook paths (§2).
3. **Build-with-AI prompt is the primary** method; hand-build is the fallback (§3); always run the
   **verification checklist** even on success (§4).
4. **GHL Raw Body is FLAT, data-only, no nesting, NO messageTemplate** — one value per key (§5, §14).
5. **Store Reusable Tunnel Values** in AGENTS.md + TOOLS.md + the client's Notion doc, every time,
   kept updated (§6).
6. Use only the **verified channel→type enum** (§7).
7. Outbound replies use **`GHL_PRIVATE_INTEGRATION_TOKEN`** + Version **`2021-04-15`** (§8); calendar
   dates are **epoch milliseconds** (§9).
8. The base SMS install also creates the **first playbook (appointment booking)** and wires the hook
   path to it (§10).
9. Register crons via the **CLI**, not `cron.jobs` JSON (§11).
10. API-reply hooks use **`deliver: false`** (§12).
11. **READ §14 FIRST** — the corrected GHL hook structure (flat body, server-only messageTemplate)
    supersedes any older nested-body or in-body-messageTemplate example anywhere in this skill (§14).

---

## 14. CORRECTED GHL HOOK STRUCTURE (2026-05-29) — SUPERSEDES ALL OLDER EXAMPLES

> **Verified LIVE on Corey / Explore Growth, 2026-05-29, OpenClaw 2026.5.27.** This section supersedes
> ANY older nested-body example or in-body `messageTemplate` anywhere in Skill 38. If another file in
> this skill still shows a nested `contact:{…}` / `customer_message:{…}` body, THIS section wins.

### CARDINAL RULE — TWO separate objects in TWO systems; never put one inside the other

- **(A) GHL Custom Webhook RAW BODY** = DATA ONLY, **FLAT**, no nesting, and it must **NOT** contain a
  `messageTemplate`.
- **(B) OpenClaw `hooks.mappings` entry** (in `openclaw.json`) = config + the `messageTemplate`. The
  `messageTemplate` is **SERVER-SIDE ONLY**.

### 14.1 — GHL RAW BODY MUST BE FLAT (no nested objects)

A nested `contact:{…}` / `customer_message:{…}` body makes **EVERY** field resolve **EMPTY** at the hook
(proven: even a hardcoded `"channel":"sms"` arrived blank when nested). Canonical correct FLAT body:

```json
{
  "channel": "sms",
  "contact_id": "{{contact.id}}",
  "first_name": "{{contact.first_name}}",
  "last_name": "{{contact.last_name}}",
  "email": "{{contact.email}}",
  "phone": "{{contact.phone}}",
  "subject": "{{message.subject}}",
  "message_body": "{{message.body}}",
  "match": "ghl-sales",
  "session_key": "hook:ghl:sms:{{contact.id}}",
  "agent_id": "sales",
  "location_id": "{{location.id}}",
  "location_name": "{{location.name}}"
}
```

### 14.2 — NEVER put a `messageTemplate` in the GHL body

GHL would try to expand the `{{contact_id}}` / `{{message_body}}` placeholders inside it as ITS OWN merge
fields, fail (they are not valid GHL field names), mangle them to `##{}##` and drop the closing quote →
GHL error **"Error while parsing the object to JSON"** → the webhook is **Skipped**. The `messageTemplate`
lives **ONLY** on the server mapping.

### 14.3 — The server mapping REQUIRES a `messageTemplate`

With none, the hook returns `{"ok":false,"error":"hook mapping requires message"}`.

### 14.4 — The server `messageTemplate` MUST include the reply-via-GHL-API instruction

Otherwise the agent drafts a reply but never sends it (zero GHL API calls → the customer gets nothing).
Canonical correct mapping (an `openclaw.json` `hooks.mappings` entry):

```json
{
  "id": "ghl-sales",
  "match": { "path": "ghl-sales" },
  "action": "agent",
  "agentId": "sales",
  "model": "ollama/deepseek-v4-flash:cloud",
  "wakeMode": "now",
  "name": "GHL Sales Inbound",
  "sessionKey": "{{session_key}}",
  "messageTemplate": "Contact {{contact_id}}: {{message_body}} -- You are the Sales agent. Reply to contact {{contact_id}} via the GHL Conversations API per TOOLS.md (check conversation-workflows for the matching playbook).",
  "deliver": false,
  "timeoutSeconds": 300
}
```

Note the `messageTemplate` references the **FLAT body key names** (`{{contact_id}}`, `{{message_body}}`),
and `sessionKey: "{{session_key}}"` pulls the flat `session_key` the body sends.

### 14.5 — `deliver` MUST be `false`

`deliver: true` makes OpenClaw ALSO try to push the reply to a channel, conflicting with the agent's own
GHL-API reply. (See §12 for the full rationale.)

### 14.6 — There is NO GHL merge tag for channel/message-type

Hardcode `"channel":"sms"` in the body (one workflow per channel). For multi-channel, branch on the
Customer-Replied trigger's Reply-Channel filter and hardcode `channel` per branch.

### 14.7 — Body VALUES use GHL's real merge tokens; insert via the Custom Values picker

Body VALUES use GHL's real merge tokens (`{{contact.id}}`, `{{contact.first_name}}`,
`{{contact.last_name}}`, `{{contact.email}}`, `{{contact.phone}}`, `{{message.body}}`,
`{{message.subject}}`, `{{location.id}}`, `{{location.name}}`) and **MUST be inserted via GHL's Custom
Values picker** (typed-as-text tokens send empty). The body KEY NAMES (`contact_id`, `message_body`, etc.)
are what OpenClaw reads/maps.

### 14.8 — Body-supplied / templated `sessionKey` requires two `hooks` flags

A body-supplied or templated `sessionKey` requires `hooks.allowRequestSessionKey=true` **AND**
`hooks.allowedSessionKeyPrefixes` (e.g. `["hook:"]`). Without any `sessionKey`, all contacts collapse into
one shared `hook:ghl:default` session (their conversations merge).

### 14.9 — `agentId` is NOT templatable in a mapping

A `{{…}}` `agentId` silently falls back to the **default** agent. To push the target agent from the
webhook, POST to `/hooks/agent` (it reads top-level body fields `agentId`, `sessionKey`, `message`,
`name`, `channel`, `to`, `model`, `thinking` directly). Otherwise use **one hook PATH per agent** with
`agentId` hardcoded.

### 14.10 — `fallbacks` is NOT a valid `hooks.mappings` key

The schema is `.strict()` and rejects it. `fallbacks` belongs only on a model-routing config.

### 14.11 — `GHL_LOCATION_ID` (env) is the credential, NOT the body `location_*` fields

`GHL_LOCATION_ID` (env) is the REQUIRED GHL API credential the agent uses to send the reply. It is NOT the
`location_id` / `location_name` body merge fields. Keep the env credential; the `location_*` body fields
are optional data only.

### 14.12 — Valid `hooks.mappings` keys (`.strict()` schema, 2026.5.27)

`id`, `match`, `action`, `agentId`, `model`, `wakeMode`, `name`, `sessionKey`, `messageTemplate`,
`textTemplate`, `deliver`, `allowUnsafeExternalContent`, `channel`, `to`, `thinking`, `timeoutSeconds`,
`transform`. (Anything else — e.g. `fallbacks` — is rejected.)
