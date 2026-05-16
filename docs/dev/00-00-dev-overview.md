# Dev Overview

This folder contains a detailed development workflow. The high level goals are:

- Provide specific actions to take, not general advice. Recipes, not research or thought pieces.
- Keep it lightweight with minimal cross-dependenices. It is a for a busy, solo, part time developer.
- Terminology should be generic, implementation should be specific. Concepts must be generally useful, but trying to maintain abstractions as a solo developer is not worth the time. As appropriate, cross-reference to Anthropic's guidance.

Process management is define in the "Planning Hierarchy" section, from Initiative down to local tasks. The source of truth for planning is Linear, separate to the version controlled source code managed in GitHub.

Every list item in the "Development Catalog" section represents a markdown document to be written and maintained. Broadly speaking, individual file should be no more than 200-300 lines.

Each document is relatively standalone, and they are not being written in any specific order. Instead, a document is being written every time I am starting a task in my development work where I have not yet formalised that task.

Each document is to be concise, prescriptive, with actual commands, skills, tools to execute. Those might be standalone executions, or short workflows.  

These are intended to be day-to-day tools and activities, where I as developer am responsible for all coordination, orchestration, judgement calls. As a solo developer, I need fast, simple techniques that are easy to maintain and adapt on the fly. The focus MUST be on a small number of skills, commands or agents that I can use to effectively delegate work to coding agents.

It is ok to propose the development of new skills and tools (scripts and binaries) in order to deliver and maintain a good document.

## Planning Hierarchy

Work is planned and tracked across four levels. The top three live in Linear and are visible to humans. The fourth is internal to the coding agent.

**Initiative (PRD)** — a long-running program of work with no end date. The PRD describes what the platform is, its architectural principles, constraints, and conventions. It links to key documents in Notion, Figma, and the repository. It is updated occasionally when foundational decisions change. Stored as a Linear initiative with a pinned document or linked Notion page.

**Project (PRD)** — a scoped body of work with a target completion date. The PRD describes the problem, users, scope, data model, phased delivery plan, and risks. It includes a "Context for Agents" section with confirmed decisions, relevant code paths, and explicitly undecided questions. Stored as a Linear project under the parent initiative, with the PRD as a project document.

**Issue (plan)** — a feature, fix, or piece of work that maps to a single PR (unless it is a sub-issue that maps to the PR of its ancestors). The issue description is the source of truth for what is being built and how. An issue may start lightweight (when written by a human), but has its description populated with a detailed plan before work begins. A [Coding Issue Template](https://linear.app/contrastingsounds/new?template=fc6d7daa-2449-4b87-a1d8-84b0745dd6d9) is available that contains a structure for a detailed plan, and is recommended for use by any human or agent to use when creating the issue. Comments are used for updates and allowing agents to ask clarification questions. This is where human and agent collaborate most closely.

**Local task** — a granular checklist item internal to Claude Code, stored in ~/.claude/tasks/. Execution skills (`/execute-issue`, `/execute-plan`) create local tasks from Linear sub-issues or plan file work items, model their cross-dependencies, then dispatch parallel agents — one per task — committing each independently.

The split of information between cloud-based Linear and local tasks is deliberate. Linear tracks what was planned and why, at a level of detail useful to humans. Local tasks track what the agent is doing right now, at a level of detail useful to the agent. The Pull Request is where the two meet — the human can verify the agent's work against the issue's plan.

## Key Documents

| Level | Lives in | Typically Written by |
|---|---|---|
| Initiative PRD | Linear Initiative | Human |
| Project PRD | Linear Project | Human |
| Issue description | Linear Issue | Human writes, agent expands |
| Issue comments | Linear Issue | Both |
| Local tasks | `~/.claude/tasks/` | Agent |
| PR | GitHub | Agent creates, human reviews |

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
