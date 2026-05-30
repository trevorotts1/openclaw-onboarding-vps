# Skill 38 — Conversational AI System: Changelog

## [1.5.7] - 2026-05-30 - Round-2 backlog F21: Multi-Tenant Agent Isolation (the AGENCY tier, OFF by default)

### Why
Round-2 backlog feature 1 of 6. For an AGENCY running ON TOP of Convert-and-Flow (a client who serves
their OWN end-clients), each end-client now gets an ISOLATED agent context — Client A's data,
conversations, Knowledge Sources, Communication Playbooks, and Conversation Workflows NEVER leak to
Client B's agent. Unlocks the agency-tier sale; an operator running their own multi-tenant agency benefits first.
Toggle default OFF — most clients are single-tenant. Canonical content is byte-identical across
`openclaw-onboarding` (Mac) and `openclaw-onboarding-vps`; only repo-specific env (paths, qc-static line
positions) diverges.

### Added — `protocols/multi-tenant-isolation-protocol.md` (F21, Step 9.44), byte-identical across both repos
- The full isolation protocol: the opaque `tenant_id`; the `hooks.mappings` `tenant_id` routing convention
  (the authoritative "which tenant" source per turn); the per-tenant root `<MASTER_FILES_DIR>/tenants/<tenant_id>/`
  scoping ALL FOUR surfaces (conversation logs, typed Knowledge Sources, Communication Playbooks, Conversation
  Workflows); the per-tenant `tenant.md` config directive (declares the active tenant so the agent loads only
  that tenant's context); tenant resolution order (mapping `tenant_id` → AGENTS.md binding → `tenant.md`, else
  ESCALATE — never guess); per-tenant tag namespacing `ZHC-<tenant_id>-…`; the operator-only/never-customer-invoked
  guard (a customer can never switch tenants — cross-tenant injection vector); and the PII-free F52 log.
- **Honest scope:** the isolation protocol + the scoping/namespacing scheme + the per-tenant config mechanism +
  the `hooks.mappings` `tenant_id` convention — an architecture/protocol feature, NOT a runtime DB migration.

### Added — QC gate + negative test, byte-identical across both repos
- `scripts/qc-multi-tenant.sh` — asserts the load-bearing F21 substance (protocol substance, AGENTS Step 0.8 block,
  MEMORY Rule 26, the PII-free `multi-tenant-events.jsonl` contract documented+seeded, the per-tenant root scaffold,
  the default-OFF toggle). Wired into `scripts/11-run-qc-checklist.sh` + `.github/workflows/qc-static.yml`.
- `scripts/qc-multi-tenant.test.sh` — negative self-test: proves the gate PASSES intact and FAILS when each of
  three invariants is broken (the `hooks.mappings` `tenant_id` convention, the operator-only guard, the
  `multi-tenant-events.jsonl` seeding).

### Changed — wiring (canonical additions byte-identical; host-script scaffolding repo-local)
- `scripts/05-update-agents-md.sh` — new marker block `STEP_0_8_MULTI_TENANT_ISOLATION` (AGENTS.md Step 0.8,
  early context-setup region: resolve the active tenant FIRST so the rest of the turn loads only that tenant's
  scope). Idempotent BEGIN/END marker.
- `scripts/06-append-memory-rules.sh` — appends MEMORY Rule 26 (Multi-Tenant Isolation Rule) in a new
  Round-2 marker block (does NOT renumber rules 6-25), marker-guarded + backup-before-write.
- `scripts/25-seed-round3-feature-files.sh` — seeds the empty `multi-tenant-events.jsonl` sink + scaffolds the
  per-tenant root `tenants/<TENANT_ID>/` (a `tenant.md` directive + the four scoped surfaces + a tenants README),
  existence-guarded (never overwrites operator files).
- `INSTRUCTIONS.md` — new Step 9.44 row + the Phase-5 F52 data-contract row for `multi-tenant-events.jsonl`
  (`event_type` `tenant_routing`, PII-free).

### openclaw.json toggle (documentation-only default — no destructive write)
- `skill38.multi_tenant.enabled` default **false** (OFF); `skill38.multi_tenant.tenants{}` optional per-tenant map.

## [1.5.6] - 2026-05-30 - ZHC Tag-Prefix Rule substance QC fix (byte-identical across both onboarding repos)

### Why
A QC re-score of the "ZHC Tag-Prefix Convention" system rule found four real substance gaps and a
doc-parity gap. This release closes all of them so the rule is self-consistent end-to-end and the gate
genuinely catches a regression. The shared docs/scripts are made **byte-identical** across
`openclaw-onboarding` (Mac) and `openclaw-onboarding-vps`. UNIVERSAL — zero personal/client data.

### Changed — `protocols/intelligent-followup-protocol.md` (F29), byte-identical across both repos
- The three agent-created follow-up tags are now `ZHC-` prefixed (per the rule's single test "did the AGENT
  create this tag?"): `cold-lead-released` → `ZHC-cold-lead-released`, `followup-opted-out` →
  `ZHC-followup-opted-out`, `stalled-sales` → `ZHC-stalled-sales`.
- Wired the 10-touchpoint sequence so each touch applies `ZHC-followup-cadence-1` … `ZHC-followup-cadence-10`
  (added to each T1…T10 heading + the cron pseudocode), so the operator can see exactly how far a contact got.
- Added a "Tags this protocol creates" table at the top documenting the full ZHC- tag set + CREATE-TAG-FIRST.

### Changed — `protocols/sales-best-practices-protocol.md`, byte-identical across both repos
- The same agent-created `stalled-sales` tag is now `ZHC-stalled-sales` (the F29 entry signal also surfaces here).

### Added — `references/tag-migration-notes.md` (the spec-required deliverable), byte-identical across both repos
- New optional, operator-driven migration reference: explains the not-retroactive posture and gives a
  legacy-bare-tag → `ZHC-` mapping table. Cross-linked from `zhc-tag-prefix-protocol.md`. Seeded idempotently
  into the operator's master-files dir (`KnowledgeBases/business/tag-migration-notes.md`) by
  `scripts/25-seed-round3-feature-files.sh` (existence-guarded, never overwrites).

### Changed — `scripts/qc-zhc-tag-prefix.sh` (close the enforcement hole), both repos
- Added `intelligent-followup-protocol.md` to the SCAN_FILES list.
- Added the F29 tags (`ZHC-stalled-sales`, `ZHC-followup-cadence-1`/`-10`, `ZHC-cold-lead-released`,
  `ZHC-followup-opted-out`) to the expected-tags list.
- Added a dedicated check (4b) that fails on a BARE prose-applied follow-up tag in that file (the prose
  "tag contact as `x`" form the create_tag literal parser cannot see). Proven with a negative test.
- CI (`.github/workflows/qc-static.yml`) now plants a bare F29 follow-up tag and asserts the gate fails closed
  (in addition to the existing bare-create_tag negative test).

### Changed — Skill 39 real-estate carve-out contradiction (Mac repo) + journey template (both repos)
- `39-real-estate-playbook/references/real-estate-tags.md` (Mac): the "Supporting (non-ZHC) status tags"
  carve-out is removed; those agent-created lifecycle tags are now `ZHC-` prefixed
  (`ZHC-listing-alert-engaged`, `ZHC-showing-confirmed`, `ZHC-offer-active`, `ZHC-under-contract`,
  `ZHC-closed`, `ZHC-post-close-nurture`, `ZHC-sphere-reactivation`) — no undocumented contradiction left.
  (VPS Skill 39 already used a ZHC-only 4-tag vocabulary, so it had no carve-out to fix.)
- `38-conversational-ai-system/templates/journey-templates/real-estate/journey.md` (both repos): the lifecycle
  tags it applies are `ZHC-` prefixed to match (incl. `ZHC-buyer-lead`/`ZHC-seller-lead`).

### Changed — `protocols/zhc-tag-prefix-protocol.md` doc parity + self-consistency, byte-identical across both repos
- VPS now carries the "NOT retroactive — bot-detection continuity" section so both protocols match (gap 5).
- Added a canonical-name note: the rule's canonical name is the "ZHC Tag-Prefix Rule" (shipped as Rule 20;
  number may vary per client MEMORY.md) — refer to it by name, not number (gap 6; no renumber).
- Documented the F29 tags + the new migration-notes reference in Naming-form examples + Cross-references.

## [1.5.5] - 2026-05-30 - F46 (Conversational CRM Field Write + Create-If-Missing) QC deep-fix + Mac↔VPS reconciliation

### Why
F46 shipped at v1.5.0 but a QC re-score surfaced four gaps, all on or around the F46 logging contract:
a **PII leak** on the VPS side (the canonical JSONL example logged `value_written` — raw customer PII —
directly contradicting the same doc's PII note), a **cross-repo schema divergence** (VPS carried TWO
competing JSONL schemas — a per-event `field_key/field_type/value_written/workflow_id` form AND a combined
`crm_field_write` summary — while Mac shipped ONE clean PII-free schema), the **F35 weekly tune-up not
actually wired** (F46 + AGENTS Step 2.5 + MEMORY Rule 24 all claimed the tune-up reviews auto-created-field
usage, but `weekly-tune-up-protocol.md` had no such review item), and an **inaccurate cross-reference**
(F46 pointed at `references/ghl-api-quick-reference.md` for the discover/write shapes, but that file never
documented the `customFields` endpoints). The Mac `crm-field-write-protocol.md` was the correct, PII-safe
reference; this VPS doc was reconciled toward it. UNIVERSAL — zero personal/client data; `qc-no-personal-data.sh`
passes both repos.

### Fixed — PII leak + single JSONL schema (`protocols/crm-field-write-protocol.md`, reconciled to Mac)
- **Removed the `value_written` raw-customer-value key** from the canonical JSONL example AND deleted the
  competing `crm_field_write` summary schema + its `field_key/field_type/workflow_id` per-event form. The
  protocol now ships Mac's ONE PII-free contract: `event_type` `field_write` / `field_created` /
  `field_write_skipped` with keys `contact_id`, `workflow`, `field_name`, `field_id`, `data_type`,
  `created_now`, `validated`, `reason` (skip), `operator_notified` — collectively the `crm_field_write`
  event family, NEVER the raw value (PII stays in GHL + the conversation log).
- INSTRUCTIONS.md F46 data-contract row + the strategic-roadmap F46 entry updated to the same event family +
  key fields (dropped the "summary form" reference); the F46 event-type values + key data fields are now
  identical across both repos.

### Added — F46↔F35 wiring made bidirectional (`protocols/weekly-tune-up-protocol.md`, identical both repos)
- New "What it analyzes" item **5. CRM auto-created field usage (F46)**: reads `crm-field-mappings.md` +
  `crm-field-writes-log.jsonl` (field NAME/ID + metadata only, never the raw value) and reports, per
  `ZHC_`-prefixed auto-created field, written-vs-ignored counts (flag unused fields for operator review),
  operator-field collisions (consolidate candidates), and repeated `field_write_skipped` patterns (wrong
  dataType). Closes the loop the F46 protocol + AGENTS Step 2.5 + MEMORY Rule 24 already claimed.

### Added — accurate cross-reference (`references/ghl-api-quick-reference.md`, both repos)
- New **CUSTOM FIELDS (F46)** section documenting the real shapes: `GET /locations/<LOCATION_ID>/customFields`
  (returns `id`/`name`/`fieldKey`/`dataType`) and `POST /locations/<LOCATION_ID>/customFields` (create with
  `name`/`dataType`, `ZHC_` prefix, operator-approved never customer-invoked), Version `2021-07-28`. The F46
  protocol's pointer to this file is now accurate.

### Changed — QC gate tightened (`scripts/qc-feature-logs.sh`, identical both repos)
- Added a **PII guard**: any Round-3 protocol's JSONL example line carrying a raw-value key
  (`value_written` / `"value"` / `field_value` / `raw_value`) is now a hard FAIL. Negative-tested — it
  catches the exact `value_written` leak this release removed.
- `scripts/qc-tools-md-ghl-ref.sh` size budget bumped for the legitimate new CUSTOM FIELDS section (VPS
  MAX_LINES 185→195; Mac CHAR_BUDGET 6500→7000), documented as a deliberate bump (same rationale as prior
  bumps; the line guard remains the real anti-bloat gate).

### Verification
- `bash -n` clean on all changed scripts. `scripts/qc-feature-logs.sh` PASS both repos (incl. new PII guard).
  `scripts/qc-tools-md-ghl-ref.sh` + `qc-no-personal-data.sh` PASS both repos. Full `11-run-qc-checklist.sh`
  introduces ZERO new failures vs clean main (remaining FAILs are environmental — live-install paths absent
  in a bare clone). VPS↔Mac version sequences kept independent (not converged).

## [1.5.4] - 2026-05-30 - F47 (Smart FAQ) + F45 (Geo-Qualification) substance deep-fix (byte-identical across both onboarding repos)

### Why
F47 and F45 shipped at v1.5.0 and were reconciled to a canonical superset at v1.5.3, but several roadmap
(`references/conversational-ai-strategic-roadmap.md`, Features 45 + 47) SUBSTANCE points were thin or
missing in the protocol bodies — and the two protocol files had drifted apart between the Mac and VPS repos.
This release deep-fills every spec gap and makes the two protocol files (and the new QC gate) **byte-identical**
across `openclaw-onboarding` (Mac) and `openclaw-onboarding-vps`. UNIVERSAL — zero personal/client data;
`qc-no-personal-data.sh` passes.

### Changed — `protocols/smart-faq-tool-protocol.md` (F47), made byte-identical across both repos
- Crisp one-line **sentence-vs-sub-flow rule** at the top (one sentence + nothing changes → F47; needs a
  follow-up/calc/quote/mini-flow → F44 `ZHC-faq-detoured`).
- The parallel FAQ-match layer is stated to run **alongside the active workflow AND the F44 always-listening
  layer** (Step 1.42), as the two halves of one layer.
- Restored the explicit **"bigger than one sentence → hand to F44"** section with the `ZHC-faq-detoured` tag
  (this is F44's tag, distinct from F47's `ZHC-faq-answered`).
- `faq-scope.md` reframed as the task's **sales-relevant vs ops-relevant** split, with worked guidance.
- Expanded the **F44(sub-flow) vs F47(sentence)** table (added trigger + reply-shape rows) and the bidirectional
  hand-off (F44 hands simple questions DOWN to F47; F47 hands bigger ones UP to F44).
- Keeps: `KnowledgeBases/business/faqs.md` match, the "By the way, [answer]. Coming back to [topic]…" handoff,
  `ZHC-faq-answered`, `faq-detour-log.jsonl` schema.

### Changed — `protocols/geo-qualification-protocol.md` (F45), made byte-identical across both repos
- Added the **per-product toggle** `skill38.geo_qualification.per_product` (in ADDITION to the global default-OFF
  `enabled`), with the explicit resolution order (global OFF wins → per-product override → fall back to
  `service-areas.md` presence) and a mixed-catalog example (gate an in-person consult, never gate a digital course).
