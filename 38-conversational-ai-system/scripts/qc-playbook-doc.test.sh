#!/usr/bin/env bash
# qc-playbook-doc.test.sh — fixture tests for qc-playbook-doc.sh.
#
# The live gate runs against a client's installed conversation-workflows/ folder
# (needs a real install), so CI proves it via throwaway fixtures instead — same
# posture as qc-trinity-registry.test.sh. Each case builds a temp
# conversation-workflows/ folder (+ optional run manifest), runs
# qc-playbook-doc.sh --dir <fixture> [--manifest <m>] --json, and asserts the
# verdict + (optionally) the missing slug it flags.
#
# Exit 0 = all cases pass; 1 = a case failed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QC="$SCRIPT_DIR/qc-playbook-doc.sh"

if [ ! -f "$QC" ]; then
  echo "FATAL: qc-playbook-doc.sh not found next to this test ($QC)" >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

# run_case <name> <dir> <manifest-or-empty> <expected_verdict> <expect_grep_in_json>
run_case() {
  local name="$1" dir="$2" manifest="$3" want_verdict="$4" want_grep="${5:-}"
  local out
  if [ -n "$manifest" ]; then
    out="$(bash "$QC" --dir "$dir" --manifest "$manifest" --json 2>&1)"
  else
    out="$(bash "$QC" --dir "$dir" --json 2>&1)"
  fi
  local got_verdict
  got_verdict="$(printf '%s' "$out" | sed -n 's/.*"verdict"[[:space:]]*:[[:space:]]*"\([A-Z_]*\)".*/\1/p' | head -1)"
  [ -z "$got_verdict" ] && got_verdict="<parse-error>"

  local ok=1
  [ "$got_verdict" != "$want_verdict" ] && ok=0
  if [ -n "$want_grep" ] && ! printf '%s' "$out" | grep -q "$want_grep"; then ok=0; fi

  if [ "$ok" = "1" ]; then
    echo "  [PASS] $name (verdict=$got_verdict)"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $name"
    echo "         want verdict=$want_verdict grep='$want_grep'"
    echo "         got  verdict=$got_verdict"
    echo "         --- json ---"
    printf '%s\n' "$out" | sed 's/^/         /'
    FAIL=$((FAIL+1))
  fi
}

# Writes a bullet-form registry like 09-install-conversation-workflows.sh.
write_registry() {
  local dir="$1"; shift
  {
    echo "# Conversation Workflows — Registry"
    echo ""
    echo "## Active workflows"
    echo ""
    for b in "$@"; do
      echo "- $b"
    done
  } > "$dir/registry.md"
}

echo "=== qc-playbook-doc fixture tests ==="

# ---------------------------------------------------------------------------
# Case 1: doc URL recorded ON the registry row => PASS.
# ---------------------------------------------------------------------------
C1="$TMP_ROOT/c1"; mkdir -p "$C1"
: > "$C1/appointment-booking.md"
write_registry "$C1" "appointment-booking: book appts — doc: https://www.notion.so/appt-booking-abc123"
run_case "doc URL on registry row" "$C1" "" "PASS"

# ---------------------------------------------------------------------------
# Case 2: playbook on disk, NO doc anywhere => FAIL (the skip we're preventing).
# ---------------------------------------------------------------------------
C2="$TMP_ROOT/c2"; mkdir -p "$C2"
: > "$C2/appointment-booking.md"
write_registry "$C2" "appointment-booking: book appts"
run_case "playbook present, no doc => FAIL" "$C2" "" "FAIL" "appointment-booking"

# ---------------------------------------------------------------------------
# Case 3: doc recorded in the run manifest playbookDocs[] (Notion) => PASS.
# ---------------------------------------------------------------------------
C3="$TMP_ROOT/c3"; mkdir -p "$C3"
: > "$C3/appointment-booking.md"
write_registry "$C3" "appointment-booking: book appts"
M3="$TMP_ROOT/m3.md"
{
  echo "## Playbook docs"
  echo "playbookDocs[]: appointment-booking -> https://www.notion.so/client/appt-booking-xyz"
} > "$M3"
run_case "doc in manifest playbookDocs[] (Notion)" "$C3" "$M3" "PASS"

# ---------------------------------------------------------------------------
# Case 4: Google Docs fallback recorded in manifest => PASS.
# ---------------------------------------------------------------------------
C4="$TMP_ROOT/c4"; mkdir -p "$C4"
: > "$C4/appointment-booking.md"
write_registry "$C4" "appointment-booking: book appts"
M4="$TMP_ROOT/m4.md"
echo "playbookDocs[]: appointment-booking -> https://docs.google.com/document/d/abc/edit" > "$M4"
run_case "Google Docs fallback in manifest" "$C4" "$M4" "PASS"

