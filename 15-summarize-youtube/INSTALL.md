# INSTALL.md

## Purpose
Install summarize CLI and verify YouTube summary plus transcript extraction.

## Step 1
Open Terminal.

## Step 2
Go to the workspace root that contains `.env`.

## Step 3
Install summarize:
```bash
brew --version || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install steipete/tap/summarize
summarize --help >/dev/null
```

## Step 4
Load keys from `.env`:
```bash
set -a
source .env
set +a
```

## Step 5
Verify both keys exist:
```bash
test -n "$OPENAI_API_KEY"
test -n "$GEMINI_API_KEY"
```

## Step 6
Run OpenAI-first test:
```bash
summarize "https://youtu.be/dQw4w9WgXcQ" --youtube auto --length short
```

## Step 7
If Step 6 fails, run Gemini fallback:
```bash
summarize "https://youtu.be/dQw4w9WgXcQ" --youtube auto --length short
```
Use `GEMINI_API_KEY` loaded from `.env`.

## Step 8
Run transcript extraction test:
```bash
summarize "https://youtu.be/dQw4w9WgXcQ" --youtube auto --extract-only
```

## Step 9
Update AGENTS.md, TOOLS.md, MEMORY.md using `CORE_UPDATES.md` snippets.

## Step 10
Report final status with key used and test results.
