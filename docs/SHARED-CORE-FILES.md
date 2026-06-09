# Shared Core Files — Zero-Human-Workforce file model

> **Binding rule N32** (see [`AGENTS.md`](../AGENTS.md) canonical index). Enforced by
> `link_shared_core_files()` in `install.sh` + `update-skills.sh`, and asserted by
> `scripts/qc-system-integrity.sh` check **9.9**.

## The model

On every box, **ALL of an account's agents + sub-agents SHARE that box's ONE
canonical `AGENTS.md`, `TOOLS.md`, and `USER.md`** — via **symlinks**, not copies.
There is exactly one real copy of each of those three files per box, and it lives
in the box's **canonical workspace** (`CANON_DIR`). Every other agent's
`AGENTS.md` / `TOOLS.md` / `USER.md` is a symlink pointing at the canonical one.

This is the Zero-Human-Workforce file model: the operating guide (`AGENTS.md`),
the tool catalog (`TOOLS.md`), and the owner/user profile (`USER.md`) are
box-wide truths — every agent on the box reads the *same* ones. Editing the
canonical file updates every agent at once; there is no drift between agents and
no duplicate maintenance.

### Shared (symlinked) vs per-agent (own real files)

| File | Scope | On a non-canonical agent workspace |
|---|---|---|
| `AGENTS.md` | **Shared** (box-wide) | symlink → `CANON_DIR/AGENTS.md` |
| `TOOLS.md`  | **Shared** (box-wide) | symlink → `CANON_DIR/TOOLS.md` |
| `USER.md`   | **Shared** (box-wide) | symlink → `CANON_DIR/USER.md` |
| `IDENTITY.md` | **Per-agent** (own) | untouched real file (+ additive preservation, below) |
| `SOUL.md`     | **Per-agent** (own) | untouched real file |
| `MEMORY.md`   | **Per-agent** (own) | untouched real file |
| `HEARTBEAT.md`| **Per-agent** (own) | untouched real file |

Each agent keeps its OWN real `IDENTITY.md`, `SOUL.md`, `MEMORY.md`, and
`HEARTBEAT.md` — those are an agent's personality, soul, memory, and rhythm, and
must never be shared.

## `CANON_DIR` — what the symlinks point at

`CANON_DIR` = the box's **default agent workspace** =
`agents.defaults.workspace` from the box's `openclaw.json` (fallback
`$HOME/clawd`). The canonical `AGENTS.md` / `TOOLS.md` / `USER.md` live in
`CANON_DIR`.

### Co-mingling guard (CRITICAL — N29)

The symlink target is **ALWAYS the LOCAL box's own canonical workspace**. It is
**NEVER** a hardcoded path and **NEVER** a cross-box path. A client box links to
the **client's own** files (the client is the USER) — never to the operator's
files or to another account's files. The resolver reads the *local* box's
`openclaw.json` and falls back only to the *local* `$HOME/clawd`. There is no
code path that can produce a cross-box target. Check 9.9 fails loudly if any
core-file symlink resolves outside `CANON_DIR`.

## Nested workflow agent exemption

Internal workflow micro-agents — any workspace path matching
`*/workflows/*/agents/*` (e.g. `workflows/bug-fix/agents/triager`) — are
**EXEMPT**. Their core files are **NEVER** touched. They keep their own real
`AGENTS.md` / `TOOLS.md` / `USER.md` because a workflow micro-agent is a
self-contained unit, not one of the account's standing agents.

## What `link_shared_core_files()` does, per non-canonical, non-workflow-agent workspace `W`

For each of `AGENTS.md`, `TOOLS.md`, `USER.md`:

- **Already a symlink** → repoint to `CANON_DIR/<file>` **only if it points
  somewhere wrong**; otherwise no-op.
- **A real file** → it is **backed up** to `W/<file>.bak-unify-<ts>` (the backup
  is **NEVER deleted**). Any content in that file **not already present** in
  `CANON_DIR/<file>` is **APPENDED** to the agent's own `W/IDENTITY.md` under a
  guarded marker:

  ```
  <!-- PRESERVED FROM <agent> <file> (unification <ts>) -->
  ...the unique lines...
  <!-- /PRESERVED -->
  ```

  (`IDENTITY.md` is created if absent.) This is **ADD-only** — nothing is ever
  removed. The real file is then replaced by a symlink → `CANON_DIR/<file>`.
- **Absent** → left absent. No stray symlink is created for a file the agent
  never had.

`IDENTITY.md` / `SOUL.md` / `MEMORY.md` / `HEARTBEAT.md` are otherwise left
untouched (the only write is the additive preservation block above).

## Idempotency

A second run makes **no new backups** and produces **no churn**:

- a correct symlink is a no-op;
- a real file whose `*.bak-unify-<ts>` already exists is skipped;
- a preservation block is never re-appended if a marker for that agent+file
  already exists.

The function logs every action with the `[shared-core]` prefix and prints a
final tally (`linked` / `repointed` / `backed_up` / `preserved` /
`canon-skipped` / `workflow-agent-exempt` / `noop`).

## When it runs

- **Install path** — `install.sh`, right after the canonical workspace is
  resolved (Step 10), called as `link_shared_core_files "$WORKSPACE_DIR"`.
- **Update path** — `update-skills.sh`, after skills + workspaces are set up
  (right after GHL-MCP wiring), called as `link_shared_core_files`.
- It is re-applied on every update and by the `onboarding-resume` cron, so
  agent workspaces that Skill 23 creates *after* the first install are unified
  on the next pass.

## QC

`scripts/qc-system-integrity.sh` **check 9.9** asserts: for every non-workflow-agent
workspace, `AGENTS.md` / `TOOLS.md` / `USER.md` are symlinks resolving to
`CANON_DIR`. A real file where a symlink is required, or a symlink resolving
outside `CANON_DIR` (a co-mingling violation), is reported as a FAILURE in the
standard `id|desc|remedy` format.
