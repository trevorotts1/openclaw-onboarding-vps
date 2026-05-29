#!/usr/bin/env bash
# qc-playbook-doc.sh — machine-enforce the per-playbook human-facing DOC deliverable.
#
# ROOT CAUSE this gate kills: when a communications/conversation playbook is
# created (the base install creates the FIRST one — appointment booking), the
# agent is ALSO supposed to create a HUMAN-FACING copy of that playbook in the
# CLIENT'S own account, in this fallback order:
#     (1) the client's Notion  →  (2) Google Docs  →  (3) a plain-text doc the
#     client can access.
# On a recent client this step was SKIPPED: the agent scaffolded the playbook
# files locally and reported the install "clean" but never created the client's
# Notion doc. Root cause: the Notion-doc deliverable was PROSE in the playbook,
# not an ENFORCED gate, so the agent skipped it. A skipped doc leaves the
# customer stranded — no human-facing reference of what was set up. This gate
# makes the deliverable un-droppable, enforced exactly like THE TRINITY
# (qc-trinity-registry.sh) and the send-directive / conversation-memory gates.
#
# WHAT IT CHECKS: it runs against a client's installed conversation-workflows/
# folder + the run manifest. For EVERY conversation playbook that exists (each
# <slug>.md / each registry row), there MUST be a RECORDED human-facing doc —
# a Notion URL, a Google Doc URL, or a plain-text doc path — recorded in one of:
#
#   1. the playbook's registry row in conversation-workflows/registry.md
#      (a Notion/Docs URL or a *.md/*.txt path on the bullet/table row), OR
#   2. a `playbookDocs[]` entry in the run manifest that names the slug AND a
#      destination (URL or path).  The manifest entry form (one per playbook):
#         playbookDocs[]: <slug> -> <notion-url | google-doc-url | text-path>
#
# A playbook with NO recorded doc in either location is a VIOLATION (the doc was
# skipped — the exact failure this gate prevents). "Scaffolded locally" is NOT
# enough; the human-facing copy in the CLIENT's account must be recorded.
#
# Exit codes (mirror qc-conversation-memory.sh / qc-trinity-registry.sh):
#   0 = every conversation playbook has a recorded human-facing doc;
#   1 = one or more playbooks have NO recorded doc (violation);
#   2 = NO playbooks exist yet (nothing recorded) — never silently pass blind;
#       the scan target is empty, treated as a non-pass so a fresh/empty install
#       can't masquerade as a green "doc gate".
#   3 = no conversation-workflows folder found at all (pass --dir, or run after
#       01-locate-master-files-folder.sh has written the pointer).
#
# Usage:
#   bash scripts/qc-playbook-doc.sh                          # auto-locate via pointer file
#   bash scripts/qc-playbook-doc.sh --dir /path/to/conversation-workflows
#   bash scripts/qc-playbook-doc.sh --dir <dir> --manifest /path/to/run-manifest.md
#   bash scripts/qc-playbook-doc.sh --json
#
# Implementation note: PURE BASH (awk/grep/sed), no python — qc-static.yml's
# Python-syntax + anthropic-string scans key off .py files, and BASH keeps this
# gate trivially CI-portable (same posture as qc-conversation-memory.sh).

set -uo pipefail

WF_DIR=""
MANIFEST=""
JSON_MODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) WF_DIR="$2"; shift 2 ;;
    --manifest) MANIFEST="$2"; shift 2 ;;
    --json) JSON_MODE=1; shift ;;
    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ── Auto-locate via the pointer file written by 01-locate-master-files-folder.sh.
MASTER_FILES_DIR=""
if [ -z "$WF_DIR" ]; then
  POINTER="${HOME}/.openclaw/.skill-38-master-files-dir"
  if [ -f "$POINTER" ]; then
    MASTER_FILES_DIR="$(cat "$POINTER")"; MASTER_FILES_DIR="${MASTER_FILES_DIR%$'\n'}"
    [ -n "$MASTER_FILES_DIR" ] && WF_DIR="$MASTER_FILES_DIR/conversation-workflows"
  fi
else
  # Infer MASTER_FILES_DIR as the parent of the passed conversation-workflows dir
  # so we can auto-locate today's run manifest when --manifest is not given.
  MASTER_FILES_DIR="$(cd "$(dirname "$WF_DIR")" 2>/dev/null && pwd || true)"
fi

