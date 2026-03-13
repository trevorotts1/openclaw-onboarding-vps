#!/usr/bin/env python3
"""
AI Workforce Blueprint - Scaffold Builder
Creates the full department/role folder structure with starter files.
Auto-detects Coaching Personas Matrix and wires governing personas per department.
Run: python3 build-workforce.py
"""

import os
import sys
import subprocess
import json

DEPT_SUFFIX = "-dept"

# Pre-built departments with descriptions
PREBUILT_DEPARTMENTS = {
    "marketing": "Content, ads, social media, email campaigns",
    "sales": "Converting leads to customers",
    "billing": "Invoicing, payments, financial tracking",
    "customer-support": "Helping existing clients",
    "operations": "Day-to-day business running",
    "creative": "Graphics, video, content creation",
    "hr-people": "Team management, hiring",
    "legal-compliance": "Contracts, regulations",
    "it-tech": "Software, websites, infrastructure",
    "master-orchestrator": "Routes all work (always included)",
}

# Department → Governing Personas mapping
# Personas listed in priority order (most relevant first)
DEPT_PERSONAS = {
    "sales": [
        ("hormozi-100m-offers", "Offer design, pricing, value stacking"),
        ("voss-never-split-difference", "Negotiation, objection handling, difficult conversations"),
        ("rackham-spin-selling", "Discovery calls, consultative selling, needs analysis"),
        ("pink-to-sell-is-human", "Persuasion, moving people, pitching"),
        ("jones-exactly-what-to-say", "Magic words, closing language, exact phrasing"),
        ("priestley-oversubscribed", "Demand generation, positioning, being sought after"),
        ("kane-hook-point", "Attention, hooks, getting noticed in a crowded market"),
    ],
    "marketing": [
        ("miller-building-storybrand-2", "Brand messaging, clarity, customer story"),
        ("godin-this-is-marketing", "Permission marketing, being seen, serving an audience"),
        ("bly-copywriters-handbook", "Copywriting, conversion copy, direct response"),
        ("wiebe-copy-hackers", "Value proposition, website copy, conversion optimization"),
        ("cialdini-influence", "Persuasion psychology, social proof, reciprocity"),
        ("charvet-words-change-minds", "Language patterns, NLP, communication styles"),
    ],
    "leadership": [
        ("sinek-start-with-why", "Why-driven leadership, purpose, inspiring action"),
        ("sinek-find-your-why", "Team purpose, finding and articulating why"),
        ("collins-good-to-great", "Building great companies, disciplined strategy"),
        ("grover-relentless", "Elite performance, relentless execution, standards"),
        ("lakhiani-extraordinary-mind", "Rewriting rules, extraordinary thinking"),
        ("samit-disrupt-yourself", "Innovation, personal disruption, reinvention"),
    ],
    "operations": [
        ("clear-atomic-habits", "Habit building, systems, behavior change"),
        ("forte-building-second-brain", "Second brain, PKM, knowledge management"),
        ("forte-para-method", "PARA organization system, folder structure"),
        ("moran-12-week-year", "12-week execution, goal sprints, accountability"),
        ("duhigg-power-of-habit", "Habit loops, cue-routine-reward, organizational habits"),
        ("pink-when", "Timing, when to schedule tasks, energy management"),
    ],
    "ops": [
        ("clear-atomic-habits", "Habit building, systems, behavior change"),
        ("forte-building-second-brain", "Second brain, PKM, knowledge management"),
        ("forte-para-method", "PARA organization system, folder structure"),
        ("moran-12-week-year", "12-week execution, goal sprints, accountability"),
        ("duhigg-power-of-habit", "Habit loops, cue-routine-reward, organizational habits"),
        ("pink-when", "Timing, when to schedule tasks, energy management"),
    ],
    "finance": [
        ("michalowicz-profit-first", "Cash flow, profit first, financial discipline"),
    ],
    "billing": [
        ("michalowicz-profit-first", "Cash flow, profit first, financial discipline"),
    ],
    "coaching": [
        ("robbins-five-second-rule", "Confidence, 5-second action, overcoming hesitation"),
        ("robbins-let-them-theory", "Control release, boundaries, letting go"),
        ("sharma-5am-club", "Morning routine, discipline, peak performance"),
        ("goggins-cant-hurt-me", "Mental toughness, suffering, pushing limits"),
        ("jakes-instinct", "Instinct, spiritual intelligence, inner knowing"),
        ("pink-drive", "Motivation, intrinsic drive, autonomy mastery purpose"),
        ("attwood-passion-test", "Passion, life purpose, alignment"),
        ("grenny-crucial-conversations", "High-stakes conversations, safety, mutual purpose"),
    ],
    "support": [
        ("tawwab-set-boundaries-find-peace", "Boundaries, self-respect, healthy limits"),
        ("brown-atlas-of-heart", "Emotional vocabulary, empathy, human connection"),
        ("grenny-crucial-conversations", "Difficult conversations, de-escalation"),
        ("voss-never-split-difference", "Tactical empathy, listening, resolution"),
    ],
    "customer-support": [
        ("tawwab-set-boundaries-find-peace", "Boundaries, self-respect, healthy limits"),
        ("brown-atlas-of-heart", "Emotional vocabulary, empathy, human connection"),
        ("grenny-crucial-conversations", "Difficult conversations, de-escalation"),
        ("voss-never-split-difference", "Tactical empathy, listening, resolution"),
    ],
    "creative": [
        ("miller-building-storybrand-2", "Storytelling, narrative clarity, brand voice"),
        ("godin-this-is-marketing", "Creativity in service of an audience"),
        ("kane-hook-point", "Hooks, attention, creative differentiation"),
        ("bly-copywriters-handbook", "Copy craft, headlines, creative writing standards"),
    ],
    "hr": [
        ("obama-becoming", "Identity, resilience, becoming"),
        ("tawwab-set-boundaries-find-peace", "Boundaries, healthy workplace dynamics"),
        ("brown-atlas-of-heart", "Emotional intelligence, team culture"),
        ("grenny-crucial-conversations", "Performance conversations, feedback"),
    ],
    "hr-people": [
        ("obama-becoming", "Identity, resilience, becoming"),
        ("tawwab-set-boundaries-find-peace", "Boundaries, healthy workplace dynamics"),
        ("brown-atlas-of-heart", "Emotional intelligence, team culture"),
        ("grenny-crucial-conversations", "Performance conversations, feedback"),
    ],
    "legal": [
        ("grenny-crucial-conversations", "Difficult negotiations, high-stakes discussions"),
    ],
    "legal-compliance": [
        ("grenny-crucial-conversations", "Difficult negotiations, high-stakes discussions"),
    ],
    "it": [
        ("clear-atomic-habits", "Systematic thinking, process improvement"),
        ("forte-building-second-brain", "Knowledge management, documentation"),
    ],
    "it-tech": [
        ("clear-atomic-habits", "Systematic thinking, process improvement"),
        ("forte-building-second-brain", "Knowledge management, documentation"),
    ],
    "master-orchestrator": [
        ("collins-good-to-great", "Strategic thinking, disciplined execution"),
        ("sinek-start-with-why", "Purpose-driven decision making"),
    ],
}

