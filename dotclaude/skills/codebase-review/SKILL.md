---
description: Review an entire codebase for quality, fitness for purpose, and health. Use when taking stock after many PRs, reviving a neglected project, or getting familiar with a cloned repo.
argument-hint: Optional focus or maturity (e.g. "prototype", "pkg/fsm", "production-ready check")
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(scc *) Bash(bash *)
---

## Scan data

```!
bash ${CLAUDE_SKILL_DIR}/scripts/codebase-scan.sh
```

## Input

Focus area, maturity context, or review emphasis: $ARGUMENTS

If arguments mention a maturity level (prototype, MVP, production), adapt review expectations accordingly. A prototype doesn't need hardened security, but does need clear purpose and readable code. A production system needs both.

If no arguments are provided, infer maturity from the codebase signals (test coverage, CI config, deployment config, README maturity).

## Step 1: Gather Context

### 1a: Determine what this code is supposed to do

This is the most important step. Before judging quality, understand purpose.

1. Parse the git remote from the scan data. If the owner matches `ContrastingSounds`, `jonwalls-dev`, or `TheRillJon`, this is the user's own repo — search Linear for the project:

```
mcp__linear__list_projects()
```

If a matching project is found, pull all attached documents (PRDs, design specs, architecture docs):

```
mcp__linear__list_documents(projectId: "<project_id>")
mcp__linear__get_document(id: "<doc_id>")
```

2. Read the project's README, CLAUDE.md, and any docs/ directory.

3. From all sources, build a picture of:
   - What the project is supposed to do (requirements, goals)
   - What stage it's at (prototype, active development, maintenance)
   - What constraints or conventions are stated
   - What language guidelines apply (check `~/.myai/lang-guides/` for the detected languages)

If no design docs exist and the README is minimal, note this as a finding — a codebase without a stated purpose is hard to evaluate and hard to maintain.

## Step 2: Qualitative Review

This is the core of the review. Read the code and assess it against its stated purpose and language standards. Use scan data to prioritise where to focus (high-churn, high-complexity files first).

### 2a: Fitness for purpose

If a PRD or design spec was found:
- Compare implementation against stated requirements
- List requirements that are fully implemented, partially implemented, or missing
- Flag code that doesn't map to any stated requirement (scope creep or undocumented features)

If no design docs exist:
- Infer purpose from the code, README, and package metadata
- Assess whether the code does what it appears to intend
- Note any half-finished features, dead ends, or abandoned directions

### 2b: Code quality and language idioms

Read the language guidelines from `~/.myai/lang-guides/` for the detected languages. Assess:

- **Readability**: Is the code clear and well-structured? Could someone new understand it?
- **Idiomatic style**: Does it follow the conventions for its language? (Go: effective Go patterns, error handling, package structure. Python: PEP 8, type hints, project layout. TypeScript: strict mode, proper typing, framework conventions.)
- **Naming**: Are types, functions, variables, and packages named clearly and consistently?
- **Abstractions**: Are they appropriate for the project's complexity? Over-abstraction in a small project is as much a problem as under-abstraction in a large one.
- **Error handling**: Is it consistent and appropriate? Does it follow language idioms?
- **Dead code**: Unused exports, unreachable branches, commented-out blocks.

### 2c: Project documentation

Assess the quality of project documentation:

- **README**: Does it explain what the project does, how to run it, and how to develop on it? Is it up to date?
- **CLAUDE.md**: Does it exist? Does it contain useful conventions, patterns, and project-specific guidance? Or is it boilerplate / outdated?
- **Code comments**: Are they accurate and useful, or stale and misleading? Are there areas where comments would help but are missing?

### 2d: Architecture and design

- **Module structure**: Is the code organised in a way that makes sense for its size and purpose?
- **Dependency direction**: Do modules depend inward (good) or circularly (bad)?
- **God files/packages**: Are there files doing too much?
- **API surface**: Are boundaries clean or is everything exported/public?
- **Consistency**: Error handling, logging, config management — are patterns consistent across the codebase?

### 2e: Test quality

- Do tests exist? Are they meaningful or boilerplate?
- Do they test behaviour or implementation details?
- Are high-churn files (from scan data) well-tested?
- Is the test structure appropriate for the language (see language guidelines)?

## Step 3: Automated Findings

Review the scan data from the top of this skill for automated findings. These support the qualitative review — they don't replace it.

- **Security**: If the scan found leaked secrets or high-severity vulnerabilities, call these out as P1 regardless of project maturity.
- **Dependencies**: Flag outdated deps with known CVEs. For prototypes, outdated-but-not-vulnerable deps are low priority.
- **Churn + complexity**: High-churn, high-complexity files that are also poorly tested are the highest-risk code.

For prototypes and MVPs, don't flag security hardening gaps unless there's actual exposure (auth handling, user input, network services). For production code, apply full scrutiny.

## Step 4: Triage and Report

### 4a: Report structure

Present the review in this order — quality first, automated findings second:

1. **Purpose and context**: What this code is for, what stage it's at, what docs exist
2. **Fitness for purpose**: Does it deliver on its requirements? What's missing?
3. **Code quality highlights**: What's good, what needs work, language-specific observations
4. **Documentation assessment**: README, CLAUDE.md, code comments
5. **Architecture observations**: Structure, patterns, design issues
6. **Automated findings**: Security, dependencies, churn hotspots (from scan data)

### 4b: Classify findings

| Priority | Criteria |
|----------|----------|
| **P1 — Fix now** | Broken build/tests, leaked secrets, data loss risks, code that contradicts stated requirements |
| **P2 — Fix soon** | Poor readability in high-churn areas, missing tests for core logic, stale/misleading docs, deps with known CVEs |
| **P3 — Capture** | Style drift, minor inconsistencies, missing convenience docs, non-idiomatic patterns in low-churn code |

### 4c: Offer next actions

After presenting findings, offer:
- **Create Linear issues**: "Want me to create Linear issues for the P1 and P2 findings?"
- **Update CLAUDE.md**: "Should I add any of these patterns as CLAUDE.md rules?"
- **Fix P1s now**: "Want me to fix the P1 issues in a worktree?"
- **Improve README**: "Want me to draft a better README based on what I've learned about this project?"

Wait for the user to choose before taking action.

## Rules

- **Read-only by default**: Do not modify any files during the review. Only modify if the user explicitly asks in Step 4c.
- **Quality over checklists**: The primary value is qualitative assessment of code quality, readability, and fitness for purpose. Automated scan data supports this but doesn't replace it.
- **Adapt to maturity**: A prototype, MVP, and production codebase have different expectations. Don't apply production standards to a prototype, and don't let a prototype slide on readability.
- **Read the language guidelines**: Always check `~/.myai/lang-guides/` for language-specific conventions before assessing code style.
- **Linear is optional**: If not the user's repo or no Linear project found, skip and continue.
- **Respect focus**: If $ARGUMENTS specifies a focus area, scope analysis to that area.
- **Interpret, don't just list**: Every section should contain analysis. The value is interpretation and prioritisation, not raw output.
