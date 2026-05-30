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
  for marker in "INBOUND_WEBHOOK_CLASSIFICATION" "SKILL38_RUNTIME_ROUTING" "workflow-builder" \
                "SKILL38_ZHC_TAG_PREFIX" "STEP_1_35_AGGRESSION_PRE_ROUTING" "STEP_1_42_INTERRUPTS_AND_FAQ" \
                "STEP_2_0_GEO_QUALIFICATION" "STEP_2_5_CRM_FIELD_WRITE"; do
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

# -------- Backend self-test STANDARD (static gate — proves the self-test exists + is wired) --------
section "Backend self-test standard (qc-self-test.sh)"
QC_SELFTEST_STD="$SCRIPT_DIR/qc-self-test.sh"
[ -f "$QC_SELFTEST_STD" ] || QC_SELFTEST_STD="$SKILL38_ROOT/scripts/qc-self-test.sh"
if [ -f "$QC_SELFTEST_STD" ]; then
  if bash "$QC_SELFTEST_STD" >/dev/null 2>&1; then
    report_pass "qc-self-test.sh: the backend self-test (24-self-test-hook.sh) exists, POSTs a synthetic flat-23-key inbound with the real Bearer, verifies 200/{ok:true} + no 401/429 + log read + GHL send + temp-contact cleanup, and is wired as a blocking readiness gate + documented"
  else
    report_fail "qc-self-test.sh: the backend self-test standard is missing or not wired — run it directly for detail"
  fi
else
  report_fail "qc-self-test.sh not found (looked in scripts/)"
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

# -------- TOOLS.md GHL API quick-reference (machine-enforced) --------
# Two checks: (1) the SOURCE block that 24-update-tools-md.sh injects is complete +
# concise + leak-free (always runnable, no install needed); (2) if a client
# workspace TOOLS.md exists, the injected marker block is present + valid (LIVE).
section "TOOLS.md GHL API quick-reference (qc-tools-md-ghl-ref.sh)"
QC_TOOLS="$SCRIPT_DIR/qc-tools-md-ghl-ref.sh"
[ -f "$QC_TOOLS" ] || QC_TOOLS="$SKILL38_ROOT/scripts/qc-tools-md-ghl-ref.sh"
if [ -f "$QC_TOOLS" ]; then
  # (1) source block (the canonical reference that gets injected)
  if bash "$QC_TOOLS" >/dev/null 2>&1; then
    report_pass "GHL API quick-reference SOURCE block is complete (all messaging types + calendars + appointments + invoices), carries every required scope, is concise, and has zero personal/client data"
  else
    report_fail "qc-tools-md-ghl-ref.sh: the GHL API quick-reference source block is incomplete / oversized / leaks client data — run it directly for detail"
  fi
  # (2) live: is the marker block actually injected into the client TOOLS.md?
  CLIENT_TOOLS=""
  for T in "/data/.openclaw/workspace/TOOLS.md" "$HOME/.openclaw/workspace/TOOLS.md"; do
    [ -f "$T" ] && CLIENT_TOOLS="$T" && break
  done
  if [ -n "$CLIENT_TOOLS" ]; then
    TOOLS_RC=0
    bash "$QC_TOOLS" --tools-md "$CLIENT_TOOLS" >/dev/null 2>&1 || TOOLS_RC=$?
    case "$TOOLS_RC" in
      0) report_pass "client TOOLS.md ($CLIENT_TOOLS) has the GHL API quick-reference block — the agent has the canonical request shapes in core context" ;;
      3) report_fail "client TOOLS.md ($CLIENT_TOOLS) is MISSING the GHL quick-reference block — run scripts/24-update-tools-md.sh, then re-check" ;;
      *) report_fail "qc-tools-md-ghl-ref.sh: the injected block in $CLIENT_TOOLS is incomplete / oversized / leaks client data — run it directly for detail" ;;
    esac
  else
    echo "  [SKIP] no client workspace TOOLS.md on this box — source-block check above still applies"
  fi
else
  report_fail "qc-tools-md-ghl-ref.sh not found (looked in scripts/)"
fi

# -------- ZHC tag-prefix rule (machine-enforced) --------
section "ZHC- programmatic tag-prefix (qc-zhc-tag-prefix.sh)"
QC_ZHC="$SCRIPT_DIR/qc-zhc-tag-prefix.sh"
[ -f "$QC_ZHC" ] || QC_ZHC="$SKILL38_ROOT/scripts/qc-zhc-tag-prefix.sh"
if [ -f "$QC_ZHC" ]; then
  if bash "$QC_ZHC" >/dev/null 2>&1; then
    report_pass "every programmatic tag example is ZHC- prefixed (rule documented, canonical tags present, no bare create-tag literal)"
  else
    report_fail "qc-zhc-tag-prefix.sh found a ZHC- prefix violation — run it directly for detail"
  fi
