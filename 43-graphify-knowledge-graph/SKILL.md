---
name: graphify-knowledge-graph
description: Maps the client's OWN codebase + AI workforce into a persistent, queryable knowledge graph (god nodes, community detection, query/path/explain). Installs graphify on the client box, registers the OpenClaw skill, wires /graphify into the agent's AGENTS.md, and installs the FREE AST auto-rebuild git hook. The heavy semantic pass is on-demand (owner-triggered); the AST rebuild is free + automatic. Uses the CLIENT'S OWN model (their Ollama / configured model) — never operator keys.
triggers:
  - "graphify"
  - "/graphify"
  - "map my workforce"
  - "build a knowledge graph"
  - "how does my codebase fit together"
  - "what calls this"
  - "trace the data flow"
  - "set up graphify"
version: 1.0.0
---

# Skill 43: Graphify Knowledge Graph

## MANDATORY - Teach Yourself Protocol (TYP)

**Before using this skill, complete the Teach Yourself Protocol (Skill 01) on this folder.**

Required read order:
1. SKILL.md (this file) — overview, what it ships, the on-demand vs. automatic split
2. INSTALL.md — one-time setup: install graphify, register skill, wire AGENTS.md, install the free hook, map the workforce ONCE
3. INSTRUCTIONS.md — runtime guide: how the agent answers codebase/workforce questions FROM THE GRAPH
4. CORE_UPDATES.md — what gets appended to AGENTS.md + TOOLS.md + MEMORY.md
5. EXAMPLES.md — worked, copy-pasteable example flows (UNIVERSAL placeholders only)
6. CHANGELOG.md — version history

Per N3 ("read before act"), do not skip. Per N4, follow steps in declared order.

## Governing protocol (binding for this skill and all skills in the repo)

This skill is governed by ../QC-PROTOCOL.md (repo root) — the Sub-Agent Handoff and Mandatory QC Protocol. Every install, every PR, every multi-file change runs the 10-category QC rubric (8.5 threshold) BEFORE declaring done. Sub-agents receive full instructions (never summaries). See QC-PROTOCOL.md Part 5 for the sub-agent contract.

## What This Skill Is

**Skill 43 is the Graphify Knowledge Graph** — it turns the client's OWN code, docs, and AI workforce into a navigable, queryable knowledge graph with **god nodes**, **community detection**, and `query` / `path` / `explain` tools. Where Skill 23 (AI Workforce Blueprint) *builds* the client's departments and roles, Skill 43 lets the agent **SEE** how all of it connects — surfacing cross-department relationships and gaps the owner wouldn't think to ask about.

Three outputs land in `graphify-out/`:
- `graph.html` — interactive visual graph
- `graph.json` — GraphRAG-ready data the agent queries
- `GRAPH_REPORT.md` — plain-language report (communities, god nodes, audit trail)

The graph carries an **honest audit trail** (every edge tagged `EXTRACTED` / `INFERRED` / `AMBIGUOUS`), so the agent never passes off an inference as a fact.

## The two-speed model (READ THIS — it is the core of the skill)

graphify has two extraction passes with very different costs:

| Pass | What it does | Cost | When it runs |
|---|---|---|---|
| **AST (structural)** | Parses code files, extracts symbols/calls/imports deterministically | **FREE** (no LLM) | **AUTOMATIC** — the post-commit git hook re-runs it after every commit |
| **Semantic (LLM)** | Reads docs/personas/SOPs, infers relationships, names communities | Costs tokens on the **CLIENT'S OWN model** | **ON-DEMAND ONLY** — owner-triggered (`/graphify`) |

So: the cheap structural graph stays fresh by itself for free; the expensive semantic enrichment is run **only when the owner asks for it**. This skill NEVER schedules an automatic semantic re-build and NEVER spends operator tokens.

## CLIENT'S OWN MODEL — never operator keys

The semantic pass uses **the client's own model** — their Ollama (default `deepseek-v4-pro:cloud`) or whatever model their box is configured with. Concretely, the heavy pass is invoked as:

```bash
graphify <path> --backend ollama --model deepseek-v4-pro:cloud
```

This skill NEVER falls back to operator API keys for a client's graph. If the client has no usable model, STOP and tell the owner — do not substitute an operator key. (See NO-COMINGLING-RULE.md / AGENTS.md N29.)

## What it maps (mapped ONCE at install)

At install time the agent maps the client's OWN workforce exactly once:
- the client's `workspace/` (AGENTS.md, departments, role workspaces, personas, SOPs)
- the client's skills folder (their installed `NN-slug/` skills)

After that one-time map, the free AST hook keeps the structural layer fresh on every commit; the owner re-runs the semantic pass via `/graphify` whenever they want a deeper re-read.

## Relationship to other skills

- **Skill 23 (AI Workforce Blueprint)** — Skill 43 is the *lens* over what Skill 23 *builds*. It does NOT modify Skill 23. After Skill 23 builds the departments, Skill 43 maps them so the agent can answer "which department owns X?" / "what feeds the Command Center?" from the graph.
- **Skill 32 (Command Center)** — the graph is a complementary view: the Command Center is the operational dashboard; the graph is the structural/relationship map of the same workforce.
- It is a **sibling** of the standalone domain skills (39, 41, 42): additive, bolts on, never edits the skills it observes.

## What This Skill Ships

```
43-graphify-knowledge-graph/
├── SKILL.md
├── INSTRUCTIONS.md
├── INSTALL.md
├── CORE_UPDATES.md
├── EXAMPLES.md
├── CHANGELOG.md
├── skill-version.txt          # 1.0.0
├── qc-graphify-knowledge-graph.sh
├── scripts/
│   └── verify-graphify-install.sh
└── references/
    └── graphify-commands.md    # the verified CLI surface used by this skill
```

## Privacy & cost guardrails

- **Free by default to keep fresh:** the only automatic work is the FREE AST hook. No cron, no scheduled semantic re-build.
- **Private:** the semantic pass runs on the client's own (local/cloud) model. The client's code/workforce is graphed on their own box with their own model.
- **No operator keys, ever:** see the CLIENT'S OWN MODEL section above and AGENTS.md N29.
- **Honest audit trail:** `INFERRED` / `AMBIGUOUS` edges are labelled — the agent must not present an inference as a fact.
