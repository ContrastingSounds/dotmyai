---
description: Claim and execute the next ready bead, then land the plane
---

# Execute Next Ready Bead

Claim the next available bead from the ready queue, execute it, and complete the session properly.

## Step 1: Find and Claim Work

Run `bd ready` to see available work, then claim the highest priority task (not epic):

```bash
bd ready
bd update <id> --status=in_progress
```

**Selection priority:**
1. Choose tasks over epics (epics are containers, not actionable)
2. Choose lower P-number first (P1 before P2)
3. If tied, choose the one listed first

Show the user which bead you're claiming and display its full description with `bd show <id>`.

## Step 2: Execute the Work

Read the bead's description carefully. It should contain:
- **Goal** - What needs to be accomplished
- **Context** - Why this work exists
- **Deliverables** - Specific files/artifacts to create
- **Reference** - Link to planning document (read if needed)

Execute the work described. Use TodoWrite to track sub-tasks if the work is complex.

## Step 3: Quality Gates

After completing the work, run appropriate quality checks:

```bash
# If Python code was modified:
uv run pytest

# If only non-code files changed, skip tests
```

Fix any failing tests before proceeding.

## Step 4: Landing the Plane Protocol

**MANDATORY** - Complete ALL of these steps:

### 4a. File issues for discovered work
If you found bugs, TODOs, or follow-up work during execution:
```bash
bd create --title="<discovered issue>" --type=task --priority=2 --description="..."
```

### 4b. Update issue status
```bash
# Close the bead you worked on
bd close <id>

# Sync beads (pull from main for ephemeral branches)
bd sync --from-main
```

### 4c. Commit changes
```bash
git add <files>
git commit -m "Description of changes

Closes: <bead-id>"
```

### 4d. Verify clean state
```bash
git status
```

Must show clean working tree with all changes committed.

## Step 5: Hand Off

Provide a brief summary:
- What was completed
- Any issues discovered (with bead IDs)
- What's ready to work on next (`bd ready`)

## Important Rules

- **One bead per session** - Focus on completing one bead fully
- **Don't skip quality gates** - Tests must pass before closing
- **Always close the bead** - Mark it done when work is complete
- **Always commit** - Never leave uncommitted changes
- **Note:** This is an ephemeral branch (no upstream), so we don't push. Code merges to main locally.
