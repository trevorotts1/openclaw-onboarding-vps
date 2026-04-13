# OpenClaw Onboarding

**A complete onboarding package for setting up a fully operational OpenClaw agent.**

**Current Version: v8.0.0** — See [CHANGELOG.md](CHANGELOG.md) for what's new.

This repo contains **34 skill folders** (01 through 34, with 13, 33, and 34 archived) plus an install script.

### What's New in v8.0.0 (April 13, 2026) — BlackCEO System Overhaul v3.3
- **Persona runtime loader**: Replaces hardcoded PERSONA_DETAILS with dynamic runtime loading from company-config.json
- **Grade formula updated**: New 40/30/15/15 weighting (Revenue 40%, Mission 30%, Efficiency 15%, Team 15%)
- **company-config.json wired to CEO Board**: CEO Performance Board now reads directly from company configuration
- **Department Browser + Focus view**: New Kanban-style department browser with focused task views at `/ceo-board/[dept]/focus`
- **Task API department filtering**: All task endpoints support department-based filtering
- **SOP creation + Devil's Advocate**: Each department now has SOP templates with built-in Devil's Advocate review
- **303 hardcoded ~/clawd/ paths cleaned**: All paths now use configurable workspace variables
- **All ports standardized to 4000**: Consistent port configuration across all services
- **department-naming-map.json created**: Standardized department naming conventions
- **persona-selection-log template created**: Structured logging for persona selection decisions
- **Anti-staleness guards added**: Automatic detection and refresh of stale configuration data
- **Post-task persona verification**: Validation step confirms persona performance after task completion
- **Memory Wiki integration**: Full integration with OpenClaw Memory Wiki for persistent knowledge

### What's New in v6.0.8 (March 27, 2026)
- **Persona matching per-task**: Personas are no longer statically assigned to departments. They are matched at runtime using a 5-layer alignment check (Company Mission, Owner Values, Company Goals, Department Goals, Task Fit). New `persona-matching-protocol.md` and `persona-categories.json`.
- **Token-in-webhook response**: Skill 32 tunnel token is now returned directly in the webhook HTTP response. No more waiting for Trevor to forward the token. Trevor still receives a Telegram backup notification.
- **cloudflared built into install**: The `create-tunnel.sh` script now installs cloudflared automatically if missing (Mac: `brew`, Linux: `curl`).
- **Role-level governing-personas.md**: Now a reference guide with suggested starting points, not a static persona assignment.

### What's New in v5.5.1 (March 20, 2026)
- **QC Agent Roles** added to all 17 departments - optional quality control agents that report to department heads
- New QC-ROLES-MASTER.md reference document (34KB) covering QC agent responsibilities, workflows, and model selection
- Department-specific QC checklists and validation procedures
- No config changes required for existing clients - purely additive

### Updating Existing Installs
If you already have the onboarding system installed, update to the latest version:

```
curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps-vps/main/scripts/update-skills.sh | bash
```


### What's New in v5.5.0 (March 20, 2026)
- **memory-core switched to Gemini (Skill 31), Cloudflare manual setup added (Skill 32)
- Added client-hostname uniqueness requirement before DNS registration
- Added explicit requirement to verify the free self-hosted memory-core / GitHub path during Command Center setup
- Added 5-layer memory verification requirement for each department workspace

### What's New in v5.4.1 (March 19, 2026)
- **Skill 32: Cloudflare Tunnel Auto-Setup** - New Phase 6b automates domain registration for client Command Centers
- Webhook registration system connects client tunnels to zerohumanworkforce.com subdomains
- Client registry tracking for all active Command Center deployments
- Automated DNS route creation and URL verification

### What's New in v5.4.0 (March 19, 2026)
- **Skill 32: Command Center Setup** - Activates your AI workforce as a live Command Center with persistent department agents, Telegram topics, and a visual Kanban dashboard
- Integration between Skill 23 (AI Workforce Blueprint) and live operation
- 8-phase installation with automated workspace creation and topic binding

### What's New in v5.3.0 (March 19, 2026)
- **Skill 23: AI Workforce Blueprint** - Added department heads (Chief/Head roles) to all 15 existing departments
- **Two new departments:** Research (Chief Research Officer + 3 roles) and Communications (Chief Communications Officer + 3 roles)
- **All 17 departments now presented equally** - Removed the "optional" tier, clients choose which to keep

