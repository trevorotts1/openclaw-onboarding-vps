#!/usr/bin/env bash
set -euo pipefail

ONBOARDING_VERSION="v2.4.0"

# ============================================================
#  OpenClaw Onboarding Installer
#  Run via: curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding/main/install.sh | bash
# ============================================================

# ----------------------------------------------------------
# Check if onboarding already in progress
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

# Create flag file
touch "$INSTALL_FLAG"
trap 'rm -f "$INSTALL_FLAG"' EXIT

echo ""
echo "============================================"
echo "   OpenClaw Onboarding Installer"
echo "   Version: ${ONBOARDING_VERSION}"
echo "============================================"
echo ""

# ----------------------------------------------------------
# Step 1: Check that OpenClaw CLI is installed
# ----------------------------------------------------------
echo "[1/5] Checking for OpenClaw CLI..."
if ! command -v openclaw &>/dev/null; then
  echo ""
  echo "ERROR: OpenClaw CLI not found in PATH."
  echo ""
  echo "Install OpenClaw first:"
  echo "  npm install -g openclaw"
  echo ""
  exit 1
fi
echo "  Found: $(command -v openclaw)"

# ----------------------------------------------------------
# Step 2: Download the onboarding package
# ----------------------------------------------------------
echo ""
echo "[2/5] Downloading 29 skills from GitHub..."
TEMP_ZIP="/tmp/openclaw-onboarding-pkg.zip"
TEMP_EXTRACT="/tmp/openclaw-onboarding-extract"

curl -fsSL "https://github.com/trevorotts1/openclaw-onboarding/archive/refs/heads/main.zip" -o "$TEMP_ZIP"
if [ ! -f "$TEMP_ZIP" ]; then
  echo "ERROR: Failed to download onboarding package."
  exit 1
fi
echo "  Downloaded to $TEMP_ZIP"

# ----------------------------------------------------------
# Step 3: Extract to ~/.openclaw/onboarding/
# ----------------------------------------------------------
echo ""
echo "[3/5] Extracting to ~/.openclaw/onboarding/..."
rm -rf "$TEMP_EXTRACT"
unzip -qo "$TEMP_ZIP" -d "$TEMP_EXTRACT"
if [ ! -d "$TEMP_EXTRACT/openclaw-onboarding-main" ]; then
  echo "ERROR: Unexpected archive structure."
  rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
  exit 1
fi

# Clear existing onboarding folder and copy fresh
cp -r "$TEMP_EXTRACT/openclaw-onboarding-main/"* "$ONBOARDING_DIR/"
rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
echo "  Installed to $ONBOARDING_DIR"

# Count skills
SKILL_COUNT=$(ls -1 "$ONBOARDING_DIR" | grep -E "^[0-9]+-" | wc -l)
echo "  Skills found: $SKILL_COUNT"

# Record version
SKILLS_DIR="$HOME/.openclaw/skills"
mkdir -p "$SKILLS_DIR"
echo "$ONBOARDING_VERSION" > "$SKILLS_DIR/.onboarding-version"
echo "$ONBOARDING_VERSION" > "$ONBOARDING_DIR/.onboarding-version"
echo "  Version: $ONBOARDING_VERSION"

# ----------------------------------------------------------
# Step 4: Set up backup folder
# ----------------------------------------------------------
echo ""
echo "[4/5] Setting up backup folder..."
DOWNLOADS_DIR="$HOME/Downloads"
BACKUP_DIR=""

# Look for existing backup folder
if [ -d "$DOWNLOADS_DIR" ]; then
  while IFS= read -r dir; do
    dirname_lower=$(basename "$dir" | tr '[:upper:]' '[:lower:]')
    if [[ "$dirname_lower" == *openclaw* ]] && [[ "$dirname_lower" == *backup* ]]; then
      BACKUP_DIR="$dir"
      break
    fi
  done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type d 2>/dev/null)
fi

