# CORE_UPDATES.md

## Rule: TYP-Lean Format
Add concise summaries and file paths only. Never paste full documentation into core files.

---

## AGENTS.md snippet

**[ADD TO AGENTS.md]**

```
## Summarize Skill (YouTube Transcript + Summary)
- Installed summarize via Homebrew (`steipete/tap/summarize`)
- Keys: discovered from ~/clawd/secrets/.env, ~/.openclaw/.env, or ~/.config/openclaw/.env
- Key order: OPENAI_API_KEY first, GEMINI_API_KEY fallback (--provider gemini)
- Missing keys are skippable per provider - skill continues with available provider(s)
- Full install reference: ~/Downloads/openclaw-master-files/16-summarize-youtube-full.md
```

---

## TOOLS.md snippet

**[ADD TO TOOLS.md]**

```
## summarize CLI
- Install: `brew install steipete/tap/summarize`
- Summary (OpenAI): `OPENAI_API_KEY="$OPENAI_API_KEY" summarize "https://youtu.be/VIDEO_ID" --youtube auto`
- Summary (Gemini): `GEMINI_API_KEY="$GEMINI_API_KEY" summarize "https://youtu.be/VIDEO_ID" --youtube auto --provider gemini`
- Transcript: `summarize "https://youtu.be/VIDEO_ID" --youtube auto --extract-only`
- Key discovery order: ~/clawd/secrets/.env → ~/.openclaw/.env → ~/.config/openclaw/.env
- Full reference: ~/Downloads/openclaw-master-files/16-summarize-youtube-full.md
```

---

## MEMORY.md snippet

**[ADD TO MEMORY.md]**

```
## Installed: summarize tool
- summarize CLI installed via Homebrew
- Keys loaded from env discovery (~/clawd/secrets/.env or ~/.openclaw/.env)
- OpenAI-first with --provider gemini fallback confirmed working
- Transcript extraction confirmed working
- Full reference: ~/Downloads/openclaw-master-files/16-summarize-youtube-full.md
```
