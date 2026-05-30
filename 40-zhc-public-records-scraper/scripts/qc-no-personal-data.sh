#!/usr/bin/env bash
# qc-no-personal-data.sh — Skill 40 UNIVERSAL-skill guard.
#
# Skill 40 is a UNIVERSAL skill — the SAME tiered public-records engine for any
# operator. No real person, client, brand, token, or personal id may appear
# anywhere in the skill tree. FAILS (exit 1) on a forbidden identifier; PASSES
# (exit 0) clean.
#
# It also enforces two positive invariants for THIS skill (use --no-invariants to
# skip):
#   (a) the Tier 1 county registry TSV parses to >= 10 county rows with 6 columns
#       each (the curated tier must actually be populated), and
#   (b) the four tier keywords (Tier 1..Tier 4 honest gap) are documented.
#
# County names + government portal DOMAINS (e.g. hcad.org, sdarcc.gov) are PUBLIC
# reference data, NOT personal/client data — they are expected and allowed.
#
# PURE BASH (grep/sed/awk), no python. bash -n clean. set -uo pipefail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SELF="$SCRIPT_DIR/qc-no-personal-data.sh"
JSON_MODE=0
INVARIANTS=1

while [ $# -gt 0 ]; do
  case "$1" in
    --json)          JSON_MODE=1; shift ;;
    --skill-dir)     SKILL_DIR="$2"; shift 2 ;;
    --no-invariants) INVARIANTS=0; shift ;;
    -h|--help)       sed -n '1,24p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

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

echo "=== qc-no-personal-data (Skill 40): universal-skill identifier guard ==="

while IFS= read -r f; do
  scan_file "$f"
done < <(find "$SKILL_DIR" \( -name '*.md' -o -name '*.sh' -o -name '*.txt' -o -name '*.tsv' \) -type f 2>/dev/null)

if [ "$INVARIANTS" -eq 1 ]; then
  TSV="$SKILL_DIR/references/tier1-county-registry.tsv"
  if [ ! -f "$TSV" ]; then
    HITS+=("INVARIANT: Tier 1 registry TSV missing ($TSV)"); FAIL=1
  else
    rows="$(($(wc -l < "$TSV") - 1))"
    cols="$(head -1 "$TSV" | awk -F'\t' '{print NF}')"
    if [ "$rows" -lt 10 ]; then HITS+=("INVARIANT: Tier 1 registry has $rows rows (<10 required)"); FAIL=1; fi
    if [ "$cols" -ne 6 ]; then HITS+=("INVARIANT: Tier 1 registry header has $cols cols (6 required)"); FAIL=1; fi
    # every data row must have 6 tab-separated fields
    bad="$(awk -F'\t' 'NR>1 && NF!=6 {c++} END{print c+0}' "$TSV")"
    if [ "$bad" -gt 0 ]; then HITS+=("INVARIANT: $bad Tier 1 row(s) do not have 6 columns"); FAIL=1; fi
  fi
  # tier vocabulary documented somewhere
  for kw in "Tier 1" "Tier 2" "Tier 3" "Tier 4"; do
    if ! grep -rqF -- "$kw" "$SKILL_DIR" --include='*.md' 2>/dev/null; then
      HITS+=("INVARIANT: '$kw' not documented in any .md"); FAIL=1
    fi
  done
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — no personal/client identifiers; Tier 1 registry populated; tiers documented."
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"PASS"}\n'
  exit 0
else
  echo "RESULT: FAIL —"
  for h in "${HITS[@]}"; do echo "  - $h"; done
  [ "$JSON_MODE" = "1" ] && printf '{"verdict":"FAIL","hits":%s}\n' "${#HITS[@]}"
  exit 1
fi
