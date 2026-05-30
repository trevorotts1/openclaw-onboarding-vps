#!/usr/bin/env bash
# 06-append-memory-rules.sh — Skill 38: append MEMORY.md design rules 6-18
#   Rules 6-14 (v5.14) + rules 15-18 (v1.4.0 — GHL/Build-with-AI + 3-part build + USP).
# Idempotent. Backs up before any edit. Never overwrites operator content.
# Upgrade-safe: rules 15-18 land via their own marker so installs that already have the
# v5.14 block (rules 6-14) still get the new rules on re-run, without double-appending.

set -euo pipefail
case "$(uname -s)" in
  Darwin) WS_DEFAULT="$HOME/clawd" ;;
  Linux)  WS_DEFAULT="/data/clawd" ;;
esac
WS="${OPENCLAW_WORKSPACE:-$WS_DEFAULT}"
MEM_MD="$WS/MEMORY.md"
[ -f "$MEM_MD" ] || { echo "[skill 38] $MEM_MD not found — skipping"; exit 0; }

MARKER_BEGIN="<!-- BEGIN skill-38 memory-rules v5.14 -->"
if grep -qF "$MARKER_BEGIN" "$MEM_MD"; then
  echo "[skill 38] MEMORY.md already contains skill 38 rules 6-14 — preserved"
else
  cp "$MEM_MD" "$MEM_MD.bak-skill38-$(date +%Y%m%dT%H%M%SZ)"
  cat >> "$MEM_MD" <<'BLOCK'

<!-- BEGIN skill-38 memory-rules v5.14 -->
## Skill 38 — Conversational AI System: MEMORY.md design rules 6-14

