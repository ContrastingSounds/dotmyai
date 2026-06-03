# 03 · Validate (loop step 2)

Make the issue execution-ready: a `## Work Items` checklist where every task is
independently testable, plus an `## Execution Analysis` section describing
dependencies and execution waves. Ported from the validation skill, rewritten so
open questions become **documented assumptions** rather than stop points.

This phase makes **no code changes** — it only updates the Linear issue
description. Keep your own context lean: delegate codebase reading to subagents.

## Step 1: Fetch issue context

Run in parallel:

```
mcp__linear__get_issue(id: "<ID>", includeRelations: true)
mcp__linear__list_comments(issueId: "<ID>")
mcp__linear__list_issues(parentId: "<ID>")   # sub-issues (children)
```

If the issue is already execution-ready (description already has a `## Work Items`
section with `*Files*:` and `*TEST*:` lines for each task, and no unresolved
question comments), skip to **execute** (`04-execute.md`). Re-validation is
wasted work.

## Step 2: Resolve open questions into assumptions

Scan the description and comments for unresolved questions (lines ending `?`,
"Open Questions" sections, `TBD`/`TODO`/`[?]`, and clarification comments with no
answering reply).

For each unresolved question, **do not wait** — resolve it autonomously:

1. Choose the most reasonable interpretation given the codebase, the issue's
   stated goal, and project conventions (CLAUDE.md, language guidelines).
2. Record it as an assumption in a single Linear comment on the issue:

   ```
   🤖 **Autonomous assumptions** (no human available; proceeding):
   - Q: <question> → Assumed: <decision + 1-line rationale>
   - ...
   These can be revisited; work proceeded under them.
   ```

3. Proactively resolve clearly-answered clarification threads with a threaded
   reply (`mcp__linear__save_comment` with `parentId` = the question comment):
   `✅ **Resolved** — <1-2 sentence summary>`.

**Defer trigger**: if a question is genuinely undecidable without external
knowledge you cannot obtain (e.g. "which third-party vendor's API key do we
use?") *and* it blocks the core of the work, defer the issue
(`07-deferral-and-exit.md`). A question that only blocks a peripheral task →
assume, note it, and proceed; the peripheral task can be deferred at execute time
if the assumption proves wrong.

## Step 3: Explore the codebase (delegate)

Do **not** read implementation files into your own context. Dispatch one or more
`Explore` subagents:

```
Agent(
  subagent_type: "Explore",
  description: "Map files for <ID>",
  prompt: "For Linear issue <ID> (<one-line goal>), identify the exact files each
  task will create or modify. Read CLAUDE.md for conventions and test commands.
  For each prospective task, return: task title, concrete file paths (real paths,
  not globs), the test/validation command that proves it correct, and any
  ordering constraints (types before consumers, infra before features). Return a
  compact structured list — no file contents."
)
```

Keep only the returned structured map (task → files → test → constraints).

## Step 4: Dependency analysis

From the exploration map:

- **File overlap**: tasks touching the same file must run sequentially (never two
  agents on one file).
- **Logical dependencies**: type/interface definitions before consumers;
  infra/config/schema before features; signature changes before callers.
- **Execution waves**: Wave 1 = no dependencies (parallel); Wave 2 = depends only
  on Wave 1; continue until all tasks are placed. A single dependency chain
  collapses to one task per wave (fully sequential).

## Step 5: Write the execution-ready description

Update the issue with `mcp__linear__save_issue`. **Preserve** existing problem
statement / approach / constraints; add or replace the checklist and analysis.

```markdown
## Work Items

- [ ] **Task 1: <imperative title>** *(SUB-ID if from a sub-issue)*
  *TODO*: <specific change — logic to add/modify>
  *Files*: `path/a.go`, `path/a_test.go`
  *TEST*: <exact command or check that proves correctness>
  *Then*: Run tests → commit → update Linear

- [ ] **Task 2: ...** *(SUB-ID)*
  ...

## Execution Analysis

### File Overlap
[Each task pair sharing files, or "No file overlap."]

### Dependencies
[Each dep with direction + reason, or "No dependencies."]

### Execution Order
[Wave-based plan, or "Sequential: Task 1 → Task 2 → ..."]
```

Rules for the checklist:
- Each task is one independently testable, independently committable unit.
- Every task lists every file it touches in `*Files*:` (from Step 3).
- When a task comes from a sub-issue, include the sub-issue ID so execute can map
  status updates back to it.
- Exactly one authoritative checklist; consolidate any duplicates.

## Step 6: Hand off

Confirm the saved description contains a `## Work Items` section, then proceed to
**execute** (`04-execute.md`).

If no concrete, testable tasks could be produced even with reasonable
assumptions, **defer** the issue (`07-deferral-and-exit.md`) and return to triage.
