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
- [ ] **GHL reply mechanism** — the playbook reply is sent **via the GHL Conversations API per
      TOOLS.md** (NOT direct to a carrier, NOT a raw curl). State this explicitly. See
      `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14 for the reply path; the webhook body's
      `messageTemplate` says "reply to this contact via the GHL Conversations API per TOOLS.md".
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

## 4. STORAGE ORDER in the CLIENT's account (fallback chain)

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
required REGARDLESS of which client-account destination is used.

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
