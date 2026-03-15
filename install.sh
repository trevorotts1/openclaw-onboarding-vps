#!/usr/bin/env bash
set -euo pipefail

ONBOARDING_VERSION="v2.4.0-vps"

# ============================================================
#  OpenClaw VPS Onboarding Installer (Hostinger Edition)
#  Run INSIDE the Docker container:
#    docker ps
#    docker exec -it [container-name] bash
#    curl -fsSL https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding-vps/main/install.sh | bash
# ============================================================

# ----------------------------------------------------------
# VPS persistent storage paths
# Everything must live under /data/ to survive container restarts
# ----------------------------------------------------------
DATA_DIR="/data"
ONBOARDING_DIR="$DATA_DIR/.openclaw/onboarding"
WORKSPACE_DIR="$DATA_DIR/openclaw/workspace"
MASTER_FILES_DIR="$DATA_DIR/openclaw-master-files"
BACKUP_DIR="$DATA_DIR/openclaw-backups"
SKILLS_DIR="$DATA_DIR/.openclaw/skills"

mkdir -p "$ONBOARDING_DIR" "$WORKSPACE_DIR" "$MASTER_FILES_DIR" "$BACKUP_DIR" "$SKILLS_DIR"

# ----------------------------------------------------------
# Check if onboarding already in progress
# ----------------------------------------------------------
INSTALL_FLAG="$ONBOARDING_DIR/.install-in-progress"

if [ -f "$INSTALL_FLAG" ]; then
  echo ""
  echo "============================================"
  echo "   Onboarding already in progress"
  echo "============================================"
  echo "If this is incorrect, remove the flag:"
  echo "  rm $INSTALL_FLAG"
  echo ""
  exit 0
fi

touch "$INSTALL_FLAG"
trap 'rm -f "$INSTALL_FLAG"' EXIT

echo ""
echo "============================================"
echo "   OpenClaw VPS Onboarding Installer"
echo "   Version: ${ONBOARDING_VERSION}"
echo "   Storage: /data/ (persistent)"
echo "============================================"
echo ""

# ----------------------------------------------------------
# Step 1: Check that OpenClaw CLI is installed
# ----------------------------------------------------------
echo "[1/6] Checking for OpenClaw CLI..."
if ! command -v openclaw &>/dev/null; then
  echo ""
  echo "ERROR: OpenClaw CLI not found in PATH."
  echo "Install OpenClaw first: npm install -g openclaw"
  echo ""
  exit 1
fi
echo "  Found: $(command -v openclaw)"

# ----------------------------------------------------------
# Step 2: Check required tools
# ----------------------------------------------------------
echo ""
echo "[2/6] Checking required tools..."

# Check for tar (required for extraction)
if ! command -v tar &>/dev/null; then
  echo "ERROR: tar not found. Install it: apt-get install -y tar"
  exit 1
fi
echo "  tar: OK"

# Check for curl
if ! command -v curl &>/dev/null; then
  echo "ERROR: curl not found. Install it: apt-get install -y curl"
  exit 1
fi
echo "  curl: OK"

# Install unzip if missing (used as fallback)
if ! command -v unzip &>/dev/null; then
  echo "  unzip not found - installing..."
  apt-get update -qq && apt-get install -y -qq unzip 2>/dev/null || echo "  (unzip install failed - will use tar)"
fi

# ----------------------------------------------------------
# Step 3: Download the VPS onboarding package
# ----------------------------------------------------------
echo ""
echo "[3/6] Downloading 29 skills from GitHub..."
TEMP_ZIP="/tmp/openclaw-onboarding-vps-pkg.zip"
TEMP_EXTRACT="/tmp/openclaw-onboarding-vps-extract"

curl -fsSL "https://github.com/trevorotts1/openclaw-onboarding-vps/archive/refs/heads/main.zip" -o "$TEMP_ZIP"
if [ ! -f "$TEMP_ZIP" ]; then
  echo "ERROR: Failed to download onboarding package."
  exit 1
fi
echo "  Downloaded to $TEMP_ZIP"

# ----------------------------------------------------------
# Step 4: Extract to /data/.openclaw/onboarding/
# ----------------------------------------------------------
echo ""
echo "[4/6] Extracting to $ONBOARDING_DIR..."
rm -rf "$TEMP_EXTRACT"
mkdir -p "$TEMP_EXTRACT"

# Try unzip first, fall back to python3
if command -v unzip &>/dev/null; then
  unzip -qo "$TEMP_ZIP" -d "$TEMP_EXTRACT"
else
  python3 -c "import zipfile; zipfile.ZipFile('/tmp/openclaw-onboarding-vps-pkg.zip').extractall('$TEMP_EXTRACT')"
fi

if [ ! -d "$TEMP_EXTRACT/openclaw-onboarding-vps-main" ]; then
  echo "ERROR: Unexpected archive structure."
  rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
  exit 1
