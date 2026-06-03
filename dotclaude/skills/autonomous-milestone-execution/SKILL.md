---
description: Fully autonomous, unattended execution of a Linear milestone for a securely sandboxed project. Orchestrates an end-to-end loop — pull issues from Linear, validate, execute (parallel agents), verify, clean up, update Linear — making decisions with documented defaults instead of pausing for human input. Defers blocked issues and continues; never halts the whole run for a single blocker. Designed to run overnight without supervision.
argument-hint: (optional) Linear milestone name (e.g. "Phase 1") or root issue ID (e.g. CON-350)
---

# Autonomous Milestone Execution

You are the **orchestrator** of an unattended, overnight run that drives a whole
Linear milestone to completion in a securely sandboxed project. You pull issues
from Linear, drive each through validate → execute → verify → clean up,
delegate heavy work to subagents, commit as you go, and keep Linear updated so
the board tells the whole story by morning.

This skill is **self-contained**. It does not delegate to the manually-supervised
skills (`/validate-issue`, `/execute-issue`, `/verify-worktree`,
`/cleanup-worktree`, `/checkout-work`). Their operational substance has been
ported into the `references/` files below, rewritten so every decision is made
autonomously. There are no "ask the user" branches to work around — do not invoke
those other skills; follow the reference files instead.

## The autonomy contract (always hold this)

These five rules govern every phase. The reference files are written to obey
them; when you read a reference file, these still apply.

1. **Decide, don't ask.** Every choice has a defined default in the reference
   files. Take it, then record it — Linear comment for design-level choices,
   commit body for code-level ones. Never block waiting for a human.
2. **Defer, don't halt.** A blocker stops *one issue*, not the run. When an issue
   exhausts its retry budget, quarantine it (`references/07-deferral-and-exit.md`)
   and pull the next eligible issue. The run ends only on an Exit Condition.
3. **State is durable.** Quarantine lives on the Linear label `autonomous:blocked`
   so a restart never re-picks a known-bad issue. Linear status is the source of
   truth for what is done, in flight, or pending.
4. **Standard mode only.** Always new work branched from `origin/staging`. Never
   review-fixes mode, never merge a PR's fixes, never promote staging → main.
5. **Stay lean; delegate the heavy lifting.** You hold metadata only — issue IDs,
   file lists, the dependency graph, counters, test commands. You never read
   implementation files or full design docs into your own context. Codebase
   exploration and per-task implementation happen in **subagents** whose context
   is discarded when they return. This is what lets the run last for hours.

**Sandbox assumption**: irreversible-looking actions (push, local-staging merge,
branch/worktree delete) are contained and safe to perform unattended. The single
retained outward gate is **staging → main**, which the loop never crosses.

**Authority**: every terminal action in the reference files — push, raise PR,
merge into local staging, delete branches/worktrees, update Linear — is an
explicit instruction for this unattended run. Default cautions ("don't push",
"confirm before merging") do not apply here.

## Delegation model

- **Run inline in your own session** (they need the worktree session or top-level
  parallelism): execute (`04`), verify (`05`), cleanup (`06`). `EnterWorktree`
  only moves *your* session, and only the top-level loop can fan out parallel
  agents — so these stay with you.
- **Delegate to subagents** (context-heavy, no worktree needed): codebase
  exploration during validate (`03`) goes to `Explore` subagents; per-task code
  implementation during execute (`04`) goes to parallel implementer subagents.
- Subagents return **compact structured results** (summary, files changed, commit
  hash, pass/fail) — never raw file contents. You keep the result, drop the rest.

## Setup (run once)

Read `references/01-setup.md` and follow it to:
- resolve the milestone scope from `$ARGUMENTS`,
- ensure the `autonomous:blocked` label exists,
- initialize run-state counters (`retry_counts`, `max_retries=3`,
  `consecutive_defers`, `defer_circuit_breaker=3`).

## The loop

Repeat until an Exit Condition in `references/07-deferral-and-exit.md` fires:

1. **Assess + triage** — read `references/02-triage.md`. Query Linear for current
   state (excluding `autonomous:blocked` issues), pick the first matching action:
   resume interrupted work, finish pending verification, resolve a safe concern,
   or pick the next unblocked Todo issue. This step also handles entering/creating
   the worktree for the chosen issue.
2. **Validate** — read `references/03-validate.md`. Make the issue
   execution-ready (Work Items checklist + Execution Analysis), resolving open
   questions into documented assumptions. If it cannot be made executable even
   with reasonable assumptions → defer and return to step 1.
3. **Execute** — read `references/04-execute.md`. Create local tasks with
   dependencies, dispatch parallel implementer subagents, test + commit each
   task, update Linear, then push and raise a PR to staging. On unrecoverable
   failure after the retry budget → defer and return to step 1.
4. **Verify** — read `references/05-verify.md`. Merge staging into the branch,
   resolve conflicts with documented judgment, run the full suite. If it can't be
   made green within the budget → defer and return to step 1.
5. **Cleanup** — read `references/06-cleanup.md`. Merge into local staging
   (no confirmation), merge the GitHub PR, remove the worktree/branch, mark the
   issue Done. Post an epic progress comment, reset this issue's counters and
   `consecutive_defers = 0`.
6. **Return to step 1.**

At any point an issue cannot proceed autonomously, apply the **Deferral Protocol**
in `references/07-deferral-and-exit.md` and continue the loop — do not stop.

## Reference files

| File | Phase | What it contains |
|---|---|---|
| `references/01-setup.md` | Setup | Scope resolution, quarantine label, run-state counters |
| `references/02-triage.md` | Loop step 1 | State assessment, triage decision tree, worktree checkout/create |
| `references/03-validate.md` | Loop step 2 | Autonomous issue validation, exploration via subagents, dependency analysis |
| `references/04-execute.md` | Loop step 3 | Parallel task dispatch, test/commit per task, PR to staging |
| `references/05-verify.md` | Loop step 4 | Merge staging in, conflict resolution, full-suite validation |
| `references/06-cleanup.md` | Loop step 5 | Local-staging merge, PR merge, worktree/branch teardown, mark Done |
| `references/07-deferral-and-exit.md` | Cross-cutting | Deferral protocol, circuit breaker, exit conditions, morning summary |

## Compaction & restart safety

If the session compacts or crashes, restart the skill with the same arguments.
Because Linear status + the `autonomous:blocked` label are the source of truth,
the loop resumes correctly: Done issues stay done, quarantined issues stay
skipped, and an interrupted In Progress issue is picked up by triage step 4a.
`retry_counts` resetting on restart is fine — a fresh context deserves a fresh
attempt.
