#!/usr/bin/env bash
# 11-run-qc-checklist.sh — Skill 38 Pre-Handoff QC (mechanical checks)
# Automates the file-existence / cron / config-validate / tunnel-curl
# items from protocols/pre-handoff-qc-protocol.md. Human-judgment items
# (tone, copy, agent behavior) stay in the markdown checklist.
#
# OS-aware (Darwin + Linux). Exit 0 on full pass, 1 if any item fails.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------- OS detection --------
OS_KERNEL="$(uname -s 2>/dev/null || echo unknown)"
case "$OS_KERNEL" in
  Darwin) OS=mac ;;
  Linux)  OS=linux ;;
  *)      OS=other ;;
esac

# -------- Master files dir --------
MASTER_FILES_POINTER="${HOME}/.openclaw/.skill-38-master-files-dir"
if [ -f "$MASTER_FILES_POINTER" ]; then
  MASTER_FILES_DIR="$(cat "$MASTER_FILES_POINTER")"
else
  MASTER_FILES_DIR="${MASTER_FILES_DIR:-}"
fi

PASS=0
FAIL=0
report_pass() { echo "  [PASS] $*"; PASS=$((PASS+1)); }
report_fail() { echo "  [FAIL] $*"; FAIL=$((FAIL+1)); }
section()     { echo ""; echo "=== $* ==="; }

# -------- Resolve skill 38 root --------
SKILL38_ROOT="${SKILL38_ROOT:-${HOME}/clawd/skills/38-openclaw-cloudflare-tunnel}"
if [ ! -d "$SKILL38_ROOT" ]; then
  # try a few common alternates
  for cand in \
    "${HOME}/.openclaw/skills/38-openclaw-cloudflare-tunnel" \
    "${HOME}/clawd/skills/38" \
    "${HOME}/.claude/skills/38-openclaw-cloudflare-tunnel"; do
    [ -d "$cand" ] && SKILL38_ROOT="$cand" && break
  done
fi

section "Skill 38 root"
if [ -d "$SKILL38_ROOT" ]; then
  report_pass "skill root: $SKILL38_ROOT"
else
  report_fail "skill root not found (SKILL38_ROOT=$SKILL38_ROOT)"
fi

# -------- File existence: protocols / templates / scripts / references --------
section "File existence — protocols/"
PROTOCOL_FILES=(
  "protocols/pre-handoff-qc-protocol.md"
  "protocols/qc-protocol.md"
  "protocols/handoff-protocol.md"
)
for f in "${PROTOCOL_FILES[@]}"; do
  if [ -f "$SKILL38_ROOT/$f" ]; then report_pass "$f"; else report_fail "MISSING: $f"; fi
done

section "File existence — templates/ (journey + channel)"
TEMPLATE_FILES=(
  "templates/channel-playbook-template.md"
  "templates/journey-template.md"
)
for f in "${TEMPLATE_FILES[@]}"; do
  if [ -f "$SKILL38_ROOT/$f" ]; then report_pass "$f"; else report_fail "MISSING: $f"; fi
done

section "File existence — scripts/ (install + QC)"
SCRIPT_FILES=(
  "scripts/11-run-qc-checklist.sh"
  "scripts/12-scaffold-channel-playbooks.sh"
)
for f in "${SCRIPT_FILES[@]}"; do
  if [ -f "$SKILL38_ROOT/$f" ]; then report_pass "$f"; else report_fail "MISSING: $f"; fi
done

section "File existence — references/"
REFERENCE_FILES=(
  "references/subagent-delegation-pattern.md"
)
for f in "${REFERENCE_FILES[@]}"; do
  if [ -f "$SKILL38_ROOT/$f" ]; then report_pass "$f"; else report_fail "MISSING: $f"; fi
done

