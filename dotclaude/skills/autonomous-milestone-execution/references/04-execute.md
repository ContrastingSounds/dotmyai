# 04 · Execute (loop step 3)

Implement the issue on its worktree branch with maximum safe parallelism, test
and commit each task separately, update Linear, then push and raise a PR to
staging. Ported from the execution skill, **standard mode only** — always branch
from staging, never review-fixes, never merge a PR's fixes.

You (the orchestrator) run this inline: you are already in the worktree (entered
in `02-triage.md`), and only the top-level loop can fan out parallel agents. The
heavy code-writing is delegated to **implementer subagents**.

## Step 1: Determine task set

The issue is validated (`03-validate.md`), so the description has a `## Work Items`
checklist and `## Execution Analysis`.

- **Sub-issues exist** (work package): each sub-issue is a task.
- **No sub-issues, 4+ checklist items**: create one sub-issue per item so status
  is trackable — do not prompt:

  ```
  mcp__linear__save_issue(title: "<task title>", team: "<parent team>",
    project: "<parent project>", assignee: "me", state: "Todo", priority: 3,
    parentId: "<parent ID>")
  ```

- **No sub-issues, <4 items**: work the checklist items directly; no sub-issues
  needed.

Move the issue (and parent, if a work package) to **In Progress**:
`mcp__linear__save_issue(id: "<ID>", state: "In Progress")`.

Post the execution order as a comment on the issue for the audit trail.

## Step 2: Create local tasks with dependencies

For each work item, create a local task carrying its metadata:

```
TaskCreate(
  subject: "<issue-id>: <short title>",
  description: "<TODO, files, TEST command from the checklist>",
  metadata: {linearIssueId: "<sub-issue ID or parent ID>",
             files: ["path/a.go", ...], validationCommand: "<TEST>"}
)
```

Then model dependencies from the Execution Analysis (file overlap + logical):

```
TaskUpdate(taskId: "<id>", addBlockedBy: ["<dep-task-id>"])
```

Tasks sharing any file are chained. Logical ordering adds blocks where no file
overlap already chains them. Never let two ready tasks touch the same file.

## Step 3: Load dispatch metadata (lean)

Read the worktree's CLAUDE.md and extract **only**: test command, build command,
lint/format commands, primary language. Do not read the whole file.

Record the language guideline path (do not read it): Go →
`~/.myai/lang-guides/go/go-guidelines.md`; Python →
`~/.myai/lang-guides/python/python-guidelines.md`. Store as `LANG_GUIDE_PATH`.

If a Linear project exists, list (do not fetch) design docs via
`mcp__linear__list_documents(projectId: "<project ID>")`; store IDs as
`DESIGN_DOC_IDS`. Agents fetch what they need themselves.

## Step 4: Parallel dispatch loop

### 4a · Find ready tasks

`TaskList()` → tasks with `status=pending` and no incomplete blockers.
- None ready and none in progress → all done, exit loop (Step 5).
- None ready but some in progress → wait for agents to return.

### 4b · Dispatch all ready tasks in one message

For each ready task: `TaskUpdate(taskId, status: in_progress)`, gather completed
blockers' `metadata.summary` + `crossTaskNotes`, then spawn **all** ready agents
in a single message so they run concurrently:

```
Agent(
  description: "<issue-id>: <short task title>",
  prompt: "## Task
<TODO from the work item>

## Issue ID
<sub-issue ID or parent ID>

## Files to modify
<files from task metadata>

## Cross-task context
<summary + crossTaskNotes from completed blockers; omit if none>

## Context references
- Language guidelines: <LANG_GUIDE_PATH or omit>
- Design docs (fetch via mcp__linear__get_document if needed): <DESIGN_DOC_IDS or omit>

## Instructions
1. Read CLAUDE.md and the language guidelines. Fetch a design doc only if needed.
2. Read the listed files to understand current state.
3. Implement exactly what the task requires — nothing more.
4. Run the validation command (or targeted tests for the changed files).
5. If validation fails, fix and retry. After 3 failed attempts, report the
   failure with the error output — do NOT skip or fake it.
6. Run formatters and linters.
7. Stage only your files and commit:
   git add <specific files>
   git commit -m '<issue-id>: <imperative description>

   Co-Authored-By: Claude <model> <noreply@anthropic.com>'
8. Return a COMPACT result: what changed, tests passed (yes/no + key line),
   commit hash, any note a dependent task needs. No file contents."
)
```

### 4c · Process results

For each returned agent:
- **Verify the commit**: `git log -1 --oneline` confirms a new commit exists.
- **Success** → `TaskUpdate(taskId, status: completed, metadata: {commitHash,
  summary, crossTaskNotes, filesChanged})`, then update Linear (4d).
- **Failure** → apply the **task-failure policy** below. Do not block unrelated
  tasks; only tasks depending on this one are affected.

### 4d · Update Linear per task

Work package: comment + close the sub-issue, then tick the parent checklist:

```
mcp__linear__save_comment(issueId: "<sub-issue ID>", body: "Completed: <summary>. Validation: pass.")
mcp__linear__save_issue(id: "<sub-issue ID>", state: "Done")
```

Tick the matching item in the parent description (re-fetch first; match by task
title substring, not line number, to survive concurrent ticks):

```
get_issue → replace the matching "- [ ]" with "- [x]" → save_issue
```

Single issue: post progress comment and tick the item the same way.

### 4e · Loop

Return to 4a; dispatch newly unblocked tasks. Repeat until all are completed or a
task is permanently failed.

## Task-failure policy (autonomous)

A subagent reports a task it could not complete after its own 3 internal retries:

1. The orchestrator attempts a diagnosis-and-fix pass: re-dispatch the task once
   with the failure detail and any new cross-task context.
2. If it still fails, this is an **issue-level blocker**. Hand control back to the
   loop's execute-failure handling (SKILL.md step 3): increment
   `retry_counts[<issue-ID>]`; under `max_retries` re-attempt the broader execute;
   at/over `max_retries`, **defer the issue** (`07-deferral-and-exit.md`).
   Leave completed tasks' commits in place — partial progress stays on the branch
   for the human.

Never fake a passing test, never skip a task to "unblock" a commit, never commit
code that fails its validation.

## Step 5: Final validation

With all tasks complete, run the full suite from the worktree using the commands
from Step 3 (e.g. `go test ./... && go vet ./... && go build ./...`). Fix any
failure before proceeding; if unfixable within the issue's retry budget, defer.

## Step 6: Push and raise PR to staging

```bash
git push -u origin "<branch>"
gh pr create --base staging --title "<issue title>" --body "$(cat <<'EOF'
## Summary
<1-2 sentences>

## Changes
<one line per task/sub-issue completed>

## Test results
<final validation summary>

## Linear
<link to the issue>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
EOF
)"
```

Post the PR link on the issue and move it to **In Review**:

```
mcp__linear__save_comment(issueId: "<ID>", body: "PR raised: <URL>\nAll tasks complete; full suite passing.\nBranch: <branch>")
mcp__linear__save_issue(id: "<ID>", state: "In Review")
```

Do **not** merge the PR here — cleanup does the local-staging merge and PR merge.
Proceed to **verify** (`05-verify.md`).

## Rules (execute)

- Single branch, all tasks; no per-task sub-branches.
- One commit per task; never batch.
- Independent tasks run concurrently; same-file tasks are chained.
- Task state (TaskCreate/Update/List) is authoritative and survives compaction.
- PR targets staging, never main. Never merge a PR's review fixes here.
- Lean orchestrator: hold metadata, not file contents. All implementation lives
  in subagent contexts.
