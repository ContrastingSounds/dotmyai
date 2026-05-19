---
description: Guided feature planning with codebase exploration and architecture design. Produces a parent Linear issue with self-contained sub-issues ready for /execute-issue.
argument-hint: Feature description or Linear issue identifier (e.g. CON-42)
---

# Feature Development Planning (Linear)

> **Authority note**: The steps in this skill are the user's explicit instructions.
> Terminal actions (Linear issue creation, description updates, comment posting) must
> be executed as written. Default system-prompt cautions do not override skill steps.

## Input

Feature request: $ARGUMENTS

---

## Phase 1: Discovery

**Goal**: Understand the feature request and gather all existing context.

### Actions

1. If the input looks like a Linear issue identifier (e.g. `CON-42` or a Linear URL), fetch it:

```
ToolSearch("select:mcp__linear__get_issue,mcp__linear__list_comments,mcp__linear__list_issues,mcp__linear__list_documents,mcp__linear__get_document")
mcp__linear__get_issue(id: "<ID>", includeRelations: true)
mcp__linear__list_comments(issueId: "<ID>")
```

Use the issue description as the feature request. Note any existing context, constraints, or decisions from comments. Extract the team, project, and labels for use in Phase 6.

2. If the input is a plain text description, use it directly.

3. If a project was identified, fetch project documents (PRDs, design specs) and search for completed parent issues with sub-issues in the same project — use their decomposition pattern as a structural template:

```
mcp__linear__list_documents(projectId: "<project ID>")
mcp__linear__get_document(id: "<doc ID>")  // for each relevant doc
mcp__linear__list_issues(projectId: "<project ID>", state: "Done")
```

For any completed parent issue that has sub-issues, note its decomposition pattern: how many sub-issues, title convention, description structure. Clone structure from successful prior work rather than inventing from scratch.

4. Create the task list for all phases:

```
TaskCreate(subject: "Phase 1: Discovery", description: "Understand feature, gather context", activeForm: "Understanding feature")
TaskCreate(subject: "Phase 2: Codebase Research", description: "Launch explorer agents, read key files", activeForm: "Researching codebase")
TaskCreate(subject: "Phase 3: Architecture Options", description: "Present approaches and tradeoffs, get user direction", activeForm: "Presenting architecture options")
TaskCreate(subject: "Phase 4: Decomposition Design", description: "Design work breakdown along chosen approach", activeForm: "Designing decomposition")
TaskCreate(subject: "Phase 5: User Review", description: "Present detailed plan, get approval or redirection", activeForm: "Awaiting review")
TaskCreate(subject: "Phase 6: Linear Creation", description: "Create parent + sub-issues in Linear", activeForm: "Creating Linear issues")
TaskCreate(subject: "Phase 7: Quality Review", description: "Design integration test plan", activeForm: "Planning integration tests")
```

5. Mark Phase 1 in_progress. Summarize your understanding of the feature in 2-3 sentences. Mark Phase 1 completed.

---

## Phase 2: Codebase Research

**Goal**: Build deep, file-specific understanding of the domain — specific files, data structures, existing patterns, extension points, and conventions. This phase is exploration only; no design decisions are made yet.

### Actions

1. Mark Phase 2 in_progress.

2. Launch 2-3 `code-explorer` agents in parallel. Each should target a different aspect:
   - **Existing patterns**: Find features similar to this one. Identify the pattern they follow: file structure, naming conventions, data flow, test approach. Return 5-10 key files and describe the pattern each demonstrates.
   - **Domain structures**: Find data structures, types, interfaces, and schemas relevant to this feature domain. Map how data flows through the system. Return 5-10 key files with specific types/structs/interfaces defined in each.
   - **Integration points**: Find where this feature would connect to existing code. Identify extension points, hooks, middleware, routers, or factory patterns that new code plugs into. Return 5-10 key files and describe what each contributes.

   Each agent prompt must include: "Return a list of 5-10 key files to read."

3. After agents return, read all key files they identified to build deep understanding.

4. Present a structured summary of findings: patterns discovered, conventions to follow, integration points, data structures, and constraints.

5. Mark Phase 2 completed.

---

## Phase 3: Architecture Options