# -------- openclaw cron list --------
section "openclaw cron list — 5 expected crons"
EXPECTED_CRONS=(
  "weekly-tune-up"
  "proactive-suggestions-scan"
  "model-version-freshness"
  "monthly-comprehensive-review"
  "system-health-heartbeat"
)
if command -v openclaw >/dev/null 2>&1; then
  CRON_OUT="$(openclaw cron list 2>&1 || true)"
  for name in "${EXPECTED_CRONS[@]}"; do
    if printf '%s\n' "$CRON_OUT" | grep -q "$name"; then
      report_pass "cron present: $name"
    else
      report_fail "cron MISSING: $name"
    fi
  done
else
  report_fail "openclaw CLI not on PATH — cannot verify cron list"
fi

# -------- openclaw config validate --------
section "openclaw config validate"
if command -v openclaw >/dev/null 2>&1; then
  if openclaw config validate >/dev/null 2>&1; then
    report_pass "config validates clean"
  else
    report_fail "openclaw config validate exited non-zero"
  fi
else
  report_fail "openclaw CLI not on PATH — cannot run config validate"
fi

# -------- Public tunnel curl --------
section "Public tunnel reachability"
if [ -n "${PUBLIC_HOSTNAME:-}" ] && [ -n "${ROUTE_ID:-}" ]; then
  URL="https://${PUBLIC_HOSTNAME}/hooks/${ROUTE_ID}"
  HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$URL" || echo "000")"
  case "$HTTP_CODE" in
    200|401|403|404|405)
      report_pass "tunnel live ($URL → HTTP $HTTP_CODE)"
      ;;
    000)
      report_fail "tunnel UNREACHABLE ($URL → connect/DNS failure)"
      ;;
    *)
      report_pass "tunnel responds ($URL → HTTP $HTTP_CODE)"
      ;;
  esac
else
  echo "  [SKIP] PUBLIC_HOSTNAME or ROUTE_ID not set; cannot probe tunnel"
fi

# -------- AGENTS.md marker blocks --------
section "AGENTS.md marker blocks"
AGENTS_MD="${AGENTS_MD:-${HOME}/.openclaw/AGENTS.md}"
[ -f "$AGENTS_MD" ] || AGENTS_MD="${MASTER_FILES_DIR:-}/AGENTS.md"
if [ -f "$AGENTS_MD" ]; then
  for marker in "INBOUND_WEBHOOK_CLASSIFICATION" "SKILL38_RUNTIME_ROUTING" "workflow-builder"; do
    if grep -q "$marker" "$AGENTS_MD"; then
      report_pass "AGENTS.md contains marker: $marker"
    else
      report_fail "AGENTS.md MISSING marker: $marker"
    fi
  done
else
  report_fail "AGENTS.md not found (tried \$AGENTS_MD and \$MASTER_FILES_DIR/AGENTS.md)"
fi

# -------- MEMORY.md marker block --------
section "MEMORY.md marker block"
MEMORY_MD="${MEMORY_MD:-${HOME}/.openclaw/MEMORY.md}"
[ -f "$MEMORY_MD" ] || MEMORY_MD="${MASTER_FILES_DIR:-}/MEMORY.md"
if [ -f "$MEMORY_MD" ]; then
  if grep -q "skill-38" "$MEMORY_MD" || grep -q "SKILL38_MEMORY_RULES" "$MEMORY_MD"; then
    report_pass "MEMORY.md contains skill-38 memory-rules block"
  else
    report_fail "MEMORY.md MISSING skill-38 memory-rules block"
  fi
else
  report_fail "MEMORY.md not found"
fi

# -------- 23-key GHL body linter (machine-enforced) --------
section "23-key GHL RAW BODY linter (qc-23-key-bodies.sh)"
QC_23="$SCRIPT_DIR/qc-23-key-bodies.sh"
[ -f "$QC_23" ] || QC_23="$SKILL38_ROOT/scripts/qc-23-key-bodies.sh"
if [ -f "$QC_23" ]; then
  if bash "$QC_23" >/dev/null 2>&1; then
    report_pass "all GHL RAW BODY examples are 23-key, flat, placeholder-free"
  else
    report_fail "qc-23-key-bodies.sh found 23-key-rule violation(s) — run it directly for detail"
  fi
