# Skill 43 — CORE_UPDATES

What this skill appends to the client's workspace core files. Apply once on install.

> Note: `graphify claw install` (INSTALL.md §3) writes its own `## graphify` section
> into AGENTS.md automatically. The block below is the human-readable operating note
> that complements it; if `graphify claw install` already added a section, keep both —
> they do not conflict.

---

## AGENTS.md (append)

```markdown
## Graphify Knowledge Graph (Skill 43)

The Graphify Knowledge Graph is installed at `~/.openclaw/skills/43-graphify-knowledge-graph/`
(VPS: `/data/.openclaw/skills/43-graphify-knowledge-graph/`). The client's OWN workforce
(workspace: departments, roles, personas, SOPs, AGENTS.md) is mapped into a queryable graph
at `<workspace>/graphify-out/graph.json`.

For ANY codebase/workforce question ("which department owns X?", "what feeds the Command
Center?", "trace a lead end-to-end", "what calls Y?"): query the graph FIRST —
`graphify query "<question>"` — do not rebuild. The graph is already built.

Two-speed model:
- The FREE AST hook keeps the structural graph fresh on every `git commit` automatically.
- The semantic (LLM) re-read is ON-DEMAND, owner-triggered ONLY, and runs on the
  CLIENT'S OWN model (their Ollama, e.g. `deepseek-v4-pro:cloud`) — NEVER operator keys.

Honest audit trail: edges are tagged EXTRACTED / INFERRED / AMBIGUOUS. Never present an
inference as a fact (AGENTS.md N27). NEVER use an operator key for a client's graph,
and NEVER map one client's workforce into another client's graph (AGENTS.md N29 /
NO-COMINGLING-RULE.md).
```

## TOOLS.md (append)

```markdown
## Graphify Knowledge Graph (Skill 43)

- Query the graph:     `graphify query "<question>"`
- Path between nodes:  `graphify path "A" "B"`
- Explain a node:      `graphify explain "X"`
- Free structural refresh (no LLM): `graphify update .`   (also automatic via the post-commit hook)
- Deep semantic re-read (owner-triggered, client's OWN model):
    `graphify . --backend ollama --model deepseek-v4-pro:cloud`   # use the client's configured model
- Verify install:      `bash ~/.openclaw/skills/43-graphify-knowledge-graph/scripts/verify-graphify-install.sh`
  (VPS: `/data/.openclaw/skills/43-graphify-knowledge-graph/scripts/verify-graphify-install.sh`)
- Full QC:             `bash ~/.openclaw/skills/43-graphify-knowledge-graph/qc-graphify-knowledge-graph.sh`
```

## MEMORY.md (append — once the workforce is mapped)

```markdown
graphify: workforce mapped | graph at <WS>/graphify-out/graph.json | AST hook ON (free) | semantic = on-demand (client model) | Skill 43
```
