#!/usr/bin/env bash
# qc-no-personal-data.sh — Skill 39 UNIVERSAL-skill guard.
#
# Skill 39 is a UNIVERSAL skill — the SAME real-estate brain for any operator and
# any market. No real person, client, brand, token, or personal id may appear
# anywhere in the skill tree. This gate FAILS (exit 1) if a forbidden identifier
# is found, and PASSES (exit 0) when clean.
#
# It also enforces a positive invariant for THIS skill: the four RE tags
# (ZHC-buyer-lead / ZHC-seller-lead / ZHC-investor-lead /
# ZHC-pre-foreclosure-prospect) must all be present somewhere in the tree (a
# regression that drops one is caught). Use --no-tag-check to scan identifiers only.
#
# PURE BASH (grep/sed), no python. bash -n clean. set -uo pipefail.
#
# Exit codes: 0 = clean; 1 = a forbidden identifier (or a missing required tag).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SELF="$SCRIPT_DIR/qc-no-personal-data.sh"
JSON_MODE=0
TAG_CHECK=1

while [ $# -gt 0 ]; do
  case "$1" in
    --json)        JSON_MODE=1; shift ;;
    --skill-dir)   SKILL_DIR="$2"; shift 2 ;;
    --no-tag-check) TAG_CHECK=0; shift ;;
    -h|--help)     sed -n '1,24p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Forbidden identifiers (same discipline as Skill 38's universal guard).
PATTERNS=(
  '\bTrevor\b' '\bTeresa\b' '\bKeez\b' '\bChristy\b' '\bCandace\b'
  '\bAngeleen\b' '\bBeverly\b' '\bEvelyn\b' '\bMonique\b' '\bLyric\b'
  '\bKofi\b' '\bPelham\b' '\bCorey\b' '\bMaria\b'
  'Grants Boutique' 'Explore Growth' 'thewinningformulacourse'
  'growthriveprosper' 'blackceo' 'zerohumanworkforce' '\bmarico\b'
  'trevelynotts' '5252140759'
)
# NOTE: 'marico' (Marico Consulting brand) is word-bounded so it does NOT collide
# with the real county name "Maricopa" (a public, allowed jurisdiction).

FAIL=0
HITS=()

scan_file() {
  local f="$1"
  [ "$(cd "$(dirname "$f")" && pwd)/$(basename "$f")" = "$SELF" ] && return 0
  local pat
  for pat in "${PATTERNS[@]}"; do
    if grep -nEi -- "$pat" "$f" >/dev/null 2>&1; then
      while IFS= read -r line; do
        HITS+=("$f: $line")
      done < <(grep -nEi -- "$pat" "$f" 2>/dev/null | sed 's/[[:space:]]\{1,\}/ /g' | cut -c1-160)
      FAIL=1
    fi
  done
}

echo "=== qc-no-personal-data (Skill 39): universal-skill identifier guard ==="

while IFS= read -r f; do
  scan_file "$f"
done < <(find "$SKILL_DIR" \( -name '*.md' -o -name '*.sh' -o -name '*.txt' \) -type f 2>/dev/null)

# Positive invariant: required RE tags present in SKILL CONTENT (not just in this
# gate's own REQUIRED_TAGS array). We grep the tree but EXCLUDE this script so a
# regression that drops a tag from the protocols/AGENTS block is actually caught.
if [ "$TAG_CHECK" -eq 1 ]; then
  REQUIRED_TAGS=( "ZHC-buyer-lead" "ZHC-seller-lead" "ZHC-investor-lead" "ZHC-pre-foreclosure-prospect" )
  for t in "${REQUIRED_TAGS[@]}"; do
    # search every file except this gate itself
    found=0
    while IFS= read -r cf; do
      [ "$(cd "$(dirname "$cf")" && pwd)/$(basename "$cf")" = "$SELF" ] && continue
      if grep -qF -- "$t" "$cf" 2>/dev/null; then found=1; break; fi
    done < <(find "$SKILL_DIR" \( -name '*.md' -o -name '*.sh' -o -name '*.txt' \) -type f 2>/dev/null)
    if [ "$found" -eq 0 ]; then
      HITS+=("MISSING REQUIRED TAG: $t")
      FAIL=1
    fi
  done
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — no personal/client identifiers; all required ZHC- RE tags present."
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"PASS"}\n'
  exit 0
else
  echo "RESULT: FAIL —"
  for h in "${HITS[@]}"; do echo "  - $h"; done
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"FAIL","hits":%s}\n' "${#HITS[@]}"
  exit 1
fi
