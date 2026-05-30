#!/usr/bin/env bash
# 09-install-conversation-workflows.sh
#
# Creates the conversation-workflows registry under MASTER_FILES_DIR.
#
# What this does:
#   1. Reads MASTER_FILES_DIR from ~/.openclaw/.skill-38-master-files-dir
#      (this pointer file is written by 01-locate-master-files-folder.sh).
#   2. Creates `$MASTER_FILES_DIR/conversation-workflows/` if missing.
#   3. Writes `$MASTER_FILES_DIR/conversation-workflows/registry.md` with the
#      3-Layer architecture summary, file-naming conventions, and trigger
#      phrases — ONLY IF the registry does not already exist (idempotent).
#
# OS-aware (Darwin / Linux) but the source-of-truth for the path is the
# pointer file written by step 01.

set -euo pipefail

# -----------------------------------------------------------------------------
# Resolve MASTER_FILES_DIR
# -----------------------------------------------------------------------------
POINTER_FILE="${HOME}/.openclaw/.skill-38-master-files-dir"
if [[ ! -f "$POINTER_FILE" ]]; then
  echo "[09-install-conversation-workflows] pointer file missing: $POINTER_FILE" >&2
  echo "[09-install-conversation-workflows] run 01-locate-master-files-folder.sh first." >&2
  exit 1
fi

MASTER_FILES_DIR="$(cat "$POINTER_FILE")"
MASTER_FILES_DIR="${MASTER_FILES_DIR%$'\n'}"

if [[ -z "$MASTER_FILES_DIR" || ! -d "$MASTER_FILES_DIR" ]]; then
  echo "[09-install-conversation-workflows] MASTER_FILES_DIR is empty or not a directory: '$MASTER_FILES_DIR'" >&2
  exit 1
fi

WORKFLOWS_DIR="$MASTER_FILES_DIR/conversation-workflows"
REGISTRY="$WORKFLOWS_DIR/registry.md"

mkdir -p "$WORKFLOWS_DIR"

# -----------------------------------------------------------------------------
# Conversation-memory: the per-contact conversation-log directory.
#
# GHL inbound hook sessions are SINGLE-TURN — the agent's only memory of a
# contact across messages is the per-contact log file under conversational-logs/.
# The directory MUST exist AND be writable by the gateway RUNTIME user, or the
# agent silently fails to persist context (root cause of a live-client incident,
# where the dir was root-owned and the agent could not write until chowned to
# the node runtime user).
# -----------------------------------------------------------------------------
LOGS_DIR="$MASTER_FILES_DIR/conversational-logs"
mkdir -p "$LOGS_DIR"
echo "[09-install-conversation-workflows] conversational-logs dir ensured → $LOGS_DIR"

# Ensure the runtime user (the user the OpenClaw gateway runs as) owns the dir
# so the agent can write per-contact logs. On VPS/Docker the gateway runs as
# `node`; on a Mac Homebrew install it runs as the login user. Only chown when
# running as root (otherwise leave ownership as-is — the current user already
# owns what it just created).
RUNTIME_USER="${OPENCLAW_RUNTIME_USER:-node}"
if [[ "$(id -u)" -eq 0 ]]; then
  if id "$RUNTIME_USER" >/dev/null 2>&1; then
    chown -R "$RUNTIME_USER" "$LOGS_DIR" \
      && echo "[09-install-conversation-workflows] chowned conversational-logs → $RUNTIME_USER (gateway runtime user)" \
      || echo "[09-install-conversation-workflows] WARN: chown to $RUNTIME_USER failed — the agent may not be able to write logs; chown it manually." >&2
  else
    echo "[09-install-conversation-workflows] WARN: runtime user '$RUNTIME_USER' not found; set OPENCLAW_RUNTIME_USER and chown $LOGS_DIR to the gateway user so the agent can write logs." >&2
  fi
