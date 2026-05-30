<!-- OPERATOR HEADER -->
<!-- Skill 38 reference/protocol doc: Communications Playbook Standard. -->
<!-- This is the FULL standard. AGENTS.md / TOOLS.md / SKILL.md get only a 1-2 line pointer to this file -->
<!-- (what the playbook is + its file path) — NEVER the playbook body inline (avoid core-md bloat). -->
<!-- §0 below is the BINDING "EVERY COMMUNICATION PLAYBOOK MUST INCLUDE ALL OF THE FOLLOWING" checklist, -->
<!-- machine-enforced by scripts/qc-communications-playbook-standard.sh (wired into -->
<!-- scripts/11-run-qc-checklist.sh + .github/workflows/qc-static.yml). Mirrors workflow-ai-instructions-standard.md §0. -->
<!-- Companion docs: conversation-workflows-protocol.md (THE TRINITY + builder), -->
<!-- workflow-ai-instructions-standard.md (the Build-with-AI prompt standard), -->
<!-- ghl-raw-body-json-standard.md (the FLAT 23-key body standard), -->
<!-- references/GHL-INBOUND-AND-PLAYBOOKS.md §14 (the canonical 23-key body + reply-via-GHL mechanism). -->

# Communications Playbook Standard

A **communications playbook** (a.k.a. conversation playbook / Layer 2 playbook) tells the agent how
to behave inside ONE conversational scenario once an inbound conversation has landed. This document is
the single standard for the FORMAT every playbook follows and the CHECKLIST of items that MUST appear
in every playbook, plus where playbooks are stored and registered.

> **THE TRINITY (read first).** A GHL **workflow/automation**, a **communications playbook**, and a
> **workflow-AI prompt** travel together. If you build a workflow you MUST also have its communications
> playbook AND its workflow-AI prompt. If you create a communications playbook you MUST create the
> matching workflow-AI prompt (and the workflow). One implies the other two. Full rule in
> `conversation-workflows-protocol.md` → "THE TRINITY". Do not ship a playbook alone.

---

## 0. EVERY COMMUNICATION PLAYBOOK MUST INCLUDE ALL OF THE FOLLOWING (BINDING — NON-NEGOTIABLE)

> **STANDARDIZATION CONTRACT.** A communications playbook is NOT free-form. Two different installs of this
> skill must produce structurally identical playbooks — only the substituted values (the channel, the
> persona/voice, the scenario goal, the trigger phrases, the tags) change. No improvising, no reordering,
> no dropping an item. If ANY one of the mandatory inclusions below is missing, the playbook is INVALID and
> the install is not complete. This §0 is what `scripts/qc-communications-playbook-standard.sh`
> machine-enforces (wired into `scripts/11-run-qc-checklist.sh` + `.github/workflows/qc-static.yml`); the
> field-by-field detail is in §1–§8 below.
>
> **Scope of "communication playbook" here.** This standard covers BOTH (a) the per-channel voice/behavior
> doc for the **8 supported channels** — **SMS, Email, Facebook Messenger, Facebook comments, Instagram DM,
> LinkedIn, Live Chat, and the All-in-One / Chat Widget** — and (b) the per-scenario conversation playbook
> that rides on top of that channel voice. Every playbook this skill emits, on any of those channels, MUST
> carry all of the following.

EVERY COMMUNICATION PLAYBOOK MUST INCLUDE ALL OF THE FOLLOWING:

1. **(a) Channel + persona / voice identity.** The exact channel (one of the 8 above) AND the persona/voice
   the agent speaks in on it — the named agent identity + tone/brand voice. The reader must know *who* is
   speaking and *on which channel* from the top of the doc.
2. **(b) Opening behavior + how to greet.** How the agent OPENS the conversation / greets the contact on
   this channel (first-touch vs returning contact), so first contact is consistent — not improvised.
3. **(c) Conversation goal / desired outcome.** One sentence: what success looks like for THIS scenario
   (booking / sale / info delivered / escalation) — the desired customer outcome.