# ---------------------------------------------------------------------------
# Case 5: plain-text fallback path recorded in manifest => PASS.
# ---------------------------------------------------------------------------
C5="$TMP_ROOT/c5"; mkdir -p "$C5"
: > "$C5/appointment-booking.md"
write_registry "$C5" "appointment-booking: book appts"
M5="$TMP_ROOT/m5.md"
echo "playbookDocs[]: appointment-booking -> /home/client/shared/appointment-booking-playbook.txt" > "$M5"
run_case "plain-text fallback path in manifest" "$C5" "$M5" "PASS"

# ---------------------------------------------------------------------------
# Case 6: manifest names the slug but with NO destination => still FAIL.
# (A bare playbookDocs[] line with no URL/path doesn't count as recorded.)
# ---------------------------------------------------------------------------
C6="$TMP_ROOT/c6"; mkdir -p "$C6"
: > "$C6/appointment-booking.md"
write_registry "$C6" "appointment-booking: book appts"
M6="$TMP_ROOT/m6.md"
echo "playbookDocs[]: appointment-booking -> (pending)" > "$M6"
run_case "manifest entry w/o destination => FAIL" "$C6" "$M6" "FAIL" "appointment-booking"

# ---------------------------------------------------------------------------
# Case 7: registered-but-not-on-disk slug still owes a doc => FAIL.
# ---------------------------------------------------------------------------
C7="$TMP_ROOT/c7"; mkdir -p "$C7"
write_registry "$C7" "pricing-inquiry: answer pricing questions"
run_case "registered slug, no doc => FAIL" "$C7" "" "FAIL" "pricing-inquiry"

# ---------------------------------------------------------------------------
# Case 8: empty folder (no playbooks at all) => NO_PLAYBOOKS (exit 2, not PASS).
# ---------------------------------------------------------------------------
C8="$TMP_ROOT/c8"; mkdir -p "$C8"
write_registry "$C8"   # heading only, no bullets
rc8=0
bash "$QC" --dir "$C8" >/dev/null 2>&1 || rc8=$?
out8="$(bash "$QC" --dir "$C8" --json 2>&1)"
v8="$(printf '%s' "$out8" | sed -n 's/.*"verdict"[[:space:]]*:[[:space:]]*"\([A-Z_]*\)".*/\1/p' | head -1)"
if [ "$v8" = "NO_PLAYBOOKS" ] && [ "$rc8" -eq 2 ]; then
  echo "  [PASS] empty folder => NO_PLAYBOOKS + exit 2 (verdict=$v8 rc=$rc8)"
  PASS=$((PASS+1))
else
  echo "  [FAIL] empty folder => expected NO_PLAYBOOKS + exit 2; got verdict=$v8 rc=$rc8"
  FAIL=$((FAIL+1))
fi

# ---------------------------------------------------------------------------
# Case 9: two playbooks, one with a doc, one without => FAIL naming the bad one.
# ---------------------------------------------------------------------------
C9="$TMP_ROOT/c9"; mkdir -p "$C9"
: > "$C9/appointment-booking.md"
: > "$C9/pricing-inquiry.md"
write_registry "$C9" \
  "appointment-booking: book appts — doc: https://www.notion.so/appt" \
  "pricing-inquiry: pricing Q"
run_case "mixed: one doc'd, one not => FAIL on the bad one" "$C9" "" "FAIL" "pricing-inquiry"

# ---------------------------------------------------------------------------
# Case 10: no conversation-workflows folder at all => NO_FOLDER (exit 3).
# ---------------------------------------------------------------------------
rc10=0
bash "$QC" --dir "$TMP_ROOT/does-not-exist" >/dev/null 2>&1 || rc10=$?
out10="$(bash "$QC" --dir "$TMP_ROOT/does-not-exist" --json 2>&1)"
v10="$(printf '%s' "$out10" | sed -n 's/.*"verdict"[[:space:]]*:[[:space:]]*"\([A-Z_]*\)".*/\1/p' | head -1)"
if [ "$v10" = "NO_FOLDER" ] && [ "$rc10" -eq 3 ]; then
  echo "  [PASS] missing folder => NO_FOLDER + exit 3 (verdict=$v10 rc=$rc10)"
  PASS=$((PASS+1))
else
  echo "  [FAIL] missing folder => expected NO_FOLDER + exit 3; got verdict=$v10 rc=$rc10"
  FAIL=$((FAIL+1))
fi

echo ""
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — qc-playbook-doc enforces the per-playbook human-facing doc deliverable."
  exit 0
else
  echo "RESULT: FAIL — $FAIL fixture case(s) failed."
  exit 1
fi
