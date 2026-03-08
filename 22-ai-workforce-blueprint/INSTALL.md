# Installing the AI Workforce Blueprint Skill

## Prerequisites
- OpenClaw installed and running
- A workspace folder (e.g., `~/Downloads/my-ai-workforce/` or wherever your business files live)
- Python 3.8+ (for the automated scaffold script)

## Installation Steps

### Step 1 - Download the skill
```bash
curl -L https://github.com/trevorotts1/openclaw-onboarding/archive/refs/heads/main.zip -o ~/Downloads/openclaw-onboarding.zip
unzip ~/Downloads/openclaw-onboarding.zip -d ~/Downloads/
```

### Step 2 - Copy skill to your skills folder
```bash
cp -r ~/Downloads/openclaw-onboarding-main/22-ai-workforce-blueprint ~/.openclaw/skills/
```

### Step 3 - Tell your AI to read the skill
Say to your AI: "Read the AI Workforce Blueprint skill at ~/.openclaw/skills/22-ai-workforce-blueprint/SKILL.md"

### Step 4 - Start your workforce build
Say to your AI: "Build my AI workforce. Use Option A."

Your AI will ask you questions about your business and create the full folder structure.

## What Happens After Install
- Your AI knows the full blueprint system and can build or audit department structures
- You can say "add a new department" at any time and the AI knows exactly what files to create
- The skill works standalone - no personas or other skills required

## To Add a New Department Later
Just say: "Add a [department name] department to my workforce structure."
Your AI will create the folder, role subfolders, and all required files.