fi

cp -r "$TEMP_EXTRACT/openclaw-onboarding-vps-main/"* "$ONBOARDING_DIR/"
rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
echo "  Installed to $ONBOARDING_DIR"

SKILL_COUNT=$(ls -1 "$ONBOARDING_DIR" | grep -E "^[0-9]+-" | wc -l)
echo "  Skills found: $SKILL_COUNT"

echo "$ONBOARDING_VERSION" > "$SKILLS_DIR/.onboarding-version"
echo "$ONBOARDING_VERSION" > "$ONBOARDING_DIR/.onboarding-version"
echo "  Version: $ONBOARDING_VERSION"

# ----------------------------------------------------------
# Step 5: Set up ffmpeg static binary in /data/bin/
# ----------------------------------------------------------
echo ""
echo "[5/6] Checking ffmpeg..."
BIN_DIR="$DATA_DIR/bin"
mkdir -p "$BIN_DIR"

if command -v ffmpeg &>/dev/null; then
  echo "  ffmpeg already available: $(command -v ffmpeg)"
else
  echo "  ffmpeg not found - downloading static binary to $BIN_DIR..."
  FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
  curl -fsSL "$FFMPEG_URL" -o /tmp/ffmpeg.tar.xz 2>/dev/null && \
    tar -xf /tmp/ffmpeg.tar.xz -C /tmp/ 2>/dev/null && \
    cp /tmp/ffmpeg-*-amd64-static/ffmpeg "$BIN_DIR/ffmpeg" && \
    cp /tmp/ffmpeg-*-amd64-static/ffprobe "$BIN_DIR/ffprobe" && \
    chmod +x "$BIN_DIR/ffmpeg" "$BIN_DIR/ffprobe" && \
    rm -rf /tmp/ffmpeg* && \
    echo "  ffmpeg installed to $BIN_DIR/ffmpeg" || \
    echo "  WARNING: ffmpeg download failed. Video skills will not work. Install manually later."

  # Add to PATH for this session
  export PATH="$BIN_DIR:$PATH"
fi

# ----------------------------------------------------------
# Step 6: Write onboarding flag to AGENTS.md
# ----------------------------------------------------------
echo ""
echo "[6/6] Writing onboarding flag..."
AGENTS_FILE="$WORKSPACE_DIR/AGENTS.md"

if [ -f "$AGENTS_FILE" ]; then
  grep -v "ONBOARDING PENDING\|ONBOARDING COMPLETE" "$AGENTS_FILE" > "$AGENTS_FILE.tmp" 2>/dev/null || true
  mv "$AGENTS_FILE.tmp" "$AGENTS_FILE" 2>/dev/null || true
fi

cat >> "$AGENTS_FILE" << 'ONBOARDING_FLAG'

---
🔴🔴🔴 ONBOARDING PENDING - EXECUTE IMMEDIATELY

VPS INSTALLATION - All paths use /data/ (persistent storage)

The OpenClaw onboarding package (29 skills) has been installed to:
  /data/.openclaw/onboarding/

READ THIS FILE FIRST: /data/.openclaw/onboarding/Start Here.md

IMPORTANT - VPS RULES:
- Install skills SEQUENTIALLY (01 through 29 in order) - NO parallel sub-agents
- All paths use /data/ NOT ~/clawd/ or ~/Downloads/
- Browser tools use headless mode only (no visible Chrome on VPS)
- Skip skill 13 (archived)
- Skills 22-23: Main orchestrator ONLY
- Track progress in /data/.openclaw/onboarding/.onboarding-status

DO NOT:
- Skip reading Start Here.md
- Use parallel sub-agents (unreliable in Docker)
- Use ~/clawd/ or ~/Downloads/ paths (not persistent)
- Trigger gateway restarts without asking

ZERO TOLERANCE SHORTCUTS:
- "I'll read that later" = WRONG. Read it NOW.
- "This looks similar to..." = WRONG. Read every file completely.
- "I can skip this step" = WRONG. Follow every step exactly.
---
ONBOARDING_FLAG

echo "  Onboarding flag written to $AGENTS_FILE"

# ----------------------------------------------------------
# Done
# ----------------------------------------------------------
echo ""
echo "============================================"
echo "  OpenClaw VPS Onboarding Package Ready"
echo "  Version: ${ONBOARDING_VERSION}"
echo "============================================"
echo ""
echo "  📦 29 skills downloaded to:"
echo "     /data/.openclaw/onboarding/"
echo ""
echo "  💾 All data stored in /data/ (survives restarts)"
echo ""
echo "  📋 Next step: Tell your AI agent:"
echo "       'Begin onboarding installation'"
echo ""
echo "  The agent will read AGENTS.md and install"
echo "  all 29 skills sequentially."
echo ""
echo "============================================"
echo ""
