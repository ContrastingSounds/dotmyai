# Dev Overview

This folder contains a detailed development workflow. The high level goals are:

- Provide specific actions to take, not general advice. Recipes, not research or thought pieces.
- Keep it lightweight with minimal cross-dependenices. It is a for a busy, solo, part time developer.
- Terminology should be generic, implementation should be specific. Concepts must be generally useful, but trying to maintain abstractions as a solo developer is not worth the time. As appropriate, cross-reference to Anthropic's guidance.

Every list item in the "Development Catalog" section represents a markdown document to be written and maintained. Broadly speaking, individual file should be no more than 200-300 lines.

Each document is relatively standalone, and they are not being written in any specific order. Instead, a document is being written every time I am starting a task in my development work where I have not yet formalised that task.

Each document is to be concise, prescriptive, with actual commands, skills, tools to execute. Those might be standalone executions, or short workflows.  

These are intended to be day-to-day tools and activities, where I as developer am responsible for all coordination, orchestration, judgement calls. As a solo developer, I need fast, simple techniques that are easy to maintain and adapt on the fly. The focus MUST be on a small number of skills, commands or agents that I can use to effectively delegate work to coding agents.

It is ok to propose the development of new skills and tools (scripts and binaries) in order to deliver and maintain a good document.

## Development Catalog

### 01 Prep (Configure, Plan)
- brainstorm (local)
- plan (Linear)
- `01-03-configuration.md` — git branching strategy (staging + work branches)
- `01-04-work-packages-and-trees.md` — bundling changes, worktree setup, dependency ordering
- Project level MCP, plugins, skills

### 02 Build (Implementation)
- `02-01-task-management.md` — Linear issue fetching, status updates, comment conventions
- Context management
- `02-03-coding.md` — context loading, code changes, commit discipline
- `02-04-testing.md` — test decisions, verification commands, agent anti-patterns

### 03 Review (Verify)
- Code base review
- PR review
- Code simplification 
- Validate against PRD
- Logging review

### 04 Deploy (Scale)
- GCP Cloud Run
- Cloudflare 
- Local tools

### 05 Refine (Automate)
- CI/CD workflows 
- README docs 
- Logging
- Slack messaging