- Added the **exact confirmation question** ("…what ZIP code would the service be at? I don't want to turn you
  away if we actually can help.") and a complete **all-response-branches** table — **here** (in-area, qualify),
  **elsewhere** (confirmed out-of-area, apply mode), **vacation** (do-not-disqualify), **moving** (clarify
  timing, do-not-disqualify if pending/unclear), **no clear engagement** (do-NOT-disqualify; a non-answer is not
  a confirmed out-of-area location).
- The 4 out-of-area modes now name their tags (`decline_plus_referral`/`waitlist`/`full_decline` →
  `ZHC-out-of-service-area`; `limited_remote` → `ZHC-service-area-flexible`).
- Strengthened the JSONL invariant note: the vacation/moving/no-engagement branches never produce an
  `in_area:false` + `ZHC-out-of-service-area` line.
- Keeps: HINTS-only priority (pixel/IP → area code → form address → explicit ask), `service-areas.md`
  (ZIP/county/state/radius per product), the 3 ZHC tags, `geo-qualification-log.jsonl` schema.

### Changed — supporting touchpoints (so the new substance reaches the running agent), applied identically to both repos
- **`scripts/05-update-agents-md.sh`** (`STEP_2_0_GEO_QUALIFICATION` block) — added the per-product toggle,
  the exact confirmation question, and the here/elsewhere/vacation/moving/no-engagement branch summary.
- **`scripts/06-append-memory-rules.sh`** (Rule 23) — added the per-product opt-in and the
  do-not-disqualify-on-vacation/moving/no-answer rule.
- **`scripts/25-seed-round3-feature-files.sh`** (`service-areas.md` seed) — documents the per-product toggle
  and the do-not-disqualify branches.

### Added — QC gate (the "update QC gates to verify these" requirement)
- **`scripts/qc-f45-f47-substance.sh`** (NEW, byte-identical across both repos) — machine-verifies all 41
  F45/F47 substance points listed above from the protocol files alone; fails closed on a stripped point.
  Wired into `scripts/11-run-qc-checklist.sh` AND `.github/workflows/qc-static.yml` (with a per-product-toggle
  negative self-test). `SKILL.md` self-counts bumped (scripts 54→55; QC linters eighteen→nineteen).

---

## [1.5.3] - 2026-05-30 - Round-3 canonical reconciliation (match the sibling onboarding repo EXACTLY)

### Why
The two onboarding repos (`openclaw-onboarding` Mac + `openclaw-onboarding-vps`) had drifted on the Round-3
Queue-A artifacts: divergent AGENTS.md marker names + step numbers, a different MEMORY.md rule split, a thinner
`qc-zhc-tag-prefix.sh`, a `qc-no-personal-data.sh` without `--no-gen`, `-test.sh` (vs `.test.sh`) test naming,
a missing standalone `qc-self-test.sh`, and a roadmap that indexed ZERO Round-3 features. This release applies
the CANONICAL reconciliation plan so this repo matches the sibling EXACTLY for every Round-3 artifact (only the
intentional Mac-vs-VPS platform-plumbing differences remain). UNIVERSAL — zero personal/client data;
`qc-no-personal-data.sh` passes.

### Changed — AGENTS.md marker scheme + step numbers (canonical = one dedicated block per feature)
- **`scripts/05-update-agents-md.sh`** — renamed/split the Round-3 marker blocks to the canonical scheme:
  `STEP_1_35_AGGRESSION` → `STEP_1_35_AGGRESSION_PRE_ROUTING` (Step 1.35); `STEP_2_0_INTERRUPTS` →
  `STEP_1_42_INTERRUPTS_AND_FAQ` (Step 2.0 → **1.42**); `STEP_2_5_GEO` → `STEP_2_0_GEO_QUALIFICATION`
  (Step 2.5 → **2.0**); and the merged `STEP_TAG_PREFIX` block SPLIT into two dedicated blocks —
  `SKILL38_ZHC_TAG_PREFIX` (tag-prefix note) + `STEP_2_5_CRM_FIELD_WRITE` (F46 CRM-field note at Step 2.5).
  The Pixel block (`STEP_1_45_PIXEL_CONCIERGE`) was already canonical. Toggles shown nested under `skill38.`.

### Changed — MEMORY.md rule numbering (canonical = 6 rules, one feature per rule)
- **`scripts/06-append-memory-rules.sh`** — the v1.5.0 block now emits **rules 20-25** (was 20-24): un-merged
  VPS's Rule 23 → canonical **23 (geo, F45)** + **24 (CRM, F46)**, and un-merged Rule 24 → canonical
  **25 (smart-FAQ, F47)**; the F52 logging sentence moves to the centralized INSTRUCTIONS.md data-contract table
  (NOT its own rule). 20 = ZHC tag-prefix, 21 = F50, 22 = F44. Marker comment + trailer echo updated to "20-25".

### Changed — protocol bodies (merged to the canonical superset; every cross-ref points at the canonical marker/step/rule)
- **`zhc-tag-prefix-protocol.md`** — H1 retitled `— Step 9.42`; cross-ref marker `STEP_TAG_PREFIX` →
  `SKILL38_ZHC_TAG_PREFIX`.
- **`aggression-detection-protocol.md`** — H1 `(F50) — Step 9.37`; marker (×2) →
  `STEP_1_35_AGGRESSION_PRE_ROUTING`; added the "Severity is per-message, but tension can accumulate" section
  and the dedicated **MEMORY.md (Rule 21)** section.
- **`smart-playbook-switching-protocol.md`** — H1 `(F44) — Step 9.38`; added the operator-config
  `interrupt-triggers.md` reference, the `skill38.smart_playbook_switching.{enabled, max_interrupt_depth}`
  toggle block, and the **MEMORY.md (Rule 22)** section; cross-ref → Step 1.42 / `STEP_1_42_INTERRUPTS_AND_FAQ`.
- **`geo-qualification-protocol.md`** — H1 `(F45) — Step 9.39`; nested the toggle under
  `skill38.geo_qualification.enabled`; added the "PRE-FILL the confirmation question" guidance and the
  **MEMORY.md (Rule 23)** section; cross-ref → Step 2.0 / `STEP_2_0_GEO_QUALIFICATION`.
- **`crm-field-write-protocol.md`** — H1 `(F46) — Step 9.40`; added the THREE distinct JSONL event types
  (`field_write` / `field_created` / `field_write_skipped`) alongside a back-compat `crm_field_write` summary
  line, the `skill38.crm_field_write.{enabled, create_if_missing, created_field_prefix}` toggle block, and the
  **MEMORY.md (Rule 24)** section; cross-ref → Step 2.5 / `STEP_2_5_CRM_FIELD_WRITE`.
- **`smart-faq-tool-protocol.md`** — H1 `(F47) — Step 9.41`; added the `skill38.smart_faq.enabled` toggle block
  and the **MEMORY.md (Rule 25)** section; cross-ref → Step 1.42 / `STEP_1_42_INTERRUPTS_AND_FAQ`.
- **`conversational-safeguards.md`** — Safeguard 4 now carries the inline two-tier bullet detail (Tier 1 / Tier 2
  / ALL-CAPS-alone) with the nested `skill38.aggression_detection` toggle path, so the safeguards file is
  self-contained.
- **`conversation-workflows-protocol.md`** (§D.1) + **`references/workflow-ai-instructions-standard.md`** (§6) —
  the agent-created example tags updated to the `ZHC-` form (`ZHC-pricing-interest` / `ZHC-discovery-scheduled` /
  `ZHC-quoted`) with the ZHC tag-prefix note, so no bare agent-created example tag is left behind.

### Changed / Added — QC gates (canonical = the SUPERSET of both repos' checks)
- **`scripts/qc-zhc-tag-prefix.sh`** — now the UNION: ONB's checks (MEMORY Rule 20 appended,
  `SKILL38_ZHC_TAG_PREFIX` marker present, the D.1 + Section-6 example tags are ZHC-) PLUS the load-bearing
  bare-create-tag literal parser (a `create_tag(... name="…")` / `POST .../tags` literal must be `ZHC-` or a
  placeholder; `add_tag`/apply lines are NOT flagged). Negative-tested.
- **`scripts/qc-no-personal-data.sh`** — adopted the `--no-gen`-aware version; the banned-identifier list keeps
  every VPS-specific token from the prior version (the extra fleet client names + the operator brand domain) so
  no coverage is lost in the swap.
- **`scripts/qc-self-test.sh` (NEW).** Static gate that asserts the backend self-test standard against
  `24-self-test-hook.sh` (exists/parses, POSTs the synthetic flat-23-key inbound with the real Bearer, verifies
  hook 200/{ok:true} + no 401/429 + conversation-log read + GHL send + temp-contact cleanup, documents PASS/FAIL,
  and is wired as a blocking readiness gate + documented). Wired into `11-run-qc-checklist.sh` + CI.
- **Test-helper naming** — renamed `qc-playbook-doc-test.sh` → `qc-playbook-doc.test.sh`,
  `qc-trinity-registry-test.sh` → `qc-trinity-registry.test.sh`, `qc-zhc-pixel-test.sh` → `qc-zhc-pixel.test.sh`
  (the canonical `.test.sh` form); CI references updated.
- **`scripts/11-run-qc-checklist.sh`** — the AGENTS.md marker grep list updated to the canonical markers
  (`SKILL38_ZHC_TAG_PREFIX`, `STEP_1_35_AGGRESSION_PRE_ROUTING`, `STEP_1_42_INTERRUPTS_AND_FAQ`,
  `STEP_2_0_GEO_QUALIFICATION`, `STEP_2_5_CRM_FIELD_WRITE`); added the `qc-self-test.sh` section.

### Changed — INSTRUCTIONS.md
- The Phase-5 Round-3 table + intro now reference the canonical marker names, step numbers, and nested
  `skill38.*` toggle namespaces. The F52 JSONL data-contract documentation is unchanged (still enforced by
  `qc-feature-logs.sh`).

### Changed — roadmap (CAT1 traceability)
- **`references/conversational-ai-strategic-roadmap.md`** — added a "Round 3 — Conversational Depth + Verticals"
  section indexing EVERY Round-3 artifact (the ZHC- tag-prefix system rule + F44 + F45 + F46 + F47 + F49 + F50 +
  F52 + Skill 39 + Skill 40) with each entry expanded from the matching in-repo protocol/skill file (no edge
  cases stripped), plus a "Round-3 QC-enforced standards" subsection (the 3 standards + their gates). Footer
  corrected to **39 protocol files** (was a stale 32); "Last updated" → May 30, 2026.

