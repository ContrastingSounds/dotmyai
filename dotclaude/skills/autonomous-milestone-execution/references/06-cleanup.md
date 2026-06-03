# 06 · Cleanup (loop step 5)

Merge the verified branch into **local staging**, merge the GitHub PR, tear down
the worktree and branch, and mark the issue Done. Ported from the cleanup skill,
rewritten to proceed without the confirmation prompt. Run inline.

Assumes `05-verify.md` passed. External steps (GitHub, Linear) fail gracefully —
if there is no PR or no issue, skip and continue. **Never push staging. Never
touch main.**

## Step 1: Validate environment

1. `git status`. If on `staging`, check out the branch and continue. If there are
   uncommitted changes, **commit them automatically**
   (`git add -A && git commit -m "<issue-id>: wip before cleanup"`).
2. Record the branch name and worktree path.

## Step 2: Confirm the branch is current

```bash
git log staging..HEAD --oneline   # what will merge
git log HEAD..staging --oneline   # staging commits not in the branch
```

If staging has commits the branch lacks, run **verify** (`05-verify.md`) once to
reconcile (merge staging in + re-test), then return here. Do not stop.

## Step 3: Merge into local staging (no confirmation)

```bash
# find the main working tree
git worktree list   # locate the main repo path
```

In the main repo:

```bash
git checkout staging
git merge <branch>
```

Proceed without asking. Log the merged commit list (from Step 2) into the Linear
comment in Step 6 for the audit trail. If the merge fails (it should not after
verify), defer the issue and report — do not force.

## Step 4: Merge the GitHub PR (graceful)

```bash
gh pr list --head <branch> --state open --json number,title
```

- No open PR → note "no open PR — skipping" and continue.
- PR exists → `gh pr merge <number> --merge --delete-branch --body "Merged to staging locally via autonomous run"`.
- `gh` unavailable / no GitHub remote → note it and continue.

## Step 5: Remove worktree and branch

```bash
git worktree remove <worktree-path>
# if Step 4 didn't delete the remote branch:
git push origin --delete <branch>   # ignore "remote branch missing"
git fetch --prune
git branch -d <branch>              # safe delete; if it refuses, investigate, do not -D
```

If `git branch -d` refuses ("not fully merged"), something went wrong — defer the
issue with that detail rather than force-deleting.

## Step 6: Update Linear (graceful)

Resolve the issue ID (from the loop, or from the branch name pattern
`[A-Z]+-[0-9]+`). Then:

```
mcp__linear__save_comment(issueId: "<ID>", body: "Merged <branch> into staging (<N> commits).\n<brief summary of commits>\nPR: <merged/skipped>.")
mcp__linear__save_issue(id: "<ID>", state: "Done")
```

If Linear fetch/save fails, note it and continue — do not let an external failure
block local cleanup.

## Step 7: Post epic progress + reset counters

Comment on the parent epic (or the issue, if standalone):

```
Completed <issue-ID>: <title>.
Milestone progress: <done>/<total> issues (<deferred> deferred).
Next: <next issue ID + title, or "assessing">.
```

Reset run state: `retry_counts[<issue-ID>] = 0`; `consecutive_defers = 0`
(a success breaks the defer streak).

Return to **triage** (`02-triage.md`).

## Rules (cleanup)

- Merge to **local staging only** — never `git push` staging, never merge to main.
- No confirmation gate — proceed, but always log the merged commit list to Linear.
- Safe delete only (`git branch -d`); investigate refusals, never `-D`.
- Fail gracefully on GitHub/Linear; never let externals block local teardown.
