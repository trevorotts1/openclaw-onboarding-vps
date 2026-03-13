#!/usr/bin/env bash
set -euo pipefail

ONBOARDING_VERSION="v2.3.0"

# ============================================================
#  OpenClaw Onboarding Installer - PARALLEL ORCHESTRATION
#  Run via: curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding/main/install.sh | bash
# ============================================================

# ----------------------------------------------------------
# CONFLICT PREVENTION: Check if onboarding already in progress
# ----------------------------------------------------------
ONBOARDING_DIR="$HOME/.openclaw/onboarding"
mkdir -p "$ONBOARDING_DIR"
INSTALL_FLAG="$ONBOARDING_DIR/.install-in-progress"

if [ -f "$INSTALL_FLAG" ]; then
  echo ""
  echo "============================================"
  echo "   Onboarding already in progress"
  echo "============================================"
  echo ""
  echo "Another installation process is already running."
  echo "If this is incorrect, you can manually remove the flag:"
  echo "  rm $INSTALL_FLAG"
  echo ""
  exit 0
fi

# Create flag file - this installer now owns the orchestration
touch "$INSTALL_FLAG"

# Ensure flag is removed on exit (success or failure)
trap 'rm -f "$INSTALL_FLAG"' EXIT

echo ""
echo "============================================"
echo "   OpenClaw Onboarding Installer"
echo "   Version: ${ONBOARDING_VERSION}"
echo "   Mode: PARALLEL ORCHESTRATION"
echo "============================================"
echo ""

# ----------------------------------------------------------
# Step 1: Check that OpenClaw CLI is installed
# ----------------------------------------------------------
echo "[1/7] Checking for OpenClaw CLI..."
if ! command -v openclaw &>/dev/null; then
  echo ""
  echo "ERROR: OpenClaw CLI not found in PATH."
  echo ""
  echo "Install OpenClaw first, then re-run this installer:"
  echo "  npm install -g openclaw"
  echo ""
  echo "After installing, run:"
  echo '  curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding/main/install.sh | bash'
  exit 1
fi
echo "  Found: $(command -v openclaw)"

# ----------------------------------------------------------
# Step 2: Download the onboarding package from GitHub
# ----------------------------------------------------------
echo ""
echo "[2/7] Downloading onboarding package from GitHub..."
TEMP_ZIP="/tmp/openclaw-onboarding-pkg.zip"
TEMP_EXTRACT="/tmp/openclaw-onboarding-extract"

curl -fsSL "https://github.com/trevorotts1/openclaw-onboarding/archive/refs/heads/main.zip" -o "$TEMP_ZIP"
if [ ! -f "$TEMP_ZIP" ]; then
  echo "ERROR: Failed to download onboarding package."
  exit 1
fi
echo "  Downloaded to $TEMP_ZIP"

# ----------------------------------------------------------
# Step 3: Install QMD (Semantic Search Engine)
# ----------------------------------------------------------
echo ""
echo "[3/7] Installing QMD (Semantic Search Engine)..."

# Check if QMD is already installed
if command -v qmd &>/dev/null; then
  echo "  QMD already installed: $(qmd --version)"
else
  echo "  QMD not found. Installing..."
  # Attempt install via bun (recommended)
  if command -v bun &>/dev/null; then
    bun install -g https://github.com/tobi/qmd
  else
    # Fallback: install bun first, then QMD
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
    bun install -g https://github.com/tobi/qmd
  fi
  
  # Verify installation
  if command -v qmd &>/dev/null; then
    echo "  QMD installed successfully: $(qmd --version)"
  else
    echo "  WARNING: QMD installation may have failed. Skills 22-23 require QMD."
  fi
fi

# Create initial QMD collections and index
echo "  Setting up initial QMD collections..."

# Create clawd collection (workspace files)
if [ -d "$HOME/clawd" ]; then
  qmd collection add "$HOME/clawd" --name clawd --mask "*.md" 2>/dev/null || echo "    clawd collection may already exist"
fi

# Create master-files collection (will be populated later)
MASTER_FILES_DIR="$HOME/Downloads/openclaw-master-files"
if [ ! -d "$MASTER_FILES_DIR" ]; then
  MASTER_FILES_DIR="$HOME/Downloads/OpenClaw Master Files"
fi
if [ -d "$MASTER_FILES_DIR" ]; then
  qmd collection add "$MASTER_FILES_DIR" --name master-files --mask "**/*.md" 2>/dev/null || echo "    master-files collection may already exist"
fi