### Notes
- Skills 39 (real estate) + 40 (public-records scraper) are intentionally NOT modified here — they are divergent
  independent builds between the two repos and require a build-level canonical decision (per the plan's Section 4)
  before either repo's apply-agent touches them; auto-merging would risk diverging the two trees.
- This is a Skill-38-only release (skill-version 1.5.2 → 1.5.3). The repo-wide OpenClaw version bump is handled
  separately by the Cap phase.

## [1.5.2] - 2026-05-30 - Feature 49 (ZHC Pixel): per-client visitor-signal pixel + Pixel Concierge

### Why
The VPS Skill 38 was the only place F49 (ZHC Pixel) was still missing — it had already shipped in the sibling
`openclaw-onboarding` repo (PR #58, Skill 38 1.5.2). This release ports that implementation 1:1 so both repos
match. Every client gets THEIR OWN private visitor-signal pixel that POSTs anonymous-but-persistent behavior
batches to THEIR OpenClaw over THEIR existing Cloudflare tunnel (`pixel.<CLIENT_DOMAIN>` → tunnel → hook
`pixel-visitor-signal` → a scoped **Pixel Concierge** agent), NOT a shared analytics service. UNIVERSAL —
zero personal/client data; ZHC- tags + ZHC_ fields throughout.

### Added
- **`protocols/zhc-pixel-protocol.md` (NEW PROTOCOL, INSTRUCTIONS Step 9.43).** The full F49 spec: the pixel
  architecture, legally-compliant identification (first-party form linkage only — NEVER fabricate identity),
  the `pixel-visitor-signal` hook, the behavioral trigger rules, the Pixel Concierge agent, the scope-gated
  Cloudflare deploy, the JSONL data contract (§7), the GDPR/CCPA/DNT/deletion privacy controls (§8), and an
  honest "MVP vs production follow-ups" status.
- **`templates/zhc-pixel/zhc-pixel.template.js` (NEW TEMPLATE, ~250 LoC).** Anonymous first-party cookie +
  persistent `visitor_id`, a privacy-bounded soft fingerprint, a Do-Not-Track hard-stop at boot, scroll/click/
  pageview/visibility watchers, a batched `sendBeacon`/`fetch` POST, the `window.ZHCPixel` API
  (`grantConsent`/`denyConsent`/`optOut`/`flush`), and the three per-client placeholders `__ZHC_PIXEL_ENDPOINT__`
  / `__ZHC_PIXEL_SITE_ID__` / `__ZHC_PIXEL_AGENT_ID__`. The hooks bearer token is NEVER baked into the bundle.
- **`scripts/26-verify-pixel-prerequisites.sh` (NEW).** CF scope precheck — Pages:Edit + Workers Scripts:Edit +
  Workers Routes:Edit — that HALTS and points at the token-instructions Google Doc when a scope is missing, and
  records `ZHC_PIXEL_SCOPES_OK` so the deploy can gate on it. Never echoes the CF token.
- **`scripts/27-render-pixel-js.sh` (NEW).** Renders the per-client pixel JS by substituting the three
  placeholders; guards against any unresolved placeholder leaking into output; persists the site id / hostname /
  agent to the run-state; prints the `<script>` paste snippet.
- **`scripts/28-configure-pixel-hook.sh` (NEW).** Registers the `pixel-visitor-signal` `hooks.mappings` entry
  (`deliver:false`, the bot-gate-first `messageTemplate` with the F52 JSONL append + the no-fabrication +
  least-intrusive directives — fail-closed guarded), a SEPARATE scoped **Pixel Concierge** agent in
  `agents.list`, and the `hook:pixel:` `allowedSessionKeyPrefixes` + `allowedAgentIds` allow-list; ensures the
  F52 `pixel-events/` dir; reuses HOOKS_TOKEN (never the gateway token); runs `openclaw config validate`.
  jq-1.7-safe, same merge discipline as `15-configure-hooks-mappings.sh`.
- **`scripts/29-deploy-pixel-cloudflare.sh` (NEW).** Scope-GATED Cloudflare deploy: adds
  `pixel.<CLIENT_DOMAIN>` to the client's EXISTING tunnel + a proxied CNAME, creates/reuses a CF Pages project
  hosting the JS, deploys it via the API, and (optionally) deploys an edge Worker + binds a Workers Route. No
  silent failure — exits non-zero with the Google-Doc pointer when scopes are missing.
- **`scripts/qc-zhc-pixel.sh` + `scripts/qc-zhc-pixel-test.sh` (NEW QC GATE + NEGATIVE TEST).** Machine-enforces
  every F49 invariant (template + 3 placeholders + generator substitution-guard; the hook registration with
  deliver:false + bot-gate-first + `hook:pixel:` allow-list + the `pixel-events` dir; the
  `STEP_1_45_PIXEL_CONCIERGE` AGENTS block + protocol doc; the ZHC- tag + ZHC_ field set; the GDPR/CCPA/DNT/
  deletion controls in BOTH the protocol and the template; the scope precheck naming all three scopes + the
  token Doc + the `ZHC_PIXEL_SCOPES_OK` gate flag; the gated deploy) and DELEGATES the no-personal-data scan to
  `qc-no-personal-data.sh`. The negative test proves the gate fails closed on three broken invariants. Wired
  into `scripts/11-run-qc-checklist.sh` + `.github/workflows/qc-static.yml`.
- **AGENTS.md `STEP_1_45_PIXEL_CONCIERGE` block** (via `scripts/05-update-agents-md.sh`, free slot 1.45 — a
  concise pointer to `protocols/zhc-pixel-protocol.md`, never inlining the full ruleset).
- **GHL ZHC_ fields** (`ZHC_first_visit_date` / `ZHC_total_visits` / `ZHC_pages_viewed` /
  `ZHC_high_intent_signal`, F46 create-if-missing) + **tags** (`ZHC-pixel-visitor` /
  `ZHC-pixel-returning-visitor` / `ZHC-pixel-high-intent` / `ZHC-pixel-bot-suspected`).
- **F52 JSONL emitter** to `<MASTER_FILES_DIR>/pixel-events/YYYY-MM-DD.jsonl` (timestamp + event_type + data);
  schema documented in `protocols/zhc-pixel-protocol.md` §7 and the INSTRUCTIONS.md data-contract index.

### Notes
- VPS-vs-onboarding path adaptations (behavior identical): the install scripts are numbered `26`–`29` (the
  onboarding `25`–`28`, because VPS already ships `25-seed-round3-feature-files.sh`); the negative test follows
  the VPS `-test.sh` naming (`qc-zhc-pixel-test.sh`, vs the onboarding `.test.sh`); and the delegated
  no-personal-data call drops the onboarding-only `--no-gen` flag the VPS `qc-no-personal-data.sh` does not
  accept. All cross-references (between the four scripts, the gate, the protocol, INSTRUCTIONS, and the AGENTS
  block) were renumbered to match.
- **The live per-client Cloudflare deploy is GATED, not auto-run** — it requires the operator's CF token to
  carry Pages/Workers scopes; the precheck HALTS otherwise (owner directive). The deploy code ships.

## [1.5.1] - 2026-05-30 - THREE QC-enforced standards: Communications Playbook (elevated), GHL Raw Body JSON (new), Notion Client-Doc (new)

### Why
Skill 38 already shipped one formal, machine-enforced standard — `references/workflow-ai-instructions-standard.md`
(OPERATOR HEADER → a hard "EVERY … MUST INCLUDE ALL OF THE FOLLOWING" §0 checklist → field-by-field detail,
gated in CI). The communications playbook, the GHL Custom Webhook RAW BODY, and the client Notion setup doc
each had their rules scattered across protocols, the source playbook, and inline prose, enforced (where at
all) only obliquely. This release brings all three to the SAME rigor as the workflow-AI standard: a hard
mandatory-checklist headline, codified field-by-field detail, and a dedicated machine-enforced QC gate that
FAILS the build (and is negative-tested) if the standard is violated. Standards are still POINTERS from
SKILL.md / INSTRUCTIONS.md — the bodies are never inlined into AGENTS.md/SKILL.md. (Lands on top of the
[1.5.0] Round-3 feature wave; the ZHC- tag-prefix inclusion in the Communications Playbook Standard aligns
with [1.5.0]'s `zhc-tag-prefix-protocol.md`.)

### Added
- **`references/ghl-raw-body-json-standard.md` (NEW STANDARD).** The single human-readable standard for the
  GHL Custom Webhook RAW BODY (object A): the BINDING §0 "EVERY GHL RAW BODY MUST BE THE FULL 23-KEY FLAT
  JSON" rule (23 = minimum AND standard, never fewer, never nested), the FLAT rule, the placeholder-free
  `messageTemplate` stub rule, `deliver:false`, the per-channel-variant rule (only `channel` + `session_key`
  prefix change), the EXACT 23 keys with a one-line purpose each, and the canonical body shown once.
  Codifies `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14 (the source of truth) and points at
  `scripts/qc-23-key-bodies.sh` as the body linter.
- **`references/notion-client-doc-standard.md` (NEW STANDARD).** The single standard for the client
  Quick-Start Notion setup doc: the BINDING §0 "EVERY CLIENT NOTION SETUP DOC MUST INCLUDE ALL OF THE
  FOLLOWING, IN THIS ORDER" 12-item list — Quick-Start first; Webhook URL (own block); Authorization as TWO
  blocks (block1 `Authorization` / block2 `Bearer <token>` value-only, NEVER combined); Content-Type as two
  blocks; the FLAT 23-key Raw Body; tags-first + field-by-field manual fill + "Build-with-AI builds the
  SHAPE only" warning + post-build VERIFY; the Communication Playbooks section (CTA + trigger-word +
  I-Do/You-Do + brainstorm); VPS-vs-Mac; how-it-works LAST; every copyable value in its own code block;
  Telegram delivery; universal/no-personal-data.
- **`scripts/qc-communications-playbook-standard.sh` (NEW QC GATE).** Asserts the Communications Playbook
  Standard still carries its §0 mandatory checklist + every required item. Negative-tested (dropping the
  ZHC- tag prefix FAILS). Pure bash.
- **`scripts/qc-ghl-raw-body-standard.sh` (NEW QC GATE).** Asserts the GHL Raw Body JSON Standard documents
  the §0 FLAT-23-key rule + the exact 23 keys, and COMPOSES with `scripts/qc-23-key-bodies.sh` so every real
  object-A body obeys it. Negative-tested (dropping a key FAILS). Pure bash.
- **`scripts/qc-notion-doc-standard.sh` (NEW QC GATE).** Asserts the Notion Client-Doc Standard documents
  the §0 ordered mandatory list, and COMPOSES with `scripts/qc-reference-sheet.sh` so the actually-generated
  doc conforms. Negative-tested (dropping "Quick Start FIRST" FAILS). Pure bash.

### Changed (ELEVATED, not duplicated)
- **`references/communications-playbook-standard.md` — ELEVATED** to the same mandatory-checklist + QC rigor
  as the workflow-AI standard. Added a hard, leading **§0 "EVERY COMMUNICATION PLAYBOOK MUST INCLUDE ALL OF
  THE FOLLOWING"** binding checklist (9 inclusions: channel+persona/voice identity, opening behavior/greeting,
  goal/desired outcome, the MANDATORY SEND rule, the conversation-memory read-before/append-after protocol,
  escalation/handoff + honesty floor, quiet-hours + compliance-keyword respect, the **ZHC-** tag prefix for
  programmatic tags, per-channel formatting), scoped to the 8 channels (SMS, Email, FB Messenger, FB
  comments, IG DM, LinkedIn, Live Chat, All-in-One/Chat Widget). Enriched the §1 tick-list and the §2
  canonical skeleton to match (added Persona/voice, Opening/greeting, Quiet-hours & compliance, Per-channel
  formatting, ZHC- prefix on tagging). The pre-existing file was elevated in place — NOT duplicated.
- **`scripts/11-run-qc-checklist.sh`** — wired in the three new gates (sections before the final summary).
- **`.github/workflows/qc-static.yml`** — wired in three new CI steps, each running the gate (positive) AND
  a negative test that proves the gate fails closed when a mandatory item is removed.
- **`SKILL.md` / `INSTRUCTIONS.md`** — added one-line POINTERS to each new/elevated standard (bodies not
  inlined). Self-counts updated for the three new references + three new scripts.

### QC
- All Skill 38 gates pass (incl. `qc-no-personal-data.sh` — UNIVERSAL, zero personal/client data in the new
  docs + the generated output). The three new gates pass positive and FAIL on a removed mandatory item
  (negative-tested locally + in CI).

## [1.5.0] - 2026-05-30 - Round-3 Queue-A feature wave: ZHC tag-prefix, F50 aggression (two-tier), F44 detour-and-return, F45 geo-qualification, F46 CRM field write, F47 inline FAQ — one coherent minor bump

### Why
Round-3 Queue-A bundles six CORE conversational behaviors into one coherent minor bump. Each is UNIVERSAL (no personal/client data — `qc-no-personal-data.sh` passes), each ships as a `protocols/<name>-protocol.md` + a new INSTRUCTIONS Step 9.37–9.41, each new AGENTS.md step lands ONLY via `scripts/05-update-agents-md.sh` marker blocks, and each behavioral feature emits a JSONL log under the F52 data contract. Two new machine-enforced QC gates (ZHC- tag-prefix + F52 data contract) are wired into `scripts/11-run-qc-checklist.sh` and CI.

### Added — protocols (6)
- **`protocols/zhc-tag-prefix-protocol.md`** — every tag the agent CREATES programmatically (GHL skill `create_tag` / `POST /locations/{locationId}/tags`) MUST be prefixed `ZHC-`. NOT retroactive; never renames operator/human/3rd-party tags. CRM custom fields the agent creates use the parallel `ZHC_` (underscore) prefix. Reuses the EXISTING create-tag mechanism (conversation-workflows-protocol.md §D.1 + workflow-ai-instructions-standard.md §6) — only constrains the name. MEMORY.md Rule 20.
- **`protocols/aggression-detection-protocol.md` (F50)** — EXTENDS the Safeguard family in `conversational-safeguards.md` (Safeguard 4); does NOT rebuild bot detection (Safeguard 3 is unchanged; NEW bot firings tag `ZHC-bot-suspected`). Two-tier classifier at AGENTS.md **Step 1.35**, PRE-routing (before workflow match, before LLM spend). Tier 1 tension (multiple irritation words / sustained 3+ msgs / `!!!`/`???` → tag `ZHC-tension-detected`, heightened attention, no reroute); Tier 2 aggression (profanity-AT-agent / threats legal-physical-public / ALLCAPS+profanity+direct-address / 3+ signals → tag `ZHC-aggression-detected`, route to aggression-handler as an F44 detour, notify operator). **ALL CAPS ALONE does NOT fire.** openclaw.json `aggression_detection.{enabled (default true), sensitivity (lenient|standard|strict, default standard)}` with documented per-sensitivity thresholds. Logs to `aggression-detection-log.md` + `aggression-detection-log.jsonl`.
- **`protocols/smart-playbook-switching-protocol.md` (F44)** — NEW protocol, **DETOUR-AND-RETURN**, explicitly DISTINCT from F33 route-and-stay (`intelligent-routing-protocol.md`, Step 9.33). Always-listening layer parallel to the active workflow at AGENTS.md **Step 2.0**; on trigger (operator urgent keywords, FAQ types, compliance redirects, F50 aggression, F49 pixel-priority) SAVE workflow state (step + gathered data + context) → EXECUTE sub-flow → RETURN to the saved state with a soft transition ("Coming back to where we were…"). Max 2 levels deep then escalate; multiple triggers = highest priority first, queue the rest. Tags `ZHC-interrupt-handled` / `ZHC-faq-detoured` / `ZHC-aggression-handled-and-resumed`. Logs to `interrupt-log.jsonl`.
- **`protocols/geo-qualification-protocol.md` (F45)** — per-client toggle, openclaw.json `geo_qualification.enabled` default **OFF**. Location-detection priority pixel/IP (if F49) → phone area code → form address → explicit ask. CRITICAL: signals are HINTS; the agent **ALWAYS ASKS to confirm before any disqualification**. Operator-configured out-of-area handling (decline+referral / limited-remote / waitlist / full-decline). Per-product service areas in `KnowledgeBases/sales/service-areas.md` (ZIP/county/state/radius). Tags `ZHC-out-of-service-area` / `ZHC-service-area-confirmed` / `ZHC-service-area-flexible`. Logs to `geo-qualification-log.jsonl`. AGENTS.md **Step 2.5**.
- **`protocols/crm-field-write-protocol.md` (F46)** — agent writes ANY GHL contact custom field mid-conversation (type-aware: text/number/date/dropdown), discovering via `GET /locations/{locationId}/customFields` and validating before write. CREATE-IF-MISSING: create via `POST /locations/{locationId}/customFields` with `ZHC_` prefix (e.g. `ZHC_budget_range`), notify operator, record the per-workflow mapping in `crm-field-mappings.md`. F35 weekly tune-up reviews usage. Operator-approved allow-list action, NEVER customer-invoked. Logs to `crm-field-writes-log.jsonl`.
- **`protocols/smart-faq-tool-protocol.md` (F47)** — lightweight sibling of F44: a SENTENCE, not a sub-flow. Parallel FAQ-match layer against `KnowledgeBases/business/faqs.md`; brief inline answer then RETURN to the current step ("By the way, [answer]. Coming back to [topic]…"). Per-workflow scope in `conversation-workflows/<id>/faq-scope.md`. Tag `ZHC-faq-answered`. Logs to `faq-detour-log.jsonl`. AGENTS.md **Step 2.0** (same always-listening layer).

### Added — scripts (3)
- **`scripts/25-seed-round3-feature-files.sh`** — idempotently seeds `service-areas.md` (F45), `faqs.md` (F47), `crm-field-mappings.md` (F46), the five F52 JSONL sinks, and `aggression-detection-log.md`. Never overwrites operator content. Universal (placeholders only).
- **`scripts/qc-zhc-tag-prefix.sh`** — machine-enforces the ZHC- programmatic tag-prefix rule (rule documented + not-retroactive; canonical F44/F45/F47/F50 tag tokens are ZHC- forms; no bare create-tag example literal). Pure bash. Wired into Step 11 QC + CI (with a negative self-test).
- **`scripts/qc-feature-logs.sh`** — machine-enforces the F52 data contract (each of the five logs is JSONL with timestamp+event_type, documented in its protocol AND INSTRUCTIONS.md, and seeded by script 25). Pure bash. Wired into Step 11 QC + CI (with a negative self-test).

### Changed
- **`protocols/conversational-safeguards.md`** — EXTENDED with Safeguard 4 (aggression two-tier, pointing at the new protocol) and a `ZHC-bot-suspected` tag note; bot-detection logic itself untouched. Safeguard ordering gains the pre-routing aggression check (3.5).
- **`scripts/05-update-agents-md.sh`** — four new marker blocks: `STEP_1_35_AGGRESSION`, `STEP_2_0_INTERRUPTS`, `STEP_2_5_GEO`, `STEP_TAG_PREFIX` (the ZHC-/ZHC_ namespace note). AGENTS.md is mutated ONLY here.
- **`scripts/06-append-memory-rules.sh`** — new `v1.5.0` marker block appends rules 20-24 (does NOT renumber 6-18).
- **`scripts/11-run-qc-checklist.sh`** — runs the two new gates; the AGENTS.md marker check now includes the four new markers.
- **`INSTRUCTIONS.md`** — Steps 9.37–9.41 table + the centralized F52 JSONL data-contract index + three new Hard rules.
- **`SKILL.md`** — self-counts updated (protocols 32→38, scripts 41→44, eleven→thirteen QC linters); AGENTS/MEMORY summary lines updated.
- **`.github/workflows/qc-static.yml`** — two new CI steps (ZHC- tag-prefix + F52 data contract), each with a negative self-test.

### Notes
- F50 was **EXTENDED, not rebuilt** — bot detection already lived in Safeguard 3 and is untouched.
- F44 was **BUILT as detour-and-return** — it is distinct from F33 (route-and-stay); the earlier recon's conflation is corrected here.
- Skill 38 ONLY. UNIVERSAL (`qc-no-personal-data.sh` passes). Repo-wide version and repo-root CHANGELOG untouched.

## [1.4.21] - 2026-05-30 - Correct the reply mechanic: MIRROR the inbound channel + send BY contactId (conversationId is READ-only), QC-enforced

### Why
The send-directive and the GHL API quick-reference described the reply as a single hardcoded-SMS call and
implied `conversationId` could be a send field. Verified against the GoHighLevel official OpenAPI
**SendMessageBodyDto**, the correct mechanic is: ONE send endpoint (`POST /conversations/messages`), the
send `type` **MIRRORS the inbound channel** (SMS→SMS, Email→Email, Facebook→FB, Instagram→IG,
WhatsApp→WhatsApp, Live Chat→Live_Chat — never a hardcoded SMS), the reply is **threaded BY `contactId`**
(the send body is `{type, contactId, locationId, message}` — Email adds subject+html+emailFrom+emailTo),
and the body does **NOT** accept `conversationId`. GHL threads the reply into the contact's conversation
by `contactId` and returns `conversationId`+`messageId`. `conversationId` is the **READ key only** —
`GET /conversations/search?locationId=&contactId=` to find the thread, then
`GET /conversations/{conversationId}/messages` to read history. GMB is **inbound-only** (not a valid send
`type`); TikTok send `type` is `TIKTOK` (TikTok inbound is workflow-action-only); RCS/Custom are also valid
enum members.

### Changed
- **`scripts/15-configure-hooks-mappings.sh`** — the installer's canonical SERVER-mapping `messageTemplate`
  (object B, the only instruction that reaches the agent) rewritten to **channel-mirroring + contactId-
  threaded**: read the inbound `{{channel}}`, SEND via `POST /conversations/messages` with `type` = the
  MIRRORED channel value (do NOT hardcode SMS), body `{type, contactId, locationId, message}` (Email adds
  subject+html+emailFrom+emailTo), GHL threads by `contactId`. Added the READ path (`GET
  /conversations/search` → `GET /conversations/<conversationId>/messages`, `conversationId` = READ key
  only) and a GMB-inbound-only note. PRESERVED the READ-before / APPEND-after conversation-log memory steps
  and every element the QC gates require. The Step-4 E2E body messageTemplate aligned to the same mirroring
  directive.
- **`references/ghl-api-quick-reference.md`** (preloaded into the client `TOOLS.md`) — MESSAGING section
  corrected: send `type` enum is exactly **SMS / Email / FB / IG / WhatsApp / Live_Chat** (note RCS / Custom
  / TIKTOK also exist; **GMB = inbound-only, NOT a send type**; long-forms Instagram/Facebook/Webchat and
  Call are rejected). Send body shows **`{type, contactId, locationId, message}`** (NO `conversationId`).
  Added a **Read thread history** block: `GET /conversations/search?locationId=&contactId=` +
  `GET /conversations/<conversationId>/messages` (scope `conversations.readonly`, added to the scopes
  summary). Documented channel-mirroring and contactId-threading.
- **`references/workflow-ai-instructions-standard.md`** — added a concise **§3.6 "Critical Design Pattern"**
  (one endpoint, mirror the inbound channel, send by `contactId`, `conversationId` is read-only) and updated
  the §4 SEND-directive verification item to channel-mirroring + contactId.
- **`references/GHL-INBOUND-AND-PLAYBOOKS.md`** — §7 send-`type` enum reworded (GMB inbound-only; RCS/Custom/
  TIKTOK valid; mirror the inbound channel); §8 send body annotated `{type, contactId, locationId, message}`
  (no `conversationId`) + new **§8.1 read recipe** (search → messages); §14.1 23-key body gains a note that
  the thread is preserved BY `contact_id` on send and `conversationId` is looked up only to READ history
  (**the 23 keys are UNCHANGED**); §14.4 server-mapping directive + example rewritten to mirroring +
  contactId.
- **`references/v6.0-source-playbook.md`**, **`templates/sms-workflow-ai-prompt-template.md`**,
  **`templates/client-reference-sheet-template.md`**, **`scripts/21-generate-client-reference-sheet.sh`**,
  **`scripts/24-self-test-hook.sh`** — the body (object A) `messageTemplate` send directive updated to the
  channel-mirroring + contactId phrasing (kept **placeholder-free**, no `{{…}}`, per the 23-key rule).

### QC
- **`scripts/qc-tools-md-ghl-ref.sh`** — extended to assert the corrected shape (verified against the GHL
  SendMessageBodyDto): channel-mirroring is documented, the send body uses `contactId`, **`conversationId`
  is NEVER on a send-shape line** (it is the READ key only), the READ-thread-history path
  (`GET /conversations/search` + `conversationId` as the read key) is present, GMB is documented as
  inbound-only, and send `type`s use the short forms FB/IG/Live_Chat (no rejected long-forms). Added the
  `conversations.readonly` scope to the required-scopes set and raised the concise size budget 160→185 to
  fit the corrected MESSAGING section + the new read block (still the fast canonical subset, not the whole
  API). Negative-tested (the CI job's email-leak / oversize / dropped-op negatives still FAIL as expected).
- All Skill 38 gates pass: qc-23-key-bodies (23 keys UNCHANGED, placeholder-free), qc-send-directive,
  qc-conversation-memory, qc-tools-md-ghl-ref, qc-reference-sheet, qc-no-personal-data (UNIVERSAL — zero
  personal/client data; planted-leak negative still fails closed), qc-config-schema-safety,
  qc-trinity-registry-test, qc-playbook-doc-test, and the self-test wiring check.

### Notes
- **23-key GHL RAW BODY: UNCHANGED** — no key added/removed/renamed. The thread is preserved by `contact_id`
  on send; `conversationId` is looked up only to READ history.
- Universal skill — zero personal/client data.

## [1.4.20] - 2026-05-30 - Preload client TOOLS.md with the verified GHL API quick-reference (faster runtime, QC-enforced)

### Why
At runtime the conversational-AI agent had to dig through the dense per-module GHL references
(`references/GHL-INBOUND-AND-PLAYBOOKS.md` §7-§9, Skill 29 `references/{conversations,calendars,payments}.md`)
to recall the exact request shape for a send / book / reschedule / cancel / invoice call. That is
slow and error-prone mid-conversation. The fix: preload the **canonical request shapes** into the
CLIENT agent's **TOOLS.md** so they live in the agent's **core context** — exact method, full URL,
the 3 required headers, the JSON body shape (placeholders), and the required PIT scope per operation.
WHERE/WHY: shapes belong in **TOOLS.md** (WHERE-THINGS-LIVE), not AGENTS.md (WHAT-TO-DO). The block
is kept **concise** (canonical subset only, not the whole API) to avoid core-file bloat.

### Added
- **`references/ghl-api-quick-reference.md`** — the concise canonical block, grouped MESSAGING /
  CALENDARS / APPOINTMENTS / INVOICES, with a "Required PIT scopes" summary at top. Verified against
  the in-repo sources (do NOT invent): the live-probed `references/GHL-INBOUND-AND-PLAYBOOKS.md`
  §7 (send-`type` enum) / §8 (messaging) / §9 (calendars), plus Skill 29
  `references/{conversations,calendars,payments}.md`. Canonical shapes:
  - **Messaging — one endpoint, switch on `type`:** `POST /conversations/messages`
    (scope `conversations/message.write`) for `SMS` / `Email` (subject+html) / `FB` / `IG` /
    `WhatsApp` / `Live_Chat`. **Chat Widget = Live Chat** (no distinct widget type). **All-in-One /
    unified inbox is NOT a separate send type** — every channel flows through this one endpoint; pick
    the `type` matching the inbound channel. Verified-REJECTED `type`s documented: `GMB`, `TikTok`,
    `Call`, and long-forms `Instagram`/`Facebook`/`Webchat` (4xx — reply to GMB/TikTok via a GHL
    workflow automation instead).
  - **Calendars:** list `GET /calendars/?locationId=` (scope `calendars.readonly`), get
    `GET /calendars/<calendarId>` (`calendars.readonly`), create `POST /calendars/`
    (`calendars.write`), free-slots `GET /calendars/<calendarId>/free-slots?startDate=&endDate=`
    (epoch **milliseconds**, scope `calendars.readonly`).
  - **Appointments:** book `POST /calendars/events/appointments` (required `calendarId`,
    `locationId`, `contactId`, `startTime`; optional `endTime`), reschedule
    `PUT /calendars/events/appointments/<eventId>`, cancel `DELETE /calendars/events/<eventId>`
    (the book response `id` IS the `eventId`) — all scope `calendars/events.write`.
  - **Invoices:** create `POST /invoices/` then send `POST /invoices/<invoiceId>/send` —
    both scope `invoices.write`.
  - Headers everywhere: `Authorization: Bearer $GHL_PRIVATE_INTEGRATION_TOKEN`,
    `Version: 2021-04-15`, `Content-Type: application/json` (the repo's verified Version).
- **`scripts/24-update-tools-md.sh`** — idempotently injects that canonical block into the workspace
  `TOOLS.md` (OS-aware: `/data/.openclaw/workspace/TOOLS.md` / `$HOME/.openclaw/workspace/TOOLS.md`,
  override via `TOOLS_MD` env or arg 1). Marker-wrapped (`<!-- BEGIN/END SKILL38: GHL_API_QUICK_REFERENCE -->`),
  timestamped backup before any write, skips cleanly if the block is already present. Universal: the
  block carries placeholders only; the client's real `PUBLIC_HOSTNAME`, if exported, is written ONLY
  as a one-line orientation comment — never a token, never client data. Runs in the core-file-updater
  wave (alongside `05-update-agents-md.sh` / `06-append-memory-rules.sh`).
- **`scripts/qc-tools-md-ghl-ref.sh`** — machine-enforces the block. FAILs if it is missing any
  messaging type (SMS/Email/FB/IG/Live_Chat) or the unified-inbox note, any calendar op
  (list/get/create/free-slots), any appointment op (book/reschedule/cancel), the send-invoice op, or
  any required scope; if it exceeds the concise size budget (default 160 lines); or if it leaks any
  personal/client identifier (literal Bearer token / email / phone / 20+ char real-id). SOURCE mode
  scans `references/ghl-api-quick-reference.md` (CI-runnable, no install needed); `--tools-md FILE`
  scans an installed `TOOLS.md` (exit 3 = block missing = step skipped). Negative-tested: a dropped
  op, a dropped scope, an oversize budget, and an email/phone/token/real-id leak each FAIL.

### Changed
- `scripts/11-run-qc-checklist.sh` — runs the new gate (source block always; live `TOOLS.md` when present).
- `.github/workflows/qc-static.yml` — new step proves the source block is complete/concise/leak-free,
  the installer is idempotent and preserves existing content, the live gate passes on an injected
  `TOOLS.md` and exits 3 on a missing marker, and the negative cases (leak / oversize / dropped op) FAIL.
- `INSTALL.md` + `INSTRUCTIONS.md` (new Step 7.5) reference the installer + gate.
- Self-counts: `scripts/` (`*.sh`) and `references/` (`*.md`) bumped for the new GHL-quick-ref installer +
  gate + reference, layered on top of the v1.4.19 self-test/no-personal-data additions.

## [1.4.19] - 2026-05-30 - Standardized workflow-AI output + exhaustive Build-with-AI webhook + 60yo-simple verification + client self-test + AI backend self-test + Notion-doc enforcement + UNIVERSAL no-personal-data guard

### Why
Three problems with the workflow-AI output: (a) it was NOT standardized — wildly different each run;
(b) it was too light on the GHL Build-with-AI Custom Webhook instructions (the part Build-with-AI gets
wrong most); and (c) the templates + source playbook were authored using a specific operator + client as
the worked example, so real names and client data leaked into the generated client Notion docs (a client
opened "their" doc and saw someone else's name). This release standardizes the output, spells out every
webhook field, rewrites the human verification to be dead-simple for a 60-year-old, adds a client
self-test and an AI backend self-test, hard-enforces the Notion doc, and strips ALL personal/client data
from a UNIVERSAL skill. The GHL body stays EXACTLY 23 keys, flat (non-negotiable).

### Added
- **`scripts/24-self-test-hook.sh`** — the AI BACKEND SELF-TEST (the agent tests ITSELF before the client
  ever does), a BLOCKING readiness gate. After configuring the hook and BEFORE telling the client to test,
  the agent: (a) confirms the backend is prepared to receive (hooks.enabled, an inbound mapping with a
  working model, `deliver:false`, node-owned `conversational-logs/`, GHL creds in `secrets/.env`, gateway
  healthz 200); (b) POSTs a SYNTHETIC FLAT 23-key GHL inbound (channel sms, a dedicated throwaway test
  contact) to its OWN public hook with the real Bearer token; (c) VERIFIES by ground truth — hook returns
  200/{ok:true}, the run used the configured model with NO 401/429, the agent READ the conversation log,
  and the GHL Conversations API send returned a messageId (creates a temporary test contact via the GHL
  API, confirms the send, then DELETEs the temp contact + the test log); (d) on any failure the agent FIXES
  the cause and RE-TESTS until green; (e) setup is NOT marked complete and the client NOT told to test until
  it passes. `--check-wiring` static mode + no-config `--live` SKIP (exit 3) for CI. Standard documented in
  `references/GHL-INBOUND-AND-PLAYBOOKS.md` §4.5; wired as a blocking gate in `scripts/11-run-qc-checklist.sh`.
- **`scripts/qc-no-personal-data.sh`** — UNIVERSAL-skill guard. Scans the whole `38-conversational-ai-system/`
  tree AND drives `21-generate-client-reference-sheet.sh` offline to scan the generated reference sheet, and
  FAILS on ANY forbidden identifier (operator/client names, real hostnames, real tokens, real location ids,
  real phone/email, real Telegram ids). Negative-tested (a planted identifier exits 1). Wired into
  `scripts/11-run-qc-checklist.sh` + CI (with an in-CI negative self-test).
- **`references/workflow-ai-instructions-standard.md` §0** — a hard, explicit block: **"EVERY workflow-AI
  instruction set MUST INCLUDE ALL OF THE FOLLOWING"** — the five mandatory inclusions, in exact order:
  (1) workflow name + PUBLISH; (2) Trigger: type + sub-option + filters in exact order; (3) **Settings →
  Allow Re-entry = ON**; (4) Custom Webhook — every field with the exact value; (5) Save → Publish toggle ON
  → Save. `scripts/21-generate-client-reference-sheet.sh` + `templates/sms-workflow-ai-prompt-template.md`
  emit this exact structure every run, for every client.
- **🧪 "How to test your system"** section in the generated client doc — a client self-test: Contacts →
  search your own name → open your own contact record → send yourself a text → reply from your phone →
  Automations → open the workflow → **Execution Logs** → every step green (especially the Custom Webhook);
  anything red = failure (re-run the verification checklist / contact support).

### Changed
- **REQ 1 STANDARDIZATION** — the workflow-AI prompt + the manual-fill steps + the verification now carry
  the §0 five-part structure every run, including the previously-missing **Settings → Allow Re-entry = ON**
  (a workflow left at the default fires once per contact then silently goes dead).
- **REQ 2 EXHAUSTIVE Build-with-AI webhook** — the Build-with-AI prompt AND the verification now spell out
  EVERY Custom Webhook field with the EXACT value: EVENT = CUSTOM; METHOD = POST; URL = the exact hook URL
  (no placeholder); AUTHORIZATION dropdown = None (token goes in headers); HEADERS via "Add item" with the
  value box holding ONLY `Bearer <token>` (never the word "Authorization"), then Content-Type =
  application/json; RAW BODY = the full FLAT 23-key JSON; plus Settings → Allow Re-entry = ON. Every value
  the human copies is in its OWN code block.
- **REQ 3 60-year-old-simple verification** — `scripts/21-generate-client-reference-sheet.sh` §8 rewritten
  to a dead-simple per-area checklist: one short imperative line per check + the exact value in a COPY CODE
  BLOCK + a one-line "if you do not see it, paste this." Covers, in order: open the workflow; Trigger;
  Settings → Allow Re-entry; Webhook URL; Headers; Raw Body; Save; Publish; Save.
- **REQ 6 Notion doc HARD-enforced** — `scripts/qc-reference-sheet.sh` now also requires the **Allow
  Re-entry** instruction and the **🧪 How to test your system** section (Execution Logs / Contacts / reply /
  red = fail); combined with the existing gates the install cannot be marked complete unless the doc was
  created (Quick Start + 23-key body + split Authorization + playbooks/trigger/I-Do-You-Do + VPS-vs-Mac +
  How-to-test) AND delivered via Telegram (`qc-notify-client-doc.sh`, fail-closed). The
  `templates/workflow-verification-checklist-template.md` also gained the Allow-Re-entry checks + an
  Execution-Logs self-test end-to-end test.
- **REQ 7 UNIVERSAL — stripped ALL personal/client data** from the entire tree (templates, scripts,
  references including the v6.0 source playbook, and the CHANGELOG narrative): operator/client names, the
  worked-example client + brand, real hostnames, the hardcoded operator Telegram id, and a real personal
  email local-part — all replaced with generic placeholders (`<CLIENT_BUSINESS_NAME>`, `<PUBLIC_HOSTNAME>`,
  `<HOOKS_TOKEN>`, `<LOCATION_ID>`, "the operator", "your setup admin"). The operator chat id is now
  supplied per-install (`OPERATOR_TELEGRAM_CHAT_ID`), never hardcoded to a person. The operator-personal
  Cloudflare-OTP-suppression note was rewritten as a generic deliverability gotcha. Telegram message
  sign-offs changed from a person's name to "your setup admin." Enforced going forward by
  `scripts/qc-no-personal-data.sh`.

### Files
- scripts/ 37 → 39 (`24-self-test-hook.sh`, `qc-no-personal-data.sh`). QC linters 9 → 10.
- CI (`.github/workflows/qc-static.yml`): added the self-test wiring gate, the no-personal-data gate (with
  an in-CI negative self-test), and the Allow-Re-entry/How-to-test markers ride along in the reference-sheet
  gate. Touched ONLY `38-conversational-ai-system/` + its CI steps.

## [1.4.18] - 2026-05-30 - Audit/prune (v6.0 playbook labels + stale self-counts) + VPS-vs-Mac install section (QC-enforced)

### Why
A full audit/prune pass plus a new installer-facing deliverable. (1) The packaged playbook was
consolidated to **v6.0** (the file is `references/v6.0-source-playbook.md`, banner "Version: 6.0",
"Supersedes v5.x"), but the skill-package files (SKILL.md / INSTALL.md / INSTRUCTIONS.md /
CORE_UPDATES.md / EXAMPLES.md) and several deep-dive references still NAMED the current canonical
doc "the v5.14 playbook" — including self-contradictions like "the v5.14 playbook … lives at
`references/v6.0-source-playbook.md`". (2) Several self-counts had drifted (playbook line count,
"27 protocols", a stale AGENTS.md marker name, "scripts/ numbered 00-08"). (3) Installers had no
single place that spelled out how a Skill 38 install differs on a Hostinger Docker VPS vs a Mac mini,
which is the #1 source of "the hook is live but inbound does nothing" / "the token vanished on reboot".

### Added
- **`references/VPS-VS-MAC-INSTALL.md`** — a new reference: **⚙️ Things to consider when installing:
  VPS (Hostinger Docker) vs Mac mini**. VPS column: env in host `/docker/<project>/.env` applied with
  `docker compose up -d --force-recreate` (plain restart ignores `env_file`); GHL/provider creds ALSO
  in the container `/data/.openclaw/secrets/.env`; the `/hostinger/server.mjs` wrapper rewrites
  `hooks.token` to `hooks_${OPENCLAW_GATEWAY_TOKEN}` each boot UNLESS `OPENCLAW_HOOKS_TOKEN` is set in
  the host `.env`; the gateway port is often NOT 18789 (read `PORT` / `openclaw gateway status`);
  public hook via cloudflared-on-PM2 (`pm2 save`) or an existing Traefik `*.hstgr.cloud` route; `apt`
  is a brew shim (use `/data/linuxbrew/.linuxbrew/bin/brew`). Mac column: provider keys in the
  `openclaw.json` top-level `env` block (launchd service-env / `~/.openclaw/.env` alone insufficient);
  GHL creds in `~/.openclaw/secrets/.env`; restart via
  `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway`; remote access via Cloudflare tunnel +
  Access token (wrap remote cmds in `zsh -lc`); public hook via `sudo cloudflared service install`.
  COMMON to both: 23-key FLAT body, node-owned `conversational-logs/`, GHL creds in `secrets/.env`,
  `deliver:false`, Ollama Cloud `:cloud` `maxTokens` capped at 65536. References count 15 → 16.
- **`scripts/21-generate-client-reference-sheet.sh`** now emits that VPS-vs-Mac section into the
  generated client reference sheet, placed AFTER the 🚀 Quick Start and BEFORE the deep
  Reference & explanation (Quick-Start-first ordering preserved). The block mirrors
  `references/VPS-VS-MAC-INSTALL.md` verbatim.
- **`scripts/qc-reference-sheet.sh`** now machine-enforces the VPS-vs-Mac section (and gained a
  `--require-manual-fill` flag that asserts it explicitly; it is checked by default regardless).
  FAILs the generated doc if the section is missing OR if either the VPS points (force-recreate /
  container `secrets/.env` / `OPENCLAW_HOOKS_TOKEN` / the server.mjs wrapper) or the Mac points
  (`openclaw.json` top-level `env` block / `launchctl kickstart`) are absent. Negative-tested:
  removing the whole section, the lone `launchctl` line, or the lone `force-recreate` line each
  produces a named FAIL (exit 1).
- **`INSTRUCTIONS.md`** — a new BINDING hard rule for the VPS-vs-Mac section + Step 6 pointer.

### Fixed (audit/prune — stale, conflicting, or drifted)
- **Stale version labels (the packaged playbook is v6.0, not v5.14).** Renamed the operative
  "the v5.14 playbook / v5.14 walkthrough / Skill 38 (v5.14)" references to **v6.0** in:
  `SKILL.md` (title + read-order + ships list + estimate), `INSTALL.md` (protocols / source-playbook /
  Step-9.21 / estimate / Phases-0-7 / read-next), `INSTRUCTIONS.md` (banner + read-order + "ship in
  full" + Step 5 + Phase-5 header + pending-features), `CORE_UPDATES.md` (title + AGENTS-block source),
  `EXAMPLES.md` (model-freshness rule), and the deep-dive cross-references in
  `references/{stripe-webhooks-reference,shopify-graphql-reference,cloudflare-tunnel-troubleshooting,
  stripe-coupons-api,sales-frameworks-deep-dive,ghl-coupons-api,cloudflare-godaddy-setup-guide}.md`
  and `scripts/{02-create-knowledgebases,07-stripe-setup-wizard}.sh`. **Deliberately preserved** as
  accurate history: the playbook's own internal changelog, the per-feature "shipped in vX.Y" roadmap
  tags, the VERBATIM-extraction provenance headers/comments (with their original source filename +
  line ranges), and the live MEMORY.md idempotency marker names (renaming them would re-append rules
  on installed boxes — clarified in CORE_UPDATES.md that those labels are stable identifiers).
- **`INSTRUCTIONS.md` "8,797 lines" → "9,483 lines"** and **`INSTALL.md` "8,797-line" → "9,483-line"**
  (actual `wc -l` of `references/v6.0-source-playbook.md`).
- **`references/conversational-ai-strategic-roadmap.md` "packages 27 protocol files" → "32"** (the
  actual count; the 27 contradicted SKILL.md's "32 protocol files" + the SELF-COUNTS). Refreshed the
  status-legend / "Last updated" banner from v5.4 to v6.0 (per-feature "shipped in vX.Y" tags kept).
- **`INSTRUCTIONS.md` "where the 27 protocols ship" → "the bulk of the 32 protocols"** and
  **"scripts/ folder is numbered 00-08" → "00-23"** (both stale self-counts).
- **`CORE_UPDATES.md` AGENTS.md marker correction.** It documented a marker
  `<!-- BEGIN skill-38 conversational-ai v5.14 -->` that `scripts/05-update-agents-md.sh` does NOT
  write; corrected to the real `<!-- BEGIN SKILL38: <NAME> -->` convention (e.g.
  `SKILL38_RUNTIME_ROUTING`).
- **`references/cloudflare-tunnel-troubleshooting.md` hardcoded `localhost:18789`** softened to
  `localhost:<PORT>` with an explicit note that a VPS gateway often binds a non-18789 port (read
  `PORT` / `openclaw gateway status`).
- Self-counts: `SKILL.md` SELF-COUNTS comment and the "16 reference documents" lines updated for the
  new reference; counts re-verified (`protocols/=32`, `scripts/=37`, `references/=16`, journeys=8).

### Verified (no change required)
- **The 23-key FLAT GHL Custom Webhook body holds everywhere.** `qc-23-key-bodies.sh` scans
  references/ + templates/ + scripts/ (incl. the ~9.5k-line v6.0 playbook) — all 22 object-A bodies
  PASS (23-key, flat, placeholder-free). The body in `protocols/conversation-workflows-protocol.md`
  was hand-verified as the full flat 23-key body. No 8/11/13-key or nested body exists anywhere; the
  only sub-23 mentions are "no stripped bodies allowed" rules. messageTemplate stays server-only +
  placeholder-free, `deliver:false`, send-directive + conversation-memory read-before/append-after all
  green (`qc-send-directive.sh`, `qc-conversation-memory.sh`).
- The Authorization header in the client doc stays TWO separate copy blocks ("Authorization" / "Bearer
  <token>"), Content-Type likewise split; Quick-Start-first ordering, the "Your Communication
  Playbooks" section (trigger word + I-Do/You-Do + brainstorm), and the mandatory Telegram doc-delivery
  are all intact and still QC-green.

### QC
All Skill 38 gates green: `qc-23-key-bodies`, `qc-trinity-registry-test`, `qc-send-directive`,
`qc-conversation-memory`, `qc-playbook-doc-test`, `qc-reference-sheet` (now incl. the VPS-vs-Mac
markers), `qc-notify-client-doc`, `qc-config-schema-safety`. `bash -n` clean across all 37 scripts.
QC-PROTOCOL.md 10-category rubric: every category ≥ 8.5.

### Notes
- Additive only; no schema/config changes; no `.py` added (the inline grep/awk QC core stays BASH, so
  the `.py` claude-/anthropic ban is respected). `38-conversational-ai-system/skill-version.txt` is the
  only version bumped (1.4.17 → 1.4.18) — it is NOT one of the repo's 8 version locations, so
  `bump-version.sh` was correctly not run. SCOPE: 38-conversational-ai-system only; no other skill
  touched.

## [1.4.17] - 2026-05-29 - New-playbook CREATION experience: personal trigger word + "I Do / You Do" + brainstorm prep

### Why
Clients knew they *could* ask for a new communication playbook (v1.4.16), but the skill never taught the
agent to make the experience feel guided and personal, and the client doc never explained the experience.
Three pieces were missing: (1) a personal **trigger word** (like "Alexa"/"Hey Siri") so the client has a
fast, memorable way to start a build; (2) an **"I Do / You Do"** overview so the client knows who is
responsible for what and that a good playbook takes **~15-30 minutes** (not 30 seconds); and (3) the
**brainstorm "things to think about"** so the client comes prepared and knows the AI's job is to brainstorm
the perfect playbook WITH them.

### Added — AGENT BEHAVIOR (the playbook-CREATION flow)
- **`protocols/conversation-workflows-protocol.md`** — extended the new-playbook creation flow (Section A +
  Part 3) with three new agent behaviors, NOT a duplicate flow:
  - **A.0 — Offer a personal TRIGGER WORD (FIRST build only, BINDING).** On the client's first playbook
    build, the agent OFFERS a personal trigger word, explained voice-assistant style (*"like 'Alexa' or
    'Hey Siri'"*; e.g. *"Playbook time!"*), asks for it, confirms it, and **REMEMBERS it** — stored in the
    client's **USER.md** (`Playbook trigger word: "<word>"`), in the `conversation-workflows/registry.md`
    header (`Trigger word: "<word>"`), and added to the AGENTS.md Step 1.85/1.75 trigger set. On later
    builds, recognizing the stored word (or any Section A phrase) starts the flow without re-offering.
  - **A.1 — Present the "I Do / You Do" overview (every build start, BINDING).** The agent presents a short
    8-step who-does-what map (YOU trigger → AI brainstorms → YOU answer → AI drafts → YOU review → AI
    finalizes+stores+builds the Workflow AI prompt → AI wires tag/calendar/appointment actions → YOU
    approve, go live) and sets the **~15-30 minute** expectation up front.
  - **A.2 — Brainstorm prep (the agent's job + "things to think about").** The agent states its job is to
    BRAINSTORM the perfect playbook WITH the client, and gives the things to think about — goal / audience
    / channel(s) / offer-hook / tone / timing & cadence / win action — with the reassurance *"if you're
    unsure, that's what I'm here to brainstorm."* Then asks only smart-gap questions, never a 50-question
    form.
- **`references/communications-playbook-standard.md`** — new **§8** pointer mirroring A.0/A.1/A.2 so the
  three behaviors ship with every playbook build (author-to-the-protocol, no duplication).
- **`references/workflow-ai-instructions-standard.md`** — new **§7** pointer mirroring the same flow (the
  Workflow-AI prompt is built during the same creation flow).
- **`INSTRUCTIONS.md`** — extended the "Your Communication Playbooks" BINDING rule to name the new
  client-facing content (🔑 trigger word, 🤝 I-Do/You-Do + ⏱️ ~15-30 min, 🧠 brainstorm things-to-think-
  about) and to point at the matching agent behavior in the protocol.

### Added — CLIENT DOC (the client-facing explanation)
- **`scripts/21-generate-client-reference-sheet.sh`** — extended the **💬 Your Communication Playbooks**
  section (still AFTER 🚀 Quick Start, BEFORE Reference & explanation; FLAT 23-key body + Quick-Start-first
  ordering unchanged) with three emoji-rich blocks: **🔑 Your personal trigger word** (voice-assistant
  style, with a copyable *"Playbook time!"* example and the "your AI remembers it" note); **🤝 How we build
  it together — the "I Do / You Do" process** (the 8-step split + the ⏱️ ~15-30 minute expectation); and
  **🧠 Things to think about before we brainstorm** (the goal/audience/channel/offer/tone/timing/win-action
  list + the "if you're unsure, that's what I'm here to brainstorm" reassurance).

### QC
- **`scripts/qc-reference-sheet.sh`** — now ENFORCES the generated client doc carries the new content, and
  FAILs the build if missing: the **"trigger word"** concept explained voice-assistant style (**Alexa /
  Hey Siri**); the **"I Do / You Do"** process + the **~15-30 minute** time expectation; and the brainstorm
  **"things to think about"** list + the **"here to brainstorm"** reassurance. Negative-tested: stripping
  any of the three from a generated sheet makes the gate exit non-zero. Wired into
  `scripts/11-run-qc-checklist.sh` + CI `.github/workflows/qc-static.yml` (unchanged wiring — same gate).

### Notes
- Additive only; no schema/config changes. THE TRINITY, the 23-key body, the send-directive, the
  conversation-memory, the per-playbook doc, the Telegram doc-delivery, and the Authorization two-block
  rule are all unchanged.

## [1.4.16] - 2026-05-29 - Authorization two-block fix + enriched "Your Communication Playbooks" (just-ask CTA + Convert-and-Flow abilities)

### Root cause this prevents
- **(A) The Authorization VALUE box still carried the "Authorization:" prefix.** The Reference &
  explanation body of the client doc (from `templates/client-reference-sheet-template.md`) emitted the
  Authorization header as a SINGLE combined code block `Authorization: Bearer <token>` (and a single
  combined `Content-Type: application/json`). A GHL custom header has a **Key field** and a **Value
  field** — two separate copy boxes. The Quick Start (in `21-generate-client-reference-sheet.sh`) already
  split them, but the template body did not, so the doc still showed a combined block the client had to
  hand-edit. (The combined-block QC check only fired on real ```` ``` ```` fences; the template used
  pseudo-fence `[code block, copy button]` markers, so the bug slipped through.)
- **(B) Clients did not know the AI builds new playbooks FOR them.** The "Your Communication Playbooks"
  section said where playbooks live and "tell your AI to build one," but did not teach the client that
  their AI is connected to Convert and Flow and can take real actions (tags, calendar, appointments), nor
  walk them through what the AI does end-to-end.

### Changed
- **`templates/client-reference-sheet-template.md`** — the Authorization header is now **TWO separate copy
  blocks**: block 1 = exactly `Authorization` (paste into the Header KEY field), block 2 = exactly
  `Bearer <HOOKS_TOKEN>` (paste into the Header VALUE field — **the value box no longer carries the
  `Authorization:` prefix**). Content-Type split the same way (block 1 `Content-Type`, block 2
  `application/json`). The click-by-click step now tells the reader exactly which field each block goes
  into (Key field vs Value field, never one combined box).
- **`scripts/21-generate-client-reference-sheet.sh`** — ENRICHED the **💬 Your Communication Playbooks**
  section (still AFTER the 🚀 Quick Start, BEFORE the Reference & explanation; FLAT 23-key body and
  Quick-Start-first ordering unchanged). It now carries: a friendly emoji-rich **"Want another
  communication playbook? Just ask me! 🚀"** CTA with a concrete copyable example (*"Help me build a
  missed-call follow-up playbook"*, plus appointment-reminder/lead-nurture/review-request examples); a
  walkthrough of what the AI does — (1) 💬 brainstorm WITH you (not a 50-question form), (2) 🛠️ create
  the playbook, (3) 🗂️ store it in `conversation-workflows/` **mirrored to Notion**, (4) 📝 build the
  matching **Workflow AI prompt wired to YOUR Convert and Flow account**, (5) 🤖 take real actions in
  Convert and Flow on your behalf — **create tags 🏷️, update your calendar 📅, create/book appointments
  🗓️**; and the explicit line **"You have an AI that is connected to your Convert and Flow account and
  can do these things for you — just ask."**
- **`scripts/qc-reference-sheet.sh`** — now ENFORCES: (a) the **Bearer-value block must NOT contain the
  word "Authorization"** (a new check, in addition to the existing combined-`Authorization: Bearer` and
  separate-key/value-block checks); (b) the enriched playbook section — the **"Want another communication
  playbook? Just ask me!"** CTA, the concrete copyable example, the `conversation-workflows/` + Notion
  (mirrored) location, the **brainstorm / not-a-50-question** note, the **Workflow AI prompt** wired to
  **Convert and Flow**, the Convert-and-Flow abilities (**create tags / update calendar / book
  appointments**), and the explicit **"connected to your Convert and Flow account — just ask"** statement.
  Negative-tested (a doc missing any of these FAILs; a combined or prefixed Authorization value FAILs).
- **`references/communications-playbook-standard.md`** + **`references/workflow-ai-instructions-standard.md`**
  — mirrored both changes into the standards that define this content: the Authorization **two-block** rule
  (block 1 `Authorization` → Key field; block 2 `Bearer <token>` → Value field, no `Authorization:`
  prefix; Content-Type split the same way) and the enriched "Your Communication Playbooks" section (just-ask
  CTA + concrete example + brainstorm-not-50-questions + store-and-mirror + Workflow-AI-prompt-wired-to-
  Convert-and-Flow + the create-tags/calendar/appointments abilities + the explicit connected statement).

### Version
- `skill-version.txt` 1.4.15 → **1.4.16**; this CHANGELOG entry; `SKILL.md` SELF-COUNTS stamp →
  v1.4.16 + the `qc-reference-sheet.sh` description updated. **No script/linter was added or removed**
  (scripts/=37, protocols/=32, references/=15, journey templates=8 all unchanged), and **none of the 8
  repo-tracked version locations changed**, so the repo version stays v10.16.9 and `bump-version.sh` is
  intentionally NOT run (matching the v1.4.15 / v1.4.14 / v1.4.13 precedent).

### Constraints honored
- 23-key FLAT body unchanged (`qc-23-key-bodies.sh` still green); Quick-Start-first ordering and the FLAT
  23-key body in the generated doc are intact; no nesting; no `\n` in JSON; QC stays BASH (no `.py` with
  `claude-`/`anthropic`). All Skill 38 static gates green locally.

## [1.4.15] - 2026-05-29 - Mandatory Telegram doc-delivery + Communication Playbooks location section + readiness gates

### Root cause this prevents
- **(A) The client doc kept not getting sent.** The operator has said it repeatedly — "every client gets
  their link via Telegram, no matter what" — yet the install kept finishing without the client ever being
  SENT their Quick-Start / Notion doc LINK over Telegram. It was prose, not an enforced gate, so it got
  skipped. (And finding the chat from `sessions.json` keys alone misses paired chats — the paired-chat lesson.)
- **(B) Clients ask "where are my workflows?" on their first test.** The generated doc had no prominent
  answer to where their communication playbooks live, or how to get a new one.
- **(C) "Complete" was declared before the backend could receive.** No single gate asserted hooks.mappings
  live + deliver:false + a working model + healthz 200 before testing/hand-off.

### Added
- **`scripts/22-notify-client-doc.sh`** (NEW) — MANDATORY, GATED Telegram doc-delivery. Finds the client's
  Telegram chat id by **grepping the transcripts** `agents/*/sessions/*.jsonl` for every id form
  (`"chat":{"id"`, `telegram:direct:`, `"chatId"`, `"from":{"id"`), drops the operator id, takes the
  **most-frequent** remaining id (NOT sessions.json keys only). Sends the doc LINK via
  `openclaw message send --channel telegram` (gateway only, never `api.telegram.org`). Records
  `clientDocDelivered=true` in the run manifest on success; on no-chat / send-failure it **FLAGS LOUDLY**
  (stderr) + records `clientDocDelivered=false` and **exits non-zero** — the install is INCOMPLETE, never a
  silent skip.
- **`scripts/qc-notify-client-doc.sh`** (NEW) — machine-enforces the above is present, transcript-grep-based,
  gated, gateway-sending, and WIRED into `scripts/11-run-qc-checklist.sh` + INSTRUCTIONS.md. Wired into CI
  (with fixture smoke tests: a client id must win the transcript scan; an operator-only transcript must
  exit 1 and record `clientDocDelivered=false`).
- **`scripts/qc-backend-ready.sh`** (NEW) — concise "backend ready to RECEIVE" completion gate:
  hooks.mappings live + `deliver:false` + a working `model` + gateway `healthz` 200. Live check; exits 3
  (SKIP) when no install is present (so CI treats it as a skip, not a failure). Wired into Step 11 QC + CI.

### Changed
- **`scripts/21-generate-client-reference-sheet.sh`** — the generated client doc now carries a prominent
  **💬 Your Communication Playbooks** section, placed AFTER the 🚀 Quick Start and BEFORE the
  Reference & explanation. It says WHERE the playbooks live (the client's master-files
  `conversation-workflows/` folder + the human-facing copies in Notion → Google Docs → text) and, in BIG
  BOLD, **"Want a NEW communications playbook? Start here:"** — just tell your AI *"help me build a [purpose]
  playbook"* and it brainstorms with you and builds all 3 parts (THE TRINITY: workflow-AI prompt +
  conversation playbook + GHL automation), with what-happens-next.
- **`scripts/qc-reference-sheet.sh`** — extended to FAIL the build if the generated sheet is missing the
  **Your Communication Playbooks** section, the **"Want a NEW communications playbook"** call-to-action, the
  `conversation-workflows/` + Notion location, the *"help me build a … playbook"* instruction, or the
  all-3-parts (Trinity) statement. (Still BASH; offline Layer-3 sandbox.)
- **`scripts/11-run-qc-checklist.sh`** — runs the two new gates (`qc-notify-client-doc.sh` +
  `qc-backend-ready.sh`, the latter SKIPs on exit 3).
- **`INSTRUCTIONS.md`** — added Step 6.5 (mandatory gated Telegram doc-delivery) + three binding Hard rules
  (Telegram delivery; doc-exists-AND-backend-ready completion gates before testing; the Your Communication
  Playbooks section). Checkpoint D now requires `clientDocDelivered=true`.
- **`references/v6.0-source-playbook.md`** — new Step 6.5 (the transcript-grep Telegram delivery gate);
  Checkpoint D + Phase 7 deliverables now require the Telegram delivery, the Your Communication Playbooks
  section, and the backend-ready gate.
- **`references/communications-playbook-standard.md`** + **`references/workflow-ai-instructions-standard.md`**
  — added the "Your Communication Playbooks" section to the standard so every client doc carries it.
- **`.github/workflows/qc-static.yml`** — two new CI steps (Telegram doc-delivery gate + fixtures; backend-
  ready no-config SKIP assertion). All new gates are BASH (no `.py`), respecting the claude-/anthropic ban.
- **`SKILL.md` / `INSTALL.md`** — self-counts re-verified: scripts/ 34 → **37** (added the delivery step +
  two QC gates); protocols/=32, references/=15, journey templates=8 unchanged.

### Constraints honored
- 23-key FLAT body (the generator's canonical body is unchanged; `qc-23-key-bodies.sh` still green), no
  nesting, no `\n` in JSON. All new gates are BASH (no `.py` with `claude-`/`anthropic`). CI green.

## [1.4.14] - 2026-05-29 - Bulletproof Quick-Start + workflow-AI (where-to-paste, tag-first, post-build verify)

### Root cause this prevents
Verified from live client pain on multiple client builds.
- **(A) Clients copy each field individually (they are 50+).** A combined `Authorization: Bearer <token>`
  line in one code block forces the client to hand-edit after pasting; the header KEY and the header VALUE
  need their OWN copy boxes. Same for `Content-Type` / `application/json`.
- **(B) Quick Start without explanation strands the client; explanation without Quick Start buries the
  copy-paste.** The sheet must lead with an actionable **🚀 Quick Start** AND still carry a full
  **Reference & explanation** section after it — both, in that order.
- **(C) The blank-tag gotcha — blank tag in a filter.** Build-with-AI created a trigger filter like
  `does not contain <tag>` where the referenced tag was **blank / never created**, so the trigger silently
  never matched and every inbound message went nowhere. Tags must be created FIRST (and the client must
  know WHERE to check: **Settings → Tags**), and the post-build verification must re-check that any tag in
  a filter is a real, existing one.

### Changed
- **`scripts/21-generate-client-reference-sheet.sh`** — the generated reference sheet now leads with a
  literal **🚀 Quick Start** section and keeps a full **Reference & explanation** section AFTER it. Quick
  Start order: (1) Webhook URL, (2) **Authorization header — TWO separate copy boxes**: the key
  `Authorization` and the value `Bearer <token>` (never combined), (3) **Content-Type header — TWO separate
  copy boxes**: `Content-Type` and `application/json`, (4) Raw Body JSON (fenced `json`, FLAT 23-key),
  (5) **Tags — create FIRST** (where to check: **Settings → Tags**; what you should see), (6) manual
  Custom-Webhook fill steps (now field-by-field: Method dropdown / URL box / Headers Add-item Key+Value /
  Content-Type dropdown / RAW BODY box), (7) Workflow-AI prompt pointer, (8) **post-build verification** —
  TRIGGER / CUSTOM WEBHOOK / PUBLISH, each with WHERE-to-go + WHAT-you-should-SEE + WHAT-to-put-if-missing,
  including the blank/non-existent-tag-in-a-`does not contain`-filter known bug.
- **`scripts/qc-reference-sheet.sh`** — extended the machine gate. It now FAILS the build if the generated
  sheet is missing: the literal **🚀 Quick Start** section; a **Reference & explanation** section AFTER it
  (order-enforced); a code block containing ONLY `Authorization` AND a code block containing ONLY the
  `Bearer <token>` value (and FAILS if they are combined as `Authorization: Bearer …`); a code block
  containing ONLY `Content-Type` AND one containing ONLY `application/json`; the manual-fill instructions;
  the **create-tag-FIRST + Settings → Tags** instruction; and the **post-build verification** section
  covering TRIGGER + PUBLISH + the blank-tag-in-a-filter bug. (Still BASH; no `openclaw` on PATH in the
  sandbox → offline Layer-3 markdown.)
- **`references/workflow-ai-instructions-standard.md`** — §4 verification now gives WHERE/WHAT/WHAT-to-put
  per item and adds a dedicated **TAG FILTER references a REAL, existing tag** item (the blank-tag gotcha);
  §5 create-tag-first rule now covers filter tags (not just Add-Tag), states **WHERE tags live (Settings →
  Tags)**, and explains why a blank tag in a `does not contain` filter silently never matches.
- **`templates/sms-workflow-ai-prompt-template.md`** — create-tag-first note now covers filter tags + says
  **Settings → Tags** is where to confirm a tag exists; the "Common Build with AI mistakes" list adds the
  blank/non-existent tag-in-a-filter failure mode.
- **`templates/workflow-verification-checklist-template.md`** — the concise checklist now annotates each
  item with WHERE/WHAT-you-should-SEE/WHAT-to-put, and adds a dedicated **TAG FILTER references a REAL,
  existing tag** item (the blank-tag gotcha).
- **`SKILL.md`** — SELF-COUNTS stamp → v1.4.14 (counts unchanged: protocols/=32, scripts/=34,
  references/=15, journeys=8); the `qc-reference-sheet.sh` description updated to list the new enforcement.

### Enforcement
- The extended `qc-reference-sheet.sh` already runs in `scripts/11-run-qc-checklist.sh` and in
  `.github/workflows/qc-static.yml` ("Skill 38 client reference sheet copy-paste artifacts"), so the new
  Quick-Start / separate-blocks / tag-first / post-build-verification markers are checked on every push
  and PR. Negative-tested: a sheet with a combined `Authorization: Bearer` block, no tag-first, or no
  verification section FAILS (exit 1).

### Version
- Skill 38 `skill-version.txt`: 1.4.13 → 1.4.14. No repo-tracked version file changed, so the repo version
  (v10.16.9) and the 8 bump-version.sh locations are unchanged.

## [1.4.13] - 2026-05-29 - v1.4.11 install-script bug fixes (config-validate / jq 1.7 / pointer-source / legacy-path) + MANDATORY manual Custom-Webhook fill instructions

### Root cause this prevents
Two distinct problems, both verified on a live 2026.5.27 box.

**(A) Install-script bugs that broke/degraded fresh installs.**
- `scripts/15-configure-hooks-mappings.sh`: the Model Wizard wrote `agents.defaults.async` /
  `agents.defaults.batch` model keys that are NOT in the 2026.5.27 schema — `openclaw config validate`
  fails ("Invalid input"). It also used a jq merge beginning `.hooks //= {};` which **jq 1.7 REJECTS**
  (the top-level `;` separator is a compile error), so the hooks merge never ran.
- `scripts/04-register-crons.sh` (and the inline cron in `15`): wrote the legacy `.cron.jobs` config
  block, which does NOT validate on 2026.5.27 — crons must be registered via the gateway cron store
  (`openclaw cron add`).
- `scripts/02-create-knowledgebases.sh` + `scripts/03-create-journey-templates.sh`: tried to **`source`**
  the master-files **pointer file**, whose content is a bare directory PATH (not an env script) — the
  shell tries to execute the path and errors ("<path>: is a directory"), leaving `MASTER_FILES_DIR` UNSET.
- `scripts/12-scaffold-channel-playbooks.sh`: hardcoded a legacy skill path
  (`~/clawd/skills/38-openclaw-cloudflare-tunnel`) that no longer exists, so the channel-playbook
  template could not be found.

**(B) Client-facing gap.** GHL's "Build with AI" only builds the workflow SHAPE (trigger + an EMPTY
Custom Webhook action); it does NOT reliably populate the URL, the Authorization/Bearer header, the
Content-Type header, or the Raw Body JSON. Clients did not know they had to open the Custom Webhook action
and paste those values in by hand — so the webhook shipped empty and silently dropped every message.

### Fixed (PART A — install-script bugs)
- **`scripts/15-configure-hooks-mappings.sh`** — (1) Model Wizard no longer writes
  `agents.defaults.async/.batch`; it writes ONLY the supported real-time model
  (`agents.list[main].model`) and PERSISTS the async/batch TIER selections to the secrets/state env
  (`REALTIME_MODEL`/`ASYNC_MODEL`/`BATCH_MODEL`) for downstream consumers. (2) the hooks jq merge now uses
  `.hooks = (.hooks // {}) |` instead of `.hooks //= {};` (valid jq 1.7, same semantics) — the corrected
  SERVER `messageTemplate` (read-before + append-after + mandatory SEND) is unchanged and still validates
  clean. (3) the inline system-health-heartbeat cron is now registered via `openclaw cron add`, not a
  `.cron.jobs` write.
- **`scripts/04-register-crons.sh`** — rewritten to register all 5 crons via the gateway cron store
  (`openclaw cron add --name … --cron … --agent main --message … --light-context --best-effort-deliver`),
  idempotent against `openclaw cron list`; no more `.cron.jobs` config writes. Reads `BATCH_MODEL` from the
  persisted secrets/state env for the batch crons.
- **`scripts/02-create-knowledgebases.sh`** + **`scripts/03-create-journey-templates.sh`** — read the
  master-files pointer with `cat` (it is a path-pointer file, not a sourceable env script) instead of
  `source`-ing it, matching scripts 11/12.
- **`scripts/12-scaffold-channel-playbooks.sh`** — resolves `SKILL38_ROOT` (and the template path)
  DYNAMICALLY from the script's own location instead of the dead hardcoded legacy path.
- **`scripts/10-generate-capabilities-playbook.sh`** — reads the async/batch tier models from
  `$ASYNC_MODEL`/`$BATCH_MODEL` (sourced from secrets/state env) instead of the now-absent
  `agents.async.model`/`agents.batch.model` config keys.

### Fixed (PART B — mandatory manual Custom-Webhook fill)
- **`scripts/21-generate-client-reference-sheet.sh`** — the generated client reference sheet now LEADS
  with the copy-paste values in this exact order: **1) Webhook URL, 2) Authorization/Bearer token (real
  revealed value), 3) Raw Body JSON (fenced `json`, FLAT 23-key), 4) the manual Custom-Webhook fill steps
  ("Build with AI will NOT fill it — do it yourself"), 5) the Workflow-AI prompt pointer** — with all
  explanation/reference following AFTER.
