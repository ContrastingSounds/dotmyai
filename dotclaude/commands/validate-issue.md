---
description: Review a Linear issue and update its description so it is ready to execute — no outstanding questions, a task checklist with validation steps, and test/commit/update instructions per task.
argument-hint: Linear issue identifier (e.g. CON-42)
---

# Validate Issue for Execution

## Input

Linear issue identifier: $ARGUMENTS

## Step 1: Parse the Issue Identifier

Extract the issue identifier from the input. Accepted formats:
- Full URL: `https://linear.app/{workspace}/issue/{ID}/...` → extract `{ID}` (e.g., `CON-42`)
- Short identifier: `CON-42` → use directly

If the input does not match either format, ask the user for a valid Linear issue URL or identifier.

## Step 2: Fetch the Issue and Comments

1. Use `mcp__claude_ai_Linear__get_issue` with `includeRelations: true` to retrieve the issue details, including description and relations (sub-issues, parent, blocking/blocked-by).
2. Use `mcp__claude_ai_Linear__list_comments` to retrieve all comments on the issue.

If the issue cannot be found, inform the user and stop.

## Step 3: Check for Outstanding Questions

Scan both the issue description and comments for unresolved questions:

### In the Description
- Lines phrased as questions (ending with `?`)
- Sections titled "Open Questions" or similar
- Placeholders like `TBD`, `TODO`, `[?]`, or `[TBC]`

### In the Comments
- Clarification questions (typically formatted with bold headings like `**Q1: ...**`) that have no follow-up response from a different author
- Questions asked by any participant that remain unanswered

If outstanding questions exist:
1. List every unresolved question for the user.
2. Ask the user whether to (a) proceed anyway and note assumptions, (b) wait for answers, or (c) post follow-up comments requesting answers.
3. Do not continue to Step 4 until the user confirms how to proceed.

### Resolve Answered Threads

Proactively resolve any clarification question threads where the answer is clear and complete — do not wait for user confirmation:

1. Post a threaded reply using `mcp__claude_ai_Linear__save_comment` with `parentId` set to the question comment's ID:
   ```
   ✅ **Resolved** — [1-2 sentence summary of the answer and any decisions made]
   ```
2. Only resolve threads where the response fully addresses the question. Leave ambiguous or partially answered threads open.
3. Do this before proceeding to Step 4, so the issue's comment state accurately reflects what is settled vs. still open.

## Step 4: Explore the Codebase

Based on the issue description and implementation plan, explore the relevant parts of the codebase:

1. Read CLAUDE.md for project architecture, testing commands, and conventions.
2. Identify which files, packages, and patterns are relevant to each task.
3. Read the key files to understand current implementation and determine accurate validation steps.

Use the Agent tool with `subagent_type: "Explore"` for broad codebase exploration when needed. For targeted lookups, use Grep/Glob/Read directly.

## Step 5: Build the Execution-Ready Checklist

Rewrite or refine the issue description so it contains a **task checklist** where every item follows this pattern:

```markdown
- [ ] **Task N: [Short imperative title]**
  *What*: [Specific description of the change — files to modify, logic to add/change]
  *Validate*: [How to verify this task is correct — specific test command, manual check, or expected output]
  *Then*: Run tests → commit → update Linear
```

### Checklist Rules

- Each task must be a single, independently testable unit of work.
- Tasks should be ordered so that earlier tasks don't depend on later ones.
- If a task modifies test fixtures or adds new tests, call that out explicitly.
- Every task must have a concrete validation step — not just "check it works" but a specific command or assertion.
- Group related changes into one task when they must be committed together (e.g., a struct change and all callers).
- Keep tasks small enough that each commit is easy to review.

## Step 6: Update the Issue Description

Use `mcp__claude_ai_Linear__save_issue` to update the issue description with the validated, execution-ready content. Preserve the existing problem statement, context, and approach sections. Replace or add the implementation checklist.

The final description structure should be:

```markdown
## Problem Statement
[Preserved from existing description]

## Current State
[Preserved or updated from existing description]

## Proposed Approach
[Preserved from existing description]

## Execution Checklist

- [ ] **Task 1: ...**
  *What*: ...
  *Validate*: ...
  *Then*: Run tests → commit → update Linear

- [ ] **Task 2: ...**
  *What*: ...
  *Validate*: ...
  *Then*: Run tests → commit → update Linear

[...]

## Technical Considerations
[Preserved from existing description]
```

## Step 7: Report to User

Summarize what was done:
1. Whether any outstanding questions were found and how they were resolved.
2. The number of tasks in the checklist.
3. Any assumptions made or risks flagged.
4. Suggest next step: "Run `/execute-issue {ID}` to begin execution, or review the updated description in Linear first."

## Rules

- **No code changes**: This command only updates the Linear issue. It does not write code, create branches, or modify the codebase.
- **Preserve context**: When updating the issue description, keep valuable existing content (problem statement, approach, technical considerations). Refine the checklist, don't replace the whole description.
- **Be specific**: Reference actual file paths, function names, and test commands discovered from the codebase — not generic placeholders.
- **Block on questions**: Do not produce an execution checklist while questions are unresolved unless the user explicitly says to proceed.
- **One checklist**: The issue should have exactly one authoritative checklist in the description when this command completes. Remove or consolidate duplicate task lists.
