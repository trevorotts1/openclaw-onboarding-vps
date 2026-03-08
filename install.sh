#!/bin/bash
# OpenClaw Onboarding - Master Install Script
# One command installs everything, step by step.
# Usage: curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding/main/install.sh | bash

set -e

REPO_URL="https://github.com/trevorotts1/openclaw-onboarding"
SKILLS_DIR="$HOME/.openclaw/skills"
TEMP_DIR=$(mktemp -d)
SUMMARY_INSTALLED=()
SUMMARY_NEEDS_KEY=()
SUMMARY_SKIPPED=()

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "\n${BLUE}==>${NC} $1"; }
print_ok()   { echo -e "${GREEN}✅${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠️${NC}  $1"; }
print_fail() { echo -e "${RED}❌${NC} $1"; }

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║   OpenClaw Onboarding - Master Installer   ║"
echo "╠════════════════════════════════════════════╣"
echo "║  Install order:                            ║"
echo "║  1. Teach Yourself Protocol (TYP)          ║"
echo "║  2. Back Yourself Up Protocol              ║"
echo "║  3. QMD (semantic search engine)           ║"
echo "║  4-23. All remaining skills in order       ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "Starting automatically. No action needed from you"
echo "unless asked for an API key or credential."
echo ""

# ─────────────────────────────────────────────
# STEP 1: Check OpenClaw is installed
# ─────────────────────────────────────────────
print_step "Checking OpenClaw..."
if ! command -v openclaw &>/dev/null; then
  print_fail "OpenClaw is not installed. Install it first: https://docs.openclaw.ai"
  exit 1
fi
print_ok "OpenClaw found: $(openclaw --version 2>/dev/null || echo 'installed')"

# ─────────────────────────────────────────────
# STEP 2: Download the repo
# ─────────────────────────────────────────────
print_step "Downloading OpenClaw Onboarding from GitHub..."
curl -s -L "$REPO_URL/archive/refs/heads/main.zip" -o "$TEMP_DIR/onboarding.zip"
unzip -q "$TEMP_DIR/onboarding.zip" -d "$TEMP_DIR"
EXTRACTED="$TEMP_DIR/openclaw-onboarding-main"
print_ok "Downloaded and extracted"

# ─────────────────────────────────────────────
# STEP 3: Copy all skills to ~/.openclaw/skills/
# ─────────────────────────────────────────────
print_step "Installing skill folders..."
mkdir -p "$SKILLS_DIR"
for skill_dir in "$EXTRACTED"/[0-9]*; do
  skill_name=$(basename "$skill_dir")
  cp -r "$skill_dir" "$SKILLS_DIR/"
  echo "  Installed: $skill_name"
done

# Copy update scripts
mkdir -p "$SKILLS_DIR/scripts"
cp "$EXTRACTED/scripts/"* "$SKILLS_DIR/scripts/" 2>/dev/null || true
chmod +x "$SKILLS_DIR/scripts/"*.sh 2>/dev/null || true
print_ok "All skills installed to $SKILLS_DIR"

# ─────────────────────────────────────────────
# STEP 4: Check Python3
# ─────────────────────────────────────────────
print_step "Checking Python3..."
if command -v python3 &>/dev/null; then
  print_ok "Python3 found: $(python3 --version)"
else
  print_warn "Python3 not found - Book-to-Persona pipeline will not work without it"
fi

# ─────────────────────────────────────────────
# STEP 5: Install QMD (required early - used by Skills 22 and 23)
# ─────────────────────────────────────────────
print_step "Installing QMD (semantic search engine)..."
if command -v qmd &>/dev/null; then
  print_ok "QMD already installed: $(qmd --version 2>/dev/null | head -1)"
else
  print_warn "QMD not found. Installing now..."
  QMD_INSTALLED=false

  # Try bun first
  if command -v bun &>/dev/null; then
    bun install -g https://github.com/tobi/qmd 2>/dev/null && QMD_INSTALLED=true
  fi

  # Try npm if bun failed
  if [ "$QMD_INSTALLED" = false ] && command -v npm &>/dev/null; then
    npm install -g @anthropic/qmd 2>/dev/null && QMD_INSTALLED=true
  fi

  # Install bun if neither worked
  if [ "$QMD_INSTALLED" = false ]; then
    print_warn "Installing bun to get QMD..."
    curl -fsSL https://bun.sh/install | bash 2>/dev/null
    export PATH="$HOME/.bun/bin:$PATH"
    bun install -g https://github.com/tobi/qmd 2>/dev/null && QMD_INSTALLED=true || true
  fi

  # Verify
  if command -v qmd &>/dev/null; then
    print_ok "QMD installed: $(qmd --version 2>/dev/null | head -1)"
    SUMMARY_INSTALLED+=("QMD")
  else
    print_fail "QMD install failed. Install manually: bun install -g https://github.com/tobi/qmd"
    print_warn "Continuing - Skills 22 and 23 will remind you to install QMD when needed."
  fi