- **`references/workflow-ai-instructions-standard.md`**, **`templates/sms-workflow-ai-prompt-template.md`**,
  **`templates/workflow-verification-checklist-template.md`** — each gains a prominent, MANDATORY section:
  after Build-with-AI runs you MUST open the Custom Webhook action and manually enter Method=POST, the URL,
  Headers via Add item (`Authorization: Bearer <token>` + `Content-Type: application/json`), and the Raw
  Body JSON, then Save + Publish, and verify every field is non-empty before publishing — Build-with-AI
  will NOT fill these for you.
- **`references/communications-playbook-standard.md`** — documents that the manual Custom-Webhook fill step
  is mandatory in every client doc.

### Added
- **`scripts/qc-config-schema-safety.sh`** (pure BASH) — new machine-enforced QC gate that statically scans
  the numbered install scripts and FAILs if any reintroduces a config-invalidating pattern: a `.cron.jobs`
  write, an `agents.defaults.async/.batch` write, or a jq `//= …;` statement. Prose that merely names a
  banned key (comments, `echo`/`printf`/`report_*` strings) is not flagged. Wired into
  `scripts/11-run-qc-checklist.sh` AND `.github/workflows/qc-static.yml` (runs in CI on every push/PR).

### Changed
- **`scripts/qc-reference-sheet.sh`** — extended to ALSO require the manual-fill instructions in the
  generated sheet (greps for "Custom Webhook" + "manually"/"paste" + "Build with AI will not"), on top of
  the existing Bearer/`json`-fence/hook-URL markers.