else
  report_fail "qc-zhc-tag-prefix.sh not found (looked in scripts/)"
fi

# -------- ZHC Pixel (Feature 49) invariants (machine-enforced) --------
section "ZHC Pixel rule (qc-zhc-pixel.sh)"
QC_PIXEL="$SCRIPT_DIR/qc-zhc-pixel.sh"
[ -f "$QC_PIXEL" ] || QC_PIXEL="$SKILL38_ROOT/scripts/qc-zhc-pixel.sh"
if [ -f "$QC_PIXEL" ]; then
  if bash "$QC_PIXEL" >/dev/null 2>&1; then
    report_pass "ZHC Pixel (F49) invariants hold: pixel JS template + 3 placeholders + generator; pixel-visitor-signal hook (deliver:false, bot-gate-first, scoped Pixel Concierge + hook:pixel: allow-list); STEP_1_45_PIXEL_CONCIERGE AGENTS block + protocol; ZHC-/ZHC_ prefixes; GDPR/CCPA/DNT/deletion privacy controls; scope precheck + gated deploy; no personal data"
  else
    report_fail "qc-zhc-pixel.sh found an F49 invariant violation — run it directly for detail"
  fi
else
  report_fail "qc-zhc-pixel.sh not found (looked in scripts/)"
fi

# -------- F52 JSONL data contract (machine-enforced) --------
section "F52 JSONL data contract (qc-feature-logs.sh)"
QC_LOGS="$SCRIPT_DIR/qc-feature-logs.sh"
[ -f "$QC_LOGS" ] || QC_LOGS="$SKILL38_ROOT/scripts/qc-feature-logs.sh"
if [ -f "$QC_LOGS" ]; then
  if bash "$QC_LOGS" >/dev/null 2>&1; then
    report_pass "all five Round-3 feature logs are JSONL (timestamp+event_type), documented in protocol + INSTRUCTIONS.md, and seeded by the installer"
  else
    report_fail "qc-feature-logs.sh found an F52 data-contract violation — run it directly for detail"
  fi
else
  report_fail "qc-feature-logs.sh not found (looked in scripts/)"
fi

# -------- F45 + F47 behavioral substance (machine-enforced) --------
section "F45 + F47 substance (qc-f45-f47-substance.sh)"
QC_F45F47="$SCRIPT_DIR/qc-f45-f47-substance.sh"
[ -f "$QC_F45F47" ] || QC_F45F47="$SKILL38_ROOT/scripts/qc-f45-f47-substance.sh"
if [ -f "$QC_F45F47" ]; then
  if bash "$QC_F45F47" >/dev/null 2>&1; then
    report_pass "F45 (geo) + F47 (smart FAQ) carry every roadmap substance point: F47 = parallel layer alongside the workflow, a SENTENCE not a sub-flow, the 'By the way…Coming back to' handoff, sales-vs-ops faq-scope, faqs.md match, the F44-vs-F47 difference, ZHC-faq-detoured hand-off, ZHC-faq-answered, faq-detour-log.jsonl; F45 = default-OFF + per-product toggle, pixel/IP->area-code->form->ask priority, ALWAYS-confirm + exact question + all 5 branches (here/elsewhere/vacation/moving/no-engagement=do-not-disqualify), 4 out-of-area modes, service-areas.md (radius/zips/states/counties), the 3 ZHC tags, geo-qualification-log.jsonl + confirmed_with_customer invariant"
  else
    report_fail "qc-f45-f47-substance.sh found a missing F45/F47 substance point — run it directly for detail"
  fi
else
  report_fail "qc-f45-f47-substance.sh not found (looked in scripts/)"
fi