fi

# ─────────────────────────────────────────────
# STEP 6: Install Python packages
# ─────────────────────────────────────────────
print_step "Installing Python packages..."
for pkg in pdfplumber ebooklib html2text; do
  python3 -c "import $pkg" 2>/dev/null && print_ok "$pkg already installed" || {
    print_warn "Installing $pkg..."
    pip3 install $pkg --break-system-packages -q 2>/dev/null && print_ok "$pkg installed" || \
    pip3 install $pkg -q 2>/dev/null && print_ok "$pkg installed" || \
    print_warn "$pkg install failed - Book-to-Persona pipeline needs this"
  }
done

# Calibre (optional)
if command -v ebook-convert &>/dev/null; then
  print_ok "Calibre found (MOBI/AZW3 support enabled)"
else
  print_warn "Calibre not found - MOBI/AZW3 books won't work. Install: brew install --cask calibre"
fi

# ─────────────────────────────────────────────
# STEP 7: API Keys - check all env file locations
# ─────────────────────────────────────────────
print_step "Checking API keys..."
echo "  Scanning all env file locations..."

# All possible env file locations - checks in order, uses first found value
ENV_LOCATIONS=(
  "$HOME/clawd/secrets/.env"
  "$HOME/.openclaw/.env"
  "$HOME/.openclaw/openclaw.env"
  "$HOME/clawd/.env"
  "$HOME/.env"
)

# Primary env file - where we write new keys
PRIMARY_ENV="$HOME/clawd/secrets/.env"

PENDING_FILE="$HOME/.openclaw/skills/.pending-setup.md"

log_pending() {
  local key_name="$1"
  local description="$2"
  local skill="$3"
  if [ ! -f "$PENDING_FILE" ]; then
    echo "# Pending Skill Setup" > "$PENDING_FILE"
    echo "These API keys were not found during install. Your AI agent checks this file" >> "$PENDING_FILE"
    echo "automatically and will remind you to add them when relevant." >> "$PENDING_FILE"
    echo "" >> "$PENDING_FILE"
  fi
  cat >> "$PENDING_FILE" << ENTRY

## $key_name
- **Skill:** $skill
- **What it unlocks:** $description
- **How to add:** echo "${key_name}=YOUR_KEY_HERE" >> $PRIMARY_ENV
- **Status:** PENDING
ENTRY
}

check_or_ask_key() {
  local key_name="$1"
  local description="$2"
  local skill="${3:-unknown skill}"
  local existing=""

  # Check ALL env file locations
  for env_path in "${ENV_LOCATIONS[@]}"; do
    if [ -f "$env_path" ]; then
      local val
      val=$(grep "^${key_name}=" "$env_path" 2>/dev/null | cut -d= -f2-)
      if [ -n "$val" ] && [ "$val" != '""' ] && [ "$val" != "''" ]; then
        print_ok "$key_name found (in $(basename "$env_path"))"
        existing="$val"
        break
      fi
    fi
  done

  if [ -n "$existing" ]; then
    return 0
  fi

  echo ""
  print_warn "$key_name not found in any env file"
  echo "  Needed for: $description"
  echo "  Skill: $skill"
  echo ""
  echo "  Options:"
  echo "  [1] Enter the key now"
  echo "  [2] Skip this key - remind me later (agent will prompt you when needed)"
  echo "  [3] Skip permanently"
  echo ""
  read -p "  Choice [1/2/3] (default: 2): " key_choice
  key_choice="${key_choice:-2}"

  case "$key_choice" in
    1)
      read -p "  Enter $key_name: " user_key
      if [ -n "$user_key" ]; then
        mkdir -p "$(dirname "$PRIMARY_ENV")"
        echo "${key_name}=${user_key}" >> "$PRIMARY_ENV"
        print_ok "$key_name saved to $PRIMARY_ENV"
        return 0
      fi
      ;;
    3)
      print_warn "$key_name permanently skipped"
      SUMMARY_SKIPPED+=("$key_name")
      return 1
      ;;
  esac

  # Default: remind later
  log_pending "$key_name" "$description" "$skill"
  print_warn "$key_name added to pending - agent will remind you when needed"
  SUMMARY_NEEDS_KEY+=("$key_name")
  return 1
}

