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

## Step 2: Fetch the Issue, Comments, and Sub-Issues

1. Use `mcp__linear__get_issue` with `includeRelations: true` to retrieve the issue details, including description and relations (blocking/blocked-by).
2. Use `mcp__linear__list_comments` to retrieve all comments on the issue.
3. Use `mcp__linear__list_issues` with `parentId` set to the issue identifier to retrieve sub-issues (children). Linear's `includeRelations` only returns peer relations (blocking, related, duplicate) — parent-child relationships require a separate query.

Run all three calls in parallel. If the issue cannot be found, inform the user and stop.

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

1. Post a threaded reply using `mcp__linear__save_comment` with `parentId` set to the question comment's ID:
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

## Step 4b: Analyze Task Dependencies

Using the codebase knowledge from Step 4, perform a code-level dependency analysis across all tasks identified in the issue description (or sub-issues from Step 2):

### File mapping

For each task, list the specific files it will create or modify. Use actual file paths from the codebase, not package names or directory globs. Record these per-task file lists — they will be included in the task checklist (Step 6) and the Execution Analysis section (Step 7).

### Overlap detection

Compare file lists across tasks. Two tasks that modify the same file must be executed sequentially — never in parallel — to prevent merge conflicts on a shared branch.

### Logical dependency detection

Beyond file overlap, identify ordering constraints:
- A task that defines new types or interfaces must run before tasks that consume them.
- A task that creates infrastructure (config, schema, middleware) must run before tasks that depend on it.
- A task that changes a function signature must run before tasks that call that function.

### Execution wave assignment

Group tasks into execution waves:
- **Wave 1**: Tasks with no dependencies (can all run in parallel).
- **Wave 2**: Tasks that depend only on Wave 1 tasks (can run in parallel with each other once Wave 1 completes).
- Continue until all tasks are assigned.

If all tasks form a single dependency chain, there is one task per wave (fully sequential execution).

Record the file overlap, dependencies, and wave assignments for inclusion in Steps 6 and 7.

## Step 5: Check for Sub-Issues

Use the `list_issues` results from Step 2 to check whether the issue has sub-issues (children).

### If sub-issues exist

Each sub-issue becomes a task in the checklist. For each sub-issue:

1. The `list_issues` response includes titles and truncated descriptions. Fetch full details with `mcp__linear__get_issue` for any sub-issue whose description was truncated.
2. Use the sub-issue's title as the task title, and its identifier as a reference (e.g., `**Task 1: Add field validation (CON-43)**`).
3. Derive the *What* and *Validate* sections from the sub-issue's description and your codebase exploration. If the sub-issue description is too vague to produce a concrete validation step, flag it and ask the user.
4. Preserve the sub-issue ordering implied by any blocking relations. If no blocking relations exist, order by sub-issue sort order or creation date.

Each sub-issue should appear as a task in the checklist. Additional tasks that don't correspond to a sub-issue are fine — not every task needs its own sub-issue.

### If no sub-issues exist

Build the checklist from the issue description and codebase exploration as described below.

## Step 6: Build the Execution-Ready Checklist

Rewrite or refine the issue description so it contains a **task checklist** where every item follows this pattern:

```markdown
- [ ] **Task N: [Short imperative title]** *(SUB-ID if from a sub-issue)*
  *TODO*: [Specific description of the change — logic to add/change]
  *Files*: `path/to/file1.go`, `path/to/file2.go`
  *TEST*: [How to verify this task is correct — specific test command, manual check, or expected output]
  *Then*: Run tests → commit → update Linear
```

### Checklist Rules

- Each task must be a single, independently testable unit of work.
- Tasks should be ordered so that earlier tasks don't depend on later ones.
- Every task must include a `*Files*:` line listing every file that task will create or modify, using backtick-quoted paths separated by commas. These come from the file mapping in Step 4b.
- If a task modifies test fixtures or adds new tests, call that out explicitly.
- Group related changes into one task when they must be committed together (e.g., a struct change and all callers).
- Keep tasks small enough that each commit is easy to review.
- When tasks originate from sub-issues, include the sub-issue identifier so `/execute-issue` can map tasks back to sub-issues for status updates.

## Step 7: Update the Issue Description

Use `mcp__linear__save_issue` to update the issue description with the validated, execution-ready content. Preserve the existing problem statement, context, and approach sections. Replace or add the implementation checklist.

The final description structure should contain:

```markdown
## Problem Statement
[Preserved from existing description]

## Current State
[Preserved or updated from existing description]

## Proposed Approach
[Preserved from existing description]

## Work Items

- [ ] **Task 1: [Title]** *(CON-43)*
  *TODO*: ...
  *Files*: `pkg/handler.go`, `pkg/handler_test.go`
  *TEST*: ...
  *Then*: Run test suite → commit → update Linear

- [ ] **Task 2: [Title]** *(CON-44)*
  *TODO*: ...
  *Files*: `pkg/types.go`, `pkg/service.go`
  *TEST*: ...
  *Then*: Run test suite → commit → update Linear

[...]

## Execution Analysis

### File Overlap
[List each pair of tasks that share files, with the shared file(s):
- Task 1 ↔ Task 3: `pkg/handler.go`
Or: "No file overlap — all tasks modify distinct files."]

### Dependencies
[List each dependency with direction and reason:
- Task 3 → Task 1: file overlap (`pkg/handler.go`)
- Task 4 → Task 2: logical (defines `FooConfig` consumed by Task 4)
Or: "No dependencies — all tasks are independent."]

### Execution Order
[Wave-based execution plan:
- **Wave 1** (parallel): Task 1, Task 2
- **Wave 2** (parallel, after Wave 1): Task 3, Task 4
- **Wave 3** (after Wave 2): Task 5
Or: "Sequential: Task 1 → Task 2 → Task 3 (single dependency chain)"]

## Constraints
[Preserved from existing description]
```

When tasks come from sub-issues, include the sub-issue identifier in parentheses after the title. When tasks don't correspond to a sub-issue, omit the identifier.

## Step 8: Report to User

Summarize what was done:
1. Whether any outstanding questions were found and how they were resolved.
2. The number of tasks in the checklist, and how many originated from sub-issues.
3. The execution analysis: how many tasks can run in parallel, how many waves, and any file overlaps or dependencies that force sequencing.
4. Any assumptions made or risks flagged.
5. Suggest next step: "Run `/execute-issue {ID}` to begin execution, or review the updated description in Linear first."

## Rules

- **No code changes**: This command only updates the Linear issue. It does not write code, create branches, or modify the codebase.
- **Preserve context**: When updating the issue description, keep valuable existing content (problem statement, approach, technical considerations). Refine the checklist, don't replace the whole description.
- **Be specific**: Reference actual file paths, function names, and test commands discovered from the codebase — not generic placeholders.
- **Block on questions**: Do not produce an execution checklist while questions are unresolved unless the user explicitly says to proceed.
- **One checklist**: The issue should have exactly one authoritative checklist in the description when this command completes. Remove or consolidate duplicate task lists.