**Goal**: Present 2-3 genuinely distinct approaches with tradeoffs so the user can choose the direction before any detailed decomposition begins. This is the strategic decision gate.

### Actions

1. Mark Phase 3 in_progress.

2. Launch 1-2 `code-architect` agents with the combined findings from Phase 2. The architect prompt must ask for **multiple distinct approaches**, not a single recommendation:

   "Given these codebase exploration findings: [explorer summaries]. Identify 2-3 genuinely distinct approaches for implementing this feature. Each approach should represent a different philosophy, not just a naming variation. For each approach, describe:
   - **Name and core idea**: One sentence capturing the philosophy
   - **How it decomposes**: What the natural work units would be (high-level, not fully enumerated)
   - **Key files affected**: Which areas of the codebase it touches
   - **Tradeoffs**: What it optimizes for and what it sacrifices (complexity, performance, maintainability, scope, risk)
   - **Estimated scope**: Rough number of sub-issues it would produce"

3. Present the approaches to the user as a concise comparison:
   - Brief summary of each approach (2-3 sentences each)
   - Tradeoffs comparison (table format)
   - Your recommendation with reasoning — but present all options, not just the recommended one

4. **Wait for user to choose an approach.**

   - User picks an approach → continue to Phase 4 with that approach
   - User asks for a hybrid or modification → incorporate and confirm, then continue
   - "Whatever you think is best" → continue with your recommendation

5. Mark Phase 3 completed.

---

## Phase 4: Decomposition Design

**Goal**: Break down the chosen approach into specific work units and draft all Linear content. The parent issue description IS the design document.

### Actions

1. Mark Phase 4 in_progress.

2. Based on the approach chosen in Phase 3, determine the decomposition axis. The axis determines what a "family" is and what a "variant" is:
   - UI features: families = component types, variants = specific instances or states
   - Backend features: families = domain entities, variants = operations per entity
   - Data pipelines: families = pipeline stages, variants = data formats or sources
   - Cross-cutting: families = architectural layers, variants = specific implementations

3. Enumerate work units as a families × variants matrix. Present as a table:

   | # | Family | Variant | Key Trait | Key Files |
   |---|--------|---------|-----------|-----------|
   | 1 | ... | ... | ... | ... |

   Each row becomes a sub-issue. If reference issues from Phase 1 suggest a different structure, follow that proven pattern instead.

4. **Create the parent issue in Linear** (or update if input was an existing issue). The parent description IS the complete design document — someone reading only this issue understands the full scope.

   ```
   ToolSearch("select:mcp__linear__save_issue,mcp__linear__save_comment")
   ```

   If the input was a Linear issue ID, update the existing issue:
   ```
   mcp__linear__save_issue(id: "<existing ID>", description: "<parent description below>")
   ```

   If the input was plain text, create a new issue:
   ```
   mcp__linear__save_issue(
     title: "<feature title>",
     team: "<team>",
     project: "<project if identified>",
     assignee: "me",
     state: "Todo",
     priority: 2,
     description: "<parent description below>"
   )
   ```

   Note the returned issue ID — it will be used as `parentId` for the Build and Test sub-issues.

5. **Create the Build and Test sub-issues** under the parent. These are the two top-level work streams:

   ```
   mcp__linear__save_issue(
     title: "Build: <feature title>",
     team: "<team from parent>",
     project: "<project from parent>",
     assignee: "me",
     state: "Todo",
     priority: 2,
     parentId: "<parent issue ID>",
     description: "Implementation work stream. Decomposition sub-issues are children of this issue."
   )
   ```

   Note the returned Build issue ID — decomposition sub-issues in Phase 6 use this as their `parentId`.

   ```
   mcp__linear__save_issue(
     title: "Test: <feature title>",
     team: "<team from parent>",
     project: "<project from parent>",
     assignee: "me",
     state: "Todo",
     priority: 2,
     parentId: "<parent issue ID>",
     description: "Integration testing work stream. Placeholder — populated in Phase 7."
   )
   ```

   Note the returned Test issue ID — it will be used in Phase 7. Set the Test issue as blocked by the Build issue:

   ```
   mcp__linear__save_issue(
     id: "<Test issue ID>",
     blockedBy: ["<Build issue ID>"]
   )
   ```

   Parent description template:

