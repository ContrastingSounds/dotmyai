# Go Coding Guidelines

## Overview

These standards guide development of Go CLI tools built in `~/.myai/ext/go/` and installed to `~/.myai/tools/`. Tools are small, focused command-line utilities for file management, text processing, and developer workflow automation.

## Project Structure

```
ext/go/
├── go.mod          # module myai/tools, go 1.24
├── Makefile        # build/test/lint targets
├── cmd/            # one subdirectory per tool, each produces a binary
│   └── <tool>/
│       └── main.go
└── internal/       # shared packages (used by multiple tools)
    └── <pkg>/
```

Binaries are built to `~/.myai/tools/` where they sit alongside Python and shell scripts. The `.gitignore` excludes binaries (no extension) while keeping `.py` and `.sh` files tracked.

## Adding a New Tool

1. Create a directory under `cmd/`:
   ```bash
   mkdir -p ~/.myai/ext/go/cmd/mytool
   ```
2. Add `main.go` with a `package main` and `func main()`.
3. Build it:
   ```bash
   cd ~/.myai/ext/go && make mytool
   ```
4. The binary appears at `~/.myai/tools/mytool`.
5. Run `make test` to ensure nothing is broken.
6. Run `go mod tidy` if you added dependencies.

## Preferred Libraries

- **CLI arguments**: stdlib `flag`. Use [cobra](https://github.com/spf13/cobra) only when the tool genuinely needs subcommands.
- **Logging**: stdlib `log/slog` (structured logging, added in Go 1.21).
- **File paths**: stdlib `path/filepath`. Always use `filepath.Clean` on user-supplied paths.
- **Testing**: stdlib `testing`. No third-party assertion libraries needed.
- **HTTP**: stdlib `net/http` for simple requests.
- **JSON**: stdlib `encoding/json`; consider `encoding/json/v2` when stable.
- **Avoid**: viper, logrus, testify. Keep the dependency tree minimal.

## Style & Formatting

- **`gofmt`/`goimports`** are mandatory — code must be formatted before commit.
- **`golangci-lint`** for static analysis. Run via `make lint`.
- **Import grouping** (enforced by `goimports`):
  ```go
  import (
      "fmt"
      "os"

      "golang.org/x/term"

      "myai/tools/internal/pathutil"
  )
  ```
  Stdlib, then third-party, then local — separated by blank lines.
- **Package names**: short, lowercase, singular. No `_` or `mixedCaps`. The package name should not repeat the import path (`pathutil`, not `pathutilpkg`).
- **Exported names**: `PascalCase`. Unexported: `camelCase`.
- **No stuttering**: `pathutil.Clean`, not `pathutil.PathClean`.
- **Interfaces**: name by what they do — `Reader`, `Formatter`. Single-method interfaces use method name + `er`.
- **Keep functions short**. If a function needs a comment explaining a section, that section might be its own function.

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
- **Don't panic** in library/tool code. Reserve `panic` for truly unrecoverable programmer errors.

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

## Testing

- Use stdlib `testing`. Table-driven tests are the default pattern:
  ```go
  func TestCleanPath(t *testing.T) {
      tests := []struct {
          name string
          input string
          want string
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
- Run tests: `cd ~/.myai/ext/go && make test`

## Dependencies

- Prefer stdlib. The best dependency is no dependency.
- When you do need a third-party package, prefer small, focused libraries over large frameworks.
- Run `go mod tidy` before committing to remove unused dependencies.
- Check `go.sum` into version control.

## Security

- Never hardcode secrets or API keys. Use environment variables.
- Use `filepath.Clean` on any user-provided file paths.
- Validate all external inputs before use.
- Be careful with `os/exec` — avoid passing unsanitized input to shell commands.

## Code Review Checklist

Before considering code complete, verify:
- [ ] Code is formatted with `gofmt`/`goimports`
- [ ] All errors are handled (no discarded errors without justification)
- [ ] Tests cover main functionality and edge cases
- [ ] No hardcoded values that should be configurable
- [ ] `go mod tidy` has been run
- [ ] `make lint` passes clean
- [ ] CLI tools follow the `main()` → `run()` pattern
- [ ] stdout/stderr usage is correct
