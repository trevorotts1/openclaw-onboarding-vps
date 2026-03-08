# BlackCEO Team Management Setup - Core File Updates

Update ONLY the files listed below. Use the EXACT text provided.
Do not update files marked NO UPDATE NEEDED.

TYP RULE: Add LEAN SUMMARIES + FILE PATH POINTERS to core files only.
Full protocol content lives in:
~/Downloads/[master-files-folder]/OpenClaw Onboarding/15-blackceo-team-management/blackceo-team-management-full.md
Team config lives in: ~/.openclaw/skills/15-blackceo-team-management/TEAM_CONFIG.md

---

## AGENTS.md - UPDATE REQUIRED

Add:

```
## Team Management - Dispatcher Protocol [PRIORITY: CRITICAL]
- Main session = dispatcher. Each person gets a dedicated worker sub-agent.
- Routing table: ~/clawd/WORKFLOW_AUTO.md
- Team config (source of truth): ~/.openclaw/skills/15-blackceo-team-management/TEAM_CONFIG.md
- Dispatcher has full cross-worker visibility via sessions_history
- Workers operate in isolated context windows. No conversation data from one worker bleeds into another.
- Workers CAN send directed Telegram messages to any ID when explicitly asked. There is no messaging lockdown - only context isolation.
- Full protocol: [MASTER_FILES_FOLDER]/OpenClaw Onboarding/15-blackceo-team-management/blackceo-team-management-full.md

### Team Members (fill in from TEAM_CONFIG.md during setup)
| Name | Telegram ID | Role | Worker Label |
|------|-------------|------|-------------|
(Populated during Step 0 intake - see INSTALL.md)

### Context Isolation Rule (NOT Communication Lockdown)
- Worker conversation data is STRICTLY isolated per worker. One worker's context NEVER leaks to another.
- Directed sends are ALWAYS allowed: if any team member says "send [name] a message" or "tell [person] X," execute the Telegram send immediately.
- "Cross-posting" means auto-sharing results without being asked. It does NOT mean blocking directed sends.
- Workers CAN use the message tool to send to any Telegram ID when explicitly asked.
- Workers CANNOT read, reference, or expose another worker's conversation history.
```

---

## TOOLS.md - UPDATE REQUIRED

Add:

```
## Team Dispatcher - Message Routing
- WORKFLOW_AUTO.md: ~/clawd/WORKFLOW_AUTO.md (routing table)
- Team config: ~/.openclaw/skills/15-blackceo-team-management/TEAM_CONFIG.md
- To send to specific person: message tool with target = their Telegram ID
- Worker results go ONLY to the requesting DM
- Full protocol: [MASTER_FILES_FOLDER]/OpenClaw Onboarding/15-blackceo-team-management/blackceo-team-management-full.md
```

---

## MEMORY.md - UPDATE REQUIRED

Add:

```
## Team Management - Installed [DATE]
- Dispatcher architecture configured
- Routing table: ~/clawd/WORKFLOW_AUTO.md
- Team config (source of truth): ~/.openclaw/skills/15-blackceo-team-management/TEAM_CONFIG.md
- Context isolation: Workers have isolated context windows (no data bleed between workers). Workers CAN send directed messages to any Telegram ID when explicitly asked - isolation is context only, not communication lockdown.
- Full protocol: [MASTER_FILES_FOLDER]/OpenClaw Onboarding/15-blackceo-team-management/blackceo-team-management-full.md

### Team Members (fill in from TEAM_CONFIG.md during setup)
| Name | Telegram ID | Role |
|------|-------------|------|
(Populated during Step 0 intake - see INSTALL.md)
```

---

## IDENTITY.md - NO UPDATE NEEDED

---

## HEARTBEAT.md - NO UPDATE NEEDED

(Team routing is session-aware via AGENTS.md. No heartbeat entry required.)

---

## USER.md - NO UPDATE NEEDED

(Team member data lives in TEAM_CONFIG.md, not USER.md. USER.md is for the primary operator only.)

---

## SOUL.md - NO UPDATE NEEDED