```markdown
## Summary
[2-3 sentence overview — what and why]

## Work Streams
- **Build** (<Build issue ID>): Implementation decomposed into N sub-issues
- **Test** (<Test issue ID>): Integration testing — blocked by Build

## Scope
[Count of decomposition sub-issues under Build, decomposition axis explained]
[Table: families × variants with columns: #, Name, Key Trait, Key Files]

## Design Decisions
[Key architectural decisions from codebase research, with reasoning.
Include which approach was chosen in Phase 3 and why.]

## Reference Patterns
[Existing code patterns that sub-issues should follow, with specific file paths and function/type names]

## Dependencies
[Execution order constraints: which sub-issues must complete before others, and why (file overlap, logical dependency)]

## Acceptance Criteria
[Observable conditions for the overall feature being complete]

## Integration Test Plan
[Placeholder — filled in Phase 7]

## Next Steps
Sub-issues are created and ready for `/execute-issue <ID>`.
```

6. **Create each decomposition sub-issue in Linear** as a child of the **Build** issue. These are draft descriptions for user review in Phase 5 — not the full self-contained descriptions needed for execution (those are expanded in Phase 6).

   For each work unit, create a Linear issue with:
   - **Title** following convention: `[FAMILY] [VARIANT]: [Imperative description]`
   - **Description** containing:
     - **Summary**: 3-4 sentences on what the sub-issue will accomplish
     - **Key files**: Which files will be created or modified
     - **Dependencies**: Which other sub-issues must complete first, and why

   ```
   mcp__linear__save_issue(
     title: "<title following convention>",
     team: "<team from parent>",
     project: "<project from parent>",
     assignee: "me",
     state: "Todo",
     priority: 3,
     parentId: "<Build issue ID>",
     description: "## Summary\n[3-4 sentences]\n\n## Key Files\n[file list]\n\n## Dependencies\n[dependency list or 'None']"
   )
   ```

   Record all returned sub-issue IDs — they will be updated with full descriptions in Phase 6.

7. Mark Phase 4 completed.

---

## Phase 5: User Review

**Goal**: Present the detailed breakdown for approval or redirection. The strategic direction was already chosen in Phase 3; this review covers the specifics of the decomposition. All issues (parent, Build, Test, and decomposition sub-issues) already exist in Linear as drafts from Phase 4.

### Actions

1. Mark Phase 5 in_progress.

2. Present the full plan:
   - Parent issue title and full description (from Phase 4)
   - Work stream structure: Build (with decomposition sub-issues) and Test (integration testing, blocked by Build)
   - Sub-issue list as a numbered table with columns: title, summary, key files, dependencies, estimated complexity (S/M/L)
   - One focused question if genuine ambiguity exists (maximum one question, and only if truly needed)

3. **Wait for user response before proceeding.**

   - Approval ("looks good", "proceed", etc.) → continue to Phase 6 as-is
   - Specific redirections ("drop variant X", "add Y", "reorder these") → incorporate feedback into the Linear issues (update, create, or cancel sub-issues as needed), briefly re-present the changed portions, then continue
   - "Whatever you think is best" → continue to Phase 6 with your recommendation

4. Mark Phase 5 completed.

---

## Phase 6: Linear Enrichment

**Goal**: Expand the draft sub-issues (created in Phase 4) into full self-contained descriptions, set up blocking relations, and post a summary. The parent issue and all sub-issues already exist in Linear from Phase 4.

### Actions

1. Mark Phase 6 in_progress.

2. If the user requested changes in Phase 5, update the parent issue description in Linear first:
   ```
   mcp__linear__save_issue(id: "<parent ID>", description: "<revised parent description>")
   ```

3. **Update each decomposition sub-issue** (already created as children of the Build issue in Phase 4). Enrich each Phase 4 draft into a full, self-contained description. Every sub-issue must contain everything an executing agent needs — it must NOT reference the parent for context. Use the Phase 4 draft (title, summary, key files, dependencies) as the starting point, then expand it into this template:

