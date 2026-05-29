# Skill 38 — Conversational AI System: Changelog

## [1.4.17] - 2026-05-29 - New-playbook CREATION experience: personal trigger word + "I Do / You Do" + brainstorm prep

### Why
Clients knew they *could* ask for a new communication playbook (v1.4.16), but the skill never taught the
agent to make the experience feel guided and personal, and the client doc never explained the experience.
Three pieces were missing: (1) a personal **trigger word** (like "Alexa"/"Hey Siri") so the client has a
fast, memorable way to start a build; (2) an **"I Do / You Do"** overview so the client knows who is
responsible for what and that a good playbook takes **~15-30 minutes** (not 30 seconds); and (3) the
**brainstorm "things to think about"** so the client comes prepared and knows the AI's job is to brainstorm
the perfect playbook WITH them.

### Added — AGENT BEHAVIOR (the playbook-CREATION flow)
- **`protocols/conversation-workflows-protocol.md`** — extended the new-playbook creation flow (Section A +
  Part 3) with three new agent behaviors, NOT a duplicate flow:
  - **A.0 — Offer a personal TRIGGER WORD (FIRST build only, BINDING).** On the client's first playbook
    build, the agent OFFERS a personal trigger word, explained voice-assistant style (*"like 'Alexa' or
    'Hey Siri'"*; e.g. *"Playbook time!"*), asks for it, confirms it, and **REMEMBERS it** — stored in the
    client's **USER.md** (`Playbook trigger word: "<word>"`), in the `conversation-workflows/registry.md`
    header (`Trigger word: "<word>"`), and added to the AGENTS.md Step 1.85/1.75 trigger set. On later
    builds, recognizing the stored word (or any Section A phrase) starts the flow without re-offering.
  - **A.1 — Present the "I Do / You Do" overview (every build start, BINDING).** The agent presents a short
    8-step who-does-what map (YOU trigger → AI brainstorms → YOU answer → AI drafts → YOU review → AI
    finalizes+stores+builds the Workflow AI prompt → AI wires tag/calendar/appointment actions → YOU
    approve, go live) and sets the **~15-30 minute** expectation up front.
  - **A.2 — Brainstorm prep (the agent's job + "things to think about").** The agent states its job is to
    BRAINSTORM the perfect playbook WITH the client, and gives the things to think about — goal / audience
    / channel(s) / offer-hook / tone / timing & cadence / win action — with the reassurance *"if you're
    unsure, that's what I'm here to brainstorm."* Then asks only smart-gap questions, never a 50-question
    form.
- **`references/communications-playbook-standard.md`** — new **§8** pointer mirroring A.0/A.1/A.2 so the
  three behaviors ship with every playbook build (author-to-the-protocol, no duplication).
- **`references/workflow-ai-instructions-standard.md`** — new **§7** pointer mirroring the same flow (the
  Workflow-AI prompt is built during the same creation flow).
- **`INSTRUCTIONS.md`** — extended the "Your Communication Playbooks" BINDING rule to name the new
  client-facing content (🔑 trigger word, 🤝 I-Do/You-Do + ⏱️ ~15-30 min, 🧠 brainstorm things-to-think-
  about) and to point at the matching agent behavior in the protocol.

### Added — CLIENT DOC (the client-facing explanation)
- **`scripts/21-generate-client-reference-sheet.sh`** — extended the **💬 Your Communication Playbooks**
  section (still AFTER 🚀 Quick Start, BEFORE Reference & explanation; FLAT 23-key body + Quick-Start-first
  ordering unchanged) with three emoji-rich blocks: **🔑 Your personal trigger word** (voice-assistant
  style, with a copyable *"Playbook time!"* example and the "your AI remembers it" note); **🤝 How we build
  it together — the "I Do / You Do" process** (the 8-step split + the ⏱️ ~15-30 minute expectation); and
  **🧠 Things to think about before we brainstorm** (the goal/audience/channel/offer/tone/timing/win-action
  list + the "if you're unsure, that's what I'm here to brainstorm" reassurance).

### QC
- **`scripts/qc-reference-sheet.sh`** — now ENFORCES the generated client doc carries the new content, and
  FAILs the build if missing: the **"trigger word"** concept explained voice-assistant style (**Alexa /
  Hey Siri**); the **"I Do / You Do"** process + the **~15-30 minute** time expectation; and the brainstorm
  **"things to think about"** list + the **"here to brainstorm"** reassurance. Negative-tested: stripping
  any of the three from a generated sheet makes the gate exit non-zero. Wired into
  `scripts/11-run-qc-checklist.sh` + CI `.github/workflows/qc-static.yml` (unchanged wiring — same gate).

### Notes
- Additive only; no schema/config changes. THE TRINITY, the 23-key body, the send-directive, the
  conversation-memory, the per-playbook doc, the Telegram doc-delivery, and the Authorization two-block
  rule are all unchanged.

## [1.4.16] - 2026-05-29 - Authorization two-block fix + enriched "Your Communication Playbooks" (just-ask CTA + Convert-and-Flow abilities)

### Root cause this prevents
- **(A) The Authorization VALUE box still carried the "Authorization:" prefix.** The Reference &
  explanation body of the client doc (from `templates/client-reference-sheet-template.md`) emitted the
  Authorization header as a SINGLE combined code block `Authorization: Bearer <token>` (and a single
  combined `Content-Type: application/json`). A GHL custom header has a **Key field** and a **Value
  field** — two separate copy boxes. The Quick Start (in `21-generate-client-reference-sheet.sh`) already
  split them, but the template body did not, so the doc still showed a combined block the client had to
  hand-edit. (The combined-block QC check only fired on real ```` ``` ```` fences; the template used
  pseudo-fence `[code block, copy button]` markers, so the bug slipped through.)
- **(B) Clients did not know the AI builds new playbooks FOR them.** The "Your Communication Playbooks"
  section said where playbooks live and "tell your AI to build one," but did not teach the client that
  their AI is connected to Convert and Flow and can take real actions (tags, calendar, appointments), nor
  walk them through what the AI does end-to-end.

### Changed
- **`templates/client-reference-sheet-template.md`** — the Authorization header is now **TWO separate copy
  blocks**: block 1 = exactly `Authorization` (paste into the Header KEY field), block 2 = exactly
  `Bearer <HOOKS_TOKEN>` (paste into the Header VALUE field — **the value box no longer carries the
  `Authorization:` prefix**). Content-Type split the same way (block 1 `Content-Type`, block 2
  `application/json`). The click-by-click step now tells the reader exactly which field each block goes
  into (Key field vs Value field, never one combined box).
- **`scripts/21-generate-client-reference-sheet.sh`** — ENRICHED the **💬 Your Communication Playbooks**
  section (still AFTER the 🚀 Quick Start, BEFORE the Reference & explanation; FLAT 23-key body and
  Quick-Start-first ordering unchanged). It now carries: a friendly emoji-rich **"Want another
  communication playbook? Just ask me! 🚀"** CTA with a concrete copyable example (*"Help me build a
  missed-call follow-up playbook"*, plus appointment-reminder/lead-nurture/review-request examples); a
  walkthrough of what the AI does — (1) 💬 brainstorm WITH you (not a 50-question form), (2) 🛠️ create
  the playbook, (3) 🗂️ store it in `conversation-workflows/` **mirrored to Notion**, (4) 📝 build the
  matching **Workflow AI prompt wired to YOUR Convert and Flow account**, (5) 🤖 take real actions in
  Convert and Flow on your behalf — **create tags 🏷️, update your calendar 📅, create/book appointments
  🗓️**; and the explicit line **"You have an AI that is connected to your Convert and Flow account and
  can do these things for you — just ask."**
- **`scripts/qc-reference-sheet.sh`** — now ENFORCES: (a) the **Bearer-value block must NOT contain the
  word "Authorization"** (a new check, in addition to the existing combined-`Authorization: Bearer` and
  separate-key/value-block checks); (b) the enriched playbook section — the **"Want another communication
  playbook? Just ask me!"** CTA, the concrete copyable example, the `conversation-workflows/` + Notion
  (mirrored) location, the **brainstorm / not-a-50-question** note, the **Workflow AI prompt** wired to
  **Convert and Flow**, the Convert-and-Flow abilities (**create tags / update calendar / book
  appointments**), and the explicit **"connected to your Convert and Flow account — just ask"** statement.
  Negative-tested (a doc missing any of these FAILs; a combined or prefixed Authorization value FAILs).
- **`references/communications-playbook-standard.md`** + **`references/workflow-ai-instructions-standard.md`**
  — mirrored both changes into the standards that define this content: the Authorization **two-block** rule
  (block 1 `Authorization` → Key field; block 2 `Bearer <token>` → Value field, no `Authorization:`
  prefix; Content-Type split the same way) and the enriched "Your Communication Playbooks" section (just-ask
  CTA + concrete example + brainstorm-not-50-questions + store-and-mirror + Workflow-AI-prompt-wired-to-
  Convert-and-Flow + the create-tags/calendar/appointments abilities + the explicit connected statement).

### Version
- `skill-version.txt` 1.4.15 → **1.4.16**; this CHANGELOG entry; `SKILL.md` SELF-COUNTS stamp →
  v1.4.16 + the `qc-reference-sheet.sh` description updated. **No script/linter was added or removed**
  (scripts/=37, protocols/=32, references/=15, journey templates=8 all unchanged), and **none of the 8
  repo-tracked version locations changed**, so the repo version stays v10.16.9 and `bump-version.sh` is
  intentionally NOT run (matching the v1.4.15 / v1.4.14 / v1.4.13 precedent).

### Constraints honored
- 23-key FLAT body unchanged (`qc-23-key-bodies.sh` still green); Quick-Start-first ordering and the FLAT
  23-key body in the generated doc are intact; no nesting; no `\n` in JSON; QC stays BASH (no `.py` with
  `claude-`/`anthropic`). All Skill 38 static gates green locally.

## [1.4.15] - 2026-05-29 - Mandatory Telegram doc-delivery + Communication Playbooks location section + readiness gates

### Root cause this prevents
- **(A) The client doc kept not getting sent.** The operator has said it repeatedly — "every client gets
  their link via Telegram, no matter what" — yet the install kept finishing without the client ever being
  SENT their Quick-Start / Notion doc LINK over Telegram. It was prose, not an enforced gate, so it got
  skipped. (And finding the chat from `sessions.json` keys alone misses paired chats — the Teresa lesson.)
- **(B) Clients ask "where are my workflows?" on their first test.** The generated doc had no prominent
  answer to where their communication playbooks live, or how to get a new one.
- **(C) "Complete" was declared before the backend could receive.** No single gate asserted hooks.mappings
  live + deliver:false + a working model + healthz 200 before testing/hand-off.

### Added
- **`scripts/22-notify-client-doc.sh`** (NEW) — MANDATORY, GATED Telegram doc-delivery. Finds the client's
  Telegram chat id by **grepping the transcripts** `agents/*/sessions/*.jsonl` for every id form
  (`"chat":{"id"`, `telegram:direct:`, `"chatId"`, `"from":{"id"`), drops the operator id, takes the
  **most-frequent** remaining id (NOT sessions.json keys only). Sends the doc LINK via
  `openclaw message send --channel telegram` (gateway only, never `api.telegram.org`). Records
  `clientDocDelivered=true` in the run manifest on success; on no-chat / send-failure it **FLAGS LOUDLY**
  (stderr) + records `clientDocDelivered=false` and **exits non-zero** — the install is INCOMPLETE, never a
  silent skip.
- **`scripts/qc-notify-client-doc.sh`** (NEW) — machine-enforces the above is present, transcript-grep-based,
  gated, gateway-sending, and WIRED into `scripts/11-run-qc-checklist.sh` + INSTRUCTIONS.md. Wired into CI
  (with fixture smoke tests: a client id must win the transcript scan; an operator-only transcript must
  exit 1 and record `clientDocDelivered=false`).
- **`scripts/qc-backend-ready.sh`** (NEW) — concise "backend ready to RECEIVE" completion gate:
  hooks.mappings live + `deliver:false` + a working `model` + gateway `healthz` 200. Live check; exits 3
  (SKIP) when no install is present (so CI treats it as a skip, not a failure). Wired into Step 11 QC + CI.

### Changed
- **`scripts/21-generate-client-reference-sheet.sh`** — the generated client doc now carries a prominent
  **💬 Your Communication Playbooks** section, placed AFTER the 🚀 Quick Start and BEFORE the
  Reference & explanation. It says WHERE the playbooks live (the client's master-files
  `conversation-workflows/` folder + the human-facing copies in Notion → Google Docs → text) and, in BIG
  BOLD, **"Want a NEW communications playbook? Start here:"** — just tell your AI *"help me build a [purpose]
  playbook"* and it brainstorms with you and builds all 3 parts (THE TRINITY: workflow-AI prompt +
  conversation playbook + GHL automation), with what-happens-next.
- **`scripts/qc-reference-sheet.sh`** — extended to FAIL the build if the generated sheet is missing the
  **Your Communication Playbooks** section, the **"Want a NEW communications playbook"** call-to-action, the
  `conversation-workflows/` + Notion location, the *"help me build a … playbook"* instruction, or the
  all-3-parts (Trinity) statement. (Still BASH; offline Layer-3 sandbox.)
- **`scripts/11-run-qc-checklist.sh`** — runs the two new gates (`qc-notify-client-doc.sh` +
  `qc-backend-ready.sh`, the latter SKIPs on exit 3).
- **`INSTRUCTIONS.md`** — added Step 6.5 (mandatory gated Telegram doc-delivery) + three binding Hard rules
  (Telegram delivery; doc-exists-AND-backend-ready completion gates before testing; the Your Communication
  Playbooks section). Checkpoint D now requires `clientDocDelivered=true`.
- **`references/v6.0-source-playbook.md`** — new Step 6.5 (the transcript-grep Telegram delivery gate);
  Checkpoint D + Phase 7 deliverables now require the Telegram delivery, the Your Communication Playbooks
  section, and the backend-ready gate.
- **`references/communications-playbook-standard.md`** + **`references/workflow-ai-instructions-standard.md`**
  — added the "Your Communication Playbooks" section to the standard so every client doc carries it.
- **`.github/workflows/qc-static.yml`** — two new CI steps (Telegram doc-delivery gate + fixtures; backend-
  ready no-config SKIP assertion). All new gates are BASH (no `.py`), respecting the claude-/anthropic ban.
- **`SKILL.md` / `INSTALL.md`** — self-counts re-verified: scripts/ 34 → **37** (added the delivery step +
  two QC gates); protocols/=32, references/=15, journey templates=8 unchanged.

### Constraints honored
- 23-key FLAT body (the generator's canonical body is unchanged; `qc-23-key-bodies.sh` still green), no
  nesting, no `\n` in JSON. All new gates are BASH (no `.py` with `claude-`/`anthropic`). CI green.

## [1.4.14] - 2026-05-29 - Bulletproof Quick-Start + workflow-AI (where-to-paste, tag-first, post-build verify)

### Root cause this prevents
Verified from live client pain on Teresa + Maria.
- **(A) Clients copy each field individually (they are 50+).** A combined `Authorization: Bearer <token>`
  line in one code block forces the client to hand-edit after pasting; the header KEY and the header VALUE
  need their OWN copy boxes. Same for `Content-Type` / `application/json`.
- **(B) Quick Start without explanation strands the client; explanation without Quick Start buries the
  copy-paste.** The sheet must lead with an actionable **🚀 Quick Start** AND still carry a full
  **Reference & explanation** section after it — both, in that order.
- **(C) The Teresa gotcha — blank tag in a filter.** Build-with-AI created a trigger filter like
  `does not contain <tag>` where the referenced tag was **blank / never created**, so the trigger silently
  never matched and every inbound message went nowhere. Tags must be created FIRST (and the client must
  know WHERE to check: **Settings → Tags**), and the post-build verification must re-check that any tag in
  a filter is a real, existing one.

### Changed
- **`scripts/21-generate-client-reference-sheet.sh`** — the generated reference sheet now leads with a
  literal **🚀 Quick Start** section and keeps a full **Reference & explanation** section AFTER it. Quick
  Start order: (1) Webhook URL, (2) **Authorization header — TWO separate copy boxes**: the key
  `Authorization` and the value `Bearer <token>` (never combined), (3) **Content-Type header — TWO separate
  copy boxes**: `Content-Type` and `application/json`, (4) Raw Body JSON (fenced `json`, FLAT 23-key),
  (5) **Tags — create FIRST** (where to check: **Settings → Tags**; what you should see), (6) manual
  Custom-Webhook fill steps (now field-by-field: Method dropdown / URL box / Headers Add-item Key+Value /
  Content-Type dropdown / RAW BODY box), (7) Workflow-AI prompt pointer, (8) **post-build verification** —
  TRIGGER / CUSTOM WEBHOOK / PUBLISH, each with WHERE-to-go + WHAT-you-should-SEE + WHAT-to-put-if-missing,
  including the blank/non-existent-tag-in-a-`does not contain`-filter known bug.
- **`scripts/qc-reference-sheet.sh`** — extended the machine gate. It now FAILS the build if the generated
  sheet is missing: the literal **🚀 Quick Start** section; a **Reference & explanation** section AFTER it
  (order-enforced); a code block containing ONLY `Authorization` AND a code block containing ONLY the
  `Bearer <token>` value (and FAILS if they are combined as `Authorization: Bearer …`); a code block
  containing ONLY `Content-Type` AND one containing ONLY `application/json`; the manual-fill instructions;
  the **create-tag-FIRST + Settings → Tags** instruction; and the **post-build verification** section
  covering TRIGGER + PUBLISH + the blank-tag-in-a-filter bug. (Still BASH; no `openclaw` on PATH in the
  sandbox → offline Layer-3 markdown.)
- **`references/workflow-ai-instructions-standard.md`** — §4 verification now gives WHERE/WHAT/WHAT-to-put
  per item and adds a dedicated **TAG FILTER references a REAL, existing tag** item (the Teresa gotcha);
  §5 create-tag-first rule now covers filter tags (not just Add-Tag), states **WHERE tags live (Settings →
  Tags)**, and explains why a blank tag in a `does not contain` filter silently never matches.
- **`templates/sms-workflow-ai-prompt-template.md`** — create-tag-first note now covers filter tags + says
  **Settings → Tags** is where to confirm a tag exists; the "Common Build with AI mistakes" list adds the
  blank/non-existent tag-in-a-filter failure mode.
- **`templates/workflow-verification-checklist-template.md`** — the concise checklist now annotates each
  item with WHERE/WHAT-you-should-SEE/WHAT-to-put, and adds a dedicated **TAG FILTER references a REAL,
  existing tag** item (the Teresa gotcha).
- **`SKILL.md`** — SELF-COUNTS stamp → v1.4.14 (counts unchanged: protocols/=32, scripts/=34,
  references/=15, journeys=8); the `qc-reference-sheet.sh` description updated to list the new enforcement.

### Enforcement
- The extended `qc-reference-sheet.sh` already runs in `scripts/11-run-qc-checklist.sh` and in
  `.github/workflows/qc-static.yml` ("Skill 38 client reference sheet copy-paste artifacts"), so the new
  Quick-Start / separate-blocks / tag-first / post-build-verification markers are checked on every push
  and PR. Negative-tested: a sheet with a combined `Authorization: Bearer` block, no tag-first, or no
  verification section FAILS (exit 1).

### Version
- Skill 38 `skill-version.txt`: 1.4.13 → 1.4.14. No repo-tracked version file changed, so the repo version
  (v10.16.9) and the 8 bump-version.sh locations are unchanged.

## [1.4.13] - 2026-05-29 - v1.4.11 install-script bug fixes (config-validate / jq 1.7 / pointer-source / legacy-path) + MANDATORY manual Custom-Webhook fill instructions

### Root cause this prevents
Two distinct problems, both verified on a live 2026.5.27 box.

**(A) Install-script bugs that broke/degraded fresh installs.**
- `scripts/15-configure-hooks-mappings.sh`: the Model Wizard wrote `agents.defaults.async` /
  `agents.defaults.batch` model keys that are NOT in the 2026.5.27 schema — `openclaw config validate`
  fails ("Invalid input"). It also used a jq merge beginning `.hooks //= {};` which **jq 1.7 REJECTS**
  (the top-level `;` separator is a compile error), so the hooks merge never ran.
- `scripts/04-register-crons.sh` (and the inline cron in `15`): wrote the legacy `.cron.jobs` config
  block, which does NOT validate on 2026.5.27 — crons must be registered via the gateway cron store
  (`openclaw cron add`).
- `scripts/02-create-knowledgebases.sh` + `scripts/03-create-journey-templates.sh`: tried to **`source`**
  the master-files **pointer file**, whose content is a bare directory PATH (not an env script) — the
  shell tries to execute the path and errors ("<path>: is a directory"), leaving `MASTER_FILES_DIR` UNSET.
- `scripts/12-scaffold-channel-playbooks.sh`: hardcoded a legacy skill path
  (`~/clawd/skills/38-openclaw-cloudflare-tunnel`) that no longer exists, so the channel-playbook
  template could not be found.

**(B) Client-facing gap.** GHL's "Build with AI" only builds the workflow SHAPE (trigger + an EMPTY
Custom Webhook action); it does NOT reliably populate the URL, the Authorization/Bearer header, the
Content-Type header, or the Raw Body JSON. Clients did not know they had to open the Custom Webhook action
and paste those values in by hand — so the webhook shipped empty and silently dropped every message.

### Fixed (PART A — install-script bugs)
- **`scripts/15-configure-hooks-mappings.sh`** — (1) Model Wizard no longer writes
  `agents.defaults.async/.batch`; it writes ONLY the supported real-time model
  (`agents.list[main].model`) and PERSISTS the async/batch TIER selections to the secrets/state env
  (`REALTIME_MODEL`/`ASYNC_MODEL`/`BATCH_MODEL`) for downstream consumers. (2) the hooks jq merge now uses
  `.hooks = (.hooks // {}) |` instead of `.hooks //= {};` (valid jq 1.7, same semantics) — the corrected
  SERVER `messageTemplate` (read-before + append-after + mandatory SEND) is unchanged and still validates
  clean. (3) the inline system-health-heartbeat cron is now registered via `openclaw cron add`, not a
  `.cron.jobs` write.
- **`scripts/04-register-crons.sh`** — rewritten to register all 5 crons via the gateway cron store
  (`openclaw cron add --name … --cron … --agent main --message … --light-context --best-effort-deliver`),
  idempotent against `openclaw cron list`; no more `.cron.jobs` config writes. Reads `BATCH_MODEL` from the
  persisted secrets/state env for the batch crons.
- **`scripts/02-create-knowledgebases.sh`** + **`scripts/03-create-journey-templates.sh`** — read the
  master-files pointer with `cat` (it is a path-pointer file, not a sourceable env script) instead of
  `source`-ing it, matching scripts 11/12.
- **`scripts/12-scaffold-channel-playbooks.sh`** — resolves `SKILL38_ROOT` (and the template path)
  DYNAMICALLY from the script's own location instead of the dead hardcoded legacy path.
- **`scripts/10-generate-capabilities-playbook.sh`** — reads the async/batch tier models from
  `$ASYNC_MODEL`/`$BATCH_MODEL` (sourced from secrets/state env) instead of the now-absent
  `agents.async.model`/`agents.batch.model` config keys.

### Fixed (PART B — mandatory manual Custom-Webhook fill)
- **`scripts/21-generate-client-reference-sheet.sh`** — the generated client reference sheet now LEADS
  with the copy-paste values in this exact order: **1) Webhook URL, 2) Authorization/Bearer token (real
  revealed value), 3) Raw Body JSON (fenced `json`, FLAT 23-key), 4) the manual Custom-Webhook fill steps
  ("Build with AI will NOT fill it — do it yourself"), 5) the Workflow-AI prompt pointer** — with all
  explanation/reference following AFTER.
- **`references/workflow-ai-instructions-standard.md`**, **`templates/sms-workflow-ai-prompt-template.md`**,
  **`templates/workflow-verification-checklist-template.md`** — each gains a prominent, MANDATORY section:
  after Build-with-AI runs you MUST open the Custom Webhook action and manually enter Method=POST, the URL,
  Headers via Add item (`Authorization: Bearer <token>` + `Content-Type: application/json`), and the Raw
  Body JSON, then Save + Publish, and verify every field is non-empty before publishing — Build-with-AI
  will NOT fill these for you.
- **`references/communications-playbook-standard.md`** — documents that the manual Custom-Webhook fill step
  is mandatory in every client doc.

### Added
- **`scripts/qc-config-schema-safety.sh`** (pure BASH) — new machine-enforced QC gate that statically scans
  the numbered install scripts and FAILs if any reintroduces a config-invalidating pattern: a `.cron.jobs`
  write, an `agents.defaults.async/.batch` write, or a jq `//= …;` statement. Prose that merely names a
  banned key (comments, `echo`/`printf`/`report_*` strings) is not flagged. Wired into
  `scripts/11-run-qc-checklist.sh` AND `.github/workflows/qc-static.yml` (runs in CI on every push/PR).

### Changed
- **`scripts/qc-reference-sheet.sh`** — extended to ALSO require the manual-fill instructions in the
  generated sheet (greps for "Custom Webhook" + "manually"/"paste" + "Build with AI will not"), on top of
  the existing Bearer/`json`-fence/hook-URL markers.
- **`scripts/11-run-qc-checklist.sh`** — wires `qc-config-schema-safety.sh` in as a mechanical gate.
- **`SKILL.md`** — self-counts updated (scripts 33 → 34); the new QC linter documented.

## [1.4.12] - 2026-05-29 - client reference sheet MUST include the bearer token + a copyable GHL Raw Body JSON (machine-enforced)

### Root cause this prevents
On a live client (Teresa) the generated Client Reference Sheet
(`scripts/21-generate-client-reference-sheet.sh`) had NEITHER the hooks Bearer token NOR the GHL Custom
Webhook Raw Body as a copyable ` ```json ` fenced code block. The client opened their reference doc, the
token was simply missing, and there was no JSON to copy into GHL's Build-with-AI — which stranded the
client. The sheet's content came entirely from the template wrapper, where the bearer token appeared
only inside `[code block, copy button]` pseudo-markers (not a real fence) and the per-channel Raw Body
JSONs lived in a separate Part 3 documentation section, not the reference sheet body. The sheet MUST
contain both, ALWAYS — now enforced, not left to the template.

### Fixed
- **`scripts/21-generate-client-reference-sheet.sh`** now APPENDS two authoritative, always-present
  sections to the rendered reference sheet (so they survive regardless of template wrapping):
  - **Authorization Header / Bearer Token** — resolves the real `hooks.token` in priority order
    `HOOKS_TOKEN` → `OPENCLAW_HOOKS_TOKEN` → `hooks.token` read from `openclaw.json`
    (`$OPENCLAW_CONFIG`, `~/.openclaw/openclaw.json`, `/data/.openclaw/openclaw.json`), and renders it as
    `Authorization: Bearer <token>` inside a real fenced code block. If the token cannot be resolved it
    emits a clearly-marked `REPLACE_ME__…` PLACEHOLDER and WARNs to stderr (never silently omits it).
  - **GHL Custom Webhook — Raw Body** — the canonical FLAT 23-key body as a copyable ` ```json ` fenced
    code block, plus the Method (POST), the hook URL (`https://<host>/hooks/<id>`), and Content-Type
    (`application/json`) as copyable code blocks. The body's `messageTemplate` carries the full
    SEND-directive and stays placeholder-free; the body is not nested and not stripped below 23 keys.

### Added
- **`scripts/qc-reference-sheet.sh`** (pure BASH, mirrors the other `qc-*.sh`) — new machine-enforced QC
  gate. Default mode drives `21-generate-client-reference-sheet.sh` in an offline sandbox (strips
  `openclaw` from PATH → Layer-3 markdown, no network/Telegram) and FAILs (exit 1) if the rendered sheet
  lacks the word `Bearer`, a line-anchored ` ```json ` fence, or a hook URL; `--sheet FILE` statically
  checks an existing sheet; exit 2 (never a blind PASS) if no sheet can be produced/located. BASH (not
  Python) so it respects qc-static's ban on claude-/anthropic strings in `.py` under 22/23. Wired into
  `.github/workflows/qc-static.yml` (runs in CI on every push/PR).

### Changed
- **`scripts/11-run-qc-checklist.sh`** — wires `qc-reference-sheet.sh` in as a mechanical gate.
- **`references/communications-playbook-standard.md`** — new section documenting that the bearer token +
  copyable Raw Body JSON are MANDATORY in every client reference sheet, machine-enforced by
  `qc-reference-sheet.sh`.

## [1.4.11] - 2026-05-29 - enforce the per-playbook human-facing DOC deliverable (Notion → Google Docs → text) so a created playbook can never ship without a client-facing reference

### Root cause this prevents
When a communications/conversation playbook is created (the base install creates the FIRST one —
appointment booking), the agent is supposed to ALSO create a human-facing copy of that playbook in the
**CLIENT's own account**, in the fallback order **(1) the client's Notion → (2) Google Docs → (3) a
plain-text doc the client can access**. On a recent client this step was SKIPPED: the agent scaffolded
the playbook files locally and reported the install "clean," but never created the client's Notion doc,
leaving the customer stranded with no human-facing reference of what was set up. Root cause: the
Notion-doc deliverable was **PROSE** in the playbook, not an **ENFORCED gate**, so the agent skipped it.
This release makes the deliverable un-droppable, enforced exactly like the send-directive and
conversation-memory gates ("AUTOMATIC NEXT STEP prose is not enforcement — needs a state field + a
verify/resume gate + a QC check").

### Added
- **`scripts/qc-playbook-doc.sh`** (pure BASH, bash 3.2-safe) — new machine-enforced QC gate. Runs against
  a client's installed `conversation-workflows/` folder + the run manifest: for EVERY conversation playbook
  (each `<slug>.md` / registry row) it FAILS (exit 1) if there is NO recorded human-facing doc — no Notion
  URL / Google Doc URL / plain-text path on the registry row OR in a `playbookDocs[]` manifest entry. Exit 2
  when NO playbooks exist yet (never silently pass blind); exit 3 when no `conversation-workflows/` folder is
  found. Mirrors `qc-trinity-registry.sh` / `qc-conversation-memory.sh`. Wired into
  `scripts/11-run-qc-checklist.sh`.
- **`scripts/qc-playbook-doc-test.sh`** — CI fixture suite (10 cases) proving the gate: doc-on-registry-row,
  doc-in-manifest (Notion / Google Docs / plain-text), no-doc => FAIL, manifest-entry-without-destination =>
  FAIL, registered-but-no-doc => FAIL, mixed, empty-folder => NO_PLAYBOOKS (exit 2), missing-folder =>
  NO_FOLDER (exit 3). Wired into `.github/workflows/qc-static.yml` (runs in CI on every push/PR), mirroring
  `qc-trinity-registry-test.sh` (the live gate needs a runtime folder, so CI proves it via fixtures).

### Changed
- **Installer now creates + records the per-playbook human-facing doc**
  (`scripts/09-install-conversation-workflows.sh`). After the registry exists, an idempotent doc pass runs
  over every playbook on disk (the appointment-booking starter + any later ones): it tries **Notion**
  (create a NEW subpage under a parent page the integration can access via `NOTION_API_KEY`; if the key is
  missing or no accessible parent page exists, fall through), then **Google Docs** (only if a wired helper
  `SKILL38_GDOCS_HELPER` exists — no silent no-op), then a **plain-text** `.md` under
  `conversation-workflows/client-docs/` as the always-available last resort. The resulting URL/path is
  RECORDED on the playbook's registry row AND as a `playbookDocs[]` line in the run manifest, and an
  operator-facing line states WHERE the doc was created (or which fallback was used). Idempotent: skips a
  playbook that already has a recorded doc.
- **`templates/run-manifest-template.md`** — added a `Playbook docs` section documenting the
  `playbookDocs[]: <slug> -> <url-or-path>` state field (the home for the recorded-doc state the gate checks).
- **BINDING install step + verify/resume self-check** added to `INSTRUCTIONS.md` (Step 9.20 row + a
  NON-NEGOTIABLE hard rule): the install is NOT complete until `qc-playbook-doc.sh` exits 0; if it exits
  non-zero, re-run `09-install-conversation-workflows.sh` to create+record the missing doc, then re-check —
  do not hand off.
- **AGENTS.md Step 1.85 builder block** (`scripts/05-update-agents-md.sh`, `BLOCK_E` Part 3) now makes the
  human-facing doc BINDING + machine-enforced (Notion → Google Docs → text, URL recorded) instead of
  "a NEW Notion doc" prose.
- **Standards updated to mandatory + gated (not optional prose):**
  `references/communications-playbook-standard.md` (new MUST-APPEAR checklist item + §4 now flagged
  MANDATORY/machine-enforced + record-the-destination requirement); `references/v6.0-source-playbook.md`
  (MUST-APPEAR checklist item + §4 flagged mandatory/gated); `references/GHL-INBOUND-AND-PLAYBOOKS.md`
  (§10 day-one wiring requirement now includes the mandatory gated doc; §13 binding-rules index updated);
  `protocols/conversation-workflows-protocol.md` (3-PART build Part 3 now BINDING + gated).
- **`SKILL.md`** self-counts updated (scripts 30 → 32) and the QC-linter list now names the five gates.

### Notes
- The QC gate + its fixture suite are **BASH** (not `.py`), per the qc-static rule that bans
  `claude-`/`anthropic` strings in `.py` files under Skill 22/23 scans.
- No 23-key bodies were touched; FLAT bodies / no nesting / no backslash-n-in-JSON constraints respected.

## [1.4.10] - 2026-05-29 - enforce conversation-memory (read-before + append-after) so hook agents never lose context

### Root cause this prevents
GHL inbound hook sessions are **SINGLE-TURN / stateless** — every hook run is a fresh session
(`user-turns=1`) with no chat history. The agent's only memory of a contact across messages is the
per-contact conversation log file under `conversational-logs/` — it must READ that log BEFORE replying
and APPEND to it AFTER replying. On a live client (Corey) this broke: the canonical server-mapping
`messageTemplate` was simplified during testing and lost the conversation-log read/append steps, the
`conversational-logs/` directory was never created (and on creation was root-owned so the agent couldn't
write), and AGENTS.md had no memory protocol — so the agent had zero memory and "didn't remember
anything" mid-booking. `qc-send-directive.sh` did NOT catch this because it only checks the SEND clause.
This release makes the conversation-memory logic un-droppable, enforced exactly like the send-directive.

### Added
- **`scripts/qc-conversation-memory.sh`** (pure BASH) — new machine-enforced QC gate. Scans every GHL
  inbound SERVER-mapping `messageTemplate` (the installer canonical + reference examples, detected by the
  `INBOUND MESSAGE FROM GOHIGHLEVEL` signature, mirroring `qc-send-directive.sh`) and FAILS (exit non-zero)
  if it lacks the conversation-log READ-before or APPEND-after steps. The installer template is a hard
  requirement (exit 1 if missing/incomplete); no server templates found = exit 2 (linter went blind).
  Wired into `scripts/11-run-qc-checklist.sh` AND `.github/workflows/qc-static.yml` (runs in CI on every
  push/PR). Now scans 3 server templates (installer + v6.0 playbook + GHL-INBOUND §14.4) — all PASS.
- **AGENTS.md "Conversation Memory Protocol" base rule** (`scripts/05-update-agents-md.sh`, new idempotent
  marker block `CONVERSATION_MEMORY_PROTOCOL`) — concise pointer-style rule: hook sessions are single-turn,
  memory = per-contact logs, READ `conversational-logs/<contact_id>__<name>.md` before replying, CONTINUE
  in-progress topics, APPEND after sending; a reply that ignores or fails to update the log is a failure.

### Changed
- **Installer template now carries read-before + append-after + a fail-closed guard**
  (`scripts/15-configure-hooks-mappings.sh`). The written server-mapping `messageTemplate` now contains the
  MEMORY/READ step, a CONTINUE step, the SEND directive, and an APPEND/LOG step. Added a fail-closed guard:
  the installer refuses to write the hook config (exit 8) if the messageTemplate lacks the conversation-log
  read/append elements (needles `conversational-logs` / `read` / `append`).
- **Installer creates the `conversational-logs/` directory + chowns it to the runtime user**
  (`scripts/09-install-conversation-workflows.sh` — the Step-9 conversation-system installer). Now
  `mkdir -p <MASTER_FILES_DIR>/conversational-logs` and, when running as root, `chown -R` it to the gateway
  runtime user (`node` on VPS/Docker; override via `OPENCLAW_RUNTIME_USER`) so the agent can write logs
  (Corey's dir was root-owned and unwritable). Non-root runs warn to chown if the gateway runs as a
  different user.
- **Documented canonical server template updated** so the conversation-memory steps are part of the
  documented canonical template (replacing simplified templates that lacked them):
  `references/v6.0-source-playbook.md` (Step-3 server `messageTemplate`),
  `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14.4 (replaced the simplified one-line server template with the
  full enriched canonical template + send-directive + memory steps),
  `references/communications-playbook-standard.md` (new conversation-MEMORY checklist item),
  `references/workflow-ai-instructions-standard.md` (new conversation-MEMORY checklist item + machine-
  enforcement note). Respects the 23-key rule, FLAT bodies, no nesting, no literal `\n` in JSON — the
  memory steps live ONLY on the SERVER mapping (object B), never in the placeholder-free GHL body (object A).

## [1.4.8] - 2026-05-29 - add Skill 23 cross-reference (role/SOP gate + comms hand-off) to v6.0 playbook

### Added
- **Skill 23 cross-reference in the v6.0 source playbook.** Appended a "🔗 How this connects to the AI
  Workforce Blueprint (Skill 23)" section to `references/v6.0-source-playbook.md` (placed at the end, right
  before the condensed changelog tail). Documents the two enforced connections between Skill 38 and Skill 23:
  (1) the Role Library + SOP Library auto-pull gate (a workforce build is not complete until every role has its
  role library pulled in and its multi-SOP DMAIC library authored — build-state field + verify/resume gate, not
  prose), and (2) the comms-automation hand-off (a workforce with a Communications / Sales / Customer-Support
  department hands off to Skill 38 at closeout to scaffold the matching conversational-AI automations, enforced
  via a `commsAutomationStatus` state field + resume self-ping). Reiterates THE TRINITY (workflow + playbook +
  workflow-AI prompt travel together). No system coverage changed — documentation cross-link only.

## [1.4.7] - 2026-05-29 - close the 2 QC gaps (trinity registry format + 23-key linter covers v6.0 playbook)

Closed the two remaining QC gaps so both machine-enforced linters reconcile against what the install
scripts actually produce — no silent no-ops, no unchecked corpora.

### Fixed
- **GAP 1 — trinity registry format mismatch.** `scripts/qc-trinity-registry.sh` parsed the
  conversation-workflows registry ONLY as a markdown TABLE, but
  `scripts/09-install-conversation-workflows.sh` writes the active-workflow list as BULLETS
  (`<workflow-id>: <one-line description>` under `## Active workflows`). On a real installed registry the
  reconciliation silently no-op'd. The validator now parses the **bullet form** as well as the table: each
  bullet's `<workflow-id>` is reconciled against `<id>.md` + `<id>--build-with-ai-prompt.md` on disk; a bullet
  with no Layer-1 column defaults to "Layer 1 needed" (prompt required) unless the description says
  `(uses existing inbound routing)` / `Layer 1: No`. Installer template and
  `protocols/conversation-workflows-protocol.md` §F updated so installer, validator, and docs agree end to end.
- **GAP 2 — 23-key linter blind to the v6.0 playbook (and to ```bash bodies elsewhere).**
  `scripts/qc-23-key-bodies.sh` explicitly excluded `references/v6.0-source-playbook.md` (~9,430 lines, the
  largest set of GHL RAW BODY examples) and its non-greedy fence regex desynced on mixed-language docs — it
  silently skipped real bodies inside ```bash fences (e.g. BOTH canonical bodies in
  `references/GHL-INBOUND-AND-PLAYBOOKS.md`). Removed the name exclusion and replaced fence pairing with a
  language-agnostic fence walker (opens/closes paired in document order). Scan now covers **22** object-A
  bodies across 5 files (was 9 across 3) — all PASS (23-key, flat, placeholder-free). The v6.0 playbook's 11
  per-channel bodies are scanned and pass; no body needed correcting and the fingerprint did not mis-flag any
  non-body block, so nothing was re-excluded.

### Added
- `scripts/qc-trinity-registry-test.sh` — fixture suite (7 cases) proving the reconciliation catches a
  **registered-but-missing-files** row and a **file-present-but-unregistered** slug on the real **bullet**
  format, plus table-form regressions. Wired into CI (`.github/workflows/qc-static.yml`) next to the 23-key
  linter so both run on every push/PR.

## [1.4.6] - 2026-05-29 - v6.0 clean comprehensive playbook; de-staled

Synced the CLEAN, conflict-free v6.0 comprehensive playbook into the skill so the repo carries NO stale or
self-contradicting playbook content.

### Changed
- **Renamed `references/v5.14-source-playbook.md` → `references/v6.0-source-playbook.md`** (git mv) and replaced
  its content with the clean v6.0 source playbook. Every GHL hook passage in v6.0 is reconciled to the single
  **23-key FLAT body** standard: no nested bodies, no `deliver:true`, no mapping-level `fallbacks`, in-body
  `messageTemplate` kept placeholder-free, server-mapping `sessionKey` is `"{{session_key}}"`.
- Updated every reference/link that pointed to the old `v5.14-source-playbook.md` filename to the new
  `v6.0-source-playbook.md` name across `INSTALL.md`, `INSTRUCTIONS.md`, `protocols/conversation-workflows-protocol.md`,
  six `references/*.md` pointer docs (stripe-coupons, stripe-webhooks, shopify-graphql, sales-frameworks,
  ghl-coupons, cloudflare-tunnel-troubleshooting, cloudflare-godaddy-setup-guide), and the load-bearing scripts
  `scripts/01-locate-master-files-folder.sh` (`PLAYBOOK_SRC`/`DEST_PLAYBOOK`) and `scripts/qc-23-key-bodies.sh`
  (`EXCLUDE_NAMES`).

### Fixed (surgical conflict sweep — contradictions with the corrected 23-key structure)
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14 CARDINAL RULE — corrected the stale "GHL Custom Webhook RAW BODY
  … must **NOT** contain a `messageTemplate`" line, which contradicted §14.1's canonical 23-key body (the body
  DOES carry a `messageTemplate` key, kept placeholder-free; only the *templated* `messageTemplate` is server-side-only).
- `protocols/pre-handoff-qc-protocol.md` — corrected a QC checklist item that told the agent to verify a
  `fallbacks` chain "configured" on the `hooks.mappings` entry; `fallbacks` is NOT a valid `.strict()` mapping
  key. Now states fallback chains belong only on the model-routing config.

Standards (communications-playbook-standard, workflow-ai-instructions-standard) remain their own reference docs;
the playbook references them rather than duplicating them.

## [1.4.5] - 2026-05-29 - 8 rated improvements (push to 10): machine-enforced 23-key + TRINITY, Build-with-AI label fix, real self-counts, fleshed journeys, Skill 23 chain

Part of repo `v10.16.9`. Six of the eight rated improvements land in this skill; the other two
(cross-skill chain enforcement + library-gate status surfacing) land in Skill 23 but reference this skill.
No stripped GHL bodies introduced — the 9 embedded object-A bodies all pass the new linter (23-key, flat,
placeholder-free).

### Added
- `scripts/qc-23-key-bodies.sh` — machine-enforces the 23-key GHL RAW BODY rule across references/ +
  templates/ + scripts/ (exactly 23 flat keys, placeholder-free `messageTemplate`, no nesting, no `\n`).
  Wired into `scripts/11-run-qc-checklist.sh` and into CI (`.github/workflows/qc-static.yml`). Excludes the
  verbatim `v6.0-source-playbook.md` (narrative source, superseded by GHL-INBOUND §14); skips object-B server mappings.
- `scripts/qc-trinity-registry.sh` — machine-enforces THE TRINITY: a registry row with a communications
  playbook but no Build-with-AI prompt (or an orphan prompt) is flagged INCOMPLETE; honors the
  Layer-1-not-needed exemption. Wired into `11-run-qc-checklist.sh`; referenced from the verification
  checklist + standards.

### Changed
- **Mislabel fix (the failure this standard set out to kill):** `templates/sms-workflow-ai-prompt-template.md`,
  `templates/workflow-verification-checklist-template.md`, `scripts/21-generate-client-reference-sheet.sh`,
  `scripts/09-install-conversation-workflows.sh`, and `scripts/20-seed-design-principles.sh` now name the
  authoritative location — GHL **Automations → "Build with AI"** (top-right) on a NEW automation — instead
  of "Use Workflow AI" / "Create workflow → Workflow AI".
- **Real self-counts:** `SKILL.md` + `INSTALL.md` now state protocols=32, scripts=27, references=15,
  journeys=8 (was 31/9/10) with a `SELF-COUNTS` re-verify comment; a re-verification note was added to the
  repo `scripts/bump-version.sh`.
- **7 stub journey templates fleshed out** to ≥ coach depth with vertical-specific triggers / conversation
  phases / success actions: consulting, course-creator, e-commerce, real-estate, saas, service-provider,
  wellness (109–121 lines each).
- **Distinction-map table** added at the top of `protocols/conversation-workflows-protocol.md` (channel
  communication playbook vs communications playbook vs workflow-AI prompt vs GHL automation).
- **Skill 23 upstream cross-reference** added to `SKILL.md` + the protocol's TRINITY note (Skill 23's
  comms/sales/support build now hands off here via the enforced `commsAutomationStatus` chain).

### Version
- `skill-version.txt` → `1.4.5`.

## [1.4.4] - 2026-05-29 - THE TRINITY + communications-playbook & workflow-AI standards

Teaches the connection between a GHL workflow, its communications playbook, and its workflow-AI prompt
(THE TRINITY — one implies the other two, never ship one alone), and ships two standardized
reference/protocol docs with must-appear checklists. CORE md files stay lean: AGENTS.md gets only
concise pointers; full content lives in the reference docs. No stripped GHL bodies introduced — the
one embedded body is the full 23-key flat body (messageTemplate placeholder-free, no nesting).

### Added
- `references/communications-playbook-standard.md` — the FULL communications-playbook standard:
  must-appear checklist (slug/id, owner agent id, channel, trigger phrases/intent, goal, step-by-step
  flow, the GHL reply mechanism via the GHL Conversations API per TOOLS.md, cross-playbook transition
  rules, edge cases incl. frustration/refund/legal, on-success/tagging, tone, honesty floor), the
  canonical format skeleton, STORAGE (always under `conversation-workflows/` + register in
  `registry.md`), and the CLIENT-account STORAGE ORDER fallback chain (Notion → Google Docs → plain
  text, always in that order).
- `references/workflow-ai-instructions-standard.md` — the FULL workflow-AI (Build-with-AI) standard:
  WHERE the prompt goes (GHL Automations → "Build with AI" button — no API, no MCP), the must-appear
  checklist, the explicit Custom Webhook field-by-field steps (EVENT=CUSTOM, METHOD=POST via dropdown,
  URL = the REAL hook url not the sample placeholder, AUTHORIZATION dropdown=None, HEADERS via
  "Add item" → Authorization Bearer token + Content-Type, CONTENT-TYPE=application/json, RAW BODY =
  the full 23-key flat body via the Custom Values picker — not shortened to 4 keys), the
  Build-with-AI VERIFICATION CHECKLIST, and MULTI-ACTION teaching (if/else branches, Add-Tag,
  tag-check, multiple sequential actions, create-tag-first via the GHL skill).

### Changed
- `protocols/conversation-workflows-protocol.md` — added the binding "THE TRINITY" section at the top;
  pointed §D.2 at the workflow-AI standard and §E at the communications-playbook standard +
  client-account storage-order fallback chain.
- `scripts/05-update-agents-md.sh` — AGENTS.md Step 1.85 block now carries a concise THE TRINITY
  pointer + pointers to both standard docs; Step 1.8 (BLOCK_B) points the active-playbook reader at
  the communications-playbook standard and the GHL-Conversations-API reply mechanism. Pointers only —
  no playbook bodies in AGENTS.md.
- `templates/sms-workflow-ai-prompt-template.md` — Custom Webhook action rewritten to the precise
  field-by-field format (EVENT=CUSTOM, METHOD dropdown, real URL not sample placeholder, HEADERS via
  "Add item", CONTENT-TYPE, RAW BODY via Custom Values); added a Multi-action note (if/else, Add-Tag,
  tag-check, multiple actions, create-tag-first). Renamed "Workflow AI" usage to "Build with AI" in
  the how-to. Body unchanged (still the 23-key flat body).
- `templates/workflow-verification-checklist-template.md` — prepended the concise BUILD-WITH-AI
  VERIFICATION CHECKLIST (trigger/filter, exact actions, METHOD=POST, real URL, AUTHORIZATION=None,
  headers via Add item, content-type, 23-key flat body, tags, Published) above the detailed
  click-by-click checklist.
- `skill-version.txt` bumped to `1.4.4`.

## [1.4.3] - 2026-05-29 - Enforce 23-key GHL body everywhere

Owner directive (non-negotiable): EVERY GHL Custom Webhook RAW BODY example in Skill 38 must contain
**all 23 keys** — 23 is the MINIMUM, no stripped/short (8/11/13-key) bodies are allowed anywhere in the
repo. Every previously-shorter (13-key) body was REPLACED with the full 23-key canonical body. The body
stays FLAT (no nesting), the body's `messageTemplate` value is kept **placeholder-free** (no `{{…}}`, or
GHL throws "Error while parsing the object to JSON"), and no `\n` appears inside any JSON example. The
23 keys (exact): `id`, `match`, `action`, `agent_id`, `model`, `wakeMode`, `name`, `session_key`,
`messageTemplate`, `deliver`, `timeoutSeconds`, `channel`, `to`, `thinking`, `contact_id`, `first_name`,
`last_name`, `email`, `phone`, `subject`, `message_body`, `location_id`, `location_name`. Per-channel
variants change only `channel` + the `session_key` prefix (sms / fb / instagram / whatsapp / live_chat /
email). The OpenClaw server `hooks.mappings` entry (object B) is unchanged — it keeps its own templated
`messageTemplate`; only the GHL Custom Webhook body (object A) is the 23-key payload.

### Changed
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — replaced the §3.1 Build-with-AI Raw Body and the §14.1
  canonical body with the full 23-key body; added the per-channel variants table (§14.1); stated the
  23-key rule plainly in §5 with the full key list and per-key explanation; updated the §4 verification
  checklist field list to all 23 keys and reframed the messageTemplate item to "placeholder-free" (instead
  of "no messageTemplate"); reconciled §14.2 (body messageTemplate must stay placeholder-free) and added a
  two-objects note after §14.4; updated the header warning, §13 quick-index items 4 & 11, and the §14 intro.
- `references/v5.14-source-playbook.md` — upgraded the localhost smoke-test body, the E2E test body, the
  Part 1 D.2 Build-with-AI body, the D.3 verification-checklist body reference, and all Part 3 channel Raw
  Body blocks to the full 23-key body (added a WhatsApp block; aligned facebook→fb, livechat→live_chat to
  the §7 verified send-type enum); updated the §3C corrected-structure callout to the 23-key standard.
- `scripts/15-configure-hooks-mappings.sh` — the Step 4 E2E test PAYLOAD is now the full 23-key body
  (validated as 23-key JSON); header comment updated to the 23-key rule. Server mapping unchanged.
- `templates/client-reference-sheet-template.md` — all channel Raw Body blocks upgraded to 23 keys (added
  WhatsApp); count references updated.
- `templates/sms-workflow-ai-prompt-template.md` — the SMS Raw Body upgraded to 23 keys; the Workflow-AI
  "common mistakes" list now flags placeholder-in-body-messageTemplate and sub-23-key (stripped) bodies.
- `templates/workflow-verification-checklist-template.md` — Raw Body checklist item now mandates all 23 keys.
- `protocols/conversation-workflows-protocol.md` — the D.2 Build-with-AI body and the verification-checklist
  Raw Body item upgraded to the 23-key standard.
- `skill-version.txt` bumped to `1.4.3`.

## [1.4.2] - 2026-05-29 - Corrected GHL inbound hook structure: FLAT body, no nesting, server-only messageTemplate

GHL inbound-hook correction verified LIVE on Corey / Explore Growth (OpenClaw 2026.5.27). The GHL Custom
Webhook RAW BODY is now documented as **FLAT** (no nested `contact:{}` / `customer_message:{}` objects — a
nested body makes EVERY field resolve EMPTY at the hook) and **data-only** (it must NOT contain a
`messageTemplate` — a templated messageTemplate in the body makes GHL throw "Error while parsing the object
to JSON" and Skip the webhook). The `messageTemplate` lives ONLY on the server `hooks.mappings` entry,
references the FLAT body key names, and MUST include the reply-via-GHL-API instruction (or the agent drafts
a reply but never sends it). `deliver:false`; `agentId` is hardcoded per hook path (NOT templatable);
`fallbacks` is not a valid mappings key (`.strict()` schema); `GHL_LOCATION_ID` env is the API credential,
not the body `location_*` fields. `skill-version.txt` bumped to `1.4.2`.

### Changed
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — replaced the nested Build-with-AI Raw Body (§3.1) with the
  canonical FLAT body; rewrote §5 (FLAT body rule, with a labeled ❌ NESTED counter-example); updated the
  §4 verification checklist (FLAT body + no in-body messageTemplate); added a header warning pointing to the
  new section; added **§14 "CORRECTED GHL HOOK STRUCTURE (2026-05-29)"** capturing the full SPEC (cardinal
  rule, flat body, server-only messageTemplate with the GHL-API reply instruction, `deliver:false`, sessionKey
  gating, agentId not templatable / `/hooks/agent`, `fallbacks` invalid, `GHL_LOCATION_ID` is the credential,
  valid `.strict()` mappings keys).
- `references/v5.14-source-playbook.md` — converted the canonical `hooks.mappings` messageTemplate/sessionKey
  to FLAT body keys (added the reply-via-GHL-API instruction; `timeoutSeconds` 180→300), flattened the
  localhost smoke-test body, the E2E test body, the D.2 Build-with-AI prompt body, and all six Part 3 channel
  Raw Body JSONs; added a CORRECTED-structure call-out + updated the "Why these settings" prose.
- `scripts/15-configure-hooks-mappings.sh` — `messageTemplate` now references FLAT body keys and explicitly
  instructs the agent to actually send via the GHL API; `deliver` true→**false**; `timeoutSeconds` 180→300;
  `sessionKey` now pulls the flat `{{session_key}}` body key; the Step 4 E2E test PAYLOAD is now a FLAT body.
- `scripts/21-generate-client-reference-sheet.sh` — added `HOOK_NAME` and `AGENT_ID` to the template
  placeholder substitution (so the flattened templates render with concrete values).
- `templates/sms-workflow-ai-prompt-template.md` — flattened the Raw JSON body; added the FLAT/data-only
  rule, the "nests the body" + "adds messageTemplate to body" failure modes, and `<AGENT_ID>` to placeholders.
- `templates/client-reference-sheet-template.md` — flattened all six channel Raw Body JSONs (Part 3); updated
  the Part 3 intro (FLAT, data-only, Custom Values picker) and the "adding other services" note.
- `protocols/conversation-workflows-protocol.md` — flattened the Build-with-AI prompt Raw JSON body and
  clarified the server-only messageTemplate rule.

## [1.4.1] - 2026-05-28 - Hostinger Docker env-discovery + conversation-playbook builder + CF/GoDaddy Notion-offer

Patch release on top of the 1.4.0 GHL hardening: the Hostinger Docker env-discovery layer, the
conversation-playbook builder hardening, and the CF/GoDaddy prereq-halt Notion-offer (when a client has
no Cloudflare API token, the agent OFFERS a Notion doc in the client's OWN workspace from
`references/cloudflare-godaddy-setup-guide.md` + link, or a manual step-by-step walkthrough — never a
bare `cat` for the operator to read on the box). `skill-version.txt` is bumped to `1.4.1`.

### Added
- `references/HOSTINGER-DOCKER-ENV.md` (NEW) — bulletproof Hostinger Docker VPS env-discovery. Documents where the
  environment lives (host `/docker/<project>/.env` = canonical `env_file`; container mirror `/data/.openclaw/.env`
  via the `volumes: ./data:/data` bind mount; live `docker exec <container> printenv`), the EXACT copy-paste
  discovery sequence (`docker ps` → derive `<project>` → `cat /docker/<project>/.env` → `docker exec … printenv |
  grep API_KEY`), THE HARD RULE (never report a key "missing" before running that sequence — if other keys like
  `ANTHROPIC_API_KEY` are visible you're in the right place; add the missing key there, don't claim you can't find
  it), the canonical add-a-key procedure (append host + mirror container + `docker compose up -d --force-recreate`;
  plain `restart` does NOT reload `env_file`), and the `/hostinger/server.mjs` `hooks.token` rewrite gotcha.

### Changed
- `references/v5.14-source-playbook.md` Step O.5 — added a Hostinger Docker pointer (env is `/docker/<project>/.env`;
  run the discovery sequence + HARD RULE in HOSTINGER-DOCKER-ENV.md before reporting any key missing).
- `scripts/00-verify-prerequisites.sh` "CLOUDFLARE API KEY NOT FOUND" halt — added a prominent Hostinger Docker
  block (the env is `/docker/<project>/.env`, run discovery before reporting missing) and made the
  `cloudflare-godaddy-setup-guide.md` pointer clearly the path for getting a domain into Cloudflare + creating the
  CF API token; the "save your key" step now shows the Hostinger host-`.env` + force-recreate path.
- Step 9.20 (Conversation Workflow Builder) — now explicitly a **3-PART build** every time: Part 1 (Build-with-AI
  prompt + manual-build fallback + verification checklist — nails the funnel SHAPE, operator pastes token/URL/Raw
  values), Part 2 (the Layer 2 conversation playbook in `conversation-workflows/`, registered in `registry.md`; the
  hook path wires the two halves), Part 3 (the brainstorm trigger — FRIENDLY proactive Q&A, NOT 50 questions; uses
  Typed Knowledge Bases + USER.md + MEMORY.md, asks only smart gaps, regurgitates a concise "is this what you want?"
  summary; on YES builds Part 1 → Part 2 → pointer → NEW Notion doc → register). USP framing added
  (communication-driven funnels / automations, beats CloseBot). Cross-references to Step 9.33 (Intelligent Playbook
  Routing) and Step 9.34 (Proactive Features Suite) added at all three steps so builder → router → proactive engine
  are explicitly one loop. Mirrored into `protocols/conversation-workflows-protocol.md` and `scripts/05-update-agents-md.sh`
  (Step 1.85). Removed ambiguous "Workflow AI" usage — renamed to "Build-with-AI" throughout (artifact files
  `<id>--build-with-ai-prompt.md`); fixed the operator-instruction block that still said "Use Workflow AI".
- `scripts/06-append-memory-rules.sh` + `CORE_UPDATES.md` — added MEMORY.md design rules 15-18 (GHL/automation
  terminology = GHL Automations workflow; GHL Automations have NO API/NO MCP, only the "Build with AI" button; the
  3-part build checklist; communication-driven-funnels + brainstorm-not-50-questions). Written under a separate
  `v1.4.0` marker so existing v5.14 installs get rules 15-18 on upgrade without re-appending 6-14 (idempotent +
  upgrade-safe, verified).

## [1.4.0] - 2026-05-28 - GHL inbound hardening: Build-with-AI prompt, 4-token model, verified APIs, calendar-sync

### Why
Debugging a live client (Corey, Hostinger Docker VPS) surfaced a cluster of repeatable failures that
every future VPS client would otherwise hit: the four secrets in this system kept getting confused;
`deliver: true` on GHL API-reply hooks silently broke replies; the `cron.jobs` JSON format stopped
validating on current openclaw; the VPS wrapper resets `hooks.token` on every boot; and there was no
authoritative reference for the one-tunnel-many-hooks model, the Build-with-AI prompt (GHL's only
programmatic automation-build path), the verified channel→type enum, or the verified Calendar API.

### Added
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` (NEW) — the authoritative reference. Contains: the 4-token
  table (CF API token vs tunnel connector token vs HOOKS_TOKEN vs GHL PIT, with VPS specifics); the
  one-tunnel-many-hooks model (created once, reused; new automations = new hook paths, never recreate
  the tunnel); the copy-paste **Build-with-AI prompt** template (the only programmatic way to build a
  GHL automation) with placeholders; the post-build **verification checklist** (incl. the "GHL Test
  button sends empty merge fields → verify with a real inbound" gotcha); the **Reusable Tunnel Values**
  storage rule (AGENTS.md + TOOLS.md + client Notion, every time); the **one-value-per-key** JSON rule;
  the **verified channel→type enum** (SMS/Email/FB/IG/WhatsApp/Live_Chat valid; TikTok/Call/GMB and
  long-forms invalid); the GHL Conversations reply recipe + the verified Calendar recipe (free-slots is
  epoch-millis; book requires calendarId/locationId/contactId/startTime, endTime optional); and the
  ready **first conversation playbook = appointment booking** Layer 2 template.
- `scripts/skill38-calendar-sync.sh` (NEW) — weekly GHL calendar refresh. Maintains a
  `<!-- GHL_CALENDARS_START/END -->` marker block in TOOLS.md (adds new calendars, removes deleted).
  Generic across clients; reads PIT + GHL_LOCATION_ID from the client env file. Registered via
  `openclaw cron add` (Sunday 9am).

### Changed (surgical edits to `references/v5.14-source-playbook.md`)
- **Step 3C / Step 3.5G:** `deliver: true` → `deliver: false` on the GHL inbound hooks mapping, with
  the corrected rationale (deliver:false for any hook that replies via an external API; deliver:true
  only to echo the agent's final text to its own bound channel).
- **Step 3A:** added the 4-token disambiguation (pointer to the new ref doc) and the VPS rule — set
  `OPENCLAW_HOOKS_TOKEN` in host-level `/docker/<project>/.env` (the `/hostinger/server.mjs` wrapper
  rewrites `hooks.token` every boot), then `docker compose up -d --force-recreate`.
- **All cron registrations** (conversation-log-summarizer, system-health-heartbeat, weekly-tune-up,
  proactive-suggestions-scan, monthly-comprehensive-review, plus the new calendar-sync): replaced the
  `cron.jobs` JSON and the old positional `cron add` form with the supported flag-based CLI
  (`openclaw cron add --name … --cron … --agent … --message … --light-context --best-effort-deliver`),
  noting the JSON format no longer validates.
- **Step 6:** the Build-with-AI prompt is now the PRIMARY workflow-build method; the 20-step
  hand-build is demoted to a clearly-labeled FALLBACK. The verification checklist is required even on
  success. Added the Reusable Tunnel Values section + the Notion-doc quality spec (Reusable Tunnel
  Values → Build-with-AI prompt per channel → verification checklist). The base SMS install also
  creates the first appointment-booking playbook and wires the hook path to it (day-one round-trip).
- **Step 9.19:** added the verified GHL Calendar API recipe + the calendar-sync install + Sunday cron.
- **Step 9.20 D.2:** renamed "Workflow AI prompt" → "Build-with-AI prompt" and noted it is the SAME
  generator used for the base onboarding automation in Step 6 (one generator, two call sites).
- **Rules of Engagement:** added Rule 7 — one value per key (proper JSON structure).
- Standardized the outbound cred var to `GHL_PRIVATE_INTEGRATION_TOKEN` and Version `2021-04-15`;
  added WhatsApp to the verified send-type table and the invalid-types list.

### Source of truth
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — authoritative for GHL inbound + playbooks (this release).
- `references/v5.14-source-playbook.md` — the canonical playbook (surgically updated, pointers added).

## [1.0.0] - 2026-05-28 - Initial release (packages v5.14 playbook)

### Why
Christy's v5.14 conversational AI playbook (~8,800 lines, 14 version iterations) packaged as
an installable skill. Builds the conversational AI BRAIN on top of skill 29 (GHL Convert and Flow).

### Added
- 27 protocol files (humanizer NOT included; skill 19 owns it)
- 8 customer journey templates (coach fully detailed; 7 stubbed)
- 9 idempotent + OS-aware install scripts (00 prerequisites → 08 Shopify wizard)
- 7 reference documents including the FULL v5.14 source playbook + strategic roadmap
- SKILL.md, INSTALL.md, INSTRUCTIONS.md, EXAMPLES.md, CORE_UPDATES.md
- AGENTS.md Steps 1.7, 1.8, 1.9, 2.8; upgraded Step 1.75
- MEMORY.md design rules 6-14
- 4 cron jobs (Sunday 2am tune-up, Saturday 11pm proactive + 11:30pm model freshness, 1st-of-month review)

### Source of truth
- `references/v5.14-source-playbook.md` — the canonical 8,797-line playbook
- `references/conversational-ai-strategic-roadmap.md` — strategic context (✅ shipped vs 📋 pending)

### Out of scope (DEFERRED, not in this skill)
- F14 Voice/Phone Integration
- F15 Proactive Outreach Campaigns
- F16 A/B Testing of Reply Variants
- F17 Customer Segmentation Awareness
- F18 Webhook Chaining
- F21 Multi-Tenant Agent Isolation

The skill's structure (numbered scripts, protocols/ folder, references/) leaves room for
these to be added later without restructuring.
