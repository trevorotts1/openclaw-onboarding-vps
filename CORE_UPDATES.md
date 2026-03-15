# Core Updates - Base Installation

These updates apply to ALL installations regardless of which skills are installed.
Add these to your core workspace files after running install.sh.

## AGENTS.md

**Where:** Add at the bottom of AGENTS.md

**Exact text to add:**
```
## OpenClaw Onboarding Skills - Installed
Skills folder: /data/.openclaw/skills/
Version: [check /data/.openclaw/skills/.onboarding-version]
Weekly auto-update: Sundays at 2:00 AM (check with: crontab -l | grep update-skills)

## Pending Skill Setup - Check and Remind
File: /data/.openclaw/skills/.pending-setup.md
If this file exists with entries marked Status: PENDING, proactively remind the user.
When relevant to what they are working on, say: "You have a pending skill setup for [key] - want to add that now?"
When user provides the key: save it to /data/openclaw/workspace/secrets/.env and mark the entry Status: COMPLETE.
Never nag - bring it up once per session max, only when relevant.
```

## MEMORY.md

**Where:** Add under installed skills

**Exact text to add:**
```
## OpenClaw Onboarding Installed ([DATE])
Skills: /data/.openclaw/skills/
Version: [check /data/.openclaw/skills/.onboarding-version]
Pending setup: /data/.openclaw/skills/.pending-setup.md (check if any skills need API keys)
Weekly updates: Sundays 2 AM automatic, logs at /data/.openclaw/skills/.update-log
Repo: https://github.com/trevorotts1/openclaw-onboarding
```
