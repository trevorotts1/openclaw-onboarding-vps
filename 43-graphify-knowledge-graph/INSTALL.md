# Skill 43 — INSTALL (One-Time Setup)

The skill folder ships with the onboarding package — `install.sh` / `update-skills.sh` copy every `NN-slug/` folder verbatim, so `43-graphify-knowledge-graph/` lands at:
- Mac: `~/.openclaw/skills/43-graphify-knowledge-graph/`
- VPS: `/data/.openclaw/skills/43-graphify-knowledge-graph/`

This file covers prerequisites, the one-time install + map, and verification. All commands are run ON THE CLIENT BOX (VPS: inside the Docker container).

---

## 1. Prerequisites

| Requirement | Status | Why |
|---|---|---|
| `uv` (preferred) or `pip3` available on the client box | **Required** | To install graphify (`uv tool install` preferred) |
| `git` in the workspace being mapped | **Required for the hook** | The free AST auto-rebuild hook is a git post-commit hook |
| Client's own model reachable (their Ollama, default `deepseek-v4-pro:cloud`) | **Required for the semantic map** | The heavy semantic pass uses the CLIENT'S OWN model — NEVER operator keys |
| Skill 23 (AI Workforce Blueprint) installed | **Recommended** | So there is a real workforce (departments/roles/SOPs) to map |

> VPS note: install runs INSIDE the Hostinger Docker container. `apt`/`apt-get` is a brew shim and brew is OFF PATH — do NOT use apt. Use `uv tool install` or `pip3 install --user ... --break-system-packages`, or the explicit Linuxbrew path `/data/linuxbrew/.linuxbrew/bin/...`.

## 2. Install graphify on the client box

```bash
# Preferred — uv tool (clean, isolated). Installs the full extras set.
uv tool install "graphifyy[all]"

# Fallback if uv is not present (VPS container: add --break-system-packages):
pip3 install --user "graphifyy[all]" --break-system-packages \
  || pip3 install --user "graphifyy[all]"
```

Verify the binary is reachable:

```bash
graphify --help | head -3        # should print "Usage: graphify <command>"
```

## 3. Register the OpenClaw skill + wire `/graphify` into AGENTS.md

Two steps — they do different things, run BOTH:

```bash
# (a) Register graphify as an OpenClaw skill (copies the skill into the
#     platform config dir so the agent can invoke it):
graphify install --platform claw

# (b) Wire it into the workspace AGENTS.md so the agent ALWAYS checks the
#     graph before answering codebase/workforce questions and rebuilds it
#     after code changes. Run from the workspace root being mapped:
#       Mac:  cd ~/.openclaw/workspace
#       VPS:  cd /data/.openclaw/workspace
graphify claw install
```

`graphify claw install` appends a `## graphify` section to the workspace `AGENTS.md` — that is what makes `/graphify` always-on for the client's agent (no manual invocation needed in future sessions).

## 4. Install the FREE AST auto-rebuild hook

```bash
# Run from inside the git repo / workspace you want kept fresh:
graphify hook install     # post-commit + post-checkout hooks (FREE, no LLM)
graphify hook status      # confirm installed
```

After every `git commit`, the hook detects which **code** files changed (`git diff HEAD~1`), re-runs **AST** extraction on just those files, and rebuilds `graph.json` + `GRAPH_REPORT.md`. This is **free** (no LLM, no tokens). Doc/persona/SOP changes are NOT picked up by the hook — those need an on-demand semantic re-run (`/graphify --update`, step 6).

> The hook appends to any existing post-commit hook rather than replacing it.

## 5. Map the client's OWN workforce — ONCE, on the client's OWN model

This is the one-time heavy semantic pass. Run it ONCE at install, pointed at the client's workspace, using **the client's own model**:

```bash
# Map the client's workspace (departments, roles, personas, SOPs, AGENTS.md).
# --backend ollama + --model = the CLIENT'S OWN model. NEVER operator keys.
WS="$HOME/.openclaw/workspace"            # Mac
# VPS: WS=/data/.openclaw/workspace
cd "$WS"
graphify . --backend ollama --model deepseek-v4-pro:cloud
```

Substitute the client's actually-configured model if it differs from `deepseek-v4-pro:cloud` (read it from their `openclaw.json` `agents.defaults.model` or equivalent). If the client has no usable local/cloud model of their own, **STOP and tell the owner** — do NOT substitute an operator API key (NO-COMINGLING-RULE.md / AGENTS.md N29).

Outputs land in `<WS>/graphify-out/`: `graph.html`, `graph.json`, `GRAPH_REPORT.md`.

## 6. Re-running later (who pays / when)

| Action | Command | Cost | Trigger |
|---|---|---|---|
| Structural refresh after code change | (automatic) `graphify hook` | **FREE** | every `git commit` |
| Structural refresh, manual | `graphify update .` | **FREE** | anytime |
| Deep semantic re-read (docs/personas/SOPs) | `graphify . --backend ollama --model <client-model>` or `/graphify --update` | client's own model tokens | **ON-DEMAND, owner-triggered ONLY** |

NEVER schedule an automatic semantic re-build. The expensive pass is owner-triggered, on the client's own model.

## 7. Verify

```bash
# Mac
bash ~/.openclaw/skills/43-graphify-knowledge-graph/scripts/verify-graphify-install.sh
# VPS
bash /data/.openclaw/skills/43-graphify-knowledge-graph/scripts/verify-graphify-install.sh
```

For full QC:

```bash
bash ~/.openclaw/skills/43-graphify-knowledge-graph/qc-graphify-knowledge-graph.sh
```

## 8. Core file updates

After install, apply the appends in CORE_UPDATES.md to the workspace's AGENTS.md, TOOLS.md, and MEMORY.md.