- **`scripts/11-run-qc-checklist.sh`** — wires `qc-config-schema-safety.sh` in as a mechanical gate.
- **`SKILL.md`** — self-counts updated (scripts 33 → 34); the new QC linter documented.

## [1.4.12] - 2026-05-29 - client reference sheet MUST include the bearer token + a copyable GHL Raw Body JSON (machine-enforced)

### Root cause this prevents
On a live client the generated Client Reference Sheet
(`scripts/21-generate-client-reference-sheet.sh`) had NEITHER the hooks Bearer token NOR the GHL Custom
Webhook Raw Body as a copyable ` ```json ` fenced code block. The client opened their reference doc, the
token was simply missing, and there was no JSON to copy into GHL's Build-with-AI — which stranded the
client. The sheet's content came entirely from the template wrapper, where the bearer token appeared
only inside `[code block, copy button]` pseudo-markers (not a real fence) and the per-channel Raw Body
JSONs lived in a separate Part 3 documentation section, not the reference sheet body. The sheet MUST
contain both, ALWAYS — now enforced, not left to the template.

### Fixed
- **`scripts/21-generate-client-reference-sheet.sh`** now APPENDS two authoritative, always-present
  sections to the rendered reference sheet (so they survive regardless of template wrapping):
  - **Authorization Header / Bearer Token** — resolves the real `hooks.token` in priority order
    `HOOKS_TOKEN` → `OPENCLAW_HOOKS_TOKEN` → `hooks.token` read from `openclaw.json`
    (`$OPENCLAW_CONFIG`, `~/.openclaw/openclaw.json`, `/data/.openclaw/openclaw.json`), and renders it as
    `Authorization: Bearer <token>` inside a real fenced code block. If the token cannot be resolved it
    emits a clearly-marked `REPLACE_ME__…` PLACEHOLDER and WARNs to stderr (never silently omits it).
  - **GHL Custom Webhook — Raw Body** — the canonical FLAT 23-key body as a copyable ` ```json ` fenced
    code block, plus the Method (POST), the hook URL (`https://<host>/hooks/<id>`), and Content-Type
    (`application/json`) as copyable code blocks. The body's `messageTemplate` carries the full
    SEND-directive and stays placeholder-free; the body is not nested and not stripped below 23 keys.

