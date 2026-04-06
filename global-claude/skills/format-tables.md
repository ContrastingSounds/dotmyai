---
description: Format markdown tables to have equal column widths
---

# Format Markdown Tables

Format all tables in a markdown file to have equal column widths for better readability.

## Usage

Run the formatter on the file: `$ARGUMENTS`

```bash
python ai/tools/format_markdown_tables.py "$ARGUMENTS"
```

If no file is specified, ask the user which file to format.

## What It Does

- Finds all markdown tables in the file
- Calculates the maximum width for each column
- Pads all cells to equal width within their column
- Preserves alignment indicators (`:---`, `:---:`, `---:`)
- Rewrites the file in-place

## After Formatting

Show the user which file was formatted and confirm completion.
