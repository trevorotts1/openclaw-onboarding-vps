#!/usr/bin/env bash
# qc-send-directive.sh — machine-enforce the MANDATORY GHL send-directive.
#
# ROOT CAUSE this gate kills: if the GHL inbound hook's SERVER-mapping
# `messageTemplate` does not EXPLICITLY order the agent to SEND its reply via
# the GHL Conversations API, the model drafts a reply and stops — drafting is
# NOT sending, and the customer receives nothing. The send-directive must be
# present in EVERY GHL inbound server-mapping messageTemplate. This is enforced,
# not optional.
#
# WHAT IT SCANS (the load-bearing send-directive carrier = the OpenClaw
# `hooks.mappings` SERVER mapping messageTemplate, a.k.a. object B):
#   1. The INSTALLER canonical template — the messageTemplate the installer
#      WRITES in scripts/15-configure-hooks-mappings.sh (NEW_MAPPING). It must
#      NOT be possible to install a GHL hook whose messageTemplate lacks the
#      send-directive, so this file is checked explicitly and is REQUIRED.
#   2. Every canonical server-mapping messageTemplate embedded in references/ +
#      templates/ + scripts/ — detected by the canonical inbound signature
#      "INBOUND MESSAGE FROM GOHIGHLEVEL" (the server mapping that actually
#      builds the agent prompt). Each such template must carry the directive.
#
# WHY NOT THE GHL BODY messageTemplate: the GHL Custom Webhook RAW BODY (object
# A, snake_case "agent_id", placeholder-free, 23 keys) carries an INERT
# messageTemplate that the server mapping OVERRIDES at runtime — the directive
# that actually reaches the agent lives on the server mapping. The body's 23-key
# placeholder-free rule is enforced separately by qc-23-key-bodies.sh.
#
# REQUIRED ELEMENTS (all must be present in each server-mapping messageTemplate;
# wording may vary but every element is mandatory):
#   - the word SEND (the imperative)
#   - the GHL Conversations API (phrase "GHL Conversations API" or the endpoint
#     "conversations/messages")
#   - the drafting-is-NOT-sending clause
#   - "do not end the turn until a messageId/conversationId is returned"
#
# Exit codes: 0 = all server-mapping send-directives present and complete;
#             1 = one or more violations (missing element, or installer template
#                 missing/lacking the directive);
#             2 = no server-mapping templates found (the scan target moved — the
#                 linter went blind; treated as FAILURE).
#
# Usage:
#   bash scripts/qc-send-directive.sh            # human output
#   bash scripts/qc-send-directive.sh --json     # machine output
#   bash scripts/qc-send-directive.sh --skill-dir /path/to/38-conversational-ai-system

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
JSON_MODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --skill-dir) SKILL_DIR="$2"; shift 2 ;;
    --json) JSON_MODE=1; shift ;;
    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

export SKILL_DIR JSON_MODE

python3 - <<'PYEOF'
import os
import re
import json
import sys
from pathlib import Path

SKILL_DIR = Path(os.environ["SKILL_DIR"])
JSON_MODE = os.environ.get("JSON_MODE", "0") == "1"

SCAN_DIRS = ["references", "templates", "scripts"]

# The canonical server-mapping (object B) signature. The installer + the v6.0
# playbook + GHL-INBOUND all open the server template with this exact phrase.
SERVER_SIGNATURE = "INBOUND MESSAGE FROM GOHIGHLEVEL"

# The installer file whose written messageTemplate MUST carry the directive.
INSTALLER_REL = "scripts/15-configure-hooks-mappings.sh"


def check_directive(text):
    """Return a list of missing-element strings for one messageTemplate value.
    Empty list == the full send-directive is present."""
    missing = []
    low = text.lower()

    # 1. The imperative word SEND (uppercase, the directive emphasizes it).
    if "SEND" not in text:
        missing.append('missing the imperative word "SEND" (uppercase)')

    # 2. The GHL Conversations API (phrase or the endpoint).
    if ("ghl conversations api" not in low) and ("conversations/messages" not in low):
        missing.append('missing the GHL Conversations API ("GHL Conversations API" or "conversations/messages")')

    # 3. The drafting-is-NOT-sending clause.
    has_not_sending = ("not sending" in low) or ("is not sending" in low)
    mentions_draft = ("draft" in low) or ("compos" in low)
    if not (has_not_sending and mentions_draft):
        missing.append('missing the drafting-is-NOT-sending clause ("drafting/composing ... is NOT sending")')

    # 4. Do-not-end-turn-until-messageId.
    has_messageid = ("messageid" in low) or ("conversationid" in low)
    has_dont_end = bool(re.search(r"do\s*not\s+end", low) or re.search(r"don't\s+end", low))
    if not (has_messageid and has_dont_end):
        missing.append('missing "do NOT end your turn until a messageId/conversationId is returned"')

    return missing


