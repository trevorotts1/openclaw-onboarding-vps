# Skill 43 — Graphify Knowledge Graph — Changelog

## 1.0.0 — 2026-06-06

Initial release. Ships the Graphify Knowledge Graph as standalone Skill 43.

- Installs graphify on the client box: `uv tool install "graphifyy[all]"` (pip3 `--break-system-packages` fallback for VPS containers; `apt` is a brew shim on Hostinger and is NOT used).
- Registers the OpenClaw skill (`graphify install --platform claw`) and wires `/graphify` into the workspace AGENTS.md (`graphify claw install`) so the agent always checks the graph before answering codebase/workforce questions.
- Installs the FREE AST auto-rebuild git hook (`graphify hook install`) — structural graph stays fresh on every commit at zero token cost.
- Maps the client's OWN workforce ONCE at install using the CLIENT'S OWN model (`graphify . --backend ollama --model deepseek-v4-pro:cloud`, or the client's configured model). NEVER operator keys.
- Two-speed model documented throughout: AST = free + automatic (hook); semantic = on-demand, owner-triggered ONLY, on the client's own model. No cron, no scheduled semantic rebuild.
- Honest audit trail surfaced to the agent: EXTRACTED / INFERRED / AMBIGUOUS edges; never present an inference as a fact (N27).
- No-comingling guardrail wired in: never use an operator key for a client's graph, never map one client's workforce into another's (N29 / NO-COMINGLING-RULE.md).
- Ships SKILL.md / INSTALL.md / INSTRUCTIONS.md / CORE_UPDATES.md / EXAMPLES.md, `references/graphify-commands.md`, `scripts/verify-graphify-install.sh`, and `qc-graphify-knowledge-graph.sh`.
- All content uses universal placeholders only. No client PII, scores, or working artifacts shipped.
