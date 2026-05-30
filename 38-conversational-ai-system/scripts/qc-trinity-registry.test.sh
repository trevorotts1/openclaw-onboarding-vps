#!/usr/bin/env bash
# qc-trinity-registry.test.sh — fixture tests for qc-trinity-registry.sh.
#
# Proves the validator reconciles against the REAL registry format the installer
# (09-install-conversation-workflows.sh) actually writes: the BULLET form
# `<workflow-id>: <one-line description>` under the "## Active workflows"
# heading — not just the documented markdown TABLE.
#
# Each case builds a throwaway conversation-workflows/ folder, runs
# qc-trinity-registry.sh --dir <fixture> --json, and asserts the verdict +
# the specific problems detected.
#
# Exit 0 = all cases pass; 1 = a case failed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QC="$SCRIPT_DIR/qc-trinity-registry.sh"

if [ ! -f "$QC" ]; then
  echo "FATAL: qc-trinity-registry.sh not found next to this test ($QC)" >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

# run_case <name> <dir> <expected_verdict> <expect_grep_in_json>
# expect_grep_in_json may be empty to skip the substring check.
run_case() {
  local name="$1" dir="$2" want_verdict="$3" want_grep="${4:-}"
  local out
  out="$(bash "$QC" --dir "$dir" --json 2>&1)"
  local got_verdict
  got_verdict="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("verdict","<parse-error>"))' 2>/dev/null || echo "<parse-error>")"

  local ok=1
  if [ "$got_verdict" != "$want_verdict" ]; then
    ok=0
  fi
  if [ -n "$want_grep" ] && ! printf '%s' "$out" | grep -q "$want_grep"; then
    ok=0
  fi

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

# Writes a bullet-form registry exactly like 09-install-conversation-workflows.sh:
# an "## Active workflows" heading followed by `<id>: <desc>` bullets.
write_bullet_registry() {
  local dir="$1"; shift
  {
    echo "# Conversation Workflows — Registry"
    echo ""
    echo "## Active workflows"
    echo ""
    echo "(Append one bullet per installed workflow — \`<workflow-id>: <one-line description>\`.)"
    echo ""
    for b in "$@"; do
      echo "- $b"
    done
  } > "$dir/registry.md"
}

echo "=== qc-trinity-registry fixture tests (bullet format) ==="

# ---------------------------------------------------------------------------
# Case 1: BULLET form, fully complete (playbook + prompt) => PASS.
# ---------------------------------------------------------------------------
C1="$TMP_ROOT/c1"; mkdir -p "$C1"
write_bullet_registry "$C1" "webinar-followup: re-engage Tuesday webinar leads"
: > "$C1/webinar-followup.md"
: > "$C1/webinar-followup--build-with-ai-prompt.md"
run_case "bullet: complete trinity" "$C1" "PASS"

# ---------------------------------------------------------------------------
# Case 2: BULLET form, registered-but-missing-files => FAIL.
# The bullet names a workflow that has NO files on disk.
# ---------------------------------------------------------------------------
C2="$TMP_ROOT/c2"; mkdir -p "$C2"
write_bullet_registry "$C2" "pricing-inquiry: answer pricing questions"
# (no pricing-inquiry.md, no prompt)
run_case "bullet: registered but no files on disk" "$C2" "FAIL" "no files on disk"

# ---------------------------------------------------------------------------
# Case 3: BULLET form, file-present-but-unregistered slug => FAIL.
# A playbook (+prompt) exists on disk but the registry bullets don't list it.
# ---------------------------------------------------------------------------
C3="$TMP_ROOT/c3"; mkdir -p "$C3"
write_bullet_registry "$C3" "pricing-inquiry: answer pricing questions"
: > "$C3/pricing-inquiry.md"
: > "$C3/pricing-inquiry--build-with-ai-prompt.md"
# Unregistered extra on disk:
: > "$C3/refund-handling.md"
: > "$C3/refund-handling--build-with-ai-prompt.md"
run_case "bullet: file present but unregistered" "$C3" "FAIL" "not registered in registry.md"

# ---------------------------------------------------------------------------
# Case 4: BULLET form, playbook present but Build-with-AI prompt missing, and
# the bullet gives NO Layer-1 hint => unknown disposition => must FAIL.
# ---------------------------------------------------------------------------
C4="$TMP_ROOT/c4"; mkdir -p "$C4"
write_bullet_registry "$C4" "onboarding-welcome: greet new signups"
: > "$C4/onboarding-welcome.md"
# (no --build-with-ai-prompt.md)
run_case "bullet: playbook w/o prompt, no Layer-1 hint" "$C4" "FAIL" "Build-with-AI prompt MISSING"

# ---------------------------------------------------------------------------
# Case 5: BULLET form with an explicit "uses existing inbound" hint => the
# prompt is legitimately absent => PASS.
# ---------------------------------------------------------------------------
C5="$TMP_ROOT/c5"; mkdir -p "$C5"
write_bullet_registry "$C5" "faq-general: answer common questions (uses existing inbound routing)"
: > "$C5/faq-general.md"
# (no prompt — and that's fine, Layer 1 not needed)
run_case "bullet: Layer-1=No hint, prompt-free OK" "$C5" "PASS"

# ---------------------------------------------------------------------------
# Case 6: regression — TABLE form still parses and a 'No' row stays prompt-free.
# ---------------------------------------------------------------------------
C6="$TMP_ROOT/c6"; mkdir -p "$C6"
{
  echo "# Conversation Workflows Registry"
  echo ""
  echo "| ID | Name | Trigger summary | Layer 1? | OpenClaw playbook | GHL prompt | Verification checklist |"
  echo "|---|---|---|---|---|---|---|"
  echo "| pricing-inquiry | Pricing Q | price, cost | No (uses existing inbound) | pricing-inquiry.md | n/a | n/a |"
} > "$C6/registry.md"
: > "$C6/pricing-inquiry.md"
run_case "table: Layer-1=No row, prompt-free OK" "$C6" "PASS"

# ---------------------------------------------------------------------------
# Case 7: regression — TABLE form 'Yes' row missing its prompt => FAIL.
# ---------------------------------------------------------------------------
C7="$TMP_ROOT/c7"; mkdir -p "$C7"
{
  echo "# Conversation Workflows Registry"
  echo ""
  echo "| ID | Name | Trigger summary | Layer 1? | OpenClaw playbook | GHL prompt | Verification checklist |"
  echo "|---|---|---|---|---|---|---|"
  echo "| webinar-followup | Webinar | tag webinar-attendee | Yes | webinar-followup.md | webinar-followup--build-with-ai-prompt.md | n/a |"
} > "$C7/registry.md"
: > "$C7/webinar-followup.md"
# (prompt file deliberately NOT created, though table claims it)
run_case "table: Layer-1=Yes row missing prompt" "$C7" "FAIL" "Build-with-AI prompt MISSING"

echo ""
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — qc-trinity-registry reconciles bullet AND table registries."
  exit 0
else
  echo "RESULT: FAIL — $FAIL fixture case(s) failed."
  exit 1
fi
