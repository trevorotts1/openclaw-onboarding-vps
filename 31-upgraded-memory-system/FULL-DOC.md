# Upgraded Memory System - Complete Reference

This is the combined reference document for Skill 31. It contains all documentation in reading order. Use this as a single-file reference instead of reading individual files.

---

---

# === SKILL.md ===

# Skill 31: Upgraded Memory System (8-Layer Architecture)

## What This Skill Is About

This skill upgrades your OpenClaw agent from the default memory system to an 8-layer architecture that makes your agent genuinely remember everything, find information accurately, and improve over time. The default memory system works okay at first but degrades as memory grows. This fixes that.

## When to Use This Skill

- You are setting up a new OpenClaw installation and want the best memory from day one
- Your agent keeps forgetting things you told it
- Memory search returns irrelevant results
- Important information gets lost during compaction
- You want your agent to automatically capture and recall memory without being told
- You are migrating from the old Google Embedding 2 retrieval query system to Google Gemini Embedding 2

## The 8 Layers

| Layer | What It Does | How It Works |
|-------|-------------|--------------|
| 1. Markdown files | Stores the source of truth | MEMORY.md (long-term) and daily logs (memory/YYYY-MM-DD.md) |
| 2. Memory flush | Saves important context before compaction | Custom prompt with 8 categories tells the agent exactly what to capture |
| 3. Session indexing | Makes past conversations searchable | Agent can search what you talked about last week, not just today |
| 4. Gemini Embedding 2 | Finds information by meaning | Google's multimodal embedding API replaces the old local search |
| 5. memory-core | Auto-captures and auto-recalls memory | Native OpenClaw memory system - survives compaction, no external dependencies |
| 6. Cognee | Graph-based knowledge relationships | Connects facts, people, projects in a graph database for complex queries |
| 7. Obsidian Vault | Structured knowledge base | Obsidian-compatible markdown with wikilinks, frontmatter, and daily notes |
| 8. Wiki System | Collaborative documentation | Memory wiki with deterministic pages, managed blocks, and source-backed updates |

## Files in This Folder and Reading Order

1. **SKILL.md** - You are here. Overview and context.
2. **INSTALL.md** - Step-by-step installation for all 8 layers.
3. **INSTRUCTIONS.md** - How to use and maintain the memory system after installation.
4. **EXAMPLES.md** - Example searches, flush outputs, and memory operations.
5. **CORE_UPDATES.md** - What to add to AGENTS.md, TOOLS.md, and MEMORY.md.
6. **upgraded-memory-system.skill** - Skill metadata file.

## Prerequisites

| Prerequisite | Required For | How to Check |
|-------------|-------------|--------------|
| Teach Yourself Protocol (TYP) | All skills | Check AGENTS.md for "Teach Yourself Protocol" |
| Google API key | Layer 4 (Gemini search) | `echo $GOOGLE_API_KEY` returns a key starting with AIza |
| Python 3.8+ | Layer 4 (Gemini search) | `python3 --version` |
| google-genai + numpy | Layer 4 (Gemini search) | `python3 -c "import google.genai; import numpy"` |
| OpenClaw running | All layers | `openclaw status` shows gateway running |

## Prerequisite Handling

**If prerequisites are NOT met:** Install all skill files anyway. Mark the skill as INSTALLED but NOT IMPLEMENTED. Add a note to AGENTS.md listing which prerequisites are missing. The agent should remind the user once per session until prerequisites are met.

**If prerequisites ARE met:** Install and implement fully. Run verification tests for each layer.

## Key Things the AI Agent Must Know

1. All 8 layers run simultaneously. They do not compete. Each solves a different problem.
2. Layer 4 (Gemini Embedding 2) replaces the old Google Embedding 2 retrieval query engine. Google Embedding 2 is deprecated.
3. Layer 5 (memory-core) is the native OpenClaw memory system. It replaces the legacy memory plugin.
4. Layers 6-8 (Cognee, Obsidian Vault, Wiki System) are advanced add-ons that extend memory capabilities.
4. The memory flush prompt must include explicit categories or it saves junk.
5. Session indexing adds noise, so the flush prompt is even more important as a filter.
6. If migrating from Google Embedding 2: run the migration steps in INSTALL.md before enabling Layer 4.
7. Cognee (Layer 6) requires Docker. Install only if you need graph-based knowledge relationships.

---

# === INSTALL.md ===

# Upgraded Memory System - Installation (8-Layer)

## Prerequisite Check

