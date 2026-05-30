# Tier 2 Adapter-Authoring Protocol (Skill 40)

How to write a new Tier 2 platform adapter. An adapter abstracts ONE vendor
platform (used by many counties) so the engine covers any county on that vendor
without a per-county Tier 1 entry.

## The adapter contract
Every file in `scripts/adapters/*.sh` MUST implement exactly this CLI:

- `--vendor` → print the human vendor name (one line, exit 0).
- `--covers "<county>" "<state>"` → exit 0 if this adapter handles the county,
  non-zero otherwise. Coverage is operator-confirmed and EMPTY by default.
- `--plan "<county>" "<state>" "<record_type>" "<query>"` → print the LIVE-fetch
  plan (base URL pattern, search form, param, fetch method, attribution
  reminder). Exit 0 only if `--covers` would pass; else non-zero with a message.

The router (`02-detect-and-route.sh`) calls `--covers` on every adapter in turn;
the first that returns 0 wins Tier 2.

## Rules
1. **Coverage is operator-confirmed.** Never hardcode a county→vendor claim you
   have not confirmed. Default coverage EMPTY; the operator adds confirmed pairs
   (env var `SKILL40_<VENDOR>_COVERAGE` or editing the in-file list).
2. **No fabrication.** The `--plan` output is a fetch PLAN for the agent to
   execute LIVE; the adapter does not return invented record data.
3. **Compliance in the plan.** Every `--plan` reminds: respect robots.txt + ToS,
   attribute source + retrieval timestamp, honest-gap on unreachable/blocked.
4. **bash -n clean, `set -uo pipefail`.** No personal/client data (the
   `qc-no-personal-data.sh` gate scans adapters too).

## Pattern to copy
Start from `scripts/adapters/tyler-technologies.sh` (or `govos-landmark.sh`).
Change the VENDOR string, the coverage env var name, and the `--plan` body
describing that vendor's search form. Keep the contract identical.

## Verifying a new adapter
```bash
scripts/adapters/<your>.sh --vendor
SKILL40_<VENDOR>_COVERAGE="example county:ZZ" scripts/adapters/<your>.sh --covers "Example County" ZZ ; echo $?   # want 0
scripts/adapters/<your>.sh --covers "Nope County" ZZ ; echo $?                                                    # want non-zero
```
