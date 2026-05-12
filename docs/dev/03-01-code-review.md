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

Or with maturity context or a focus area:

```
/codebase-review prototype — focus on readability and fitness for purpose
/codebase-review production-ready check
/codebase-review pkg/fsm
```

## What the Skill Does

The `/codebase-review` skill is defined at `dotclaude/skills/codebase-review/` and bundles a scan script at `scripts/codebase-scan.sh`.

The review is structured quality-first, automated-findings-second:

| Stage | What | How |
|-------|------|-----|
| **Scan** | Injects automated health data into context: LOC/complexity, git churn, dependency health, secrets, vulnerabilities. | Bundled `codebase-scan.sh` via `!` shell execution |
| **Context** | Determines purpose — checks ownership, pulls Linear PRDs, reads README/CLAUDE.md, loads language guidelines. | `git remote`, Linear MCP tools, file reads |
| **Quality review** | Assesses fitness for purpose, code quality, language idioms, documentation, architecture, test quality. | Code reading informed by scan data + design docs |
| **Automated findings** | Security, dependency, and churn findings from scan data. Weighted by project maturity — prototype vs production. | Scan data triage |
| **Triage** | Classifies findings as P1/P2/P3. Offers to create Linear issues, update CLAUDE.md, improve README, or fix P1s. | Agent + your judgment |

### Maturity-aware review

The skill adapts its expectations based on project maturity (stated in arguments or inferred from signals like CI config, test coverage, deployment setup):

- **Prototype**: Readability and fitness for purpose are critical. Security hardening and dependency currency are low priority unless there's actual exposure.
- **MVP / active development**: Code quality, test coverage for core logic, and clear documentation become important.
- **Production**: Full scrutiny — security, dependency health, test coverage, consistent patterns, clean API surfaces.

## Complementary Tools

### Git archaeology

Use `/git-xray` for deep commit history analysis:

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
| **P1 — Fix now** | Broken build/tests, leaked secrets, data loss risks, code contradicting stated requirements | Block further work until resolved |
| **P2 — Fix soon** | Poor readability in high-churn areas, missing tests for core logic, stale/misleading docs, deps with known CVEs | Create Linear issues, schedule in next cycle |
| **P3 — Capture** | Style drift, minor inconsistencies, non-idiomatic patterns in low-churn code | Log for opportunistic cleanup |

## Ownership Detection

The scan script checks the git remote against your GitHub accounts:
- `ContrastingSounds` (primary)
- `jonwalls-dev` (org)
- `TheRillJon`

If matched, the skill searches Linear for a matching project and pulls any PRDs or design specs. These are used to assess fitness for purpose — the review compares implementation against stated requirements and flags gaps, scope creep, or missing documentation.

For third-party repos, context comes from README, docs/, and CLAUDE.md.