### Added
- **`scripts/qc-reference-sheet.sh`** (pure BASH, mirrors the other `qc-*.sh`) — new machine-enforced QC
  gate. Default mode drives `21-generate-client-reference-sheet.sh` in an offline sandbox (strips
  `openclaw` from PATH → Layer-3 markdown, no network/Telegram) and FAILs (exit 1) if the rendered sheet
  lacks the word `Bearer`, a line-anchored ` ```json ` fence, or a hook URL; `--sheet FILE` statically
  checks an existing sheet; exit 2 (never a blind PASS) if no sheet can be produced/located. BASH (not
  Python) so it respects qc-static's ban on claude-/anthropic strings in `.py` under 22/23. Wired into
  `.github/workflows/qc-static.yml` (runs in CI on every push/PR).

### Changed
- **`scripts/11-run-qc-checklist.sh`** — wires `qc-reference-sheet.sh` in as a mechanical gate.
- **`references/communications-playbook-standard.md`** — new section documenting that the bearer token +
  copyable Raw Body JSON are MANDATORY in every client reference sheet, machine-enforced by
  `qc-reference-sheet.sh`.

## [1.4.11] - 2026-05-29 - enforce the per-playbook human-facing DOC deliverable (Notion → Google Docs → text) so a created playbook can never ship without a client-facing reference

### Root cause this prevents
When a communications/conversation playbook is created (the base install creates the FIRST one —
appointment booking), the agent is supposed to ALSO create a human-facing copy of that playbook in the
**CLIENT's own account**, in the fallback order **(1) the client's Notion → (2) Google Docs → (3) a
plain-text doc the client can access**. On a recent client this step was SKIPPED: the agent scaffolded
the playbook files locally and reported the install "clean," but never created the client's Notion doc,
leaving the customer stranded with no human-facing reference of what was set up. Root cause: the
Notion-doc deliverable was **PROSE** in the playbook, not an **ENFORCED gate**, so the agent skipped it.
This release makes the deliverable un-droppable, enforced exactly like the send-directive and
conversation-memory gates ("AUTOMATIC NEXT STEP prose is not enforcement — needs a state field + a
verify/resume gate + a QC check").

### Added
- **`scripts/qc-playbook-doc.sh`** (pure BASH, bash 3.2-safe) — new machine-enforced QC gate. Runs against
  a client's installed `conversation-workflows/` folder + the run manifest: for EVERY conversation playbook
  (each `<slug>.md` / registry row) it FAILS (exit 1) if there is NO recorded human-facing doc — no Notion
  URL / Google Doc URL / plain-text path on the registry row OR in a `playbookDocs[]` manifest entry. Exit 2
  when NO playbooks exist yet (never silently pass blind); exit 3 when no `conversation-workflows/` folder is
  found. Mirrors `qc-trinity-registry.sh` / `qc-conversation-memory.sh`. Wired into
  `scripts/11-run-qc-checklist.sh`.
- **`scripts/qc-playbook-doc-test.sh`** — CI fixture suite (10 cases) proving the gate: doc-on-registry-row,
  doc-in-manifest (Notion / Google Docs / plain-text), no-doc => FAIL, manifest-entry-without-destination =>
  FAIL, registered-but-no-doc => FAIL, mixed, empty-folder => NO_PLAYBOOKS (exit 2), missing-folder =>
  NO_FOLDER (exit 3). Wired into `.github/workflows/qc-static.yml` (runs in CI on every push/PR), mirroring
  `qc-trinity-registry-test.sh` (the live gate needs a runtime folder, so CI proves it via fixtures).

### Changed
- **Installer now creates + records the per-playbook human-facing doc**
  (`scripts/09-install-conversation-workflows.sh`). After the registry exists, an idempotent doc pass runs
  over every playbook on disk (the appointment-booking starter + any later ones): it tries **Notion**
  (create a NEW subpage under a parent page the integration can access via `NOTION_API_KEY`; if the key is
  missing or no accessible parent page exists, fall through), then **Google Docs** (only if a wired helper
  `SKILL38_GDOCS_HELPER` exists — no silent no-op), then a **plain-text** `.md` under
  `conversation-workflows/client-docs/` as the always-available last resort. The resulting URL/path is
  RECORDED on the playbook's registry row AND as a `playbookDocs[]` line in the run manifest, and an
  operator-facing line states WHERE the doc was created (or which fallback was used). Idempotent: skips a
  playbook that already has a recorded doc.
- **`templates/run-manifest-template.md`** — added a `Playbook docs` section documenting the
  `playbookDocs[]: <slug> -> <url-or-path>` state field (the home for the recorded-doc state the gate checks).
- **BINDING install step + verify/resume self-check** added to `INSTRUCTIONS.md` (Step 9.20 row + a
  NON-NEGOTIABLE hard rule): the install is NOT complete until `qc-playbook-doc.sh` exits 0; if it exits
  non-zero, re-run `09-install-conversation-workflows.sh` to create+record the missing doc, then re-check —
  do not hand off.
- **AGENTS.md Step 1.85 builder block** (`scripts/05-update-agents-md.sh`, `BLOCK_E` Part 3) now makes the
  human-facing doc BINDING + machine-enforced (Notion → Google Docs → text, URL recorded) instead of
  "a NEW Notion doc" prose.
- **Standards updated to mandatory + gated (not optional prose):**
  `references/communications-playbook-standard.md` (new MUST-APPEAR checklist item + §4 now flagged
  MANDATORY/machine-enforced + record-the-destination requirement); `references/v6.0-source-playbook.md`
  (MUST-APPEAR checklist item + §4 flagged mandatory/gated); `references/GHL-INBOUND-AND-PLAYBOOKS.md`
  (§10 day-one wiring requirement now includes the mandatory gated doc; §13 binding-rules index updated);
  `protocols/conversation-workflows-protocol.md` (3-PART build Part 3 now BINDING + gated).
- **`SKILL.md`** self-counts updated (scripts 30 → 32) and the QC-linter list now names the five gates.

### Notes
- The QC gate + its fixture suite are **BASH** (not `.py`), per the qc-static rule that bans
  `claude-`/`anthropic` strings in `.py` files under Skill 22/23 scans.
- No 23-key bodies were touched; FLAT bodies / no nesting / no backslash-n-in-JSON constraints respected.

## [1.4.10] - 2026-05-29 - enforce conversation-memory (read-before + append-after) so hook agents never lose context

### Root cause this prevents
GHL inbound hook sessions are **SINGLE-TURN / stateless** — every hook run is a fresh session
(`user-turns=1`) with no chat history. The agent's only memory of a contact across messages is the
per-contact conversation log file under `conversational-logs/` — it must READ that log BEFORE replying
and APPEND to it AFTER replying. On a live client this broke: the canonical server-mapping
`messageTemplate` was simplified during testing and lost the conversation-log read/append steps, the
`conversational-logs/` directory was never created (and on creation was root-owned so the agent couldn't
write), and AGENTS.md had no memory protocol — so the agent had zero memory and "didn't remember
anything" mid-booking. `qc-send-directive.sh` did NOT catch this because it only checks the SEND clause.
This release makes the conversation-memory logic un-droppable, enforced exactly like the send-directive.

### Added
- **`scripts/qc-conversation-memory.sh`** (pure BASH) — new machine-enforced QC gate. Scans every GHL
  inbound SERVER-mapping `messageTemplate` (the installer canonical + reference examples, detected by the
  `INBOUND MESSAGE FROM GOHIGHLEVEL` signature, mirroring `qc-send-directive.sh`) and FAILS (exit non-zero)
  if it lacks the conversation-log READ-before or APPEND-after steps. The installer template is a hard
  requirement (exit 1 if missing/incomplete); no server templates found = exit 2 (linter went blind).
  Wired into `scripts/11-run-qc-checklist.sh` AND `.github/workflows/qc-static.yml` (runs in CI on every
  push/PR). Now scans 3 server templates (installer + v6.0 playbook + GHL-INBOUND §14.4) — all PASS.
- **AGENTS.md "Conversation Memory Protocol" base rule** (`scripts/05-update-agents-md.sh`, new idempotent
  marker block `CONVERSATION_MEMORY_PROTOCOL`) — concise pointer-style rule: hook sessions are single-turn,
  memory = per-contact logs, READ `conversational-logs/<contact_id>__<name>.md` before replying, CONTINUE
  in-progress topics, APPEND after sending; a reply that ignores or fails to update the log is a failure.

### Changed
- **Installer template now carries read-before + append-after + a fail-closed guard**
  (`scripts/15-configure-hooks-mappings.sh`). The written server-mapping `messageTemplate` now contains the
  MEMORY/READ step, a CONTINUE step, the SEND directive, and an APPEND/LOG step. Added a fail-closed guard:
  the installer refuses to write the hook config (exit 8) if the messageTemplate lacks the conversation-log
  read/append elements (needles `conversational-logs` / `read` / `append`).
- **Installer creates the `conversational-logs/` directory + chowns it to the runtime user**
  (`scripts/09-install-conversation-workflows.sh` — the Step-9 conversation-system installer). Now
  `mkdir -p <MASTER_FILES_DIR>/conversational-logs` and, when running as root, `chown -R` it to the gateway
  runtime user (`node` on VPS/Docker; override via `OPENCLAW_RUNTIME_USER`) so the agent can write logs
  (the client's dir was root-owned and unwritable). Non-root runs warn to chown if the gateway runs as a
  different user.
- **Documented canonical server template updated** so the conversation-memory steps are part of the
  documented canonical template (replacing simplified templates that lacked them):
  `references/v6.0-source-playbook.md` (Step-3 server `messageTemplate`),
  `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14.4 (replaced the simplified one-line server template with the
  full enriched canonical template + send-directive + memory steps),
  `references/communications-playbook-standard.md` (new conversation-MEMORY checklist item),
  `references/workflow-ai-instructions-standard.md` (new conversation-MEMORY checklist item + machine-
  enforcement note). Respects the 23-key rule, FLAT bodies, no nesting, no literal `\n` in JSON — the
  memory steps live ONLY on the SERVER mapping (object B), never in the placeholder-free GHL body (object A).

