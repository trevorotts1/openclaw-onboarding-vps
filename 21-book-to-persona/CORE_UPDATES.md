# CORE_UPDATES.md - Book-to-Persona Skill

## Rule: Reference Only - No Full Docs in Core Files
Add concise summaries and file paths only. Never paste full documentation into core files.

---

## AGENTS.md

**Where:** Add a new section at the bottom of AGENTS.md titled `## Book-to-Persona Skill (Installed)`

**Exact text to add:**
```
## Book-to-Persona Skill (Installed)
Converts any book (PDF/EPUB/MOBI/AZW3) into a dual-purpose persona blueprint.
40 pre-built personas already included. Pipeline runs on new books only.

Pipeline:
- Phase 1: Kimi K2.5 via direct Moonshot API (api.moonshot.ai/v1, temp 1.0) → extraction-notes.md
- Phase 2: DeepSeek V3.2 via OpenRouter → analysis-notes.md
- Phase 3: OpenAI Codex → persona-blueprint.md (all 14 sections)
- Content filter fallback: OpenRouter moonshotai/kimi-k2.5

Persona Reflex (DEFAULT BEHAVIOR):
Before any professional task, run: qmd search coaching-personas "<task keywords>"
Load returned persona's Task Mode. Execute the task through that methodology.
Skip only if Trevor explicitly says so.

Key paths:
- Skill: ~/clawd/skills/book-to-persona/
- Personas: ~/Downloads/openclaw-master-files/coaching-personas/personas/
- Router: ~/clawd/skills/book-to-persona/PERSONA-ROUTER.md
- Orchestrator: ~/clawd/projects/coaching-personas-matrix/orchestrator.py
- QMD collection: coaching-personas (7,465 vectors)

To add a new book: follow SOP in MEMORY.md under "Add New Book to Coaching Personas Matrix"
```

---

## TOOLS.md

**Where:** Add a new section under model routing titled `## Book-to-Persona - Model Routing`

**Exact text to add:**
```
## Book-to-Persona - Model Routing
- Phase 1: moonshot/kimi-k2.5 — MOONSHOT_API_KEY in ~/clawd/secrets/.env — endpoint: https://api.moonshot.ai/v1 — temperature MUST be 1.0
- Phase 2: deepseek/deepseek-v3.2 via OpenRouter ONLY (OPENROUTER_API_KEY)
- Phase 3: openai/gpt-5.2-codex via direct OpenAI API
- Fallback (content filter): OpenRouter moonshotai/kimi-k2.5 for flagged books
- QMD search: qmd search coaching-personas "<keywords>" — returns persona folder path
Full pipeline reference: ~/clawd/skills/book-to-persona/PIPELINE.md
```

---

## MEMORY.md

**Where:** Add a new entry under installed skills or at the bottom titled `## Book-to-Persona Persona Library`

**Exact text to add:**
```
## Book-to-Persona Persona Library (Installed [DATE])
- Skill: ~/clawd/skills/book-to-persona/
- 40 pre-built personas: ~/Downloads/openclaw-master-files/coaching-personas/personas/
- QMD collection: coaching-personas (7,465 vectors, 447 documents)
- GitHub: https://github.com/trevorotts1/openclaw-onboarding (skill 21-book-to-persona)
- Persona Reflex: query QMD before every professional task (see AGENTS.md)
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

No update required. This skill does not change anything about how you interact with Trevor directly.

---

## IDENTITY.md

No update required unless you are setting up a persona as your primary operating identity.

---

## HEARTBEAT.md

**Where:** Add under Active Capabilities if this section exists, otherwise skip.

**Exact text to add:**
```
## Persona Reflex - ACTIVE
QMD collection coaching-personas loaded (7,465 vectors).
Before professional tasks: qmd search coaching-personas "<task>" → load persona Task Mode.
```

---

## What NOT to Add to Core Files
- Do NOT paste PIPELINE.md into AGENTS.md
- Do NOT paste prompt templates into TOOLS.md
- Do NOT paste the 14-section blueprint format into any core file
- Do NOT add API keys to core files
- Core files get: what it is, what it does, where to find details. That is all.
