---
description: Pull a Linear issue, review requirements, create a detailed implementation plan, and raise clarification questions as comments. Planning only — no execution.
argument-hint: Linear issue URL (e.g. https://linear.app/team/issue/CON-18/title)
---

# Create Implementation Plan from Linear Issue

## Input

Linear issue URL or identifier: $ARGUMENTS

## Step 1: Parse the Issue Identifier

Extract the issue identifier from the input. Accepted formats:
- Full URL: `https://linear.app/{workspace}/issue/{ID}/...` → extract `{ID}` (e.g., `CON-18`)
- Short identifier: `CON-18` → use directly

If the input does not match either format, ask the user for a valid Linear issue URL or identifier.

## Step 2: Fetch the Issue

Use `mcp__claude_ai_Linear__get_issue` with `includeRelations: true` to retrieve the issue details. Read the full description, status, labels, and any existing comments.

If the issue cannot be found, inform the user and stop.

## Step 3: Understand the Codebase Context

Based on the issue requirements, explore the relevant parts of the codebase:

1. Read CLAUDE.md for project architecture and conventions
2. Identify which files, packages, and patterns are relevant to the issue
3. Read the key files to understand current implementation
4. Note any constraints, dependencies, or patterns that affect the plan

Use the Agent tool with `subagent_type: "Explore"` for broad codebase exploration when needed. For targeted lookups, use Grep/Glob/Read directly.

## Step 4: Draft the Implementation Plan

Update the Linear issue description with a structured implementation plan. Preserve any existing content that is still relevant (problem statement, context) and add or refine:

### Plan Structure

```markdown
## Problem Statement
[Keep or refine existing problem statement]

## Current State
[Document relevant current implementation details discovered from codebase]

## Proposed Approach
[Specific approach chosen, with rationale for why this approach over alternatives]

## Implementation Plan

### Phase N: [Phase Name]
- [ ] Step description — file(s) affected, what changes
- [ ] ...

[Repeat for each phase]

## Technical Considerations
[Architecture constraints, dependency implications, backward compatibility, testing strategy]

## Open Questions
See comments for clarification questions that need answers before implementation.
```

Use `mcp__claude_ai_Linear__save_issue` to update the description. Keep what works from the existing description — refine rather than replace wholesale.

## Step 5: Raise Clarification Questions

Post each clarification question as a **separate comment** on the issue using `mcp__claude_ai_Linear__save_comment`, so the user can respond to each one individually in Linear. Each comment should have a bold heading summarizing the question (e.g., `**Q1: Scope of API surface**`) followed by the full question and any relevant options or trade-offs.

Focus questions on:

- Ambiguous requirements or underspecified behavior
- Trade-offs that need a product/user decision
- Scope boundaries — what's in vs. out
- Dependencies on external tools, libraries, or decisions
- Anything that would change the implementation approach

## Step 6: Report to User

Summarize what was done:
1. Brief overview of the plan created
2. Number of open questions raised
3. Suggest next steps (e.g., "Review the updated issue description and answer the clarification questions, then we can iterate on the plan")

## Rules

- **Planning only**: Do not write code, create branches, or make any changes to the codebase.
- **Preserve context**: When updating the issue description, keep valuable existing content. Refine, don't replace.
- **Be specific**: Reference actual file paths, function names, and line numbers from the codebase in the plan.
- **Flag risks**: Call out anything that seems risky, complex, or likely to require iteration.
- **One question per comment**: Post each clarification question as its own comment so the user can reply to each individually.
