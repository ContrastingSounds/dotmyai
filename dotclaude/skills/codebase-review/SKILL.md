---
description: Review an entire codebase — detect ownership, pull Linear design docs, run automated health scan, and produce triaged findings. Use when taking stock after many PRs, reviving a neglected project, or getting familiar with a cloned repo.
argument-hint: Optional focus area (e.g. "pkg/fsm", "security only", "post-PR-spree")
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(scc *) Bash(bash *)
---

## Scan data

```!
bash ${CLAUDE_SKILL_DIR}/scripts/codebase-scan.sh
```

## Input

Focus area or review context: $ARGUMENTS

If arguments are provided, scope the review to the specified area or emphasis. Otherwise, review the full codebase.

## Step 1: Determine Ownership and Context

### 1a: Check repo ownership

Parse the git remote from the scan data above. Check if the owner matches any of:
- `ContrastingSounds`
- `jonwalls-dev`
- `TheRillJon`

If it matches, this is the user's own repo — proceed to 1b. Otherwise, skip to 1c.

### 1b: Search Linear for project and design docs (own repos only)

Search for a Linear project matching the repo name:

```
mcp__linear__list_projects()
```

Scan the results for a project name that matches or closely matches the repo name. If found:

1. Retrieve the project details:
```
mcp__linear__get_project(id: "<project_id>")
```

2. List all documents attached to the project:
```
mcp__linear__list_documents(projectId: "<project_id>")
```

3. For each document that looks like a PRD, design spec, or architecture doc (based on title), retrieve its content:
```
mcp__linear__get_document(id: "<doc_id>")
```

Store any PRD or design document content for use in Step 2. If no project or documents are found, note this and continue.

### 1c: Read local project docs

Read the project's CLAUDE.md, README, and any docs/ directory for architecture context. For third-party repos, this is the primary source of design intent.

## Step 2: Agent Review Passes

Using the scan data injected above and any design documents from Step 1, run the following review passes. Adapt based on the focus area from $ARGUMENTS if provided.

### 2a: Architecture review

Analyze the codebase architecture with context from all prior steps:

- If a PRD or design spec was found: compare the implementation against the stated requirements. List requirements that are fully implemented, partially implemented, or missing. Flag code that doesn't map to any stated requirement.
- Cross-reference high-churn files from the scan with their complexity scores — these are where risk concentrates.
- Check dependency direction: do modules depend inward (good) or circularly (bad)?
- Look for god files/packages, inconsistent patterns in error handling/logging/config, dead code, and overly broad API surfaces.

### 2b: Security review

If the scan found leaked secrets or high-severity vulnerabilities, call these out as P1 findings immediately.

Then perform a broader security assessment:
- Input validation at system boundaries
- Auth boundaries and credential handling
- Insecure data handling patterns

### 2c: Test assessment

Cross-reference test coverage with churn hotspots from the scan:
- Are the most-changed files also the best-tested?
- Look for untested high-churn files, tests with no meaningful assertions, and stale test files.
- If tests can be run quickly (small project), run them and report results. For larger projects, collect tests without running and report coverage structure.

### 2d: Targeted specialist passes (if warranted)

Based on findings so far, invoke specialist agents where they add value:

- If error handling concerns were found: use the `silent-failure-hunter` agent on affected directories.
- If domain types look problematic: use the `type-design-analyzer` on core type files.
- If stale comments were flagged: use the `comment-analyzer` on affected areas.

Only run specialists that address specific concerns from earlier passes — do not run all of them by default.

## Step 3: Triage and Report

### 3a: Classify findings

Classify every finding into one of three priorities:

| Priority | Criteria |
|----------|----------|
| **P1 — Fix now** | Security vulns, broken build/tests, data loss risks, leaked secrets |
| **P2 — Fix soon** | High-churn + high-complexity hotspots, deps with known CVEs, missing critical tests |
| **P3 — Capture** | Code smells, style drift, minor tech debt, missing docs |

### 3b: Present the report

Present findings grouped by priority. For each finding include:
- File path and line number where applicable
- What the issue is
- Why it matters (risk/impact)
- Suggested fix direction

### 3c: Offer next actions

After presenting findings, offer these actions:
- **Create Linear issues**: "Want me to create Linear issues for the P1 and P2 findings?"
- **Update CLAUDE.md**: "Should I add any of these patterns as CLAUDE.md rules to prevent recurrence?"
- **Fix P1s now**: "Want me to fix the P1 issues in a worktree?"

Wait for the user to choose before taking action.

## Rules

- **Read-only by default**: Do not modify any files during the review. Only modify if the user explicitly asks for fixes in Step 3c.
- **Linear is optional**: If the repo is not owned by the user, or if no Linear project is found, skip the Linear steps and continue. The review works without design docs.
- **Respect focus**: If $ARGUMENTS specifies a focus area, scope all analysis to that area. Don't run unrelated passes.
- **Don't run all specialists**: Only invoke specialist agents (2d) when earlier passes surface specific concerns.
- **Interpret, don't just list**: Every section should contain analysis, not just raw tool output. The value of this skill is the interpretation and prioritisation.