else
  echo "[09-install-conversation-workflows] running as non-root ($(id -un)); conversational-logs owned by current user. If the gateway runs as a DIFFERENT user (e.g. node), chown $LOGS_DIR to that user."
fi

if [[ -f "$REGISTRY" ]]; then
  echo "[09-install-conversation-workflows] registry already present — leaving as-is: $REGISTRY"
else

# -----------------------------------------------------------------------------
# Write registry.md
# -----------------------------------------------------------------------------
cat > "$REGISTRY" <<'REG_EOF'
# Conversation Workflows — Registry

This folder holds every Conversation Workflow installed for this client.
The agent reads `registry.md` on every inbound to see which workflow (if
any) should fire for the customer's current intent.

## What is a Conversation Workflow?

A scenario-specific behavior override. Other conversational AI platforms
make operators build workflows in visual node-based UIs (n8n, Zapier, GHL
Workflow Builder). This system has operators TALK through workflows: the
agent asks intelligent questions, synthesizes a Conversation Playbook,
AND auto-builds the GHL routing layer the customer needs to reach the AI
in the first place.

Conversation Workflows are complementary to Communication Playbooks:

- **Communication Playbook** = baseline tone/voice for a channel. One per
  channel. Applies to every reply on that channel.
- **Conversation Workflow** = specific scenario behavior override. Many
  per client. Applies only when its trigger fires (pricing inquiry,
  booking request, FAQ, etc.).

When a workflow fires, its scenario instructions override the channel
playbook's body content, but the channel playbook's tone/signature is
still honored.

## 3-Layer Architecture summary

- **Layer 0 — Routing check.** Did this inbound match an existing
  workflow's trigger? If yes, fire that workflow. If no, fall through to
  the standard channel playbook.
- **Layer 1 — GHL side.** The GHL workflow + tag automations that route
  the inbound message into the agent in the first place. Auto-built
  during workflow setup; mirrored in `<workflow-id>--ghl-side.md`.
- **Layer 2 — OpenClaw playbook.** The agent-side scenario behavior:
  Phase 1 (acknowledge), Phase 2 (gather), Phase 3 (act), Phase 4
  (handoff). Stored in `<workflow-id>.md`.

Full builder protocol (Layers 0/1/2 walkthrough): see the skill's
`protocols/conversation-workflows-protocol.md`.

## File-naming conventions

For every workflow with id `<workflow-id>` (kebab-case, alphanumeric +
hyphens only):

- `<workflow-id>.md` — Layer 2 OpenClaw playbook (Phase 1-4 + edge cases)
- `<workflow-id>--ghl-side.md` — Layer 1 GHL routing mirror (tags,
  triggers, workflow IDs)
- `<workflow-id>--build-with-ai-prompt.md` — the Build-with-AI prompt
  (pasted into GHL Automations -> "Build with AI") used to build the GHL side
  (legacy name `<workflow-id>--workflow-ai-prompt.md` still accepted by QC)
- `<workflow-id>--verification-checklist.md` — operator-runnable
  verification checklist confirming the workflow is live end-to-end

## How to invoke the builder

The operator can trigger the Workflow Builder by sending the agent any
of these intent phrases (case-insensitive, fuzzy match — Step 9.20
Section A):

- "Help me build a conversation playbook"
- "Help me build a conversation workflow"
- "Build me a workflow for <X>"
- "Build me a playbook for <X>"
- "Create a workflow for <X>"
- "Create a playbook for <X>"
- "Set up a conversation flow for <X>"
- "I want a workflow that does <X>"
- "Walk me through building a workflow"

The agent then hands control to the Workflow Builder subagent walkthrough
(`protocols/conversation-workflows-protocol.md` Section B) and runs the
operator through the 3-Layer setup end-to-end.

## Active workflows

