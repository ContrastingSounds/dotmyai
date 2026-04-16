# Development Workflow

## Git Workflow

**Note** Claude Code uses git worktrees when spinning up agents to perform work, but Claude Code worktrees should *only* be used for Claude by Claude. When directly starting up a new branch or worktree, use git, gh, and convenience functions in ~/.zshrc

- Starting a new branch & worktree
  - cleaning up the branch & worktree after
- Cloning PRs
- Cloning branches

### Work Source Code (rill)

#### convenience functions
- **`local-tree <branch>`** — New branch from latest main. Runs `_rill_wt_setup` (symlinks shared `.claude/` config, copies `settings.local.json`, `npm install`, `make cli`).
- **`branch-tree <branch>`** — Checkout an existing remote branch into a worktree. For reviewing or continuing someone else's work.
- **`pr-tree <pr-number>`** — Checkout a PR by number. Fetches PR metadata via `gh` to name the worktree `pr-<number>-<slug>`.

### General Purpose

#### convenience functions
- **`new-tree <branch>`** — Create a new branch + worktree from latest main in any git repo. Generic equivalent of `local-tree`.
- **`plan-tree <name> <plan-file>`** — Create a worktree + branch from main in any git repo. Runs `uv sync` and prints a prompt to paste into Claude Code with the plan file path.

#### manual worktree management

```sh
# Create a new branch + worktree from latest main
git fetch origin
git worktree add ../<repo>-<branch> -b <branch> main

# cd into the worktree and start working
cd ../<repo>-<branch>
```

```sh
# Cleanup: from the main repo directory (not the worktree)
git worktree remove ../<repo>-<branch>   # remove worktree + directory
git branch -d <branch>                   # delete branch (safe; checks merge status)
git worktree prune                       # optional; cleans stale metadata
```

### Claude notes version control

Each worktree has its own `.claude/` directory with notes, plans, and local config that are gitignored by the parent repo. The `ngit` system provides per-worktree version control for these files using a nested git repo at `.claude/notes/.git`.

#### What `_rill_wt_setup` does

Symlinks shared config from the main worktree so it's always up to date:
- `CLAUDE.md`, `CLAUDE.local.md`, `rules/`, `skills/`, `settings.json`

Copies per-worktree config (independent per branch):
- `settings.local.json`

Starts empty (session/branch-specific content; not copied or linked):
- `notes/`, `plans/`, `worktrees/`

#### What's tracked by `ngit`

The notes repo uses `core.worktree` set to `.claude/` with an inverted `.gitignore` (ignore `*`, then `!` allow specific paths). Tracked files:

- `.claude/notes/` — investigation notes, architecture docs, session summaries
- `.claude/plans/` — implementation plans, task breakdowns

#### How it works

`_rill_wt_setup` (called by `local-tree`, `pr-tree`, `branch-tree`) symlinks shared config and copies `settings.local.json` from the main repo. It does not call `_rill_notes_init`; run that manually if you want per-worktree notes version control.

The notes repo lives at `.claude/notes/.git` because `.claude/notes/` is in the parent repo's `.gitignore`, so the nested `.git` directory is invisible to the parent.

#### Usage

```sh
ngit status                    # see what's changed
ngit diff                      # review changes
ngit add -A                    # stage everything
ngit commit -m "update notes"  # commit
ngit log --oneline             # history
```

`ngit` is a wrapper that finds `.claude/notes/.git` relative to `git rev-parse --show-toplevel`, so it works from anywhere in the worktree.

#### Manual initialisation

For an existing worktree that doesn't have a notes repo yet:

```sh
_rill_notes_init "$(git rev-parse --show-toplevel)"
```

## Development Process

1. Brainstorm
2. Plan
3. Develop
4. Debug
5. Test
6. CI/CD

### Brainstorm

While structured research processes are entirely possible, the goal of the
"brainstorm" phase is to allow fast, easy AI-assisted exporation of ideas.
Explicitly labelling this stage is really just a naming convention for
having a "brainstorm" folder, which is also in .gitignore to avoid polluting
the repository.

- Save artefacts to `ai/brainstorm`
- No set process or templates

### Plan

The goal of the planning stage is to generate good designs, PRDs and plans.
Plans are always required, as agentic coding is significantly more effective
after iterating over a planning document. PRDs are also useful for keeping
a clear view of the desired outcome of the coding project. 

The `ai/plans` folder might also be used to store other planning and design
artifacts.

- For "official" projects, should be associated to a Linear project or issue
- outputs to both `ai/designs` and `ai/plans` folders
- `designs` are permanent, evolving documents that represent the goal
- `plans` are temporory, frequently archived documents for meeting the goal

### Develop

For serious development tasks (but not necessarily minor ones), some form
of TODO list is necessary. All agents and IDEs provide some form of this, and
the out-of-the-box tooling is often all that is required.

Note that for product development, work must be tracked in Linear. There is no
established relationship between Linear issues and an agent's plans and todos.
The working assumptions of myai are:

- Issues in Linear ensure alignment to product roadmaps and customer commitments
- Local TODOs and .beads ensure local control of detailed coding tasks
  - They are more detailed and also more ephmeral than Linear issues
  - beads epics are "less epic" than in Linear, more akin to issues and projects
- Development may take place over session sessions and context refreshes

### Debug

tbc

### Test

Testing is the primary feedback loop for verifying agent-generated code.

- Read `ai/instructions/testing-strategy.md` for the full strategy
- Run tests after each meaningful change (catch failures early)
- Every bug fix requires a regression test
- Never weaken or skip tests to make them pass
- Always verify actual test output — don't trust summaries

### CI/CD

- AI is quite good at developing GitHub actions for CI/CD automation