else
  report_fail "qc-23-key-bodies.sh not found (looked in scripts/)"
fi

# -------- THE TRINITY registry completeness (machine-enforced) --------
section "THE TRINITY registry completeness (qc-trinity-registry.sh)"
QC_TRINITY="$SCRIPT_DIR/qc-trinity-registry.sh"
[ -f "$QC_TRINITY" ] || QC_TRINITY="$SKILL38_ROOT/scripts/qc-trinity-registry.sh"
if [ -f "$QC_TRINITY" ]; then
  TRINITY_RC=0
  bash "$QC_TRINITY" >/dev/null 2>&1 || TRINITY_RC=$?
  case "$TRINITY_RC" in
    0) report_pass "every registered workflow has its playbook + Build-with-AI prompt" ;;
    3) echo "  [SKIP] no conversation-workflows folder yet (nothing to check)" ;;
    *) report_fail "qc-trinity-registry.sh found incomplete trinity row(s) — run it directly for detail" ;;
  esac
else
  report_fail "qc-trinity-registry.sh not found (looked in scripts/)"
fi

# -------- MANDATORY GHL send-directive (machine-enforced) --------
section "MANDATORY GHL send-directive (qc-send-directive.sh)"
QC_SEND="$SCRIPT_DIR/qc-send-directive.sh"
[ -f "$QC_SEND" ] || QC_SEND="$SKILL38_ROOT/scripts/qc-send-directive.sh"
if [ -f "$QC_SEND" ]; then
  if bash "$QC_SEND" >/dev/null 2>&1; then
    report_pass "every GHL inbound server-mapping messageTemplate carries the SEND-directive (drafting != sending)"
  else
    report_fail "qc-send-directive.sh found a server template missing the SEND-directive — run it directly for detail"
  fi
else
  report_fail "qc-send-directive.sh not found (looked in scripts/)"
fi

# -------- MANDATORY conversation-memory (read-before + append-after) --------
section "MANDATORY conversation-memory (qc-conversation-memory.sh)"
QC_MEM="$SCRIPT_DIR/qc-conversation-memory.sh"
[ -f "$QC_MEM" ] || QC_MEM="$SKILL38_ROOT/scripts/qc-conversation-memory.sh"
if [ -f "$QC_MEM" ]; then
  if bash "$QC_MEM" >/dev/null 2>&1; then
    report_pass "every GHL inbound server-mapping messageTemplate READS the conversation log before replying and APPENDS after (single-turn sessions => log IS the memory)"
  else
    report_fail "qc-conversation-memory.sh found a server template missing the read-before/append-after steps — run it directly for detail"
  fi
else
  report_fail "qc-conversation-memory.sh not found (looked in scripts/)"
fi

# -------- MANDATORY per-playbook human-facing DOC (Notion → Docs → text) --------
section "MANDATORY per-playbook human-facing DOC (qc-playbook-doc.sh)"
QC_DOC="$SCRIPT_DIR/qc-playbook-doc.sh"
[ -f "$QC_DOC" ] || QC_DOC="$SKILL38_ROOT/scripts/qc-playbook-doc.sh"
if [ -f "$QC_DOC" ]; then
  DOC_RC=0
  bash "$QC_DOC" >/dev/null 2>&1 || DOC_RC=$?
  case "$DOC_RC" in
    0) report_pass "every conversation playbook has a recorded human-facing doc in the client's account (Notion → Google Docs → text)" ;;
    2) report_fail "qc-playbook-doc.sh: NO conversation playbooks exist yet — the base install must create the first playbook (appointment booking) AND its human-facing doc before hand-off" ;;
    3) echo "  [SKIP] no conversation-workflows folder yet (run after 01-locate-master-files-folder.sh / 09-install-conversation-workflows.sh)" ;;
    *) report_fail "qc-playbook-doc.sh found a playbook with NO recorded human-facing doc (the doc deliverable was skipped) — run it directly for detail" ;;
  esac