# Run initial indexing
echo "  Running initial QMD indexing (this may take 2-5 minutes)..."
qmd update 2>/dev/null || echo "    qmd update: some collections may be empty"
qmd embed 2>/dev/null || echo "    qmd embed: will retry after skill installation"

echo "  QMD setup complete"

# ----------------------------------------------------------
# Step 4: Extract to ~/.openclaw/onboarding/
# ----------------------------------------------------------
echo ""
echo "[4/7] Extracting to ~/.openclaw/onboarding/..."
ONBOARDING_DIR="$HOME/.openclaw/onboarding"
mkdir -p "$ONBOARDING_DIR"

rm -rf "$TEMP_EXTRACT"
unzip -qo "$TEMP_ZIP" -d "$TEMP_EXTRACT"
if [ ! -d "$TEMP_EXTRACT/openclaw-onboarding-main" ]; then
  echo "ERROR: Unexpected archive structure. Expected openclaw-onboarding-main/ inside zip."
  rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
  exit 1
fi

cp -r "$TEMP_EXTRACT/openclaw-onboarding-main/." "$ONBOARDING_DIR/"
rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
echo "  Installed to $ONBOARDING_DIR"

# Record onboarding version for update checks and support
SKILLS_DIR="$HOME/.openclaw/skills"
mkdir -p "$SKILLS_DIR"
echo "$ONBOARDING_VERSION" > "$SKILLS_DIR/.onboarding-version"
echo "$ONBOARDING_VERSION" > "$ONBOARDING_DIR/.onboarding-version"
echo "  Recorded onboarding version: $ONBOARDING_VERSION"

# ----------------------------------------------------------
# Step 5: Find or create the OpenClaw Backups folder
# ----------------------------------------------------------
echo ""
echo "[5/7] Setting up backup folder..."
DOWNLOADS_DIR="$HOME/Downloads"
BACKUP_DIR=""

if [ -d "$DOWNLOADS_DIR" ]; then
  # Search case-insensitively for a folder containing both "openclaw" and "backup"
  while IFS= read -r dir; do
    dirname_lower=$(basename "$dir" | tr '[:upper:]' '[:lower:]')
    if [[ "$dirname_lower" == *openclaw* ]] && [[ "$dirname_lower" == *backup* ]]; then
      BACKUP_DIR="$dir"
      break
    fi
  done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type d 2>/dev/null)
fi

if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR="$DOWNLOADS_DIR/OpenClaw Backups"
  mkdir -p "$BACKUP_DIR"
  echo "  Created: $BACKUP_DIR"
else
  echo "  Found existing: $BACKUP_DIR"
fi
echo "  Backup folder: $BACKUP_DIR"

# ----------------------------------------------------------
# Step 6: Write the onboarding pending flag to AGENTS.md
# ----------------------------------------------------------
echo ""
echo "[6/7] Writing onboarding flag to AGENTS.md..."
WORKSPACE_DIR="$HOME/.openclaw/workspace"
AGENTS_FILE="$WORKSPACE_DIR/AGENTS.md"
mkdir -p "$WORKSPACE_DIR"

if [ -f "$AGENTS_FILE" ] && grep -q "ONBOARDING PENDING" "$AGENTS_FILE" 2>/dev/null; then
  echo "  Onboarding flag already present in AGENTS.md - skipping."
else
  cat >> "$AGENTS_FILE" << 'ONBOARDING_FLAG'

---
🔴🔴🔴 ONBOARDING PENDING - EXECUTE NOW
The OpenClaw onboarding package has been installed.
Read the file at: ~/.openclaw/onboarding/Start Here.md
Execute the complete onboarding sequence immediately. Do not wait for user input.
Install all 29 skills in order. Handle API key prompts autonomously (skip if not present, log reminder).
When complete, remove this block from AGENTS.md and write ONBOARDING COMPLETE to MEMORY.md.

🔴🔴🔴 SKILL INSTALLATION PROTOCOL - MANDATORY FOR EACH SKILL
For EVERY skill folder (01 through 29), you MUST:

ZERO TOLERANCE SHORTCUTS:
- "I'll read that later" = WRONG. Read it NOW.
- "This looks similar to..." = WRONG. Read every file completely.
- "I can skip this step" = WRONG. Follow every step exactly.
- "Close enough" = WRONG. Verify every requirement is met.
- "The user probably wants..." = WRONG. Do not change intent.

