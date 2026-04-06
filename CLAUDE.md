# MYAI (pronounced: "My Eye")

This repo is saved at `~/.myai` and serves as the agent-independent store of all common knowledge that the developer using this machine wants to use across multiple projects, agents, programming languages, and so on.

## Folder Structure (PLANNED)

.myai/
├ CLAUDE.md              # This file; instructions on how to use the knowledge store
├ INTEGRATIONS.md        # Primary tools for development environment
├ LOCAL.md               # Notes on machine configuration e.g. notes on .zshrc
│
├── docs/                # dotmyai docs for humans
│   └── REFERENCES.md       # External tools, libraries, docs
│
├── project-docs/        # Quick reference docs for humans to use in a code repo's docs folder
├────── DEV_WORKFLOW.md     # Summary of my generic agentic development process
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
├── lang-guides/         # Idiomatic coding guidelines and snippets
│
├── ext/                 # Technology-specific resources
│   ├── dotmyai/         # Go source for CLI tools; binaries build to tools/
│   ├── linear/          # How to use Linear with Claude across multiple projects
│   └── rill/            # Rill-specific resources and skills
│
├── commands/            # Markdown commands
├── skills/              # Markdown skills and commands
├── templates/           # Markdown templates e.g. for PRD and plan docs
└── tools/               # Deterministic tooling eg Go, Python, TypeScript
