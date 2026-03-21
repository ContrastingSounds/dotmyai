# MYAI (pronounced: "My Eye")

This repo is saved at `~/.myai` and serves as the agent-independent store of all common knowledge that the developer using this machine wants to use across multiple projects, agents, programming languages, and so on.

## Folder Structure (PLANNED)

.myai/
├ CLAUDE.md              # This file; instructions on how to use the knowledge store
├ DEV_WORKFLOW.md        # Summary of my generic agentic development process
├ INTEGRATIONS.md        # Tools configured for Claude
├ LOCAL.md               # Notes on machine configuration e.g. notes on .zshrc
├ REFERENCES.md          # External tools, libraries, docs
├── .beads/              # Folder for beads: https://github.com/steveyegge/beads
├── guidelines/          # Idiomatic coding guidelines and snippets
├── project-ai/          # Folder structure to use in a code repo's ai folder
│   ├── brainstorms/        # For persisting docs from "loose" work and casual research
│   ├── designs/            # PRDs and other "slow-changing" requirements and designs
│   ├── plans/              # Formal agentic plans to be converted directly into actions
│   ├── reviews/            # Outputs of reviews and quality checks
│   │   
│   ├── instructions/       # Markdown files providing guidance on various topics
│   ├── tools/              # Deterministic tools, typically in Python and Go
│   ├── skills/             # Agentic skills
│   └── subagents/          # Subagents
│
├── ext/                 # Technology-specific resources
│   ├── go/              # Go source for CLI tools; binaries build to tools/
│   └── rill/            # Rill-specific resources and skills
│
├── skills/              # Markdown skills and commands
├── templates/           # Markdown templates e.g. for PRD and plan docs
├── tools/               # Deterministic tooling eg Go, Python, TypeScript