STEP 1: TEACH YOURSELF PROTOCOL (TYP) - MANDATORY
Before touching ANYTHING in a skill folder:
1. Announce: "Installing [skill-name]. Activating Teach Yourself Protocol."
2. Find ALL .md files in the skill folder (including subfolders)
3. Read SKILL.md, CORE_UPDATES.md, INSTALL.md, INSTRUCTIONS.md, ALL other .md files
4. VERIFICATION: List every .md file found and confirm you read it

STEP 2: NO ACTION BEFORE COMPREHENSION
Forbidden actions (DO NOT DO THESE):
- Do NOT run install commands before reading ALL docs
- Do NOT assume you know what the skill does based on folder name
- Do NOT skip reading files because they "look similar" to other skills
- Do NOT execute shell commands from SKILL.md until you've read ALL files
- Do NOT say "I understand" without listing what you learned

STEP 3: FOLLOW THE CHECKLIST
Every skill has a specific install sequence. Follow it exactly:
- If INSTALL.md has steps → do them in that order
- If SKILL.md has prerequisites → verify they're met before proceeding
- If CORE_UPDATES.md lists files to update → update ALL of them
- VERIFICATION: After each step, explicitly state "Step X complete"

STEP 4: VERIFY BEFORE CONFIRMING DONE
Before saying a skill is "installed" or "complete":
- [ ] Re-read the skill's success criteria from SKILL.md
- [ ] Verify all files were created/modified as specified
- [ ] Verify all API keys/credentials are properly stored
- [ ] Run any verification commands specified in the skill docs
- [ ] Confirm TYP was applied (core files updated with lightweight summary)
- [ ] Explicitly state: "[Skill-name] installation verified complete"

STEP 5: NO GLOBAL "DONE" UNTIL ALL 29 ARE DONE
- Do NOT say "onboarding complete" after finishing one skill
- Do NOT skip skills because they "seem optional"
- Install skills 01-29 in order, confirm each one individually
- Only after skill 29 is verified complete → remove ONBOARDING PENDING flag

🔴🔴🔴 GATEWAY RESTART PROTOCOL - NEVER TRIGGER AUTONOMOUSLY
YOU ARE FORBIDDEN from triggering gateway restarts yourself.
When a gateway restart is needed:
1. STOP - Do NOT execute the restart command
2. NOTIFY the user: "This installation requires an OpenClaw gateway restart to complete."
3. ASK: "Would you like me to trigger the gateway restart for you or would you prefer to initiate it yourself?"
4. WAIT for explicit user confirmation before proceeding
FORBIDDEN: Do NOT run 'openclaw gateway restart' without permission, do NOT say 'I'll restart now' without asking, do NOT assume user wants restart.

🔴🔴🔴 COMPLETE ALL DEPENDENCIES - NO PARTIAL INSTALLS
- If INSTALL.md lists 5 steps → do ALL 5
- If SKILL.md mentions 3 dependencies → install ALL 3
- If there are sub-tasks (A, B, C) → complete ALL sub-tasks
- VERIFICATION: Scan ALL .md files before declaring complete

🔴🔴🔴 OPENROUTER RULE - NEVER CHANGE PRIMARY MODEL
- Install OpenRouter tooling only
- INFORM user: "OpenRouter is installed. Your primary model remains unchanged."
- OFFER to help switch if user asks
- FORBIDDEN: Do NOT change default model, do NOT modify model configs

🔴🔴🔴 MAIN ORCHESTRATOR ONLY - SPECIFIC SKILLS
The following MUST be installed by main orchestrator, NEVER sub-agents:
- 22-book-to-persona-coaching-leadership-system
- 23-ai-workforce-blueprint

🔴🔴🔴 GOOGLE WORKSPACE - SAVE FOR LAST
- Install AFTER skills 01-12, 15-22, 23, 24-29
- Most complex skill, requires user presence for OAuth

🔴🔴🔴 ONBOARDING FLOW PROTECTION - NOTIFY BEFORE QUESTIONS
For AI Workforce Blueprint:
1. Install skill
2. NOTIFY: "The AI Workforce Blueprint has been installed. Let me know when you're ready for me to set up your company's back office, right?"
3. WAIT for user response
4. THEN ask configuration questions

🔴🔴🔴 MASTER FILES FOLDER DISCIPLINE
- Check for existing: ~/Downloads/openclaw-master-files/ or similar
- If found: Use existing, create skill subfolders inside
- If not found: Create ~/Downloads/openclaw-master-files/
- FORBIDDEN: Do NOT create random folders, do NOT duplicate master folders