# -------- Communications Playbook Standard (machine-enforced) --------
section "Communications Playbook Standard (qc-communications-playbook-standard.sh)"
QC_CPS="$SCRIPT_DIR/qc-communications-playbook-standard.sh"
[ -f "$QC_CPS" ] || QC_CPS="$SKILL38_ROOT/scripts/qc-communications-playbook-standard.sh"
if [ -f "$QC_CPS" ]; then
  if bash "$QC_CPS" >/dev/null 2>&1; then
    report_pass "Communications Playbook Standard carries its §0 'EVERY COMMUNICATION PLAYBOOK MUST INCLUDE ALL OF THE FOLLOWING' mandatory checklist + every required item (channel/persona, opening, goal, SEND rule, conversation-memory, escalation/honesty, quiet-hours/compliance, ZHC- tag prefix, per-channel formatting, the 8 channels)"
  else
    report_fail "qc-communications-playbook-standard.sh: the Communications Playbook Standard is missing a mandatory item — run it directly for detail"
  fi
else
  report_fail "qc-communications-playbook-standard.sh not found (looked in scripts/)"
fi

# -------- GHL Raw Body JSON Standard (machine-enforced) --------
section "GHL Raw Body JSON Standard (qc-ghl-raw-body-standard.sh)"
QC_RAWBODY="$SCRIPT_DIR/qc-ghl-raw-body-standard.sh"
[ -f "$QC_RAWBODY" ] || QC_RAWBODY="$SKILL38_ROOT/scripts/qc-ghl-raw-body-standard.sh"
if [ -f "$QC_RAWBODY" ]; then
  if bash "$QC_RAWBODY" >/dev/null 2>&1; then
    report_pass "GHL Raw Body JSON Standard documents the §0 'FULL 23-key FLAT JSON' rule + FLAT rule + placeholder-free messageTemplate + deliver:false + the exact 23 keys, AND every real object-A body obeys it (composes qc-23-key-bodies.sh)"
  else
    report_fail "qc-ghl-raw-body-standard.sh: the GHL Raw Body JSON Standard is incomplete or a real body violates the 23-key rule — run it directly for detail"
  fi
else
  report_fail "qc-ghl-raw-body-standard.sh not found (looked in scripts/)"
fi

# -------- Notion Client-Doc Standard (machine-enforced) --------
section "Notion Client-Doc Standard (qc-notion-doc-standard.sh)"
QC_NOTIONDOC="$SCRIPT_DIR/qc-notion-doc-standard.sh"
[ -f "$QC_NOTIONDOC" ] || QC_NOTIONDOC="$SKILL38_ROOT/scripts/qc-notion-doc-standard.sh"
if [ -f "$QC_NOTIONDOC" ]; then
  if bash "$QC_NOTIONDOC" >/dev/null 2>&1; then
    report_pass "Notion Client-Doc Standard documents the §0 ordered mandatory list (Quick-Start first, split Authorization two-block, split Content-Type, FLAT 23-key body, tags-first + manual-fill + Build-with-AI-shape-only + post-build VERIFY, Communication Playbooks section, VPS-vs-Mac, how-it-works LAST, each value its own code block, Telegram delivery, universal/no-personal-data), AND the generated doc conforms (composes qc-reference-sheet.sh)"
  else
    report_fail "qc-notion-doc-standard.sh: the Notion Client-Doc Standard is incomplete or the generated doc fails — run it directly for detail"
  fi
else
  report_fail "qc-notion-doc-standard.sh not found (looked in scripts/)"
fi

# -------- Multi-Tenant Agent Isolation (F21) invariant gate (machine-enforced) --------
section "Multi-tenant isolation rule (qc-multi-tenant.sh)"
QC_MT="$SCRIPT_DIR/qc-multi-tenant.sh"
[ -f "$QC_MT" ] || QC_MT="$SKILL38_ROOT/scripts/qc-multi-tenant.sh"
if [ -f "$QC_MT" ]; then
  if bash "$QC_MT" >/dev/null 2>&1; then
    report_pass "F21 multi-tenant isolation invariants hold (protocol + AGENTS Step 0.8 + MEMORY Rule 26, per-tenant scoping/namespacing + tenant.md config + hooks.mappings tenant_id convention, PII-free multi-tenant-events.jsonl seeded, per-tenant root scaffolded, toggle default OFF)"
  else
    report_fail "qc-multi-tenant.sh found an F21 invariant violation — run it directly for detail"
  fi
else
  report_fail "qc-multi-tenant.sh not found (looked in scripts/)"
fi