Before installing, check these prerequisites. If any are missing, still install the skill files but mark the skill as PENDING.

```bash
# Check 1: Google API Key
echo $GOOGLE_API_KEY
# Expected: starts with AIza... If empty, MARK AS PENDING.

# Check 2: Python SDK
python3 -c "from google import genai; import numpy; print('SDK ready')"
# Expected: "SDK ready". If error, run: pip3 install google-genai numpy

# Check 3: OpenClaw running
openclaw status | grep "Gateway service"
# Expected: shows "running"
```

**If Check 1 fails:** Tell the user:
"Layer 4 (Gemini search) requires a Google API key. Get one free at https://aistudio.google.com/app/apikey and set it: export GOOGLE_API_KEY='AIza...' in your ~/.zshrc. I will install the skill files now, but Layer 4 will not be active until the key is set."

**If Check 2 fails:** Run `pip3 install google-genai numpy` and retry.

**If all checks pass:** Proceed with full installation.

---

## Layer 1: Markdown Files (Source of Truth)

### 1.1 Verify MEMORY.md exists

```bash
ls -la /data/clawd/MEMORY.md
```

If MEMORY.md does not exist, create it:

```bash
cat > /data/clawd/MEMORY.md << 'EOF'
# MEMORY.md

> This file contains persistent state, lessons learned, and project status ONLY.
> - Behavior rules: See AGENTS.md
> - Tool setup/API credentials: See TOOLS.md
> - Who I am: See IDENTITY.md
> - Who you are: See USER.md

EOF
```

### 1.2 Verify daily log directory exists

```bash
mkdir -p /data/clawd/memory
```

### 1.3 Verify core files exist

Check that these files are present. If any are missing, create them from the templates in the onboarding package:

- /data/clawd/MEMORY.md
- /data/clawd/AGENTS.md
- /data/clawd/TOOLS.md
- /data/clawd/USER.md
- /data/clawd/SOUL.md
- /data/clawd/IDENTITY.md
- /data/clawd/HEARTBEAT.md

---

## Layer 2: Memory Flush (Improved Compaction)

### 2.1 Update the flush prompt in openclaw.json

Open `~/.openclaw/openclaw.json` and find the `compaction.memoryFlush` section under `agents.defaults`. Replace the prompt and systemPrompt with these values:

**prompt:**
```
Write a durable session note to memory/YYYY-MM-DD.md. Capture: decisions, constraints, open questions, owners, and any state that would break the plan if forgotten. If nothing meaningful happened, write NO_FLUSH.

Store durable memories only in memory/YYYY-MM-DD.md (create memory/ if needed).

If memory/YYYY-MM-DD.md already exists, APPEND new content only and do not overwrite existing entries.

Treat workspace bootstrap/reference files such as MEMORY.md, SOUL.md, TOOLS.md, and AGENTS.md as read-only during this flush; never overwrite, replace, or edit them.

If no user-visible reply is needed, start with NO_REPLY.
```

**systemPrompt:**
```
Be terse. Prefer bullet points. Do not rewrite the conversation.

Capture these categories if present:
- People and relationships (names, roles, who reports to whom, contact details mentioned)
- Credentials and access (API keys configured, services connected, auth methods)
- Project status (what shipped, what's blocked, what's next)
- Decisions made (and who made them)
- Preferences discovered (formatting, communication style, tool choices)
- Things that went wrong (errors, mistakes, lessons learned)
- Financial information (costs, credits, balances mentioned)
- Deadlines and commitments (dates promised, schedules agreed to)

Do NOT store: routine greetings, small talk, repeated context already in MEMORY.md, or speculative plans that were never confirmed.
```

### 2.2 Set the soft threshold

In the same `memoryFlush` block, set:

```json
"softThresholdTokens": 32000
```

This triggers the flush when the context reaches 32K tokens.

---

## Layer 3: Session Indexing (Past Conversations Searchable)

### 3.1 Enable session memory

In `~/.openclaw/openclaw.json`, find the `agents.defaults.memorySearch` section. Add or verify these settings:

```json
"memorySearch": {
  "enabled": true,
  "sources": ["memory", "sessions"],
  "experimental": {
    "sessionMemory": true
  }
}
```

### 3.2 Configure sync behavior

In the same `memorySearch` block, add:

```json
"sync": {
  "onSessionStart": true,
  "onSearch": true,
  "watch": true,
  "watchDebounceMs": 1200,
  "sessions": {
    "deltaBytes": 20000,
    "deltaMessages": 10
  }
}
```

---

## Layer 4: Gemini Embedding 2 (Semantic Search)

