# Development Workflow

## Git Workflow

**Note** Claude Code uses git worktrees when spinning up agents to perform work, but Claude Code worktrees should *only* be used for Claude by Claude. When directly starting up a new branch or worktree, use git, gh, and convenience functions in ~/.zshrc

- Working with branches & worktrees
- Cloning PRs
- Cloning branches

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

### Worktree Shared-Resource Gotchas

When running multiple worktrees (especially parallel agents), watch for
shared-resource conflicts:

- **Ports**: Integration tests binding to fixed ports will collide. Use dynamic
  port assignment or environment variables per worktree.
- **Databases**: Each worktree needs its own database name or schema for
  integration tests. Don't share a test database across parallel agents.
- **Docker daemon**: Parallel Dockerfile builds or container name conflicts.
  Use worktree-specific container name prefixes.
- **Package caches**: Generally shared safely, but parallel `go mod download`
  or `npm install` can race. Usually harmless but can cause transient errors.
- **Disk budget**: Each worktree is a full copy of the working tree (not the
  `.git` directory). Budget ~5GB per worktree beyond base repo size for
  large projects.

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

**Context management**: Plan in one session, then start implementation in a
fresh session (`/clear`) with only the plan loaded. This keeps the context
window focused on code, not conversation history. After 2 failed corrections,
`/clear` and write a better initial prompt rather than accumulating stale context.
Use `/compact <instructions>` with focus directives when the context window grows
large mid-session.

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

**Agentic coding loop**: The core iteration pattern for agent-assisted development:

1. Pick a task from the plan or TODO list
2. Implement the change
3. Run tests / build / lint (provide the verification command in the prompt)
4. If pass → commit → move to next task
5. If fail → fix → re-run (max 2 attempts, then rethink the approach)
6. After committing, consider whether context has grown stale — `/clear` if so

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

**Reference pipeline stages** (adapt per language):

1. **Lint**: language-specific linter (`golangci-lint run`, `ruff check`, `oxlint`)
2. **Test**: full suite with race detection where applicable (`go test -race -cover ./...`)
3. **Security**: vulnerability scanning (`govulncheck ./...`, `pip-audit`, `npm audit`)
4. **Build**: compile / bundle
5. **Release**: on tag push only

**Self-correcting CI**: When a CI build fails, the agent analyzes logs, proposes
a fix, commits it, and re-runs. Use a deterministic marker (e.g., a passing test
suite) to signal halt. This pattern saved Elastic ~20 days of engineering work
in the first month.

**Practical tips**:
- Use `concurrency` with `cancel-in-progress: true` in GitHub Actions to cut
  monthly CI minutes 30-50%
- Pin action versions to commit SHAs, not tags (tags can be retargeted)
- Use `go-version-file: go.mod` instead of hardcoded Go versions
- For `go generate`: commit generated code and verify with
  `go generate ./... && git diff --exit-code` in CI
- See `templates/go-ci.yml` for a reference GitHub Actions workflow

### Code Review

**Writer/reviewer separation**: Use separate sessions for writing and reviewing.
A fresh context eliminates confirmation bias toward code you just wrote. This
is the single most impactful review practice.

**Risk-based scope**: Scale review depth to change size:
- Trivial (≤10 lines): quick scan
- Lite (≤100 lines): focused review
- Full (100+ lines): multi-pass review with security and architecture checks

**What AI review can and cannot do**:
- Good at: style consistency, common bugs, missing error handling, test coverage gaps
- Cannot replace humans for: architectural alignment, cross-system contract changes,
  subtle concurrency bugs, design validation

**Review process** — 3 steps, scaled to change size:

| Step | Tool | When to use |
|------|------|-------------|
| 1. Quick review | `/review` (bundled) | Every PR-ready change, before pushing. Zero setup. |
| 2. Deep review | `pr-review-toolkit:code-reviewer` (plugin) | Non-trivial PRs (100+ lines), or changes to error handling / concurrency / security-sensitive code. |
| 3. Error audit | `pr-review-toolkit:silent-failure-hunter` (plugin) | Any PR touching error handling, catch blocks, fallback logic, or retry paths. Especially valuable for Go where agent-generated code has 2x the error handling issues. |

Step 1 is always. Steps 2–3 are additive based on risk. For trivial changes (≤10 lines), a quick scan without tools is fine.

### Skills and Commands Worth Knowing

**Bundled skills** (ship with Claude Code, always available):
- `/simplify` — parallel agents review changed files for reuse and quality
- `/review [PR]` — local PR review
- `/security-review` — security analysis of pending branch changes

**Official plugins** (install to add):
- `code-review` — multi-agent pipeline: pre-screen → summarize → 4 parallel reviewers → validation
- `pr-review-toolkit` — 6 specialized agents (comment-analyzer, test-analyzer, silent-failure-hunter, type-design-analyzer, code-reviewer, code-simplifier)
- `feature-dev` — 7-phase feature development with parallel exploration and architecture agents
- `commit-commands` — `/commit`, `/commit-push-pr`, `/clean_gone`
- `claude-code-setup` — analyzes a codebase and recommends automations

**Community skills**:
- `cc-skills-golang` (samber) — Go-specific agent instructions, reduced errors 41-43% in benchmarks

**Plugin hygiene**: Keep 2-3 active plugins max. Use `skillOverrides` to set
unused skills to `"name-only"` or `"off"` to avoid context pollution.

**When to add automation** (progressive adoption):

| Trigger | Add |
|---------|-----|
| Agent gets a convention wrong twice | CLAUDE.md rule |
| You keep typing the same prompt | Skill |
| A side task floods your conversation | Subagent |
| Something must happen every time | Hook |
| A second repo needs the same setup | Plugin |