(Rules 1-5 are skill 19 / skill 29 territory; these 9 are skill 38's per the v5.14 playbook.)

6.  Conversation Log Rule — log every inbound + outbound, real-time, never lose a turn.
7.  Quiet Hours Rule — never proactively message outside operator-defined quiet hours;
    reactive replies still go.
8.  PII Rule — scrub email/phone/SSN/credit-card patterns before any model call; replace
    with stable tokens, never log raw PII.
9.  Confidence Rule — if model confidence below threshold, escalate to operator; never
    bluff a confident answer.
10. Sales Brain Rule — apply BANT/MEDDIC/SPICED + the 6 objection patterns + buyer-signal
    scoring before any pricing reveal.
11. Customer Service vs Support Rule — detect mode by signal keywords; mid-conversation
    mode-switching allowed; honesty floors enforced.
12. Discount Code Rule — generate discount codes only per per-product policy; never
    invent a code without operator-approved rules.
13. Intelligent Routing Rule — Conversation Workflows override channel playbooks when
    context routing says they should.
14. Tune-up Rule — Sunday 2am weekly + Saturday 11pm proactive + 1st-of-month review
    cron jobs are the heartbeat. Never disable without operator approval.

<!-- END skill-38 memory-rules v5.14 -->
BLOCK
  echo "[skill 38] MEMORY.md updated (rules 6-14 appended; backup at $MEM_MD.bak-*)"
fi

# --- v1.4.0 top-up: conversation-playbook builder rules 15-18 (own marker = upgrade-safe) ---
MARKER_BEGIN_14="<!-- BEGIN skill-38 memory-rules v1.4.0 -->"
if grep -qF "$MARKER_BEGIN_14" "$MEM_MD"; then
  echo "[skill 38] MEMORY.md already contains skill 38 rules 15-18 — preserved"
  exit 0
fi
cp "$MEM_MD" "$MEM_MD.bak-skill38-v140-$(date +%Y%m%dT%H%M%SZ)"
cat >> "$MEM_MD" <<'BLOCK14'

<!-- BEGIN skill-38 memory-rules v1.4.0 -->
## Skill 38 — Conversation-playbook builder design rules 15-18 (v1.4.0)

15. "Workflow" / "automation" / "Workflow AI" Rule — these mean a GHL (Convert and Flow)
    Automations-section workflow unless the operator explicitly says otherwise. Not n8n,
    not Zapier, not an OpenClaw cron.
16. GHL Automations build-path Rule — GHL Automations have NO API and NO MCP. The ONLY
    programmatic path is GHL's "Build with AI" button (top-right of the Automations area):
    click it, paste the Build-with-AI instructions. (Future: if Playwright / browser-control
    is installed, an agent can open the Automations area and paste automatically; right now
    it's a manual paste by the operator.) Never claim there's an API for building GHL
    automations — there isn't.
17. 3-Part Build Rule — every "build me a conversation playbook / workflow / automation"
    request produces THREE artifacts, every time (Step 9.20 / conversation-workflows-protocol.md):
    (1) Build-with-AI prompt + manual-build fallback + verification checklist;
    (2) the Layer 2 conversation playbook at conversation-workflows/<id>.md, registered in
        conversation-workflows/registry.md;
    (3) a NEW Notion doc for that playbook.
    The hook path (https://<PUBLIC_HOSTNAME>/hooks/<HOOK_NAME>) wires the GHL automation to the
    conversation playbook. Never stop after one artifact.
18. Communication-driven funnels Rule — the system's USP is communication-driven funnels /
    automations: the operator builds by TALKING / brainstorming, not click-and-drag (the edge
    over CloseBot). On a builder trigger, run a FRIENDLY brainstorm — do NOT dump 50 questions.
    Use what you already know (Typed Knowledge Bases + USER.md + MEMORY.md) and ask ONLY the
    smart gaps, then regurgitate a concise "is this what you want to happen?" summary as the
    final confirmation before building.

<!-- END skill-38 memory-rules v1.4.0 -->
BLOCK14

echo "[skill 38] MEMORY.md updated (rules 15-18 appended; backup at $MEM_MD.bak-skill38-v140-*)"

# --- v1.5.0 top-up: Round-3 Queue-A CORE feature rules 20-25 (own marker = upgrade-safe) ---
# Does NOT renumber the existing rules 6-18 — appends in a fresh marker block.
# One feature per rule (canonical scheme): 20 tag-prefix / 21 F50 / 22 F44 / 23 F45 /
# 24 F46 / 25 F47. The F52 JSONL data-contract is documented centrally in INSTRUCTIONS.md
# (Phase-5 data-contract table) — it is NOT its own MEMORY rule.
MARKER_BEGIN_150="<!-- BEGIN skill-38 memory-rules v1.5.0 -->"
if grep -qF "$MARKER_BEGIN_150" "$MEM_MD"; then
  echo "[skill 38] MEMORY.md already contains skill 38 rules 20-25 — preserved"
  exit 0
fi
cp "$MEM_MD" "$MEM_MD.bak-skill38-v150-$(date +%Y%m%dT%H%M%SZ)"
cat >> "$MEM_MD" <<'BLOCK150'

<!-- BEGIN skill-38 memory-rules v1.5.0 -->
## Skill 38 — Round-3 Queue-A CORE: design rules 20-25 (v1.5.0)

20. ZHC Tag-Prefix Rule — every tag the agent creates PROGRAMMATICALLY (via the GHL
    skill's create_tag, or the fallback POST /locations/{id}/tags) carries the `ZHC-`
    prefix, so agent-created tags are instantly distinguishable from operator-created ones.
    This is NOT retroactive: never rename existing or operator-owned tags; only prefix the
    names the agent creates going forward. Companion: programmatically created CRM custom
    FIELDS use the `ZHC_` prefix (Rule 24). The bot tag is `ZHC-bot-suspected` going
    forward; existing `bot-detected` tags are honored as-is. Reuse the existing D.1 /
    Section-6 tag-creation mechanism — only the NAME changes. See
    `<MASTER_FILES_DIR>/zhc-tag-prefix-protocol.md`.
21. Aggression Rule (F50) — screen every inbound for hostility BEFORE routing and BEFORE
    the model (Step 1.35). Tier 1 TENSION (multiple irritation words / 3+ message streak /
    !!!|???) → tag `ZHC-tension-detected`, heighten care, NO reroute. Tier 2 AGGRESSION
    (profanity-AT-agent / threats legal-physical-public / ALLCAPS+profanity+direct-address
    / 3+ signals in one message) → tag `ZHC-aggression-detected`, route to aggression-
    handler, notify operator. ALL CAPS ALONE never fires. Sensitivity lenient|standard|
    strict in openclaw.json. Extends bot-detection, does not replace it. See
    `<MASTER_FILES_DIR>/aggression-detection-protocol.md`.
22. Interrupt Rule (F44, detour-and-return) — always-listening layer parallel to the active
    workflow. On an interrupt (operator-urgent keyword, FAQ type, compliance redirect, F50
    aggression, F49 pixel-priority): SAVE state (step + gathered data + context) → EXECUTE
    sub-flow → RETURN to the saved step with a soft "coming back to where we were"
    transition. DISTINCT from Step 9.33's route-and-stay. Max 2 levels deep, then escalate.
    Multiple triggers: highest priority first, queue the rest. Tags `ZHC-interrupt-handled`
    / `ZHC-faq-detoured` / `ZHC-aggression-handled-and-resumed`. See
    `<MASTER_FILES_DIR>/smart-playbook-switching-protocol.md`.
23. Geo-Qualification Rule (F45, OFF by default; per-product opt-in via
    `geo_qualification.per_product`) — when ON, location signals (pixel/IP →
    phone area code → form address → explicit ask) are HINTS only. ALWAYS ASK to confirm
    before ANY disqualification or out-of-area handling — never disqualify on a guess, and
    never on "vacation," "moving," or a non-answer (all do-not-disqualify). Only a CONFIRMED,
    genuinely out-of-area service location triggers out-of-area handling, which is
    operator-configured (decline+referral / limited-remote / waitlist / full decline).
    Service areas per product in `KnowledgeBases/sales/service-areas.md`. Tags
    `ZHC-out-of-service-area` / `ZHC-service-area-confirmed` / `ZHC-service-area-flexible`.
    See `<MASTER_FILES_DIR>/geo-qualification-protocol.md`.
24. CRM Field-Write Rule (F46) — the agent writes ANY GHL contact custom field mid-convo,
    type-aware (text/number/date/dropdown), discovering via GET /locations/{id}/customFields
    and validating before write. CREATE-IF-MISSING: if no matching field exists, create one
    with the `ZHC_` prefix (operator-approved allow-list action, NEVER customer-invoked),
    notify the operator, record the mapping in `crm-field-mappings.md`. The weekly tune-up
    reviews field usage. See `<MASTER_FILES_DIR>/crm-field-write-protocol.md`.
25. Smart-FAQ Rule (F47) — answer quick known FAQs INLINE, a SENTENCE not a sub-flow, then
    return to the current step in the SAME reply ("By the way, [answer]. Coming back to
    [topic]…"). Matches `KnowledgeBases/business/faqs.md`, scoped per workflow via
    `faq-scope.md`. Bigger FAQ questions hand off to F44 as a detour. Tag
    `ZHC-faq-answered`. See `<MASTER_FILES_DIR>/smart-faq-tool-protocol.md`.

<!-- END skill-38 memory-rules v1.5.0 -->
BLOCK150

echo "[skill 38] MEMORY.md updated (rules 20-25 appended; backup at $MEM_MD.bak-skill38-v150-*)"