**Skip this layer if GOOGLE_API_KEY is not set. Mark as PENDING.**

### 4.1 Set the search provider

In `~/.openclaw/openclaw.json`, find the `agents.defaults.memorySearch` section. Add or update:

```json
"provider": "gemini",
"model": "models/gemini-embedding-2-preview"
```

### 4.2 Set the memory backend

Find the top-level `memory` section in openclaw.json and set:

```json
"memory": {
  "backend": "builtin"
}
```

**Important:** There may be TWO places where the backend is configured. The top-level `memory.backend` AND the `agents.defaults.memorySearch.provider`. The `memory.backend` should be "builtin" (for memory-core) and `memorySearch.provider` should be "gemini". If the top-level still says "google embedding 2", the search will fail even if memorySearch says "gemini".

### 4.3 Configure search quality

In the `memorySearch` section, add:

```json
"query": {
  "maxResults": 50,
  "minScore": 0.18,
  "hybrid": {
    "enabled": true,
    "vectorWeight": 0.75,
    "textWeight": 0.25,
    "candidateMultiplier": 8
  }
}
```

---

## Layer 5: memory-core (Native Memory System)

Layer 5 uses OpenClaw's built-in memory-core instead of the legacy memory plugin.

### 5.1 Verify memory-core is enabled

In `~/.openclaw/openclaw.json`, verify the memory backend:

```json
"memory": {
  "backend": "builtin"
}
```

### 5.2 Configure auto-capture

In `~/.openclaw/openclaw.json`, under `agents.defaults`, add:

```json
"memory": {
  "autoCapture": true,
  "autoRecall": true
}
```

### 5.3 Verify memory-core status

```bash
openclaw memory status
```

Expected output should show:
- Backend: builtin
- Provider: gemini
- Auto-capture: enabled
- Auto-recall: enabled

---

## Layer 6: Cognee (Graph-Based Knowledge)

**Requires Docker. Skip if Docker is not available.**

### 6.1 Check Docker availability

```bash
docker --version
```

If Docker is not installed, Layer 6 will be marked as PENDING.

### 6.2 Install Cognee

```bash
openclaw plugins install @openclaw/cognee
```

### 6.3 Configure Cognee

In `~/.openclaw/openclaw.json`, under `plugins.entries`:

```json
"cognee": {
  "enabled": true,
  "config": {
    "connection_string": "sqlite:///data/cognee.db",
    "llm_provider": "gemini",
    "llm_model": "gemini-3-flash-preview"
  }
}
```

### 6.4 Start Cognee container

```bash
openclaw cognee start
```

### 6.5 Verify Cognee is running

```bash
openclaw cognee status
```

Expected: Status shows "connected" with graph statistics.

---

## Layer 7: Obsidian Vault (Structured Knowledge Base)

### 7.1 Check if Obsidian is installed (Linux)

```bash
which obsidian 2>/dev/null || flatpak list 2>/dev/null | grep -i obsidian
```

If Obsidian is not installed, you can download it from https://obsidian.md or install via flatpak: `flatpak install flathub md.obsidian.Obsidian`

### 7.2 Create or identify vault location

Default vault location:
```bash
mkdir -p ~/Documents/ObsidianVault
```

Or use an existing vault:
```bash
ls ~/Documents/ | grep -i obsidian
```

### 7.3 Configure Obsidian integration

In `~/.openclaw/openclaw.json`, add:

```json
"obsidian": {
  "enabled": true,
  "vaultPath": "/home/USERNAME/Documents/ObsidianVault",
  "dailyNotes": true,
  "wikilinks": true
}
```

Replace USERNAME with your actual username.

### 7.4 Verify vault access

```bash
openclaw obsidian status
```

Expected: Shows vault path, note count, and daily notes status.

---

## Layer 8: Wiki System (Collaborative Documentation)

### 8.1 Enable wiki system

In `~/.openclaw/openclaw.json`, add:

```json
"wiki": {
  "enabled": true,
  "vaultPath": "/home/USERNAME/.openclaw/wiki",
  "backend": "sqlite"
}
```

### 8.2 Initialize wiki vault

```bash
openclaw wiki init
```

### 8.3 Configure wiki sync

```bash
openclaw wiki config set autoSync true
openclaw wiki config set syncInterval 300
```

### 8.4 Verify wiki system

```bash
openclaw wiki status
```

Expected: Shows vault initialized, sync enabled, page count.

---

## Migration from Google Embedding 2 (Existing Users Only)