4. **(d) MANDATORY SEND rule.** The reply is **SENT via the GHL Conversations API** (`POST
   conversations/messages`), **mirroring the inbound channel** into the send `type` (SMS→SMS, Email→Email,
   Facebook→FB, Instagram→IG, WhatsApp→WhatsApp, Live Chat→Live_Chat — never a hardcoded SMS), sent **BY
   `contactId`** (`conversationId` is the READ key only, never a send-body field). **Drafting/composing is
   NOT sending** — the agent must make the send call and must NOT end its turn until a `messageId` is
   returned, or the customer gets nothing. Never reply direct-to-carrier or via raw curl.
5. **(e) Conversation-MEMORY protocol.** GHL inbound hook sessions are **single-turn / stateless** — the
   per-contact log `<MASTER_FILES_DIR>/conversational-logs/<contact_id>__<name>.md` is the agent's ONLY
   cross-message memory. The playbook MUST state: **READ that log BEFORE replying** (continue any
   in-progress topic/booking) and **APPEND the inbound + sent reply AFTER sending.**
6. **(f) Escalation / handoff rules + honesty floor.** When and to whom the agent hands off (frustration →
   sentiment-monitoring-protocol.md; legal/compliance → compliance-keyword-detection-protocol.md; low
   confidence → confidence-threshold-protocol.md), AND the **honesty floor** — the agent NEVER fabricates
   price, availability, policy, or outcome; when unsure it says so and escalates/researches, it does NOT
   guess. This is binding.
7. **(g) Quiet-hours + compliance-keyword respect.** The playbook MUST honor **quiet hours**
   (`quiet-hours-protocol.md`) and **compliance keywords** (`compliance-keyword-detection-protocol.md`,
   e.g. STOP / UNSUBSCRIBE on SMS — never reply to those; the channel's send-window rules, e.g. Facebook /
   Instagram's 24-hour window).
8. **(h) ZHC- tag-prefix for any programmatic tags.** Any tag the agent CREATES or APPLIES programmatically
   MUST be prefixed **`ZHC-`** (e.g. `ZHC-pricing-interest`) so machine-created tags are namespaced and
   never collide with the operator's hand-made tags. Tags must be CREATED FIRST via the GHL skill (per
   `workflow-ai-instructions-standard.md` "create the tag first").
9. **(i) Per-channel formatting constraints.** The character/format limits for the channel (SMS: ≤160 chars
   where possible; Email: 2–4 short paragraphs + subject-line matching; FB/IG: 1–3 conversational
   sentences; LinkedIn: professional register; Live Chat / Chat Widget: short, fast, typing-cadence
   replies). The playbook states the constraint that applies to ITS channel.

These nine are the floor. They appear in every playbook this skill emits, for every channel, for every
client. The §1 MUST-APPEAR tick-list and the §2 canonical skeleton below restate and operationalize them.

---

## 1. MUST-APPEAR CHECKLIST (every communications playbook, no exceptions)

A communications playbook is NOT complete until EVERY item below is present. The
Build-with-AI verification checklist and QC pass both check for these.

- [ ] **slug / id** — kebab-case unique id (e.g. `pricing-inquiry`). Matches the filename
      (`<slug>.md`) and the registry row.
- [ ] **owner agent id** — the OpenClaw agent id that runs this playbook (e.g. `sales`,
      `support`, `main`). This is the `agent_id` the Trinity's webhook body routes to.
- [ ] **channel + persona / voice identity (§0.a)** — the channel(s) this playbook applies to (one of the
      8: sms / email / facebook-messenger / facebook-comments / instagram / linkedin / live_chat /
      all-in-one-chat-widget; whatsapp / gmb / conversations also routable). Must match the workflow-AI
      prompt's `channel`. AND the persona/voice the agent speaks in (named agent identity + tone/brand
      voice) — who is speaking, on which channel.
- [ ] **opening behavior / greeting (§0.b)** — how the agent OPENS / greets on this channel (first-touch
      vs returning contact), so first contact is consistent rather than improvised.
- [ ] **trigger phrases / intent** — the keywords/phrases AND the semantic intent that activate
      this playbook (so the agent can recognize it from message content).
- [ ] **goal / desired outcome (§0.c)** — one sentence: what success looks like (booking / sale / info
      delivered / escalation) — the desired customer outcome.
- [ ] **step-by-step flow** — the phases the agent walks through (acknowledge → qualify → gather →
      deliver value → close). Each phase says what to say, what to ask, what to listen for.
