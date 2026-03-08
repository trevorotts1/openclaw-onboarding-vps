#!/usr/bin/env python3
"""
AI Workforce Blueprint - Scaffold Script
Creates the full department/role folder structure with starter files.
Run: python3 build-workforce.py
"""

import os
import sys

DEPT_SUFFIX = "-dept"

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

## Where to Find Examples
- Good examples: good-examples.md
- Bad examples: bad-examples.md
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


def create_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"  Created: {path}")


def ask(question, default=None):
    if default:
        answer = input(f"{question} [{default}]: ").strip()
        return answer if answer else default
    return input(f"{question}: ").strip()


def main():
    print("\n=== AI Workforce Blueprint - Scaffold Builder ===\n")
    
    workspace = ask("Where should I build the workforce folder? (full path)", 
                    os.path.expanduser("~/Downloads/my-ai-workforce"))
    workspace = os.path.expanduser(workspace)
    
    business_name = ask("What is your business name?", "My Business")
    
    print("\nWhat departments does your business need?")
    print("Common options: sales, marketing, operations, finance, coaching, leadership, creative, support")
    print("(Press Enter after each. Type 'done' when finished.)\n")
    
    departments = []
    while True:
        dept = input("Department name (or 'done'): ").strip().lower()
        if dept == 'done' or dept == '':
            break
        if dept:
            departments.append(dept)
    
    if not departments:
        departments = ['sales', 'marketing', 'operations', 'finance']
        print(f"Using defaults: {departments}")
    
    dept_roles = {}
    for dept in departments:
        print(f"\nWhat roles exist in {dept.upper()}?")
        print("(Press Enter after each. Type 'done' when finished.)\n")
        roles = []
        while True:
            role = input(f"  Role in {dept} (or 'done'): ").strip().lower().replace(' ', '-')
            if role == 'done' or role == '':
                break
            if role:
                roles.append(role)
        if not roles:
            roles = ['general']
        dept_roles[dept] = roles
    
    print(f"\n=== Building workforce at {workspace} ===\n")
    
    os.makedirs(workspace, exist_ok=True)
    
    routing_sections = []
    
    for dept in departments:
        dept_folder = os.path.join(workspace, f"{dept}{DEPT_SUFFIX}")
        os.makedirs(dept_folder, exist_ok=True)
        print(f"\n[{dept.upper()}-DEPT]")
        
        routing_lines = [f"## {dept.title()} Tasks"]
        routing_lines.append(f"- [describe task type] → {dept}{DEPT_SUFFIX}/[role]/")
        routing_sections.append('\n'.join(routing_lines))
        
        for role in dept_roles[dept]:
            role_folder = os.path.join(dept_folder, role)
            os.makedirs(role_folder, exist_ok=True)
            
            role_title = role.replace('-', ' ').title()
            dept_name = f"{dept.title()} Department"
            
            create_file(
                os.path.join(role_folder, "00-START-HERE.md"),
                START_HERE_TEMPLATE.format(role_title=role_title, dept_name=dept_name, role_name=role_title)
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
    
    # Universal SOPs folder
    universal_sops = os.path.join(workspace, "universal-sops")
    os.makedirs(universal_sops, exist_ok=True)
    routing_content = ROUTING_TEMPLATE.format(routing_sections='\n\n'.join(routing_sections))
    create_file(os.path.join(universal_sops, "00-ROUTING.md"), routing_content)
    create_file(os.path.join(universal_sops, "tools.md"), "# Universal Tools\n\n[Tools used across all departments]\n")
    
    print(f"\n=== BUILD COMPLETE ===")
    print(f"\nWorkforce folder: {workspace}")
    print(f"Departments built: {', '.join([d + '-dept' for d in departments])}")
    print(f"\nNext steps:")
    print("1. Open each 00-START-HERE.md and fill in the role description")
    print("2. Rename 01-first-task.md to match your actual first task")
    print("3. Add your real tools to each tools.md")
    print("4. Update universal-sops/00-ROUTING.md with your specific task types")
    print("5. Tell your AI: 'My workforce is at [path]. Read universal-sops/00-ROUTING.md first.'")


if __name__ == "__main__":
    main()