if [ -z "$WF_DIR" ] || [ ! -d "$WF_DIR" ]; then
  if [ "$JSON_MODE" = "1" ]; then
    printf '{"verdict":"NO_FOLDER","dir":"%s"}\n' "${WF_DIR:-<unset>}"
  else
    echo "qc-playbook-doc: no conversation-workflows folder at '${WF_DIR:-<unset>}'."
    echo "  Pass --dir <path>, or run after 01-locate-master-files-folder.sh has written the pointer."
  fi
  exit 3
fi

# ── Auto-locate the most recent run manifest if not explicitly passed.
if [ -z "$MANIFEST" ] && [ -n "$MASTER_FILES_DIR" ] && [ -d "$MASTER_FILES_DIR" ]; then
  MANIFEST="$(find "$MASTER_FILES_DIR" -maxdepth 1 -type f -name 'run-manifest-*.md' 2>/dev/null | sort | tail -n1 || true)"
fi

# Reserved companion suffixes — these are NOT standalone playbooks.
RESERVED_SUFFIXES=(
  "--build-with-ai-prompt.md"
  "--workflow-ai-prompt.md"
  "--verification-checklist.md"
  "--ghl-side.md"
)

is_reserved() {
  # $1 = filename. Return 0 if it ends with a reserved companion suffix.
  local name="$1" suf
  for suf in "${RESERVED_SUFFIXES[@]}"; do
    case "$name" in *"$suf") return 0 ;; esac
  done
  return 1
}

# A doc destination token = a URL, a notion.so reference, OR a .md/.txt path.
# Used to test a registry row or a manifest entry for a recorded human-facing doc.
line_has_doc_dest() {
  # $1 = haystack line. Return 0 if it names a Notion/Docs URL or a text-doc path.
  local hay low
  hay="$1"
  low="$(printf '%s' "$hay" | tr '[:upper:]' '[:lower:]')"
  case "$low" in
    *"http://"*|*"https://"*) return 0 ;;   # any URL (Notion / Google Doc / etc.)
    *"notion.so"*|*"notion.site"*) return 0 ;;
    *"docs.google.com"*|*"drive.google.com"*) return 0 ;;
    *.md*|*.txt*) return 0 ;;                # plain-text doc path fallback
  esac
  return 1
}

# ── Discover playbook slugs on disk (the <slug>.md files, excluding registry +
#    reserved companions).
declare -a SLUGS=()
while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  [ "$base" = "registry.md" ] && continue
  case "$base" in *.md) : ;; *) continue ;; esac
  is_reserved "$base" && continue
  SLUGS+=("${base%.md}")
done < <(find "$WF_DIR" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null | sort -z)

# Also pull slugs that are registered in the registry "## Active workflows"
# bullet/table rows but may not yet have a <slug>.md on disk (still owe a doc).
REGISTRY="$WF_DIR/registry.md"
declare -a REG_SLUGS=()
if [ -f "$REGISTRY" ]; then
  while IFS= read -r slug; do
    [ -n "$slug" ] && REG_SLUGS+=("$slug")
  done < <(
    awk '
      BEGIN{inactive=0}
      /^#/ { inactive = (tolower($0) ~ /active workflow/) ? 1 : 0 }
      {
        line=$0
        # BULLET form: optional -/* marker, then `<slug>: <desc>`
        if (inactive && line ~ /^[[:space:]]*[-*]?[[:space:]]*`?[a-z0-9][a-z0-9-]*`?[[:space:]]*:[[:space:]]/) {
          s=line
          sub(/^[[:space:]]*[-*]?[[:space:]]*`?/, "", s)
          sub(/`?[[:space:]]*:.*/, "", s)
          if (s ~ /^[a-z0-9][a-z0-9-]*$/) print s
        }
        # TABLE form: | <id> | ... |  (id col 1, skip header/separator)
        else if (line ~ /^[[:space:]]*\|/) {
          n=split(line, c, "|")
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", c[2])
          id=c[2]
          if (id != "" && tolower(id) != "id" && id !~ /^[-: ]+$/ && id ~ /^[a-z0-9][a-z0-9-]*$/) print id
        }
      }
    ' "$REGISTRY"
  )
fi

# Merge disk slugs + registry slugs (dedupe). Bash 3.2-safe (no associative
# arrays — this gate also runs on macOS fleet boxes whose default bash is 3.2);
# membership is tested against a space-padded accumulator string.
ALL_SLUGS=()
SEEN_STR=" "
for s in "${SLUGS[@]:-}" "${REG_SLUGS[@]:-}"; do
  [ -z "$s" ] && continue
  case "$SEEN_STR" in
    *" $s "*) : ;;                       # already seen — skip
    *) ALL_SLUGS+=("$s"); SEEN_STR="$SEEN_STR$s " ;;
  esac
