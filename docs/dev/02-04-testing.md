# Testing

When and how to test during agent-executed tasks.

For the comprehensive testing philosophy and rules, see `templates/testing-strategy.md`. This document covers the practical decisions an agent makes during execution.

## Decision Tree: Does This Change Need New Tests?

### New tests required

- **New function, method, or API endpoint**: Test its behavior.
- **Bug fix**: Regression test is mandatory. Write the failing test first, then fix the bug, then verify the test passes. This is non-negotiable (testing strategy rule 5).
- **New validation logic or error path**: Test both the happy path and the error case.
- **Behavior change to existing function**: Update existing tests to reflect new behavior, add tests for new cases.

### Existing tests sufficient (update if needed)

- **Renaming**: Update test references to match new names.
- **Documentation-only changes**: No tests needed.
- **Config changes**: Verify with build/lint, not new tests.
- **Formatting or style fixes**: Existing tests confirm nothing broke.

### Run existing tests, no new tests needed

- **Refactoring that preserves behavior**: Existing tests prove equivalence. If they all pass, the refactoring is correct.
- **Dependency updates**: Existing tests verify compatibility.

## Test-First vs Test-After

### Test-first (preferred for these cases)

- **Bug fixes**: Write the failing regression test, verify it fails, fix the bug, verify the test passes.
- **New behavior with a clear specification**: The issue description or PRD defines expected outputs. Write tests that assert those outputs, then implement.

### Test-after (acceptable for these cases)

- **Exploratory changes**: Shape isn't known yet. Implement, then write tests once the interface stabilizes.
- **Refactoring**: Existing tests already cover the behavior. Run them after each change.

### Both: most tasks

For the typical task in a work package:
1. Read existing tests to understand current coverage
2. Implement the change
3. Update or add tests
4. Run validation

## Verification Commands

Use the verification command from the task description or CLAUDE.md when available. If none is specified, use the appropriate commands for the language.

### Go

```sh
go test ./pkg/... -v              # targeted package tests
go test ./... -v                  # full suite
go test -run TestSpecific ./pkg/  # single test
go vet ./...                      # static analysis
go build ./...                    # compilation check
```

For race detection (CI or final validation): `go test -race ./...`

### Python

```sh
uv run pytest tests/ -v               # full suite
uv run pytest tests/test_specific.py  # single file
uv run pytest -k "test_name"          # single test
uv run ruff check .                   # linting
```

### TypeScript

```sh
npx vitest run                    # full suite
npx vitest run src/lib/x.test    # single file
npx oxlint .                     # linting
```

## Full Suite vs Targeted Tests

### During task execution: targeted

Run only the tests relevant to the changed files. This gives faster feedback and keeps the agent focused on the current task.

Example: if modifying `pkg/fsm/simulation.go`, run `go test ./pkg/fsm/ -v`, not `go test ./...`.

### After all tasks complete: full suite

Before raising a PR, run the full test suite to catch cross-cutting regressions. This is the final validation step.

### Before merge (via `/verify-worktree`): full suite after merge

`/verify-worktree` merges `staging` into the work branch and runs the full test suite. This catches conflicts with changes that landed on staging while the work package was in progress.

## Agent-Specific Anti-Patterns

These are common failure modes when agents generate or modify tests. Watch for them.

### Tests from the same prompt as the implementation

When the agent generates both the code and the tests in one pass, they share the same blind spots. The agent writes tests that validate its understanding of the requirement — not the requirement itself.

**Mitigation**: Review tests critically. Ask: would this test catch a bug, or does it just confirm the implementation?

### Hallucinated dependencies

Agents hallucinate package names at a significant rate. A test that imports a non-existent package will fail to compile (best case) or pull in a malicious package (worst case).

**Mitigation**: Verify that all imports resolve to real, intended packages.

### Tautological tests

Tests that mirror the implementation rather than testing behavior. Signs:
- Expected output constructed with the same logic as the function under test
- Assertions on implementation details rather than observable behavior
- Tests that pass regardless of the function's return value

**Mitigation**: The test should be understandable without reading the implementation. If you need to read the source to understand why the test expects a particular value, the test is likely tautological.

### Weakening tests to pass

Never acceptable without explicit justification. If a test fails after a code change:
- The code is wrong, not the test
- Exception: the test was genuinely testing the wrong behavior (document why in the commit message)
- Exception: requirements changed and the test needs to reflect the new requirement

Do not broaden assertions, add skips, or disable tests to make a suite green.

## Rules

- Test before commit. Never commit code that fails its validation step.
- Every bug fix gets a regression test. No exceptions.
- Run targeted tests during task execution, full suite before PR.
- Verify actual test output. Do not trust "all tests passed" without seeing which tests ran.
- Never weaken, skip, or disable tests to unblock a commit.

## Related

- `templates/testing-strategy.md` — comprehensive testing strategy with language-specific patterns and agent-specific guidance
- `02-03-coding.md` — commit discipline (tests must pass before commit)
- `01-04-work-packages-and-trees.md` — lifecycle includes full suite before PR
