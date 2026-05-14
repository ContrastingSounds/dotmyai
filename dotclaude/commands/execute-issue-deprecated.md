---
description: Execute a Linear issue end-to-end — optionally split into sub-issues, create a worktree, and work through each task with tests, commits, and Linear updates.
argument-hint: Linear issue identifier (e.g. CON-42)
---

# Execute Linear Issue

## Input

Linear issue identifier: $ARGUMENTS

## Step 1: Parse the Issue Identifier

Extract the issue identifier from the input. Accepted formats:
- Full URL: `https://linear.app/{workspace}/issue/{ID}/...` → extract `{ID}` (e.g., `CON-42`)
- Short identifier: `CON-42` → use directly

If the input does not match either format, ask the user for a valid Linear issue URL or identifier.

## Step 2: Fetch and Review the Issue

1. Use `mcp__claude_ai_Linear__get_issue` with `includeRelations: true` to retrieve the issue details.
2. Use `mcp__claude_ai_Linear__list_comments` to retrieve all comments.

**Pre-flight checks** — confirm the issue is ready to execute:
- The description contains a task checklist (lines starting with `- [ ]`).
- There are no unresolved questions in the description or unanswered question-comments.

If the issue is not execution-ready, tell the user and suggest running `/validate-issue {ID}` first. Stop here.

3. Move the issue to "In Progress":
```
mcp__claude_ai_Linear__save_issue(id: "{ID}", state: "In Progress")
```

## Step 3: Parse the Checklist

Extract every checklist item from the description. For each item, capture:
- **Title**: The bold task name (e.g., `Task 1: Add field validation`)
- **What**: The description of changes
- **Validate**: The validation step
- **Files involved**: Infer from the "What" section which files will be created or modified

## Step 4: Decide Whether to Create Sub-Issues

Count the checklist items.

### If 4 or more items → Create sub-issues

For each checklist item, create a sub-issue:
```
mcp__claude_ai_Linear__save_issue(
  title: "[task title from checklist]",
  team: "ContrastingSounds",
  project: "Mock Machines",
  assignee: "me",
  state: "Todo",
  priority: 3,
  parentId: "[parent issue ID]"
)
```

Note the returned identifier for each sub-issue.

#### Set up blocking dependencies

Analyze which tasks depend on others based on:
1. **File overlap**: If Task B modifies a file that Task A also modifies, Task B should be blocked by Task A. This prevents merge conflicts when working on a single branch.
2. **Logical dependency**: If Task B's code depends on types, functions, or structures introduced by Task A.
3. **Test dependency**: If Task B's validation step requires Task A's changes to pass.

For each dependency found, use `mcp__claude_ai_Linear__save_issue` to set the blocking relation, or note the execution order.

**Strong preference**: Order tasks to minimize the number of times the same file is touched across consecutive tasks. If two tasks both modify `types.go`, they should run back-to-back so changes are additive, not conflicting.

Post a comment on the parent issue listing the sub-issues and their dependency order:
```
mcp__claude_ai_Linear__save_comment(
  issueId: "[parent ID]",
  body: "Created sub-issues with execution order:\n1. CON-XX: [title] (no blockers)\n2. CON-YY: [title] (blocked by CON-XX)\n..."
)
```

### If fewer than 4 items → No sub-issues

Work through the checklist items in order directly on the parent issue. Skip to Step 5.

## Step 5: Create Worktree and Branch

Determine the branch name from the issue identifier (lowercase):
```bash
# Example: CON-42 → con-42
git worktree add ../mock_machines-con-42 -b con-42-[short-description]
cd ../mock_machines-con-42
```

Run the commands via Bash. If the worktree or branch already exists, inform the user and ask whether to reuse it or create a fresh one.

All subsequent work happens in the worktree directory.

## Step 6: Execute Tasks

Process tasks in dependency order (or checklist order if no sub-issues were created). For each task:

### 6a: Read CLAUDE.md and Understand Context

