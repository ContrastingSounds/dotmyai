---
description: Merge a verified worktree branch into staging, push so GitHub auto-closes the PR, update the Linear issue, remove the worktree, and delete the branch.
argument-hint: (optional) Linear issue ID (e.g. CON-42) to mark as Done
---

# Cleanup Worktree

Merge a completed and verified worktree branch into staging, push staging so GitHub auto-closes the PR, update the Linear issue, then clean up the worktree and branch. This command assumes `/verify-worktree` has already been run successfully.

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
4. Fast-forward local staging to the remote first: run `git fetch origin`, then `git merge --ff-only origin/staging`. This guards against the Step 4 push being rejected. If the fast-forward fails (local staging has diverged from the remote), **stop** and tell the user to reconcile staging before cleaning up.
5. Run `git merge <branch>` (use the branch name recorded in Step 1).
6. Confirm the merge succeeded. If it fails (it shouldn't if verify-worktree was run), stop and report the error.

## Step 4: Push Staging — GitHub Auto-Closes the PR (Graceful)

Once the merge is in local staging, push it. GitHub marks the PR as **Merged** automatically because the PR's head commits are now reachable from its base branch — no `gh pr merge` is needed.

1. If the repo has no GitHub remote or `gh` is unavailable, note "No GitHub remote — keeping staging local" and continue to Step 5. (The local merge stands; pushing is just skipped.)
2. Run `git push origin staging`.
3. Confirm GitHub recognized the merge: run `gh pr list --head <branch> --json number,state` (or `gh pr view <branch> --json state`). Expect the PR state to be **MERGED**.
4. If no open PR was found for the branch, note "No PR to auto-close — staging pushed" and continue.
5. If the PR is still **OPEN** after the push, do **not** fall back to `gh pr merge`. Note it and continue — surface it in the Step 7 report so the user can check the PR manually.

## Step 5: Remove Worktree and Branch

1. Run `git worktree remove <worktree-path>` using the path recorded in Step 1.
2. Run `git push origin --delete <branch>` to remove the remote branch. If the remote branch doesn't exist (already gone, or no remote), note this and continue.
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
2. Staging pushed; PR auto-closed as merged (or skipped/still-open — state why)
3. Worktree removed
4. Branch deleted
5. Linear issue updated (or skipped — state why)
6. Current state: on staging, working directory clean

## Rules

- **Require verification first.** If staging has commits not in the branch, refuse to proceed and direct the user to `/verify-worktree`.
- **Ask before merging.** Always show the commit list and get confirmation before merging into staging. The confirmation also covers the push in Step 4 — once confirmed, the merge is pushed to remote staging.
- **Do not force-delete.** Use `git branch -d` (not `-D`). If it fails, something is wrong — investigate rather than forcing.
- **Push staging.** After the local merge, push `staging` to origin so GitHub auto-closes the PR. Never push or merge to `main` — the developer promotes `staging` to `main` separately.
- **Clean up completely.** Both the worktree directory and the branch should be removed.
- **Fail gracefully on externals.** If GitHub or Linear steps fail (no PR, no issue, no access), log what happened and continue. Never let an external service failure block the local cleanup.
