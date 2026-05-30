# GHL Convert-and-Flow API — Quick Reference (canonical request shapes)

> **What this is.** A concise, verified quick-reference of the GHL (GoHighLevel /
> LeadConnector) Convert-and-Flow API request shapes the conversational-AI agent needs at
> RUNTIME — exact method, URL, the 3 headers, the JSON body shape (placeholder fields), and
> the required PIT scope for each operation. This block is injected into the CLIENT agent's
> **TOOLS.md** by `scripts/24-update-tools-md.sh` so the agent has the canonical shapes in its
> core context and answers fast — no digging through the dense per-module references at runtime.
>
> **Source of truth (verified, do not invent):** `references/GHL-INBOUND-AND-PLAYBOOKS.md` §7-§9
> (live-probed against the GHL API) and Skill 29's `references/{conversations,calendars,payments}.md`.
> Deeper per-endpoint detail lives there; this file is the fast canonical subset only.

**Base URL:** `https://services.leadconnectorhq.com`

**Headers — all THREE required on every call:**
```
Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN
Version: 2021-04-15
Content-Type: application/json
```
- Credential var: `GHL_PRIVATE_INTEGRATION_TOKEN` (the PIT, token #4). Never expose it to a customer.
- `Version` is exactly `2021-04-15` on every Convert-and-Flow call (messaging, calendars, invoices).

**Required PIT scopes (summary):** `conversations/message.write`, `calendars.readonly`,
`calendars.write`, `calendars/events.readonly`, `calendars/events.write`, `invoices.write`.

---

## MESSAGING — ONE endpoint, switch on `type`

**Every channel sends through the SAME endpoint** — `POST /conversations/messages` — and GHL
switches behavior on the `type` field. Required scope for all of them: **`conversations/message.write`**.

> **All-in-One Chat (unified inbox):** GHL's unified inbox is **NOT** a separate send type. EVERY
> channel below flows through this one endpoint; pick the `type` that **matches the inbound channel**
> the customer messaged on (from the hook payload), and reply on that same channel.

| Channel | `type` value | Body shape (besides `contactId`) |
|---|---|---|
| SMS | `SMS` | `"message"` |
| Email | `Email` | `"subject"`, `"html"` |
| Facebook Messenger | `FB` | `"message"` |
| Instagram DM | `IG` | `"message"` |
| WhatsApp | `WhatsApp` | `"message"` |
| Live Chat / website Chat Widget | `Live_Chat` | `"message"` |

> **Chat Widget = Live Chat.** The website chat widget routes through Live Chat — use
> `type: "Live_Chat"`. There is no distinct widget send type in the verified enum.
>
> **Rejected `type` values (do NOT use — the API 4xx's, verified live):** `GMB`, `TikTok`, `Call`,
> and long-forms `Instagram` / `Facebook` / `Webchat`. To reply to a Google Business (GMB) or TikTok
> inbound, send via a **GHL workflow automation**, not this API.

```bash
# SMS / FB / IG / WhatsApp / Live_Chat  (same shape, swap the type)
POST https://services.leadconnectorhq.com/conversations/messages
# scope: conversations/message.write
{"type":"SMS","contactId":"<CONTACT_ID>","message":"<reply text>"}
{"type":"FB","contactId":"<CONTACT_ID>","message":"<reply text>"}
{"type":"IG","contactId":"<CONTACT_ID>","message":"<reply text>"}
{"type":"WhatsApp","contactId":"<CONTACT_ID>","message":"<reply text>"}
{"type":"Live_Chat","contactId":"<CONTACT_ID>","message":"<reply text>"}

# Email  (subject + html instead of message)
POST https://services.leadconnectorhq.com/conversations/messages
# scope: conversations/message.write
{"type":"Email","contactId":"<CONTACT_ID>","subject":"<subject>","html":"<html body>"}
```

---

## CALENDARS

> Calendar date params are **epoch MILLISECONDS** (not seconds, not ISO).

| Operation | Method + URL | Scope | Notes |
|---|---|---|---|
| List calendars | `GET /calendars/?locationId=<LOCATION_ID>` | `calendars.readonly` | query: `locationId` (required) |
| Get calendar | `GET /calendars/<calendarId>` | `calendars.readonly` | |
| Create calendar | `POST /calendars/` | `calendars.write` | body per the deep ref |
| Free slots | `GET /calendars/<calendarId>/free-slots?startDate=<epochMillis>&endDate=<epochMillis>` | `calendars.readonly` | query: `startDate`, `endDate` (epoch ms) |

```bash
GET  https://services.leadconnectorhq.com/calendars/?locationId=<LOCATION_ID>
GET  https://services.leadconnectorhq.com/calendars/<calendarId>
POST https://services.leadconnectorhq.com/calendars/                      # body per deep ref
GET  https://services.leadconnectorhq.com/calendars/<calendarId>/free-slots?startDate=<epochMillis>&endDate=<epochMillis>
```

---

## APPOINTMENTS

| Operation | Method + URL | Scope | Body |
|---|---|---|---|
| Book appointment | `POST /calendars/events/appointments` | `calendars/events.write` | REQUIRED: `calendarId`, `locationId`, `contactId`, `startTime`; OPTIONAL: `endTime` (GHL derives it) |
| Reschedule | `PUT /calendars/events/appointments/<eventId>` | `calendars/events.write` | `{"startTime":"…","endTime":"…"}` |
| Cancel | `DELETE /calendars/events/<eventId>` | `calendars/events.write` | none |

> The Book response returns the appointment **`id`** — that `id` **IS the `eventId`** for
> reschedule/cancel. (Cancel is a `DELETE` on `/calendars/events/<eventId>`, not an appointment-status PUT.)

```bash
POST   https://services.leadconnectorhq.com/calendars/events/appointments
# scope: calendars/events.write
{"calendarId":"<CAL_ID>","locationId":"<LOC_ID>","contactId":"<CONTACT_ID>","startTime":"<slot start>"}

PUT    https://services.leadconnectorhq.com/calendars/events/appointments/<eventId>     # reschedule
{"startTime":"<new start>","endTime":"<new end>"}

DELETE https://services.leadconnectorhq.com/calendars/events/<eventId>                  # cancel
```

---

## INVOICES

Create the invoice first, then SEND it by id. Both require **`invoices.write`**.

| Operation | Method + URL | Scope | Body |
|---|---|---|---|
| Create invoice | `POST /invoices/` | `invoices.write` | invoice body per the deep ref (returns the invoice `id`) |
| Send invoice | `POST /invoices/<invoiceId>/send` | `invoices.write` | `{}` (id in the path) |

```bash
POST https://services.leadconnectorhq.com/invoices/                 # create -> returns invoice id
# scope: invoices.write
{ <invoice body per deep ref> }

POST https://services.leadconnectorhq.com/invoices/<invoiceId>/send # send by id
# scope: invoices.write
{}
```

---

> **Deeper detail:** for full body field lists, query params, and edge cases, see
> `references/GHL-INBOUND-AND-PLAYBOOKS.md` (§7 verified send-type enum, §8 messaging recipe,
> §9 calendar recipe) and Skill 29 `references/{conversations,calendars,payments}.md`. This
> quick-reference is the canonical fast subset — keep it concise; do not inline the whole API here.