Before starting the first task, read the project's CLAUDE.md for architecture, testing commands, and conventions. For each subsequent task, re-read any files that will be modified to understand their current state (they may have changed from prior tasks).

### 6b: Implement the Change

Read the relevant files, understand the current implementation, and make the changes described in the task's "What" section. Follow the project's coding conventions.

Use the Edit tool for modifications and Write for new files. Be precise — change only what the task requires.

### 6c: Validate

Run the validation step specified in the task. Typical commands:
- `go test ./pkg/fsm/ -v`
- `go test ./pkg/fsm/ -run TestName -v`
- `go run main.go -testAll -test "" simulations/PaymentProcessor/mock-machine.yaml`
- `go build ./...`
- `go vet ./...`

If validation fails:
1. Read the error output carefully.
2. Fix the issue.
3. Re-run validation.
4. If the fix requires more than 3 attempts, pause and ask the user for guidance.

### 6d: Commit

Stage and commit the changes:
```bash
git add [specific files]
git commit -m "con-42: [imperative description of what was done]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

Use specific file paths in `git add`, not `git add -A`. The commit message should reference the issue identifier and describe the change.

### 6e: Update Linear

If working with sub-issues, update the sub-issue:
```
mcp__claude_ai_Linear__save_comment(issueId: "[sub-issue ID]", body: "Completed: [brief summary of what was done and validation result]")
mcp__claude_ai_Linear__save_issue(id: "[sub-issue ID]", state: "Done")
```

If working without sub-issues, post a progress comment on the parent issue:
```
mcp__claude_ai_Linear__save_comment(issueId: "[parent ID]", body: "Completed task N: [brief summary]")
```

### 6f: Proceed to Next Task

Move to the next task in dependency order. Repeat from 6b.

## Step 7: Final Validation

After all tasks are complete, run the full test suite from the worktree:
```bash
go test ./pkg/fsm/ -v
go run main.go -testAll -test "" simulations/PaymentProcessor/mock-machine.yaml
go vet ./...
```

If any test fails, diagnose and fix before proceeding.

## Step 8: Close Out the Issue

Update the parent issue:
```
mcp__claude_ai_Linear__save_comment(
  issueId: "[parent ID]",
  body: "All tasks complete. Branch: con-42-[description]\n\nChanges:\n- [summary of each commit]\n\nValidation: all tests passing."
)
mcp__claude_ai_Linear__save_issue(id: "[parent ID]", state: "Done")
```

## Step 9: Report to User

Summarize what was done:
1. Number of tasks completed (and sub-issues if created).
2. Number of commits on the branch.
3. Final test results.
4. The worktree path and branch name.
5. Suggested next steps:
   - Review the changes: `cd ../mock_machines-con-42 && git log --oneline main..HEAD`
   - Verify the branch: run `/verify-worktree` from the worktree to merge main into the branch and run tests
   - Merge and clean up: run `/cleanup-worktree [issue ID]` from the worktree to merge into main, remove the worktree, delete the branch, and mark the Linear issue as Done

Do **not** merge or push automatically — leave that to the user.

## Rules

- **Single branch**: All tasks are committed to the same branch in the worktree. Do not create separate branches per sub-issue.
- **Dependency order**: Always respect blocking dependencies. Never start a task whose blockers are incomplete.
- **Minimize file conflicts**: When ordering tasks, prefer sequences where consecutive tasks touch different files. When two tasks must touch the same file, run them back-to-back.
- **Test before commit**: Never commit code that fails its validation step.
- **Commit per task**: Each task gets its own commit. Do not batch multiple tasks into one commit.
- **No merge or push**: Do not merge the branch into main or push to remote. The user decides when to merge.
- **Ask on ambiguity**: If a task description is unclear or a validation step is missing, ask the user before guessing.
- **Fail gracefully**: If a task cannot be completed after reasonable effort (3+ failed attempts at validation), stop, post a comment on the Linear issue explaining the blocker, and ask the user for guidance. Do not skip the task and continue to dependent tasks.
