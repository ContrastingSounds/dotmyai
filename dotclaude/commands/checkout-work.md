---
description: Resolve a Linear Project, Linear Issue, GitHub PR, or git branch to the correct branch, create or reuse a worktree, and enter it.
argument-hint: Linear project name, issue ID (CON-123), PR number (1234), or branch name
---

# Checkout Work

Given a reference to work — a Linear project name, Linear issue ID, GitHub PR number, or remote git branch — resolve it to a branch, create or reuse a local worktree, and switch the session into it.

## Input

Work reference: $ARGUMENTS

## Step 1: Pre-flight Checks

1. Confirm we are in a git repository: `git rev-parse --show-toplevel`
   - If not, stop: "This command must be run from inside a git repository."

2. Check if we are already inside a linked worktree:
   ```bash
   GIT_DIR=$(git rev-parse --git-dir)
   GIT_COMMON=$(git rev-parse --git-common-dir)
   ```
   - If `$GIT_DIR` != `$GIT_COMMON`, stop: "You are already inside a worktree. Exit it first before checking out new work."

3. Fetch latest remote state:
   ```bash
   git fetch origin
   ```

4. Record the repo name for worktree directory naming:
   ```bash
   REPO=$(basename "$(git rev-parse --show-toplevel)")
   ```

## Step 2: Classify and Resolve

Evaluate the input `$ARGUMENTS` against the following rules, in order. Stop at the first match.

### 2a: GitHub PR number

**Pattern**: input is purely digits (`^\d+$`)

```bash
gh pr view $ARGUMENTS --json headRefName,state,title
```

- If the PR does not exist, stop: "No PR #$ARGUMENTS found in this repository."
- If the PR state is `MERGED` or `CLOSED`, warn the user and ask whether to proceed.
- Extract `headRefName` as `$BRANCH`.
- Move to Step 3.

### 2b: Linear Issue ID

**Pattern**: input matches `^[A-Za-z]+-\d+$` (e.g., `CON-123`)

```
mcp__linear__get_issue(id: "$ARGUMENTS", includeRelations: true)
```

- If the issue does not exist, stop: "No Linear issue found for $ARGUMENTS."
- Record the issue title and status.
- Lowercase the issue ID: `ISSUE_ID=$(echo "$ARGUMENTS" | tr '[:upper:]' '[:lower:]')`
- Check for an existing remote branch:
  ```bash
  git ls-remote --heads origin "${ISSUE_ID}-*"
  ```
  - If one branch matches → use it as `$BRANCH`.
  - If multiple match → list them and ask the user which to use.
  - If none match → derive a new branch name: `${ISSUE_ID}-<2-4 word slug from issue title>`. This will be created from `origin/staging` in Step 3.
- Move to Step 3.

### 2c: Ambiguous input (cascade)

For any input that does not match the patterns above — single words, multi-word strings, or hyphenated strings.

**Try remote git branch first** (fast, definitive):

```bash
git ls-remote --heads origin "$ARGUMENTS"
```

- If a match is found → use `$ARGUMENTS` as `$BRANCH`. Move to Step 3.

**Then try Linear Project** (slower, MCP round-trip):

```
mcp__linear__list_projects()
```

- Case-insensitive exact match against project names first, then substring match.
- If no match → stop: "Could not resolve '$ARGUMENTS' as a git branch or Linear project."
- If match found, list project issues:
  ```
  mcp__linear__list_issues(projectId: "<project ID>")
  ```
- Filter to issues with state "In Progress" or "Todo".
- For each candidate issue, check for a matching remote branch:
  ```bash
  git ls-remote --heads origin "<lowercase-issue-id>-*"
  ```
- **Exactly one branch found** → use it as `$BRANCH`.
- **Multiple branches found** → list the issues and their branches, ask the user which to check out.
- **No branches but active issues exist** → list the issues, ask the user which to start. Derive `$BRANCH` as `<issue-id>-<slug>` (new branch from staging).
- **No active issues** → stop: "Project '<name>' has no in-progress or todo issues."
- Move to Step 3.

## Step 3: Create or Reuse Worktree

### 3a: Extract issue ID for directory naming

Extract the issue ID from `$BRANCH` — the first segment matching `<letters>-<digits>` (e.g., `con-129` from `con-129-code-review-fixes`).

If no issue ID can be extracted (rare — e.g., a branch named `feature-xyz`), use the full branch name as the directory suffix.

```
WORKTREE_DIR="../${REPO}-${ISSUE_ID}"
```

### 3b: Check for existing worktree

```bash
git worktree list
```

- If a worktree already exists on `$BRANCH` → record its path as `$WORKTREE_DIR`. Skip to Step 4.

### 3c: Ensure origin/staging exists

Check if `origin/staging` exists (needed for new branches):

```bash
git ls-remote --heads origin staging
```

If it does not exist:
```bash
git branch staging origin/main
git push -u origin staging
```

### 3d: Create worktree

- **Tracking an existing remote branch:**
  ```bash
  git worktree add "$WORKTREE_DIR" "origin/${BRANCH}"
  ```

- **Creating a new branch** (no remote branch existed):
  ```bash
  git worktree add "$WORKTREE_DIR" -b "$BRANCH" origin/staging
  ```

- If the worktree directory already exists (stale state), report the conflict and ask the user how to proceed.

## Step 4: Enter Worktree

```
EnterWorktree(path: "$WORKTREE_DIR")
```

## Step 5: Report

Summarize what happened:

- **Resolved**: what the input was classified as and what it resolved to
- **Branch**: `$BRANCH`
- **Worktree**: `$WORKTREE_DIR` (new or existing)
- **Linear context** (if applicable): issue title, status, project name

## Rules

- **Never cd or pushd.** Use `EnterWorktree` to switch into the worktree.
- **Never create branches for unresolved inputs.** If nothing matches, report what was tried and stop.
- **Reuse before create.** Always check `git worktree list` before creating a new worktree.
- **Branch from staging.** New branches always start from `origin/staging`, per the branching model.
- **Lowercase issue IDs.** Branch names use lowercase issue IDs (e.g., `con-129`, not `CON-129`).
- **Do not start implementation.** This skill only sets up the worktree. The user decides what to do next.
