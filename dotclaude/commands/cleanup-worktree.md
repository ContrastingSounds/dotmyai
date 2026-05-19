---
description: Merge a verified worktree branch into staging, close the GitHub PR and Linear issue, remove the worktree, and delete the branch.
argument-hint: (optional) Linear issue ID (e.g. CON-42) to mark as Done
---

# Cleanup Worktree

Merge a completed and verified worktree branch into staging, close related GitHub and Linear items, then clean up the worktree and branch. This command assumes `/verify-worktree` has already been run successfully.

Each external step (GitHub, Linear) fails gracefully — if there's no PR or no issue, skip that step and continue.

## Input

Optional Linear issue identifier: $ARGUMENTS

## Step 1: Validate Environment

1. Run `git status` and confirm we are **not** on `staging`. If we are on staging, stop and tell the user: "Run this command from the worktree branch you want to merge, not from staging."
2. Record the current branch name and the worktree working directory path.
3. Check for uncommitted changes. If there are any, stop and tell the user: "Please commit or stash your changes before cleaning up."

## Step 2: Verify Branch is Up to Date

1. Run `git log staging..HEAD --oneline` to show what commits will be merged.
2. Run `git log HEAD..staging --oneline` to check if staging has commits not in this branch.
   - If staging has commits not in the branch, **stop** and tell the user: "Staging has commits not in this branch. Run `/verify-worktree` first to merge staging into the branch and run tests before cleaning up."
3. Show the user the list of commits that will be merged and ask for confirmation before proceeding.

## Step 3: Merge into Staging

1. Identify the path to the main repo. The worktree is typically at `../<repo>-<branch>` relative to the main repo. Use `git worktree list` to find the main working tree path.
2. Change to the main repo directory.
3. Run `git checkout staging`.
4. Run `git merge <branch>` (use the branch name recorded in Step 1).
5. Confirm the merge succeeded. If it fails (it shouldn't if verify-worktree was run), stop and report the error.

## Step 4: Close GitHub PR (Graceful)

1. Run `gh pr list --head <branch> --state open --json number,title` to find any open PR for the branch.
2. If no open PR exists, note "No open GitHub PR found — skipping" and continue to Step 5.
3. If a PR exists, run `gh pr close <number> --delete-branch --comment "Merged to staging locally via /cleanup-worktree"`. The `--delete-branch` flag removes the remote branch on GitHub.
4. If `gh` is not available or the repo has no GitHub remote, note this and continue.

## Step 5: Remove Worktree and Branch

1. Run `git worktree remove <worktree-path>` using the path recorded in Step 1.
2. If Step 4 did not delete the remote branch (no PR found, or `gh` unavailable), run `git push origin --delete <branch>` to remove it. If the remote branch doesn't exist, note this and continue.
3. Run `git fetch --prune` to clean up stale remote tracking references.
4. Run `git branch -d <branch>` to delete the local branch.
5. Confirm all succeeded. If the branch delete fails with "not fully merged", warn the user — this indicates something went wrong.

## Step 6: Update Linear (Graceful)

Determine the Linear issue to update:

1. If the user provided a Linear issue identifier in `$ARGUMENTS`, use that.
2. Otherwise, try to extract an issue identifier from the branch name (e.g., a branch named `con-42-add-feature` maps to `CON-42`). Look for patterns like `[A-Z]+-[0-9]+` at the start of the branch name (case-insensitive).
3. If no identifier is found by either method, note "No Linear issue identified — skipping" and continue to Step 7.

Once an identifier is resolved:

1. Use `mcp__linear__get_issue` to fetch the issue. If the fetch fails (e.g. invalid ID, no Linear access), note this and continue to Step 7.
2. Use `mcp__linear__save_comment` to add a comment summarizing the merge:
   - Branch name that was merged
   - Number of commits merged
   - Brief summary of what the commits contain (from git log)
3. Use `mcp__linear__save_issue` to move the issue to **Done** state.

## Step 7: Report

Summarize what was done:

1. Branch merged into staging
2. GitHub PR closed (or skipped — state why)
3. Worktree removed
4. Branch deleted
5. Linear issue updated (or skipped — state why)
6. Current state: on staging, working directory clean

## Rules

- **Require verification first.** If staging has commits not in the branch, refuse to proceed and direct the user to `/verify-worktree`.
- **Ask before merging.** Always show the commit list and get confirmation before merging into staging.
- **Do not force-delete.** Use `git branch -d` (not `-D`). If it fails, something is wrong — investigate rather than forcing.
- **Do not push.** Merging to local staging only. The user decides when to push.
- **Clean up completely.** Both the worktree directory and the branch should be removed.
- **Fail gracefully on externals.** If GitHub or Linear steps fail (no PR, no issue, no access), log what happened and continue. Never let an external service failure block the local cleanup.