(Append one bullet per installed workflow — `<workflow-id>: <one-line description>`.
This bullet form is what `scripts/qc-trinity-registry.sh` reconciles against on
every QC run — each `<workflow-id>` must have its `<workflow-id>.md` playbook AND
its `<workflow-id>--build-with-ai-prompt.md` on disk, unless the description says
"uses existing inbound routing" (then Layer 1 is skipped and the prompt is
legitimately absent). The richer markdown TABLE form from the protocol is also
accepted by the validator.)

<!-- workflows: none yet -->
REG_EOF

echo "[09-install-conversation-workflows] registry created → $REGISTRY"
fi

# =============================================================================
# BINDING: per-playbook human-facing DOC deliverable (Notion → Google Docs → text)
#
# When a conversation playbook exists, the install is NOT complete until a
# HUMAN-FACING copy of it has been created in the CLIENT's account (so the
# customer has a readable/editable reference of what was set up). This is the
# step that was SKIPPED on a recent client — the playbook was scaffolded locally
# and the install reported "clean," but the client's Notion doc was never
# created. This routine makes it un-droppable at install time; the QC gate
# scripts/qc-playbook-doc.sh fail-closes the hand-off if it was skipped anyway.
#
# Fallback order (ALWAYS in this order, never skip ahead):
#   (1) the client's Notion  — if NOTION_API_KEY is set AND a parent page the
#       integration can access exists (the integration MUST be shared with a
#       parent page); create a NEW subpage under it.
#   (2) Google Docs — if no Notion path, and a Google Docs helper/CLI is wired.
#   (3) plain-text doc — always-available last resort; a .md the client can read.
#
# The resulting URL/path is RECORDED two ways so qc-playbook-doc.sh sees it:
#   - appended to that playbook's registry row, AND
#   - written as a `playbookDocs[]: <slug> -> <dest>` line in today's run manifest.
# An operator-facing line states WHERE each doc was created (or which fallback).
# =============================================================================

NOTION_API_KEY="${NOTION_API_KEY:-}"
NOTION_PARENT_SEARCH="${SKILL38_NOTION_PARENT_SEARCH:-${NOTION_PARENT_PAGE_TITLE:-}}"

# Locate today's / most-recent run manifest so we can record playbookDocs[] there
# too (the manifest is the auditable run record; the registry row is the runtime
# pointer). If none exists, we still record on the registry row.
RUN_MANIFEST="$(find "$MASTER_FILES_DIR" -maxdepth 1 -type f -name 'run-manifest-*.md' 2>/dev/null | sort | tail -n1 || true)"

# A doc destination = URL or .md/.txt path (mirrors qc-playbook-doc.sh).
_dest_is_recorded_for() {
  # $1 = slug. Returns 0 if a doc dest is already recorded (registry row or manifest).
  local slug="$1" line
  if [[ -f "$REGISTRY" ]]; then
    while IFS= read -r line; do
      case "$line" in
        *"$slug"*)
          case "$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')" in
            *http://*|*https://*|*notion.so*|*notion.site*|*docs.google.com*|*.md*|*.txt*) return 0 ;;
          esac ;;
      esac
    done < "$REGISTRY"
  fi
  if [[ -n "$RUN_MANIFEST" && -f "$RUN_MANIFEST" ]]; then
    while IFS= read -r line; do
      case "$line" in
        *playbookDocs*"$slug"*)
          case "$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')" in
            *http://*|*https://*|*.md*|*.txt*) return 0 ;;
          esac ;;
      esac
    done < "$RUN_MANIFEST"
  fi
  return 1
}