```markdown
## Context
[Repeat relevant parent context: what the overall feature is, key design decisions
that affect THIS sub-issue. An agent executing this issue reads ONLY this description.
It does not have access to the parent issue.]

## Task
[Specific description of what to build or change. Include the approach to follow,
not just the goal. Use code snippets where they clarify the design better than prose.]

## Files
[Explicit file paths to create or modify, with what changes in each:
- `path/to/file.go` — add FooHandler following the pattern in BarHandler
- `path/to/file_test.go` — add table-driven tests for FooHandler]

## Reference Code
[Specific files and function/type names to use as templates:
- Pattern: `pkg/handlers/bar.go` BarHandler (follow this structure)
- Types: `pkg/types/models.go` FooConfig (use this existing type)
- Tests: `pkg/handlers/bar_test.go` (follow this test structure)]

## Validation
[Exact commands to verify the work:
- `go test ./pkg/handlers/... -run TestFoo -v`
- `go vet ./pkg/handlers/...`
Or if no test exists yet: "Add tests following the pattern in bar_test.go,
then run `go test ./pkg/handlers/... -v` to verify."]

## Acceptance Criteria
- [ ] [Specific, verifiable condition 1]
- [ ] [Specific, verifiable condition 2]
- [ ] All tests pass
```

   For each sub-issue (using the ID returned in Phase 4):
   ```
   mcp__linear__save_issue(
     id: "<sub-issue ID from Phase 4>",
     description: "<full self-contained description>"
   )
   ```

4. **Set blocking relations.** After all sub-issues are created, add dependency relations based on file overlap and logical dependencies identified in Phase 4:

   ```
   mcp__linear__save_issue(
     id: "<dependent sub-issue ID>",
     blockedBy: ["<blocking sub-issue ID>"]
   )
   ```

5. **Post summary comment** on the parent issue:

   ```
   mcp__linear__save_comment(
     issueId: "<parent ID>",
     body: "Planning complete.\n\n**Build** (<Build ID>): N sub-issues\n1. <ID>: <title>\n2. <ID>: <title>\n...\n\n**Test** (<Test ID>): Integration testing (blocked by Build)\n\nExecution order: [describe dependency chain or 'all independent']\n\nReady for `/execute-issue <Build ID>`."
   )
   ```

6. Mark Phase 6 completed.

---

## Phase 7: Quality Review

**Goal**: Design the integration test plan and populate the Test issue. The Test issue is the cross-cutting verification that happens *after* all Build sub-issues are executed. Each Build sub-issue has its own Validation section for unit-level checks; this phase plans the verification that the whole feature works together.

### Actions

1. Mark Phase 7 in_progress.

2. Based on the decomposition and codebase research from Phase 2, identify **integration concerns** — things that can only be verified after multiple sub-issues are complete:
   - **Cross-component interactions**: Do the pieces compose correctly?
   - **End-to-end data flows**: Does data move through the full pipeline?
   - **Performance and resource concerns**: Does the combined feature meet constraints?
   - **Regressions**: Do existing features still work with all the new code in place?

3. Design concrete verification steps:
   - **Automated checks**: Test commands, build commands, lint commands to run against the full branch after all sub-issues are complete.
   - **Manual verification**: Steps the developer must perform themselves (e.g., "Open the app, navigate to X, verify Y appears correctly"). Include expected results.
   - **Scripts**: If a verification step is complex, write the script content directly in the plan so the developer can run it.

4. Determine the project's primary language and read the matching guide from `~/.myai/lang-guides/<language>/<language>-guidelines.md` to identify the standard test, build, lint, and vet commands for that language. Use these to populate the integration test plan.

5. **Assess complexity** of the integration test plan. The plan is **complex** if it has 3+ distinct verification areas (e.g., API integration tests, UI end-to-end tests, performance benchmarks, data migration validation). Otherwise it is **simple**.

