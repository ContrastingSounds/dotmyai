# Personal CLAUDE.md

## Developer Profile

Primary languages: Go, Python, TypeScript, SQL.

## Language Guidelines

Read these files when working in the corresponding language:

- **Go**: `~/.myai/guidelines/go-guidelines.md`
- **Python**: `~/.myai/guidelines/python-guidelines.md`
- **Dev workflow**: `~/.myai/DEV_WORKFLOW.md`
- **Integrations**: `~/.myai/INTEGRATIONS.md`

## TypeScript Guidelines

### Toolchain

- **Vite+** is the preferred unified toolchain (bundles Vite, Vitest, Oxlint, Oxfmt, Rolldown). If a project doesn't use Vite+ yet, use npm with individual tools.
- **Testing**: Vitest. Colocate test files as `*.test.ts`. Test behavior, not implementation.
- **Linting/Formatting**: Oxlint + Oxfmt via Vite+, or ESLint + Prettier as fallback.
- **Frameworks**: Astro for content sites, SolidJS for interactive/reactive UIs. Prefer signals-based reactivity over virtual DOM diffing.

### Style

- `strict: true` in tsconfig always. No `any` except at type definition boundaries.
- Prefer `interface` over `type` for object shapes.
- Naming: `PascalCase` for types/interfaces, `camelCase` for functions/variables, `UPPER_SNAKE_CASE` for constants.
- Import order: node builtins → third-party → local, separated by blank lines.
- Error handling: explicit try/catch at system boundaries, typed errors where possible.
- Prefer `const` over `let`. Never `var`.
- Use template literals over string concatenation.

### Project Structure

```
project/
├── src/
│   ├── components/     # UI components
│   ├── lib/            # Shared utilities
│   ├── pages/          # Route pages (Astro)
│   └── types/          # Shared type definitions
├── tests/              # Integration/e2e tests (unit tests colocated with source)
├── public/             # Static assets
├── tsconfig.json
└── package.json
```

## SQL & DuckDB

**DuckDB is the default** for ad hoc data tasks: CSV/Parquet/JSON exploration, one-off analysis, format conversion.

- Prefer DuckDB CLI or Python `duckdb` module for data exploration.
- Use DuckDB for reading/writing Parquet — not pandas.
- Use `COPY ... TO` for format conversion (e.g., CSV to Parquet).
- SQL style: uppercase keywords (`SELECT`, `FROM`, `WHERE`), lowercase identifiers, CTEs over subqueries, trailing commas.
- For persistent app databases: SQLite (Python) or `database/sql` + sqlc (Go).
- For analytics backends: ClickHouse.

## Testing Strategy

### Philosophy

- Tests are a first-class deliverable, not an afterthought.
- Write tests alongside code, not after.
- Tests are documentation of intent and safety nets for agentic iteration.
- When making changes, run existing tests first to establish a baseline before modifying anything.

### Per-Language

- **Go**: Table-driven tests with stdlib `testing`. Use `testdata/` for fixtures. Gate integration tests with build tags or `testing.Short()`. Full details in `~/.myai/guidelines/go-guidelines.md`.
- **Python**: pytest with fixtures in `conftest.py`. 80%+ coverage on business logic. Mock at boundaries only, not internals. Full details in `~/.myai/guidelines/python-guidelines.md`.
- **TypeScript**: Vitest. Colocate unit tests as `*.test.ts` next to source. Test behavior, not implementation. Use `vi.mock()` sparingly and only at module boundaries.
- **SQL/DuckDB**: Test queries against small fixture datasets. Assert row counts and key values.

### Anti-Patterns — Call Out When Spotted

- Faked or fabricated test results. Always run the actual test and show real output.
- Tautological tests that pass regardless of input.
- Mocking internals instead of boundaries.
- Skipping or disabling tests to unblock a commit.
- Asserting on implementation details rather than behavior.

## Git & Commits for Agentic Coding

### Commit Rhythm

- Commit early, commit often. Each logical unit of work gets its own commit.
- Commit before switching context — before moving to a new task, file, or approach, commit what works.
- After completing a unit of work: run tests, commit, then move on.

### Commit Quality

- Messages: imperative mood, explain *why* not *what*. First line under 72 characters.
- Pre-commit: run formatters and linters (gofmt, ruff, oxlint/prettier) before committing.
- Run tests before pushing.

### Branch Discipline

- Feature branches for anything non-trivial. Never commit directly to main.

### Git Worktrees

Use worktrees as the default isolation for development work:

- Start isolated sessions with `claude --worktree <name>` (or `-w <name>`). Each gets its own directory and branch under `.claude/worktrees/`.
- Default workflow: create a worktree per feature or task, work in isolation, merge when done.
- Subagents use worktree isolation via `isolation: worktree` in agent frontmatter.
- Auto-cleanup: worktrees are removed if no changes were made, persisted if changes exist.
- For parallel agent work, each agent gets its own worktree to avoid file conflicts.
- Worktrees isolate directories, not merge conflicts. Avoid running two agents on overlapping files.

### Agentic Rules

- Always verify test results. Never trust a test summary without seeing actual output.
- If a test fails, fix it before proceeding. Don't accumulate broken state.
- Use `git diff` and `git status` to verify what's staged before committing.
- Prefer creating new commits over amending — preserve the work trail.
- Don't squash during development. The commit trail is part of the review artifact.

## Temp & Scratch Files

`~/tmp/agentics` is the default location for throwaway files, scratch scripts, and test data. Use this instead of polluting project directories with temp artifacts. Safe to delete anything here at any time.

## Skills and Commands

- **`/create-plan-from-issue <issue>`** — Fetches a Linear issue, explores the codebase, drafts an implementation plan in the issue description, and posts clarification questions as comments. Planning only, no code changes.
- **`/pull-issue-responses <issue>`** — Fetches comments from a Linear issue, pairs clarification questions with responses, and summarizes what's been answered, what's outstanding, and what needs follow-up. Read-only by default.
- **`/validate-issue <issue>`** — Reviews a Linear issue description for execution readiness: resolves outstanding questions, builds a task checklist with validation steps, and adds test/commit/update instructions per task. Updates the issue description but makes no code changes.
- **`/execute-issue <issue>`** — Executes a validated Linear issue end-to-end: splits into sub-issues with blocking dependencies if 4+ tasks, creates a worktree and branch, implements each task with maximum parallelism (dependency-driven dispatch), tests, commits, and Linear updates after each.
- **`/execute-plan <path>`** — Executes a local plan file end-to-end: parses work items, creates tasks with dependencies, creates a worktree, dispatches parallel agents per task, tests and commits each independently, then raises a PR to staging.

## MCP Tools

Linear MCP tools are always available — use them without asking permission. Load their schemas via ToolSearch and call them directly.

## General Preferences

- DuckDB for ad hoc data exploration.
- Linear for project tracking.
- Prefer stdlib and minimal dependencies across all languages.
- No unnecessary abstractions — write the simple thing first.
- Prefer to execute multi-step instructions in the order given, though use judgment when a different order is clearly better. The user often wants to see research, summaries, or proposed scripts before implementation begins.