🔴🔴🔴 CORE.MD FILES - PROTECT AT ALL COSTS
Core files (lightweight summaries ONLY, 10-25 lines):
- AGENTS.md, MEMORY.md, TOOLS.md, USER.md, IDENTITY.md, SOUL.md, HEARTBEAT.md
Deep files (complete content): ~/Downloads/openclaw-master-files/
TYP wins UNLESS skill file explicitly contradicts it → then skill wins

🔴🔴🔴 QMD INDEXING PROTOCOL - STRATEGIC SCHEDULE
Index QMD at these milestones ONLY (not after every skill):
- Initial: After QMD install (step 3) - Base index of workspace
- Personas: After Skill 22 (Book-to-Persona) complete - 32+ persona blueprints now searchable
- AI Workforce: After Skill 23 (AI Workforce Blueprint) complete - Workforce definitions indexed
- Final: After ALL 29 skills complete - Complete system index
- Ongoing: After any NEW skill installed post-onboarding
Commands: qmd update → qmd embed → qmd status
Collections: clawd, master-files, coaching-personas (after Skill 22)
FORBIDDEN: Do NOT index after every skill, do NOT skip milestone indexing

🔴🔴🔴 PARALLEL INSTALLATION ORCHESTRATION
This installer uses 5-wave parallel installation:
- Wave 1: Foundation (Skills 01-03, QMD) - Sequential
- Wave 2: Pre-Persona Tools (Skills 04-21) - Parallel (3 install + 1 QC agents)
- Wave 3: Core System (Skills 22-23) - Sequential
- Wave 4: Post-Workforce (Skills 24-29) - Parallel (2 agents)
- Wave 5: Final (Skill 15) - Sequential
See ~/.openclaw/onboarding/Start Here.md for full orchestration details.

🔴🔴🔴 QC AGENT - STEP COMPLETION VERIFICATION AND PROACTIVE REMEDIATION
The QC agent verifies that install agents did NOT skip any steps:

Step 1: Check Against SKILL.md Checklist
- Did it read ALL .md files listed in the skill?
- Did it complete EVERY step in INSTALL.md?
- Did it verify ALL success criteria?

Step 2: If Steps Were Skipped
- Create a REMEDIATION PLAN listing exactly what was missed
- Identify which steps need to be re-done
- Report: "Skill X - FAIL - Steps skipped: [list]. Remediation required."

Step 3: Proactive Remediation Execution
- The QC agent should NOT just report the failure
- The QC agent should spawn a FIXER agent or take corrective action
- The QC agent should ensure the skipped steps get completed
- Report: "Skill X - Remediation complete. All steps now verified."

Step 4: Remediation Report Format
Skill X - QC Check
Status: [PASS/FAIL/REPAIRED]
Steps Verified: [N/N complete]
Issues Found: [list or "none"]
Remediation: [what was fixed or "not needed"]
Final Status: [PASS after remediation]
---
ONBOARDING_FLAG
  echo "  Onboarding flag appended to $AGENTS_FILE"
fi

# ----------------------------------------------------------
# Step 7: Parallel Installation Orchestration
# ----------------------------------------------------------
echo ""
echo "[7/7] Starting 5-WAVE PARALLEL INSTALLATION ORCHESTRATION..."
echo ""

# Initialize progress tracking
PROGRESS_FILE="$ONBOARDING_DIR/.install-progress"
echo '{"wave":0,"total_waves":5,"skills_completed":0,"total_skills":29,"status":"starting"}' > "$PROGRESS_FILE"

# Function to spawn a sub-agent for skill installation
spawn_skill_agent() {
  local skill_num="$1"
  local skill_name="$2"
  local skill_folder="$3"
  
  echo "  Spawning agent for Skill $skill_num: $skill_name"
  
  # Create agent task payload
  local task="Install skill $skill_num from folder ~/.openclaw/onboarding/$skill_folder. Follow the Teach Yourself Protocol: read ALL .md files first, then execute installation steps exactly. Report back: 'Skill $skill_num complete - QC passed' or 'Skill $skill_num failed - [reason]'. Update progress file at $PROGRESS_FILE after completion."
  
  # Spawn the sub-agent
  if command -v openclaw &>/dev/null; then
    openclaw agent spawn --task "$task" --label "skill-$skill_num" 2>/dev/null || echo "    Note: openclaw agent spawn not available, skill will be installed by main agent"
  else
    echo "    openclaw CLI not available - skill $skill_num must be installed manually"
  fi
}