START_HERE_TEMPLATE = """# {role_title} - Start Here

## What This Role Does
[Describe what this role is responsible for]

## Who Owns This Role
{dept_name} > {role_name}

## Top Tasks
[List the numbered task files this role uses, in order]
1. 01-[task-name].md

## Tools This Role Uses
[List the tools, software, and logins this role needs]

## Rules for This Role
[List any non-negotiable rules for how this role operates]

{governing_personas_section}
## Where to Find Examples
- Good examples: good-examples.md
- Bad examples: bad-examples.md
"""

GOVERNING_PERSONAS_SECTION = """## Governing Personas
This department is governed by the following coaching personas.
Before executing work in this role, query QMD to load the relevant persona's Task Mode.

{persona_list}

**How to query:** `qmd search "<task description>" -c coaching-personas`
**Full persona map:** See PERSONA-ROUTER.md in the book-to-persona skill folder

"""

GOVERNING_PERSONAS_FILE = """# Governing Personas - {dept_title} Department

The following coaching personas govern how agents in this department think, communicate, and execute work.
Before any task, query QMD to load the relevant persona's Task Mode.

## How to Use
```bash
qmd search "<describe your task>" -c coaching-personas
```
Load the returned persona's **Task Mode** section. Execute through that methodology.

## Personas for This Department

{persona_entries}

## Cross-Reference
- Full routing map: See PERSONA-ROUTER.md in the book-to-persona skill
- QMD collection: coaching-personas
- To query a specific persona: `qmd get qmd://coaching-personas/[persona-folder]/persona-blueprint.md`
"""

