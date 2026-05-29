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
