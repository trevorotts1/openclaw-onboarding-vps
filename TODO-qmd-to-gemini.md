# TODO: QMD to Gemini Embedding 2 Migration
**VPS Repo:** `trevorotts1/openclaw-onboarding-vps`  
**Status:** Ready for implementation  
**Last updated:** March 17, 2026 at 10:45 PM

---

## Phase 0: Pre-Implementation Setup

- [ ] **0.1** Verify `GOOGLE_AI_STUDIO_API_KEY` is in environment
- [ ] **0.2** Test Gemini Embedding 2 API connectivity
  ```bash
  curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-2-preview:embedContent?key=$GOOGLE_AI_STUDIO_API_KEY" \
    -H 'Content-Type: application/json' \
    -X POST \
    -d '{"content": {"parts": [{"text": "test"}]}}'
  ```
- [ ] **0.3** Verify `gai-search` CLI availability (or plan Python SDK route)
- [ ] **0.4** Create backup branch: `git checkout -b migration/qmd-to-gemini`

---

## Phase 1: Persona Blueprints (Easiest Wins - 40 files)

**Pattern:** All 40 files have identical 4-line header
**Time estimate:** 15 minutes with sed
**Risk:** Low

- [ ] **1.1** Update all 40 persona-blueprint.md files
  ```bash
  cd /tmp/openclaw-onboarding-vps/22-book-to-persona-coaching-leadership-system/personas/
  for file in */persona-blueprint.md; do
    sed -i '' \
      -e 's/\*\*QMD Index:\*\*/\*\*Gemini Index:\*\*/g' \
      -e 's|\.\/qmd-index\/|./gemini-index/|g' \
      "$file"
  done
  ```

**Files to verify (spot-check 5):**
- [ ] clear-atomic-habits/persona-blueprint.md
- [ ] sinek-start-with-why/persona-blueprint.md
- [ ] sharma-5am-club/persona-blueprint.md
- [ ] pink-drive/persona-blueprint.md
- [ ] covey-7-habits/persona-blueprint.md

---

## Phase 2: Core Skill 22 - Book to Persona (High Priority)

**Location:** `22-book-to-persona-coaching-leadership-system/`  
**Files:** 7 core files  
**Time estimate:** 2-3 hours  
**Risk:** Medium

### 2.1 Rename Primary Documentation File
- [ ] **2.1.1** Rename `QMD-RETRIEVAL-GUIDE.md` → `GAI-SEARCH-GUIDE.md`
  ```bash
  mv QMD-RETRIEVAL-GUIDE.md GAI-SEARCH-GUIDE.md
  ```
- [ ] **2.1.2** Update file content (46 QMD references inside)
  - Replace "QMD" → "Gemini" or "gai-search" contextually
  - Keep code examples valid

### 2.2 Update SKILL.md
- [ ] **2.2.1** Line 21: Update TYP reading list reference
  - Change: `6. QMD-RETRIEVAL-GUIDE.md` → `6. GAI-SEARCH-GUIDE.md`
- [ ] **2.2.2** Line 76: Update TYP step reference
  - Change: `Read QMD-RETRIEVAL-GUIDE.md` → `Read GAI-SEARCH-GUIDE.md`
- [ ] **2.2.3** Line 141: Update documentation link
  - Change: `QMD-RETRIEVAL-GUIDE.md` → `GAI-SEARCH-GUIDE.md`
- [ ] **2.2.4** Step 3 (QMD setup): Rewrite entirely for Gemini
  - Remove `qmd update && qmd embed`
  - Add `gai-search index add` or direct API equivalent
- [ ] **2.2.5** All remaining "QMD" mentions: Update to "Gemini"

### 2.3 Update INSTALL.md
- [ ] **2.3.1** Line 99: Update file listing
  - Change: `6. QMD-RETRIEVAL-GUIDE.md` → `6. GAI-SEARCH-GUIDE.md`
- [ ] **2.3.2** Line 126: Update expected output list
  - Change: `QMD-RETRIEVAL-GUIDE.md` → `GAI-SEARCH-GUIDE.md`
- [ ] **2.3.3** QMD installation section: Replace with Gemini setup

### 2.4 Update QC.md
- [ ] **2.4.1** 32 QMD references: Update all to Gemini equivalents
- [ ] **2.4.2** Validation commands: Replace `qmd status` with Gemini checks

### 2.5 Update CORE_UPDATES.md
- [ ] **2.5.1** Line 64: Update guide location reference
  - Change path from `QMD-RETRIEVAL-GUIDE.md` to `GAI-SEARCH-GUIDE.md`