GOOD_EXAMPLES_TEMPLATE = """# Good Examples - {role_title}

## What Great Output Looks Like
[Add examples of excellent work from this role]

## Why These Are Good
[Explain what makes these examples the standard to meet]
"""

BAD_EXAMPLES_TEMPLATE = """# Bad Examples - {role_title}

## What Poor Output Looks Like
[Add examples of work that does not meet the standard]

## Why These Are Bad
[Explain what went wrong and what to do instead]
"""

TOOLS_TEMPLATE = """# Tools - {role_title}

## Tools This Role Uses

| Tool | Purpose | Where to Find Login |
|------|---------|-------------------|
| [Tool Name] | [What it does] | [Where credentials are stored] |

## Rules for Tool Use
[Any restrictions, permissions, or usage rules]
"""

TASK_TEMPLATE = """# {task_title}

## Purpose
[What this task accomplishes]

## When to Do This
[What triggers this task]

## Step by Step
1. [Step 1]
2. [Step 2]
3. [Step 3]

## What Good Output Looks Like
[Describe the result when this task is done correctly]

## Common Mistakes
[What usually goes wrong and how to avoid it]
"""

ROUTING_TEMPLATE = """# Task Routing - Which Department Handles What

## How to Use This File
When a task comes in, find the matching category below.
Go directly to that department folder and read the role's 00-START-HERE.md.

{routing_sections}

## When You Are Unsure
If the task does not match any category above:
1. Ask: "What is the end goal of this task?"
2. Route to the department whose purpose most closely matches that goal
3. If still unsure, default to ops-dept/ and let the Operations team route it further
"""


def telegram_print(message):
    """Print in Telegram-friendly format - no tables, short lines, bullets."""
    print(message)


def show_options():
    """Present the 3 options to the user."""
    telegram_print("""
🎯 AI WORKFORCE BLUEPRINT - Choose Your Path

I will help you build the folder and file system that turns your AI into a trained workforce.

📋 OPTION A - Full Automated Build (Recommended)
   • I interview you about your business
   • I build everything automatically based on your answers
   • Most personalized results
   • Best for: First-time setup

🛠️ OPTION B - Manual Build
   • You build everything yourself using the blueprint
   • Read ai-workforce-blueprint-full.md for guidance
   • Best for: Hands-on users who want full control

🔍 OPTION C - Audit / Resume Mode
   • I scan your existing workforce folder
   • Add missing files, wire personas if available
   • Never overwrites existing content
   • Best for: Returning users, adding personas later
""")


def show_prebuilt_departments():
    """Show the pre-built departments available."""
    telegram_print("""
📁 PRE-BUILT DEPARTMENTS AVAILABLE:

• marketing-dept - Content, ads, social media, email campaigns
• sales-dept - Converting leads to customers
• billing-dept - Invoicing, payments, financial tracking
• customer-support-dept - Helping existing clients
• operations-dept - Day-to-day business running
• creative-dept - Graphics, video, content creation
• hr-people-dept - Team management, hiring
• legal-compliance-dept - Contracts, regulations
• it-tech-dept - Software, websites, infrastructure
• master-orchestrator-dept - Routes all work (always included)
""")


