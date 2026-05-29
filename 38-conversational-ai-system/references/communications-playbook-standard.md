<!-- OPERATOR HEADER -->
<!-- Skill 38 reference/protocol doc: Communications Playbook Standard. -->
<!-- This is the FULL standard. AGENTS.md / TOOLS.md get only a 1-2 line pointer to this file -->
<!-- (what the playbook is + its file path) — NEVER the playbook body inline (avoid core-md bloat). -->
<!-- Companion docs: conversation-workflows-protocol.md (THE TRINITY + builder), -->
<!-- workflow-ai-instructions-standard.md (the Build-with-AI prompt standard), -->
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

## 1. MUST-APPEAR CHECKLIST (every communications playbook, no exceptions)

A communications playbook is NOT complete until EVERY item below is present. The
Build-with-AI verification checklist and QC pass both check for these.

- [ ] **slug / id** — kebab-case unique id (e.g. `pricing-inquiry`). Matches the filename
      (`<slug>.md`) and the registry row.
- [ ] **owner agent id** — the OpenClaw agent id that runs this playbook (e.g. `sales`,
      `support`, `main`). This is the `agent_id` the Trinity's webhook body routes to.
- [ ] **channel** — the channel(s) this playbook applies to (sms / email / facebook / instagram /
      whatsapp / live_chat / gmb / conversations). Must match the workflow-AI prompt's `channel`.
- [ ] **trigger phrases / intent** — the keywords/phrases AND the semantic intent that activate
      this playbook (so the agent can recognize it from message content).
- [ ] **goal** — one sentence: what success looks like (booking / sale / info delivered / escalation).
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
- [ ] **edge cases** — at minimum: customer frustration (→ sentiment-monitoring-protocol.md), refund
      request, legal/compliance escalation (→ compliance-keyword-detection-protocol.md), and
      low-confidence (→ confidence-threshold-protocol.md).
- [ ] **on-success / tagging** — the action(s) that fire when the scenario succeeds (book, invoice,
      escalate, send doc, AND the GHL tag(s) to apply). If a tag is needed, it must already have been
      created via the GHL skill (see workflow-ai-instructions-standard.md "create the tag first").
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
**Channel:** <sms | email | facebook | instagram | whatsapp | live_chat | gmb | conversations>
**Created:** <ISO date>
**Trigger phrases / intent:** <keywords + semantic description>
**Goal:** <one sentence>
**Customer profile:** <who this is for>
**Desired customer outcome:** <what good looks like for THEM>

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

## Edge cases
### Frustration → escalate via sentiment-monitoring-protocol.md
### Refund request → <policy + escalation>
### Legal / compliance → compliance-keyword-detection-protocol.md (hard gate)
### Low confidence → confidence-threshold-protocol.md

## On success / tagging
- <action(s)>; apply tag(s): <tag(s) — created beforehand via the GHL skill>

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

- [ ] **Authorization Header / Bearer Token** — a literal `Authorization: Bearer <token>` block, with the
      ACTUAL `hooks.token` (read from `HOOKS_TOKEN` / `OPENCLAW_HOOKS_TOKEN` / `hooks.token` in
      `openclaw.json` at generation time) inside a fenced code block. If the token cannot be resolved, the
      generator emits a clearly-marked PLACEHOLDER and warns — it never silently omits the section.
- [ ] **GHL Custom Webhook — Raw Body** — the canonical FLAT 23-key body as a ` ```json ` fenced code block
      (copyable), plus the **Method (POST)**, the **hook URL** (`https://<host>/hooks/<id>`), and
      **Content-Type** (`application/json`), each as a copyable code block. The body stays placeholder-free
      in `messageTemplate` and is never nested or stripped below 23 keys.

A live client (Teresa) was stranded by a reference sheet that had NEITHER the bearer token NOR a copyable
Raw Body JSON — there was nothing to paste into GHL's Build-with-AI. This is now **machine-enforced by
`scripts/qc-reference-sheet.sh`** (wired into `scripts/11-run-qc-checklist.sh` AND CI
`.github/workflows/qc-static.yml`): the gate drives the generator in an offline sandbox and FAILS the
build if the rendered sheet lacks the word `Bearer`, a ` ```json ` fenced code block, or the hook URL. It
is no longer optional prose.