- [ ] **GHL reply mechanism (MANDATORY SEND)** — the playbook reply is SENT **via the GHL Conversations
      API per TOOLS.md** (NOT direct to a carrier, NOT a raw curl). Drafting/composing is NOT sending —
      the agent MUST make the send call (POST conversations/messages) and MUST NOT end the turn until a
      messageId/conversationId is returned, or the customer gets nothing. State this explicitly. The
      OpenClaw `hooks.mappings` SERVER-mapping `messageTemplate` carries this send-directive (machine-
      enforced by `scripts/qc-send-directive.sh`). See `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14 for
      the reply path.
- [ ] **conversation MEMORY (READ-before + APPEND-after)** — GHL inbound hook sessions are
      **SINGLE-TURN / stateless** (every inbound = a fresh session, no chat history). The agent's only
      memory of a contact across messages is the per-contact conversation log under
      `<MASTER_FILES_DIR>/conversational-logs/<contact_id>__<name>.md`. The playbook MUST state that on
      every inbound the agent (1) **READS** that log BEFORE replying and continues any in-progress
      topic/booking it finds (don't restart), and (2) **APPENDS** the inbound + its sent reply to the log
      AFTER sending. A reply that ignores or fails to update the log is a failure. The SERVER-mapping
      `messageTemplate` carries these steps (machine-enforced by `scripts/qc-conversation-memory.sh`, and
      the installer is fail-closed if they're absent). See `references/v6.0-source-playbook.md` Step 9
      (conversation log system), `protocols/conversation-log-protocol.md`, and
      `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14.4.
- [ ] **cross-playbook transition rules** — when this playbook should hand off to another playbook
      mid-conversation, and which one (max 3 switches, soft transitions — see Step 9.33 Intelligent
      Playbook Routing). If none, say "none".
- [ ] **edge cases + escalation/handoff (§0.f)** — at minimum: customer frustration (→
      sentiment-monitoring-protocol.md), refund request, legal/compliance escalation (→
      compliance-keyword-detection-protocol.md), and low-confidence (→ confidence-threshold-protocol.md).
      State WHEN and to WHOM the agent hands off.
- [ ] **quiet-hours + compliance-keyword respect (§0.g)** — the playbook honors quiet hours
      (`quiet-hours-protocol.md`) and compliance keywords (`compliance-keyword-detection-protocol.md`) —
      e.g. STOP / UNSUBSCRIBE on SMS (never reply), and the channel's send-window rules (e.g. Facebook /
      Instagram 24-hour window). State the rule that applies to THIS channel.
- [ ] **on-success / tagging — ZHC- prefix (§0.h)** — the action(s) that fire when the scenario succeeds
      (book, invoice, escalate, send doc, AND the GHL tag(s) to apply). Any tag the agent
      CREATES/APPLIES programmatically MUST be **`ZHC-` prefixed** (e.g. `ZHC-pricing-interest`) so
      machine-created tags are namespaced away from the operator's hand-made tags. The tag must already
      have been created via the GHL skill (see workflow-ai-instructions-standard.md "create the tag first").
- [ ] **per-channel formatting constraints (§0.i)** — the character/format limit for THIS channel (SMS
      ≤160 chars where possible; Email 2–4 short paragraphs + match the subject-line format; FB/IG 1–3
      conversational sentences; LinkedIn professional register; Live Chat / Chat Widget short, fast,
      typing-cadence replies).
- [ ] **tone** — the specific tone for THIS scenario, layered on top of the channel communication
      playbook's baseline voice.
- [ ] **honesty floor** — the agent never fabricates prices, availability, policy, or outcomes. When
      it does not know, it says so and escalates or researches — it does NOT guess. This is binding.
- [ ] **linked GHL routing (Trinity back-reference)** — names the matching workflow-AI prompt file and
      verification checklist file (or "uses existing inbound routing — no Layer 1").
- [ ] **human-facing doc created in the client's account (Notion → Google Docs → text), URL recorded**
      (MANDATORY DELIVERABLE) — in ADDITION to the master-files copy (§3), a human-readable copy of this
      playbook MUST be created in the CLIENT's OWN account so they have a shareable/editable reference of
      what was set up. Use the fallback chain in §4, ALWAYS in order: **(a) the client's Notion → (b) if
      no Notion, the client's Google Docs → (c) if neither, a plain-text doc the client can access.** The
      resulting **URL/path MUST be recorded** (on this playbook's registry row AND as a `playbookDocs[]`
      entry in the run manifest). A playbook scaffolded locally but with NO human-facing doc in the
      client's account is INCOMPLETE — the customer is left with no reference. This is **machine-enforced
      by `scripts/qc-playbook-doc.sh`** (wired into `scripts/11-run-qc-checklist.sh` + CI); the installer
      `scripts/09-install-conversation-workflows.sh` performs the create+record automatically and is
      fail-closed at QC if it was skipped.

