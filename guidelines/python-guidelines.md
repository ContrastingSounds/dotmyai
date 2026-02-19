# Python Coding Guidelines

## Dependency Management

### Package Manager

- Use `uv` for dependency management (fast, reliable)
- Fallback to `pip` + `pip-tools` if `uv` unavailable

### Dependency Files

- `pyproject.toml`: Primary dependency specification
- `uv.lock` or `requirements.txt`: Locked versions for reproducibility

### Adding Dependencies

```bash
uv add <package>           # Add runtime dependency
uv add --dev <package>     # Add dev dependency
```

### Guidelines

- Pin major versions in pyproject.toml (e.g., `requests>=2.28,<3`)
- Keep dev dependencies separate from runtime
- Audit dependencies periodically for security updates
- Prefer well-maintained packages with active communities

## Style & Formatting

- Follow PEP 8 with a line length of 88 characters (Black default)
- Use type hints for all function signatures
- Prefer `pathlib.Path` over `os.path`
- Use f-strings for string formatting

## Naming Conventions

- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Constants: `SCREAMING_SNAKE_CASE`
- Private members: prefix with single underscore `_private`

## Code Organization

- One class per file for significant classes
- Group imports: stdlib, third-party, local (separated by blank lines)
- Keep functions under 30 lines; extract helpers if longer

## Error Handling

- Use specific exception types, not bare `except:`
- Prefer early returns to reduce nesting
- Use context managers (`with`) for resource management

## Documentation

- Docstrings for all public functions and classes (Google style)
- Inline comments only for non-obvious logic
- Keep README updated with setup and usage instructions

## Testing Guidelines

### Framework

- Use `pytest` for all tests
- Place tests in `tests/` directory mirroring `src/` structure

### Test Structure

- Name test files `test_<module>.py`
- Name test functions `test_<behavior>_<scenario>`
- Use fixtures for common setup; keep them in `conftest.py`

### Coverage

- Aim for 80%+ coverage on business logic
- Don't test trivial code (getters, dataclasses)
- Always test edge cases and error paths

### Mocking

- Use `pytest-mock` or `unittest.mock`
- Mock at boundaries (external APIs, databases, filesystem)
- Prefer dependency injection over patching where possible

### Running Tests

```bash
pytest                    # Run all tests
pytest -x                 # Stop on first failure
pytest --cov=src          # With coverage
pytest -k "test_name"     # Run specific test
```