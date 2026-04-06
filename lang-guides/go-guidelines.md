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
- **`golangci-lint`** for static analysis.
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

Standard layout for applications:

```
project/
├── go.mod
├── cmd/              # Entry points (one subdir per binary)
│   └── myapp/
│       └── main.go
├── internal/         # Private packages (not importable by other modules)
│   ├── config/
│   └── handler/
└── pkg/              # Public packages (importable by other modules, use sparingly)
```

For libraries, keep it flat — no `cmd/`, no `internal/` unless the package is large.

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