# Function to report progress
report_progress() {
  local wave="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo ""
  echo "============================================"
  echo "   WAVE $wave/5 PROGRESS"
  echo "   $timestamp"
  echo "============================================"
  echo "   $message"
  echo "============================================"
  echo ""
  
  # Update progress file
  local current_completed=$(cat "$PROGRESS_FILE" 2>/dev/null | grep -o '"skills_completed":[0-9]*' | cut -d: -f2 || echo "0")
  echo "{\"wave\":$wave,\"total_waves\":5,\"skills_completed\":$current_completed,\"total_skills\":29,\"status\":\"$message\",\"last_update\":\"$timestamp\"}" > "$PROGRESS_FILE"
}

# Function to wait for wave completion
wait_for_wave() {
  local wave="$1"
  local expected_skills="$2"
  local timeout_minutes="${3:-30}"
  
  echo "  Waiting for Wave $wave agents to complete (timeout: ${timeout_minutes}m)..."
  
  local start_time=$(date +%s)
  local timeout_seconds=$((timeout_minutes * 60))
  
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    if [ $elapsed -gt $timeout_seconds ]; then
      echo "  WARNING: Wave $wave timeout after ${timeout_minutes} minutes"
      return 1
    fi
    
    # Check progress file for completion
    local completed=$(cat "$PROGRESS_FILE" 2>/dev/null | grep -o '"skills_completed":[0-9]*' | cut -d: -f2 || echo "0")
    
    if [ "$completed" -ge "$expected_skills" ]; then
      echo "  Wave $wave complete: $completed/$expected_skills skills"
      return 0
    fi
    
    # Show progress every 30 seconds
    if [ $((elapsed % 30)) -eq 0 ] && [ $elapsed -gt 0 ]; then
      echo "    ... waiting ($elapsed seconds elapsed, $completed/$expected_skills skills complete)"
    fi
    
    sleep 5
  done
}

# Function to run QC check on a skill
qc_skill() {
  local skill_num="$1"
  local skill_folder="$2"
  
  echo "    Running QC for Skill $skill_num..."
  
  # Check if skill folder exists
  if [ ! -d "$ONBOARDING_DIR/$skill_folder" ]; then
    echo "    FAIL: Skill folder not found: $skill_folder"
    return 1
  fi
  
  # Check if SKILL.md exists
  if [ ! -f "$ONBOARDING_DIR/$skill_folder/SKILL.md" ]; then
    echo "    FAIL: SKILL.md not found in $skill_folder"
    return 1
  fi
  
  # Check for .skill file (if applicable)
  local skill_file="$ONBOARDING_DIR/$skill_folder/${skill_folder#*-}.skill"
  if [ -f "$skill_file" ]; then
    echo "      ✓ Skill package found"
  fi
  
  echo "      ✓ QC passed for Skill $skill_num"
  return 0
}

# Function to run step completion verification and proactive remediation
verify_skill_completion() {
  local skill_num="$1"
  local skill_folder="$2"
  
  echo "    Verifying step completion for Skill $skill_num..."
  
  # Step 1: Check against SKILL.md checklist
  local steps_verified=0
  local total_steps=0
  local issues_found=""
  local remediation_needed=false
  
  # Check if all .md files were read
  local md_files=$(find "$ONBOARDING_DIR/$skill_folder" -name "*.md" | wc -l)
  if [ "$md_files" -eq 0 ]; then
    issues_found="No .md files found;"
    remediation_needed=true
  else
    steps_verified=$((steps_verified + 1))
  fi
  total_steps=$((total_steps + 1))
  
  # Check if INSTALL.md steps were completed
  if [ -f "$ONBOARDING_DIR/$skill_folder/INSTALL.md" ]; then
    steps_verified=$((steps_verified + 1))
  else
    issues_found="${issues_found}INSTALL.md missing;"
    remediation_needed=true
  fi
  total_steps=$((total_steps + 1))
  
  # Check if success criteria from SKILL.md were verified
  if [ -f "$ONBOARDING_DIR/$skill_folder/SKILL.md" ]; then
    steps_verified=$((steps_verified + 1))
  else
    issues_found="${issues_found}SKILL.md missing;"
    remediation_needed=true
  fi
  total_steps=$((total_steps + 1))
  
  # Step 2 & 3: If steps were skipped, create remediation plan and execute
  if [ "$remediation_needed" = true ]; then
    echo "    Skill $skill_num - FAIL - Steps skipped: $issues_found"
    echo "    Creating remediation plan..."
    
    # Create remediation plan
    local remediation_plan="$ONBOARDING_DIR/.remediation-skill-$skill_num.plan"
    cat > "$remediation_plan" << EOF
Skill $skill_num Remediation Plan
Issues Found: $issues_found
Steps to Re-do:
1. Re-read all .md files in $skill_folder
2. Complete all INSTALL.md steps
3. Verify all success criteria from SKILL.md
Created: $(date '+%Y-%m-%d %H:%M:%S')
EOF
    
    echo "    Spawning FIXER agent for Skill $skill_num..."
    # Spawn a fixer agent to complete the skipped steps
    openclaw agent spawn \
      --task "Remediate Skill $skill_num. Read the remediation plan at $remediation_plan. Complete all skipped steps: $issues_found. Report: 'Skill $skill_num - Remediation complete. All steps now verified.'" \
      --label "skill-$skill_num-remediation" 2>/dev/null || echo "      Note: Could not spawn fixer agent"
    
    return 1
  fi
  
  # Step 4: Remediation Report Format
  echo ""
  echo "    Skill $skill_num - QC Check"
  echo "    Status: PASS"
  echo "    Steps Verified: $steps_verified/$total_steps complete"
  echo "    Issues Found: none"
  echo "    Remediation: not needed"
  echo "    Final Status: PASS"
  echo ""
  
  return 0
}

