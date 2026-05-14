# Work Packages and Worktrees

How to bundle related changes into a single worktree and execute them as a unit.

## What Is a Work Package

A work package is a set of related changes that share one branch, one worktree, and one PR. Each change gets its own commit. The whole package is reviewed and merged as a single PR.

Examples:
- **Code review findings**: `/codebase-review` generates a parent issue with sub-issues for each finding. All findings are implemented on one branch.
- **Feature decomposition**: A feature issue is split into sub-issues for each component. All components land in one PR.
- **Refactoring batch**: Related cleanup tasks grouped under a parent issue.

The common thread: the changes are related, touch overlapping context, and are too small individually to justify separate PRs.

## When to Bundle

Bundle changes into a work package when any of these apply:

- A parent issue already has sub-issues (e.g., code review output)
- Changes share context (same module, same types, same test suite)
- Changes touch overlapping files (separate PRs would conflict)
- Changes are small enough that individual PRs would be overhead

Do NOT bundle when:
- Changes are independent and could be reviewed separately
- A single change is large enough to warrant its own PR and review cycle
- Changes have different risk profiles (don't mix a one-line fix with a refactor)

## Worktree Setup

Always use standard git worktrees. See `01-03-configuration.md` for the branching model.

```sh
git fetch origin
git worktree add ../<repo>-<issue-id> -b <issue-id>-<description> origin/staging
cd ../<repo>-<issue-id>
```

The worktree branches from `staging` and the PR will target `staging`.

For convenience functions and shared-resource gotchas, see `docs/dev-workflow.md`.

### Naming

- **Branch**: `<issue-id>-<short-description>` — the parent issue ID, not sub-issue IDs
- **Directory**: `../<repo>-<issue-id>`

Example for CON-129 in the mock_machines repo:
```sh
git worktree add ../mock_machines-con-129 -b con-129-review-findings origin/staging
```

## Mapping Sub-Issues to Commits

Each sub-issue in the work package maps to exactly one commit on the shared branch.

### Commit message format

```
<issue-id>: <imperative description>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

Use the sub-issue ID (e.g., `con-130`), not the parent ID. First line under 72 characters.

### Example

For CON-129 with sub-issues CON-130 through CON-136:
```
con-130: replace deprecated strings.Title with shared titleCase helper
con-131: add FieldIndex map to StateMachine for O(1) field lookups
con-132: use cached AgeIdx/TurnIdx in StepWithForcedEvent
...
```

## Dependency Ordering

Before starting work, determine the order in which sub-issues should be executed. The goal is to minimize merge conflicts and ensure each commit builds on a stable base.

### Ordering criteria (in priority order)

1. **Logical dependencies**: If Task B uses types or functions introduced by Task A, do A first.
2. **File overlap**: If two tasks modify the same file, run them back-to-back. This keeps changes additive rather than conflicting.
3. **Minimize context switches**: Group tasks that touch the same area of the codebase.

### Procedure

1. For each sub-issue, identify the files it will modify (from the issue description or by reading the code).
2. Build a dependency graph based on file overlap and logical dependencies.
3. Produce a linear execution order that respects the graph.
4. Post the execution order as a comment on the parent issue.

If the agent is executing via `/execute-issue`, this analysis is done automatically in Step 3.

## Lifecycle

### 1. Create

Create a worktree and branch from `staging`. See Worktree Setup above.

### 2. Work

Execute sub-issues in dependency order. For each:
- Read current file state (may have changed from prior tasks)
- Implement the change
- Run targeted tests
- Format, lint, commit
- Update the sub-issue in Linear

See `02-01-task-management.md` for Linear conventions, `02-03-coding.md` for coding discipline, `02-04-testing.md` for testing decisions.

### 3. Test

After all sub-issues are complete, run the full test suite from the worktree. Fix any cross-cutting regressions before proceeding.

### 4. PR

Push the branch and raise a PR targeting `staging`:

```sh
git push -u origin <branch>
gh pr create --base staging --title "<parent issue title>" --body "..."
```

The PR body should list all sub-issues completed and final test results.

### 5. Cleanup

After the PR is merged (by the developer), remove the worktree:

```sh
git worktree remove ../<repo>-<issue-id>
git branch -d <branch>
```

Or use `/cleanup-worktree` to automate this and update Linear.

## Automated Execution

Use `/execute-issue <parent-issue-id>` to execute a work package end-to-end. The skill handles worktree creation, dependency ordering, per-task execution with tests and commits, PR creation, and Linear updates.

## Related

- `01-03-configuration.md` — branching model (staging, work branches)
- `docs/dev-workflow.md` — worktree management, convenience functions, shared-resource gotchas
- `02-01-task-management.md` — Linear integration during execution
- `02-03-coding.md` — context loading and code change discipline
- `02-04-testing.md` — testing decisions during execution
