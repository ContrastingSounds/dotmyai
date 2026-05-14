# Coding

Context loading, code changes, and commit discipline for agent-executed tasks.

## Context Loading Checklist

Before writing any code, load context in this order. Each source adds a layer of understanding that informs the next.

### 1. Project CLAUDE.md

Read the target project's CLAUDE.md. Extract:
- Architecture overview and module boundaries
- Testing commands and conventions
- Style rules and naming patterns
- Linear context (workspace, initiative, project name)

If no CLAUDE.md exists, note this and rely on README and code structure.

### 2. Design documents from Linear

If the project has a Linear project (identified in CLAUDE.md or by matching the git remote owner):

```
mcp__linear__list_documents(projectId: "<project-id>")
mcp__linear__get_document(id: "<doc-id>")
```

Read PRDs and design specs. These tell you what the code is supposed to do and what constraints apply. Compare the current task against stated requirements.

### 3. Language guidelines

Check `~/.myai/lang-guides/` for the project's primary language:
- **Go**: `~/.myai/lang-guides/go/go-guidelines.md`
- **Python**: `~/.myai/lang-guides/python/python-guidelines.md`

Apply the idiomatic patterns from these guides: error handling, naming conventions, project structure, testing style.

### 4. Issue description

Read the full issue description (already fetched during task management). Focus on:
- **What**: The change to make
- **Validate**: The verification step
- **Files**: Which files to create or modify

### 5. Current file state

Read every file that will be modified. Understand the current implementation before changing it.

For subsequent tasks in a work package, re-read files that were changed by prior tasks — the branch state has evolved.

## Making Code Changes

### Follow project conventions

Use patterns already established in the codebase. If the project wraps errors with `fmt.Errorf("...: %w", err)`, do the same. If it uses table-driven tests, write table-driven tests. Do not introduce new patterns, libraries, or abstractions unless the task specifically requires it.

### Scope to the task

Change only what the task requires. Do not:
- Refactor adjacent code that "could be better"
- Add convenience features not in the task description
- Fix unrelated lint warnings
- Reorganize imports or formatting in untouched files

If you notice something that should be fixed but isn't part of the current task, note it in a comment on the Linear issue for future work.

### Error handling

Follow the project's established error handling pattern:
- **Go**: Return errors with context wrapping. Never panic in library code. Use typed errors where the caller needs to distinguish cases.
- **Python**: Raise specific exceptions at system boundaries. Use `typing` for return types.
- **TypeScript**: Explicit try/catch at system boundaries. Typed error objects where possible.

### New files

Follow the existing project structure for file placement. Check how similar files are organized before creating a new one. Add necessary imports/exports. Include package-level documentation only where the project convention requires it.

## Commit Discipline

### One commit per task

Each task (or sub-issue in a work package) gets exactly one commit. Do not batch multiple tasks into one commit. Do not split a single task across commits.

### Commit message format

```
<issue-id>: <imperative description>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

- Use the sub-issue ID for work packages (e.g., `con-130`), not the parent ID
- First line under 72 characters
- Imperative mood: "add", "replace", "extract", not "added", "replaced", "extracted"

### Staging

Use specific file paths:
```sh
git add path/to/file.go path/to/file_test.go
```

Never use `git add -A` or `git add .`. Verify what's staged before committing:
```sh
git diff --staged
git status
```

### Pre-commit checks

Run formatters before committing:
- **Go**: `gofmt -w .` or `goimports -w .`
- **Python**: `uv run ruff format .`
- **TypeScript**: `npx oxfmt .` or `npx prettier --write .`

Run linters:
- **Go**: `go vet ./...`
- **Python**: `uv run ruff check .`
- **TypeScript**: `npx oxlint .` or `npx eslint .`

Fix any issues before committing. Do not suppress linter warnings with `//nolint` or `# noqa` unless there is a genuine false positive.

## Working in a Work Package

### Task ordering

Follow the dependency order established during planning (see `01-04-work-packages-and-trees.md`). Never start a task whose blockers are incomplete.

### Incremental context

After each commit, the branch state has changed. Before the next task:
- Re-read any files modified by the previous task if the next task also touches them
- Check that the previous task's changes don't affect assumptions for the next task

### Branch hygiene

All commits go on one branch. No sub-branches per task. Do not rebase or amend mid-execution — preserve the commit trail.

## Related

- `01-03-configuration.md` — branching model
- `01-04-work-packages-and-trees.md` — work package structure and dependency ordering
- `02-01-task-management.md` — Linear integration
- `02-04-testing.md` — testing decisions
- `~/.myai/lang-guides/` — language-specific guidelines