---

## 2. STANDARD FORMAT (canonical skeleton)

Save the playbook with this structure. (This is the same Layer 2 skeleton used in
`conversation-workflows-protocol.md` Section E — kept identical so a playbook authored either way is
interchangeable.)

```markdown
# Communications Playbook: <Workflow Name>

**Slug/id:** <slug>
**Owner agent id:** <agent_id>
**Channel:** <sms | email | facebook-messenger | facebook-comments | instagram | linkedin | live_chat | all-in-one-chat-widget | whatsapp | gmb | conversations>
**Persona / voice:** <named agent identity + tone/brand voice on THIS channel>   (§0.a)
**Created:** <ISO date>
**Trigger phrases / intent:** <keywords + semantic description>
**Goal:** <one sentence>   (§0.c)
**Customer profile:** <who this is for>
**Desired customer outcome:** <what good looks like for THEM>

## Opening / greeting (§0.b)
- First-touch: <how the agent greets a brand-new contact on this channel>
- Returning contact: <how the agent re-opens, after READING the conversation log>

## When to invoke
- <trigger condition / keyword / semantic intent>

## Step-by-step flow
### Phase 1 — Acknowledge & qualify
### Phase 2 — Gather context
### Phase 3 — Deliver value
### Phase 4 — Close

## GHL reply mechanism
Reply to the contact via the GHL Conversations API per TOOLS.md. Never reply direct-to-carrier
or via raw curl. (The Trinity webhook delivers the inbound; the agent replies on the same channel.)

## Information the agent needs
- <knowledge source(s)>

## Cross-playbook transition rules
- Transition to <other-slug> when <condition>. (Max 3 switches, soft transitions — Step 9.33.)
  If none: "none".

## Edge cases (§0.f)
### Frustration → escalate via sentiment-monitoring-protocol.md
### Refund request → <policy + escalation>
### Legal / compliance → compliance-keyword-detection-protocol.md (hard gate)
### Low confidence → confidence-threshold-protocol.md

## Quiet hours & compliance (§0.g)
- Quiet hours: honor quiet-hours-protocol.md (do not send outside the window).
- Compliance keywords: honor compliance-keyword-detection-protocol.md (e.g. STOP / UNSUBSCRIBE on SMS —
  never reply; respect the channel send-window, e.g. FB/IG 24-hour rule).

## Per-channel formatting (§0.i)
- <the limit for THIS channel — SMS ≤160 chars / Email 2–4 short paragraphs / FB-IG 1–3 sentences /
  LinkedIn professional / Live Chat short & fast>

## On success / tagging (§0.h — ZHC- prefix)
- <action(s)>; apply tag(s): <ZHC-<tag> — `ZHC-` prefixed, created beforehand via the GHL skill>

## Tone
<scenario tone, on top of the channel communication playbook baseline>

## Honesty floor
The agent never fabricates price, availability, policy, or outcome. When unsure, it says so and
escalates or researches — it does NOT guess.

## Linked GHL routing (Trinity)
- Workflow-AI prompt file: <slug>--build-with-ai-prompt.md  (or "n/a — existing inbound routing")
- Verification checklist file: <slug>--verification-checklist.md  (or "n/a")
- GHL workflow built: [yes | no — uses existing inbound routing]
```

---

## 3. STORAGE — OpenClaw master-files (source of truth)

