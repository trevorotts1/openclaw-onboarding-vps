# OpenClaw Onboarding — Hostinger Docker VPS

> **Version:** see `/version` - this repo at v10.16.37.
> Every release MUST agree across the version-tracked files; run `./scripts/bump-version.sh vX.Y.Z` to update them atomically. Drift is caught in CI (`.github/workflows/version-consistency.yml`).
>
> **NOTE (v10.16.37) — TYP hardening: explicit storage path, pointer format, mandatory no-paste rule.** `01-teach-yourself-protocol` INSTRUCTIONS.md and the full doc (Section 13 + Section 17) now specify the canonical VPS storage path (`/data/.openclaw/master-files/<subfolder>/`), mandatory pointer format (full path + "when to go deeper"), and a non-negotiable no-paste rule: long docs are NEVER pasted into bootstrap files. `AGENTS.md` carries a short mandatory TYP rule so every agent reads it on session start. TYP skill-version.txt → v6.5.7. Per-release version history lives in [CHANGELOG.md](CHANGELOG.md). CI (`version-consistency.yml`) proves all nine version markers agree.
>
> **What is actually shipped on `main` right now:**
> - **Skill 38 (Conversational AI System) → v1.5.12** (its own `skill-version.txt` is on an independent track and is NOT one of the eight repo-version locations). Live `SKILL.md` self-counts: **protocols/=45, scripts/=68, references/=20, journey templates=8**. The **Round-2 backlog (v1.5.7 → v1.5.12)** added six features, all **default-OFF** (opt-in; the installer never flips them ON): **F21 Multi-Tenant Agent Isolation** (Step 9.44 / AGENTS Step 0.8), **F17 Customer Segmentation Awareness** (Step 9.45 / AGENTS Step 1.85), **F15 Proactive Outreach Campaigns** (Step 9.46 / cron+event-driven, no AGENTS step), **F16 A/B Testing of Reply Variants** (Step 9.47 / AGENTS Step 1.87), **F14 Voice/Phone Integration** (Step 9.48 / `VOICE_PHONE_PIPELINE` marker + setup wizard), and **F18 Webhook Chaining** (Step 9.49 / AGENTS Step 2.9). Each ships its protocol + a `qc-*.sh` gate + a `qc-*.test.sh` negative test. The earlier v1.5.4 → v1.5.6 wave (F47 Smart FAQ + F45 Geo-Qualification deep-fix, F46 Conversational CRM Field Write reconcile, ZHC Tag-Prefix Rule QC fix) remains shipped.
> - **Skill 39 — Real Estate Playbook & Property Intelligence** (present on `main`).
> - **Skill 40 — ZHC Public Records Scraper**, now on the canonical tiered build (ported from the canonical repo) with raw-PII logging killed.
> - **41 numbered skill folders total** (01–41), with **13, 33, 34 archived**. See the Skill Inventory table below for the live list.
>
> **After every release:** `git tag vX.Y.Z && git push --tags && gh release create vX.Y.Z --notes-from-tag` so the GitHub Releases page mirrors the CHANGELOG.

---

## 🔴 READ THIS FIRST — Deployment Models & Install Path (v10.16.37)

OpenClaw on a Hostinger VPS ships in **two deployment models**. The install path is different for each. The installer auto-detects which one you have, but you should know the difference.

### Model A — Containerized (the standard, what 99% of clients have)

Deployed via **hPanel → VPS → Docker Manager → Catalog → OpenClaw** (the one-click template). OpenClaw runs entirely INSIDE a Docker container; the bare host has no `/data`, no `openclaw` CLI, no `node`/`pip3`. The container bind-mounts `/docker/<project>-<suffix>/data` from the host → `/data` inside the container.

**You'll know you have Model A if:** `docker ps` on the host shows a container named like `openclaw-xxxx-openclaw-1`, AND `ls /data` on the host returns "No such file or directory".

### Model B — Bare-metal (rare, custom installs)

OpenClaw installed directly on the host filesystem at `/data/.openclaw/`. No Docker container in the picture.

