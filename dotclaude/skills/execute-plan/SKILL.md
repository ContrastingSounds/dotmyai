---
description: Execute a local plan file — create tasks with dependencies, work through them with maximum parallelism, test and commit each task separately.
argument-hint: path to plan file (e.g. ~/.claude/plans/my-plan.md)
disable-model-invocation: true
---

# Execute Plan

## Input

Plan file path: $ARGUMENTS

## Step 1: Parse Plan File

Read the plan file. Extract work items from numbered lists, priority groups, or checklist items. For each item, identify:
- **Title**: short imperative description
- **Description**: what needs to be done
- **Files to modify**: paths referenced or implied
- **Validation**: test commands or verification steps

Work items come from these patterns (in priority order):
1. An "Execution order" or "Implementation Order" section with numbered steps
2. Priority groups (e.g. "### Priority 1", "### Phase A")
3. Top-level numbered lists describing changes
4. Checklist items (`- [ ]`)

## Step 2: Create Tasks with Dependencies

Create a local task for each work item:

```
For each work item:
  TaskCreate(
    subject: "<short title>",
    description: "<description, files to modify, validation command>",
    metadata: {files: ["path/to/file1.go", ...], validationCommand: "go test ./pkg/..."}
  )
```

After all tasks are created, model dependencies:

```
For each dependency:
  TaskUpdate(taskId: "<id>", addBlockedBy: ["<dep-task-id>"])
```

**Dependency rules**:
- Explicit ordering in the plan (numbered steps, priority groups) → earlier items block later items in the same group only if they share files or have logical dependencies.
- File overlap: tasks sharing any file in their `files` list are chained sequentially via `addBlockedBy`.
- Contextual notes ("depends on X", "after Y is done") map to explicit `addBlockedBy`.
- Tasks in different priority groups with no file overlap and no logical dependency are independent — they can run in parallel.

## Step 3: Create Worktree

Determine the repository and create an isolated worktree:

```bash
REPO=$(basename "$(git rev-parse --show-toplevel)")
PLAN_NAME=$(basename "$ARGUMENTS" .md)  # e.g., "my-feature-plan"
BRANCH="${PLAN_NAME}"

git fetch origin
git worktree add "../${REPO}-${PLAN_NAME}" -b "${BRANCH}" origin/staging
```

If `origin/staging` does not exist, warn the user and suggest:
```bash
git branch staging main && git push -u origin staging
```

If the worktree or branch already exists, ask the user whether to reuse or create fresh.

Enter the worktree:

```
EnterWorktree(path: "../${REPO}-${PLAN_NAME}")
```

## Step 4: Load Context

### 4a: Project CLAUDE.md

Read the project's CLAUDE.md from the worktree root. Extract architecture, testing commands, conventions.

### 4b: Language guidelines

Detect the project's primary language (from CLAUDE.md, file extensions, or go.mod/pyproject.toml/package.json). Read the matching guide from `~/.myai/lang-guides/`:
- Go: `~/.myai/lang-guides/go/go-guidelines.md`
- Python: `~/.myai/lang-guides/python/python-guidelines.md`

### 4c: Files to be modified

Read all files that will be modified across all tasks. Understand the current implementation before changing anything.

## Step 5: Execute Tasks (Parallel Dispatch Loop)

Tasks execute via a parallel dispatch loop. Independent tasks (no shared files, no dependency) run simultaneously via multiple Agent() calls in a single message.

### 5a: Find ready tasks

```
TaskList() → identify tasks with status=pending and no incomplete blockers
```

- If no tasks are ready AND no tasks are in_progress → all done, exit loop.
- If no tasks are ready BUT some are in_progress → wait for agents to return.

### 5b: Prepare and dispatch agents

For each ready task:

1. `TaskUpdate(taskId, status: in_progress)`
2. `TaskGet` on each completed blocker → extract `metadata.summary` and `metadata.crossTaskNotes`
3. Build the agent prompt with task description + cross-task context from blockers

Spawn ALL ready agents in a single message (they run concurrently):