- [ ] **2.5.2** Memory slot references: Update from QMD to Gemini

### 2.6 Update _meta.json
- [ ] **2.6.1** Line 4: Update description
  - Change: `"QMD-indexed for retrieval"` → `"Gemini-indexed for retrieval"`
- [ ] **2.6.2** Line 8: Update binary dependencies
  - Change: `"bins": ["qmd", "python3"]` → `"bins": ["gai-search", "python3"]`
- [ ] **2.6.3** Line 17: Update tags
  - Change: `"qmd"` → `"gai-search"`

### 2.7 Update pipeline/orchestrator.py
- [ ] **2.7.1** Line 829: Update generated header field
  - Change: `**QMD Index:**` → `**Gemini Index:**`
- [ ] **2.7.2** Line 830: Update index location
  - Change: `./qmd-index/` → `./gemini-index/`

---

## Phase 3: Skill 23 - AI Workforce (Critical - Python Code)

**Location:** `23-ai-workforce-blueprint/`  
**Files:** SKILL.md, INSTALL.md, build-workforce.py  
**Time estimate:** 4-6 hours  
**Risk:** High (Python subprocess calls)

### 3.1 Update scripts/build-workforce.py (CRITICAL FILE)

**Current code locations:**
- Line ~640: `subprocess.run(["qmd", "update"])`
- Line ~765-768: `subprocess.run(["qmd", "embed"])`
- Line ~976: QMD status check
- Line ~1113-1146: Multiple QMD calls
- Line ~1250-1251: QMD subprocess
- Line ~1427-1428: QMD commands
- Line ~1454: QMD reference
- Line ~1487-1488: QMD subprocess

**Replacement strategy:**
- [ ] **3.1.1** Import Google GenAI SDK at top of file
  ```python
  from google import genai
  from google.genai import types
  import os
  ```
- [ ] **3.1.2** Create helper function for Gemini embedding
  ```python
  def embed_documents(file_paths, corpus_name="coaching-personas"):
      """Embed documents using Gemini Embedding 2"""
      client = genai.Client(api_key=os.environ.get("GOOGLE_AI_STUDIO_API_KEY"))
      
      results = []
      for file_path in file_paths:
          with open(file_path, 'r') as f:
              content = f.read()
          
          response = client.models.embed_content(
              model="models/gemini-embedding-2-preview",
              contents=[types.Content(parts=[types.Part(text=content)])]
          )
          results.append({
              'file': file_path,
              'embedding': response.embeddings[0].values
          })
      return results
  ```
- [ ] **3.1.3** Replace `subprocess.run(["qmd", "update"])` calls
- [ ] **3.1.4** Replace `subprocess.run(["qmd", "embed"])` calls
- [ ] **3.1.5** Replace QMD status checks with Gemini API validation
- [ ] **3.1.6** Update error messages to reference Gemini instead of QMD
- [ ] **3.1.7** Test the script to ensure it runs without errors

### 3.2 Update SKILL.md
- [ ] **3.2.1** All QMD references → Gemini
- [ ] **3.2.2** QMD-RETRIEVAL-GUIDE.md → GAI-SEARCH-GUIDE.md
- [ ] **3.2.3** Python subprocess examples → Gemini SDK examples

### 3.3 Update INSTALL.md
- [ ] **3.3.1** Dependencies section: Remove qmd, add google-genai
- [ ] **3.3.2** Installation steps: Replace QMD setup with Gemini setup
- [ ] **3.3.3** Verification section: Update QMD checks → Gemini checks

### 3.4 Update master-orchestrator-dept/03-Activity-Log-Template.md
- [ ] **3.4.1** QMD references → Gemini

---

## Phase 4: Skill 29 - GHL Convert and Flow

**Location:** `29-ghl-convert-and-flow/`  
**Files:** SKILL.md, INSTRUCTIONS.md  
**Time estimate:** 30 minutes  
**Risk:** Low

- [ ] **4.1** SKILL.md: Update 2 QMD references
- [ ] **4.2** INSTRUCTIONS.md: Update QMD → Gemini

---

## Phase 5: Skill 30 - Fish Audio API Reference

**Location:** `30-fish-audio-api-reference/`  
**Files:** SKILL.md, QC.md, INSTALL.md, README.md  
**Time estimate:** 1 hour  
**Risk:** Low

- [ ] **5.1** SKILL.md: Update QMD validation steps
- [ ] **5.2** QC.md: Update 19 QMD references
- [ ] **5.3** INSTALL.md: Update QMD → Gemini
- [ ] **5.4** README.md: Update QMD → Gemini

