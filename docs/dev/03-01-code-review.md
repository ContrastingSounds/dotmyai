# Code Review

How to review an entire codebase. Use this when taking stock after many PRs, reviving a neglected project, or getting familiar with a cloned repo.

This is broader than PR review — the goal is situational awareness and debt triage, not approve/reject on a single change.

## Prerequisites

Same plugin setup as PR review (see `03-02-pr-review.md`). Additionally:

- **`scc`** for LOC, language stats, and complexity estimates: `brew install scc`
- **`gitleaks`** for secret detection: `brew install gitleaks`
- **`trivy`** for multi-ecosystem vulnerability scanning: `brew install trivy` (alternative: `grype` — lighter, no supply-chain incident history)

Install the dotclaude symlinks if not already done:

```sh
~/.myai/tools/scripts/install-dotclaude.sh
```

## Quick Start

From the repo root, in a fresh Claude Code session:

```
/codebase-review
```

Or with a focus area:

```
/codebase-review security only
/codebase-review pkg/fsm
/codebase-review post-PR-spree — focus on consistency and regressions
```

## What the Skill Does

The `/codebase-review` skill is defined at `dotclaude/skills/codebase-review/` and bundles a scan script at `scripts/codebase-scan.sh`.

| Stage | What | How |
|-------|------|-----|
| **Scan** | Injects automated health data into context via `!` shell execution: LOC/complexity, git churn, dependency health, secrets, vulnerabilities. | Bundled `codebase-scan.sh` runs before Claude sees the skill content |
| **Context** | Checks repo ownership against your GitHub accounts. For your repos, searches Linear for the project and pulls PRDs/design docs. | `git remote`, Linear MCP tools |
| **Review** | Architecture review (informed by PRD if found), security review, test assessment, targeted specialist agents on flagged areas. | Claude Code agents |
| **Triage** | Classifies findings as P1/P2/P3 and offers to create Linear issues, update CLAUDE.md, or fix P1s in a worktree. | Agent + your judgment |

## Complementary Tools

### Git archaeology

Use `/git-xray` for deep commit history analysis (churn hotspots, bug clusters, contributor dynamics, risk map):

```
/git-xray
/git-xray --since "6 months ago" --focus pkg/fsm/
```

### Security only

```
/security-review
```

### Targeted specialist agents

Same agents as PR review, scoped to specific areas:

```
Use the silent-failure-hunter agent to review error handling in pkg/
Use the type-design-analyzer to review the domain types in pkg/types.go
Use the comment-analyzer to check for stale comments in src/lib/
```

## Triage Priorities

| Priority | Criteria | Action |
|----------|----------|--------|
| **P1 — Fix now** | Security vulns, broken build/tests, data loss risks, leaked secrets | Block further work until resolved |
| **P2 — Fix soon** | High-churn + high-complexity hotspots, deps with known CVEs, missing critical tests | Create Linear issues, schedule in next cycle |
| **P3 — Capture** | Code smells, style drift, minor tech debt, missing docs | Log for opportunistic cleanup |

## Ownership Detection

The scan script checks the git remote against your GitHub accounts:
- `ContrastingSounds` (primary)
- `jonwalls-dev` (org)
- `TheRillJon`

If matched, the skill searches Linear for a matching project and pulls any PRDs or design specs. These are used to validate code against intended purpose — the architecture review compares implementation to stated requirements and flags gaps or scope creep.

For third-party repos, context comes from README, docs/, and CLAUDE.md.
