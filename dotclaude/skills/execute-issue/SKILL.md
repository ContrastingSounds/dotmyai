---
description: Execute a work package (parent issue with sub-issues) or a single issue. Creates a worktree from staging, works through tasks with tests, commits, and Linear updates, then raises a PR to staging.
argument-hint: Linear issue identifier (e.g. CON-129)
disable-model-invocation: true
---

# Execute Issue

## Input

Linear issue identifier: $ARGUMENTS

## Step 1: Parse and Fetch

Extract the issue identifier from the input. Accepted formats:
- Full URL: `https://linear.app/{workspace}/issue/{ID}/...` — extract `{ID}`
- Short identifier: `CON-42` — use directly

Fetch the issue and its context:

```
mcp__linear__get_issue(id: "<ID>", includeRelations: true)
mcp__linear__list_comments(issueId: "<ID>")
```

Check for sub-issues:

```
mcp__linear__list_issues(parentId: "<ID>")
```

## Step 2: Determine Execution Mode

### Work Package mode (sub-issues exist)

If `list_issues` returned sub-issues, this is a work package. Each sub-issue is a task. Skip to Step 3.

### Single Issue mode (no sub-issues)

Count the `- [ ]` checklist items in the issue description.

- **4+ items, no sub-issues**: Offer to create sub-issues. If the user agrees, create one per checklist item:

```
mcp__linear__save_issue(
  title: "<task title>",
  team: "<team from parent>",
  project: "<project from parent>",
  assignee: "me",
  state: "Todo",
  priority: 3,
  parentId: "<parent ID>"
)
```

Then continue as a Work Package.

- **Fewer than 4 items**: Work through the checklist items directly. No sub-issues needed.

### Pre-flight checks (both modes)

1. Tasks must exist — either sub-issues or checklist items in the description.
2. No unresolved questions in description or unanswered question-comments.

If not ready, run `/validate-issue` in a subagent:

```
Agent(
  description: "Validate issue <ID> for execution",
  prompt: "Run /validate-issue <ID> — the issue needs an execution-ready checklist and any outstanding questions resolved before it can be executed. Use the Skill tool to invoke validate-issue.",
)
```

When the subagent completes, re-fetch the issue from Linear to pick up the updated description, then continue from Step 2 (re-evaluate execution mode with the new content).

If the subagent reports that it could not resolve outstanding questions (user input was needed and unavailable), stop and tell the user what's unresolved.

## Step 3: Plan Execution Order

### Work Package mode

For each sub-issue, read its description to identify files that will be modified.

Determine execution order based on:
1. **Existing blocking relations** in Linear (from `includeRelations`).
2. **File overlap**: Tasks modifying the same file should run back-to-back.
3. **Logical dependencies**: Types/interfaces before consumers. Infrastructure before features.

Post the execution order on the parent issue:

```
mcp__linear__save_comment(
  issueId: "<parent ID>",
  body: "Execution order:\n1. <ID>: <title> (no blockers)\n2. <ID>: <title> (after <blocker>)\n..."
)
```

Move the parent to In Progress:

```
mcp__linear__save_issue(id: "<parent ID>", state: "In Progress")
```

### Single Issue mode

Extract tasks from the checklist. Execute in listed order. Move the issue to In Progress.

## Step 4: Create Worktree

Determine the repository name from the current directory and build the worktree path:

```bash
REPO=$(basename "$(git rev-parse --show-toplevel)")
ISSUE_ID="<lowercase issue id>"  # e.g., con-129
BRANCH="${ISSUE_ID}-<short-description>"

git fetch origin
git worktree add "../${REPO}-${ISSUE_ID}" -b "${BRANCH}" origin/staging
```

If `origin/staging` does not exist, warn the user and suggest running:
```bash
git branch staging main && git push -u origin staging
```

If the worktree or branch already exists, ask the user whether to reuse it or create a fresh one.

All subsequent work happens in the worktree directory.

## Step 5: Load Context

Before writing any code, load project context in this order:

### 5a: Project CLAUDE.md

Read the project's CLAUDE.md from the worktree root. Extract architecture, testing commands, conventions, and Linear context.

### 5b: Language guidelines

Detect the project's primary language (from CLAUDE.md, file extensions, or go.mod/pyproject.toml/package.json). Read the matching guide from `~/.myai/lang-guides/`:
- Go: `~/.myai/lang-guides/go/go-guidelines.md`
- Python: `~/.myai/lang-guides/python/python-guidelines.md`

### 5c: Design documents

If a Linear project was identified, fetch PRD and design docs:

```
mcp__linear__list_documents(projectId: "<project ID>")
mcp__linear__get_document(id: "<doc ID>")
```