check_or_ask_key "MOONSHOT_API_KEY"   "Book-to-Persona Phase 1 extraction (Kimi K2.5)" "22-book-to-persona-coaching-leadership-system"
check_or_ask_key "OPENROUTER_API_KEY" "Book-to-Persona Phase 2 (DeepSeek) and model routing" "22-book-to-persona-coaching-leadership-system"
check_or_ask_key "OPENAI_API_KEY"     "Book-to-Persona Phase 3 synthesis (Codex)" "22-book-to-persona-coaching-leadership-system"
check_or_ask_key "GITHUB_TOKEN"       "Push new personas to GitHub after pipeline runs" "22-book-to-persona-coaching-leadership-system"

# ─────────────────────────────────────────────
# STEP 8: Set up QMD coaching-personas collection
# ─────────────────────────────────────────────
print_step "Setting up QMD persona collection..."

PERSONAS_DIR="$SKILLS_DIR/22-book-to-persona-coaching-leadership-system/personas"
if [ -d "$PERSONAS_DIR" ] && command -v qmd &>/dev/null; then
  if qmd status 2>/dev/null | grep -q "coaching-personas"; then
    print_ok "QMD coaching-personas collection already exists"
  else
    print_warn "Adding 40 pre-built personas to QMD index..."
    qmd collection add "$PERSONAS_DIR" --name coaching-personas --mask "**/*.md" 2>/dev/null
    qmd update 2>/dev/null
    print_ok "Persona collection added. Running embed in background (3-8 min)..."
    qmd embed 2>/dev/null &
    QMD_PID=$!
    SUMMARY_INSTALLED+=("QMD coaching-personas (40 personas, embedding in background)")
  fi
else
  if ! command -v qmd &>/dev/null; then
    print_warn "QMD not available - persona collection setup skipped"
  elif [ ! -d "$PERSONAS_DIR" ]; then
    print_warn "Persona folder not found at $PERSONAS_DIR - check skill 22 installed correctly"
  fi
fi

# ─────────────────────────────────────────────
# STEP 9: Set up weekly update cron
# ─────────────────────────────────────────────
print_step "Setting up weekly skill auto-update (Sundays 2 AM)..."
if crontab -l 2>/dev/null | grep -q "update-skills.sh"; then
  print_ok "Weekly update cron already installed"
else
  CRON_JOB="0 2 * * 0 $SKILLS_DIR/scripts/update-skills.sh >> $HOME/.openclaw/skills/.update-log 2>&1"
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  print_ok "Weekly update cron installed"
  SUMMARY_INSTALLED+=("Weekly auto-update cron")
fi

# Save installed version
REMOTE_VERSION=$(grep -m1 "^## \[v" "$EXTRACTED/CHANGELOG.md" 2>/dev/null | sed 's/## \[\(v[0-9.]*\)\].*/\1/' || echo "unknown")
echo "$REMOTE_VERSION" > "$SKILLS_DIR/.onboarding-version"

# ─────────────────────────────────────────────
# Clean up
# ─────────────────────────────────────────────
rm -rf "$TEMP_DIR"

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║              Install Complete              ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Version installed: $REMOTE_VERSION${NC}"
echo -e "${GREEN}Skills folder: $SKILLS_DIR${NC}"
echo ""

echo -e "${BLUE}Install order your AI agent will follow:${NC}"
echo "  Step 1: Teach Yourself Protocol (TYP) - how to store knowledge"
echo "  Step 2: Back Yourself Up Protocol - how to protect configs"
echo "  Step 3: QMD already installed ✅"
echo "  Steps 4-23: All remaining skills in numbered order"
echo ""

if [ -f "$PENDING_FILE" ]; then
  echo -e "${YELLOW}⚠️  API keys pending (agent will remind you when needed):${NC}"
  grep "^## " "$PENDING_FILE" | sed 's/^## /  - /'
  echo ""
  echo -e "  Full details: $PENDING_FILE"
  echo ""
fi

if [ -n "${QMD_PID:-}" ]; then
  echo -e "${YELLOW}QMD embedding personas in background (pid $QMD_PID). Check: qmd status${NC}"
  echo ""
fi

echo -e "${BLUE}Ready. Hand off to your AI agent:${NC}"
echo ""
echo "  Start onboarding by reading:"
echo "  $SKILLS_DIR/01-teach-yourself-protocol/SKILL.md"
echo ""
echo "  The agent completes each skill in order. You only need to"
echo "  provide credentials when asked. Everything else is automatic."
echo ""
