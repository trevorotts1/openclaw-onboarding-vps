#!/bin/bash
# Sets up the weekly Sunday 2 AM skill update cron job
# Run this once after installing the onboarding package

SCRIPT_PATH="$HOME/.openclaw/skills/scripts/update-skills.sh"
LOG_PATH="$HOME/.openclaw/skills/.update-log"

# Copy script to permanent location
mkdir -p "$HOME/.openclaw/skills/scripts"
cp "$(dirname "$0")/update-skills.sh" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Create log file
touch "$LOG_PATH"

# Add cron job (Sundays at 2:00 AM)
CRON_JOB="0 2 * * 0 $SCRIPT_PATH >> $LOG_PATH 2>&1"

# Check if already exists
if crontab -l 2>/dev/null | grep -q "update-skills.sh"; then
  echo "Weekly update cron already installed."
else
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "✅ Weekly update cron installed: Sundays at 2:00 AM"
fi

echo "To check update logs: cat $LOG_PATH"
echo "To run an update check now: $SCRIPT_PATH"