### Install command — same line, both models

```
ssh root@YOUR.VPS.IP
curl -fSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash
```

The script auto-detects the model and does the right thing. On **Model A** it re-executes itself inside the OpenClaw container as user `node` (because `/data` only exists in there). On **Model B** it runs as normal on the host. On a Model A box where the auto-detect can't reach the container (paused, renamed, etc.), the script **HARD FAILS** rather than silently installing to the wrong place.

### Optional — explicit `docker exec` (for users who want to be deliberate)

If you'd rather skip the auto-detect and target the container yourself:

```
ssh root@YOUR.VPS.IP
docker exec -u node -i <openclaw-container-name> bash -c \
  'curl -fSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash'
```

Find the container name with `docker ps | grep openclaw`.

### Override env vars (Model A edge cases)

| Variable | Purpose |
|---|---|
| `OPENCLAW_NO_CONTAINER_REEXEC=1` | Disable auto-detect entirely (force host install) |
| `OPENCLAW_CONTAINER_NAME=<name>` | Target a specific container (e.g. custom-renamed) |
| `OPENCLAW_CONTAINER_USER=<user>` | Override the user to exec as (defaults to container's `Config.User`, then `node`) |

### Known edge cases — read first

The Hostinger `hvps-openclaw:latest` image lacks some Linux utilities most distros ship by default (`unzip`, `wget`, `lsof`). install.sh has fallbacks for all of them, but the warning lines in the install log will mention them. **See [`INSTALL-GOTCHAS.md`](./INSTALL-GOTCHAS.md) for the full list** — including the schema-strict `channels.telegram` block, the gateway "Service: systemd user (disabled)" status that's misleading inside a container, and the `operator.admin` scope-approval flow that needs owner consent.

### Pre-install safety (recommended for client installs)

Before running the install on a production client VPS, take a snapshot. This is free, fast, and gives you instant rollback:

```
# On the host, NOT in the container:
docker commit <openclaw-container> <client>-pre-v10.14.18
cd /docker/<project>-<suffix> && tar -czf /root/<client>-data-pre-v10.14.18.tar.gz data/
```

If the install goes sideways:

```
docker stop <openclaw-container> && docker rm <openclaw-container>
# Then re-run from the snapshot tag using the same args, OR restore the tarball.
```

---


**A complete onboarding package for setting up a fully operational OpenClaw agent on Hostinger's hvps-openclaw Docker container.**

**Current Version:** see `/version` (currently **v10.16.37**) — see [CHANGELOG.md](CHANGELOG.md) for the full release history.

This repo is **Hostinger Docker VPS-only**. The Mac mini installer lives at https://github.com/trevorotts1/openclaw-onboarding.

This repo contains **41 numbered skill folders** (01 through 41), of which **3 are archived** (13, 33, 34). See the [Skill Inventory](#skill-inventory-folder-names) below for the live list, plus an install script and an update script.

> **First time installing or updating?** Read **[ONBOARDING-TRIGGERS.md](ONBOARDING-TRIGGERS.md)** — it shows exactly how to start a fresh install or run an update via Terminal or Telegram.


### Release history

The full per-version changelog — every release from v6.x through the current v10.16.x line — lives in **[CHANGELOG.md](CHANGELOG.md)**. This README advertises only the LIVE state of `main`; it is no longer a running version-history log.

---

## Quick Install (Recommended)

Run this one command on the target machine:

```bash
curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding/main/install.sh | bash
```

What it does:
1. Downloads the latest onboarding package
2. Copies skills into `~/.openclaw/skills/`
3. Installs Gemini Engine early (required by skill 22 and skill 23)
4. Asks for missing API keys with a skip option (does not block optional skills)
5. Prints the next step

---

## Next Step After Install

Open:

- `~/.openclaw/skills/Start Here.md`

That file is the master instruction file. It contains:
- prerequisites
- exact skill install order
- the required file read order per skill
- verification rules
- what to do on failures

---

## Skill Inventory (Folder Names)

| Folder | Skill |
|--------|-------|
| 01-teach-yourself-protocol | Teach Yourself Protocol |
| 02-back-yourself-up-protocol | Back Yourself Up Protocol |
| 03-agent-browser | Agent Browser |
| 04-superpowers | Superpowers |
| 05-ghl-setup | GHL Setup |
| 06-ghl-install-pages | GHL Install Pages |
| 07-kie-setup | KIE Setup |
| 08-vercel-setup | Vercel Setup |
| 09-context7 | Context7 Setup |
| 10-github-setup | GitHub Setup |
| 11-superdesign | Superdesign |
| 12-openrouter-setup | OpenRouter Setup |
| 13-google-workspace-setup-ARCHIVED | Google Workspace Setup (ARCHIVED — replaced by skill 14) |
| 14-google-workspace-integration | Google Workspace Integration |
| 15-blackceo-team-management | BlackCEO Team Management |
| 16-summarize-youtube | Summarize YouTube |
| 17-self-improving-agent | Self-Improving Agent |
| 18-proactive-agent | Proactive Agent |
| 19-humanizer | Humanizer |
| 20-youtube-watcher | YouTube Watcher |
| 21-tavily-search | Tavily Search |
| 22-book-to-persona-coaching-leadership-system | Book-to-Persona Coaching Leadership System |
| 23-ai-workforce-blueprint | AI Workforce Blueprint |
| 24-storyboard-writer | Storyboard Writer |
| 25-video-creator | Video Creator |
| 26-caption-creator | Caption Creator |
| 27-video-editor | Video Editor |
| 28-cinematic-forge | Cinematic Forge |
| 29-ghl-convert-and-flow | GHL Convert and Flow (Tier 3 API reference for skill 36) |
| 30-fish-audio-api-reference | Fish Audio API Reference |
| 31-upgraded-memory-system | Upgraded Memory System |
| 32-command-center-setup | Command Center Setup |
| 33-department-heads-ARCHIVED | Department Heads (ARCHIVED) |
| 34-intelligent-staffing-ARCHIVED | Intelligent Staffing (ARCHIVED) |
| 35-social-media-planner | Social Media Planner — FFmpeg ≥4.0 + kie.ai key required. Routes GHL operations through skill 36 MCPs when installed. |
| 36-ghl-mcp-setup | **GHL MCP Setup** — 5-tier GHL access chain: Official MCP (36 tools) → Community MCP (588 tools) → REST API (skill 29) → Playwright → Codex Computer Use. Sets `$GHL_COMMUNITY_MCP_URL`, installs launchd plist (macOS), wires cardinal rules into SOUL.md/AGENTS.md/TOOLS.md/MEMORY.md, includes 20-assertion QC script. |
| 37-zhc-closeout | **ZHC Closeout** — the zero-human-company build-completion sequence: closeout infographics + celebration video, the 9-section Notion page tree (in the client's own workspace), the Telegram closeout sequence, Skill 32 Command Center fire, and n8n wire-up. |
| 38-conversational-ai-system | **Conversational AI System (Skill 38 v1.5.12)** — the conversational AI BRAIN on top of skill 29 (GHL Convert and Flow). Live tree: **45 protocols / 68 scripts / 20 references / 8 customer-journey templates** (sales brain, intelligent follow-up, dual-mode customer service + support, typed knowledge bases, intelligent routing, weekly + monthly self-tuning, model version freshness, plus the F4x/F5x feature set incl. inline smart-FAQ, geo-qualification, conversational CRM field write/create, ZHC tag-prefix rule, and the **Round-2 backlog — all default-OFF**: F21 Multi-Tenant Agent Isolation, F17 Customer Segmentation Awareness, F15 Proactive Outreach Campaigns, F16 A/B Testing of Reply Variants, F14 Voice/Phone Integration, F18 Webhook Chaining, each with its own `qc-*.sh` gate + `qc-*.test.sh` negative test). Idempotent OS-aware install scripts. Sunday 2am + Saturday 11pm + 1st-of-month crons. Skills 05/10/19/29 required as prerequisites. (`skill-version.txt` `1.5.12` is on an independent track — NOT one of the 9 repo-version locations.) |
| 39-real-estate-playbook | **Real Estate Playbook & Property Intelligence (v10.16.37)** — the real-estate VERTICAL brain on top of skill 38 + skill 29. Provider-abstracted property lookup (operator-supplied keys; NEVER fabricates property data — honest-gap when absent), address normalization + geocoding, Street View image generation, comps/CMA, buyer/seller/investor qualification, showing scheduler (lockbox/MLS), state disclosure compliance pointers, lead routing by specialty, open-house automation, pre-foreclosure outreach (pairs w/ skill 40). RE tags `ZHC-buyer-lead`/`ZHC-seller-lead`/`ZHC-investor-lead`/`ZHC-pre-foreclosure-prospect`. ADDITIVE Sales-Brain extension into skill 38's `protocols/extensions/` (skill 38 core untouched). Emits `<MASTER_FILES_DIR>/real-estate-events.jsonl` (F52 contract). 7 scripts + 7 protocols + 3 references. Skills 29 + 38 required (hard). |
| 40-zhc-public-records-scraper | **ZHC Public Records Scraper (v10.16.37)** — tiered public-records engine: **Tier 1** 21 curated major-county configs (Cook IL, LA, Maricopa AZ, Harris TX, San Diego, Orange CA, Miami-Dade, Kings NY, Dallas, King WA, Clark NV, Santa Clara, Tarrant, Riverside, Wayne MI, Broward, Bexar, Sacramento, San Bernardino, Hillsborough, Pierce — `references/tier1-counties/*.json`); **Tier 2** platform-adapter framework (1 adapter/vendor — Tyler + GovOS examples); **Tier 3** operator-buildable validated scraper configs; **Tier 4** HONEST GAP (no source/blocked → told to operator, never fabricated). Auto-detect address/ZIP → county+state → tier. Respects robots.txt + ToS, attributes source + timestamp, per-day/per-target rate limits + daily cost cap + cost estimate before bulk ops, 30-day cache. Pairs w/ skill 39 (pre-foreclosure/NOD/tax-delinquency). Emits `<MASTER_FILES_DIR>/public-records-queries.jsonl` (F52 PII-free contract: opaque query_ref/target_ref, record TYPES + counts only). Install scripts 00-07 + 3 helper libs + 3 QC gates + 2 adapters + 4 protocols. `jq` + `curl` required (runtime). |
| 41-build-with-ai-playbook | **Build With AI Playbook Generator (v10.16.37)** — generates GoHighLevel "Build With AI" conversation playbooks: dependency-ordered build steps, webhook/trigger configuration, prompt-completeness + no-fabrication + no-personal-data + zhc-tag-prefix QC gates (each with a passing negative self-test), and OS-aware (uname -s) install scripts. Templates + protocols for repeatable, verified GHL workflow generation. Installer scripts 00-04 run at client-install time only. |

**Total: 41 numbered skill folders** (01–41) — **38 active + 3 archived** (13, 33, 34).

> **Note:** The Voice Call Plugin (`@openclaw/voice-call`) is installed separately via `openclaw plugins install @openclaw/voice-call`. It is NOT part of the onboarding skill sequence — installing it as a skill caused double-install conflicts.

---

## What Is Inside a Skill Folder

Each skill folder contains a subset of these files:
- `SKILL.md`
- `INSTALL.md`
- `INSTRUCTIONS.md`
- `EXAMPLES.md`
- `CORE_UPDATES.md`
- `*.skill` (the OpenClaw install descriptor)

Some skills also include:
- `*-full.md` (a full reference guide)
- `upstream-original/` (for imported skills)
- `scripts/`, `templates/`, `references/`

---

## Notes

- Gemini Engine is installed by `install.sh` before platform skills. There is no separate Gemini Engine skill folder.
- If you fork this repo for client delivery, update `install.sh` to point at your fork.
