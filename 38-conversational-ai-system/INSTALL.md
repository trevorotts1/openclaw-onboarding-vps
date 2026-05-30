# Skill 38 — Conversational AI System: Install Guide

## What this installs

The **conversational AI BRAIN** that runs on top of skill 29 (GHL Convert and Flow). Specifically:

- 32 protocols (sales brain, intelligent follow-up, dual-mode customer service + support, typed knowledge bases, intelligent playbook routing, proactive features suite, weekly + monthly self-tuning, model version freshness, PII scrubbing, prompt-injection protection, conversation analytics, smart booking, discount codes for GHL + Stripe, Shopify integration, and more).
- 8 customer journey templates (coach + all 7 verticals fully detailed: e-commerce, SaaS, service-provider, course-creator, real-estate, consulting, wellness).
- The numbered install scripts (`00`–`24`, OS-aware: Darwin and Linux — including `22-notify-client-doc.sh`, the MANDATORY gated Telegram doc-delivery step, `24-self-test-hook.sh`, the AI BACKEND SELF-TEST blocking gate, and `24-update-tools-md.sh`, which preloads the CLIENT `TOOLS.md` with the verified GHL API quick-reference), plus `skill38-calendar-sync.sh` and the QC linters (`qc-23-key-bodies.sh`, `qc-trinity-registry.sh`, `qc-send-directive.sh`, `qc-conversation-memory.sh`, `qc-playbook-doc.sh`, `qc-notify-client-doc.sh`, `qc-backend-ready.sh`, `qc-reference-sheet.sh`, `qc-config-schema-safety.sh`, `qc-no-personal-data.sh`, `qc-tools-md-ghl-ref.sh`, + the two fixture suites) — **41 `.sh` files total**.
- 17 reference documents under `references/` (deep-dives + the full v6.0 source playbook + the strategic roadmap + the communications-playbook & workflow-AI/Build-with-AI standards + the **Cloudflare & GoDaddy Setup Guide** from School of AI — shipped INSIDE the skill so that when `scripts/00-verify-prerequisites.sh` halts on a missing CF API token per QC-PROTOCOL.md Rule 13, the client can be walked through Cloudflare account creation, GoDaddy nameserver migration, and API token scope selection without leaving the skill folder — plus **VPS-VS-MAC-INSTALL.md**, the VPS-vs-Mac install-considerations reference mirrored into the generated client doc and enforced by `scripts/qc-reference-sheet.sh`, and **ghl-api-quick-reference.md**, the concise verified GHL Convert-and-Flow API request-shape block preloaded into the client `TOOLS.md` by `scripts/24-update-tools-md.sh`).
- AGENTS.md updates (Steps 1.7, 1.8, 1.9, 2.8 added; Step 1.75 upgraded).
- MEMORY.md design rules 6-14.
- 4 cron jobs: Sunday 2am weekly tune-up, Saturday 11pm proactive scan + 11:30pm model freshness, 1st-of-month comprehensive review.

## Prerequisites (ALL required)

This skill REFUSES to install until all 4 prerequisites are satisfied. The `00-verify-prerequisites.sh` script enforces this at the start.

1. **Skill 05 — GHL Setup** — GHL account + API access (`GHL_API_KEY`, `GHL_LOCATION_ID`).
2. **Skill 10 — GitHub Setup** — latest version. Do NOT auto-update; this skill verifies it's installed and current, and tells the operator to update skill 10 first if it's outdated.
3. **Skill 19 — Humanizer** — used ALWAYS-ON by this skill (per playbook Step 9.21). This skill does NOT ship its own humanizer; it references skill 19.
4. **Skill 29 — GHL Convert and Flow** — Convert and Flow installed AND connected to the operator's GHL location.

## What this does NOT do

- Does NOT install or modify skills 05, 10, 17, 18, 19, 29, 31.
- Does NOT replace skill 29. Skill 29 is the GENERIC GHL Convert and Flow setup; skill 38 is the conversational AI BRAIN that USES skill 29's workflow engine in unique ways (3-layer architecture in Step 9.20: Layer 0 routing check, Layer 1 GHL side with auto-tag + Workflow AI prompt + verification checklist, Layer 2 OpenClaw playbook).
- Does NOT implement pending roadmap features (F14 Voice, F15 Proactive Outreach Campaigns, F16 A/B Testing, F17 Segmentation, F18 Webhook Chaining, F21 Multi-Tenant Isolation).
- Does NOT auto-update primary models. Model freshness checks SUGGEST; operator approves YES/NO/DEFER per model.
- Does NOT generate discount codes outside per-product policy.

## Estimated install time

60-90 minutes per the v6.0 playbook (see `references/v6.0-source-playbook.md` for the full Phase-by-Phase walkthrough). The install scripts handle the mechanical parts; INSTRUCTIONS.md walks the operator through the interactive parts (model selection wizard, master files folder discovery, Notion playbook scaffolding, etc.).

## Install order (run the scripts in this order; each is idempotent)

```bash
cd ~/.openclaw/skills/38-conversational-ai-system/scripts

./00-verify-prerequisites.sh         # checks skills 05, 10, 19, 29
./01-locate-master-files-folder.sh   # Step O.2 semantic discovery
./02-create-knowledgebases.sh        # Step 9.22 four typed bases
./03-create-journey-templates.sh     # Step 9.28 customer journey templates
./04-register-crons.sh               # Sun 2am + Sat 11pm + 1st-of-month
./05-update-agents-md.sh             # Steps 1.7-1.9, 2.8, upgrade 1.75
./06-append-memory-rules.sh          # MEMORY.md design rules 6-14
./24-update-tools-md.sh              # preload TOOLS.md w/ verified GHL API quick-reference (core context)
./07-stripe-setup-wizard.sh          # Step 9.27 (operator opt-in)
./08-shopify-setup-wizard.sh         # Step 9.31 (operator opt-in)
```

> `24-update-tools-md.sh` is a **core-file updater** (it preloads the CLIENT agent's
> `TOOLS.md` with the verified, concise GHL Convert-and-Flow API quick-reference — exact
> method/URL/3 headers/body/scope per operation), so it runs in the same wave as the other
> core-file updaters (`05-update-agents-md.sh`, `06-append-memory-rules.sh`). It is idempotent
> (skips if the marker block is already present), universal (placeholders only — zero
> personal/client data), and machine-enforced by `scripts/qc-tools-md-ghl-ref.sh` (wired into
> Step 11 QC + CI). WHERE/WHY: the shapes go in TOOLS.md (WHERE-THINGS-LIVE), not AGENTS.md
> (WHAT-TO-DO). Source of truth: `references/ghl-api-quick-reference.md`.

After scripts run, follow INSTRUCTIONS.md for the interactive Phases 0-7 of the v6.0 playbook (Cloudflare tunnel creation, hook mappings configuration, Notion playbook scaffolding, channel-specific tone configuration, QC handoff).

## OS support

`darwin` (Mac mini operators) and `linux` (VPS operators). All scripts detect OS at runtime via `uname -s` and use OS-appropriate paths:

- **Darwin:** `$HOME/.openclaw/`, `$HOME/clawd/`
- **Linux:** `/data/.openclaw/`, `/data/clawd/`

## Where to read next

- `INSTRUCTIONS.md` — the operator-facing v6.0 walkthrough (Phase 0 through Phase 7).
- `protocols/` — the 32 protocol files, verbatim from the source playbook.
- `references/v6.0-source-playbook.md` — the full 9,483-line source playbook (canonical source of truth).
- `references/conversational-ai-strategic-roadmap.md` — strategic context (✅ shipped vs 📋 pending).
