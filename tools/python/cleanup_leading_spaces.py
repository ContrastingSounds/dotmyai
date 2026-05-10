#!/usr/bin/env python3
"""
Clean up unwanted leading spaces in text files.

This tool performs two cleanup operations:
1. Converts lines with only whitespace to empty strings
2. Removes leading spaces based on the selected mode

Modes:
- document (default): Find minimum leading spaces across entire document and remove that amount
- block: Analyze each block independently and remove minimum spaces per block (only if min >= 2)
- fixed: Per block, remove min(N, block_min_spaces) - never removes more than a block has

Usage:
    python3 cleanup_leading_spaces.py <file> [--mode {document|block|fixed}] [--spaces N]

Examples:
    # Document mode (default) - remove global minimum leading spaces
    python3 cleanup_leading_spaces.py file.md

    # Block mode - each block processed independently
    python3 cleanup_leading_spaces.py file.md --mode block

    # Fixed mode - remove exactly 2 spaces
    python3 cleanup_leading_spaces.py file.md --mode fixed --spaces 2
"""

import argparse
import sys
from typing import List, Tuple


def count_leading_spaces(line: str) -> int:
    """Count leading spaces in a line."""
    if not line:
        return 0
    count = 0
    for char in line:
        if char == ' ':
            count += 1
        else:
            break
    return count


def is_empty_or_whitespace(line: str) -> bool:
    """Check if line is empty or contains only whitespace."""
    return len(line.strip()) == 0


def split_into_blocks(lines: List[str]) -> List[Tuple[int, int]]:
    """
    Split lines into blocks separated by empty lines.
    Returns list of (start_idx, end_idx) tuples for each block.
    """
    blocks = []
    in_block = False
    start_idx = 0

    for i, line in enumerate(lines):
        if is_empty_or_whitespace(line):
            if in_block:
                # End of current block
                blocks.append((start_idx, i))
                in_block = False
        else:
            if not in_block:
                # Start of new block
                start_idx = i
                in_block = True

    # Handle last block if file doesn't end with empty line
    if in_block:
        blocks.append((start_idx, len(lines)))

    return blocks


def process_document_mode(lines: List[str]) -> List[str]:
    """
    Document mode: Find global minimum leading spaces and remove from all lines.
    """
    # Step 1: Convert space-only lines to empty strings
    cleaned = []
    for line in lines:
        if is_empty_or_whitespace(line):
            cleaned.append('')
        else:
            cleaned.append(line.rstrip('\n'))

    # Step 2: Find global minimum leading spaces (excluding empty lines)
    min_spaces = float('inf')
    for line in cleaned:
        if line:  # Skip empty lines
            spaces = count_leading_spaces(line)
            min_spaces = min(min_spaces, spaces)

    # If minimum is less than 2, don't remove anything
    if min_spaces == float('inf') or min_spaces < 2:
        return [line + '\n' if line or i < len(cleaned) - 1 else line
                for i, line in enumerate(cleaned)]

    # Step 3: Remove minimum leading spaces from all non-empty lines
    result = []
    for line in cleaned:
        if line:
            result.append(line[min_spaces:])
        else:
            result.append(line)

    # Add newlines back (preserve original line endings)
    return [line + '\n' if line or i < len(result) - 1 else line
            for i, line in enumerate(result)]


def process_block_mode(lines: List[str]) -> List[str]:
    """
    Block mode: Process each block independently, removing minimum leading spaces per block.
    """
    # Step 1: Convert space-only lines to empty strings
    cleaned = []
    for line in lines:
        if is_empty_or_whitespace(line):
            cleaned.append('')
        else:
            cleaned.append(line.rstrip('\n'))

    # Step 2: Split into blocks
    blocks = split_into_blocks(cleaned)

    # Step 3: Process each block independently
    result = cleaned.copy()

    for start_idx, end_idx in blocks:
        block_lines = cleaned[start_idx:end_idx]

        # Find minimum leading spaces in this block
        min_spaces = float('inf')
        for line in block_lines:
            if line:  # Skip empty lines
                spaces = count_leading_spaces(line)
                min_spaces = min(min_spaces, spaces)

        # If minimum is less than 2, skip this block
        if min_spaces == float('inf') or min_spaces < 2:
            continue

        # Remove minimum leading spaces from all lines in this block
        for i in range(start_idx, end_idx):
            if cleaned[i]:
                result[i] = cleaned[i][min_spaces:]

    # Add newlines back
    return [line + '\n' if line or i < len(result) - 1 else line
            for i, line in enumerate(result)]


def process_fixed_mode(lines: List[str], spaces_to_remove: int) -> List[str]:
    """
    Fixed mode: Per block, remove min(N, block_min_spaces) spaces.
    This ensures we never remove more spaces than a block actually has.
    """
    # Step 1: Convert space-only lines to empty strings
    cleaned = []
    for line in lines:
        if is_empty_or_whitespace(line):
            cleaned.append('')
        else:
            cleaned.append(line.rstrip('\n'))

    # Step 2: Split into blocks
    blocks = split_into_blocks(cleaned)

    # Step 3: Process each block independently
    result = cleaned.copy()

    for start_idx, end_idx in blocks:
        block_lines = cleaned[start_idx:end_idx]

        # Find minimum leading spaces in this block
        min_spaces = float('inf')
        for line in block_lines:
            if line:  # Skip empty lines
                spaces = count_leading_spaces(line)
                min_spaces = min(min_spaces, spaces)

        # Skip empty blocks
        if min_spaces == float('inf'):
            continue

        # Remove min(spaces_to_remove, block's actual min spaces)
        spaces_to_remove_from_block = min(spaces_to_remove, min_spaces)

        # Remove that amount from all lines in this block
        for i in range(start_idx, end_idx):
            if cleaned[i]:
                result[i] = cleaned[i][spaces_to_remove_from_block:]

    # Add newlines back
    return [line + '\n' if line or i < len(result) - 1 else line
            for i, line in enumerate(result)]


def main():
    parser = argparse.ArgumentParser(
        description='Clean up unwanted leading spaces in text files.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('file', help='File to process')
    parser.add_argument(
        '--mode',
        choices=['document', 'block', 'fixed'],
        default='document',
        help='Processing mode (default: document)'
    )
    parser.add_argument(
        '--spaces',
        type=int,
        help='Number of spaces to remove (required for fixed mode)'
    )

    args = parser.parse_args()

    # Validate arguments
    if args.mode == 'fixed' and args.spaces is None:
        parser.error('--spaces is required when using --mode fixed')

    # Read file
    try:
        with open(args.file, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File not found: {args.file}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file: {e}", file=sys.stderr)
        sys.exit(1)

    # Process based on mode
    if args.mode == 'document':
        result = process_document_mode(lines)
    elif args.mode == 'block':
        result = process_block_mode(lines)
    elif args.mode == 'fixed':
        result = process_fixed_mode(lines, args.spaces)

    # Write back to file
    try:
        with open(args.file, 'w') as f:
            f.writelines(result)
        print(f"✓ Processed {args.file} in {args.mode} mode")
    except Exception as e:
        print(f"Error writing file: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
