# Python Coding Guidelines

## Overview

These standards guide code generation to ensure consistency, readability, 
and maintainability across all Python projects.

## CRITICAL: Use uv Native Commands Only

**NEVER use `pip` commands in this workspace.** Always use `uv` native functionality:

- ❌ `uv pip install` - DON'T use this
- ❌ `uv pip list` - DON'T use this
- ❌ `pip install` - DON'T use this
- ✅ `uv sync` - Use this to install/update dependencies
- ✅ `uv add <package>` - Use this to add dependencies
- ✅ `uv add --dev <package>` - Use this to add developer dependencies
- ✅ `uv remove <package>` - Use this to remove dependencies
- ✅ `uv run <command>` - Use this to run commands in the venv
- ✅ `uv tree` - Use this to view dependency tree

### Guidelines

- Pin major versions in pyproject.toml (e.g., `requests>=2.28,<3`)
- Keep dev dependencies separate from runtime
- Audit dependencies periodically for security updates
- Prefer well-maintained packages with active communities

## Preferred libraries

- **uv** for package management
- `pathlib.Path` over `os.path`
- **ruff** for linting
- **ty** for type checking
- **loguru** for logging
- **pydantic** for API requests/responses
- **pydantic-ai** for LLMs
- **httpx** for HTTP requests
- **pytest** for testing
- **playwright** for browser automation
- **sqlite** for embedded transational database
- **duckdb** for embedded analytical database
- **duckdb** for reading and writing data formats like Parquet
- **fastapi** for REST APIs
- **sqlmodel** for databases backing a REST API


## Import Organization
```python
# Standard library imports
import os
import sys

# Third-party imports
import numpy as np
import pandas as pd

# Local application imports
from myapp.utils import helper_function
from myapp.models import MyModel
```


## Type safety

- Use dataclasses to clearly define important data structures
- For external calls that cross boundaries (eg REST APIs), you may use Pydantic
- Add type hints to all function signatures
- Use modern syntax from `typing` module
- Include return type annotations
- DO NOT IMPORT typing.List or typing.Dict, just use standard list and dict types
- DO NOT IMPORT typing.Optional, just use `Type | None`
- Avoid the use of typing.Any outside of model and type definition files


## PEP 8 Compliance

- Follow PEP 8 style guide as the foundation
- Maximum line length: 88 characters (Black formatter standard)
- Use 4 spaces for indentation (never tabs)
- Use blank lines to separate functions (2 lines) and classes (2 lines)
- Use single blank line to separate logical sections within functions

## Style & Formatting
- Use type hints for all function signatures
- Prefer `pathlib.Path` over `os.path`
- Use f-strings for string formatting

## Naming Conventions

- **Variables and functions**: `snake_case`
- **Classes**: `PascalCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Private attributes/methods**: prefix with single underscore `_private_method`
- **Module names**: short, lowercase, underscores if needed `my_module.py`

## Docstrings

- Always document public functions with full docstrings
- Use one-liners for simple private functions (under 10 lines, no exceptions)
- Skip docstrings for obvious private helpers, properties, and dunder methods

### Docstring format (Google Style)
```python
def calculate_metrics(
    data: pd.DataFrame,
    metric_type: str = "accuracy"
) -> dict[str, float]:
    """Calculate performance metrics from data.
    
    Args:
        data: DataFrame containing predictions and labels
        metric_type: Type of metric to calculate. Options: "accuracy", "f1"
    
    Returns:
        Dictionary mapping metric names to their values
    
    Raises:
        ValueError: If metric_type is not supported
        KeyError: If required columns are missing from data
    
    Example:
        >>> df = pd.DataFrame({"pred": [1, 0], "label": [1, 1]})
        >>> calculate_metrics(df, "accuracy")
        {'accuracy': 0.5}
    """
    pass
```

## Error Handling

### Be Specific with Exceptions
```python
# Good
try:
    result = process_file(filename)
except FileNotFoundError:
    logger.error(f"File not found: {filename}")
    raise
except PermissionError:
    logger.error(f"Permission denied: {filename}")
    return None

# Avoid bare except or overly broad catching
```

### Custom Exceptions
```python
class DataValidationError(ValueError):
    """Raised when input data fails validation checks."""
    pass

class ConfigurationError(Exception):
    """Raised when configuration is invalid or missing."""
    pass
```


## Best Practices

### Use Context Managers
```python
# Always use context managers for resources
with open('data.txt') as f:
    content = f.read()

with db.connection() as conn:
    result = conn.execute(query)
```

### Prefer List/Dict Comprehensions
```python
# Good
squares = [x**2 for x in range(10) if x % 2 == 0]

# Better than
squares = []
for x in range(10):
    if x % 2 == 0:
        squares.append(x**2)
```

### Use Dataclasses for Data Structures
```python
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    email: str
    is_active: bool = True
```

### Logging Over Print
```python
from loguru import logger

# Use appropriate log levels
logger.debug("Detailed diagnostic information")
logger.info("General informational messages")
logger.warning("Warning messages for potentially harmful situations")

# Avoid excessive logging or trying to format log output
logger.info("==============================")
logger.info("General informational messages")
logger.info("==============================")
# BAD! Avoid log output that only contains characters for visual formatting purposes
```

### Common Optimizations
```python
# Use generators for large datasets
def process_large_file(filename: str) -> Iterable[dict]:
    """Process file line by line without loading into memory."""
    with open(filename) as f:
        for line in f:
            yield parse_line(line)
```

## Dependencies

### Manage Dependencies Explicitly
- Use `pyproject.toml` 
- Separate dev dependencies from production


## Security Considerations

### Never Hardcode Secrets
```python
# Bad
API_KEY = "sk_live_abc123xyz"

# Good
import os
API_KEY = os.environ["API_KEY"]
```

### Input Validation
- Always validate and sanitize external inputs
- Use parameterized queries for SQL
- Validate file paths before operations

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

## Code Review Checklist

Before considering code complete, verify:
- [ ] All functions have type hints and docstrings
- [ ] Error handling is appropriate and specific
- [ ] Tests cover main functionality and edge cases
- [ ] No hardcoded values that should be configurable
- [ ] Logging is not used excessively
- [ ] Code follows naming conventions
- [ ] No unnecessary complexity
- [ ] Dependencies are documented