def check_personas_installed():
    """Check if coaching-personas QMD collection exists on this machine."""
    try:
        result = subprocess.run(
            ["qmd", "status"],
            capture_output=True, text=True, timeout=10
        )
        return "coaching-personas" in result.stdout
    except Exception:
        return False


def load_existing_context():
    """Load existing context from memory files to avoid asking known questions."""
    context = {
        "business_name": None,
        "departments": [],
        "tools": [],
        "industry": None,
    }
    
    # Check common context file locations
    context_files = [
        os.path.expanduser("~/clawd/MEMORY.md"),
        os.path.expanduser("~/clawd/USER.md"),
        os.path.expanduser("~/clawd/AGENTS.md"),
        os.path.expanduser("~/clawd/HEARTBEAT.md"),
        os.path.expanduser("~/clawd/IDENTITY.md"),
    ]
    
    for file_path in context_files:
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                    # Look for business name patterns
                    if "blackceo" in content.lower() or "BlackCEO" in content:
                        context["business_name"] = "BlackCEO"
                        context["industry"] = "coaching/consulting"
                    # Look for known tools
                    if "GoHighLevel" in content or "GHL" in content:
                        context["tools"].append("GoHighLevel")
                    if "Slack" in content:
                        context["tools"].append("Slack")
                    if "Google" in content:
                        context["tools"].append("Google Workspace")
            except Exception:
                pass
    
    return context


def ask_interview_style(question, example=None, default=None, context_value=None):
    """Ask a question in interview style with examples."""
    # If we already know the answer from context, skip the question
    if context_value:
        telegram_print(f"✓ Using known info: {context_value}")
        return context_value
    
    if example:
        full_question = f"{question}\n   Example: {example}"
    else:
        full_question = question
    
    if default:
        answer = input(f"{full_question}\n   [Default: {default}]: ").strip()
        return answer if answer else default
    return input(f"{full_question}: ").strip()


def get_department_selection():
    """Ask user which departments they want to use."""
    telegram_print("""
🎯 DEPARTMENT SELECTION

You can:
• Keep all pre-built departments
• Keep some + remove others
• Keep all + add custom departments
• Start from scratch with custom departments only
""")
    
    options = [
        "Keep all pre-built departments",
        "Keep some + remove others",
        "Keep all + add custom departments",
        "Start from scratch (custom only)"
    ]
    
    telegram_print("\nChoose an option:")
    for i, opt in enumerate(options, 1):
        telegram_print(f"  {i}. {opt}")
    
    choice = input("\nEnter 1-4: ").strip()
    
    if choice == "1":
        return list(PREBUILT_DEPARTMENTS.keys())
    elif choice == "2":
        telegram_print("\n📋 Available departments:")
        for dept, desc in PREBUILT_DEPARTMENTS.items():
            telegram_print(f"  • {dept} - {desc}")
        remove = input("\nWhich departments should I REMOVE? (comma-separated): ").strip()
        removed = [d.strip() for d in remove.split(",") if d.strip()]
        return [d for d in PREBUILT_DEPARTMENTS.keys() if d not in removed]
    elif choice == "3":
        custom = input("\nWhat custom departments do you want to add? (comma-separated): ").strip()
        custom_list = [d.strip() for d in custom.split(",") if d.strip()]
        return list(PREBUILT_DEPARTMENTS.keys()) + custom_list
    elif choice == "4":
        custom = input("\nWhat custom departments do you want to create? (comma-separated): ").strip()
        return [d.strip() for d in custom.split(",") if d.strip()]
    else:
        telegram_print("Invalid choice. Using all pre-built departments.")
        return list(PREBUILT_DEPARTMENTS.keys())


