#!/bin/bash
# OpenClaw Onboarding - Weekly Skill Update Check
# Runs every Sunday at 2:00 AM
# Checks GitHub for new versions, applies updates, notifies via Telegram

REPO_URL="https://github.com/trevorotts1/openclaw-onboarding"
RAW_URL="https://raw.githubusercontent.com/trevorotts1/openclaw-onboarding/main"
SKILLS_DIR="$HOME/.openclaw/skills"
VERSION_FILE="$HOME/.openclaw/skills/.onboarding-version"
CHANGELOG_CACHE="$HOME/.openclaw/skills/.onboarding-changelog"
ENV_FILE="$HOME/clawd/secrets/.env"

# Load env vars for Telegram notification
if [ -f "$ENV_FILE" ]; then
  export $(grep -E "^TELEGRAM_BOT_TOKEN|^TELEGRAM_CHAT_ID" "$ENV_FILE" | xargs) 2>/dev/null
fi

send_telegram() {
  local message="$1"
  if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=${message}" \
      -d "parse_mode=Markdown" > /dev/null 2>&1
  fi
}

# Get current local version
LOCAL_VERSION=""
if [ -f "$VERSION_FILE" ]; then
  LOCAL_VERSION=$(cat "$VERSION_FILE")
fi

# Fetch latest CHANGELOG from GitHub
REMOTE_CHANGELOG=$(curl -s --max-time 30 "$RAW_URL/CHANGELOG.md" 2>/dev/null)
if [ -z "$REMOTE_CHANGELOG" ]; then
  echo "$(date): Update check failed - could not reach GitHub" >> "$HOME/.openclaw/skills/.update-log"
  exit 1
fi

# Extract latest version from CHANGELOG
REMOTE_VERSION=$(echo "$REMOTE_CHANGELOG" | grep -m1 "^## \[v" | sed 's/## \[\(v[0-9.]*\)\].*/\1/')

if [ -z "$REMOTE_VERSION" ]; then
  echo "$(date): Could not parse remote version" >> "$HOME/.openclaw/skills/.update-log"
  exit 1
fi

echo "$(date): Local version: ${LOCAL_VERSION:-none}, Remote version: $REMOTE_VERSION" >> "$HOME/.openclaw/skills/.update-log"

# Compare versions
if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
  echo "$(date): Already up to date ($REMOTE_VERSION)" >> "$HOME/.openclaw/skills/.update-log"
  exit 0
fi

# New version found - extract what changed
CHANGES=$(echo "$REMOTE_CHANGELOG" | awk '/^## \[v/{count++} count==1{print}' | head -30)

# Download and apply updates
echo "$(date): Applying update $LOCAL_VERSION -> $REMOTE_VERSION" >> "$HOME/.openclaw/skills/.update-log"

TEMP_DIR=$(mktemp -d)
ZIP_FILE="$TEMP_DIR/onboarding.zip"

curl -s -L "$REPO_URL/archive/refs/heads/main.zip" -o "$ZIP_FILE" 2>/dev/null
if [ ! -f "$ZIP_FILE" ] || [ ! -s "$ZIP_FILE" ]; then
  echo "$(date): Download failed" >> "$HOME/.openclaw/skills/.update-log"
  rm -rf "$TEMP_DIR"
  send_telegram "⚠️ *Skill Update Failed*%0AVersion $REMOTE_VERSION available but download failed. Check GitHub manually: $REPO_URL"
  exit 1
fi

unzip -q "$ZIP_FILE" -d "$TEMP_DIR" 2>/dev/null
EXTRACTED="$TEMP_DIR/openclaw-onboarding-main"

if [ ! -d "$EXTRACTED" ]; then
  echo "$(date): Extract failed" >> "$HOME/.openclaw/skills/.update-log"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Update only skill folders that exist locally (never creates new skills automatically)
UPDATED_SKILLS=()
for skill_dir in "$EXTRACTED"/[0-9]*; do
  skill_name=$(basename "$skill_dir")
  local_skill="$SKILLS_DIR/$skill_name"
  if [ -d "$local_skill" ]; then
    cp -r "$skill_dir/"* "$local_skill/" 2>/dev/null
    UPDATED_SKILLS+=("$skill_name")
  fi
done

# Save new version
echo "$REMOTE_VERSION" > "$VERSION_FILE"
echo "$REMOTE_CHANGELOG" > "$CHANGELOG_CACHE"

# Clean up
rm -rf "$TEMP_DIR"

echo "$(date): Update complete. Skills updated: ${UPDATED_SKILLS[*]}" >> "$HOME/.openclaw/skills/.update-log"

# Notify via Telegram
SKILLS_LIST=$(printf '%s\n' "${UPDATED_SKILLS[@]}" | head -10 | sed 's/^/• /')
MESSAGE="✅ *OpenClaw Skills Updated*%0A%0AVersion: ${LOCAL_VERSION:-none} → $REMOTE_VERSION%0A%0A*What Changed:*%0A$(echo "$CHANGES" | head -15 | sed 's/$/\\n/' | tr -d '\n' | sed 's/#/\\#/g')%0A%0A*Skills Updated:*%0A$SKILLS_LIST%0A%0AFull changelog: $REPO_URL/blob/main/CHANGELOG.md"
send_telegram "$MESSAGE"

exit 0
