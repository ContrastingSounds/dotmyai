## Local Developer Preferences

This developer keeps their global development preferences in the `~/.myai` directory. 
These should referred to as relevant to each coding task.

- `~/.myai` - Main directory for local development guidelines
- `~/.myai/docs/DEV_WORKFLOW.md` - Guidelines for Go, Python
- `~/.myai/lang-guides` - Guidelines for Go, Python

## Recommended Plugins

Install for multi-agent code review and feature development:

- **`code-review`** — multi-agent review pipeline with confidence-based filtering. Posts inline GitHub comments with committable suggestions.
- **`pr-review-toolkit`** — 6 specialized review agents (comment-analyzer, test-analyzer, silent-failure-hunter, type-design-analyzer, code-reviewer, code-simplifier). More granular than `code-review`.
- **`commit-commands`** — `/commit`, `/commit-push-pr`, `/clean_gone`.

For Go projects, consider **`cc-skills-golang`** (samber) — Go-specific agent instructions that reduced errors 41-43% in benchmarks.

## Recommended Hooks

Hooks are deterministic — unlike CLAUDE.md instructions which are advisory,
hooks execute reliably every time.

- **PostToolUse (Edit/Write)**: auto-format after edits (`gofmt`, `goimports`, `ruff format`)
- **PreToolUse (Edit/Write)**: block edits to protected files (e.g., generated code, vendored deps)
- **PostToolUse (Bash)**: lint after test runs

Hooks have zero context cost unless they return `additionalContext`.

## Go Project Quick Reference

For Go projects, include these verification commands in task prompts:

```
go test -race ./...
golangci-lint run
go vet ./...
```

