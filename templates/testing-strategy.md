# Testing Strategy

This document defines the testing strategy for this project. It is intended
to be read by both human developers and coding agents.

## Core Principle

Tests are the primary verification mechanism in agent-assisted development.
An agent cannot reason about whether code is correct by reading it — it must
run the tests and observe the results. Every rule below exists to make that
feedback loop reliable.

## Rules for Agent-Assisted Development

### 1. Tests Define "Done"

A task is not complete until tests pass. If a task has no tests, writing them
is part of the task. Acceptance criteria should be expressible as test
assertions wherever possible.

### 2. Never Weaken Tests to Make Them Pass

If a test fails after a code change, the code is wrong — not the test. The
only exceptions are:
- The test was genuinely testing the wrong behavior (document why in the commit)
- Requirements changed and the test needs to reflect the new requirement

Weakening assertions, broadening expected ranges, or adding `skip`/`xfail`
to make a suite green is never acceptable without explicit justification.

### 3. Verify Results — Don't Trust Summaries

Always examine actual test output. "All tests passed" in a summary is
meaningless without seeing which tests ran and what they asserted. Watch for:
- Tests that assert nothing (tautological tests)
- Test count dropping (tests were silently removed or skipped)
- Tests that pass for the wrong reason (e.g., catching all exceptions)

### 4. Run Tests Frequently During Development

Don't batch testing to the end. Run the relevant subset of tests after each
meaningful change. Catching failures early keeps the fix localized and prevents
cascading breakage.

### 5. Every Bug Fix Gets a Regression Test

Before fixing a bug, write a test that reproduces it. Verify the test fails.
Then fix the bug. Then verify the test passes. This is non-negotiable — it
prevents the same bug from returning.

### 6. Test at the Right Level

| Level | What it tests | When to use | Mechanism |
|-------|--------------|-------------|-----------|
| Unit | Single function/method in isolation | Pure logic, transformations, calculations | In-process, no I/O |
| Integration | Multiple components working together | Database queries, API handlers, pipelines | Real dependencies, test containers or fixtures |
| End-to-end | Full system behavior | Critical user paths, deploy verification | Full stack, browser or HTTP client |

Prefer unit tests for speed and precision. Use integration tests for
correctness at boundaries. Use e2e tests sparingly for high-value paths.

**When to run each tier**:
- Unit: every code change, pre-commit
- Integration: pre-push, CI
- E2e: CI only, or manually before release

### 7. Mock at Boundaries, Not Internals

Mock external dependencies (APIs, databases, filesystems) at the interface
boundary. Never mock internal implementation details — this creates brittle
tests that break on refactoring and pass on real bugs.

### 8. Test Data Management

- Use fixture files in a `testdata/` or `fixtures/` directory
- Keep fixtures small and focused — one scenario per fixture
- Never use production data in tests
- For database tests, use transactions that roll back or isolated test databases

## Provide a Verification Command

The single highest-leverage thing you can do for agent-assisted development
is give the agent a way to verify its own work. Include a test command, lint
command, or build command in every task prompt. Agents perform dramatically
better when they can run verification after each change.

Example prompt suffix: *"Verify with `go test -race ./...` after each change."*

## Go-Specific Testing Patterns

- **Fuzz testing**: Use `func FuzzXxx(f *testing.F)` for input validation,
  parsers, and serialization. Add seed corpus entries for known edge cases.
- **Integration test gating**: Use `testing.Short()` to skip slow tests
  during rapid iteration: `if testing.Short() { t.Skip("skipping integration test") }`.
  Run the full suite with `go test ./...` (no `-short` flag) in CI.
- **Binary coverage**: Use `go build -cover` + `GOCOVERDIR` to measure
  integration/e2e test coverage against the compiled binary, not just
  unit test coverage.
- **Race detector**: Always run with `-race` in CI. Agent-generated Go code
  has 2x the concurrency errors of human-written code.

## Agent-Specific Anti-Patterns

### Tests from the same prompt as the implementation

When the agent generates both the code and the tests in one pass, they share
the same blind spots. The agent writes tests that validate its understanding
of the requirement — not the requirement itself. Mitigate by: writing tests 
in a separate session, or reviewing tests with fresh eyes before trusting them.

### Hallucinated dependencies

Agents hallucinate ~20% of package names. A test that imports a non-existent
package will fail to compile (best case) or pull in a malicious package
registered under the hallucinated name ("slopsquatting"). Always verify
that test imports resolve to real, intended packages.

### Tautological test generation

Agents tend to generate tests that mirror the implementation rather than
test behavior. Watch for: tests that construct the expected output using
the same logic as the function under test, assertions on implementation
details rather than observable behavior, and tests that pass regardless
of the function's return value.

## Enforcement

### Pre-commit / Pre-push Hooks

The project should enforce test execution via hooks. At minimum:
- **Pre-push**: run the full test suite; block push on failure
- **Pre-commit** (optional): run fast unit tests or linting

### CI Pipeline

CI must run the full test suite on every PR. Tests that are flaky in CI
should be fixed or quarantined, never ignored.

## Project-Specific Configuration

<!-- Customize this section per project -->

- **Test framework**: [e.g., pytest, go test, vitest]
- **Test command**: [e.g., `uv run pytest`, `go test ./...`, `npm test`]
- **Coverage command**: [e.g., `uv run pytest --cov=src`]
- **Minimum coverage**: [e.g., 80% on business logic]
- **Integration test tag/flag**: [e.g., `-tags=integration`, `-m integration`]
- **Test data location**: [e.g., `testdata/`, `tests/fixtures/`]