# Create if not found
if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR="$DOWNLOADS_DIR/OpenClaw Backups"
  mkdir -p "$BACKUP_DIR"
  echo "  Created: $BACKUP_DIR"
else
  echo "  Found: $BACKUP_DIR"
fi

# ----------------------------------------------------------
# Step 5: Write onboarding flag to AGENTS.md
# ----------------------------------------------------------
echo ""
echo "[5/5] Writing onboarding flag..."
WORKSPACE_DIR="$HOME/.openclaw/workspace"
AGENTS_FILE="$WORKSPACE_DIR/AGENTS.md"
mkdir -p "$WORKSPACE_DIR"

# Remove any existing ONBOARDING PENDING flag to avoid duplicates
if [ -f "$AGENTS_FILE" ]; then
  grep -v "ONBOARDING PENDING\|ONBOARDING COMPLETE" "$AGENTS_FILE" > "$AGENTS_FILE.tmp" 2>/dev/null || true
  mv "$AGENTS_FILE.tmp" "$AGENTS_FILE" 2>/dev/null || true
fi

cat >> "$AGENTS_FILE" << 'ONBOARDING_FLAG'

---
🔴🔴🔴 ONBOARDING PENDING - EXECUTE IMMEDIATELY

The OpenClaw onboarding package (29 skills) has been installed to:
  ~/.openclaw/onboarding/

YOUR TASK: Install all 29 skills following the Teach Yourself Protocol.

1. Read Start Here.md first: ~/.openclaw/onboarding/Start Here.md
2. Install skills 01-29 in order
3. For each skill: Read ALL .md files BEFORE executing any steps
4. Handle API key prompts autonomously (skip if missing, log reminder)
5. Report progress after EACH skill completes
6. When all 29 are done: Remove this ONBOARDING PENDING block from AGENTS.md

DO NOT:
- Skip skills or say "done" until all 29 are verified complete
- Take shortcuts ("I'll read that later", "This looks similar")
- Change the user's model without permission
- Trigger gateway restarts without asking

SKILL INSTALLATION ORDER:
01. Teach Yourself Protocol
02. Back Yourself Up Protocol
03. Agent Browser
04. Superpowers
05. GHL Setup
06. GHL Install Pages
07. KIE Setup
08. Vercel Setup
09. Context7
10. GitHub Setup
11. SuperDesign
12. OpenRouter Setup
13. Google Workspace Setup (ARCHIVED - skip)
14. Google Workspace Integration
15. BlackCEO Team Management
16. Summarize YouTube
17. Self-Improving Agent
18. Proactive Agent
19. Humanizer
20. YouTube Watcher
21. Tavily Search
22. Book-to-Persona Coaching Leadership System (MAIN ORCHESTRATOR ONLY)
23. AI Workforce Blueprint (MAIN ORCHESTRATOR ONLY)
24. Storyboard Writer
25. Video Creator
26. Caption Creator
27. Video Editor
28. Cinematic Forge
29. GHL Convert and Flow

When complete, write ONBOARDING COMPLETE to MEMORY.md and remove this block.
---
ONBOARDING_FLAG

echo "  Onboarding flag written to AGENTS.md"

# ----------------------------------------------------------
# Done
# ----------------------------------------------------------
echo ""
echo "============================================"
echo "  OpenClaw Onboarding Package Ready"
echo "  Version: ${ONBOARDING_VERSION}"
echo "============================================"
echo ""
echo "  📦 29 skills downloaded to:"
echo "     ~/.openclaw/onboarding/"
echo ""
echo "  📋 Next step: Tell your AI agent to begin."
echo ""
echo "     Send this message to your OpenClaw agent:"
echo ""
echo "       'Begin onboarding installation'"
echo ""
echo "  The agent will read AGENTS.md, find the"
echo "  ONBOARDING PENDING flag, and install all"
echo "  29 skills automatically."
echo ""
echo "============================================"
echo ""