# Try to publish ONE playbook markdown to the client's Notion. Echoes the page
# URL on success (and exits 0); non-zero on any failure so the caller falls back.
_notion_publish_playbook() {
  # $1 = playbook .md path; $2 = page title
  local md="$1" title="$2"
  [[ -n "$NOTION_API_KEY" ]] || return 1
  NOTION_API_KEY="$NOTION_API_KEY" \
  NOTION_PARENT_SEARCH="$NOTION_PARENT_SEARCH" \
  PB_MD="$md" PB_TITLE="$title" \
  python3 - <<'PY_PB_EOF'
import os, sys, json, re, urllib.request, urllib.error
API="https://api.notion.com/v1"
H={"Authorization":"Bearer "+os.environ["NOTION_API_KEY"],
   "Content-Type":"application/json","Notion-Version":"2022-06-28"}
def http(method, path, body=None):
    data=None if body is None else json.dumps(body).encode("utf-8")
    req=urllib.request.Request(API+path, data=data, headers=H, method=method)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))
def rich(s): return [{"type":"text","text":{"content":s[:1900]}}]
def md_to_blocks(md):
    blocks=[]
    for raw in md.split("\n"):
        line=raw.rstrip()
        if line.startswith("# "): blocks.append({"object":"block","type":"heading_1","heading_1":{"rich_text":rich(line[2:])}})
        elif line.startswith("## "): blocks.append({"object":"block","type":"heading_2","heading_2":{"rich_text":rich(line[3:])}})
        elif line.startswith("### "): blocks.append({"object":"block","type":"heading_3","heading_3":{"rich_text":rich(line[4:])}})
        elif re.match(r"^\s*[-*] ", line): blocks.append({"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":rich(re.sub(r'^\s*[-*] ','',line))}})
        elif line.strip(): blocks.append({"object":"block","type":"paragraph","paragraph":{"rich_text":rich(line)}})
    return blocks or [{"object":"block","type":"paragraph","paragraph":{"rich_text":[]}}]
# Find a parent page the integration can access. The integration MUST be shared
# with at least one page; if search returns none, there is no accessible parent
# -> fail so the caller falls back (we never create at workspace root blindly).
try:
    q=os.environ.get("NOTION_PARENT_SEARCH","") or ""
    res=http("POST","/search",{"query":q,"filter":{"property":"object","value":"page"}})
except Exception as e:
    sys.stderr.write("notion search failed: %s\n"%e); sys.exit(2)
results=res.get("results",[])
if not results:
    sys.stderr.write("no accessible parent page (share the integration with a page)\n"); sys.exit(3)
parent_id=results[0]["id"]
try:
    md=open(os.environ["PB_MD"],encoding="utf-8").read()
    blocks=md_to_blocks(md)
    created=http("POST","/pages",{"parent":{"type":"page_id","page_id":parent_id},
        "properties":{"title":[{"type":"text","text":{"content":os.environ["PB_TITLE"]}}]},
        "children":blocks[:90]})
    pid=created["id"]
    rest=blocks[90:]
    while rest:
        http("PATCH","/blocks/"+pid+"/children",{"children":rest[:90]}); rest=rest[90:]
    print(created.get("url",""))
except Exception as e:
    sys.stderr.write("notion create failed: %s\n"%e); sys.exit(4)
PY_PB_EOF
}

_record_doc_dest() {
  # $1 = slug, $2 = destination (URL or path), $3 = where ("Notion"/"Google Docs"/"plain-text")
  local slug="$1" dest="$2" where="$3"
  # 1) append to the registry row for this slug (so the runtime + qc gate see it)
  if [[ -f "$REGISTRY" ]] && grep -q "^- *${slug}:" "$REGISTRY" 2>/dev/null; then
    # append " — doc: <dest>" to the existing bullet if not already present
    if ! grep -q "^- *${slug}:.*${dest}" "$REGISTRY" 2>/dev/null; then
      python3 - "$REGISTRY" "$slug" "$dest" <<'PY_REG_EOF'
import sys
path, slug, dest = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(path, encoding="utf-8").read().split("\n")
pref = "- " + slug + ":"
for i, ln in enumerate(lines):
    if ln.lstrip().startswith(pref) and dest not in ln:
        lines[i] = ln.rstrip() + " — doc: " + dest
        break
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY_REG_EOF
    fi
  else
    # no bullet yet (e.g. starter playbook not registered as bullet) — add one
    printf -- '- %s: human-facing doc (%s) — doc: %s\n' "$slug" "$where" "$dest" >> "$REGISTRY"
  fi
  # 2) record in the run manifest playbookDocs[] (auditable run record)
  if [[ -n "$RUN_MANIFEST" && -f "$RUN_MANIFEST" ]]; then
    if ! grep -q "playbookDocs\[\]: *${slug} *->" "$RUN_MANIFEST" 2>/dev/null; then
      printf 'playbookDocs[]: %s -> %s\n' "$slug" "$dest" >> "$RUN_MANIFEST"
    fi
  fi
}