def interview_user(context):
    """Conduct interview-style questions with examples."""
    telegram_print("\n" + "="*50)
    telegram_print("🎤 INTERVIEW TIME - Let's understand your business")
    telegram_print("="*50)
    
    # Question 1: Business name
    business_name = ask_interview_style(
        "What is your business name?",
        example: "Acme Coaching, BlackCEO, Otts Consulting",
        default=context.get("business_name", "My Business"),
        context_value=context.get("business_name")
    )
    
    telegram_print("\n" + "-"*30)
    
    # Question 2: What does your business do?
    business_purpose = ask_interview_style(
        "In one sentence, what does your business do?",
        example: "I help coaches book more clients through better marketing"
    )
    
    telegram_print("\n" + "-"*30)
    
    # Question 3: Current team size
    team_size = ask_interview_style(
        "What is your current team size?",
        example: "Just me, 2-5 people, 10-20 people, 50+ people",
        default="Just me"
    )
    
    telegram_print("\n" + "-"*30)
    
    # Question 4: Main tools
    tools_answer = ask_interview_style(
        "What are the main tools your business uses?",
        example: "GoHighLevel, Slack, Google Workspace, QuickBooks, Calendly",
        default=", ".join(context.get("tools", [])) if context.get("tools") else None
    )
    tools = [t.strip() for t in tools_answer.split(",") if t.strip()]
    
    telegram_print("\n" + "-"*30)
    
    # Question 5: Biggest challenge
    challenge = ask_interview_style(
        "What is your biggest challenge right now?",
        example: "Following up with leads, creating content, managing invoices"
    )
    
    telegram_print("\n" + "-"*30)
    
    # Question 6: Existing SOPs
    has_sops = ask_interview_style(
        "Do you have existing SOPs, checklists, or training materials?",
        example: "Yes, in Google Docs / No, starting from scratch / Some, but scattered"
    )
    
    return {
        "business_name": business_name,
        "business_purpose": business_purpose,
        "team_size": team_size,
        "tools": tools,
        "challenge": challenge,
        "has_sops": has_sops,
    }


def create_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"  Created: {os.path.basename(path)}")


def ask(question, default=None):
    if default:
        answer = input(f"{question} [{default}]: ").strip()
        return answer if answer else default
    return input(f"{question}: ").strip()


def build_governing_personas_content(dept_key, for_file=False):
    """Generate governing personas content for a department."""
    personas = DEPT_PERSONAS.get(dept_key, [])
    if not personas:
        # Try partial match
        for key in DEPT_PERSONAS:
            if key in dept_key or dept_key in key:
                personas = DEPT_PERSONAS[key]
                break
    if not personas:
        return None, None

    if for_file:
        entries = []
        for folder, description in personas:
            entries.append(f"### {folder}\n**Focus:** {description}\n**Query:** `qmd search \"{description.lower()}\" -c coaching-personas`\n")
        return '\n'.join(entries)

    # For 00-START-HERE.md section
    lines = []
    for folder, description in personas:
        lines.append(f"- **{folder}**: {description}")
    return '\n'.join(lines)


def detect_existing_workspace():
    """Scan common locations for an existing workforce folder."""
    common_paths = [
        os.path.expanduser("~/Downloads/my-ai-workforce"),
        os.path.expanduser("~/Downloads/ai-workforce"),
        os.path.expanduser("~/Downloads/openclaw-master-files/ai-workforce"),
        os.path.expanduser("~/clawd/workforce"),
    ]
    for path in common_paths:
        if os.path.isdir(path) and any(d.endswith(DEPT_SUFFIX) for d in os.listdir(path)):
            return path
    return None


