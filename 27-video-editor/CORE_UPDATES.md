# Skill 27: Video Editor - CORE_UPDATES

## Core .md files this skill is allowed to update

- `AGENTS.md`
- `TOOLS.md`
- `MEMORY.md`

Do NOT update any other core files for this skill unless the user explicitly requests it.

## What to add (exact text)

### AGENTS.md
Add this rule:

```md
## Video QC Rule (Skill 27)
When generating or editing a video:
- Verify the output file exists on disk
- Verify duration and resolution match the target platform spec
- Verify audio is present when the output should contain audio
- If any check fails, treat the run as FAILED and fix before claiming done
```

### TOOLS.md
Add this section:

```md
## Video Skills Suite

### Video Editor (Skill 27)
- Location: `/data/.openclaw/skills/video-editor/`
- Purpose: cut, resize, caption, and assemble videos with repeatable scripts
- Use when: user asks to trim a video, make reels, add overlays, add captions, or export for a platform
```

### MEMORY.md
Add this pointer:

```md
## Video Skills Suite
- Video Editor (Skill 27): `/data/.openclaw/skills/video-editor/`
```
