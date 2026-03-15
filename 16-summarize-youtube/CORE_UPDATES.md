# CORE_UPDATES.md

## Rule: TYP-Lean Format
Add concise summaries and file paths only. Never paste full documentation into core files.

---

## AGENTS.md snippet

**[ADD TO AGENTS.md]**

```
## Summarize Skill (YouTube Transcript + Summary)
- Installed summarize via Homebrew (`steipete/tap/summarize`)
- Keys: discovered from /data/openclaw/workspace/secrets/.env, /data/.openclaw/.env, or ~/.config/openclaw/.env
- Key order: OPENAI_API_KEY first, GEMINI_API_KEY fallback (--provider gemini)
- Missing keys are skippable per provider - skill continues with available provider(s)
- Full install reference: /data/openclaw-master-files/16-summarize-youtube-full.md
```

---

## TOOLS.md snippet

**[ADD TO TOOLS.md]**

```
## summarize CLI
- Install: `apt-get install -y steipete/tap/summarize`
- Summary (OpenAI): `OPENAI_API_KEY="$OPENAI_API_KEY" summarize "https://youtu.be/VIDEO_ID" --youtube auto`
- Summary (Gemini): `GEMINI_API_KEY="$GEMINI_API_KEY" summarize "https://youtu.be/VIDEO_ID" --youtube auto --provider gemini`
- Transcript: `summarize "https://youtu.be/VIDEO_ID" --youtube auto --extract-only`
- Key discovery order: /data/openclaw/workspace/secrets/.env → /data/.openclaw/.env → ~/.config/openclaw/.env
- Full reference: /data/openclaw-master-files/16-summarize-youtube-full.md
```

---

## MEMORY.md snippet

**[ADD TO MEMORY.md]**

```
## Installed: summarize tool
- summarize CLI installed via Homebrew
- Keys loaded from env discovery (/data/openclaw/workspace/secrets/.env or /data/.openclaw/.env)
- OpenAI-first with --provider gemini fallback confirmed working
- Transcript extraction confirmed working
- Full reference: /data/openclaw-master-files/16-summarize-youtube-full.md
```
