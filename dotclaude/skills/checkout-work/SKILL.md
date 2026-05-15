---
description: Resolve a Linear Project, Linear Issue, GitHub PR, or git branch to the correct branch, create or reuse a worktree, and enter it.
argument-hint: project name, issue ID (CON-123), PR number (1234), or branch name
---

# Checkout Work

Given a reference to work — a Linear project name, Linear issue ID, GitHub PR number, or remote git branch — resolve it to a branch, create or reuse a local worktree, and switch the session into it.

## Input

Work reference: $ARGUMENTS

## Script

All git and GitHub CLI operations are handled by the colocated script:

```
SCRIPT=~/.myai/dotclaude/skills/checkout-work/scripts/checkout-work.sh
```

## Step 1: Pre-flight

```bash
$SCRIPT preflight
```

Parse the output. If `ERROR` is present, stop and report the error to the user. Otherwise, record `REPO` for later use.

## Step 2: Resolve

```bash
$SCRIPT resolve "$ARGUMENTS"
```

Parse the output and proceed based on `TYPE`:

### TYPE=pr

Branch is resolved. If `PR_STATE` is `MERGED` or `CLOSED`, warn the user and ask whether to proceed. Otherwise go to Step 3 with `$BRANCH` and `--track`.

### TYPE=issue

- If `BRANCH` is set → go to Step 3 with `$BRANCH` and `--track`.
- If `MULTIPLE=true` → show the branches from `BRANCHES` (pipe-delimited) and ask the user which to use. Then go to Step 3 with the chosen branch and `--track`.
- If neither `BRANCH` nor `MULTIPLE` is set → no remote branch exists. Fetch the issue from Linear to get context:
  ```
  mcp__linear__get_issue(id: "$ARGUMENTS", includeRelations: true)
  ```
  Derive a branch name: `${ISSUE_ID}-<2-4 word slug from issue title>`. Go to Step 3 with the derived branch and `--new`.

### TYPE=branch

Branch is resolved. Go to Step 3 with `$BRANCH` and `--track`.

### TYPE=unknown

The input did not match a PR number, issue ID, or remote branch. Try Linear project resolution:

```
mcp__linear__list_projects()
```

Match the input against project names (case-insensitive exact match first, then substring).

- **No match** → stop: "Could not resolve '$ARGUMENTS' as a git branch or Linear project."
- **Match found** → list project issues:
  ```
  mcp__linear__list_issues(projectId: "<project ID>")
  ```
  Filter to issues with state "In Progress" or "Todo". For each candidate, run:
  ```bash
  $SCRIPT resolve <issue-id>
  ```
  to check for matching remote branches.

  - **One branch found** → go to Step 3 with that branch and `--track`.
  - **Multiple branches** → list the issues with their branches, ask user which to check out.
  - **No branches, but active issues** → list the issues, ask which to start. Derive branch name from chosen issue and go to Step 3 with `--new`.
  - **No active issues** → stop: "Project '<name>' has no in-progress or todo issues."

## Step 3: Create or Reuse Worktree

Extract the issue ID from `$BRANCH` — the first segment matching `<letters>-<digits>` (e.g., `con-129` from `con-129-code-review-fixes`). If no issue ID can be extracted, use the full branch name as the directory suffix.

```bash
$SCRIPT create-worktree "$BRANCH" "$ISSUE_ID" --track
```

or for a new branch:

```bash
$SCRIPT create-worktree "$BRANCH" "$ISSUE_ID" --new
```

Parse the output:
- If `ERROR` → report to user and stop.
- If `STATUS=exists` → note that an existing worktree was reused.
- If `STATUS=created` → note that a new worktree was created.

Record `WORKTREE_PATH`.

## Step 4: Enter Worktree

```
EnterWorktree(path: "$WORKTREE_PATH")
```

## Step 5: Report

Summarize what happened:

- **Resolved**: what the input was classified as and what it resolved to
- **Branch**: the branch name
- **Worktree**: path (new or existing)
- **Linear context** (if applicable): issue title, status, project name

## Rules

- **Use the script for all git/gh operations.** Do not run inline git or gh commands.
- **Never cd or pushd.** Use `EnterWorktree` to switch into the worktree.
- **Never create branches for unresolved inputs.** If nothing matches, report what was tried and stop.
- **Reuse before create.** The script checks `git worktree list` before creating.
- **Branch from staging.** New branches start from `origin/staging`, per the branching model.
- **Lowercase issue IDs.** Branch names use lowercase issue IDs.
- **Do not start implementation.** This skill only sets up the worktree.
