# PR Review

How to review branch changes and PRs using Claude Code's review tools.

## One-Time Setup

Each prerequisite has a check command and a fix. Once configured, these persist across sessions.

### Plugins

Check `enabledPlugins` in `~/.claude/settings.json`:

- `code-review@claude-plugins-official` — multi-agent review pipeline
- `pr-review-toolkit@claude-plugins-official` — 6 specialist review agents
- `code-simplifier@claude-plugins-official` — post-review clarity pass

### Project CLAUDE.md

The target project should have a CLAUDE.md with:

- **Linear context**: workspace, initiative, project name (so the agent can create/find issues)
- **Coding conventions**: style rules, patterns, testing expectations (so review agents check compliance)

Without a CLAUDE.md, review agents still work but produce weaker, less project-specific findings.

## Review Commands

**Always review in a separate session from the one that wrote the code.** Writer/reviewer separation eliminates confirmation bias. Start a fresh session or use a different worktree.

### Step 1: Quick review (`/review`)

Run this first for every review. It's a bundled Claude Code skill that reviews all pending changes on the current branch.

```
/review
```

- Reads `git diff main` and analyzes all changed files
- Checks style, bugs, missing error handling, CLAUDE.md compliance
- Reports findings with file:line references
- No setup beyond being on a branch with changes

For a PR you haven't checked out locally:

```
/review PR#42
```

### Providing review context

When you know what matters, tell the agent before running a review command:

```
This change adds JSONL event logging to the simulation loop. Focus on:
- Whether every state mutation is captured (transitions, field updates, new entities)
- Whether the log is reconcilable — replaying it from initial state should reproduce final CSV output
- Error handling in the EventLogWriter (file I/O failures during simulation)

/review
```

The agent uses this guidance to prioritise findings. Without it, the review is generic.

### Step 2: Targeted specialist review (`/pr-review-toolkit:review-pr`)

Run after `/review` for non-trivial changes. This plugin auto-detects which specialist agents to run based on what files changed.

```
/pr-review-toolkit:review-pr
```

What it does:
- Reads the diff to determine which specialists are relevant
- Spawns agents sequentially based on changed file types:

| Files changed            | Agent spawned            | What it checks                              |
|--------------------------|--------------------------|---------------------------------------------|
| Any files                | `code-reviewer`          | CLAUDE.md compliance, bugs, quality (always) |
| Error handling / catch   | `silent-failure-hunter`  | Suppressed errors, empty catch, bad fallbacks |
| Type definitions         | `type-design-analyzer`   | Encapsulation, invariant expression          |
| Test files               | `pr-test-analyzer`       | Coverage gaps, missing edge cases            |
| Comments / docstrings    | `comment-analyzer`       | Comment accuracy, staleness, rot             |
| After all pass           | `code-simplifier`        | Clarity, maintainability                     |

- Aggregates results into: Critical Issues | Important Issues | Suggestions | Strengths
- Reports in-session (does not post to GitHub)

### Step 3: Full pipeline review (`/code-review`)

Run as a final pre-merge check on an existing, open PR. This is the most thorough option.

```
/code-review
```

What it does:
- Checks PR eligibility (skips draft, closed, trivial, or already-reviewed PRs)
- Spawns 5 parallel Sonnet agents:
  1. CLAUDE.md compliance audit
  2. Shallow scan for obvious bugs in changed lines only
  3. Git blame/history analysis for context-based bugs
  4. Review of previous PR comments on same files
  5. Code comment compliance check
- Each finding scored 0-100 for confidence
- Only findings ≥80 confidence pass the filter
- **Posts a formatted review comment on the PR via `gh`**
- Requires: open, non-draft PR with `gh` authenticated

### Security review (`/security-review`)

Run alongside any of the above when changes touch auth, input handling, or data access.

```
/security-review
```

Analyzes pending branch changes for security vulnerabilities: injection, auth flaws, credential exposure, insecure data handling.

## Working with Findings

After a review, you have a prioritised list of findings. Use the specialist agents to drill deeper into specific areas, then decide what to fix now vs capture for later.

