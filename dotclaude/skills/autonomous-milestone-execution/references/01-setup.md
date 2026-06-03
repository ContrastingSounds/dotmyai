# 01 · Setup (runs once)

Resolve scope, ensure the quarantine label, and initialize run-state counters.
This runs a single time at the start of the run. Everything here is metadata you
hold in your own (orchestrator) context.

## Step 1: Parse input and resolve scope

Input: `$ARGUMENTS`.

1. **Issue ID** (e.g. `CON-350`): fetch with `mcp__linear__get_issue` and use its
   milestone and project as scope.
2. **Milestone name** (e.g. `Phase 1`): read the project's CLAUDE.md for the
   project name, then resolve the milestone with `mcp__linear__list_milestones`.
3. **Blank**: read CLAUDE.md for the project, list its milestones, and select the
   earliest one that still has incomplete issues.

If scope cannot be resolved at all (no project in CLAUDE.md, no matching
milestone), this is the **one** legitimate early stop — there is nothing to work
on. Send a PushNotification (`"Autonomous run could not resolve a milestone from
'<args>'"`) and stop.

Once resolved:

```
mcp__linear__list_issues(milestone: "<milestone ID>")
```

Record (metadata only — do not fetch full descriptions yet):

- Milestone name and root issue (if any).
- Total issue count and status breakdown (Todo, In Progress, In Review, Done).
- Parent/child structure (epics → sub-issues).
- Epic dependency relationships (e.g. Foundation before API Clients).

## Step 2: Ensure the quarantine label exists

Deferred issues are marked with a durable label so triage skips them across
restarts.

1. `mcp__linear__list_issue_labels` — look for `autonomous:blocked`.
2. If absent, create it:
   `mcp__linear__create_issue_label(name: "autonomous:blocked", color: "#eb5757")`.
3. Record the label ID as `BLOCKED_LABEL`.

## Step 3: Initialize run state

Hold these in your context (reset-on-restart is acceptable and often desirable):

- `retry_counts` — map of issue ID → consecutive failed attempts. Starts empty.
- `max_retries` — **3** (per issue).
- `consecutive_defers` — issues deferred back-to-back with no success between.
  Starts at 0.
- `defer_circuit_breaker` — **3**. If `consecutive_defers` hits this, the
  milestone or environment is probably broken; stop the run rather than thrash
  (see `07-deferral-and-exit.md`).

## Step 4: Announce

Print to the console: milestone name, issue count, status breakdown, and
"running autonomously — will defer blockers and continue, never promote to main."

Then proceed to the loop (orchestrator step 1 → `02-triage.md`).