### What's New in v5.0.3 (March 19, 2026)
- **CRITICAL FIX:** memory.backend must be "builtin" not "gemini" to prevent gateway crash on restart

### What's New in v5.0.2 (March 19, 2026)
- **Client approval UX fixed** — non-interactive runs now explain why approval could not be collected
- **Exact 2-step rerun commands shown** so clients know exactly what to do next
- **Clear no-changes-made messaging** — safer and less confusing for clients

### What's New in v5.0.1 (March 19, 2026)
- **update-skills.sh v3.0** — now works on any client machine with dynamic folder detection
- **Backup protocol built in** — backs up core files and config before updates
- **Approval workflow** — shows a plan and waits for explicit approval before changes
- **Verification step** — confirms the update completed and warns if a restart may be needed
- **Never restarts automatically** — user must trigger /restart manually if required

### What's New in v5.0.0 (March 19, 2026)
- **Skill 31: Upgraded Memory System** - 8-layer architecture (markdown files, improved flush, session indexing, Gemini Embedding 2 search, memory-core auto-capture, Cognee graph knowledge, Obsidian Vault, Wiki System)
- **Skill 14 rewritten:** Google Workspace CLI (gws) replaces google-api.js and gog - single tool for Gmail and Workspace
- **Skill 23 fixed:** AI Workforce Blueprint now properly presents options A, B, C before asking questions
- **Skill 15 fixed:** BlackCEO Team Management now requires real Telegram IDs, not placeholders
- **Legacy retrieval fully replaced** with Google Gemini Embedding 2 across all skills and scripts
- **Onboarding watchdog** added: 10-minute stall detection, never-stop-early, progress reporting every 5 skills
- **Mandatory file reading protocol:** agent must read ALL .md files before installing any skill
- **CONTRIBUTING.md** added: complete checklist for adding/modifying skills
- **MIGRATION.md** added: step-by-step guide for existing Google Embedding 2 users to migrate to Gemini Embedding 2

- Install happens in a strict order
- The agent executes the steps autonomously
- Humans only provide credentials, API keys, 2FA codes, and first time logins when required

---

## Quick Install (Recommended)

Run this one command on the target machine:

```bash
curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash
```

What it does:
1. Downloads the latest onboarding package
2. Copies skills into `~/.openclaw/skills/`
3. Installs Gemini Engine early (required by skill 22 and skill 23)
4. Asks for missing API keys with a skip option (does not block optional skills)
5. Prints the next step

---

## Updating Existing Installs

To update an existing installation to the latest version:

```bash
curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps-vps/main/scripts/update-skills.sh | bash
```

This script will:
- Back up your existing config and core files
- Show you what's changing before applying updates
- Wait for your approval before making changes
- Verify the update completed successfully

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
| 12-openrouter-setup | OpenRouter Setup (last) |
| 13-google-workspace-setup | Google Workspace Setup |
| 14-google-workspace-integration | Google Workspace Integration |
| 15-blackceo-team-management | Team Management |
| 16-summarize-youtube | Summarize YouTube |
| 17-self-improving-agent | Self Improving Agent |
| 18-proactive-agent | Proactive Agent |
| 19-humanizer | Humanizer |
| 20-youtube-watcher | YouTube Watcher |
| 21-tavily-search | Tavily Search |
| 22-book-to-persona-coaching-leadership-system | Book to Persona Coaching Leadership System |
| 23-ai-workforce-blueprint | AI Workforce Blueprint |
| 24-storyboard-writer | Storyboard Writer |
| 25-video-creator | Video Creator |
| 26-caption-creator | Caption Creator |
| 27-video-editor | Video Editor |
| 28-cinematic-forge | Cinematic Forge |
| 29-ghl-convert-and-flow | GHL Convert and Flow |
| 30-fish-audio-api-reference | Fish Audio API Reference |
| 31-upgraded-memory-system | Upgraded Memory System |
| 32-command-center-setup | Command Center Setup |
| 33-department-heads | Department Heads |

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
