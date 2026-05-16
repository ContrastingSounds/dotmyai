---
description: Format markdown tables to have equal column widths
---

# Format Markdown Tables

Format all tables in a markdown file to have equal column widths for better readability.

## Usage

Run the formatter on the file: `$ARGUMENTS`

```bash
python ~/.myai/dotclaude/skills/format-tables/scripts/format_markdown_tables.py "$ARGUMENTS"
```

If no file is specified, ask the user which file to format.

## What It Does

- Finds all markdown tables in the file
- Calculates the maximum width for each column
- Pads all cells to equal width within their column
- Preserves alignment indicators (`:---`, `:---:`, `---:`)
- Rewrites the file in-place

## Cleanup Leading Spaces

If the formatted file has unwanted leading spaces (common after copy-paste from other sources), run:

```bash
python ~/.myai/dotclaude/skills/format-tables/scripts/cleanup_leading_spaces.py "$ARGUMENTS"
```

Modes: `--mode document` (default), `--mode block`, `--mode fixed --spaces N`

## After Formatting

Show the user which file was formatted and confirm completion.
