# Global Claude Commands & Skills

###### commands

**cleanup-worktree**
Merge a verified worktree branch into main, remove the worktree, delete the branch, and optionally update Linear.

**create-plan-from-issue**
Pull a Linear issue, review requirements, create a detailed implementation plan, and raise clarification questions as comments. Planning only — no execution.

**execute-issue**
Execute a Linear issue end-to-end — optionally split into sub-issues, create a worktree, and work through each task with tests, commits, and Linear updates.

**git-xray**
Run five diagnostic git commands against a repo and produce an interpreted analysis of codebase health, risk areas, and team dynamics.

**pull-issue-responses**
Pull responses to clarification questions from Linear issue comments, summarize answers, and suggest next steps.

**validate-issue**
Review a Linear issue and update its description so it is ready to execute — no outstanding questions, a task checklist with validation steps, and test/commit/update instructions per task.

**verify-worktree**
Merge main into the current worktree branch, resolve conflicts, and run tests to verify the branch is ready to merge back.

###### skills

**format-tables**
Format markdown tables to have equal column widths

**worktree-init**
Generate a .claude/CLAUDE.local.md summarizing the intent and implementation of the current worktree branch