If the user previously had Google Embedding 2 installed, follow these additional steps:

### M.1 Check for existing Google Embedding 2

```bash
which google embedding 2 2>/dev/null && echo "Google Embedding 2 found" || echo "No Google Embedding 2 installed"
ls ~/.cache/google embedding 2/index.sqlite 2>/dev/null && echo "Google Embedding 2 index found" || echo "No Google Embedding 2 index"
```

### M.2 If Google Embedding 2 is present, update the backend

The config change in Layer 4 (Step 4.2) handles this. Verify `memory.backend` is "builtin", not "google embedding 2".

### M.3 Clean up old Google Embedding 2 (optional)

```bash
# Backup first (recommended)
mv ~/.cache/google embedding 2/ ~/.cache/google embedding 2-backup/

# Or remove entirely
rm -rf ~/.cache/google embedding 2/
```

---

## Post-Installation Verification

After all layers are installed, run these checks:

```bash
# Layer 1: Markdown files exist
ls /data/clawd/MEMORY.md /data/clawd/memory/

# Layer 2: Flush prompt is configured
grep "memoryFlush" ~/.openclaw/openclaw.json | head -1

# Layer 3: Session indexing is on
grep "sessionMemory" ~/.openclaw/openclaw.json

# Layer 4: Gemini provider is set (skip if GOOGLE_API_KEY not set)
grep '"backend"' ~/.openclaw/openclaw.json
grep '"provider"' ~/.openclaw/openclaw.json | grep gemini

# Layer 5: memory-core is enabled
openclaw memory status | grep -E "Backend|autoCapture|autoRecall"

# Layer 6: Cognee is running (if Docker available)
openclaw cognee status 2>/dev/null || echo "Cognee not running (may need Docker)"

# Layer 7: Obsidian is installed (Linux)
which obsidian 2>/dev/null || flatpak list 2>/dev/null | grep -i obsidian && echo "Obsidian installed" || echo "Obsidian not installed"

# Layer 8: Wiki system is initialized
openclaw wiki status 2>/dev/null || echo "Wiki not initialized"
```

### Gateway Restart

After all configuration changes:

```
Tell the user: "I need you to restart the OpenClaw gateway for the memory upgrades to take effect. Please type /restart in Telegram or run: openclaw gateway restart"
```

Do NOT restart the gateway yourself. Ask the user to do it.

### Final Test

After restart, test the memory system:

```
Ask the agent: "Search your memory for [any topic the user has discussed before]"
```

If results come back, all layers are working.

---

### Rollback Procedure (If Layer Tests Fail)

If any layer test fails after the config changes and restart:

#### Pre-Surgery Backup

Before making any config changes, create a backup:
```bash
mkdir -p ~/.openclaw/backups
cp ~/.openclaw/openclaw.json ~/.openclaw/backups/openclaw-$(date +%Y%m%d-%H%M%S).json
```

#### Layer 4 failure (search returns nothing, wrong provider, or config crash)

1. Restore the config backup you created before making changes:
   ```bash
   cp ~/.openclaw/backups/openclaw-*.json ~/.openclaw/openclaw.json
   ```
2. Ask the user to type /restart
3. Report to the user what failed and what was rolled back
4. Do NOT attempt to re-apply the changes until the root cause is diagnosed

#### Layer 5 failure (memory-core not enabled)

1. Check memory backend config: `openclaw memory status`
2. Verify openclaw.json has `"memory": { "backend": "builtin" }`
3. If config is wrong, correct it and ask the user to type /restart
4. memory-core is built-in; no plugin installation needed

#### Config validation failure (openclaw config validate says invalid)

1. Do NOT ask the user to restart
2. Immediately restore from backup:
   ```bash
   cp ~/.openclaw/backups/openclaw-*.json ~/.openclaw/openclaw.json
   ```
3. Re-validate: `openclaw config validate`
4. Report to the user exactly what value caused the failure
5. Only proceed after the invalid value is identified and corrected

#### General rollback rules

- Always have a backup BEFORE making config changes (this is mandatory in the install steps above)
- If you are unsure what broke, restore the full backup and start diagnosis from a known-good state
- Never leave the user on an invalid config. Restore first, debug second.
- Report every rollback action to the user in Telegram with a clear explanation of what happened and why

---

## Completion Checklist

