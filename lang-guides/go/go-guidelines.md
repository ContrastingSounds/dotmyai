# Go Coding Guidelines

## Overview

These standards guide code generation to ensure consistency, readability,
and maintainability across all Go projects.

## Preferred Libraries

- **CLI arguments**: stdlib `flag` for quick tools is fine. Have standarised on using [cobra](https://github.com/spf13/cobra). Always when the tool needs subcommands, and when moving quickly on defaults. Avoid viper generally, unless there is a specific need for it.
- **Logging**: stdlib `log/slog` for structured logging. Avoid logrus.
- **File paths**: stdlib `path/filepath`. Always use `filepath.Clean` on user-supplied paths.
- **Testing**: stdlib `testing`. No third-party assertion libraries needed.
- **HTTP client**: stdlib `net/http` for simple requests.
- **HTTP server**: stdlib `net/http` with `http.NewServeMux` (Go 1.22+ enhanced routing). Use chi or echo only for complex APIs.
- **JSON**: stdlib `encoding/json`.
- **SQL**: stdlib `database/sql` with appropriate driver. Use sqlc for type-safe query generation.
- **Concurrency**: stdlib `sync`, `context`, channels. Use `golang.org/x/sync/errgroup` for managed goroutine groups.

## Import Organization

```go
import (
    // Standard library
    "fmt"
    "os"

    // Third-party
    "golang.org/x/term"

    // Local/project
    "myproject/internal/config"
)
```

Stdlib, then third-party, then local — separated by blank lines. Enforced by `goimports`.

## Style & Formatting

- **`gofmt`/`goimports`** are mandatory — code must be formatted before commit.
- **`golangci-lint`** v2 for static analysis (see golangci-lint section below).
- **Package names**: short, lowercase, singular. No `_` or `mixedCaps`. The package name should not repeat the import path (`pathutil`, not `pathutilpkg`).
- **Exported names**: `PascalCase`. Unexported: `camelCase`.
- **No stuttering**: `http.Client`, not `http.HTTPClient`. `pathutil.Clean`, not `pathutil.PathClean`.
- **Interfaces**: name by what they do — `Reader`, `Formatter`. Single-method interfaces use method name + `er`.
- **Keep functions short**. If a function needs a comment explaining a section, that section might be its own function.
- **Receiver names**: short (1-2 letters), consistent across methods. Never `self` or `this`.

## Naming Conventions

- **Variables and functions**: `camelCase`
- **Exported identifiers**: `PascalCase`
- **Constants**: `PascalCase` for exported, `camelCase` for unexported. Do not use `UPPER_SNAKE_CASE`.
- **Acronyms**: all caps when exported (`HTTPClient`, `ID`), all lower when unexported (`httpClient`, `id`)
- **Package names**: short, lowercase, no underscores (`strconv`, `httputil`)

## Comments and Documentation

- Write doc comments on all exported types, functions, and package declarations.
- Doc comments are complete sentences starting with the name of the thing being documented:
  ```go
  // CleanPath removes redundant separators and resolves relative elements.
  func CleanPath(p string) string {
  ```
- Skip comments for obvious unexported helpers.
- Use `// TODO:` for planned work. Never leave empty TODO comments.

## Error Handling

- **Always handle errors explicitly.** Never use `_` to discard an error unless you've documented why it's safe.
- **Wrap with context**:
  ```go
  if err != nil {
      return fmt.Errorf("reading config %s: %w", path, err)
  }
  ```
- **Use `errors.Is` and `errors.As`** for comparison, never `==` on error values.
- **Sentinel errors** for well-known conditions:
  ```go
  var ErrNotFound = errors.New("not found")
  ```
- **Don't panic** in library code. Reserve `panic` for truly unrecoverable programmer errors.
- **Don't log and return** — do one or the other, not both.

## CLI Tool Patterns

Use the standard `main()` → `run()` pattern so that `main` only handles exit codes:

```go
func main() {
    if err := run(); err != nil {
        fmt.Fprintf(os.Stderr, "error: %v\n", err)
        os.Exit(1)
    }
}

func run() error {
    flag.Parse()
    // tool logic here
    return nil
}
```

- **stdout** for program output (data, results).
- **stderr** for errors and diagnostic messages.
- **Exit codes**: 0 for success, 1 for general errors, 2 for usage errors.
- Parse flags in `run()`, not at package level.

## Concurrency

- Prefer channels for communication, mutexes for state protection.
- Always pass `context.Context` as the first parameter to functions that do I/O or long-running work.
- Use `errgroup.Group` for managing concurrent goroutines with error propagation.
- Never launch a goroutine without a clear plan for how it stops.
- Guard shared state with `sync.Mutex` or use channel-based designs. Prefer `sync.Mutex` for simple cases.

## Testing

- Use stdlib `testing`. Table-driven tests are the default pattern:
  ```go
  func TestCleanPath(t *testing.T) {
      tests := []struct {
          name  string
          input string
          want  string
      }{
          {"absolute", "/foo/bar", "/foo/bar"},
          {"trailing slash", "/foo/bar/", "/foo/bar"},
          {"double slash", "/foo//bar", "/foo/bar"},
      }
      for _, tt := range tests {
          t.Run(tt.name, func(t *testing.T) {
              got := CleanPath(tt.input)
              if got != tt.want {
                  t.Errorf("CleanPath(%q) = %q, want %q", tt.input, got, tt.want)
              }
          })
      }
  }
  ```
- Use `t.Helper()` in test helper functions so failures report the caller's line.
- Use `testdata/` directories for fixture files (Go tooling ignores this directory).
- Name test files `<file>_test.go` in the same package.
- Name test functions `Test<Function>_<scenario>`.
- For integration tests, use build tags or `testing.Short()` to skip slow tests.

## Project Structure

Start flat and add structure when you feel the pain, not before:

```
project/
├── go.mod
├── main.go           # Single-binary projects can start here
├── cmd/              # Multiple entry points (one subdir per binary)
│   └── myapp/
│       └── main.go
└── internal/         # Private packages (compiler-enforced, not importable by other modules)
    ├── config/
    └── handler/
```

**Do not use `pkg/`**. Since `internal/` was added, everything not in `internal/`
is already public — `pkg/` carries zero information and pollutes every import
path. The Go standard library, compiler, and core tools don't use it. The
"golang-standards/project-layout" repo is community-run with no Go team
affiliation; the Go tech lead has publicly criticized it.

For libraries, keep it flat — no `cmd/`, no `internal/` unless the package is
large. Avoid deep nesting like `internal/services/user/handlers/http/v1/`.

## Dependencies

- Prefer stdlib. The best dependency is no dependency.
- When you do need a third-party package, prefer small, focused libraries over large frameworks.
- Run `go mod tidy` before committing to remove unused dependencies.
- Check `go.sum` into version control.

## Security

- Never hardcode secrets or API keys. Use environment variables.
- Use `filepath.Clean` on any user-provided file paths.
- Validate all external inputs before use.
- Be careful with `os/exec` — avoid passing unsanitized input to shell commands. Prefer `exec.Command` with separate args over shell invocation.
- Use `crypto/rand` for security-sensitive random values, never `math/rand`.

## golangci-lint v2

golangci-lint v2 (March 2025) changed the config structure. Key differences:

- `enable-all`/`disable-all` replaced by `linters.default` accepting `"all"`,
  `"standard"`, `"none"`, `"fast"`
- New `golangci-lint fmt` command
- Migration: run `golangci-lint migrate` to convert v1 configs

**Recommended baseline**: `default: standard` plus enable `gosec`, `gocyclo`
(min-complexity: 15), `revive`, `gocritic`. See `templates/golangci-lint.yml`
for a reference config.

## go generate in CI

Commit generated code and verify it stays in sync:

```sh
go generate ./... && git diff --exit-code
```

Non-idempotent generators (timestamps, map iteration order) cause spurious
failures — make generators deterministic or exclude their output from the diff.

## Structured Logging with slog

Use `log/slog` (stdlib, Go 1.21+) for all structured logging:

```go
slog.Info("request handled",
    "method", r.Method,
    "path", r.URL.Path,
    "duration", time.Since(start),
    "status", status,
)
```

- Use `slog.With()` to add context that applies to a group of log calls.
- Use `slog.NewJSONHandler(os.Stdout, nil)` for production (machine-readable).
- Use `slog.NewTextHandler(os.Stderr, nil)` for local development.
- Pass `*slog.Logger` via dependency injection or `context.Context`, not globals.

## Common Agent Mistakes in Go

These are patterns where AI-generated Go code consistently underperforms
human-written code. Watch for them during review.

### Resource lifecycle

Agents forget to close resources — database rows, file handles, HTTP response
bodies. Every `Open`, `Query`, or `Get` that returns a closeable value needs
a corresponding `defer Close()` immediately after the error check.

### Error handling quality

AI code is almost twice as likely to have error handling issues. In Go, where
every function returns an error, this compounds. Watch for: swallowed errors
(`_ = doThing()`), errors logged and returned (pick one), and generic error
wrapping that loses context.

### Concurrency errors

Agent-generated Go code has 2x the concurrency errors of human code. Goroutines
are easy to write, hard to get right. Watch for: goroutines without clear
shutdown paths, shared state without synchronization, and channel misuse
(sending on closed channels, unbounded channel growth).

### Over-abstraction

Agents default to "enterprise" patterns — unnecessary interfaces, factory
functions, and layers of indirection. In Go, write the concrete implementation
first. Extract an interface only when you have a second consumer or need to
mock at a boundary.

### Speculating instead of reading

Agents guess at APIs rather than checking godoc or source. This produces
hallucinated function signatures, wrong parameter orders, and non-existent
package names (~20% hallucination rate for package names).

## Agent-Friendly Go Patterns

Patterns that make agent-generated code more reliable:

- **Plain SQL over ORMs**: `database/sql` + sqlc. Agents produce better SQL
  than ORM code because SQL is well-represented in training data and has
  deterministic behavior.
- **Explicit security checks**: Don't rely on the agent to "know" about
  security. Add explicit input validation, use `filepath.Clean`, prefer
  `crypto/rand`, and check `exec.Command` args.
- **Compiler as guardrail**: Go's type system catches errors instantly.
  Use strong types (custom types over raw strings for IDs, enums via
  `type Status int` with `iota`) to surface mistakes at compile time.
- **Write the dumbest thing that works**: Three similar functions are better
  than a premature generic abstraction. If you see three, consider a shared
  helper — not before.
- **Provide verification commands**: Include `go test -race ./...`,
  `golangci-lint run`, and `go vet ./...` in task prompts so the agent
  can self-verify after each change.

## Code Review Checklist

Before considering code complete, verify:
- [ ] Code is formatted with `gofmt`/`goimports`
- [ ] All errors are handled (no discarded errors without justification)
- [ ] Tests cover main functionality and edge cases
- [ ] No hardcoded values that should be configurable
- [ ] `go mod tidy` has been run
- [ ] Lint passes clean
- [ ] Doc comments on all exported identifiers
- [ ] No unnecessary complexity
