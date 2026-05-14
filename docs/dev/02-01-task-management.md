# Task Management

How to fetch, track, and update Linear issues during agent-executed work.

## Fetching an Issue

### Parse the identifier

Accepted formats:
- Full URL: `https://linear.app/{workspace}/issue/{ID}/...` — extract `{ID}`
- Short identifier: `CON-42` — use directly

### Retrieve details

```
mcp__linear__get_issue(id: "<ID>", includeRelations: true)
mcp__linear__list_comments(issueId: "<ID>")
```

`includeRelations: true` reveals parent/child and blocking relationships needed for work package detection and dependency ordering.

### Check for sub-issues

```
mcp__linear__list_issues(parentId: "<ID>")
```

If sub-issues exist, this is a work package. If not, check whether the issue description contains a task checklist.

## Pre-flight Checks

Before starting execution, verify the issue is ready:

1. **Task checklist or sub-issues exist**. The description must contain `- [ ]` lines (single issue) or the issue must have sub-issues (work package).
2. **No unresolved questions**. Scan description and comments for open questions without answers.

If the issue is not ready, suggest `/validate-issue <ID>` and stop. Do not proceed with an under-specified issue.

## Status Updates

### State transitions

| Transition | When | Who |
|------------|------|-----|
| Todo → In Progress | Agent begins execution | Agent |
| In Progress → Needs Verification | Agent raises PR | Agent |
| Needs Verification → Done | Developer merges PR | Developer |

For sub-issues within a work package:
- Each sub-issue moves to Done when its commit lands and tests pass.
- The parent issue moves to Needs Verification when the PR is raised (not when individual sub-issues complete).

### How to update

```
mcp__linear__save_issue(id: "<ID>", state: "In Progress")
```

Use state names, not IDs. Common states: `Todo`, `In Progress`, `Needs Verification`, `Done`.

## Comment Conventions

### Execution order (work packages)

Post on the parent issue at the start of execution:

```
mcp__linear__save_comment(
  issueId: "<parent-ID>",
  body: "Execution order:\n1. CON-130: Replace deprecated strings.Title (no blockers)\n2. CON-131: Add FieldIndex map (no blockers)\n3. CON-132: Use cached AgeIdx/TurnIdx (after CON-131)\n..."
)
```

### Progress updates

After each task or sub-issue completes:

```
mcp__linear__save_comment(
  issueId: "<sub-issue-ID>",
  body: "Completed: replaced strings.Title calls with shared titleCase helper.\nValidation: go test ./pkg/fsm/ -v — all passing."
)
```

Keep updates brief. State what was done and whether validation passed.

### PR link

When the PR is raised, post on the parent issue:

```
mcp__linear__save_comment(
  issueId: "<parent-ID>",
  body: "PR raised: <PR-URL>\n\nAll sub-issues completed. Full test suite passing.\nBranch: con-129-review-findings"
)
```

### Blockers

If the agent is stuck after 3 attempts at a task:

1. Post a comment on the relevant issue explaining what failed and what was tried.
2. Do not skip the task or continue to dependent tasks.
3. Ask the user for guidance.

```
mcp__linear__save_comment(
  issueId: "<issue-ID>",
  body: "**Blocked**: [description of the problem]\n\nAttempts:\n1. [what was tried]\n2. [what was tried]\n3. [what was tried]\n\nNeed guidance on how to proceed."
)
```

### Clarification questions

Use a bold heading per question and post one question per comment to enable threaded replies:

```
mcp__linear__save_comment(
  issueId: "<issue-ID>",
  body: "**Q: Scope of titleCase refactoring**\n\nThe helper exists in pkg/api but is needed in pkg/fsm. Should I move it to a shared internal package, or duplicate it in pkg/fsm?"
)
```

## Sub-Issue Tracking

### When sub-issues already exist (work package)

Fetch the parent, then list sub-issues with `list_issues(parentId)`. Work with the existing sub-issues. Do not create new ones unless the work reveals a task not covered by any existing sub-issue.

### When to create sub-issues

If the issue has 4+ checklist items in its description and no sub-issues exist, create sub-issues:

```
mcp__linear__save_issue(
  title: "<task title>",
  team: "<team>",
  project: "<project>",
  assignee: "me",
  state: "Todo",
  priority: 3,
  parentId: "<parent-ID>"
)
```

### Dependency tracking

After creating or fetching sub-issues, analyze dependencies (see `01-04-work-packages-and-trees.md` for ordering criteria) and post the execution order as a comment on the parent.

## Tools Quick Reference

| Action | Tool |
|--------|------|
| Fetch issue | `mcp__linear__get_issue` |
| List sub-issues | `mcp__linear__list_issues` (with `parentId`) |
| List comments | `mcp__linear__list_comments` |
| Update issue | `mcp__linear__save_issue` |
| Post comment | `mcp__linear__save_comment` |
| Fetch documents | `mcp__linear__list_documents`, `mcp__linear__get_document` |

## Related Commands

- `/create-plan-from-issue <ID>` — create implementation plan, no code changes
- `/validate-issue <ID>` — ensure checklist is execution-ready
- `/pull-issue-responses <ID>` — check for answered clarification questions
- `/execute-issue <ID>` — execute a work package or single issue end-to-end
