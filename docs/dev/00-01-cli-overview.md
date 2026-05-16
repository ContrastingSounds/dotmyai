# CLI Overview

Commands and skills used across the development workflow, grouped by stage from the Development Catalog.

Provenance: **(custom)** this repo · **(shell)** .zshrc · **(script)** ~/.myai/tools/ · **(claude)** built-in · **(plugin-supplier)** Claude Code plugin

## 01 Prep (Configure, Plan)

Initialize a new CLAUDE.md with codebase documentation. **(claude)**
`/init`

Resolve a Linear project, issue, PR, or branch to the correct worktree and enter it. **(custom)**
`/checkout-work <reference>`

Generate a .claude/CLAUDE.local.md summarizing the current worktree branch. **(custom)**
`/worktree-init [path/to/plan.md]`

Pull a Linear issue, draft an implementation plan, and post clarification questions. **(custom)**
`/create-plan-from-issue <issue-id>`

Review a Linear issue description and update it to be execution-ready. **(custom)**
`/validate-issue <issue-id>`

Summarize clarification question responses from Linear issue comments. **(custom)**
`/pull-issue-responses <issue-id>`

Create a new worktree and branch from main for any repo. **(shell)**
`new-tree <branch-name>`

Create a worktree from main and print a Claude prompt to execute the plan. **(shell)**
`plan-tree <branch-name> <plan-file>`

## 02 Build (Implementation)

Execute a work package or single issue: worktree, tests, commits, Linear updates, PR. **(custom)**
`/execute-issue <issue-id>`

Guided feature development with codebase understanding and architecture focus. **(plugin-anthropic)**
`/feature-dev`

Create a git commit. **(plugin-anthropic)**
`/commit`

## 03 Review (Verify)

Review an entire codebase for quality, fitness for purpose, and health. **(custom)**
`/codebase-review`

Merge main into the worktree branch, resolve conflicts, and run tests. **(custom)**
`/verify-worktree`

Review a pull request. **(claude)**
`/review`

Comprehensive multi-agent PR review. **(plugin-anthropic)**
`/pr-review-toolkit:review-pr`

Security review of pending changes on the current branch. **(claude)**
`/security-review`

Review changed code for reuse, quality, and efficiency, then fix issues found. **(plugin-anthropic)**
`/simplify`

Scan a Claude Code session JSONL for env var values leaked from .zshenv. **(script)**
`uv run ~/.myai/tools/python/scan_session_secrets.py <session.jsonl>`

## 04 Deploy (Ship)

Commit, push, and open a PR. **(plugin-anthropic)**
`/commit-commands:commit-push-pr`

Merge a verified worktree branch into main, remove the worktree and branch. **(custom)**
`/cleanup-worktree [issue-id]`

## 05 Refine (Automate)

Update CLAUDE.md with learnings from the current session. **(plugin-anthropic)**
`/claude-md-management:revise-claude-md`

Audit and improve CLAUDE.md files across a repository. **(plugin-anthropic)**
`/claude-md-management:claude-md-improver`

Analyze a codebase and recommend Claude Code automations. **(plugin-anthropic)**
`/claude-code-setup:claude-automation-recommender`

Clean up local branches whose remote tracking branch has been deleted. **(plugin-anthropic)**
`/commit-commands:clean_gone`

Run git diagnostics and produce an interpreted analysis of codebase health. **(custom)**
`/git-xray`
