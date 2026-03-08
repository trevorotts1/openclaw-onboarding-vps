# GitHub / Git Setup - Core File Updates

Update ONLY the files listed below. Use the EXACT text provided.
Do not update files marked NO UPDATE NEEDED.

---

## AGENTS.md - UPDATE REQUIRED

Add:

```
## GitHub [PRIORITY: HIGH]
- Setup method: GitHub API + gh CLI where available
- PAT scopes: repo, read:org, workflow (least-privilege)
- Always create a branch for new work (never commit directly to main)
- Commit messages: descriptive, present tense
- Full guide: [MASTER_FILES_FOLDER]/OpenClaw Onboarding/10-github-setup/github-setup-full.md
```

---

## TOOLS.md - UPDATE REQUIRED

Add:

```
## Git & GitHub
- Token: $GITHUB_TOKEN | Username: $GITHUB_USERNAME (in secrets file)
- git status, git add ., git commit -m 'message', git push, git pull
- gh pr create, gh pr list, gh issue list, gh repo create
- API: https://api.github.com
- Full guide: [MASTER_FILES_FOLDER]/OpenClaw Onboarding/10-github-setup/github-setup-full.md
```

---

## MEMORY.md - UPDATE REQUIRED

Add:

```
## GitHub/Git Setup - Installed [DATE]
- Git configured (user.name, user.email, credential.helper=store)
- gh CLI configured where available
- PAT scopes: repo, read:org, workflow | Expiry: 90 days
- Full guide: [MASTER_FILES_FOLDER]/OpenClaw Onboarding/10-github-setup/github-setup-full.md
```

---

## IDENTITY.md - NO UPDATE NEEDED

---

## HEARTBEAT.md - NO UPDATE NEEDED

---

## USER.md - NO UPDATE NEEDED

---

## SOUL.md - NO UPDATE NEEDED