done

# ── For each slug, find a recorded human-facing doc destination.
slug_has_doc() {
  # $1 = slug. Return 0 if a doc destination is recorded for it in the registry
  # row OR in the run manifest playbookDocs[] entries.
  local slug="$1"

  # (1) registry row that mentions this slug AND carries a doc destination.
  if [ -f "$REGISTRY" ]; then
    while IFS= read -r line; do
      case "$line" in
        *"$slug"*)
          if line_has_doc_dest "$line"; then return 0; fi
          ;;
      esac
    done < "$REGISTRY"
  fi

  # (2) run-manifest playbookDocs[] entry naming this slug AND a destination.
  if [ -n "$MANIFEST" ] && [ -f "$MANIFEST" ]; then
    while IFS= read -r line; do
      case "$line" in
        *"playbookDocs"*"$slug"*)
          if line_has_doc_dest "$line"; then return 0; fi
          ;;
      esac
    done < "$MANIFEST"
  fi

  return 1
}

declare -a OK_SLUGS=()
declare -a BAD_SLUGS=()
for s in "${ALL_SLUGS[@]:-}"; do
  [ -z "$s" ] && continue
  if slug_has_doc "$s"; then OK_SLUGS+=("$s"); else BAD_SLUGS+=("$s"); fi
done

total=${#ALL_SLUGS[@]}
ok=${#OK_SLUGS[@]}
bad=${#BAD_SLUGS[@]}

# ── No playbooks at all → exit 2 (never silently pass blind).
if [ "$total" -eq 0 ]; then
  if [ "$JSON_MODE" = "1" ]; then
    printf '{"dir":"%s","manifest":"%s","total":0,"verdict":"NO_PLAYBOOKS"}\n' "$WF_DIR" "${MANIFEST:-}"
  else
    echo "=== qc-playbook-doc: per-playbook human-facing DOC gate ==="
    echo "dir: $WF_DIR"
    echo ""
    echo "RESULT: NO PLAYBOOKS — no conversation playbooks exist yet, so no human-facing"
    echo "        doc could be recorded. Not a pass (a fresh/empty install must not"
    echo "        masquerade as a green doc gate). Exit 2."
  fi
  exit 2
fi

# ── Output ───────────────────────────────────────────────────────────────────
if [ "$JSON_MODE" = "1" ]; then
  printf '{\n'
  printf '  "dir": "%s",\n' "$WF_DIR"
  printf '  "manifest": "%s",\n' "${MANIFEST:-}"
  printf '  "total": %s,\n' "$total"
  printf '  "with_doc": %s,\n' "$ok"
  printf '  "missing_doc": ['
  first=1
  for s in "${BAD_SLUGS[@]:-}"; do
    [ -z "$s" ] && continue
    [ "$first" -eq 1 ] || printf ', '
    printf '"%s"' "$s"; first=0
  done
  printf '],\n'
  printf '  "verdict": "%s"\n' "$([ "$bad" -eq 0 ] && echo PASS || echo FAIL)"
  printf '}\n'
else
  echo "=== qc-playbook-doc: per-playbook human-facing DOC gate ==="
  echo "dir      : $WF_DIR"
  echo "manifest : ${MANIFEST:-<none found>}"
  echo ""
  for s in "${OK_SLUGS[@]:-}"; do
    [ -z "$s" ] && continue
    echo "  [OK]      $s — human-facing doc recorded (Notion / Google Doc / text path)"
  done
  for s in "${BAD_SLUGS[@]:-}"; do
    [ -z "$s" ] && continue
    echo "  [MISSING] $s — NO human-facing doc recorded in registry row or run-manifest playbookDocs[]"
  done
  echo ""
  if [ "$bad" -eq 0 ]; then
    echo "RESULT: PASS — all $total conversation playbook(s) have a recorded human-facing doc"
    echo "        in the client's account (Notion → Google Docs → text)."
  else
    echo "RESULT: FAIL — $bad of $total conversation playbook(s) have NO recorded human-facing doc."
    echo "        The doc deliverable was skipped — create it in the client's account"
    echo "        (Notion → Google Docs → text) and record the URL/path, then re-run."
  fi
fi

[ "$bad" -eq 0 ] && exit 0
exit 1
