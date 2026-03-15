# CORE_UPDATES.md - Paste These Into Your Core Files

> These are the only updates needed in core files. They are reference pointers only.
> Do NOT copy the master reference content into any core file.
> The master reference is 430K characters and will destroy your context window.
> Only TOOLS.md and MEMORY.md receive updates from this skill.

---

## TOOLS.md Update

Add this block to `/data/openclaw/workspace/TOOLS.md`:

```markdown
## Convert and Flow (GoHighLevel) API v2

- **Skill:** `/data/.openclaw/skills/29-ghl-convert-and-flow/`
- **Master reference (413 endpoints, 35 modules, 106 scopes):**
  `/data/openclaw-master-files/Convert and Flow - GoHighLevel API v2 Master Reference.md`
- **Base URL:** `https://services.leadconnectorhq.com`
- **Auth:** Private Integration Token (Bearer header) - API keys are DEPRECATED
- **Required header on most calls:** `Version: 2021-04-15`
- **Token stored in:** `/data/openclaw/workspace/secrets/.env` as `PRIVATE_INTEGRATION_TOKEN`

### Usage rule
Before any GHL API call: open the master reference file and search for the endpoint.
Do NOT rely on memory for endpoint paths, scopes, or required fields.
Never copy the master reference into any core .md file.

### Module quick-index
- contacts (32 endpoints): create/read/update/delete contacts, tags, tasks, notes
- conversations (19 endpoints): search, send messages, get message history
- calendars (34 endpoints): manage calendars, free slots, appointments
- opportunities (10 endpoints): pipeline management, create/update/search deals
- locations (29 endpoints): sub-account config, custom fields, users, tags
- Full module list: `/data/.openclaw/skills/29-ghl-convert-and-flow/references/modules.md`
```

---

## MEMORY.md Update

Add this block to `/data/openclaw/workspace/MEMORY.md`:

```markdown
## Convert and Flow API - Active Integration

- **Master reference:** `/data/openclaw-master-files/Convert and Flow - GoHighLevel API v2 Master Reference.md`
- **Skill folder:** `/data/.openclaw/skills/29-ghl-convert-and-flow/`
- **Token:** `/data/openclaw/workspace/secrets/.env` → `PRIVATE_INTEGRATION_TOKEN`
- **Location ID:** `/data/openclaw/workspace/secrets/.env` → `GHL_LOCATION_ID`
- **Stats:** 413 endpoints | 35 modules | 106 scopes
- **Auth method:** Private Integration Token (preferred) - API keys deprecated
- **Version header:** `Version: 2021-04-15` required on most endpoints

Load credentials before every call:
`source /data/openclaw/workspace/secrets/.env`
```
