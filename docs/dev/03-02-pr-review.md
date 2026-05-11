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

## Starting a Review

State your intent — the agent picks the right tools based on the diff size and context.

**Always review in a separate session from the one that wrote the code.** Writer/reviewer separation eliminates confirmation bias. Start a fresh session or use a different worktree.

### From a local branch (pre-PR)

Best when you're still iterating and haven't pushed yet.

```
Review my changes on this branch
```

The agent checks your branch diff against main, runs a review pass, and reports findings. For small diffs it does a single pass; for larger changes it may run multiple specialist agents in parallel.

### From a PR number

Best when reviewing your own PR before requesting human review, or reviewing someone else's work.

```
Review PR #42
```

or

```
/review PR#42
```

The agent fetches the PR diff, reviews it, and reports in-session.

### Full multi-agent review

Best as a final pre-merge check on an existing PR. Runs the full pipeline — multiple parallel agents with confidence-scored findings.

```
/code-review
```

or

```
/pr-review-toolkit:review-pr
```

`/code-review` posts a formatted review comment directly on the PR (requires an open, non-draft PR). `/pr-review-toolkit:review-pr` reports back in-session without posting.

## What the Agent Does

Understanding what happens behind the scenes helps you interpret results and steer follow-up.

### Review pipeline

1. **Diff analysis** — checks branch diff size and what areas changed
2. **Single or multi-pass** — small diffs get one pass; 100+ lines trigger parallel specialist agents
3. **Confidence filtering** — findings scored below 80% confidence are filtered out to reduce noise
4. **Structured output** — each finding includes file:line, severity, description, recommendation

### Specialist agents

These run automatically when relevant, or you can request them directly for follow-up.

| Agent | Focus |
|-------|-------|
| `silent-failure-hunter` | Suppressed errors, empty catch blocks, bad fallbacks |
| `type-design-analyzer` | Type encapsulation, invariant expression |
| `pr-test-analyzer` | Test coverage gaps, missing edge cases |
| `comment-analyzer` | Comment accuracy, stale comments, comment rot |
| `code-reviewer` | Style, guidelines, CLAUDE.md compliance |
| `code-simplifier` | Clarity, maintainability, unnecessary complexity |

Bundled extras (not part of the pipeline, run on request):
- `/security-review` — security-focused analysis of pending branch changes

## Working with Findings

The initial review gives you a prioritised list. From there, go deeper or act.

### Drilling down

Ask the agent to expand on specific findings:

```
Tell me more about finding #3

Show me the code around that error handling issue

Run the silent-failure-hunter on just pkg/fsm/

Is this actually a problem or a false positive?
```

### Fixing in-session

- **Your own code**: fix directly in the review session, then re-run the review to verify the fix. Or switch to the writer session/worktree to fix there.
- **Someone else's code**: document findings and create Linear issues. Don't fix — the author should.

### Verifying fixes

After addressing findings:

```
Re-run the review to check if the issues are resolved
```

### Post-review polish

Once review findings are addressed, a clarity pass catches different issues (naming, structure, redundancy):

```
/simplify
```

This changes code — run it in the writer session, not the review session.

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
Create a Linear issue in ContrastingSounds for finding #2

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
