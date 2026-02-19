---
description: Execute all tasks in an epic, committing after each
argument-hint: <epic-id or search text>
---

# Execute Epic Tasks

Execute all tasks belonging to an epic, working through them in priority order until the epic is complete or blocked.

## Step 1: Resolve Epic

**Input:** `$ARGUMENTS` can be an epic ID or search text.

### If input looks like an ID (e.g., `pw-87y5`):
```bash
bd show $ARGUMENTS --json
```
Verify `issue_type` is `"epic"`. If not, report error.

### If input is free text:
```bash
bd list --type=epic --status=open
```
Search epic titles for matches (case-insensitive substring). Then:
- **Single match**: Proceed automatically
- **Multiple matches**: Use AskUserQuestion to confirm which epic
- **No matches**: Report error and show available epics

Display the epic title and count of child tasks.

## Step 2: Get Ready Tasks

Query the epic's child tasks:
```bash
bd show <epic-id> --json
```

From the `dependents` array, filter to tasks that are:
- Status: `open` or `ready` (not `blocked`, `closed`, `in_progress`)
- Type: `task`, `bug`, or `feature` (not `epic`)

Sort by priority (P1 before P2), then by order listed.

If no ready tasks:
- If all tasks are `closed` → Epic is complete, go to Step 5
- If tasks are `blocked` → Report blockers and STOP

## Step 3: Execute Task

For the highest-priority ready task:

### 3a. Claim the task
```bash
bd update <id> --status=in_progress
bd show <id>
```

### 3b. Execute the work
Read the bead's description. Execute the work described. Use TodoWrite for complex sub-tasks.

### 3c. Quality gates
```bash
# If Python code was modified:
uv run pytest

# If only non-code files changed, skip tests
```

### On Success:
```bash
bd close <id>
```
Then proceed to **Land the Plane** (Step 3d).

### On Failure:
```bash
bd update <id> --status=blocked --reason="<explanation of failure>"
```
Skip landing and go directly to Step 4 to check for other work.

### 3d. Land the Plane (Per Task)

**MANDATORY after each successful task:**

```bash
# Check what changed
git status

# Stage changes
git add <files>

# Sync beads from main
bd sync --from-main

# Commit with bead reference
git commit -m "Description of changes

Closes: <bead-id>"
```

## Step 4: Check for More Work

Re-query the epic's tasks to refresh status:
```bash
bd show <epic-id> --json
```

- **If ready tasks exist**: Return to Step 3
- **If all tasks blocked**: Report blockers and STOP
- **If all tasks closed**: Proceed to Step 5

## Step 5: Final Summary

Report:
- List of all completed tasks (with IDs)
- List of any blocked tasks (with IDs and reasons)
- Epic completion status
- Run `bd epic status` to show overall progress

## Discovered Work Handling

During execution, if you discover new work:

**If directly related to this epic's scope:**
```bash
bd create --title="<discovered issue>" --type=task --priority=2 --description="..."
bd dep add <new-id> <epic-id>
```

**If unrelated future work:**
```bash
bd create --title="<discovered issue>" --type=task --priority=2 --description="..."
# Do NOT link to epic
```

## Important Rules

- **Land the plane per task** - Commit after each successful task completion
- **Don't skip quality gates** - Tests must pass before closing a task
- **Handle failures gracefully** - Mark blocked with reason, try other tasks
- **Stop if critical path blocked** - If a blocked task prevents all other work, stop
- **This is an ephemeral branch** - No push, code merges to main locally
