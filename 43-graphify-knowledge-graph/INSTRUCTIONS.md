# Skill 43 — INSTRUCTIONS (Runtime Guide)

How the agent uses the knowledge graph to answer codebase / workforce questions at runtime.

---

## 1. Fast path — the graph already exists

Before doing anything else for a codebase/workforce question, check whether the graph exists:

```bash
# from the workspace root
[ -f graphify-out/graph.json ] && echo "graph present" || echo "no graph"
```

If `graphify-out/graph.json` exists AND the request is a natural-language question about the codebase/workforce (e.g. "Which department owns billing?", "What feeds the Command Center?", "Trace a lead from intake to close", "What calls X?"), **query the graph immediately — do NOT rebuild**:

```bash
graphify query "<the owner's question>"
```

The graph is already built — use it. Only rebuild on an explicit rebuild request (`--update`, a bare path, or "re-map").

## 2. The three query verbs

| Verb | Use when | Command |
|---|---|---|
| `query` | broad context — "how does X work", "what feeds Y" | `graphify query "<question>"` |
| `path` | the relationship between two specific things | `graphify path "Sales Dept" "Command Center"` |
| `explain` | a plain-language description of one node + its neighbors | `graphify explain "Billing Specialist"` |

Cap output when you only need a short answer: `graphify query "<q>" --budget 1500`.

## 3. Honest audit trail — NEVER pass an inference as a fact

Every edge in the graph is tagged `EXTRACTED` (read directly from a file), `INFERRED` (the LLM deduced it), or `AMBIGUOUS`. When you answer from the graph:

- State `EXTRACTED` facts plainly.
- Flag `INFERRED` / `AMBIGUOUS` relationships as such ("the graph infers …, not directly stated").
- Never upgrade an inference to a fact. This is the same no-lies / proof-required discipline as AGENTS.md N27.

## 4. When to refresh the graph

| Situation | What to do | Cost |
|---|---|---|
| Code changed and was committed | Nothing — the FREE AST hook already refreshed the structural graph | free |
| Code changed, not committed / no hook | `graphify update .` | free |
| Docs / personas / SOPs / departments changed AND the owner wants the deeper view re-read | `graphify . --backend ollama --model <client-model>` (or `/graphify --update`) | client's own model tokens — **owner-triggered ONLY** |

NEVER kick off the semantic (LLM) pass on your own initiative. It costs the client's own model tokens and is reserved for explicit owner requests.

## 5. Always the CLIENT'S OWN model — never operator keys

Any rebuild that touches the semantic pass MUST use the client's own model:

```bash
graphify . --backend ollama --model deepseek-v4-pro:cloud   # or the client's configured model
```

Read the client's configured model from their `openclaw.json` if it differs. If the client has no usable model, STOP and tell the owner; do NOT use an operator key (NO-COMINGLING-RULE.md / AGENTS.md N29).

## 6. Presenting results

After a query, give the owner a concise answer plus, when useful, the relevant slice of `GRAPH_REPORT.md` (communities / god nodes). Do NOT paste the full report or the raw JSON. Keep it tight.

## 7. Logging

After the one-time install map, append one line to MEMORY.md (see CORE_UPDATES.md):

```
graphify: workforce mapped | graph at <WS>/graphify-out/graph.json | AST hook ON (free) | semantic = on-demand (client model) | Skill 43
```
