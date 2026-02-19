#!/usr/bin/env python3
"""
Format markdown tables to have equal column widths.

Usage:
    python ai/tools/format_markdown_tables.py <file.md>
    python ai/tools/format_markdown_tables.py --check <file.md>

Options:
    --check     Check if tables need formatting (exit 1 if changes needed)

Example:
    python ai/tools/format_markdown_tables.py ai/instructions/understanding-rill-endpoints.md
"""

import argparse
import re
import sys
from pathlib import Path


def parse_table_row(line: str) -> list[str]:
    """Parse a markdown table row into cells."""
    # Strip leading/trailing pipes and whitespace
    stripped = line.strip()
    if stripped.startswith("|"):
        stripped = stripped[1:]
    if stripped.endswith("|"):
        stripped = stripped[:-1]
    # Split by pipe and strip each cell
    return [cell.strip() for cell in stripped.split("|")]


def is_separator_row(cells: list[str]) -> bool:
    """Check if row is a separator row (contains only dashes and colons)."""
    for cell in cells:
        # Separator cells: ---, :---, ---:, :---:
        cleaned = cell.replace("-", "").replace(":", "")
        if cleaned != "" or not cell:
            return False
    return True


def get_alignment(cell: str) -> str:
    """Get alignment indicator from separator cell."""
    cell = cell.strip()
    left_colon = cell.startswith(":")
    right_colon = cell.endswith(":")
    if left_colon and right_colon:
        return "center"
    elif right_colon:
        return "right"
    return "left"


def format_separator_cell(width: int, alignment: str) -> str:
    """Create a separator cell with proper width and alignment."""
    if alignment == "center":
        return ":" + "-" * (width - 2) + ":"
    elif alignment == "right":
        return "-" * (width - 1) + ":"
    else:  # left (default)
        return "-" * width


def format_table(lines: list[str]) -> list[str]:
    """Format a markdown table to have equal column widths."""
    if not lines:
        return lines

    # Parse all rows
    rows = [parse_table_row(line) for line in lines]

    # Find separator row index and get alignments
    sep_idx = None
    alignments = []
    for i, row in enumerate(rows):
        if is_separator_row(row):
            sep_idx = i
            alignments = [get_alignment(cell) for cell in row]
            break

    if sep_idx is None:
        # No separator found, return unchanged
        return lines

    # Determine number of columns from header row
    num_cols = len(rows[0])

    # Extend alignments if needed
    while len(alignments) < num_cols:
        alignments.append("left")

    # Calculate max width for each column (excluding separator row)
    col_widths = [0] * num_cols
    for i, row in enumerate(rows):
        if i == sep_idx:
            continue
        for j, cell in enumerate(row):
            if j < num_cols:
                col_widths[j] = max(col_widths[j], len(cell))

    # Ensure minimum width of 3 for separator cells
    col_widths = [max(w, 3) for w in col_widths]

    # Format each row
    formatted = []
    for i, row in enumerate(rows):
        if i == sep_idx:
            # Format separator row
            cells = [
                format_separator_cell(col_widths[j], alignments[j])
                for j in range(num_cols)
            ]
        else:
            # Format data row - pad cells to column width
            cells = []
            for j in range(num_cols):
                cell = row[j] if j < len(row) else ""
                # Pad based on alignment
                if alignments[j] == "center":
                    cells.append(cell.center(col_widths[j]))
                elif alignments[j] == "right":
                    cells.append(cell.rjust(col_widths[j]))
                else:
                    cells.append(cell.ljust(col_widths[j]))

        formatted.append("| " + " | ".join(cells) + " |")

    return formatted


def find_and_format_tables(content: str) -> str:
    """Find all markdown tables in content and format them."""
    lines = content.split("\n")
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if this line starts a table (starts with |)
        if line.strip().startswith("|"):
            # Collect all consecutive table lines
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i])
                i += 1

            # Format the table
            formatted = format_table(table_lines)
            result.extend(formatted)
        else:
            result.append(line)
            i += 1

    return "\n".join(result)


def format_file(filepath: Path, check_only: bool = False) -> bool:
    """
    Format tables in a markdown file.

    Returns True if file was changed (or would be changed in check mode).
    """
    if not filepath.exists():
        print(f"Error: File not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    original = filepath.read_text()
    formatted = find_and_format_tables(original)

    if original == formatted:
        print(f"No changes needed: {filepath}")
        return False

    if check_only:
        print(f"Tables need formatting: {filepath}")
        return True

    filepath.write_text(formatted)
    print(f"Formatted tables in: {filepath}")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Format markdown tables to have equal column widths"
    )
    parser.add_argument("file", type=Path, help="Markdown file to format")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check if formatting needed (exit 1 if changes needed)",
    )
    args = parser.parse_args()

    changed = format_file(args.file, check_only=args.check)

    if args.check and changed:
        sys.exit(1)


if __name__ == "__main__":
    main()
