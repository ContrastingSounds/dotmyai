# Configuration

Git branching strategy for a solo developer using autonomous coding agents.

## Branching Model

Two long-lived branches, one short-lived branch per unit of work:

```
main        stable — manually promoted from staging
staging     integration — receives PRs from work branches
work-*      short-lived — one per issue or work package, deleted after merge
```

### Why `staging`

Autonomous agents can complete work and raise PRs without pushing to main. The developer reviews the PR at their own pace, merges to `staging`, and manually promotes `staging` to `main` when satisfied. This is the lightest possible gate that still prevents unreviewed agent code from landing on main.

### Branch flow

```
staging  ← PR ←  work branch   (agent creates branch, raises PR)
main     ← merge ←  staging    (developer decides when)
```

Agents never target `main`. Agents never merge their own PRs.

## Work Branch Conventions

### Branching point

Always branch from `staging`:

```sh
git fetch origin
git worktree add ../<repo>-<issue-id> -b <issue-id>-<description> origin/staging
```

### Naming

- **Branch**: `<issue-id>-<short-description>` (e.g., `con-129-review-findings`)
- **Directory**: `../<repo>-<issue-id>` (e.g., `../mock_machines-con-129`)

Use lowercase issue IDs. Keep descriptions to 2-4 words.

### PR target

Every PR targets `staging`. The PR title matches the parent issue title. The PR body includes:
- Summary of changes (one line per sub-issue or task)
- Test results
- Link to the Linear issue

## Staging to Main

Manual merge when the developer is satisfied. No prescribed cadence — could be after one PR or after accumulating several.

```sh
git checkout main
git merge staging
git push origin main
```

No squash needed. The commit-per-task history from work branches is already clean.

## One-Time Setup

Ensure `staging` exists locally and on the remote:

```sh
git branch staging main
git push -u origin staging
```

If the remote already has `staging`, just track it:

```sh
git fetch origin
git branch --track staging origin/staging
```

## Worktrees

Use standard git worktrees for all development work. Do NOT use `claude --worktree` or `-w` — those are for Claude's internal sub-agents and use `.claude/worktrees/` with auto-managed naming.

For manual worktree management, convenience functions, and shared-resource gotchas, see `docs/dev-workflow.md`.

### Quick reference

```sh
# Create worktree from staging
git fetch origin
git worktree add ../<repo>-<issue-id> -b <branch> origin/staging

# Cleanup after PR is merged
git worktree remove ../<repo>-<issue-id>
git branch -d <branch>
```

## Related

- `docs/dev-workflow.md` — worktree conventions, convenience functions (`new-tree`, `plan-tree`), shared-resource gotchas
- `01-04-work-packages-and-trees.md` — bundling related changes into a work package
