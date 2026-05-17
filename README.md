# INTRO TO DOTMYAI (pronounced: "Dot My Eye")

This repo is saved at `~/.myai` and serves as the store of personal core knowledge for development. "Personal core knowledge" means this is maintained by me (Jon), to service my own preferences and idiosyncracies.

It roughly follows a classic enterprise architecture link of thinking, with the concerns being:

**Data**: How should data be structured and stored? (largely git-managed markdown in folders!)

**Systems**: What platforms and applications are we concerned with? (e.g. Claude Code, Linear, GCP)

**Process**: What processes and automations should we follow? (e.g. development workflow with Linear)

**Content**: What _specific_ data needs to be managed (e.g. guidelines per programming language)

## Folder Structure

```
.myai/
├ CLAUDE.md              # Agentic instructions on how to use the knowledge store
├ LOCAL-ENV.md           # Notes on machine configuration e.g. notes on .zshrc
├ README.md              # This file; human instructions on how to use the knowledge store
│
├── docs/                # dotmyai docs for humans
│   ├── DEV_WORKFLOW.md     # Summary of my generic agentic development process
│   ├── INTEGRATIONS.md     # Notes on frequently used apps and services (eg Linear, DuckDB)
│   └── REFERENCES.md       # External tools, libraries, docs
│
├── dotclaude/           # Quick reference docs for humans to use in a code repo's docs folder
│   ├── commands/            # Markdown commands
│   └── skills/              # Markdown skills and commands
│
├── lang-guides/         # Idiomatic coding guidelines and snippets
├── external/            # Technology-specific resources
├── templates/           # Markdown templates e.g. for PRD and plan docs
└── tools/               # Deterministic tooling eg Go, Python, TypeScript
    ├── go/                  # Go
    ├── python/              # Python (prefering uv tools)
    └── scripts/             # Shell scripts
```