```
Agent(
  description: "<short task title>",
  prompt: "## Task
<task description>

## Files to modify
<list of files from task metadata>

## Cross-task context
<summary + crossTaskNotes from completed blockers. Omit if no blockers.>

## Instructions
1. Read the files listed above. Read CLAUDE.md for project conventions.
2. Implement the change described in the task. Change only what the task requires.
3. Run validation. If no validation command is specified in the task, run targeted tests for the changed files.
4. If validation fails, fix and retry. After 3 failed attempts, report the failure with details — do not skip the task.
5. Run formatters and linters.
6. Stage specific files and commit:
   git add <specific files>
   git commit -m '<imperative description>

   Co-Authored-By: Claude <model> <noreply@anthropic.com>'
7. Report what you changed, which tests passed, and the commit hash."
)
```

### 5c: Process agent results

When agents return, for each:

1. **Verify commit**: `git log -1 --oneline` — confirm a new commit exists.
2. **On success**:
   - `TaskUpdate(taskId, status: completed, metadata: {commitHash: "...", summary: "...", crossTaskNotes: "...", filesChanged: [...]})`
3. **On failure**:
   - Ask the user for guidance.
   - Do NOT block unrelated tasks — only tasks with a dependency on this one are affected.

### 5d: Loop

Return to 5a. Find newly unblocked tasks and dispatch them. Repeat until all tasks are completed or blocked on user input.

## Step 6: Final Validation

After all tasks are complete, run the full test suite from the worktree:

```bash
go test ./... -v        # or equivalent for the project language
go vet ./...
go build ./...
```

Read the test command from CLAUDE.md if available. If any test fails, diagnose and fix before proceeding.

## Step 7: Push and Create PR

Push the branch and create a PR targeting `staging`:

```bash
git push -u origin "${BRANCH}"
```

Create the PR:

```bash
gh pr create --base staging --title "<title from plan filename>" --body "$(cat <<'EOF'
## Summary
<1-2 sentence summary of the plan>

## Changes
<bulleted list: one line per task completed>

## Test results
<final validation output summary>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
EOF
)"
```

If the plan file contains a Linear issue reference (e.g. `CON-123`), post a summary comment on that issue:

```
mcp__linear__save_comment(issueId: "<ID>", body: "Plan executed: <PR URL>\n\nAll tasks completed.")
```

## Step 8: Exit Worktree

```
ExitWorktree(action: "keep")
```

## Step 9: Report

Summarize:
1. Number of tasks completed.
2. Number of commits on the branch.
3. Final test results.
4. PR URL.
5. Worktree path and branch name.
6. Next steps:
   - Review the PR on GitHub
   - To verify locally: `cd <worktree-path> && git log --oneline staging..HEAD`
   - After merging: `git worktree remove <worktree-path> && git branch -d <branch>`

## Rules

- **Single branch**: All tasks on one branch. No sub-branches per task.
- **Parallel execution**: Independent tasks (no shared files, no dependency) run simultaneously via multiple Agent() calls in one message.
- **File conflict prevention**: Tasks modifying the same file are chained via `addBlockedBy`. Never run two agents on the same file.
- **Task state is authoritative**: Use TaskCreate/TaskUpdate/TaskList for all tracking. Survives context compaction.
- **Cross-task context via metadata**: When a task completes, store `summary` and `crossTaskNotes` in task metadata. Dependent tasks retrieve this via TaskGet on their blockers.
- **Test before commit**: Never commit code that fails its validation step.
- **One commit per task**: Each task gets its own commit. Do not batch.
- **PR to staging**: Never target main. Never merge the PR — the developer does that.
- **Standard git worktrees**: Do not use `claude --worktree` or `-w`. Use `git worktree add`.
- **No pushd/popd or cd**: Use `EnterWorktree`/`ExitWorktree` to switch directories.
- **Ask on ambiguity**: If a task description is unclear or a validation step is missing, ask the user before guessing.
- **Fail gracefully**: After 3 failed validation attempts, stop, post a blocker comment, and ask the user. Do not block unrelated tasks.
- **No Linear by default**: Only interact with Linear if the plan file explicitly references a Linear issue.
