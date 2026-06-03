# 02 · Triage (loop step 1)

Assess current state from Linear + git, then take the first matching action. This
also handles entering or creating the worktree for the chosen issue, so the next
phase runs in the right place.

Keep this lean: query Linear directly rather than invoking the `/project-status`
skill. You only need enough to make the triage decision.

## Step 1: Assess

Run these in parallel:

```
mcp__linear__list_issues(milestone: "<milestone ID>", state: "In Progress")
mcp__linear__list_issues(milestone: "<milestone ID>", state: "In Review")
mcp__linear__list_issues(milestone: "<milestone ID>", state: "Todo")
```

```bash
git worktree list
git fetch --quiet origin
```

**Exclude any issue carrying `BLOCKED_LABEL`** from every category — those are
quarantined and not eligible this run.

Classify:
1. **In Progress** (not quarantined) — a prior attempt that was interrupted.
2. **In Review** (not quarantined) — has a PR but not yet verified/cleaned up.
3. **Concerns** — surfaced by the git/Linear data: an In Progress issue with no
   worktree, a worktree with no matching issue, staging/main drift, stale merged
   branches.
4. **Todo** (not quarantined), sorted by priority.

## Step 2: Triage — first matching action

### 2a · Interrupted work (In Progress issue exists)

1. Enter its worktree (Step 3 below) — resolve via the issue ID.
2. `git status` — if there are uncommitted changes, **commit them automatically**:
   `git add -A && git commit -m "<issue-id>: wip recovered by autonomous run"`.
   Do not stash-and-ask; a recovery commit is safe in the sandbox.
3. Query sub-issue statuses (`mcp__linear__list_issues(parentId: "<issue-ID>")`):
   - All sub-issues Done → execution finished, verify/cleanup skipped → go to
     **verify** (`05-verify.md`).
   - Some Todo/In Progress → resume → go to **execute** (`04-execute.md`).

### 2b · Pending verification (In Review issue exists)

1. Enter its worktree (Step 3).
2. Go to **verify** (`05-verify.md`).

### 2c · Concerns

1. Resolve anything safe without a human:
   - Stale verified/merged branch → run cleanup (`06-cleanup.md`) for it.
   - Lingering merged branches → delete them.
   - A worktree merge conflict → resolve per `05-verify.md`'s conflict rules.
2. **staging/main drift** → log it for the morning summary. Do **not** promote.
3. A concern tied to a specific issue you cannot resolve safely → treat as a
   deferral of *that issue* (`07-deferral-and-exit.md`), not a halt. A concern
   tied to no issue and not safely resolvable → record it and continue.
4. Re-assess (return to Step 1).

### 2d · Pick next issue

1. From non-quarantined Todo issues, select the highest-priority **unblocked**
   one. Respect epic dependencies: do not start an issue whose predecessor epics
   have incomplete (non-quarantined) work.
   - An issue blocked *only* by quarantined predecessors is transitively blocked —
     skip it (it cannot complete until a human clears the quarantine). This is
     not a failure; it is simply ineligible.
2. If no eligible Todo issue remains → go to **Exit Conditions**
   (`07-deferral-and-exit.md`).
3. Otherwise, enter/create the worktree (Step 3), then go to **validate**
   (`03-validate.md`).

## Step 3: Enter or create the worktree

Ported from the worktree-resolution logic, made autonomous (reuse on conflict,
pick by convention on ambiguity). Use the issue ID throughout.

```bash
REPO=$(basename "$(git rev-parse --show-toplevel)")
ISSUE_ID="<lowercase issue id>"   # e.g. con-129
git fetch origin
```

**Resolve the branch:**

1. Look for an existing remote branch for the issue:
   `git branch -r --list "origin/${ISSUE_ID}-*"`.
   - **One match** → use it (`--track`).
   - **Multiple matches** → pick the one whose name best matches the issue-ID
     convention `${ISSUE_ID}-<slug>`; if still tied, the most recently committed
     (`git for-each-ref --sort=-committerdate`). Record the choice.
   - **No match** → derive a new branch name `${ISSUE_ID}-<2-4 word slug from the
     issue title>` (fetch the title from Linear if not already held).

2. Look for an existing worktree: check `git worktree list` for a path on the
   resolved branch.
   - **Exists** → **reuse it** (do not recreate). Record `WORKTREE_PATH`.
   - **Does not exist** → create it:

     ```bash
     # existing remote branch:
     git worktree add "../${REPO}-${ISSUE_ID}" --track -b "<branch>" "origin/<branch>"
     # OR new branch from staging:
     git worktree add "../${REPO}-${ISSUE_ID}" -b "<branch>" origin/staging
     ```

     If `origin/staging` does not exist, **create it automatically** (safe in
     sandbox): `git branch staging main && git push -u origin staging`, then
     retry the worktree add.

     Record `WORKTREE_PATH = ../${REPO}-${ISSUE_ID}`.

3. Enter it (this moves your session — required so subsequent phases run in the
   worktree):

   ```
   EnterWorktree(path: "<WORKTREE_PATH>")
   ```

All subsequent commands run from the worktree. Never use `cd`/`pushd`/`popd` to
switch — use `EnterWorktree`/`ExitWorktree`.