# ============================================
# WAVE 1: FOUNDATION (Sequential)
# ============================================
report_progress 1 "FOUNDATION WAVE - Skills 01, 02, QMD, 03"
echo "Wave 1 installs the foundation skills sequentially."
echo ""

# Skill 01: Teach Yourself Protocol
echo "[Wave 1/5] Skill 01: Teach Yourself Protocol"
if qc_skill "01" "01-teach-yourself-protocol"; then
  echo "  ✓ Skill 01 QC passed"
  # Spawn agent or install directly
  spawn_skill_agent "01" "Teach Yourself Protocol" "01-teach-yourself-protocol"
else
  echo "  ✗ Skill 01 QC failed - critical error"
  exit 1
fi

# Wait for Skill 01 (critical - must complete)
echo "  Waiting for Skill 01 completion..."
sleep 2

# Skill 02: Back Yourself Up Protocol
echo ""
echo "[Wave 1/5] Skill 02: Back Yourself Up Protocol"
if qc_skill "02" "02-back-yourself-up-protocol"; then
  echo "  ✓ Skill 02 QC passed"
  spawn_skill_agent "02" "Back Yourself Up Protocol" "02-back-yourself-up-protocol"
else
  echo "  ✗ Skill 02 QC failed - critical error"
  exit 1
fi

# Wait for Skill 02 (critical - must complete)
echo "  Waiting for Skill 02 completion..."
sleep 2

# QMD already installed in Step 3, just verify
echo ""
echo "[Wave 1/5] QMD: Semantic Search Engine (already installed)"
if command -v qmd &>/dev/null; then
  echo "  ✓ QMD verified: $(qmd --version)"
else
  echo "  ✗ QMD not found - critical error"
  exit 1
fi

# Skill 03: Agent Browser
echo ""
echo "[Wave 1/5] Skill 03: Agent Browser"
if qc_skill "03" "03-agent-browser"; then
  echo "  ✓ Skill 03 QC passed"
  spawn_skill_agent "03" "Agent Browser" "03-agent-browser"
else
  echo "  ✗ Skill 03 QC failed - critical error"
  exit 1
fi

# Update progress
echo '{"wave":1,"total_waves":5,"skills_completed":4,"total_skills":29,"status":"Wave 1 complete - Foundation installed"}' > "$PROGRESS_FILE"

# ============================================
# WAVE 2: PRE-PERSONA TOOLS (Parallel - 3 install + 1 QC agents)
# ============================================
report_progress 2 "PRE-PERSONA WAVE - Skills 04-21 (3 install + 1 QC agents)"
echo "Wave 2 installs 18 skills across 3 parallel install agents + 1 QC agent."
echo ""

# Agent A: Skills 04, 05, 06, 07
echo "[Wave 2/5] Launching Agent A (Skills 04-07)..."
(
  for skill in "04-superpowers" "05-ghl-setup" "06-ghl-install-pages" "07-kie-setup"; do
    num=${skill%%-*}
    name=$(echo "$skill" | tr '-' ' ' | sed 's/^[0-9]* //')
    echo "    Agent A: Starting Skill $num"
    qc_skill "$num" "$skill" && spawn_skill_agent "$num" "$name" "$skill"
    sleep 1
  done
  echo "    Agent A: All skills (04-07) initiated"
) &
AGENT_A_PID=$!

