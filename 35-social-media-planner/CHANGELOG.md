# Changelog - Social Media Planner (Skill 35)

## v2.2.0 - June 8, 2026 (Fix #1 + Fix #2 — connection-status truth + cron enforcement)

### Why
Two runtime bugs caused direct client harm:
1. **Connection-status hallucination** — the agent reported "nothing is connected" (or named specific platforms as connected/disconnected) based on vault contents or memory instead of running a live GHL Social Planner query. A client had channels live in GHL but was told they were disconnected.
2. **Weekly theme question silently skipped** — the Saturday 8 AM theme request was driven solely by HEARTBEAT.md prose. Heartbeat timing drifts; the prompt silently never fired for at least one client.

### What
- **INSTRUCTIONS.md** — Added two new enforcement sections:
  - `## Reporting connection status — LIVE GHL CHECK ONLY (no guessing)` — bans assumptions; mandates a live GHL Social Planner API call via `check-social-connections` step before any connection-status statement. Clarifies that GHL is the PRIMARY publishing path, and that direct-platform tokens / Fish Audio / Skill 30 are all OPTIONAL and never block Skill 35.
  - `## Weekly trigger — CRON, not heartbeat (enforcement)` — mandates the weekly content-theme question and plan run are driven by `openclaw cron add` (gateway cron store), not heartbeat checklist. Documents the `skill35-weekly-theme` cron (Saturday 8:00 AM, `0 8 * * 6`), VPS-safe cron registration pattern (matching Skill 38's `04-register-crons.sh`), and state/marker file for idempotency. Supersedes INSTALL.md Step 9 (HEARTBEAT.md entry) as the timing authority.
- **scripts/register-weekly-cron.sh** (new) — idempotent shell script that registers the `skill35-weekly-theme` cron via `openclaw cron add` and validates config afterward. Exits 0 if already registered.
- **qc-skill35.sh + qc-social-media-planner.sh** — new Section I with 3 assertions: (1) live-GHL connection-status rule present in INSTRUCTIONS.md, (2) cron enforcement text present in INSTRUCTIONS.md, (3) `register-weekly-cron.sh` exists.

### Risk
Low. Changes are additive (new sections in INSTRUCTIONS.md, new script, new QC assertions). No existing behavior removed. The HEARTBEAT.md Saturday entry installed by INSTALL.md Step 9 remains as a fallback acknowledgement — only the timing authority is transferred to the cron.

---

## v2.1.0 - May 24, 2026 (Track M — closes v10.14.33 gap)

### Added — the three trigger paths INSTRUCTIONS.md has always referenced
- `scripts/run-publishing-cycle.sh` — single-topic orchestrator with full
  `--topic / --platforms / --schedule / --dry-run / --help` interface.
  Validates pre-reqs (SOUL/IDENTITY/USER/secrets, Skills 22/31), detects
  whether the 21-agent roster (15 producers + 6 QC) is configured in
  `openclaw.json`, and either prepares the per-phase workdir +
  `cycle-manifest.json` for the master orchestrator OR emits a clear
  "run Skill 23 build-workforce with the social-media-planner role-bundle"
  next-step message.
- `scripts/weekly-batch.sh` — cron-driven (`0 9 * * 1`) batch runner.
  Reads `~/.openclaw/config/content-calendar.json`, filters entries to
  the current Monday-Sunday window, invokes `run-publishing-cycle.sh`
  once per topic. Logs to `/tmp/skill-35-weekly-<date>.log`. Exits 0 with
  an informational message if the calendar file is absent.
- `scripts/content-calendar.example.json` — starter template documenting
  the schema (`{version, entries: [{date, topic, platforms, schedule}]}`).
- INSTALL.md — Step 8 new section documenting the content-calendar
  schema and the example template.

### Why
INSTRUCTIONS.md `## How to trigger this skill` has referenced these three
paths since v10.12.0, but the scripts themselves never existed. Skill 35
was installed on all 8 client boxes but unusable end-to-end. This PR
closes the gap.

### Companion change
Dashboard repo (`blackceo-command-center`) — separate PR for the
Marketing-department "Publish" button + `/api/skill-35/publish`
endpoint that queues a cycle and emits an SSE event.

---

## v1.4.0 - April 14, 2026

### Added/Updated
- Complete video production pipeline: kie.ai Veo 3.1 Lite generation + FFmpeg crossfade transitions and spec conformance (1080x1920, 9:16, H.264/AAC/30fps)
- Expanded to 8 platforms for video posts: Facebook, Instagram, LinkedIn, YouTube, TikTok, Pinterest, Threads, X (Twitter)
- HTML email newsletters with embedded images/links
- Scaled production to 15 sub-agents + 6 dedicated QC agents
- Podbean podcast publishing webhook integration
- FFmpeg for all video post-processing (crossfades, specs, optimization)

## v1.3.0 - April 13, 2026

### Changed
- Updated all webhook payload examples to use explicit variable references from identity.md
- Google Sheet webhook: `brandName` now references "[from identity.md: brand name]"
- Google Sheet webhook: `clientEmail` now references "[from identity.md: owner email]"
- Skill 32 tunnel webhook: `clientName` now references "[company slug from identity.md, lowercase, no spaces]"
- Skill 32 tunnel webhook: `companyName` now references "[from identity.md: company display name]"
- Skill 32 tunnel webhook: `contactEmail` now references "[from identity.md: owner email]"

### Added
- Full Podbean Podcast Publishing webhook documentation in CORE_UPDATES.md TOOLS.md section
- Detailed payload example for podcast publishing with all required fields
- Google Sheet Creation Webhook section with payload documentation

## v1.1.0 - April 13, 2026

### Changed
- Google Sheet creation now uses n8n webhook instead of Google Workspace API
- Webhook endpoint: `POST https://main.blackceoautomations.com/webhook/social-planner-sheet-create`
- Fields: `brandName`, `clientEmail`
- Response: `sheetUrl`, `sheetId`, `sheetName`
- No client credentials required for sheet creation
- Added Google Sheet Verification checklist to QC.md

## v1.0.0 - April 13, 2026

Initial release.

- 7-part weekly content series across Facebook, Instagram, LinkedIn, YouTube, TikTok, Pinterest
- Television Show Framework with pitch intensity scaling (4/10 to 10/10 over 7 days)
- 8 parallel sub-agents for content production
- 40+ item QC checklist across 8 categories (text, comments, images, scheduling, blog, podcast, audio, video)
- GoHighLevel (Convert and Flow) Social Planner API integration using Private Integration Token
- Image generation via kie.ai Nano Banana 2 at platform-correct ratios
- Video production via kie.ai Veo 3.1 Lite + FFmpeg merge
- Podcast production via Fish Audio S2 with inline emotion tags (depends on Skill 30)
- Blog post and email newsletter production
- Thursday carousel strategy with cross-platform image reuse (4:5 shared across FB, IG, LinkedIn)
- LinkedIn PDF carousel generation via ImageMagick/Pillow
- Google Sheet logging with 19 worksheets and horizontal 7-day storyboard layout
- Heartbeat-driven weekly theme request (Saturday 8AM, Noon, 6PM, Sunday 7AM)
- First Run Client Setup Protocol (reads core .md files, asks only for missing info)
- Persona integration with 5-layer alignment and client override option
- Memory-core integration for theme tracking, performance logging, and Dreaming insights (depends on Skill 31)
- Complete GHL API request body examples for regular posts, carousels, videos, and comments
- Image + content always bundled in one API call via mediaUrls field
- Comments always posted as separate call 1-2 minutes after parent post with action link
- Teach Yourself Protocol requirement
- Error handling with 3 retries and Telegram > Email > Text notification chain