def audit_mode(workspace, personas_installed):
    """Option C - scan existing workspace, fill gaps, wire personas if available."""
    telegram_print(f"\n🔍 AUDIT MODE - Scanning {workspace}\n")
    added = []
    updated = []

    for item in os.listdir(workspace):
        dept_path = os.path.join(workspace, item)
        if not os.path.isdir(dept_path) or not item.endswith(DEPT_SUFFIX):
            continue

        dept_key = item.replace(DEPT_SUFFIX, "")
        print(f"[{item}]")

        # Wire personas if installed and governing-personas.md missing
        if personas_installed:
            gp_file = os.path.join(dept_path, "governing-personas.md")
            if not os.path.exists(gp_file):
                persona_file_content = build_governing_personas_content(dept_key=dept_key, for_file=True)
                if persona_file_content:
                    create_file(
                        gp_file,
                        GOVERNING_PERSONAS_FILE.format(
                            dept_title=dept_key.title(),
                            persona_entries=persona_file_content
                        )
                    )
                    added.append(f"{item}/governing-personas.md")

        # Scan role folders
        for role in os.listdir(dept_path):
            role_path = os.path.join(dept_path, role)
            if not os.path.isdir(role_path):
                continue

            role_title = role.replace('-', ' ').title()
            dept_name = f"{dept_key.title()} Department"

            # Add missing files
            for fname, template, kwargs in [
                ("good-examples.md", GOOD_EXAMPLES_TEMPLATE, {"role_title": role_title}),
                ("bad-examples.md", BAD_EXAMPLES_TEMPLATE, {"role_title": role_title}),
                ("tools.md", TOOLS_TEMPLATE, {"role_title": role_title}),
            ]:
                fpath = os.path.join(role_path, fname)
                if not os.path.exists(fpath):
                    create_file(fpath, template.format(**kwargs))
                    added.append(f"{item}/{role}/{fname}")

            # Add Governing Personas section to 00-START-HERE.md if missing
            if personas_installed:
                start_here = os.path.join(role_path, "00-START-HERE.md")
                if os.path.exists(start_here):
                    with open(start_here, 'r') as f:
                        content = f.read()
                    if "Governing Personas" not in content:
                        persona_lines = build_governing_personas_content(dept_key=dept_key, for_file=False)
                        if persona_lines:
                            gov_section = GOVERNING_PERSONAS_SECTION.format(persona_list=persona_lines)
                            with open(start_here, 'a') as f:
                                f.write(f"\n{gov_section}")
                            updated.append(f"{item}/{role}/00-START-HERE.md")

    telegram_print("\n" + "="*50)
    telegram_print("✅ AUDIT COMPLETE")
    telegram_print("="*50)
    if added:
        telegram_print(f"\n📁 Added {len(added)} missing files:")
        for f in added:
            telegram_print(f"  + {f}")
    if updated:
        telegram_print(f"\n📝 Updated {len(updated)} existing files:")
        for f in updated:
            telegram_print(f"  ~ {f}")
    if not added and not updated:
        telegram_print("\n✓ Everything looks good - no gaps found.")
    if personas_installed:
        telegram_print("\n✅ Persona wiring complete.")
    else:
        telegram_print("\nℹ️ Install Skill 22 and re-run to wire personas.")


