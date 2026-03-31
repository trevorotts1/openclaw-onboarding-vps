# CORE_UPDATES.md - Book-to-Persona Skill

## Rule: Reference Only - No Full Docs in Core Files
Add concise summaries and file paths only. Never paste full documentation into core files.

---

## Quick Reference - Dependency Installation

**One-line install for all Python packages:**
```bash
pip3 install google-genai numpy pdfplumber pypdf ebooklib aiohttp beautifulsoup4 mobi lxml --break-system-packages
```

**Verify all packages:**
```bash
python3 -c "import google.genai, numpy, pdfplumber, pypdf, ebooklib, aiohttp, bs4, mobi, lxml; print('ALL PASS')"
```

---

## AGENTS.md

**Where:** Add a new section at the bottom of AGENTS.md titled `## Book-to-Persona Skill (Installed)`

**Exact text to add:**
```
## Book-to-Persona Skill (Installed)
Converts any book (PDF/EPUB/MOBI/AZW3) into a dual-purpose persona blueprint.
Pre-built personas already included. Run: gemini status -c coaching-personas to see total count. Pipeline runs on new books only.

Pipeline:
- Phase 1: kimi-k2.5 via api.moonshot.ai/v1 (temp 1.0) → extraction-notes.md
- Phase 2: deepseek/deepseek-v3.2 via OpenRouter → analysis-notes.md
- Phase 3: openai-codex/gpt-5.4 via OpenClaw OAuth → persona-blueprint.md (all 14 sections)
- Content filter fallback: openrouter/moonshotai/kimi-k2.5

Persona Reflex (DEFAULT BEHAVIOR):
Before any professional task, run: gemini search coaching-personas "<task keywords>"
Load returned persona's Task Mode. Execute the task through that methodology.
Skip only if the user explicitly says so.

Key paths:
- Skill: /data/.openclaw/skills/22-book-to-persona-coaching-leadership-system/
- Personas: /data/openclaw-master-files/coaching-personas/personas/
- Router: /data/.openclaw/skills/22-book-to-persona-coaching-leadership-system/PERSONA-ROUTER.md
- Orchestrator: /data/.openclaw/skills/22-book-to-persona-coaching-leadership-system/pipeline/orchestrator.py
- Gemini collection: coaching-personas [run: gemini status -c coaching-personas to get current counts]

To add a new book: follow SOP in MEMORY.md under "Add New Book to Coaching Personas Matrix"

Re-indexing trigger (MANDATORY after adding any new persona):
When a new book persona is added to ~/Downloads/openclaw-master-files/coaching-personas/personas/:
Run: python3 ~/clawd/scripts/gemini-indexer.py
This updates the Gemini embedding index with the new persona.
Do NOT skip this step -- the search will not find the new persona until re-indexed.
```

---

## TOOLS.md

**Where:** Add a new section under model routing titled `## Book-to-Persona - Model Routing and Gemini`

**Exact text to add:**
```
## Book-to-Persona - Model Routing and Gemini
Pipeline model routing:
- Phase 1: moonshot/kimi-k2.5 — MOONSHOT_API_KEY in /data/openclaw/workspace/secrets/.env — endpoint: https://api.moonshot.cn/v1 — temperature MUST be 1.0
- Phase 2: deepseek/deepseek-v3.2-speciale via OpenRouter ONLY (OPENROUTER_API_KEY)
- Phase 3: openai/gpt-5.3-codex via OpenClaw OAuth (ChatGPT subscription)
- Fallback (content filter): OpenRouter moonshotai/kimi-k2.5 for flagged books

Gemini collection: coaching-personas
Setup commands (run once on fresh install):
  gemini collection add /data/.openclaw/skills/22-book-to-persona-coaching-leadership-system/personas --name coaching-personas --mask "**/*.md"
  gemini update
  gemini embed  (takes 3-8 min first time, downloads local model, runs offline after)

Runtime query: gemini search coaching-personas "<task keywords>"
After adding new book: gemini update (no need to re-embed everything)
If stale/broken: gemini cleanup && gemini update && gemini embed

Full pipeline reference: /data/.openclaw/skills/22-book-to-persona-coaching-leadership-system/PIPELINE.md
Full Gemini guide: /data/.openclaw/skills/22-book-to-persona-coaching-leadership-system/GAI-SEARCH-GUIDE.md
```

---

## MEMORY.md

**Where:** Add a new entry under installed skills or at the bottom titled `## Book-to-Persona Persona Library`

**Exact text to add:**
```
## Book-to-Persona Persona Library (Installed [DATE])
- Skill: /data/.openclaw/skills/22-book-to-persona-coaching-leadership-system/
- Pre-built personas (see gemini status -c coaching-personas for count): /data/openclaw-master-files/coaching-personas/personas/
- Gemini collection: coaching-personas [run: gemini status -c coaching-personas to get current counts]
- Source: Available at your onboarding package repo.
- Persona Reflex: query Gemini before every professional task (see AGENTS.md)
- Add new book SOP: see "Add New Book to Coaching Personas Matrix" section in this file
```

---

## SOUL.md

**Where:** Add under the Boundaries section

**Exact text to add:**
```
## Persona Coaching Voice Rule (Added [DATE])
When operating through a persona from the book-to-persona library:
- NEVER use the author's name in the coaching voice
- The author's name appears ONLY inside attribution-flagged direct quotes
- Coaching Mode speaks in the methodology's voice, not the author's identity
- Example: Do not say "As Mel Robbins says..." - say "The 5-second countdown works because..."
```

---

## USER.md

No update required. This skill does not change anything about how you interact with the user directly.

---

## IDENTITY.md

No update required unless you are setting up a persona as your primary operating identity.

---

## HEARTBEAT.md

**Where:** Add under Active Capabilities if this section exists, otherwise skip.

**Exact text to add:**
```
## Persona Reflex - ACTIVE
Gemini collection coaching-personas loaded [run: gemini status -c coaching-personas to get current counts].
Before professional tasks: gemini search coaching-personas "<task>" → load persona Task Mode.
```

---

## What NOT to Add to Core Files
- Do NOT paste PIPELINE.md into AGENTS.md
- Do NOT paste prompt templates into TOOLS.md
- Do NOT paste the 14-section blueprint format into any core file
- Do NOT add API keys to core files
- Core files get: what it is, what it does, where to find details. That is all.

---

## AGENTS.md - Pending Skill Setup Rule

**Where:** Add at the bottom of AGENTS.md

**Exact text to add:**
```
## Pending Skill Setup - Check and Remind
File: /data/.openclaw/skills/.pending-setup.md
If this file exists with entries marked Status: PENDING, proactively remind the user.
When relevant to what they are working on, say: "You have a pending skill setup for [key] - want to add that now?"
When user provides the key: save it to /data/openclaw/workspace/secrets/.env and mark the entry Status: COMPLETE.
Never nag - bring it up once per session max, only when relevant.
```