```
[ ] Layer 1: MEMORY.md exists and has content
[ ] Layer 1: memory/ directory exists with daily logs
[ ] Layer 2: Flush prompt updated with 8 categories
[ ] Layer 3: sessionMemory enabled
[ ] Layer 4: memory.backend set to "builtin" (or PENDING if no API key)
[ ] Layer 4: memorySearch.provider set to "gemini" (or PENDING if no API key)
[ ] Layer 5: memory-core enabled with autoCapture and autoRecall
[ ] Layer 6: Cognee installed and running (or PENDING if no Docker)
[ ] Layer 7: Obsidian vault configured (app check: which obsidian || flatpak list | grep -i obsidian)
[ ] Layer 8: Wiki system initialized and syncing
[ ] Gateway restarted by user
[ ] Memory search test returned results
[ ] Core files updated (see CORE_UPDATES.md)
```

---

# === CORE_UPDATES.md ===

# Upgraded Memory System - Core File Updates

## Add to MEMORY.md

```markdown
## Upgraded Memory System (8 Layers) - Installed [DATE]

| Layer | Component | Status |
|-------|-----------|--------|
| 1 | Markdown files (MEMORY.md + daily logs) | Active |
| 2 | Memory flush (8-category capture prompt) | Active |
| 3 | Session indexing (past conversations searchable) | Active |
| 4 | Gemini Embedding 2 (semantic search) | Active / PENDING |
| 5 | memory-core (native auto-capture + auto-recall) | Active |
| 6 | Cognee (graph-based knowledge) | Active / PENDING |
| 7 | Obsidian Vault (structured knowledge base) | Active |
| 8 | Wiki System (collaborative documentation) | Active |

- Layer 4 provider: gemini, model: models/gemini-embedding-2-preview
- Layer 5: memory-core backend (replaces the legacy memory plugin)
- Layer 6: Cognee requires Docker; marked PENDING if unavailable
- Layer 7: Obsidian app check via `which obsidian || flatpak list | grep -i obsidian` (Linux)
- Layer 8: Wiki vault with deterministic pages and managed blocks
- All 8 layers run simultaneously. They solve different problems.
- Weekly maintenance: clean MEMORY.md, remove stale entries
- Monthly maintenance: prune daily logs older than 90 days
```

## Add to AGENTS.md

```markdown
## Memory System Rules
- Do NOT disable any of the 8 memory layers without explicit permission
- Memory flush captures 8 categories: people, credentials, project status, decisions, preferences, errors, finances, deadlines
- Session indexing is enabled. Past conversations are searchable.
- Search backend is Gemini Embedding 2 (not Google Embedding 2). Config: memory.backend = "builtin", memorySearch.provider = "gemini"
- memory-core (Layer 5) handles auto-capture and auto-recall. Do not rely on manual memory saves alone.
- MEMORY.md is the long-term source of truth. Daily logs are session-specific.
- If MEMORY.md gets longer than 1500 lines, consolidate and trim old entries.
- Cognee (Layer 6) provides graph-based knowledge relationships for complex queries.
- Obsidian Vault (Layer 7) maintains structured knowledge with wikilinks and frontmatter.
- Wiki System (Layer 8) enables collaborative documentation with source-backed updates.
```

## Add to TOOLS.md

```markdown
## Memory Search
- Backend: Google Gemini Embedding 2 (API, no local database)
- Provider config: agents.defaults.memorySearch.provider = "gemini"
- Top-level config: memory.backend = "builtin"
- Model: models/gemini-embedding-2-preview
- Requires: GOOGLE_API_KEY environment variable
- Hybrid search: 75% vector weight, 25% text weight
- memory-core (Layer 5): Native OpenClaw memory with auto-capture and auto-recall
- Cognee (Layer 6): Graph-based knowledge relationships (requires Docker)
- Obsidian Vault (Layer 7): Structured knowledge base with wikilinks
- Wiki System (Layer 8): Collaborative docs with deterministic pages
```

---

# === HOW-YOUR-MEMORY-WORKS.md ===

# How Your AI Memory System Works

Your AI assistant has an 8-layer memory system. Each layer solves a different problem. They all work together automatically. Here is what each one does and why it matters.

---

## Layer 1: Your Files

Your assistant stores important information in files on your computer. There are two types:

- **MEMORY.md** is the long-term file. It holds permanent information like your preferences, important decisions, project status, and lessons learned. Think of it like a notebook that never gets thrown away.

- **Daily logs** are short-term files that capture what happens each day. They are stored in a folder called memory/ with one file per day. These are like a daily journal.

**Why it matters:** Without these files, your assistant would forget everything between conversations.

---

## Layer 2: Smart Saving

When a conversation gets long, your assistant needs to make room for new information. Before it does, it automatically saves the important parts to your daily log file.