### Drill deeper with a specific agent

If a finding warrants deeper investigation, invoke the relevant specialist directly. These are the same agents from Step 2 but scoped to a specific file or area:

```
Use the silent-failure-hunter agent to review the error handling in pkg/fsm/simulation.go

Use the type-design-analyzer to review the Instance and StateMachine types in pkg/fsm/types.go

Use the pr-test-analyzer to check test coverage for pkg/fsm/eventlog.go
```

### Fix and re-verify

Fix in the writer session/worktree, then re-run `/review` in the review session to verify.

### Fixing review findings with `/execute-issue`

When review produces a batch of fixes — too many to hand-edit quickly, or spanning multiple files — use `/execute-issue` to work through them systematically. Create a Linear issue (or work package with sub-issues) describing the fixes, then execute it from the PR's worktree.

The skill detects that you're on a PR branch and automatically enters **review-fixes mode**: it creates a new worktree branched from the PR branch (not staging), implements and tests each fix, then presents the results and asks whether to merge the fixes back into the PR branch. It hard-stops after that — no further automation.

```
# From the PR worktree (or mention the PR in the issue/arguments):
/execute-issue CON-200
```

This gives you:
- A separate worktree for the fixes, isolating them from the PR branch until you're ready
- Parallel agent dispatch for independent fixes (same as standard execute-issue)
- A clean merge point — review the fix commits before they touch the PR branch
- A hard stop that waits for your confirmation before merging

The review-fix worktree stays on disk after the skill finishes, so you can inspect the changes, run additional tests, or merge manually if you prefer.


## Capturing Findings in Linear

Not every finding needs a Linear issue. Capture findings that need work beyond the current PR.

### When to capture

- Finding requires a separate change (too large or risky for this PR)
- Pre-existing issue discovered during review (not introduced by this PR)
- Architectural concern needing planning or discussion
- Pattern violation that should become a CLAUDE.md rule

### Creating issues from findings

Ask the agent directly — it uses `save_issue` and `save_comment` MCP tools:

```
Create a Linear issue in the Mock Machines project for finding #2

Add this finding as a comment on CON-42

Create issues for all critical findings in the Mock Machines project
```

The agent includes file:line references, severity, description, and suggested fix direction. You add priority and any context the agent doesn't have.

### Linking

- The agent includes the PR number in the Linear issue body
- Add the Linear issue ID to the PR description for traceability (or ask the agent to do it)

### Batch capture

For reviews with many findings:

```
Create Linear issues for all critical and important findings, assign to me, set priority based on severity
```

The agent batches `save_issue` calls and reports back with issue IDs.

## Troubleshooting

### `gh` authenticated as wrong account

Symptom: PR not found, or review comment posted from wrong user.

```sh
gh auth status          # check active account
gh auth login           # re-authenticate as correct account
```

### Linear MCP not responding

Symptom: "tool not available" or timeout when agent tries to create issues.

- Check env var is set: `echo $LINEAR_API_KEY_PERSONAL`
- OAuth tokens expire after 24 hours — re-auth if using OAuth flow
- Verify global MCP registration: `claude mcp list`
- See `docs/stack/linear-configuration.md` for details

### `/code-review` runs but posts nothing

Not necessarily a failure:

- PR is draft or closed (auto-skipped)
- All findings scored below 80% confidence (filtered out — this is success)
- PR has no meaningful diff against base branch

### Agent reviews wrong files

Be explicit about scope:

```
Review only the files changed in my current diff
Review just pkg/fsm/simulation.go and pkg/fsm/eventlog.go
```

### Plugin not found

Check `enabledPlugins` in `~/.claude/settings.json`. Required entries:

- `code-review@claude-plugins-official`
- `pr-review-toolkit@claude-plugins-official`

### Review is slow on large PRs

Normal for multi-agent pipelines on 500+ line diffs. Options:

- Split the PR into smaller, focused PRs
- Use a targeted specialist agent instead of the full pipeline
- Ask for review of specific directories or files
