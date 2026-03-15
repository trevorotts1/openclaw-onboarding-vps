# CORE_UPDATES - Self-Improving Agent

## Rule: TYP-Lean Format
Apply updates only to relevant core files for this skill.
Add concise summaries and file paths only. Never paste full documentation into core files.

---

## Relevant (update allowed)
- AGENTS.md
- TOOLS.md
- MEMORY.md

## Optional (only if explicitly needed)
- SOUL.md
- USER.md (update only when this skill needs user preferences or user-specific routing)

## Non-relevant (do not edit)
- IDENTITY.md
- HEARTBEAT.md

---

## Suggested snippets

### [ADD TO AGENTS.md]
- This skill requires TYP to be confirmed installed before execution.
- Trigger: agent learns from mistakes, logs corrections, queries learnings before major tasks.
- Full reference: /data/openclaw-master-files/17-self-improving-agent-full.md

### [ADD TO TOOLS.md]
- Add only tool commands or endpoints this skill uses (e.g., learnings file path, CLI hooks).
- Full reference: /data/openclaw-master-files/17-self-improving-agent-full.md

### [ADD TO MEMORY.md]
- Log: self-improving-agent skill installed.
- Persistent constraints: check .learnings/ before major tasks; log corrections immediately.
- Full reference: /data/openclaw-master-files/17-self-improving-agent-full.md
