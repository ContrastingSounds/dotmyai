# 07 · Deferral & Exit (cross-cutting)

How a single blocker is quarantined without stopping the run, and the only
conditions under which the whole run ends. Any phase may invoke the Deferral
Protocol; only the conditions here end the loop.

## Deferral Protocol

Invoked when an issue cannot proceed autonomously: validation produced no
testable tasks, execute exhausted `max_retries`, verify could not go green, or a
concern tied to the issue can't be safely resolved.

1. **Commit in-flight state.** If inside the worktree with uncommitted work,
   commit it (`<issue-id>: wip — deferred by autonomous run`). **Leave the
   worktree and branch in place** for human inspection — do not delete them, and
   do not delete partial commits. Then `ExitWorktree(action: "keep")` to return
   your session to the main repo.
2. **Quarantine the issue** with the durable label:
   `mcp__linear__save_issue(id: "<issue-ID>", labels: [<existing...>, BLOCKED_LABEL])`.
3. **Post a blocker comment** on the issue: what was attempted (each retry), the
   exact failure (test output, conflict, ambiguity), and the specific decision or
   fix a human must make. Specific enough to action without re-deriving context.
4. **Notify**: `PushNotification("Deferred <issue-ID>: <one-line reason>.")`
5. **Increment `consecutive_defers`.** If it reaches `defer_circuit_breaker` (3),
   trigger the **circuit-break exit** below.
6. **Return to triage** (`02-triage.md`). The issue now carries `BLOCKED_LABEL`,
   so it — and anything blocked only by it — is skipped for the rest of the run.

A deferral is never a silent skip: label + comment + notification always.

## Exit Conditions

End the run when **any** holds. Each ends with a written summary on Linear and a
PushNotification — never a silent stop.

### E1 · Milestone complete

Every issue in the milestone is Done.

- Post a completion summary on the milestone's root issue.
- `PushNotification("Milestone <name> complete — N/N done.")`
- If staging is ahead of main, the summary **recommends** (does not perform)
  staging → main promotion.

### E2 · No actionable work remains

Open issues remain, but every one is Done, quarantined (`BLOCKED_LABEL`), or
transitively blocked only by quarantined/incomplete work.

- Post a summary listing each remaining issue and why it couldn't progress.
- `PushNotification("Autonomous run idle — M issues deferred, need human input.")`

### E3 · Defer circuit-breaker tripped

`consecutive_defers >= defer_circuit_breaker` (3 back-to-back deferrals with no
success between). Likely systemic — a bad milestone spec, a broken build
environment, or a missing prerequisite. Stop immediately rather than burn the
night.

- Post a summary of the consecutive deferrals and their common pattern.
- `PushNotification("Autonomous run stopped: N issues failed in a row — likely systemic.")`

## Morning summary (every exit)

Whatever the exit, the final Linear summary (on the milestone root issue) must
include:

- **Completed**: issues driven to Done, with PR links.
- **Deferred**: each quarantined issue, one-line reason, link, and the worktree/
  branch left for inspection.
- **Concerns**: unresolved non-issue items (e.g. staging/main drift).
- **Recommended next human action**: the single most useful thing to do first
  (often: review a deferral, or promote staging → main).

The run **never** promotes staging → main, even on full completion — that is the
single retained human gate. Surface it as a recommendation only.