## [1.4.8] - 2026-05-29 - add Skill 23 cross-reference (role/SOP gate + comms hand-off) to v6.0 playbook

### Added
- **Skill 23 cross-reference in the v6.0 source playbook.** Appended a "🔗 How this connects to the AI
  Workforce Blueprint (Skill 23)" section to `references/v6.0-source-playbook.md` (placed at the end, right
  before the condensed changelog tail). Documents the two enforced connections between Skill 38 and Skill 23:
  (1) the Role Library + SOP Library auto-pull gate (a workforce build is not complete until every role has its
  role library pulled in and its multi-SOP DMAIC library authored — build-state field + verify/resume gate, not
  prose), and (2) the comms-automation hand-off (a workforce with a Communications / Sales / Customer-Support
  department hands off to Skill 38 at closeout to scaffold the matching conversational-AI automations, enforced
  via a `commsAutomationStatus` state field + resume self-ping). Reiterates THE TRINITY (workflow + playbook +
  workflow-AI prompt travel together). No system coverage changed — documentation cross-link only.

## [1.4.7] - 2026-05-29 - close the 2 QC gaps (trinity registry format + 23-key linter covers v6.0 playbook)

Closed the two remaining QC gaps so both machine-enforced linters reconcile against what the install
scripts actually produce — no silent no-ops, no unchecked corpora.

### Fixed
- **GAP 1 — trinity registry format mismatch.** `scripts/qc-trinity-registry.sh` parsed the
  conversation-workflows registry ONLY as a markdown TABLE, but
  `scripts/09-install-conversation-workflows.sh` writes the active-workflow list as BULLETS
  (`<workflow-id>: <one-line description>` under `## Active workflows`). On a real installed registry the
  reconciliation silently no-op'd. The validator now parses the **bullet form** as well as the table: each
  bullet's `<workflow-id>` is reconciled against `<id>.md` + `<id>--build-with-ai-prompt.md` on disk; a bullet
  with no Layer-1 column defaults to "Layer 1 needed" (prompt required) unless the description says
  `(uses existing inbound routing)` / `Layer 1: No`. Installer template and
  `protocols/conversation-workflows-protocol.md` §F updated so installer, validator, and docs agree end to end.
