# Core File Updates — Skill 38 (Conversational AI System, packages playbook v6.0)

These lines are appended to the workspace's AGENTS.md, MEMORY.md, and (optionally) other
core files at install time. They tell the master orchestrator and any sub-agent how skill 38
interleaves with skill 29 (GHL Convert and Flow) and skill 19 (Humanizer).

**Versioning:** This skill is semver-tagged starting at v1.0.0 (today, 2026-05-28).
Future v1.1, v1.2 updates can extend without restructuring (see "Room for future features"
in INSTRUCTIONS.md).

---

## [ADD TO AGENTS.md] — appended by `scripts/05-update-agents-md.sh`

The script appends named fenced blocks wrapped in `<!-- BEGIN SKILL38: <NAME> -->` /
`<!-- END SKILL38: <NAME> -->` markers (e.g. `SKILL38_RUNTIME_ROUTING`) containing the
MANDATORY SEND rule, Steps 1.7, 1.8, 1.9, 2.8 and the upgraded Step 1.75. See the script for
the exact marker names and content; the v6.0 source playbook (Steps 7 and 9.21-9.30) is the
canonical wording.

Key behaviors added:
- **Step 1.7** — Query the appropriate typed Knowledge Base for context.
- **Step 1.75** (upgraded) — Run Intelligent Playbook Routing — re-evaluate workflow match after EVERY customer message; max 3 switches per conversation; cosine similarity 0.3 advantage to switch.
- **Step 1.8** — Sales Brain check: BANT/MEDDIC/SPICED + 6 objection patterns + buyer-signal scoring + pricing reveal rules + honesty floor.
- **Step 1.9** — Customer Service & Support (dual-mode): detect service-mode vs support-mode signals; honesty floor enforced.
- **Step 2.8** — Humanizer pass via skill 19 (ALWAYS-ON; skill 38 does NOT ship its own humanizer).

## [ADD TO MEMORY.md] — appended by `scripts/06-append-memory-rules.sh`

Rules 6-14 + rules 15-18 (the conversation-playbook builder) of the MEMORY.md design principles.
(Rules 1-5 belong to skill 19/29.) The script writes them under two separate, STABLE marker names —
`<!-- BEGIN skill-38 memory-rules v5.14 -->` (rules 6-14) and `<!-- BEGIN skill-38 memory-rules v1.4.0 -->`
(rules 15-18). Those marker labels are fixed identifiers tied to when each rule-set first shipped (the
v5.14 playbook era and the v1.4.0 skill release respectively) — do NOT rename them, or already-installed
boxes will re-append the rules. The two-marker split is what lets an existing install pick up rules 15-18
on upgrade without re-appending 6-14.

6. **Conversation Log Rule** — log every inbound + outbound, real-time.
7. **Quiet Hours Rule** — never proactively message outside operator-defined quiet hours.
8. **PII Rule** — scrub before any model call; never log raw PII.
9. **Confidence Rule** — escalate below threshold; never bluff.
10. **Sales Brain Rule** — apply BANT/MEDDIC/SPICED + 6 objection patterns + buyer-signal scoring before any pricing reveal.
11. **Customer Service vs Support Rule** — detect mode by signal; mid-conversation mode-switching allowed; honesty floors enforced.
12. **Discount Code Rule** — only per per-product policy; never invent codes.
13. **Intelligent Routing Rule** — Conversation Workflows override channel playbooks per context routing.
14. **Tune-up Rule** — Sunday 2am weekly + Saturday 11pm proactive + 1st-of-month review crons are the heartbeat. Never disable without operator approval.
15. **"Workflow" / "automation" terminology Rule** — when the operator says "workflow", "automation", or "Workflow AI" they mean a **GHL (Convert and Flow) Automations-section workflow** unless they explicitly say otherwise. Do not assume n8n, Zapier, or OpenClaw cron.
16. **GHL Automations build path Rule** — GHL Automations have **NO API and NO MCP**. The ONLY programmatic way to build one is GHL's **"Build with AI" button** (top-right of the Automations area): click it and paste the Build-with-AI instructions. (Future: if Playwright/browser-control is installed, an agent can open the Automations area and paste automatically; right now it is a manual paste by the operator.) Never tell the operator there's an API for building GHL automations — there isn't.
17. **3-Part Build Rule** — every "build me a conversation playbook / workflow / automation" request produces THREE artifacts, every time (per Step 9.20 / conversation-workflows-protocol.md): (1) the Build-with-AI prompt + manual-build fallback + verification checklist; (2) the Layer 2 conversation playbook saved to `conversation-workflows/<id>.md` and registered in `conversation-workflows/registry.md`; (3) a NEW Notion doc for that playbook. The hook path is what wires the GHL automation to the conversation playbook. Never stop after one artifact.
18. **Communication-driven funnels Rule** — the system's USP is **communication-driven funnels / communication-driven automations**: the operator builds by **talking/brainstorming**, NOT click-and-drag (this is the edge over CloseBot). When the operator triggers the builder, run a **FRIENDLY brainstorm — do NOT dump 50 questions.** Use what you already know (Typed Knowledge Bases + USER.md + MEMORY.md) and ask ONLY the smart gaps, then regurgitate a concise "is this what you want?" summary as the final confirmation before building.

## [ADD TO TOOLS.md] — no automated update; operator manually documents

The operator may add tool entries for newly-wired services as Stripe/Shopify are connected. Skill 38 ships reference docs (`references/stripe-*`, `references/shopify-*`) so the operator has the API surface available.

## [REGISTERED CRONS] — registered by `scripts/04-register-crons.sh`

| Cron | Schedule | Protocol |
|---|---|---|
| `weekly-tune-up` | `0 2 * * 0` | `protocols/weekly-tune-up-protocol.md` |
| `proactive-suggestions-scan` | `0 23 * * 6` | `protocols/proactive-suggestions-protocol.md` |
| `model-version-freshness` | `30 23 * * 6` | `protocols/model-version-freshness-protocol.md` |
| `monthly-comprehensive-review` | `0 3 1 * *` | `protocols/monthly-comprehensive-review-protocol.md` |

All four cron jobs are idempotent — `04-register-crons.sh` skips entries that already exist.

## What does NOT get touched

- Skill 17, 18, 31, 29, 19 SOUL/IDENTITY/AGENTS files — left untouched per Christy.
- Operator's existing TOOLS.md, SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md — only AGENTS.md and MEMORY.md are appended to, behind clear `<!-- BEGIN/END skill-38 -->` markers, with backups before any edit.
