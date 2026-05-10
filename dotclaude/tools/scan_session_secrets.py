#!/usr/bin/env python3
"""Scan a Claude Code session JSONL file for env var values leaked from .zshenv."""

import re
import sys
from pathlib import Path

ZSHENV = Path.home() / ".zshenv"


def extract_env_values(zshenv_path: Path) -> dict[str, str]:
    """Parse .zshenv and return {VAR_NAME: value} for all export/assignment lines."""
    env_vars = {}
    pattern = re.compile(r'^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=["\']?([^"\'\n]+)["\']?')
    for line in zshenv_path.read_text().splitlines():
        line = line.strip()
        if line.startswith("#"):
            continue
        m = pattern.match(line)
        if m:
            name, value = m.group(1), m.group(2)
            if len(value) >= 8:  # skip short values that would false-positive
                env_vars[name] = value
    return env_vars


def scan_jsonl(jsonl_path: Path, env_vars: dict[str, str]) -> list[tuple[int, str, list[str]]]:
    """Return [(line_number, line_text, [matched_var_names])] for lines containing any env value."""
    hits = []
    with open(jsonl_path) as f:
        for lineno, line in enumerate(f, start=1):
            matched = [name for name, value in env_vars.items() if value in line]
            if matched:
                hits.append((lineno, line.rstrip(), matched))
    return hits


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <session.jsonl>")
        sys.exit(1)

    jsonl_path = Path(sys.argv[1])
    if not jsonl_path.exists():
        print(f"File not found: {jsonl_path}")
        sys.exit(1)

    if not ZSHENV.exists():
        print(f"No .zshenv found at {ZSHENV}")
        sys.exit(1)

    env_vars = extract_env_values(ZSHENV)
    print(f"Loaded {len(env_vars)} env vars from {ZSHENV}\n")

    hits = scan_jsonl(jsonl_path, env_vars)

    if not hits:
        print("No env var values found in session file.")
    else:
        print(f"Found {len(hits)} lines containing env var values:\n")
        for lineno, line, matched_vars in hits:
            preview = line[:200] + "..." if len(line) > 200 else line
            print(f"  Line {lineno}: {', '.join(matched_vars)}")
            print(f"    {preview}\n")


if __name__ == "__main__":
    main()