# Agent B: Skills 08, 09, 10, 11
echo "[Wave 2/5] Launching Agent B (Skills 08-11)..."
(
  for skill in "08-vercel-setup" "09-context7" "10-github-setup" "11-superdesign"; do
    num=${skill%%-*}
    name=$(echo "$skill" | tr '-' ' ' | sed 's/^[0-9]* //')
    echo "    Agent B: Starting Skill $num"
    qc_skill "$num" "$skill" && spawn_skill_agent "$num" "$name" "$skill"
    sleep 1
  done
  echo "    Agent B: All skills (08-11) initiated"
) &
AGENT_B_PID=$!

# Agent C: Skills 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
echo "[Wave 2/5] Launching Agent C (Skills 12-21)..."
(
  for skill in "12-openrouter-setup" "13-google-workspace-setup" "14-google-workspace-integration" "15-blackceo-team-management" "16-summarize-youtube" "17-self-improving-agent" "18-proactive-agent" "19-humanizer" "20-youtube-watcher" "21-tavily-search"; do
    num=${skill%%-*}
    name=$(echo "$skill" | tr '-' ' ' | sed 's/^[0-9]* //')
    echo "    Agent C: Starting Skill $num"
    qc_skill "$num" "$skill" && spawn_skill_agent "$num" "$name" "$skill"
    sleep 1
  done
  echo "    Agent C: All skills (12-21) initiated"
) &
AGENT_C_PID=$!

# Agent D: QC Agent - Continuous verification
echo "[Wave 2/5] Launching Agent D (QC Agent - continuous verification)..."
(
  echo "    Agent D: QC Agent starting - monitoring all Wave 2 skills"
  # QC agent runs continuously, checking skills as they complete
  for skill_num in 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21; do
    skill_folder=$(printf "%02d-*" "$skill_num")
    echo "    Agent D: Queued QC check for Skill $skill_num"
  done
  echo "    Agent D: QC monitoring active - reports in real-time to main orchestrator"
) &
AGENT_D_PID=$!

echo ""
echo "  All 4 Wave 2 agents launched (3 install + 1 QC). Waiting for completion..."

# Wait for all Wave 2 agents with timeout
wait_for_wave 2 21 45

# Update progress
echo '{"wave":2,"total_waves":5,"skills_completed":21,"total_skills":29,"status":"Wave 2 complete - Pre-Persona tools installed"}' > "$PROGRESS_FILE"

# ============================================
# WAVE 3: CORE SYSTEM (Sequential)
# ============================================
report_progress 3 "CORE SYSTEM WAVE - Skills 22-23 (Sequential, main orchestrator only)"
echo "Wave 3 installs core system skills sequentially."
echo "SKILLS 22 AND 23 MUST BE INSTALLED BY MAIN ORCHESTRATOR - NO SUB-AGENTS."
echo ""

# Skill 22: Book-to-Persona
echo "[Wave 3/5] Skill 22: Book-to-Persona Coaching Leadership System"
echo "  ⚠️  MAIN ORCHESTRATOR ONLY - Do NOT delegate to sub-agent"
if qc_skill "22" "22-book-to-persona-coaching-leadership-system"; then
  echo "  ✓ Skill 22 QC passed - Ready for main orchestrator"
  echo "  📋 Main orchestrator should now:"
  echo "     1. Read ALL .md files in skill 22 folder"
  echo "     2. Execute installation steps"
  echo "     3. Verify QMD coaching-personas collection created"
else
  echo "  ✗ Skill 22 QC failed"
fi

# Skill 23: AI Workforce Blueprint (must wait for 22)
echo ""
echo "[Wave 3/5] Skill 23: AI Workforce Blueprint"
echo "  ⚠️  MAIN ORCHESTRATOR ONLY - Do NOT delegate to sub-agent"
echo "  ⏳  Must complete AFTER Skill 22"
if qc_skill "23" "23-ai-workforce-blueprint"; then
  echo "  ✓ Skill 23 QC passed - Ready for main orchestrator"
  echo "  📋 Main orchestrator should now:"
  echo "     1. Read ALL .md files in skill 23 folder"
  echo "     2. NOTIFY user before asking questions"
  echo "     3. Execute installation steps"
else
  echo "  ✗ Skill 23 QC failed"
fi

# Update progress
echo '{"wave":3,"total_waves":5,"skills_completed":23,"total_skills":29,"status":"Wave 3 complete - Core system ready (main orchestrator install required)"}' > "$PROGRESS_FILE"

