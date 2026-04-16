---
name: worktree-init
description: Generate a .claude/CLAUDE.local.md summarizing the intent and implementation of the current worktree branch
user_invocable: true
argument: Optional path to a plan file (e.g., /path/to/plan.md). If omitted, all files in .claude/plans/ and .claude/notes/ are used.
---

# Worktree Init

Generate `.claude/CLAUDE.local.md` for the current worktree by synthesizing git history, plan files, and notes into a concise summary that orients future conversations.

## Inputs

Gather all of the following before writing:

### 1. Git context

- Run `git branch --show-current` to get the branch name.
- Detect the base branch: try `main`, then `master`, then fall back to `HEAD~20`. Store this as `$BASE`.
- Run `git log --oneline $BASE..HEAD` to get the branch commit history.
- Run `git diff --stat $BASE..HEAD` to get the file-change summary.

### 2. Plan and notes files

- If an argument was provided, read that file as the sole plan input.
- Otherwise, glob for `.claude/plans/*.md` and `.claude/notes/*.md` and read all matches.
- If no plan/notes files exist, rely on git history alone.

### 3. Key source files (selective)

- From the `git diff --stat` output, identify the most-changed files (top 10-15 by lines changed).
- Read the first 60 lines of each to understand module structure, exports, and types — do not read entire files.
- For files with `types` or `spec` in the name, read more (up to 150 lines) since they define contracts.

## Output

Write `.claude/CLAUDE.local.md` with the following structure. Be concise; this file is loaded into every conversation's context window.

```markdown
# <Branch Name> — Worktree Summary

Branch: `<full branch name>`

## Intent

<2-4 sentences: what problem this branch solves, what it adds or changes, and why. Derive from plan files and commit messages. Do not repeat the branch name.>

## Wizard/Flow Steps (if applicable)

<If the branch implements a multi-step flow, wizard, or pipeline, list the steps in order with one-line descriptions. Skip this section if not applicable.>

## Key Files

<Table with columns: File | Role. Group by layer (frontend, backend, tests). Use relative paths. Only include files that were added or significantly modified on this branch — not every touched file.>

## Architecture Decisions

<Bulleted list of non-obvious design choices: why X approach was chosen over Y, what constraints shaped the design, what the tradeoffs are. Derive from plan files and code. Skip if the branch is straightforward.>
```

### Guidelines

- **Derive, don't copy.** Synthesize from plans and commits; do not paste plan content verbatim.
- **Skip sections that don't apply.** A one-file bug fix doesn't need an Architecture Decisions section.
- **Relative paths only.** Use paths relative to the repo root.
- **No YAML/code blocks in Key Files.** The table format is sufficient.
- **Scale to the branch.** A 3-commit branch gets a short file. A 20-commit feature branch gets a thorough one.
- If `.claude/CLAUDE.local.md` already exists, read it first and update it rather than replacing from scratch — it may contain manual additions.