It knows to save things like:
- Decisions you made
- People and relationships mentioned
- Credentials and accounts discussed
- Project updates
- Mistakes and how they were fixed
- Deadlines and commitments

It also knows NOT to save small talk, greetings, or things already saved before.

**Why it matters:** Without smart saving, your assistant would lose important context from long conversations.

---

## Layer 3: Conversation History Search

Your assistant can search through past conversations, not just the current one. If you talked about something last week, it can find it.

This works automatically. When you ask a question, your assistant checks previous conversations for relevant context before responding.

**Why it matters:** Without this, your assistant only knows what happened in today's conversation.

---

## Layer 4: Intelligent Search

Your files are searchable using Google's Gemini Embedding 2 technology. This is not a simple keyword search. It understands meaning.

For example, if you search for "marketing budget," it will also find notes about "ad spend," "campaign costs," or "quarterly marketing allocation" even if those exact words were not in your search.

It works with markdown documents, images, and audio files.

**Why it matters:** As your knowledge base grows, simple search stops working. Intelligent search finds what you need even when you do not remember the exact words.

---

## Layer 5: Automatic Memory (memory-core)

Your assistant automatically notices and remembers important information during conversations. It does not wait for you to say "remember this." It captures things like preferences, decisions, and facts on its own.

When you start a new conversation, it automatically recalls relevant memories before responding. You do not need to remind it.

This layer uses OpenClaw's native memory-core system, which replaced the legacy memory plugin.

**Why it matters:** Without this, you would have to repeat yourself every time you start a new conversation.

---

## Layer 6: Graph Knowledge (Cognee)

Cognee creates a graph database of relationships between facts, people, projects, and concepts. Instead of just finding documents, it can answer complex questions like "What projects is Sarah working on that involve marketing budgets?"

It connects the dots between separate pieces of information that might never appear in the same document.

**Why it matters:** Simple search finds documents. Graph knowledge finds answers that span multiple documents and relationships.

---

## Layer 7: Obsidian Vault (Structured Notes)

Your assistant maintains an Obsidian-compatible vault with structured notes, wikilinks between related concepts, and frontmatter metadata. This makes it easy to browse and explore your knowledge base visually.

Daily notes capture what happened each day. Topic notes organize information by subject. Wikilinks connect related ideas.

**Why it matters:** A well-organized vault makes your knowledge browseable and discoverable, not just searchable.

---

## Layer 8: Wiki System (Collaborative Docs)

The wiki system provides deterministic pages with managed blocks and source-backed updates. Unlike free-form notes, wiki pages follow a structure that ensures consistency and enables collaboration.

Changes are tracked, sources are cited, and updates follow a predictable pattern. This is ideal for documentation that multiple people (or agents) might edit.

**Why it matters:** Structured documentation with provenance tracking ensures information stays accurate and attributable.

---

## How They Work Together

Here is an example of all 8 layers working at once:

You ask your assistant: "What did we decide about the marketing budget last week?"

1. **Layer 1** has the permanent notes in MEMORY.md
2. **Layer 2** saved the conversation details to last week's daily log when the conversation ended
3. **Layer 3** searches through last week's actual conversation transcript
4. **Layer 4** uses intelligent search to find related notes across all your files
5. **Layer 5** automatically recalled relevant memories before you even finished typing
6. **Layer 6** (Cognee) checks if there are related projects, people, or budget connections
7. **Layer 7** (Obsidian Vault) looks for any linked notes about marketing or budgets
8. **Layer 8** (Wiki System) checks for any formal documentation about budget decisions

Your assistant combines all of this to give you a complete, accurate answer.

---

## Maintenance

Your assistant handles most maintenance automatically. Two things happen periodically:

- **MEMORY.md cleanup**: When the file gets very long (over 1500 lines), old or redundant entries are consolidated to keep it manageable.
- **Daily log pruning**: Logs older than 90 days are cleaned up to save space.

Your assistant will tell you before making any major changes to these files.

---

## If Something Seems Wrong

If your assistant seems to be forgetting things or not finding information it should know:

1. Ask it: "Check your memory system status"
2. It will test each layer and report what is working and what is not
3. Most issues are fixed by typing `/restart` in Telegram

If a restart does not fix it, ask your assistant to run a full memory diagnostic.

<!-- Breadcrumb: skill-31-vps | FULL-DOC.md | Updated to v7.0.0 8-layer architecture with Linux Obsidian check by skill-31-vps on 2026-04-12 -->
