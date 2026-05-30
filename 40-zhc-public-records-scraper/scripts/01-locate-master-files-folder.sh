#!/usr/bin/env bash
# 01-locate-master-files-folder.sh — Skill 40 (ZHC Public Records Scraper)
#
# Resolves (or, last resort with explicit operator YES, creates) the client's
# OpenClaw master files folder — the <MASTER_FILES_DIR> under which Skill 40
# writes its query log (public-records-queries.jsonl, per the F52 master-files
# event contract) and its 30-day cache (public-records-cache/).
#
# Reuses Skill 38/39's selection if present so all skills share one folder.
# Persists to $HOME/.openclaw/.skill-40-master-files-dir.
#
# Idempotent. OS-aware Darwin + Linux. set -euo pipefail (read-mostly).

set -euo pipefail

OS="$(uname -s)"
mkdir -p "$HOME/.openclaw"
STATE_FILE="$HOME/.openclaw/.skill-40-master-files-dir"

# Honor explicit override or a prior Skill-38/39 selection if present.
if [ -n "${MASTER_FILES_DIR:-}" ] && [ -d "${MASTER_FILES_DIR:-}" ]; then
  echo "$MASTER_FILES_DIR" > "$STATE_FILE"
  echo "[skill 40] master files folder (from \$MASTER_FILES_DIR): $MASTER_FILES_DIR"
  exit 0
fi
for prior in "$HOME/.openclaw/.skill-39-master-files-dir" "$HOME/.openclaw/.skill-38-master-files-dir"; do
  if [ -f "$prior" ]; then
    P="$(cat "$prior" 2>/dev/null | tr -d '[:space:]')"
    if [ -n "$P" ] && [ -d "$P" ]; then
      echo "$P" > "$STATE_FILE"
      echo "[skill 40] reusing $(basename "$prior")'s master files folder: $P"
      exit 0
    fi
  fi
done

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
  echo "Multiple candidate master files folders:" >&2
  i=1
  for c in "${CANDIDATES[@]}"; do echo "  $i. $c" >&2; i=$((i+1)); done
  echo "Which one? (number — I will NOT touch the others.)" >&2
  read -r CHOICE
  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "$N" ]; then
    echo "Invalid selection: $CHOICE" >&2; exit 1
  fi
  MASTER_FILES_DIR="${CANDIDATES[$((CHOICE-1))]}"
fi

if [ -z "$MASTER_FILES_DIR" ]; then
  echo "No existing master files folder found. Create one at: $DEFAULT_CREATE ? Type YES:" >&2
  read -r CONFIRM
  [ "$CONFIRM" = "YES" ] || { echo "Aborted — no folder created." >&2; exit 1; }
  mkdir -p "$DEFAULT_CREATE"
  MASTER_FILES_DIR="$DEFAULT_CREATE"
fi

echo "$MASTER_FILES_DIR" > "$STATE_FILE"
echo "[skill 40] master files folder: $MASTER_FILES_DIR (saved to $STATE_FILE)"
exit 0