ALWAYS save the playbook file in the OpenClaw **master-files folder**, under the existing
`conversation-workflows/` directory (this repo's "communications playbooks" folder):

```
<MASTER_FILES_DIR>/conversation-workflows/<slug>.md
```

Then REGISTER it in the registry so the agent's runtime routing (AGENTS.md Step 1.8 / Step 1.85)
sees it on every inbound:

```
<MASTER_FILES_DIR>/conversation-workflows/registry.md
```

Add one registry row per playbook (id, name, trigger summary, Layer 1?, OpenClaw playbook file,
GHL prompt file, verification checklist file). The registry — NOT the playbook body — is what reaches
the bootstrap layer.

> **Core-md discipline.** AGENTS.md / TOOLS.md get ONLY a 1-2 line pointer: what the playbook is +
> its file path. The playbook body NEVER goes inline into AGENTS.md / TOOLS.md / MEMORY.md. The
> registry pointer + the AGENTS.md Step 1.85 instruction are the only things at the bootstrap layer.

---

## 4. STORAGE ORDER in the CLIENT's account (fallback chain) — MANDATORY, machine-enforced

> **This is a MANDATORY deliverable for EVERY playbook, not optional prose.** It is gated by
> `scripts/qc-playbook-doc.sh` (wired into `scripts/11-run-qc-checklist.sh` + `.github/workflows/qc-static.yml`):
> a conversation playbook with NO recorded human-facing doc (no Notion URL / Google Doc / text-doc path on
> its registry row or in the run-manifest `playbookDocs[]`) FAILS QC and blocks hand-off. The installer
> `scripts/09-install-conversation-workflows.sh` creates+records it automatically following the chain below;
> if it was skipped, the QC gate fail-closes (exit non-zero) and the install is NOT done.

Separate from the master-files copy (§3, always required), a human-readable copy of each new
communications playbook is delivered into the CLIENT's own account so they can read/edit it later.
Use this fallback chain, ALWAYS in this order:

1. **(a) The client's Notion account first.** If the client has a Notion workspace, create a NEW
   Notion doc/page for this playbook in THEIR workspace (never co-mingle with another client's
   workspace — if they have no Notion yet, do NOT borrow another client's). Per
   conversation-workflows-protocol.md Part 3, the builder creates a NEW Notion doc on YES.
2. **(b) If no Notion → the client's Google Docs.** Create a Google Doc in the client's Drive.
3. **(c) If no Google Docs → a plain text document the client can access later.** A `.md`/`.txt`
   file in a client-accessible location.

Always (a) → (b) → (c). Never skip to (c) if (a) is available. The master-files copy in §3 is
required REGARDLESS of which client-account destination is used. **RECORD the chosen destination's
URL/path** on the playbook's registry row AND as a `playbookDocs[]: <slug> -> <url-or-path>` line in the
run manifest — that recorded state is exactly what `scripts/qc-playbook-doc.sh` checks; an unrecorded
doc is treated as a skipped doc and FAILS QC.

---

## 5. Relationship to channel communication playbooks (Step 8)

Do not confuse the two:

- **Channel communication playbook** (`channel-playbook-template.md`, Step 8) = baseline tone/voice
  for a channel. One per channel. Applies to EVERY reply on that channel.
- **Communications playbook** (this standard) = specific scenario behavior. Many per client. Applies
  only when its trigger fires.

When a communications playbook fires, the agent uses its scenario instructions while still honoring
the channel communication playbook's baseline tone/signature. Both inform every reply, at different
levels of specificity.

---

## 6. CLIENT REFERENCE SHEET — bearer token + copyable GHL Raw Body are MANDATORY (machine-enforced)

The Client Reference Sheet (generated by `scripts/21-generate-client-reference-sheet.sh`, delivered to
the client in Notion or as markdown) is the doc the client opens to wire OpenClaw into GHL. It **MUST
always** contain BOTH of the following as real, copy-paste-ready fenced code blocks — never as prose,
never omitted:

- [ ] **Authorization Header / Bearer Token — TWO separate copy boxes.** A GHL custom header has a **Key
      (name) field** and a **Value field**, so the doc renders the Authorization header as **two separate
      copyable code blocks, never one combined block:**
      - Block 1 = exactly `Authorization` → paste into the Header **KEY (name)** field.
      - Block 2 = exactly `Bearer <token>` → paste into the Header **VALUE** field. The value block holds
        **ONLY** `Bearer ` + the token — it must **NOT** contain the word `Authorization` (i.e. it is
        `Bearer <token>`, never `Authorization: Bearer <token>`).

      Do the same for any other split header (Content-Type → block 1 `Content-Type`, block 2
      `application/json`). The token is the ACTUAL `hooks.token` (read from `HOOKS_TOKEN` /
      `OPENCLAW_HOOKS_TOKEN` / `hooks.token` in `openclaw.json` at generation time). If it cannot be
      resolved, the generator emits a clearly-marked PLACEHOLDER and warns — it never silently omits the
      section. Each value is its own code block. (Machine-enforced by `scripts/qc-reference-sheet.sh`: the
      Bearer-value block must NOT contain "Authorization", and a combined `Authorization: Bearer` block
      FAILS the build.)
- [ ] **GHL Custom Webhook — Raw Body** — the canonical FLAT 23-key body as a ` ```json ` fenced code block
      (copyable), plus the **Method (POST)**, the **hook URL** (`https://<host>/hooks/<id>`), and
      **Content-Type** (`application/json`), each as a copyable code block. The body stays placeholder-free
      in `messageTemplate` and is never nested or stripped below 23 keys.

A live client was once stranded by a reference sheet that had NEITHER the bearer token NOR a copyable
Raw Body JSON — there was nothing to paste into GHL's Build-with-AI. This is now **machine-enforced by
`scripts/qc-reference-sheet.sh`** (wired into `scripts/11-run-qc-checklist.sh` AND CI
`.github/workflows/qc-static.yml`): the gate drives the generator in an offline sandbox and FAILS the
build if the rendered sheet lacks the word `Bearer`, a ` ```json ` fenced code block, or the hook URL. It
is no longer optional prose.

### MANDATORY in every client doc — the manual Custom-Webhook fill step

GHL's **"Build with AI"** only builds the workflow SHAPE (trigger + filters + an EMPTY Custom Webhook
action). It does **NOT** reliably populate the URL, the Authorization/Bearer header, the Content-Type
header, or the Raw Body JSON. So **every client doc** (the Client Reference Sheet, the SMS prompt template,
and the Workflow Verification Checklist) MUST tell the client, prominently:

> **After Build-with-AI runs, you MUST open the Custom Webhook action and MANUALLY enter:** Method = POST;
> the URL; Headers via **Add item →** Key `Authorization` / Value `Bearer <token>` (the value box gets ONLY
> `Bearer ` + the token — no `Authorization:` prefix) and Key `Content-Type` / Value `application/json`
> (each header is a Key field + a Value field, two separate copy boxes); the Raw Body JSON; then **Save +
> Publish**. **Build with AI will not fill these for you. Verify every field is non-empty before
> publishing.**

This manual-fill instruction is **mandatory, not optional** — a doc that omits it strands the client with
an empty webhook that silently drops every inbound message. The Client Reference Sheet leads with the
copy-paste values (URL, bearer token, Raw Body JSON) followed by these manual-fill steps, then the
Workflow-AI prompt; `scripts/qc-reference-sheet.sh` machine-enforces that the generated sheet carries the
manual-fill instructions (greps for "Custom Webhook" + "manually"/"paste" + "Build with AI will not").

---

## 7. "YOUR COMMUNICATION PLAYBOOKS" SECTION in the client doc (MANDATORY, machine-enforced)

Every generated client doc (`scripts/21-generate-client-reference-sheet.sh`) MUST carry a prominent
**Your Communication Playbooks** section, placed **AFTER the Quick Start** and **BEFORE the deep
how-it-works (Reference & explanation)**. It answers the question every client asks on their first test —
*"where are my workflows / communication playbooks?"* — and tells them how to get a NEW one. It is a
callout / bold heading, big enough to stand out. Required content:

- **WHERE they live.** The working copies (what the AI runs) live in the client's OpenClaw master-files
  `conversation-workflows/` folder; the human-facing copies live in the client's **Notion** (and, where
  Notion is not set up, Google Docs → plain text — the §4 fallback chain). State both plainly.
- **A friendly, emoji-rich "Want another communication playbook? Just ask me! 🚀" call-to-action** with a
  concrete example the client can copy word-for-word — e.g. *"Help me build a missed-call follow-up
  playbook"* (and more examples: appointment-reminder 📅, lead-nurture 💬, review-request ✅). The client
  never has to build these by hand.
- **A walkthrough of what the AI will do when they ask:** (1) 💬 **brainstorm it WITH the client** using
  what it already knows about the business — a few smart questions, **NOT a 50-question interrogation/form**;
  (2) 🛠️ **create the communication playbook**; (3) 🗂️ **store it** — working copy saved to
  `conversation-workflows/` and **mirrored to Notion**; (4) 📝 **build the matching Workflow AI prompt
  wired to the client's Convert and Flow (GoHighLevel) account**, with exact paste-where steps; (5) 🤖 the
  AI **can take real actions in Convert and Flow on the client's behalf** — it can **create tags 🏷️,
  update the calendar 📅, create/book appointments 🗓️**, and similar automations. Together this builds
  **all 3 parts** (THE TRINITY): the workflow-AI prompt, the conversation playbook, and the GHL automation.
- **The explicit statement:** *"You have an AI that is connected to your Convert and Flow account and can
  do these things for you — just ask."*

Machine-enforced by `scripts/qc-reference-sheet.sh` (wired into `scripts/11-run-qc-checklist.sh` + CI):
the gate FAILS the build if the generated sheet is missing the **Communication Playbooks** section, the
**"Want another communication playbook? Just ask me!"** call-to-action, the concrete copyable example, the
`conversation-workflows/` + Notion (mirrored) location, the *"help me build a … playbook"* instruction,
the brainstorm / not-a-50-question note, the **all 3 parts** (THE TRINITY) statement, the Workflow-AI
prompt wired to **Convert and Flow**, the Convert-and-Flow abilities (**create tags / update calendar /
book appointments**), or the explicit **"connected to your Convert and Flow account — just ask"**
statement.

---

## 8. HOW A NEW PLAYBOOK GETS CREATED — agent behavior (trigger word + "I Do / You Do" + brainstorm)

The creation FLOW (what the agent does when a client asks to build a playbook or hits the brainstorm
trigger) is defined in full in `conversation-workflows-protocol.md` (Section A.0 / A.1 / A.2 + Part 3).
This section is the standard's pointer to those three agent behaviors so they ship with every playbook
build. Do NOT duplicate the flow — author to the protocol.

- **Personal trigger word (A.0 — FIRST build only).** On the client's FIRST playbook build, the agent
  OFFERS a personal trigger word, explained like a voice assistant — *"like 'Alexa' or 'Hey Siri'"* — a
  word/phrase the client picks (e.g. *"Playbook time!"*) that instantly tells the AI they want to build a
  playbook. The agent offers it, confirms it, and **REMEMBERS it**: store it in the client's **USER.md**
  (`Playbook trigger word: "<word>"`) AND in the `conversation-workflows/registry.md` header
  (`Trigger word: "<word>"`), and add it to the AGENTS.md Step 1.85 / 1.75 trigger set so later builds
  recognize it. On later builds, recognizing the stored word (or any Section A phrase) starts the flow —
  the agent does not re-offer.
- **"I Do / You Do" overview (A.1 — every build start).** When a build starts, the agent presents a short
  8-step "I Do / You Do" map so the client knows the responsibilities + that a good playbook takes about
  **15-30 minutes**: (1) YOU trigger it; (2) I ask a few brainstorm questions (not 50); (3) YOU answer
  (goal, audience, channel, offer, tone); (4) I draft the playbook + flow; (5) YOU review + tweak; (6) I
  finalize + store (`conversation-workflows/` mirrored to Notion) + build the Workflow AI prompt wired to
  your Convert and Flow account; (7) I wire the actions (tags, calendar, appointments); (8) YOU approve and
  we go live.
- **Brainstorm prep (A.2 — the agent's job + "things to think about").** The agent's job is to BRAINSTORM
  WITH the client to land the perfect playbook (collaborator, not a form). It tells the client the things
  to think about — the goal (book a call / recover a sale / get a review / FAQ), who it's for, the
  channel(s), the offer/hook, the tone/brand voice, timing & follow-up cadence, and the "win" action
  (booked / replied / tagged / purchased) — and reassures: *"if you're unsure, that's what I'm here to
  brainstorm."* THEN it asks only the smart-gap questions (Part 3 / Section B), using known business
  context — never a 50-question interrogation.

The CLIENT-FACING explanation of all three (so the client knows the trigger word exists, the I-Do/You-Do
split, and the ~15-30 min) lives in the generated client doc — see §7 above and
`scripts/21-generate-client-reference-sheet.sh` (machine-enforced by `scripts/qc-reference-sheet.sh`).