6. **Populate the Test issue.**

   **If simple** (1-2 verification areas): Update the Test issue description directly with the full integration test plan. The Test issue is self-contained and executable as a single unit:

   ```
   mcp__linear__save_issue(
     id: "<Test issue ID>",
     description: "<test issue description using template below>"
   )
   ```

   Test issue description template (simple):

   ```markdown
   ## Context
   [Repeat relevant feature context. This issue verifies the complete feature after all
   Build sub-issues are done. An agent executing this issue reads ONLY this description.]

   ## Integration Test Plan

   ### Automated Checks
   [Language-appropriate test, build, lint, and vet commands from the language guidelines.
   Include feature-specific test commands derived from the Build sub-issue validation steps.]

   ### Manual Verification
   - [ ] [Step 1: specific thing to check and expected result]
   - [ ] [Step 2: ...]

   ### Scripts
   [Include any custom verification scripts as code blocks]

   ## Validation
   [Exact commands to run all integration checks]

   ## Acceptance Criteria
   - [ ] All automated checks pass
   - [ ] All manual verification steps confirmed
   - [ ] No regressions in existing functionality
   ```

   **If complex** (3+ verification areas): Update the Test issue description with an overview, then create sub-issues under it — one per verification area. Each test sub-issue follows the same self-contained template as Build sub-issues (Context, Task, Files, Reference Code, Validation, Acceptance Criteria):

   ```
   mcp__linear__save_issue(
     id: "<Test issue ID>",
     description: "Integration testing for <feature>. Decomposed into N verification areas."
   )
   ```

   For each test sub-issue:
   ```
   mcp__linear__save_issue(
     title: "Test: [Verification area]: [Imperative description]",
     team: "<team from parent>",
     project: "<project from parent>",
     assignee: "me",
     state: "Todo",
     priority: 3,
     parentId: "<Test issue ID>",
     description: "<full self-contained description>"
   )
   ```

   Set blocking relations between test sub-issues if they have dependencies.

7. **Update the parent issue** with the completed Integration Test Plan section:

```markdown
## Integration Test Plan

### Automated Checks
[Language-appropriate test, build, lint, and vet commands from the language guidelines.
Include feature-specific test commands derived from the sub-issue validation steps.]

### Manual Verification
- [ ] [Step 1: specific thing to check and expected result]
- [ ] [Step 2: ...]

### Scripts
[Include any custom verification scripts as code blocks]
```

   ```
   mcp__linear__save_issue(id: "<parent ID>", description: "<updated description with integration test plan>")
   ```

8. **Report to user**:
   - Parent issue link
   - Build issue link and number of decomposition sub-issues
   - Test issue link (and number of test sub-issues if complex)
   - Dependency graph (text representation)
   - Integration test plan summary
   - Next step: `/execute-issue <Build ID>`, then `/execute-issue <Test ID>`

9. Mark Phase 7 completed.

---

## Rules

- **Planning only**: Do not create worktrees, write code, make commits, or create PRs. The output of this skill is Linear issues, not code.
- **Parent description IS the design document**: Do not create separate design documents, markdown files, or planning artifacts. Everything goes in the parent issue description.
- **Sub-issues are self-contained**: Every sub-issue must include Context, Task, Files, Reference Code, Validation, and Acceptance Criteria sections. Never say "see parent" or "as described in the parent issue." Repeat context rather than reference it.
- **Two user gates, two purposes**: Phase 3 is the strategic decision (which approach?). Phase 5 is the detail review (is the breakdown right?). Do not conflate these — the user must choose direction before decomposition begins.
- **Clone before inventing**: Search for completed work packages in the same project and use their decomposition pattern as a starting point. Do not invent structure from scratch when proven structure exists.
- **Specific file paths**: Every sub-issue must reference specific files to create/modify and specific files to use as patterns. "Follow existing conventions" is not specific enough — name the file, the function, the type.
- **Exact validation commands**: Every sub-issue must include the exact test/build command to run. "Run tests" is not specific enough — include the actual command with flags and paths.
- **Dependencies via Linear relations**: Express execution order using `blockedBy` on sub-issues, not via comments or description text.
- **Assign to me**: All created issues are assigned to "me."
- **State: Todo**: All created sub-issues start in Todo state. The parent stays in Todo until `/execute-issue` moves it to In Progress.
- **Code snippets in descriptions**: Include code snippets in sub-issue descriptions where they clarify the design better than prose. Planning includes specifying *how* to implement, not just *what* to implement.
