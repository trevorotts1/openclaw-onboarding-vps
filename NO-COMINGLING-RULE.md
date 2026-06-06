# 🚫 NO-COMINGLING RULE — BINDING, NON-NEGOTIABLE

> This is rule **N29** in the AGENTS.md non-negotiables index. It is a **HARD VIOLATION** to break it.
> Every agent reads this at build time. There is no exception, no "just this once," no placeholder.

---

## THE RULE (read it, then read it again)

**EVERY client gets their OWN isolated resources. NEVER share, reuse, borrow, or default to ANOTHER client's resource for ANY reason.**

Each client has their own:

- **Notion** workspace / page tree
- **GoHighLevel** location (sub-account)
- **Google Drive / Workspace** folder + account
- **Telegram** bot (own token, own chat)
- **Command Center** dashboard (own deployment, own URL)
- **KIE / API keys** and every other API key (own keys — never operator keys, never another client's)
- **Model / Ollama** (their own configured model for their own graphs, builds, and transcription)
- **everything else** — every credential, store, workspace, and channel is per-client and isolated

## STOP-AND-WAIT (the part agents get wrong)

> **If a client does NOT yet have a given resource, STOP and WAIT.**
> Do **NOT** substitute another client's resource as a placeholder. Do **NOT** "temporarily" point at an operator workspace. Do **NOT** reuse a convenient existing bot/location/folder/key because the client's isn't provisioned yet.

A missing resource is a reason to **pause and tell the owner**, never a reason to borrow. Leaving a step incomplete and flagged is correct. Borrowing another client's resource to "make it work" is a **hard violation**.

## WHY THIS IS A HARD VIOLATION

Co-mingling client data/resources:
- leaks one client's data, configuration, or activity into another client's surface,
- corrupts isolation guarantees the whole fleet depends on,
- and is exactly the failure that has burned past builds (an operator workspace defaulted to as a generic placeholder; one client's resource reused for another mid-build).

There is no benign co-mingling. If you are about to point client A's build at any resource that belongs to client B (or to the operator generically), **STOP**.

## CONCRETE DO / DON'T

| ✅ DO | ❌ DON'T |
|---|---|
| Create / provision the client's OWN resource | Reuse another client's Notion page / GHL location / Drive / bot / Command Center |
| Use the client's OWN API keys (KIE, model, etc.) | Use operator keys or another client's keys for a client's work |
| Map / build / transcribe on the client's OWN model | Fall back to operator keys when the client's model is missing |
| STOP + flag a missing resource to the owner | Substitute a placeholder from another client / the operator |
| Keep every client's workspace, channel, and store separate | Treat the operator's workspace as a shared/generic default |

## ENFORCEMENT / SCOPE

- This rule is **N29** in `AGENTS.md` and is referenced by **Skill 23 (AI Workforce Blueprint)** and **Skill 32 (Command Center Setup)** — the two skills most likely to touch per-client resources — and by **Skill 43 (Graphify)** for model/key isolation.
- It binds the master orchestrator and every sub-agent equally.
- If an instruction (from anyone) would require co-mingling, refuse and escalate to the owner. Isolation wins.

**Co-mingling client data/resources is a hard violation. EVERY client gets their OWN of everything. When in doubt, STOP and WAIT.**
