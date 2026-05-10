---
description: Merge a verified worktree branch into main, remove the worktree, delete the branch, and optionally update Linear.
argument-hint: (optional) Linear issue ID (e.g. CON-42) to mark as Done
---

# Cleanup Worktree

Merge a completed and verified worktree branch into main, then clean up the worktree and branch. This command assumes `/verify-worktree` has already been run successfully.

## Input

Optional Linear issue identifier: $ARGUMENTS

## Step 1: Validate Environment

1. Run `git status` and confirm we are **not** on `main`. If we are on main, stop and tell the user: "Run this command from the worktree branch you want to merge, not from main."
2. Record the current branch name and the worktree working directory path.
3. Check for uncommitted changes. If there are any, stop and tell the user: "Please commit or stash your changes before cleaning up."

## Step 2: Verify Branch is Up to Date

1. Run `git log main..HEAD --oneline` to show what commits will be merged.
2. Run `git log HEAD..main --oneline` to check if main has commits not in this branch.
   - If main has commits not in the branch, **stop** and tell the user: "Main has commits not in this branch. Run `/verify-worktree` first to merge main into the branch and run tests before cleaning up."
3. Show the user the list of commits that will be merged and ask for confirmation before proceeding.

## Step 3: Merge into Main

1. Identify the path to the main repo. The worktree is typically at `../<repo>-<branch>` relative to the main repo. Use `git worktree list` to find the main working tree path.
2. Change to the main repo directory.
3. Run `git checkout main`.
4. Run `git merge <branch>` (use the branch name recorded in Step 1).
5. Confirm the merge succeeded. If it fails (it shouldn't if verify-worktree was run), stop and report the error.

## Step 4: Remove Worktree and Branch

1. Run `git worktree remove <worktree-path>` using the path recorded in Step 1.
2. Run `git branch -d <branch>` to delete the branch.
3. Confirm both succeeded. If the branch delete fails with "not fully merged", warn the user — this indicates something went wrong.

## Step 5: Update Linear (Optional)

If the user provided a Linear issue identifier in `$ARGUMENTS`:

1. Parse the identifier (e.g., `CON-42`).
2. Use `mcp__claude_ai_Linear__get_issue` to fetch the issue.
3. Use `mcp__claude_ai_Linear__save_comment` to add a comment summarizing the merge:
   - Branch name that was merged
   - Number of commits merged
   - Brief summary of what the commits contain (from git log)
4. Use `mcp__claude_ai_Linear__save_issue` to move the issue to **Done** state.

## Step 6: Report

Summarize what was done:

1. Branch merged into main
2. Worktree removed
3. Branch deleted
4. Linear issue updated (if applicable)
5. Current state: on main, working directory clean

## Rules

- **Require verification first.** If main has commits not in the branch, refuse to proceed and direct the user to `/verify-worktree`.
- **Ask before merging.** Always show the commit list and get confirmation before merging into main.
- **Do not force-delete.** Use `git branch -d` (not `-D`). If it fails, something is wrong — investigate rather than forcing.
- **Do not push.** Merging to local main only. The user decides when to push.
- **Clean up completely.** Both the worktree directory and the branch should be removed.