else
  report_fail "qc-playbook-doc.sh not found (looked in scripts/)"
fi

# -------- Client reference sheet copy-paste artifacts (machine-enforced) --------
section "Client reference sheet copy-paste artifacts (qc-reference-sheet.sh)"
QC_REF="$SCRIPT_DIR/qc-reference-sheet.sh"
[ -f "$QC_REF" ] || QC_REF="$SKILL38_ROOT/scripts/qc-reference-sheet.sh"
if [ -f "$QC_REF" ]; then
  if bash "$QC_REF" >/dev/null 2>&1; then
    report_pass "generated client reference sheet leads with 🚀 Quick Start (separate Authorization key+value + Content-Type key+value code blocks) then a full explanation, and carries the bearer token + copyable \`\`\`json Raw Body + hook URL + manual-fill steps + create-tag-first (Settings -> Tags) + post-build verification"
  else
    report_fail "qc-reference-sheet.sh: the generated reference sheet is MISSING a required artifact — 🚀 Quick Start, the after-it explanation, the separate Authorization/Content-Type key+value code blocks, the bearer token, the copyable \`\`\`json Raw Body, the hook URL, the manual-fill steps, the create-tag-first/Settings -> Tags instruction, or the post-build verification (this strands the client) — run it directly for detail"
  fi
else
  report_fail "qc-reference-sheet.sh not found (looked in scripts/)"
fi

# -------- MANDATORY Telegram doc-delivery (client always gets their link) --------
section "MANDATORY Telegram doc-delivery (qc-notify-client-doc.sh)"
QC_NOTIFY="$SCRIPT_DIR/qc-notify-client-doc.sh"
[ -f "$QC_NOTIFY" ] || QC_NOTIFY="$SKILL38_ROOT/scripts/qc-notify-client-doc.sh"
if [ -f "$QC_NOTIFY" ]; then
  if bash "$QC_NOTIFY" >/dev/null 2>&1; then
    report_pass "the client doc-delivery step (22-notify-client-doc.sh) exists, greps the transcripts for the chat id, is gated (clientDocDelivered + non-zero on miss), sends via the gateway, and is wired into the checklist + INSTRUCTIONS — every client gets their link via Telegram, no matter what"
  else
    report_fail "qc-notify-client-doc.sh: the mandatory Telegram doc-delivery step is missing or not wired — run it directly for detail"
  fi
else
  report_fail "qc-notify-client-doc.sh not found (looked in scripts/)"
fi

# -------- Backend ready to RECEIVE (live completion gate) --------
# Testing happens ONLY after BOTH the client doc exists (qc-reference-sheet.sh,
# above) AND the backend is ready to receive: hooks.mappings live + deliver:false
# + a working model + healthz 200. On a box with no install this exits 3 (SKIP).
section "Backend ready to RECEIVE (qc-backend-ready.sh)"
QC_BACKEND="$SCRIPT_DIR/qc-backend-ready.sh"
[ -f "$QC_BACKEND" ] || QC_BACKEND="$SKILL38_ROOT/scripts/qc-backend-ready.sh"
if [ -f "$QC_BACKEND" ]; then
  BACKEND_RC=0
  bash "$QC_BACKEND" >/dev/null 2>&1 || BACKEND_RC=$?
  case "$BACKEND_RC" in
    0) report_pass "backend ready to receive: hooks.mappings live + deliver:false + a working model + healthz 200 (testing may proceed once the client doc gate also passes)" ;;
    3) echo "  [SKIP] no openclaw.json on this box — cannot verify backend readiness here" ;;
    *) report_fail "qc-backend-ready.sh: backend NOT ready to receive (hooks.mappings / deliver:false / model / healthz) — do NOT test, do NOT hand off; run it directly for detail" ;;
  esac
else
  report_fail "qc-backend-ready.sh not found (looked in scripts/)"
