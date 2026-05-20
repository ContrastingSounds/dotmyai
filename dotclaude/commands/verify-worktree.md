---
description: Merge staging into the current worktree branch, resolve conflicts, and run tests to verify the branch is ready to merge back.
argument-hint: (optional) path to simulation YAML for testing
---

# Verify Worktree Branch

Bring the current worktree branch up to date with staging, resolve any conflicts, and verify that everything still works. This must be completed successfully before running `/cleanup-worktree`.

## Step 1: Validate Environment

1. Run `git status` and confirm we are **not** on `staging`. If we are on staging, stop and tell the user: "This command should be run from a worktree branch, not staging."
2. Record the current branch name and working directory.
3. Check for uncommitted changes. If there are any, stop and tell the user: "Please commit or stash your changes before verifying the worktree."

## Step 2: Merge Main into Branch

1. Run `git fetch origin` to ensure we have the latest remote state.
2. Run `git merge staging` to bring staging's changes into the worktree branch.
3. If there are **merge conflicts**:
   - List the conflicted files for the user.
   - Attempt to understand each conflict by reading the conflicted sections.
   - For straightforward textual conflicts, resolve them and explain what you did.
   - For conflicts that involve logical decisions (e.g., both sides changed the same function differently), explain the conflict to the user and ask which resolution they prefer before proceeding.
   - After all conflicts are resolved, stage the resolved files and complete the merge commit.
4. If the merge is clean, confirm this to the user.

## Step 3: Run Validation

Verify the branch is healthy after merging staging:

1. Detect the project's language and build system (check for `go.mod`, `Package.swift`, `package.json`, `pyproject.toml`, `Makefile`, etc.).
2. Run the project's build command (e.g., `go build ./...`, `swift build`, `npm run build`, `uv run python -m py_compile ...`).
3. Run the project's test suite (e.g., `go test ./...`, `swift test`, `npm test`, `uv run pytest`).
4. If the project's CLAUDE.md specifies particular validation commands, run those instead.
5. If the user provided `$ARGUMENTS`, interpret them as additional test targets or flags and run accordingly.

## Step 4: Report Results

Summarize the outcome:

1. **Merge result**: clean merge, or conflicts resolved (list what was resolved)
2. **Test results**: pass/fail for each test run
3. **Verdict**: either "Branch is verified and ready for `/cleanup-worktree`" or "Issues found that need attention" with details

If tests fail after the merge, help the user diagnose and fix the failures. Do not tell them the branch is ready until tests pass.

## Rules

- **Do not merge into staging.** This command only merges staging *into* the branch.
- **Do not delete the branch or worktree.** That is the job of `/cleanup-worktree`.
- **Stop on uncommitted changes.** The user must have a clean working tree before starting.
- **Be transparent about conflicts.** Always explain what changed and why you chose a resolution, or ask when it requires judgment.