create_playbook_doc() {
  # $1 = playbook .md path. Creates the human-facing doc per the fallback chain
  # and records the destination. Idempotent (skips if a dest is already recorded).
  local md="$1" base slug title url
  base="$(basename "$md")"; slug="${base%.md}"
  case "$slug" in registry) return 0 ;; esac
  case "$base" in
    *--build-with-ai-prompt.md|*--workflow-ai-prompt.md|*--verification-checklist.md|*--ghl-side.md) return 0 ;;
  esac
  if _dest_is_recorded_for "$slug"; then
    echo "[09-install-conversation-workflows] human-facing doc already recorded for '$slug' — skipping"
    return 0
  fi
  title="Conversation Playbook — ${slug}"

  # (1) Notion first
  if [[ -n "$NOTION_API_KEY" ]]; then
    if url="$(_notion_publish_playbook "$md" "$title" 2>/dev/null)" && [[ -n "$url" ]]; then
      _record_doc_dest "$slug" "$url" "Notion"
      echo "[09-install-conversation-workflows] human-facing doc for '$slug' created in the client's NOTION: $url"
      return 0
    else
      echo "[09-install-conversation-workflows] Notion path unavailable for '$slug' (no NOTION_API_KEY scope / no accessible parent page) — falling back" >&2
    fi
  else
    echo "[09-install-conversation-workflows] NOTION_API_KEY not set — skipping Notion for '$slug', falling back" >&2
  fi

  # (2) Google Docs — only if a wired helper/CLI exists (no silent no-op).
  if [[ -n "${SKILL38_GDOCS_HELPER:-}" && -x "${SKILL38_GDOCS_HELPER:-}" ]]; then
    if url="$("${SKILL38_GDOCS_HELPER}" "$md" "$title" 2>/dev/null)" && [[ -n "$url" ]]; then
      _record_doc_dest "$slug" "$url" "Google Docs"
      echo "[09-install-conversation-workflows] human-facing doc for '$slug' created in the client's GOOGLE DOCS: $url"
      return 0
    fi
    echo "[09-install-conversation-workflows] Google Docs helper failed for '$slug' — falling back to plain text" >&2
  fi

  # (3) plain-text doc — always-available last resort.
  local docs_dir text_path
  docs_dir="$MASTER_FILES_DIR/conversation-workflows/client-docs"
  mkdir -p "$docs_dir"
  text_path="$docs_dir/${slug}-playbook.md"
  cp "$md" "$text_path"
  _record_doc_dest "$slug" "$text_path" "plain-text"
  echo "[09-install-conversation-workflows] no Notion/Google Docs available — wrote a PLAIN-TEXT human-facing doc for '$slug' the client can access: $text_path"
  return 0
}

# Run the doc pass over every playbook currently on disk (the base install's
# appointment-booking starter + any later ones). Idempotent on re-run.
shopt -s nullglob 2>/dev/null || true
for pb in "$WORKFLOWS_DIR"/*.md; do
  create_playbook_doc "$pb"
done

echo "[09-install-conversation-workflows] per-playbook human-facing doc pass complete (Notion → Google Docs → text). qc-playbook-doc.sh enforces this at QC."