# -------- Customer Segmentation Awareness (F17) invariant gate (machine-enforced) --------
section "Customer segmentation rule (qc-segmentation.sh)"
QC_SEG="$SCRIPT_DIR/qc-segmentation.sh"
[ -f "$QC_SEG" ] || QC_SEG="$SKILL38_ROOT/scripts/qc-segmentation.sh"
if [ -f "$QC_SEG" ]; then
  if bash "$QC_SEG" >/dev/null 2>&1; then
    report_pass "F17 customer segmentation invariants hold (protocol + AGENTS Step 1.85 + MEMORY Rule 27, five segments + per-client tag_map/segment-map.md mapping + multi-tag precedence + the four behavior overrides + before-reply-draft placement + ZHC-segment- tag prefix + operator-only guard, PII-free segmentation-events.jsonl seeded with the segment-map.md companion, toggle default OFF)"
  else
    report_fail "qc-segmentation.sh found an F17 invariant violation — run it directly for detail"
  fi
else
  report_fail "qc-segmentation.sh not found (looked in scripts/)"
fi

# -------- Proactive Outreach Campaigns (F15) invariant gate (machine-enforced) --------
section "Proactive outreach campaigns rule (qc-proactive-outreach.sh)"
QC_OUTREACH="$SCRIPT_DIR/qc-proactive-outreach.sh"
[ -f "$QC_OUTREACH" ] || QC_OUTREACH="$SKILL38_ROOT/scripts/qc-proactive-outreach.sh"
if [ -f "$QC_OUTREACH" ]; then
  if bash "$QC_OUTREACH" >/dev/null 2>&1; then
    report_pass "F15 proactive outreach invariants hold (protocol + MEMORY Rule 28, NO inbound AGENTS step — cron/event-driven, campaign-definition format cron|event trigger + GHL-tag audience + Communication-Playbook-rendered message + frequency cap + opt-out + ZHC-outreach- tag, STRICT quiet-hours respect Step 9.8, reactive-vs-proactive tracked separately via direction:proactive, operator-only/never-customer-invoked SEND, F29 migrates onto this infra, PII-free outreach-events.jsonl seeded with the outreach-campaigns/ dir + example campaign, toggle default OFF)"
  else
    report_fail "qc-proactive-outreach.sh found an F15 invariant violation — run it directly for detail"
  fi
else
  report_fail "qc-proactive-outreach.sh not found (looked in scripts/)"
fi

# -------- A/B Testing of Reply Variants (F16) invariant gate (machine-enforced) --------
section "A/B testing of reply variants rule (qc-ab-testing.sh)"
QC_ABTEST="$SCRIPT_DIR/qc-ab-testing.sh"
[ -f "$QC_ABTEST" ] || QC_ABTEST="$SKILL38_ROOT/scripts/qc-ab-testing.sh"
if [ -f "$QC_ABTEST" ]; then
  if bash "$QC_ABTEST" >/dev/null 2>&1; then
    report_pass "F16 A/B testing invariants hold (protocol + AGENTS Step 1.87 + MEMORY Rule 29, two variants a/b per channel + experiments/ab-experiments mapping + deterministic-by-contact sticky assignment + at-draft-time placement + the three outcome metrics booked/converted/sentiment + the two-proportion z-test with default N=30/arm + auto-promote-with-operator-notify + ZHC-abtest-variant- tags + operator-only/A-B-injection guard, PII-free ab-test-events.jsonl seeded with the ab-experiments/ scaffold, toggle default OFF)"
  else
    report_fail "qc-ab-testing.sh found an F16 invariant violation — run it directly for detail"
  fi
else
  report_fail "qc-ab-testing.sh not found (looked in scripts/)"
fi

section "Voice / phone integration rule (qc-voice-phone.sh)"
QC_VOICE="$SCRIPT_DIR/qc-voice-phone.sh"
[ -f "$QC_VOICE" ] || QC_VOICE="$SKILL38_ROOT/scripts/qc-voice-phone.sh"
if [ -f "$QC_VOICE" ]; then
  if bash "$QC_VOICE" >/dev/null 2>&1; then
    report_pass "F14 voice/phone invariants hold (protocol + MEMORY Rule 30 + setup wizard, STT Whisper-large-v3 via OpenRouter/Groq/Ollama -> brain -> TTS ElevenLabs Flash 2.5/OSS over Twilio Media Streams + /hooks/voice-call-event scaffolding + greeting->listen->respond->handoff/booking state machine + < 800ms first-audio target + degrade-to-text fallback + operator-only outbound-dial guard + ZHC-voice-* tags + the HONEST live-telephony gap, PII-free voice-call-events.jsonl seeded, toggle default OFF)"
  else
    report_fail "qc-voice-phone.sh found an F14 invariant violation — run it directly for detail"
  fi
else
  report_fail "qc-voice-phone.sh not found (looked in scripts/)"
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
