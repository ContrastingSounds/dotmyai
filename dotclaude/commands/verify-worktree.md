---
description: Merge main into the current worktree branch, resolve conflicts, and run tests to verify the branch is ready to merge back.
argument-hint: (optional) path to simulation YAML for testing
---

# Verify Worktree Branch

Bring the current worktree branch up to date with main, resolve any conflicts, and verify that everything still works. This must be completed successfully before running `/cleanup-worktree`.

## Step 1: Validate Environment

1. Run `git status` and confirm we are **not** on `main`. If we are on main, stop and tell the user: "This command should be run from a worktree branch, not main."
2. Record the current branch name and working directory.
3. Check for uncommitted changes. If there are any, stop and tell the user: "Please commit or stash your changes before verifying the worktree."

## Step 2: Merge Main into Branch

1. Run `git fetch origin` to ensure we have the latest remote state.
2. Run `git merge main` to bring main's changes into the worktree branch.
3. If there are **merge conflicts**:
   - List the conflicted files for the user.
   - Attempt to understand each conflict by reading the conflicted sections.
   - For straightforward textual conflicts, resolve them and explain what you did.
   - For conflicts that involve logical decisions (e.g., both sides changed the same function differently), explain the conflict to the user and ask which resolution they prefer before proceeding.
   - After all conflicts are resolved, stage the resolved files and complete the merge commit.
4. If the merge is clean, confirm this to the user.

## Step 3: Run Tests

Run the following tests to verify the branch is healthy after merging main:

```bash
go test ./pkg/fsm/ -v
```

```bash
go run main.go -testAll -test "" simulations/PaymentProcessor/mock-machine.yaml
```

If the user provided a simulation YAML path as an argument (`$ARGUMENTS`), also run:

```bash
go run main.go -testAll -test "" $ARGUMENTS
```

## Step 4: Report Results

Summarize the outcome:

1. **Merge result**: clean merge, or conflicts resolved (list what was resolved)
2. **Test results**: pass/fail for each test run
3. **Verdict**: either "Branch is verified and ready for `/cleanup-worktree`" or "Issues found that need attention" with details

If tests fail after the merge, help the user diagnose and fix the failures. Do not tell them the branch is ready until tests pass.

## Rules

- **Do not merge into main.** This command only merges main *into* the branch.
- **Do not delete the branch or worktree.** That is the job of `/cleanup-worktree`.
- **Stop on uncommitted changes.** The user must have a clean working tree before starting.
- **Be transparent about conflicts.** Always explain what changed and why you chose a resolution, or ask when it requires judgment.
