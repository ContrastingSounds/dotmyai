---
description: Autonomously work through a Linear milestone — validate, execute, verify, and clean up each issue in priority order. Designed for use with /loop for continuous execution.
argument-hint: (optional) Linear milestone name (e.g. "Phase 1") or root issue ID (e.g. CON-350)
---

# Run Phase

Autonomously work through every issue in a Linear milestone using the standard development loop:

`/project-status` → `/validate-issue` → `/execute-issue` → `/verify-worktree` → `/cleanup-worktree` → repeat

Linear issue statuses are the authoritative state machine. If the session crashes and restarts, the loop picks up from wherever Linear says things are.

## Part 1: Setup (runs once)

### Step 1: Parse Input and Resolve Scope

Input: `$ARGUMENTS`

1. If `$ARGUMENTS` is a Linear issue ID (e.g., `CON-350`): fetch it with `mcp__linear__get_issue` and use its milestone and project as scope.
2. If `$ARGUMENTS` is a milestone name (e.g., `Phase 1`): read CLAUDE.md for the project name, then resolve the milestone within that project using `mcp__linear__list_milestones`.
3. If `$ARGUMENTS` is blank: read CLAUDE.md for the project, list its milestones, and select the earliest one that has incomplete issues.

Once the milestone is resolved:

```
mcp__linear__list_issues(milestone: "<milestone ID>")
```

Record:
- The milestone name and root issue (if any).
- Total issue count and status breakdown (Todo, In Progress, In Review, Done).
- The parent/child structure (epics → sub-issues).
- Which epics have dependency relationships (e.g., Foundation must complete before API Clients).

Report the scope to the user: milestone name, issue count, status breakdown.

### Step 2: Initialize Retry State

Track failures for the halt-for-clarification mechanism:

- `retry_counts`: a map of issue ID to number of consecutive failed attempts. Starts empty.
- `max_retries`: 3.

This state lives in conversation context. If the session restarts, counts reset to zero — a fresh context may succeed where a stale one was stuck.

---

## Part 2: Development Loop

Run the following steps in sequence. After Step 7, return to Step 3. Continue until the milestone is complete or the loop halts for clarification.

### Step 3: Assess Current State

Run `/project-status` scoped to the target project.

Parse the output to classify the current state:

1. **In Progress issues**: Issues marked In Progress in Linear. Check whether an active worktree and branch exist for each.
2. **In Review issues**: Issues marked In Review (have a PR but haven't been verified/cleaned up).
3. **Concerns**: Any concerns or recommended actions raised by project-status (merge conflicts, staging/main drift, stale branches, failing tests).
4. **Todo issues**: Unstarted issues, sorted by priority.

This assessment drives the triage decision in Step 4.

### Step 4: Triage

Evaluate the assessment from Step 3. Take the **first matching action** from the list below.

#### 4a: Interrupted work (In Progress issue exists)

An issue is In Progress but we are not in its worktree. A previous session was interrupted.

1. Run `/checkout-work <issue-ID>` to enter the existing worktree.
2. Check `git status` for uncommitted changes. If any, commit or stash them.
3. Check if all sub-tasks are complete (query Linear sub-issue statuses for the issue).
   - If all sub-issues are Done → execution finished but verify/cleanup was skipped. Continue to **Step 6**.
   - If some sub-issues are still Todo or In Progress → resume execution. Continue to **Step 5b**.

#### 4b: Pending verification (In Review issue exists)

An issue has a PR but hasn't been verified and cleaned up.

1. Run `/checkout-work <issue-ID>` to enter the worktree.
2. Continue to **Step 6**.

#### 4c: Concerns raised by project-status

Project-status flagged something actionable.

1. Review each concern. If it is resolvable without human input, resolve it:
   - Stale verified branch → run `/cleanup-worktree`.
   - Merged branches lingering → delete them.
   - staging/main drift → note it but do not promote without human approval.
2. If a concern requires human judgment (e.g., conflicting design decisions, ambiguous requirements, test failures with unclear cause):
   - Post a summary to the relevant Linear issue as a comment.
   - Send a PushNotification describing the concern.
   - **Halt.** Do not continue the loop.
3. After resolving concerns, return to **Step 3** to reassess.

#### 4d: Pick next issue (no in-progress or pending work)

All clear — pick fresh work:

1. From the Todo issues, select the highest-priority unblocked issue. Respect epic dependencies: do not start an issue in an epic whose predecessor epics have incomplete work (e.g., don't start API Clients issues while Foundation issues are still Todo).
2. If no unblocked Todo issues remain in the milestone:
   - Post a completion summary on the milestone's root issue in Linear.
   - Send a PushNotification: "Milestone <name> complete."
   - **Halt.**

### Step 5: Validate and Execute

#### 5a: Validate

Use the Skill tool to run `/validate-issue <issue-ID>`.

This reviews the issue and updates its description with an execution-ready checklist: no outstanding questions, specific file paths, validation steps, dependency analysis, and test/commit instructions per task.

If validate-issue encounters unresolvable questions (needs human input):
- The questions will have been posted as Linear comments by validate-issue.
- Send a PushNotification: "Blocked on questions for <issue-ID>."
- **Halt.**

After validation completes, confirm the issue description in Linear now contains a `## Work Items` section with a task checklist.

#### 5b: Execute

Use the Skill tool to run `/execute-issue <issue-ID>`.

Execute-issue handles the full implementation cycle:
- Creates a worktree and branch from staging.
- Works through tasks with parallel agent dispatch.
- Tests each change before committing.
- Commits after each task (one commit per task, never batch).
- Updates Linear sub-issues as they complete (comments + state changes).
- Runs the full test suite after all tasks.
- Pushes the branch and raises a PR to staging.
- Posts the PR link on the Linear issue.
- Moves the issue to In Review.

**If execute-issue fails** (reports a blocker it could not resolve):
1. Increment `retry_counts[<issue-ID>]`.
2. If `retry_counts[<issue-ID>]` < `max_retries`:
   - Review the failure output. Attempt to diagnose and resolve the root cause (fix a test, resolve a conflict, clarify an ambiguous task).
   - Re-run `/execute-issue <issue-ID>`.
3. If `retry_counts[<issue-ID>]` >= `max_retries`:
   - Post a blocker comment on the Linear issue summarizing all 3 failure attempts and what was tried.
   - Send a PushNotification: "Blocked after 3 attempts on <issue-ID>."
   - **Halt.**

### Step 6: Verify

Use the Skill tool to run `/verify-worktree`.

This merges staging into the branch, resolves conflicts, and runs the full test suite to confirm the branch is clean and ready to merge back.

**If verification fails** (tests fail after merge, or conflicts require human judgment):
1. If the failure is straightforward (merge conflict resolution broke a test, obvious fix): fix it, commit, and re-run `/verify-worktree`.
2. If the failure requires design judgment or understanding of cross-issue interactions:
   - Post a blocker comment on the Linear issue explaining the verification failure.
   - Send a PushNotification: "Verification failed for <issue-ID>."
   - **Halt.**

### Step 7: Cleanup and Continue

Use the Skill tool to run `/cleanup-worktree <issue-ID>`.

This merges the branch into staging, merges the GitHub PR, removes the worktree and branch, and moves the Linear issue to Done.

After cleanup completes, confirm:
1. The Linear issue is marked Done.
2. The worktree and branch have been removed.
3. The GitHub PR is merged.

Post a brief progress comment on the parent epic in Linear:
```
Completed <issue-ID>: <title>.
Milestone progress: <done-count>/<total-count> issues.
Next: <next issue ID and title, or "assessing">.
```

Reset the retry counter for this issue: `retry_counts[<issue-ID>] = 0`.

**Return to Step 3.**

## Rules

- **Linear is the source of truth.** All decisions about what to do next come from issue statuses in Linear. Never rely on conversation memory for what's done or pending.
- **Communicate progress through Linear.** Every state transition, blocker, and completion must be recorded as a Linear comment. The user should be able to read the Linear project board and understand exactly what happened without access to terminal output.
- **Test before committing. Commit before moving on.** This is non-negotiable. Never advance to the next step with uncommitted work or failing tests. The delegated skills (`/execute-issue`, `/verify-worktree`) enforce this internally — do not override or skip their validation steps.
- **Halt, don't guess.** If you need clarification, hit a blocker you can't resolve after 3 attempts, or encounter a concern that requires human judgment: post a Linear comment explaining the situation, send a PushNotification, and stop. Never silently skip an issue or make assumptions about design intent.
- **Respect epic ordering.** Do not start work in a downstream epic while its predecessor has incomplete issues. Foundation before API Clients. API Clients before Scoring. Follow the dependency structure established in the milestone.
- **One issue at a time through the full cycle.** Do not start a new issue until the current one is Done (merged, cleaned up, Linear updated). The loop is: validate → execute → verify → cleanup → next.
- **Delegate, don't reimplement.** Use the existing skills (`/validate-issue`, `/execute-issue`, `/verify-worktree`, `/cleanup-worktree`, `/project-status`) via the Skill tool. Do not duplicate their logic.
- **Review issue descriptions when something goes wrong.** If a concern is raised, a test fails unexpectedly, or a conflict is hard to resolve, re-read the Linear issue description and recent comments before deciding how to proceed. Context from the issue may explain what the code is trying to do.
