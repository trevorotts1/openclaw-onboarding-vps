#!/usr/bin/env bash
# 01-locate-master-files-folder.sh — Skill 39 (Real Estate Playbook)
#
# Locates (or, last resort with explicit operator YES, creates) the client's
# OpenClaw master files folder. This is the <MASTER_FILES_DIR> that Skill 39's
# event log (real-estate-events.jsonl, per the F52 master-files event contract)
# is written under at runtime.
#
# Mirrors Skill 38's O.2 semantic discovery so the SAME folder is selected
# regardless of which skill resolves it first. Persists the selection to
# $HOME/.openclaw/.skill-39-master-files-dir so re-runs are stable.
#
# Idempotent. Read-only except for the optional operator-confirmed create and
# the state-file write. OS-aware Darwin + Linux.

set -euo pipefail

OS="$(uname -s)"
mkdir -p "$HOME/.openclaw"
STATE_FILE="$HOME/.openclaw/.skill-39-master-files-dir"

# Honor an explicit override or a prior Skill-38 selection if present.
if [ -n "${MASTER_FILES_DIR:-}" ] && [ -d "${MASTER_FILES_DIR:-}" ]; then
  echo "$MASTER_FILES_DIR" > "$STATE_FILE"
  echo "[skill 39] master files folder (from \$MASTER_FILES_DIR): $MASTER_FILES_DIR"
  exit 0
fi
if [ -f "$HOME/.openclaw/.skill-38-master-files-dir" ]; then
  PRIOR="$(cat "$HOME/.openclaw/.skill-38-master-files-dir" 2>/dev/null | tr -d '[:space:]')"
  if [ -n "$PRIOR" ] && [ -d "$PRIOR" ]; then
    echo "$PRIOR" > "$STATE_FILE"
    echo "[skill 39] reusing Skill 38's master files folder: $PRIOR"
    exit 0
  fi
fi

# ---------- Semantic discovery (read-only) ----------
if [ "$OS" = "Darwin" ]; then
  ROOTS=("$HOME/Downloads" "$HOME/Documents" "$HOME/Desktop" "$HOME/OpenClaw" "$HOME/.openclaw" "$HOME")
  DEFAULT_CREATE="$HOME/Downloads/OpenClaw Master Files"
else
  ROOTS=("/data" "/root" "/var/openclaw" "/home" "$HOME" "$HOME/.openclaw")
  DEFAULT_CREATE="/data/openclaw-master-files"
fi

CANDIDATES=()
for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  while IFS= read -r line; do
    [ -n "$line" ] && CANDIDATES+=("$line")
  done < <(find "$root" -maxdepth 4 -type d 2>/dev/null \
      | grep -iE '(openclaw.*master|claw.*master|openclaw.*files|master.*files)' \
      || true)
done

if [ "${#CANDIDATES[@]}" -gt 0 ]; then
  IFS=$'\n' CANDIDATES=($(printf '%s\n' "${CANDIDATES[@]}" | sort -u))
  unset IFS
fi

N="${#CANDIDATES[@]}"
MASTER_FILES_DIR=""

if [ "$N" -eq 1 ]; then
  MASTER_FILES_DIR="${CANDIDATES[0]}"
elif [ "$N" -gt 1 ]; then
  echo "I found multiple candidate master files folders:" >&2
  i=1
  for c in "${CANDIDATES[@]}"; do
    echo "  $i. $c" >&2
    i=$((i+1))
  done
  echo "Which one is the active master files folder? (number — I will NOT touch the others.)" >&2
  read -r CHOICE
  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "$N" ]; then
    echo "Invalid selection: $CHOICE" >&2
    exit 1
  fi
  MASTER_FILES_DIR="${CANDIDATES[$((CHOICE-1))]}"
fi

if [ -z "$MASTER_FILES_DIR" ]; then
  echo "No existing master files folder found." >&2
  echo "May I create one at: $DEFAULT_CREATE ? Type YES to confirm:" >&2
  read -r CONFIRM
  if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted by operator — no folder created." >&2
    exit 1
  fi
  mkdir -p "$DEFAULT_CREATE"
  MASTER_FILES_DIR="$DEFAULT_CREATE"
fi

echo "$MASTER_FILES_DIR" > "$STATE_FILE"
echo "[skill 39] master files folder: $MASTER_FILES_DIR (saved to $STATE_FILE)"
exit 0