def extract_message_templates(raw):
    """Yield every messageTemplate VALUE in a chunk of text. Handles JSON-style
    double-quoted values (incl. escaped quotes) and the installer's bash jq form
    (messageTemplate:"..." with bash-escaped single quotes)."""
    # JSON / jq style:  "messageTemplate": "...."   or   messageTemplate:"...."
    for m in re.finditer(r'"?messageTemplate"?\s*:\s*"((?:[^"\\]|\\.)*)"', raw):
        yield m.group(1)


def collect():
    findings = []           # {file, kind, value, missing}
    server_templates = 0
    installer_seen = False
    installer_has_directive = False

    for sub in SCAN_DIRS:
        d = SKILL_DIR / sub
        if not d.is_dir():
            continue
        for f in sorted(d.rglob("*")):
            if not f.is_file() or f.suffix not in (".md", ".sh", ".txt"):
                continue
            try:
                text = f.read_text(errors="ignore")
            except Exception:
                continue
            rel = str(f.relative_to(SKILL_DIR))
            is_installer = (rel == INSTALLER_REL)
            for val in extract_message_templates(text):
                if SERVER_SIGNATURE not in val:
                    continue  # not a server-mapping inbound template
                server_templates += 1
                missing = check_directive(val)
                if is_installer:
                    installer_seen = True
                    if not missing:
                        installer_has_directive = True
                findings.append({
                    "file": rel,
                    "kind": "installer" if is_installer else "reference",
                    "missing": missing,
                })
    return findings, server_templates, installer_seen, installer_has_directive


findings, server_templates, installer_seen, installer_has_directive = collect()

violations = [r for r in findings if r["missing"]]

# Hard requirement: the installer's written server template must exist AND carry
# the directive — it must be impossible to install a hook without the directive.
installer_error = None
if not installer_seen:
    installer_error = (
        f"INSTALLER GATE FAILED: no server-mapping messageTemplate found in "
        f"{INSTALLER_REL} (the canonical template the installer writes is missing "
        f"or no longer matches the '{SERVER_SIGNATURE}' signature)."
    )
elif not installer_has_directive:
    installer_error = (
        f"INSTALLER GATE FAILED: {INSTALLER_REL} writes a server-mapping "
        f"messageTemplate that lacks the full send-directive."
    )

failed = bool(violations) or (server_templates == 0) or (installer_error is not None)

if JSON_MODE:
    print(json.dumps({
        "scanned_server_templates": server_templates,
        "installer_template_present": installer_seen,
        "installer_template_has_directive": installer_has_directive,
        "installer_error": installer_error,
        "violations": violations,
        "verdict": "PASS" if not failed else ("NO_TEMPLATES" if server_templates == 0 else "FAIL"),
    }, indent=2))
else:
    print("=== qc-send-directive: MANDATORY GHL send-directive linter ===")
    print(f"skill_dir : {SKILL_DIR}")
    print(f"scanned   : {server_templates} server-mapping inbound messageTemplate(s)")
    print(f"installer : {INSTALLER_REL} "
          f"({'present' if installer_seen else 'MISSING'}; "
          f"{'directive OK' if installer_has_directive else 'directive ABSENT'})")
    print("")
    for r in findings:
        tag = "PASS" if not r["missing"] else "FAIL"
        print(f"  [{tag}] {r['file']} ({r['kind']} server template)")
        for m in r["missing"]:
            print(f"          - {m}")
    if installer_error:
        print("")
        print(f"  {installer_error}")
    print("")
    if server_templates == 0:
        print("RESULT: NO SERVER TEMPLATES FOUND — the scan target moved; the linter is blind. Treating as FAIL.")
    elif failed:
        n = len(violations) + (1 if installer_error else 0)
        print(f"RESULT: FAIL — {n} send-directive violation(s). A drafted-but-unsent reply is a failure; fix the template(s).")
    else:
        print(f"RESULT: PASS — all {server_templates} GHL server-mapping messageTemplate(s) carry the full send-directive.")

if server_templates == 0:
    sys.exit(2)
sys.exit(1 if failed else 0)
PYEOF
