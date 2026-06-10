# ~~openclaw-onboarding-vps~~ — ARCHIVED

> **ARCHIVED as of 2026-06-10.**
> This repository has been superseded by the unified repo:
>
> **[trevorotts1/openclaw-onboarding](https://github.com/trevorotts1/openclaw-onboarding)**
>
> All VPS / Hostinger Docker support is now in the unified repo under
> `platform/vps/` (overlays) and `platform/vps/bootstrap.sh` (pre-flight).
> Install on a VPS:
>
> ```bash
> # One-liner VPS install (auto-detects platform via /data/.openclaw presence):
> bash <(curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding/main/install.sh)
> ```
>
> This archive is **GitHub-reversible** (no history was deleted).
> The last live version here was **v11.8.0** (commit `5ed9b77947cd78ff94ea4346e8d4415d35738761`).

---

## Why this repo was archived

The Mac onboarding repo (`openclaw-onboarding`) became the single-source repo
for both platforms as part of **PRD 2.1** (unified Mac+VPS repo, 2026-06-10).

Key changes in the unified repo (vs this VPS-only archive):
- `platform/mac/bootstrap.sh` — Mac Homebrew prereqs + canonical path vars
- `platform/vps/bootstrap.sh` — Hostinger Docker container re-exec, disk
  pre-flight, schema validation, VPS canonical paths
- `install.sh` — unified, auto-detects platform (`OPENCLAW_PLATFORM` env var
  or `/data/.openclaw` presence), sources the right bootstrap before
  `set -euo pipefail`
- `lib-shared.sh` v1.0.1 — fixes stale `WORKSPACE=/data/clawd` path bug
  (now `/data/.openclaw/workspace` on VPS, `~/.openclaw/workspace` on Mac)
- All VPS-only files from this repo merged as union into the unified repo
  (`shared-utils/key_resolver.py`, `scripts/fix-dual-cli.sh`, VPS protocol
  docs for skills 22/23/32/35/38/39/43, `platform/vps/` overlay docs)
- All Phase-1/2 quality fixes (BUG1/BUG3/Gemini-GA/SSOT) are
  **byte-identical** in the unified repo

## Historical record

This repo contains the complete VPS onboarding history through v11.8.0.
The last annotated tag on this repo is **v11.8.0** (`5ed9b77`).

For release history going forward, see
[openclaw-onboarding/CHANGELOG.md](https://github.com/trevorotts1/openclaw-onboarding/blob/main/CHANGELOG.md).

---

*This archive README was written by the cutover automation on 2026-06-10.*
*To un-archive: GitHub repo Settings → Danger Zone → Unarchive repository.*