---

## Phase 6: Top-Level Files

**Location:** Repo root  
**Files:** Start Here.md, AGENTS.md, CHANGELOG.md, README.md  
**Time estimate:** 2-3 hours  
**Risk:** High (Start Here.md is user-facing)

### 6.1 Update Start Here.md (67 references - CRITICAL FILE)

**Major section: Step 3 (QMD setup)**
- [ ] **6.1.1** Rewrite Step 3 entirely
  - Remove: `qmd update && qmd embed`
  - Add: Gemini API key setup and `gai-search` or direct API
- [ ] **6.1.2** All inline QMD commands → Gemini equivalents
- [ ] **6.1.3** QMD-RETRIEVAL-GUIDE.md → GAI-SEARCH-GUIDE.md
- [ ] **6.1.4** Maintain warm, clear tone (Trevor's standard)
- [ ] **6.1.5** Add clear numbering for 60+ users

### 6.2 Update AGENTS.md
- [ ] **6.2.1** 20 QMD references → Gemini
- [ ] **6.2.2** Memory slot documentation: Update QMD → Gemini

### 6.3 Update CHANGELOG.md
- [ ] **6.3.1** Add migration entry for v4.0.0 (or next version)
  ```markdown
  ## [4.0.0] - 2026-03-XX
  ### Changed
  - Migrated from QMD (local SQLite) to Gemini Embedding 2 (Google API)
  - Replaced all `qmd` CLI commands with `gai-search` or direct API
  - Updated 40 persona blueprints with new index references
  ```

### 6.4 Update README.md
- [ ] **6.4.1** Feature list: Update QMD → Gemini
- [ ] **6.4.2** Architecture diagram: Update Layer 2 from QMD to Gemini

---

## Phase 7: Testing & Validation

- [ ] **7.1** Run install.sh on clean environment
- [ ] **7.2** Verify all 30 skills install without QMD errors
- [ ] **7.3** Test Skill 22 pipeline end-to-end
- [ ] **7.4** Test Skill 23 build-workforce.py
- [ ] **7.5** Verify persona blueprints generate correctly
- [ ] **7.6** Verify GAI-SEARCH-GUIDE.md is readable

---

## Phase 8: Documentation & Migration Guide

- [ ] **8.1** Create MIGRATION.md
  - For existing users (Corey, Trevor)
  - Explain how to transition existing QMD indexes
  - Provide rollback instructions
- [ ] **8.2** Update CHANGELOG.md with migration notes
- [ ] **8.3** Commit all changes
  ```bash
  git add -A
  git commit -m "feat: migrate from QMD to Gemini Embedding 2

  - Replace local SQLite QMD with Google Gemini Embedding 2 API
  - Update 40 persona blueprints with new index headers
  - Rename QMD-RETRIEVAL-GUIDE.md → GAI-SEARCH-GUIDE.md
  - Rewrite build-workforce.py to use Gemini SDK
  - Update all documentation and install scripts
  - Add MIGRATION.md for existing users

  BREAKING CHANGE: Requires GOOGLE_AI_STUDIO_API_KEY
  Closes: #migration-qmd-to-gemini"
  ```
- [ ] **8.4** Push to GitHub
  ```bash
  git push origin migration/qmd-to-gemini
  ```
- [ ] **8.5** Create PR for review

---

## Summary Checklist

| Phase | Files | Time Est. | Risk |
|-------|-------|-----------|------|
| 0 | Setup | 15 min | Low |
| 1 | 40 persona blueprints | 15 min | Low |
| 2 | 7 core Skill 22 files | 2-3 hrs | Medium |
| 3 | 4 Skill 23 files | 4-6 hrs | High |
| 4 | 2 Skill 29 files | 30 min | Low |
| 5 | 4 Skill 30 files | 1 hr | Low |
| 6 | 4 top-level files | 2-3 hrs | High |
| 7 | Testing | 2 hrs | Medium |
| 8 | Documentation | 1 hr | Low |

**Total estimated time:** 15-20 hours  
**Critical path:** Phase 3 (build-workforce.py)  
**Biggest risk:** Python subprocess calls in build-workforce.py

---

## Notes

- **Dependency:** `google-genai` Python package must be installed
- **Environment:** `GOOGLE_AI_STUDIO_API_KEY` must be set
- **Testing:** Validate on clean VPS before declaring done
- **Rollback:** Keep backup branch until fully validated