def build_workforce_automated(context, interview_data, departments):
    """Option A - Build workforce based on interview answers."""
    workspace = ask_interview_style(
        "Where should I build your workforce folder?",
        example: "~/Downloads/my-ai-workforce",
        default="~/Downloads/my-ai-workforce"
    )
    workspace = os.path.expanduser(workspace)
    
    business_name = interview_data.get("business_name", "My Business")
    
    telegram_print("\n" + "="*50)
    telegram_print(f"🏗️ BUILDING WORKFORCE FOR: {business_name}")
    telegram_print("="*50)
    
    personas_installed = check_personas_installed()
    
    # Get roles for each department
    dept_roles = {}
    for dept in departments:
        if dept == "master-orchestrator":
            continue  # No roles for master orchestrator
            
        telegram_print(f"\n📋 Let's define roles for {dept}-dept:")
        telegram_print("   Example roles:")
        
        # Show example roles based on department type
        examples = {
            "marketing": "content-creator, social-media-manager, ads-specialist",
            "sales": "appointment-setter, closer, account-manager",
            "billing": "invoice-specialist, collections, payment-processor",
            "customer-support": "support-agent, onboarding-specialist",
            "operations": "project-manager, systems-admin, process-analyst",
            "creative": "graphic-designer, video-producer, copywriter",
            "hr-people": "recruiter, onboarding-coordinator, hr-manager",
            "legal-compliance": "contract-specialist, compliance-officer",
            "it-tech": "developer, sysadmin, helpdesk",
        }
        
        example_roles = examples.get(dept, "generalist, specialist")
        telegram_print(f"   • {example_roles}")
        
        roles_input = input(f"\n   What roles exist in {dept}? (comma-separated, or 'skip' for defaults): ").strip()
        
        if roles_input.lower() == 'skip' or not roles_input:
            # Use smart defaults based on department
            if dept == "marketing":
                roles = ['content-creator', 'social-media-manager']
            elif dept == "sales":
                roles = ['appointment-setter', 'closer']
            elif dept == "operations":
                roles = ['project-manager']
            else:
                roles = ['general']
        else:
            roles = [r.strip().lower().replace(' ', '-') for r in roles_input.split(",") if r.strip()]
        
        dept_roles[dept] = roles
        telegram_print(f"   ✓ Added roles: {', '.join(roles)}")
    
    telegram_print(f"\n🔨 Creating folders and files at {workspace}...")
    os.makedirs(workspace, exist_ok=True)

    routing_sections = []

    for dept in departments:
        dept_folder = os.path.join(workspace, f"{dept}{DEPT_SUFFIX}")
        os.makedirs(dept_folder, exist_ok=True)
        telegram_print(f"\n📁 [{dept.upper()}-DEPT]")

        # Master orchestrator is special - no roles, just files
        if dept == "master-orchestrator":
            create_file(
                os.path.join(dept_folder, "00-Master-Orchestrator-Start-Here.md"),
                "# Master Orchestrator - Start Here\n\nThis is the Big Boss department.\n\n## What It Does\n- Receives ALL incoming work\n- Decides which department handles each task\n- Routes work to the right place\n- Tracks completion\n- Creates missing SOPs when needed\n\n## Rules\n- All departments report back here\n- If unsure where something goes, decide based on end goal\n- If a department has no training, create the missing how-to file\n"
            )
            create_file(
                os.path.join(dept_folder, "01-How-to-Route-Work.md"),
                "# How to Route Work to Departments\n\n## Decision Tree\n1. Read the incoming task\n2. Identify keywords and intent\n3. Match to department based on task type\n4. Send to the right department/role/file\n\n## Routing Map\n- Marketing tasks → marketing-dept/\n- Sales tasks → sales-dept/\n- Billing tasks → billing-dept/\n- Support tasks → customer-support-dept/\n- Operations tasks → operations-dept/\n"
            )
            continue

        # Build governing personas content if installed
        persona_lines = None
        if personas_installed:
            persona_lines = build_governing_personas_content(dept_key=dept, for_file=False)
            if persona_lines:
                persona_file_content = build_governing_personas_content(dept_key=dept, for_file=True)
                create_file(
                    os.path.join(dept_folder, "governing-personas.md"),
                    GOVERNING_PERSONAS_FILE.format(
                        dept_title=dept.title(),
                        persona_entries=persona_file_content or "[No personas mapped for this department yet]"
                    )
                )

        routing_lines = [f"## {dept.title()} Tasks"]
        routing_lines.append(f"- [describe task type] → {dept}{DEPT_SUFFIX}/[role]/")
        routing_sections.append('\n'.join(routing_lines))

        for role in dept_roles.get(dept, ['general']):
            role_folder = os.path.join(dept_folder, role)
            os.makedirs(role_folder, exist_ok=True)

            role_title = role.replace('-', ' ').title()
            dept_name = f"{dept.title()} Department"

            # Build governing personas section for START-HERE if personas installed
            if personas_installed and persona_lines:
                gov_section = GOVERNING_PERSONAS_SECTION.format(persona_list=persona_lines)
            else:
                gov_section = ""

            create_file(
                os.path.join(role_folder, "00-START-HERE.md"),
                START_HERE_TEMPLATE.format(
                    role_title=role_title,
                    dept_name=dept_name,
                    role_name=role_title,
                    governing_personas_section=gov_section
                )
            )
            create_file(
                os.path.join(role_folder, "01-first-task.md"),
                TASK_TEMPLATE.format(task_title="First Task")
            )
            create_file(
                os.path.join(role_folder, "good-examples.md"),
                GOOD_EXAMPLES_TEMPLATE.format(role_title=role_title)
            )
            create_file(
                os.path.join(role_folder, "bad-examples.md"),
                BAD_EXAMPLES_TEMPLATE.format(role_title=role_title)
            )
            create_file(
                os.path.join(role_folder, "tools.md"),
                TOOLS_TEMPLATE.format(role_title=role_title)
            )

    # Universal SOPs
    universal_sops = os.path.join(workspace, "universal-sops")
    os.makedirs(universal_sops, exist_ok=True)
    routing_content = ROUTING_TEMPLATE.format(routing_sections='\n\n'.join(routing_sections))
    create_file(os.path.join(universal_sops, "00-ROUTING.md"), routing_content)
    create_file(os.path.join(universal_sops, "tools.md"), "# Universal Tools\n\n[Tools used across all departments]\n")

    telegram_print("\n" + "="*50)
    telegram_print("✅ BUILD COMPLETE")
    telegram_print("="*50)
    telegram_print(f"\n📁 Workforce folder: {workspace}")
    telegram_print(f"📊 Departments built: {len(departments)}")
    if personas_installed:
        telegram_print(f"✅ Governing personas wired to all departments")
    telegram_print(f"\n🎯 Next steps:")
    telegram_print("  1. Open each 00-START-HERE.md and fill in role details")
    telegram_print("  2. Rename 01-first-task.md to match your actual tasks")
    telegram_print("  3. Add your tools to each tools.md")
    telegram_print("  4. Update universal-sops/00-ROUTING.md with your task types")