- **GAP 2 — 23-key linter blind to the v6.0 playbook (and to ```bash bodies elsewhere).**
  `scripts/qc-23-key-bodies.sh` explicitly excluded `references/v6.0-source-playbook.md` (~9,430 lines, the
  largest set of GHL RAW BODY examples) and its non-greedy fence regex desynced on mixed-language docs — it
  silently skipped real bodies inside ```bash fences (e.g. BOTH canonical bodies in
  `references/GHL-INBOUND-AND-PLAYBOOKS.md`). Removed the name exclusion and replaced fence pairing with a
  language-agnostic fence walker (opens/closes paired in document order). Scan now covers **22** object-A
  bodies across 5 files (was 9 across 3) — all PASS (23-key, flat, placeholder-free). The v6.0 playbook's 11
  per-channel bodies are scanned and pass; no body needed correcting and the fingerprint did not mis-flag any
  non-body block, so nothing was re-excluded.

### Added
- `scripts/qc-trinity-registry-test.sh` — fixture suite (7 cases) proving the reconciliation catches a
  **registered-but-missing-files** row and a **file-present-but-unregistered** slug on the real **bullet**
  format, plus table-form regressions. Wired into CI (`.github/workflows/qc-static.yml`) next to the 23-key
  linter so both run on every push/PR.

## [1.4.6] - 2026-05-29 - v6.0 clean comprehensive playbook; de-staled

Synced the CLEAN, conflict-free v6.0 comprehensive playbook into the skill so the repo carries NO stale or
self-contradicting playbook content.

### Changed
- **Renamed `references/v5.14-source-playbook.md` → `references/v6.0-source-playbook.md`** (git mv) and replaced
  its content with the clean v6.0 source playbook. Every GHL hook passage in v6.0 is reconciled to the single
  **23-key FLAT body** standard: no nested bodies, no `deliver:true`, no mapping-level `fallbacks`, in-body
  `messageTemplate` kept placeholder-free, server-mapping `sessionKey` is `"{{session_key}}"`.
- Updated every reference/link that pointed to the old `v5.14-source-playbook.md` filename to the new
  `v6.0-source-playbook.md` name across `INSTALL.md`, `INSTRUCTIONS.md`, `protocols/conversation-workflows-protocol.md`,
  six `references/*.md` pointer docs (stripe-coupons, stripe-webhooks, shopify-graphql, sales-frameworks,
  ghl-coupons, cloudflare-tunnel-troubleshooting, cloudflare-godaddy-setup-guide), and the load-bearing scripts
  `scripts/01-locate-master-files-folder.sh` (`PLAYBOOK_SRC`/`DEST_PLAYBOOK`) and `scripts/qc-23-key-bodies.sh`
  (`EXCLUDE_NAMES`).

### Fixed (surgical conflict sweep — contradictions with the corrected 23-key structure)
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` §14 CARDINAL RULE — corrected the stale "GHL Custom Webhook RAW BODY
  … must **NOT** contain a `messageTemplate`" line, which contradicted §14.1's canonical 23-key body (the body
  DOES carry a `messageTemplate` key, kept placeholder-free; only the *templated* `messageTemplate` is server-side-only).
- `protocols/pre-handoff-qc-protocol.md` — corrected a QC checklist item that told the agent to verify a
  `fallbacks` chain "configured" on the `hooks.mappings` entry; `fallbacks` is NOT a valid `.strict()` mapping
  key. Now states fallback chains belong only on the model-routing config.

Standards (communications-playbook-standard, workflow-ai-instructions-standard) remain their own reference docs;
the playbook references them rather than duplicating them.

## [1.4.5] - 2026-05-29 - 8 rated improvements (push to 10): machine-enforced 23-key + TRINITY, Build-with-AI label fix, real self-counts, fleshed journeys, Skill 23 chain

Part of repo `v10.16.9`. Six of the eight rated improvements land in this skill; the other two
(cross-skill chain enforcement + library-gate status surfacing) land in Skill 23 but reference this skill.
No stripped GHL bodies introduced — the 9 embedded object-A bodies all pass the new linter (23-key, flat,
placeholder-free).

### Added
- `scripts/qc-23-key-bodies.sh` — machine-enforces the 23-key GHL RAW BODY rule across references/ +
  templates/ + scripts/ (exactly 23 flat keys, placeholder-free `messageTemplate`, no nesting, no `\n`).
  Wired into `scripts/11-run-qc-checklist.sh` and into CI (`.github/workflows/qc-static.yml`). Excludes the
  verbatim `v6.0-source-playbook.md` (narrative source, superseded by GHL-INBOUND §14); skips object-B server mappings.
- `scripts/qc-trinity-registry.sh` — machine-enforces THE TRINITY: a registry row with a communications
  playbook but no Build-with-AI prompt (or an orphan prompt) is flagged INCOMPLETE; honors the
  Layer-1-not-needed exemption. Wired into `11-run-qc-checklist.sh`; referenced from the verification
  checklist + standards.

### Changed
- **Mislabel fix (the failure this standard set out to kill):** `templates/sms-workflow-ai-prompt-template.md`,
  `templates/workflow-verification-checklist-template.md`, `scripts/21-generate-client-reference-sheet.sh`,
  `scripts/09-install-conversation-workflows.sh`, and `scripts/20-seed-design-principles.sh` now name the
  authoritative location — GHL **Automations → "Build with AI"** (top-right) on a NEW automation — instead
  of "Use Workflow AI" / "Create workflow → Workflow AI".
- **Real self-counts:** `SKILL.md` + `INSTALL.md` now state protocols=32, scripts=27, references=15,
  journeys=8 (was 31/9/10) with a `SELF-COUNTS` re-verify comment; a re-verification note was added to the
  repo `scripts/bump-version.sh`.
- **7 stub journey templates fleshed out** to ≥ coach depth with vertical-specific triggers / conversation
  phases / success actions: consulting, course-creator, e-commerce, real-estate, saas, service-provider,
  wellness (109–121 lines each).
- **Distinction-map table** added at the top of `protocols/conversation-workflows-protocol.md` (channel
  communication playbook vs communications playbook vs workflow-AI prompt vs GHL automation).
- **Skill 23 upstream cross-reference** added to `SKILL.md` + the protocol's TRINITY note (Skill 23's
  comms/sales/support build now hands off here via the enforced `commsAutomationStatus` chain).

### Version
- `skill-version.txt` → `1.4.5`.

## [1.4.4] - 2026-05-29 - THE TRINITY + communications-playbook & workflow-AI standards

Teaches the connection between a GHL workflow, its communications playbook, and its workflow-AI prompt
(THE TRINITY — one implies the other two, never ship one alone), and ships two standardized
reference/protocol docs with must-appear checklists. CORE md files stay lean: AGENTS.md gets only
concise pointers; full content lives in the reference docs. No stripped GHL bodies introduced — the
one embedded body is the full 23-key flat body (messageTemplate placeholder-free, no nesting).

### Added
- `references/communications-playbook-standard.md` — the FULL communications-playbook standard:
  must-appear checklist (slug/id, owner agent id, channel, trigger phrases/intent, goal, step-by-step
  flow, the GHL reply mechanism via the GHL Conversations API per TOOLS.md, cross-playbook transition
  rules, edge cases incl. frustration/refund/legal, on-success/tagging, tone, honesty floor), the
  canonical format skeleton, STORAGE (always under `conversation-workflows/` + register in
  `registry.md`), and the CLIENT-account STORAGE ORDER fallback chain (Notion → Google Docs → plain
  text, always in that order).
- `references/workflow-ai-instructions-standard.md` — the FULL workflow-AI (Build-with-AI) standard:
  WHERE the prompt goes (GHL Automations → "Build with AI" button — no API, no MCP), the must-appear
  checklist, the explicit Custom Webhook field-by-field steps (EVENT=CUSTOM, METHOD=POST via dropdown,
  URL = the REAL hook url not the sample placeholder, AUTHORIZATION dropdown=None, HEADERS via
  "Add item" → Authorization Bearer token + Content-Type, CONTENT-TYPE=application/json, RAW BODY =
  the full 23-key flat body via the Custom Values picker — not shortened to 4 keys), the
  Build-with-AI VERIFICATION CHECKLIST, and MULTI-ACTION teaching (if/else branches, Add-Tag,
  tag-check, multiple sequential actions, create-tag-first via the GHL skill).

### Changed
- `protocols/conversation-workflows-protocol.md` — added the binding "THE TRINITY" section at the top;
  pointed §D.2 at the workflow-AI standard and §E at the communications-playbook standard +
  client-account storage-order fallback chain.
- `scripts/05-update-agents-md.sh` — AGENTS.md Step 1.85 block now carries a concise THE TRINITY
  pointer + pointers to both standard docs; Step 1.8 (BLOCK_B) points the active-playbook reader at
  the communications-playbook standard and the GHL-Conversations-API reply mechanism. Pointers only —
  no playbook bodies in AGENTS.md.
- `templates/sms-workflow-ai-prompt-template.md` — Custom Webhook action rewritten to the precise
  field-by-field format (EVENT=CUSTOM, METHOD dropdown, real URL not sample placeholder, HEADERS via
  "Add item", CONTENT-TYPE, RAW BODY via Custom Values); added a Multi-action note (if/else, Add-Tag,
  tag-check, multiple actions, create-tag-first). Renamed "Workflow AI" usage to "Build with AI" in
  the how-to. Body unchanged (still the 23-key flat body).
- `templates/workflow-verification-checklist-template.md` — prepended the concise BUILD-WITH-AI
  VERIFICATION CHECKLIST (trigger/filter, exact actions, METHOD=POST, real URL, AUTHORIZATION=None,
  headers via Add item, content-type, 23-key flat body, tags, Published) above the detailed
  click-by-click checklist.
- `skill-version.txt` bumped to `1.4.4`.

## [1.4.3] - 2026-05-29 - Enforce 23-key GHL body everywhere

Owner directive (non-negotiable): EVERY GHL Custom Webhook RAW BODY example in Skill 38 must contain
**all 23 keys** — 23 is the MINIMUM, no stripped/short (8/11/13-key) bodies are allowed anywhere in the
repo. Every previously-shorter (13-key) body was REPLACED with the full 23-key canonical body. The body
stays FLAT (no nesting), the body's `messageTemplate` value is kept **placeholder-free** (no `{{…}}`, or
GHL throws "Error while parsing the object to JSON"), and no `\n` appears inside any JSON example. The
23 keys (exact): `id`, `match`, `action`, `agent_id`, `model`, `wakeMode`, `name`, `session_key`,
`messageTemplate`, `deliver`, `timeoutSeconds`, `channel`, `to`, `thinking`, `contact_id`, `first_name`,
`last_name`, `email`, `phone`, `subject`, `message_body`, `location_id`, `location_name`. Per-channel
variants change only `channel` + the `session_key` prefix (sms / fb / instagram / whatsapp / live_chat /
email). The OpenClaw server `hooks.mappings` entry (object B) is unchanged — it keeps its own templated
`messageTemplate`; only the GHL Custom Webhook body (object A) is the 23-key payload.

### Changed
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — replaced the §3.1 Build-with-AI Raw Body and the §14.1
  canonical body with the full 23-key body; added the per-channel variants table (§14.1); stated the
  23-key rule plainly in §5 with the full key list and per-key explanation; updated the §4 verification
  checklist field list to all 23 keys and reframed the messageTemplate item to "placeholder-free" (instead
  of "no messageTemplate"); reconciled §14.2 (body messageTemplate must stay placeholder-free) and added a
  two-objects note after §14.4; updated the header warning, §13 quick-index items 4 & 11, and the §14 intro.
- `references/v5.14-source-playbook.md` — upgraded the localhost smoke-test body, the E2E test body, the
  Part 1 D.2 Build-with-AI body, the D.3 verification-checklist body reference, and all Part 3 channel Raw
  Body blocks to the full 23-key body (added a WhatsApp block; aligned facebook→fb, livechat→live_chat to
  the §7 verified send-type enum); updated the §3C corrected-structure callout to the 23-key standard.
- `scripts/15-configure-hooks-mappings.sh` — the Step 4 E2E test PAYLOAD is now the full 23-key body
  (validated as 23-key JSON); header comment updated to the 23-key rule. Server mapping unchanged.
- `templates/client-reference-sheet-template.md` — all channel Raw Body blocks upgraded to 23 keys (added
  WhatsApp); count references updated.
- `templates/sms-workflow-ai-prompt-template.md` — the SMS Raw Body upgraded to 23 keys; the Workflow-AI
  "common mistakes" list now flags placeholder-in-body-messageTemplate and sub-23-key (stripped) bodies.
- `templates/workflow-verification-checklist-template.md` — Raw Body checklist item now mandates all 23 keys.
- `protocols/conversation-workflows-protocol.md` — the D.2 Build-with-AI body and the verification-checklist
  Raw Body item upgraded to the 23-key standard.
- `skill-version.txt` bumped to `1.4.3`.

## [1.4.2] - 2026-05-29 - Corrected GHL inbound hook structure: FLAT body, no nesting, server-only messageTemplate

GHL inbound-hook correction verified LIVE on a client build (OpenClaw 2026.5.27). The GHL Custom
Webhook RAW BODY is now documented as **FLAT** (no nested `contact:{}` / `customer_message:{}` objects — a
nested body makes EVERY field resolve EMPTY at the hook) and **data-only** (it must NOT contain a
`messageTemplate` — a templated messageTemplate in the body makes GHL throw "Error while parsing the object
to JSON" and Skip the webhook). The `messageTemplate` lives ONLY on the server `hooks.mappings` entry,
references the FLAT body key names, and MUST include the reply-via-GHL-API instruction (or the agent drafts
a reply but never sends it). `deliver:false`; `agentId` is hardcoded per hook path (NOT templatable);
`fallbacks` is not a valid mappings key (`.strict()` schema); `GHL_LOCATION_ID` env is the API credential,
not the body `location_*` fields. `skill-version.txt` bumped to `1.4.2`.

### Changed
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — replaced the nested Build-with-AI Raw Body (§3.1) with the
  canonical FLAT body; rewrote §5 (FLAT body rule, with a labeled ❌ NESTED counter-example); updated the
  §4 verification checklist (FLAT body + no in-body messageTemplate); added a header warning pointing to the
  new section; added **§14 "CORRECTED GHL HOOK STRUCTURE (2026-05-29)"** capturing the full SPEC (cardinal
  rule, flat body, server-only messageTemplate with the GHL-API reply instruction, `deliver:false`, sessionKey
  gating, agentId not templatable / `/hooks/agent`, `fallbacks` invalid, `GHL_LOCATION_ID` is the credential,
  valid `.strict()` mappings keys).
- `references/v5.14-source-playbook.md` — converted the canonical `hooks.mappings` messageTemplate/sessionKey
  to FLAT body keys (added the reply-via-GHL-API instruction; `timeoutSeconds` 180→300), flattened the
  localhost smoke-test body, the E2E test body, the D.2 Build-with-AI prompt body, and all six Part 3 channel
  Raw Body JSONs; added a CORRECTED-structure call-out + updated the "Why these settings" prose.
- `scripts/15-configure-hooks-mappings.sh` — `messageTemplate` now references FLAT body keys and explicitly
  instructs the agent to actually send via the GHL API; `deliver` true→**false**; `timeoutSeconds` 180→300;
  `sessionKey` now pulls the flat `{{session_key}}` body key; the Step 4 E2E test PAYLOAD is now a FLAT body.
- `scripts/21-generate-client-reference-sheet.sh` — added `HOOK_NAME` and `AGENT_ID` to the template
  placeholder substitution (so the flattened templates render with concrete values).
- `templates/sms-workflow-ai-prompt-template.md` — flattened the Raw JSON body; added the FLAT/data-only
  rule, the "nests the body" + "adds messageTemplate to body" failure modes, and `<AGENT_ID>` to placeholders.
- `templates/client-reference-sheet-template.md` — flattened all six channel Raw Body JSONs (Part 3); updated
  the Part 3 intro (FLAT, data-only, Custom Values picker) and the "adding other services" note.
- `protocols/conversation-workflows-protocol.md` — flattened the Build-with-AI prompt Raw JSON body and
  clarified the server-only messageTemplate rule.

## [1.4.1] - 2026-05-28 - Hostinger Docker env-discovery + conversation-playbook builder + CF/GoDaddy Notion-offer

Patch release on top of the 1.4.0 GHL hardening: the Hostinger Docker env-discovery layer, the
conversation-playbook builder hardening, and the CF/GoDaddy prereq-halt Notion-offer (when a client has
no Cloudflare API token, the agent OFFERS a Notion doc in the client's OWN workspace from
`references/cloudflare-godaddy-setup-guide.md` + link, or a manual step-by-step walkthrough — never a
bare `cat` for the operator to read on the box). `skill-version.txt` is bumped to `1.4.1`.

### Added
- `references/HOSTINGER-DOCKER-ENV.md` (NEW) — bulletproof Hostinger Docker VPS env-discovery. Documents where the
  environment lives (host `/docker/<project>/.env` = canonical `env_file`; container mirror `/data/.openclaw/.env`
  via the `volumes: ./data:/data` bind mount; live `docker exec <container> printenv`), the EXACT copy-paste
  discovery sequence (`docker ps` → derive `<project>` → `cat /docker/<project>/.env` → `docker exec … printenv |
  grep API_KEY`), THE HARD RULE (never report a key "missing" before running that sequence — if other keys like
  `ANTHROPIC_API_KEY` are visible you're in the right place; add the missing key there, don't claim you can't find
  it), the canonical add-a-key procedure (append host + mirror container + `docker compose up -d --force-recreate`;
  plain `restart` does NOT reload `env_file`), and the `/hostinger/server.mjs` `hooks.token` rewrite gotcha.

### Changed
- `references/v5.14-source-playbook.md` Step O.5 — added a Hostinger Docker pointer (env is `/docker/<project>/.env`;
  run the discovery sequence + HARD RULE in HOSTINGER-DOCKER-ENV.md before reporting any key missing).
- `scripts/00-verify-prerequisites.sh` "CLOUDFLARE API KEY NOT FOUND" halt — added a prominent Hostinger Docker
  block (the env is `/docker/<project>/.env`, run discovery before reporting missing) and made the
  `cloudflare-godaddy-setup-guide.md` pointer clearly the path for getting a domain into Cloudflare + creating the
  CF API token; the "save your key" step now shows the Hostinger host-`.env` + force-recreate path.
- Step 9.20 (Conversation Workflow Builder) — now explicitly a **3-PART build** every time: Part 1 (Build-with-AI
  prompt + manual-build fallback + verification checklist — nails the funnel SHAPE, operator pastes token/URL/Raw
  values), Part 2 (the Layer 2 conversation playbook in `conversation-workflows/`, registered in `registry.md`; the
  hook path wires the two halves), Part 3 (the brainstorm trigger — FRIENDLY proactive Q&A, NOT 50 questions; uses
  Typed Knowledge Bases + USER.md + MEMORY.md, asks only smart gaps, regurgitates a concise "is this what you want?"
  summary; on YES builds Part 1 → Part 2 → pointer → NEW Notion doc → register). USP framing added
  (communication-driven funnels / automations, beats CloseBot). Cross-references to Step 9.33 (Intelligent Playbook
  Routing) and Step 9.34 (Proactive Features Suite) added at all three steps so builder → router → proactive engine
  are explicitly one loop. Mirrored into `protocols/conversation-workflows-protocol.md` and `scripts/05-update-agents-md.sh`
  (Step 1.85). Removed ambiguous "Workflow AI" usage — renamed to "Build-with-AI" throughout (artifact files
  `<id>--build-with-ai-prompt.md`); fixed the operator-instruction block that still said "Use Workflow AI".
- `scripts/06-append-memory-rules.sh` + `CORE_UPDATES.md` — added MEMORY.md design rules 15-18 (GHL/automation
  terminology = GHL Automations workflow; GHL Automations have NO API/NO MCP, only the "Build with AI" button; the
  3-part build checklist; communication-driven-funnels + brainstorm-not-50-questions). Written under a separate
  `v1.4.0` marker so existing v5.14 installs get rules 15-18 on upgrade without re-appending 6-14 (idempotent +
  upgrade-safe, verified).

## [1.4.0] - 2026-05-28 - GHL inbound hardening: Build-with-AI prompt, 4-token model, verified APIs, calendar-sync

### Why
Debugging a live client (a Hostinger Docker VPS) surfaced a cluster of repeatable failures that
every future VPS client would otherwise hit: the four secrets in this system kept getting confused;
`deliver: true` on GHL API-reply hooks silently broke replies; the `cron.jobs` JSON format stopped
validating on current openclaw; the VPS wrapper resets `hooks.token` on every boot; and there was no
authoritative reference for the one-tunnel-many-hooks model, the Build-with-AI prompt (GHL's only
programmatic automation-build path), the verified channel→type enum, or the verified Calendar API.

### Added
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` (NEW) — the authoritative reference. Contains: the 4-token
  table (CF API token vs tunnel connector token vs HOOKS_TOKEN vs GHL PIT, with VPS specifics); the
  one-tunnel-many-hooks model (created once, reused; new automations = new hook paths, never recreate
  the tunnel); the copy-paste **Build-with-AI prompt** template (the only programmatic way to build a
  GHL automation) with placeholders; the post-build **verification checklist** (incl. the "GHL Test
  button sends empty merge fields → verify with a real inbound" gotcha); the **Reusable Tunnel Values**
  storage rule (AGENTS.md + TOOLS.md + client Notion, every time); the **one-value-per-key** JSON rule;
  the **verified channel→type enum** (SMS/Email/FB/IG/WhatsApp/Live_Chat valid; TikTok/Call/GMB and
  long-forms invalid); the GHL Conversations reply recipe + the verified Calendar recipe (free-slots is
  epoch-millis; book requires calendarId/locationId/contactId/startTime, endTime optional); and the
  ready **first conversation playbook = appointment booking** Layer 2 template.
- `scripts/skill38-calendar-sync.sh` (NEW) — weekly GHL calendar refresh. Maintains a
  `<!-- GHL_CALENDARS_START/END -->` marker block in TOOLS.md (adds new calendars, removes deleted).
  Generic across clients; reads PIT + GHL_LOCATION_ID from the client env file. Registered via
  `openclaw cron add` (Sunday 9am).

### Changed (surgical edits to `references/v5.14-source-playbook.md`)
- **Step 3C / Step 3.5G:** `deliver: true` → `deliver: false` on the GHL inbound hooks mapping, with
  the corrected rationale (deliver:false for any hook that replies via an external API; deliver:true
  only to echo the agent's final text to its own bound channel).
- **Step 3A:** added the 4-token disambiguation (pointer to the new ref doc) and the VPS rule — set
  `OPENCLAW_HOOKS_TOKEN` in host-level `/docker/<project>/.env` (the `/hostinger/server.mjs` wrapper
  rewrites `hooks.token` every boot), then `docker compose up -d --force-recreate`.
- **All cron registrations** (conversation-log-summarizer, system-health-heartbeat, weekly-tune-up,
  proactive-suggestions-scan, monthly-comprehensive-review, plus the new calendar-sync): replaced the
  `cron.jobs` JSON and the old positional `cron add` form with the supported flag-based CLI
  (`openclaw cron add --name … --cron … --agent … --message … --light-context --best-effort-deliver`),
  noting the JSON format no longer validates.
- **Step 6:** the Build-with-AI prompt is now the PRIMARY workflow-build method; the 20-step
  hand-build is demoted to a clearly-labeled FALLBACK. The verification checklist is required even on
  success. Added the Reusable Tunnel Values section + the Notion-doc quality spec (Reusable Tunnel
  Values → Build-with-AI prompt per channel → verification checklist). The base SMS install also
  creates the first appointment-booking playbook and wires the hook path to it (day-one round-trip).
- **Step 9.19:** added the verified GHL Calendar API recipe + the calendar-sync install + Sunday cron.
- **Step 9.20 D.2:** renamed "Workflow AI prompt" → "Build-with-AI prompt" and noted it is the SAME
  generator used for the base onboarding automation in Step 6 (one generator, two call sites).
- **Rules of Engagement:** added Rule 7 — one value per key (proper JSON structure).
- Standardized the outbound cred var to `GHL_PRIVATE_INTEGRATION_TOKEN` and Version `2021-04-15`;
  added WhatsApp to the verified send-type table and the invalid-types list.

### Source of truth
- `references/GHL-INBOUND-AND-PLAYBOOKS.md` — authoritative for GHL inbound + playbooks (this release).
- `references/v5.14-source-playbook.md` — the canonical playbook (surgically updated, pointers added).

## [1.0.0] - 2026-05-28 - Initial release (packages v5.14 playbook)

### Why
The v5.14 conversational AI playbook (~8,800 lines, 14 version iterations) packaged as
an installable skill. Builds the conversational AI BRAIN on top of skill 29 (GHL Convert and Flow).

### Added
- 27 protocol files (humanizer NOT included; skill 19 owns it)
- 8 customer journey templates (coach fully detailed; 7 stubbed)
- 9 idempotent + OS-aware install scripts (00 prerequisites → 08 Shopify wizard)
- 7 reference documents including the FULL v5.14 source playbook + strategic roadmap
- SKILL.md, INSTALL.md, INSTRUCTIONS.md, EXAMPLES.md, CORE_UPDATES.md
- AGENTS.md Steps 1.7, 1.8, 1.9, 2.8; upgraded Step 1.75
- MEMORY.md design rules 6-14
- 4 cron jobs (Sunday 2am tune-up, Saturday 11pm proactive + 11:30pm model freshness, 1st-of-month review)

### Source of truth
- `references/v5.14-source-playbook.md` — the canonical 8,797-line playbook
- `references/conversational-ai-strategic-roadmap.md` — strategic context (✅ shipped vs 📋 pending)

### Out of scope (DEFERRED, not in this skill)
- F14 Voice/Phone Integration
- F15 Proactive Outreach Campaigns
- F16 A/B Testing of Reply Variants
- F17 Customer Segmentation Awareness
- F18 Webhook Chaining
- F21 Multi-Tenant Agent Isolation

The skill's structure (numbered scripts, protocols/ folder, references/) leaves room for
these to be added later without restructuring.