### 5d: Files to be modified

Read all files that will be modified across all tasks. Understand the current implementation before changing anything.

## Step 6: Execute Tasks

Process tasks in dependency order (Work Package) or checklist order (Single Issue). For each task:

### 6a: Read current state

Re-read any files that were modified by previous tasks on this branch. The code has changed since Step 5d.

Read the task description (sub-issue description or checklist item) for:
- **What**: The change to make
- **Validate**: The verification command
- **Files**: Which files to modify

### 6b: Implement

Make the changes described in the task. Follow the project's coding conventions from CLAUDE.md and language guidelines.

Use the Edit tool for modifications and Write for new files. Change only what the task requires — no scope creep.

### 6c: Test

Run the validation command from the task description. If no validation is specified, run targeted tests for the changed files:
- Go: `go test ./<package>/ -v`
- Python: `uv run pytest tests/<relevant> -v`
- TypeScript: `npx vitest run <relevant>`

If validation fails:
1. Read the error output carefully.
2. Fix the issue.
3. Re-run validation.
4. After 3 failed attempts: post a blocker comment on the issue, explain what was tried, and ask the user for guidance. Do not skip the task.

### 6d: Commit

Run formatters and linters before staging:
- Go: `gofmt -w . && go vet ./...`
- Python: `uv run ruff format . && uv run ruff check .`
- TypeScript: `npx oxfmt . && npx oxlint .`

Stage and commit:

```bash
git add <specific files>
git commit -m "<issue-id>: <imperative description>

Co-Authored-By: Claude <model> <noreply@anthropic.com>"
```

Use specific file paths in `git add`. Verify with `git diff --staged` before committing.

### 6e: Update Linear

**Work Package**: Update the sub-issue:

```
mcp__linear__save_comment(issueId: "<sub-issue ID>", body: "Completed: <summary>. Validation: <pass/fail>.")
mcp__linear__save_issue(id: "<sub-issue ID>", state: "Done")
```

**Single Issue**: Post progress on the parent:

```
mcp__linear__save_comment(issueId: "<issue ID>", body: "Completed task N: <summary>. Validation: <pass/fail>.")
```

### 6f: Next task

Repeat from 6a for the next task in order.

## Step 7: Final Validation

After all tasks are complete, run the full test suite from the worktree:

```bash
go test ./... -v        # or equivalent for the project language
go vet ./...
go build ./...
```

Read the test command from CLAUDE.md if available. If any test fails, diagnose and fix before proceeding.

## Step 8: Push and Raise PR

Push the branch and create a PR targeting `staging`:

```bash
git push -u origin "${BRANCH}"
```

Create the PR:

```bash
gh pr create --base staging --title "<parent issue title>" --body "$(cat <<'EOF'
## Summary
<1-2 sentence summary of the work package>

## Changes
<bulleted list: one line per sub-issue/task completed>

## Test results
<final validation output summary>

## Linear
<link to parent issue>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
EOF
)"
```

Post the PR link on the parent issue:

```
mcp__linear__save_comment(
  issueId: "<parent ID>",
  body: "PR raised: <PR URL>\n\nAll tasks completed. Full test suite passing.\nBranch: <branch name>"
)
```

## Step 9: Update Linear

Move the parent issue to Needs Verification:

```
mcp__linear__save_issue(id: "<parent ID>", state: "Needs Verification")
```

Do NOT move to Done — the developer reviews the PR and merges it. Done happens after merge.

## Step 10: Report to User

Summarize:
1. Number of tasks completed (and sub-issues if applicable).
2. Number of commits on the branch.
3. Final test results.
4. PR URL.
5. Worktree path and branch name.
6. Next steps:
   - Review the PR on GitHub
   - To verify locally: `cd <worktree-path> && git log --oneline staging..HEAD`
   - After merging the PR, clean up: `git worktree remove <worktree-path> && git branch -d <branch>`

## Rules

- **Single branch**: All tasks on one branch. No sub-branches per task.
- **Dependency order**: Never start a task whose blockers are incomplete.
- **Minimize file conflicts**: Consecutive tasks on the same file run back-to-back.
- **Test before commit**: Never commit code that fails its validation step.
- **One commit per task**: Each task gets its own commit. Do not batch.
- **PR to staging**: Never target main. Never merge the PR — the developer does that.
- **Standard git worktrees**: Do not use `claude --worktree` or `-w`. Use `git worktree add`.
- **Ask on ambiguity**: If a task description is unclear or a validation step is missing, ask the user before guessing.
- **Fail gracefully**: After 3 failed validation attempts, stop, post a blocker comment, and ask the user.