def main():
    telegram_print("\n" + "="*50)
    telegram_print("🚀 AI WORKFORCE BLUEPRINT - Scaffold Builder")
    telegram_print("="*50)

    # Check for personas
    personas_installed = check_personas_installed()
    if personas_installed:
        telegram_print("\n✅ Coaching Personas Matrix detected - personas will be wired automatically.")
    else:
        telegram_print("\nℹ️ Coaching Personas Matrix not detected - building clean structure.")
        telegram_print("   (Install Skill 22 later and re-run to add personas.)")

    # Check for existing workspace
    existing = detect_existing_workspace()
    if existing:
        telegram_print(f"\n📁 Existing workforce found at: {existing}")
        run_audit = input("\nRun in audit mode? Adds missing files, wires personas. (Y/n): ").strip().lower()
        if run_audit != 'n':
            audit_mode(existing, personas_installed)
            return

    # Present options
    show_options()
    
    choice = input("\nEnter your choice (A/B/C): ").strip().upper()
    
    if choice == "B":
        telegram_print("\n📖 MANUAL BUILD SELECTED")
        telegram_print("\nPlease read ai-workforce-blueprint-full.md for step-by-step instructions.")
        telegram_print("Come back and run this script again when you are ready for Option A or C.")
        return
    
    elif choice == "C":
        telegram_print("\n🔍 AUDIT MODE SELECTED")
        workspace = input("Enter path to your workforce folder: ").strip()
        workspace = os.path.expanduser(workspace)
        if os.path.isdir(workspace):
            audit_mode(workspace, personas_installed)
        else:
            telegram_print(f"❌ Folder not found: {workspace}")
        return
    
    else:  # Default to Option A
        telegram_print("\n🚀 FULL AUTOMATED BUILD SELECTED")
        
        # Show pre-built departments
        show_prebuilt_departments()
        
        # Load existing context to avoid asking known questions
        telegram_print("\n📋 Loading your existing context...")
        context = load_existing_context()
        if context.get("business_name"):
            telegram_print(f"✓ Found business info: {context['business_name']}")
        
        # Get department selection
        departments = get_department_selection()
        
        # Always include master orchestrator
        if "master-orchestrator" not in departments:
            departments.append("master-orchestrator")
        
        telegram_print(f"\n✓ Selected {len(departments)} departments")
        
        # Conduct interview
        interview_data = interview_user(context)
        
        # Build the workforce
        build_workforce_automated(context, interview_data, departments)


if __name__ == "__main__":
    main()
