# Superpowers - Core File Updates

Update ONLY the files listed below. Use the EXACT text provided.
Do not update files marked NO UPDATE NEEDED.

---

## WHERE TO INSERT CONTENT (READ THIS FIRST)

- **AGENTS.md** - Add at the TOP of the file, immediately after the first heading line (# AGENTS.md - Your Workspace)
- **TOOLS.md** - Add at the TOP of the file, immediately after the first heading line and the "Skills define..." line
- **MEMORY.md** - Add at the TOP of the file, immediately after the first heading line (# MEMORY.md)
- **IDENTITY.md** - Add at the BOTTOM of the file, before the final horizontal rule if one exists

Do NOT add to the middle of any file. Do NOT add at the bottom where it will be skipped.

---

## AGENTS.md - UPDATE REQUIRED

Add immediately after the first heading line:

```
## 🔴🔴🔴 SUPERPOWERS - THINKING DISCIPLINE (NON-NEGOTIABLE)
Source: https://github.com/obra/superpowers
Local skills: ~/Downloads/openclaw-master-files/superpowers/skills/
14 skill files. Read the relevant SKILL.md before any coding task.

### YOU DO NOT HAVE A CHOICE
If you think there is even a 1% chance a skill might apply to what you are doing,
you ABSOLUTELY MUST invoke the skill.
IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.
This is not negotiable. This is not optional. You cannot rationalize your way out of this.

### THE 4 IRON LAWS
1. No fixes without root cause investigation first
2. No production code without a failing test first
3. No completion claims without fresh verification evidence
4. No implementation without design approval

### THE HARD GATE (v4.3.0 - NON-NEGOTIABLE)
Do NOT invoke any implementation skill, write any code, scaffold any project,
or take any implementation action until you have presented a design and the user
has approved it. This applies to EVERY project regardless of perceived simplicity.
Every project goes through this process. "Simple" is where unexamined assumptions
cause the most wasted work.

### EnterPlanMode INTERCEPT
If you are about to enter plan mode, STOP. Check if brainstorming has happened first.
If brainstorming has not happened, invoke the brainstorming skill instead.
Never enter native plan mode without brainstorming first.

### RED FLAGS - STOP IF YOU ARE THINKING ANY OF THESE
These thoughts mean you are rationalizing skipping skills. Stop and invoke the skill.

| You are thinking | The reality |
|---|---|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This is too simple to need a design" | Simple = most unexamined assumptions = most wasted work. |
| "I know what that means" | Knowing the concept is not the same as using the skill. |

### SKILL PRIORITY ORDER
1. Process skills first (brainstorming, debugging) - determine HOW to approach
2. Implementation skills second - guide execution
"Let's build X" = brainstorming first, then implementation.
"Fix this bug" = systematic-debugging first, then fix.

### WORKFLOW MAP
- Building new: brainstorming -> writing-plans -> using-git-worktrees -> subagent-driven-development
- Bug fix: systematic-debugging (all 4 phases) -> fix -> verification-before-completion
- Writing code: test-driven-development (failing test FIRST, always)
- Claiming done: verification-before-completion (run it, show output)
- Reviewing code: requesting-code-review
- Merging: finishing-a-development-branch

### WORKTREE REQUIREMENT (v4.2.0 - NON-NEGOTIABLE)
using-git-worktrees MUST be invoked before subagent-driven-development or executing-plans.
Never begin implementation directly on main. Always create an isolated worktree first.
```

---

## TOOLS.md - UPDATE REQUIRED

Add immediately after the first heading line and opening description:

```
## Superpowers Skills Reference
- Full skills at: ~/Downloads/openclaw-master-files/superpowers/skills/
- Commands at: ~/Downloads/openclaw-master-files/superpowers/commands/
- Agents at: ~/Downloads/openclaw-master-files/superpowers/agents/
- 14 skills: brainstorming, systematic-debugging, test-driven-development, verification-before-completion, writing-plans, writing-skills, executing-plans, subagent-driven-development, dispatching-parallel-agents, using-git-worktrees, finishing-a-development-branch, receiving-code-review, requesting-code-review, using-superpowers
- 3 commands: brainstorm.md, execute-plan.md, write-plan.md
- 1 agent: code-reviewer.md
- Trigger map: Building new = brainstorming -> writing-plans. Bug = systematic-debugging. Code = test-driven-development. Done? = verification-before-completion.
- Worktree required: Always run using-git-worktrees before subagent-driven-development or executing-plans.
```

---

## MEMORY.md - UPDATE REQUIRED

Add immediately after the first heading line. Replace [TODAY] with today's date in human-readable format (example: March 8, 2026):

```
## Superpowers Installed [TODAY]
- Downloaded from https://github.com/obra/superpowers
- 14 skills + commands/ + agents/ + hooks/ - all verified
- Iron Laws are non-negotiable for all coding tasks
- Hard Gate: no code before design approval (v4.3.0)
- Worktree required before any implementation (v4.2.0)
- Full skills: ~/Downloads/openclaw-master-files/superpowers/skills/
```

---

## IDENTITY.md - UPDATE REQUIRED

Add at the bottom of the file:

```
## Thinking Discipline
I follow the Superpowers framework for all coding work. I investigate root cause before fixing.
I write tests before code. I verify before claiming done. I brainstorm before building.
I never start implementing until I have presented a design and the user has approved it.
I always create a git worktree before any implementation begins.
I do not have a choice when a skill applies. I use it.
```

---

## HEARTBEAT.md - NO UPDATE NEEDED

---

## USER.md - NO UPDATE NEEDED

---

## SOUL.md - NO UPDATE NEEDED
