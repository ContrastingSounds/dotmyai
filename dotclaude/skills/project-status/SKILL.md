---
description: Summarise project status from Linear, GitHub, and git. Shows recently completed work, planned work with dependencies, git branch/worktree housekeeping, and current concerns.
argument-hint: Optional project name filter, or "all" for initiative-wide (default: uses CLAUDE.md initiative)
---

# Project Status

## Input

Project filter: `$ARGUMENTS`

If `$ARGUMENTS` names a specific Linear project, scope to that project only. If blank or "all", discover all projects under the initiative named in CLAUDE.md.

## Step 1: Resolve Projects

Read CLAUDE.md to find the Linear initiative name. Then discover all projects:

```
mcp__linear__list_projects(initiative: "<initiative name>")
```

If CLAUDE.md does not name an initiative, call `list_projects()` without an initiative filter. Flag the missing initiative attribute as a concern in Section 4d.

Collect the project names and IDs. If `$ARGUMENTS` names a specific project, filter to that one.

## Step 2: Gather Data

Run all of the following in parallel. Each Linear query runs once per project.

### 2a: Linear — Recently Closed Issues

For each project, fetch issues completed or cancelled in the last 2 weeks:

```
mcp__linear__list_issues(project: "<name>", state: "Done", updatedAt: "-P14D")
mcp__linear__list_issues(project: "<name>", state: "Cancelled", updatedAt: "-P14D")
```

### 2b: Linear — Open Issues

For each project, fetch all open work across three states:

```
mcp__linear__list_issues(project: "<name>", state: "In Progress")
mcp__linear__list_issues(project: "<name>", state: "Todo")
mcp__linear__list_issues(project: "<name>", state: "Backlog")
```

### 2c: GitHub PRs

```bash
gh pr list --state merged --limit 10 --search "merged:>=$(date -v-14d +%Y-%m-%d)" --json number,title,state,mergedAt,headRefName,baseRefName
gh pr list --state open --json number,title,state,createdAt,headRefName,baseRefName
```

### 2d: Git Activity

```bash
git log --oneline -20 --all
```

### 2e: Git Branch & Worktree Audit

```bash
git branch -vv
git branch -r
git worktree list
git branch --merged staging
git branch --merged main
git branch -r --merged staging
git branch -r --merged main
```

## Step 3: Parse & Format

If any Linear query returned large JSON, save it to a temp file under `~/tmp/agentics/` (use a unique filename) and pipe through the formatter:

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/format_status.py < ~/tmp/agentics/linear_issues.json
python3 ${CLAUDE_SKILL_DIR}/scripts/format_status.py --section recently-closed < ~/tmp/agentics/linear_closed.json
python3 ${CLAUDE_SKILL_DIR}/scripts/format_status.py --section open < ~/tmp/agentics/linear_open.json
```

The script supports `--section recently-closed` (Done and Cancelled issues only) and `--section open` (In Progress, Todo, Backlog only). Without `--section`, it outputs all groups.

The script groups issues by status, sorts by priority, formats markdown tables, flags high-priority backlog items, and annotates parent/child dependency chains.

If the issue count is small enough to handle inline, skip the script and format directly.

## Step 4: Synthesise

Produce a narrative summary with these sections:

### 4a: Recently Completed Work

Cross-reference Done and Cancelled issues (from Step 2a) with merged PRs (from Step 2c). Present as:
- A table of merged PRs with their associated Linear issue IDs
- Key Linear issues completed, grouped by project
- Cancelled issues listed separately so it's clear they were dropped, not completed

### 4b: Work Planned

Present open issues (from Step 2b) grouped by project, then by state (In Progress first, then Todo, then Backlog). Within each group, sort by priority. For each issue:
- Show ID, priority, title, and parent issue if any
- If a parent issue has some children Done and some still open, note which are unblocked
- Flag high-priority items (Urgent/High) prominently

### 4c: Git Housekeeping

From Step 2e, identify:
- **Branches safe to delete**: local and remote branches that are fully merged into staging or main. Cross-reference with merged PR state — a branch whose PR is merged is a strong deletion candidate.
- **Active worktrees**: list any active worktrees and their branches
- **Stale `claude/` branches**: remote branches prefixed with `claude/` that are merged or have no corresponding open PR

Present as a concise list with recommended cleanup commands (but do NOT execute them).

### 4d: Current Concerns

Analyse the data to surface:
- Highest-priority open issues that should be tackled next
- Issues that are now unblocked (their blockers recently completed)
- staging/main branch drift (PRs merged to staging but not promoted to main)
- Missing prerequisites (e.g., Studio issues waiting on backend endpoints that don't exist yet)
- Data races, security issues, or other P1 items in the backlog
- Missing initiative attribute in CLAUDE.md (if Step 1 fell back to listing all projects)

### 4e: Recommended Actions

End with a short, numbered list of concrete next steps derived from everything above. Each action should be one sentence and directly actionable. Reference the appropriate skill or command where one exists (see `docs/dev/00-01-cli-overview.md` for the full list). For example:

- "Run `/checkout-work ENG-123` to start the highest-priority unblocked issue"
- "Run `/cleanup-worktree` to merge and clean up the verified feature branch"
- "Run `/commit-commands:clean_gone` to remove stale local branches"

Draw from:

- The highest-priority open issue(s) to start next
- Any newly unblocked work worth picking up
- Git cleanup commands to run (branch/worktree deletion)
- staging → main promotion if drift is significant
- Missing backend prerequisites that block downstream projects

Cap at 5 actions. Order by impact. Do not repeat analysis from earlier sections — just the action.

## Step 5: Output

Render the full summary to the user as a single markdown document with clear section headers.

## Rules

- **Read-only**: This skill gathers and reports. It does not modify any files, branches, issues, or PRs.
- **Scoped queries**: Always filter Linear queries by project and state. Never fetch all issues across the entire team.
- **Recently closed = last 2 weeks**: Use `updatedAt: "-P14D"` for Done and Cancelled issues, not all-time.
- **Cross-reference**: Always cross-reference Linear issues with GitHub PRs and git branches where possible.
- **No cleanup execution**: The git housekeeping section recommends cleanup commands but never runs them.
- **Graceful degradation**: Do not assume any integration is available. If a Linear call, `gh` command, or git operation fails, note the failure in the report and produce the best summary possible from whatever data is available.
