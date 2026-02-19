---
description: Create Beads task tree from a planning document
argument-hint: <path-to-plan.md>
---

# Create Beads Task Tree from Plan

Create a task tree in Beads based on the planning document at: `$ARGUMENTS`

## Instructions

1. **Read the planning document** at the specified path
2. **Identify the implementation steps** - look for sections like "Implementation Order", "Tasks", "Steps", or numbered lists describing work to be done
3. **Create an epic** for the overall work if there are 3+ tasks
4. **Create individual tasks** for each implementation step
5. **Set up dependencies** based on the logical order (which tasks block which)
6. **Show the final task tree** with `bd ready` and `bd blocked`

## Task Description Template

Every task MUST have a description following this template:

```
**Goal:** [One sentence describing what this task accomplishes]

**Context:** [1-2 sentences explaining why this task exists and how it fits into the larger plan]

**Deliverables:**
- [Specific file to create/modify]
- [Expected outcome or artifact]

**Reference:** See $ARGUMENTS for full plan details.
```

## Description Requirements

- **Self-complete**: Someone reading only the task description should understand what to do without needing to read the plan
- **Specific**: Name actual files, functions, or components involved
- **Actionable**: Clear about what "done" looks like
- **Contextual**: Explain the "why" not just the "what"
- **Referenced**: Always include the path to the source planning document

## Example Good Description

```
**Goal:** Create a line-based parser for pragma annotations in SDK resource files.

**Context:** This replaces complex AST-based endpoint extraction with simple comment parsing. The parser reads `# endpoint:` and `# facade:` comments that immediately precede method definitions.

**Deliverables:**
- Create `ai/tools/api_coverage/pragma_parser.py` (~50-80 lines)
- Implement regex patterns for endpoint/facade comments
- Return dict mapping (class_name, method_name) to endpoint info

**Reference:** See ai/02_plans/pragma-annotations-for-sdk-coverage.md for full plan details.
```

## Example Bad Description (avoid this)

```
Create the pragma parser with line-based parsing.
```

This is bad because it doesn't explain what a pragma parser is, what files are involved, or what the output should be.

## Beads Commands Reference

```bash
# Create epic
bd create --title="Epic title" --type=epic --priority=1 --description="..."

# Create task
bd create --title="Task title" --type=task --priority=N --description="..."

# Add dependency (task depends on blocker)
bd dep add <task-id> <blocker-id>

# Show results
bd ready
bd blocked
```

## Priority Guidelines

- **P1**: Core implementation tasks (must be done for feature to work)
- **P2**: Supporting tasks (cleanup, verification, documentation)
- **P3**: Polish tasks (final review, nice-to-haves)

## Execution

Now read the planning document and create the task tree following these guidelines.