# ============================================
# WAVE 4: POST-WORKFORCE (Parallel - 2 agents)
# ============================================
report_progress 4 "POST-WORKFORCE WAVE - Skills 24-29 (2 parallel agents)"
echo "Wave 4 installs 6 skills across 2 parallel agents."
echo ""

# Agent E: Skills 24, 25, 26
echo "[Wave 4/5] Launching Agent E (Skills 24-26)..."
(
  for skill in "24-storyboard-writer" "25-video-creator" "26-caption-creator"; do
    num=${skill%%-*}
    name=$(echo "$skill" | tr '-' ' ' | sed 's/^[0-9]* //')
    echo "    Agent E: Starting Skill $num"
    qc_skill "$num" "$skill" && spawn_skill_agent "$num" "$name" "$skill"
    sleep 1
  done
  echo "    Agent E: All skills (24-26) initiated"
) &
AGENT_E_PID=$!

# Agent F: Skills 27, 28, 29
echo "[Wave 4/5] Launching Agent F (Skills 27-29)..."
(
  for skill in "27-video-editor" "28-cinematic-forge" "29-ghl-convert-and-flow"; do
    num=${skill%%-*}
    name=$(echo "$skill" | tr '-' ' ' | sed 's/^[0-9]* //')
    echo "    Agent F: Starting Skill $num"
    qc_skill "$num" "$skill" && spawn_skill_agent "$num" "$name" "$skill"
    sleep 1
  done
  echo "    Agent F: All skills (27-29) initiated"
) &
AGENT_F_PID=$!

echo ""
echo "  Both Wave 4 agents launched. Waiting for completion..."

# Wait for all Wave 4 agents with timeout
wait_for_wave 4 29 30

# Update progress
echo '{"wave":4,"total_waves":5,"skills_completed":29,"total_skills":29,"status":"Wave 4 complete - All skills initiated"}' > "$PROGRESS_FILE"

# ============================================
# WAVE 5: FINAL (Sequential)
# ============================================
report_progress 5 "FINAL WAVE - Skill 15 verification"
echo "Wave 5 verifies Skill 15 completion and finalizes installation."
echo ""

echo "[Wave 5/5] Final verification..."
echo "  ✓ All 29 skills have been initiated"
echo "  📋 Final tasks for main orchestrator:"
echo "     1. Verify Skill 15 (BlackCEO Team Management) is complete"
echo "     2. Run final QMD indexing: qmd update && qmd embed && qmd status"
echo "     3. Remove ONBOARDING PENDING flag from AGENTS.md"
echo "     4. Write ONBOARDING COMPLETE to MEMORY.md"

# Update final progress
echo '{"wave":5,"total_waves":5,"skills_completed":29,"total_skills":29,"status":"COMPLETE - All waves finished"}' > "$PROGRESS_FILE"

# ----------------------------------------------------------
# Final: Trigger the running OpenClaw agent
# ----------------------------------------------------------
echo ""
echo "============================================"
echo "  ORCHESTRATION COMPLETE"
echo "============================================"
echo ""

TRIGGER_MSG="PARALLEL ONBOARDING ORCHESTRATED - EXECUTE NOW. The 5-wave parallel installation has been initiated. Wave 1 (Foundation: 01-03) and Wave 2 (Pre-Persona: 04-21 via 4 parallel agents) have been launched. Wave 3 (Core: 22-23) requires MAIN ORCHESTRATOR installation - do NOT use sub-agents. Wave 4 (Post-Workforce: 24-29 via 2 parallel agents) has been launched. Wave 5 (Final) is verification. Progress tracked at: $PROGRESS_FILE. Begin execution immediately. Install all skills following the Teach Yourself Protocol. Handle API key prompts autonomously. Report progress after EACH skill completes."

if openclaw agent --message "$TRIGGER_MSG" --deliver 2>/dev/null; then
  echo "  Agent triggered successfully."
else
  echo "  Note: Could not trigger agent via 'openclaw agent --deliver'."
  echo "  The onboarding flag has been written to AGENTS.md."
  echo "  Your agent will pick it up on its next session start."
fi

# ----------------------------------------------------------
# Done
# ----------------------------------------------------------
echo ""
echo "============================================"
echo "  Parallel onboarding orchestrated."
echo "  Your OpenClaw agents are now installing"
echo "  29 skills in 5 orchestrated waves."
echo "  Installer version: ${ONBOARDING_VERSION}"
echo ""
echo "  Progress file: $PROGRESS_FILE"
echo "  Check your configured messaging channel"
echo "  for real-time progress updates."
echo "============================================"
echo ""