fi

# -------- AI BACKEND SELF-TEST (blocking readiness gate) --------
# The agent self-tests the FULL chain by GROUND TRUTH BEFORE the client ever
# tests: backend prepared -> POST a synthetic 23-key GHL inbound to its OWN
# public hook with the real Bearer token -> verify the hook 200s, the run used
# the configured model with no 401/429, the agent read the log, and the GHL
# Conversations API send returned a messageId (temp test contact created + then
# deleted, test log removed). On a repo/CI box with no install it exits 3 (SKIP).
section "AI backend self-test (24-self-test-hook.sh — blocking readiness gate)"
QC_SELFTEST="$SCRIPT_DIR/24-self-test-hook.sh"
[ -f "$QC_SELFTEST" ] || QC_SELFTEST="$SKILL38_ROOT/scripts/24-self-test-hook.sh"
if [ -f "$QC_SELFTEST" ]; then
  SELFTEST_RC=0
  bash "$QC_SELFTEST" --live >/dev/null 2>&1 || SELFTEST_RC=$?
  case "$SELFTEST_RC" in
    0) report_pass "backend self-test GREEN: synthetic inbound -> hook 200 -> configured model (no 401/429) -> read the log -> GHL send returned a messageId (temp contact + test log cleaned up). Client may be told to test." ;;
    3) echo "  [SKIP] no openclaw.json on this box — cannot run the live self-test here" ;;
    *) report_fail "24-self-test-hook.sh: backend self-test FAILED — FIX the failing hop (creds/location, model/provider key, DND, secrets/.env placement, URL/route/token) and RE-RUN. Do NOT hand off; do NOT tell the client to test." ;;
  esac
else
  report_fail "24-self-test-hook.sh not found (looked in scripts/)"
fi

# -------- Config schema-safety (machine-enforced) --------
section "Config schema-safety — no config-invalidating install scripts (qc-config-schema-safety.sh)"
QC_CFG="$SCRIPT_DIR/qc-config-schema-safety.sh"
[ -f "$QC_CFG" ] || QC_CFG="$SKILL38_ROOT/scripts/qc-config-schema-safety.sh"
if [ -f "$QC_CFG" ]; then
  if bash "$QC_CFG" >/dev/null 2>&1; then
    report_pass "no install script writes .cron.jobs / agents.defaults.async-batch and no script uses jq '//= …;' (all would break openclaw config validate / jq 1.7)"
  else
    report_fail "qc-config-schema-safety.sh found a config-invalidating script (.cron.jobs write, agents.defaults.async/.batch write, or jq '//= …;') — run it directly for detail"
  fi
else
  report_fail "qc-config-schema-safety.sh not found (looked in scripts/)"
fi

# -------- NO personal/client data (universal-skill guard) --------
section "No personal/client data — universal-skill guard (qc-no-personal-data.sh)"
QC_NOPD="$SCRIPT_DIR/qc-no-personal-data.sh"
[ -f "$QC_NOPD" ] || QC_NOPD="$SKILL38_ROOT/scripts/qc-no-personal-data.sh"
if [ -f "$QC_NOPD" ]; then
  if bash "$QC_NOPD" >/dev/null 2>&1; then
    report_pass "no personal/client identifiers anywhere in the skill or its generated output (this is a UNIVERSAL skill)"
  else
    report_fail "qc-no-personal-data.sh found a personal/client identifier in the skill or its generated output — genericize it; run it directly for detail"
  fi
else
  report_fail "qc-no-personal-data.sh not found (looked in scripts/)"
fi

# -------- Final summary --------
section "QC SUMMARY"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo ""
  echo "  RESULT: PASS — all mechanical QC items green. Proceed to human-judgment items in protocols/pre-handoff-qc-protocol.md."
  exit 0
else
  echo ""
  echo "  RESULT: FAIL — $FAIL item(s) need attention. Do NOT seal the Run Manifest."
  exit 1
fi
