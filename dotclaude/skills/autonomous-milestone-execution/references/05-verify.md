# 05 · Verify (loop step 4)

Bring the worktree branch up to date with staging, resolve any conflicts with
documented judgment, and confirm the full suite passes. Ported from the
verification skill, rewritten to resolve conflicts and recover state
autonomously. Run inline (you are in the worktree).

This must pass before cleanup. It never merges *into* staging — only staging
*into* the branch.

## Step 1: Validate environment

1. `git status`. If somehow on `staging`, `git checkout <branch>` and continue
   (do not stop).
2. If there are uncommitted changes, **commit them automatically**:
   `git add -A && git commit -m "<issue-id>: wip before verify"`. Then continue.
3. Record the branch name and worktree path.

## Step 2: Merge staging into the branch

```bash
git fetch origin
git merge staging
```

**On merge conflicts** — resolve autonomously, do not ask:

1. List the conflicted files (for the log).
2. Read each conflict hunk and resolve it with best judgment:
   - **Independent changes on both sides** → keep both.
   - **Mutually exclusive changes** → prefer this issue's intent (its branch is
     the unit of work being delivered), unless staging's side is clearly a
     security/correctness fix, in which case keep staging's and adapt this issue's
     change around it.
   - **Generated/lockfiles** → regenerate from source rather than hand-merging.
3. Stage resolved files and complete the merge commit. In the merge commit body,
   record each non-trivial resolution and why:

   ```
   Merge staging into <branch>

   Conflict resolutions:
   - <file>: <what was chosen and why, 1 line>
   ```

4. Post a Linear comment summarizing any non-trivial resolution so it is auditable
   the next morning.

If the merge is clean, note that and continue.

## Step 3: Run validation

1. Detect the build system (go.mod / package.json / pyproject.toml / Makefile).
2. Run build, then the test suite, using the project's CLAUDE.md commands if it
   specifies them (e.g. `go build ./... && go test ./...`).

## Step 4: Decide

- **Build + tests pass** → branch is verified. Proceed to **cleanup**
  (`06-cleanup.md`).
- **Failures** → diagnose and fix within this issue's retry budget
  (`retry_counts[<issue-ID>]` against `max_retries`):
  - A failure caused by your own conflict resolution → fix the resolution,
    re-commit, re-run.
  - A genuine post-merge regression in this branch → fix it, commit, re-run.
  - If it cannot be made green within the budget, or the fix would require
    cross-issue design decisions you cannot make safely → **defer the issue**
    (`07-deferral-and-exit.md`) and return to triage.

Never declare the branch verified while build or tests fail. Never disable or
skip a test to make it pass.

## Rules (verify)

- Merge staging into the branch only — never the reverse.
- Do not delete the branch or worktree (that is cleanup's job).
- Resolve conflicts autonomously, but always record what changed and why.
