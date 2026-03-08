# CORE_UPDATES.md - Book Intelligence Pipeline

## What Goes in Core Files

Add concise summary + reference to each file listed below.
Do NOT dump full documentation into core files.
The summary tells what it is. The reference tells where to find the how-to.

---

## AGENTS.md

Add this block under a "Installed Skills" or "Capabilities" section:

```
## Book Intelligence Pipeline Skill (Installed)
Converts any bestselling book PDF into a dual-purpose persona blueprint - one that coaches
humans through challenges AND governs AI agents executing professional work across departments.
Runs 3-phase sub-agent pipeline: Kimi K2.5 extracts methodology, DeepSeek V3.2-Speciale
analyzes across 12 dimensions, GPT-5.3 Codex (OAuth) synthesizes 14-section blueprint.
Output is QMD-indexed for retrieval. Fallback: if Codex fails, Kimi K2.5 takes Phase 3.
Full documentation: ~/clawd/skills/book-to-persona/
Persona output: [detected-master-files-path]/coaching-personas/personas/
```

---

## TOOLS.md

Add this block under model routing or skills section:

```
## Book Intelligence Pipeline - Model Routing
- Phase 1 (Extraction): moonshot/kimi-k2.5 via Moonshot direct API (MOONSHOT_API_KEY)
- Phase 2 (Analysis): deepseek/deepseek-v3.2-speciale via OpenRouter
- Phase 3 (Synthesis): openai-codex/gpt-5.3-codex via OpenClaw OAuth (ChatGPT subscription)
- Phase 3 Fallback: moonshot/kimi-k2.5 if Codex fails
- Parallelism: 7 books simultaneously, continuous pipeline (each book flows independently)
- Storage: [detected-master-files-path]/coaching-personas/
Full routing reference: ~/clawd/skills/book-to-persona/PIPELINE.md
```

---

## MEMORY.md

Add this block under active projects or installed skills:

```
## Book Intelligence Pipeline - Persona Library
Skill installed at: ~/clawd/skills/book-to-persona/
Persona output at: [detected-master-files-path]/coaching-personas/personas/
QMD collection: coaching-personas (indexes all persona blueprints)
To retrieve a persona at runtime: qmd query "describe [methodology/challenge]"
To run pipeline on new book: trigger Book Intelligence Pipeline skill with PDF path
Full QMD usage: ~/clawd/skills/book-to-persona/QMD-RETRIEVAL-GUIDE.md
```

---

## What NOT to Add to Core Files

- Do NOT paste the full PIPELINE.md into AGENTS.md
- Do NOT paste the full prompt templates into TOOLS.md
- Do NOT paste the 14-section blueprint format into any core file
- Do NOT add model API keys or auth details to core files
- Do NOT add the full book list to core files

The core files get the summary (what it is, what it does) and the path (where to find the rest).
That is all.
