---
description: Run five diagnostic git commands against a repo and produce an interpreted analysis of codebase health, risk areas, and team dynamics.
argument-hint: Path to git repo (default: current directory). Options: --since "6 months ago", --top 30, --focus runtime/, --output report.md
---

# Git X-Ray: Codebase Diagnostics from Commit History

Diagnose codebase health from commit history before reading source code. Based on [The Git Commands I Run Before Reading Any Code](https://piechowski.io/post/git-commands-before-reading-code/) by Ally Piechowski.

## Input

Arguments: $ARGUMENTS

Parse the arguments to extract:
- **repo_path**: The first non-flag argument. Default: current working directory.
- **--since**: Time window for churn, bug, and crisis queries. Default: `1 year ago`.
- **--top**: Number of results for ranked lists. Default: `20`.
- **--focus**: Optional path prefix filter (e.g., `runtime/` or `web-common/src/`) to scope file-level analysis to a subsystem. Default: none (whole repo).
- **--output**: If set, write the final report to this file path. Default: print inline.

## Step 1: Validate the Target

Run via Bash:

```bash
git -C <repo_path> rev-parse --show-toplevel
```

Confirm the path is a git repository. Extract the repo name from the top-level path (e.g., `/home/user/projects/rill` → `rill`).

If the path is not a git repo, inform the user and stop.

Count total commits in the analysis window for later normalization:

```bash
git -C <repo_path> rev-list --count --since="<since>" HEAD
```

Detect the GitHub remote for PR-based analysis:

```bash
git -C <repo_path> remote get-url origin
```

Parse the remote URL to extract `owner/repo` (e.g., `git@github.com:rilldata/rill.git` → `rilldata/rill`, or `https://github.com/rilldata/rill.git` → `rilldata/rill`). This is needed for `gh` CLI queries in Step 2f.

If the remote is not a GitHub URL or `gh` is not available, skip PR-based analysis (Steps 2f–2g, and the PR-based enrichments in Step 4) and note this in the report.

## Step 2: Collect Data

Run all five commands in **parallel** using the Bash tool (five separate Bash calls in one message). All commands use `git -C <repo_path>` to target the repo without changing directory.

### 2a: Churn Hotspots

Most-modified files in the time window:

```bash
git -C <repo_path> log --format=format: --name-only --since="<since>" | sort | uniq -c | sort -nr | head -<top * 3>
```

Use `top * 3` (e.g., 60 for top-20) to get extra results that survive generated-file filtering.

If `--focus` is set, insert `| grep "^\s*[0-9]* <focus>"` after `sort -nr` and before `head`.

### 2b: Contributor Distribution

All-time contributor ranking. Note: `git shortlog` reads stdin when stdout is not a TTY (i.e., when redirected to a file), which produces empty output. Use `git log` with format and manual counting instead:

```bash
git -C <repo_path> log --format='%aN' | sort | uniq -c | sort -rn
```

### 2c: Bug-Associated Files

Files touched in commits whose messages contain fix/bug/broken:

```bash
git -C <repo_path> log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -<top * 3>
```

If `--focus` is set, apply the same grep filter as 2a.

### 2d: Commit Cadence

Monthly commit counts over the full history:

```bash
git -C <repo_path> log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
```

### 2e: Crisis Events

Reverts, hotfixes, emergencies, and rollbacks in the time window:

```bash
git -C <repo_path> log --oneline --since="<since>" | grep -iE 'revert|hotfix|emergency|rollback'
```

Note: this command returns exit code 1 if there are no matches. That is not an error — it means zero crisis events, which is a positive signal.

## Step 3: Collect Supplementary Data

After the five primary commands return, run these supplementary queries in **parallel**:

### 3a: Recent Active Contributors

Identify who has been active recently (last 6 months) to distinguish active team from historical contributors:

```bash
git -C <repo_path> log --since="6 months ago" --format='%aN' | sort | uniq -c | sort -rn
```

### 3b: Ownership of Top Churn Files

For the top 5 hand-written churn hotspots (after filtering generated files in your analysis), check who has been modifying them. Run this as a single command for each file:

```bash
git -C <repo_path> log --since="<since>" --format='%an' -- <file_path> | sort | uniq -c | sort -nr | head -5
```

You can batch these into a single Bash call using a for loop or run them in parallel.

## Step 4: Enrich and Analyze

This is the interpretive step — do not just reformat the raw data. Derive these secondary signals:

### Generated File Detection

Classify files as **generated** or **hand-written** using these heuristics:

- Path contains `/gen/`, `/generated/`, or `/proto/gen/` → generated
- File is named `*.swagger.yaml`, `*.swagger.json` → generated
- File is named `*.pb.go`, `*.pb.validate.go`, `*_pb.ts`, `*_pb2.py` → generated (protobuf)
- File is named `index.schemas.ts` or `openapi.yaml` in a `gen/` or `client/gen/` directory → generated
- File is a lock file: `go.sum`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock` → generated
- File is a module manifest that changes with dependencies: `go.mod` → semi-generated (note but don't fully exclude)

Remove generated files from the churn and bug rankings. Present filtered (hand-written only) lists as the primary analysis, with a footnote listing the generated files that were excluded and their counts.

### Churn-Bug Overlap (Risk Map)

Cross-reference the filtered churn list and filtered bug list. Files appearing in **both** are the highest-risk code. Rank by combined score (churn rank + bug rank, lower is riskier).

### Active vs. Historical Contributors

Compare the all-time contributor list (2b) with the recent-active list (3a). For each contributor, determine:
- **Active**: appeared in both lists
- **Historical**: appeared in all-time but not recent

Calculate the bus factor: what percentage of recent commits come from the top 1, top 3, and top 5 contributors?

### Velocity Inflection Points

Scan the monthly commit counts (2d) for:
- Months where count changed by >30% from the prior month
- Sustained trends: 3+ consecutive months of growth or decline
- Notable spikes or drops

### Crisis Density

Calculate: `(number of crisis events) / (total commits in window) * 100` to get a crisis percentage. Compare to rough benchmarks:
- < 1%: healthy
- 1-3%: normal for active projects
- > 3%: worth investigating deploy/test processes

## Step 5: Produce the Report

Write the report in Markdown. If `--output` is set, write to that file path. Otherwise, print inline.

Use this structure:

---

```
# Git X-Ray: <repo_name>

**Analyzed:** <today's date> | **Window:** <since value> | **Commits in window:** <N>
```

### Section 1: Risk Map

This is the most important section — the "start reading here" list.

List every hand-written file that appears in **both** the churn top-N and bug-fix top-N. For each file:
- File path
- Churn count (rank in churn list)
- Bug-fix count (rank in bug list)
- Primary author(s) from the ownership query
- Whether the primary author is still active

If no files overlap both lists, say so — that's a positive signal.

### Section 2: Churn Hotspots

Top N hand-written files by modification frequency. For each:
- File path and change count
- Whether it also appears in the bug cluster (cross-reference marker)
- Brief note on what kind of file it is if recognizable from the path (e.g., "database layer", "API handler", "UI component")

### Section 3: Bug Clusters

Top N hand-written files by bug-fix commit count. For each:
- File path and bug-fix count
- Whether it's also high-churn (chronic problem) or low-churn (concentrated fix)

### Section 4: Team & Ownership

- Top 10 all-time contributors with commit counts
- Active vs. historical status for each
- Bus factor metrics (top-1, top-3, top-5 concentration)
- Any single-owner risks on high-churn files

### Section 5: Velocity & Momentum

- Narrative description of the commit trend over time
- Call out inflection points with approximate dates
- Note any apparent seasonality or patterns (e.g., end-of-quarter spikes)

### Section 6: Stability

- Total crisis events in the window
- Crisis density percentage
- List each crisis event (one-line commit message)
- Pattern analysis: are reverts clustered in time? Do they target specific subsystems?

### Section 7: Suggested Reading Order

Based on the combined signals, recommend 5-10 files or directories that a newcomer should read first, with a one-line reason for each. Prioritize:
1. Risk map files (high churn + high bug)
2. High-churn hand-written files (most active code)
3. Entry points or core abstractions suggested by file paths

### Footnotes

- List of generated files excluded from analysis, with their raw counts
- Commands used (for reproducibility)

---

## Rules

- **Read-only**: Do not modify the target repository. No commits, no branch changes, no file edits in the target repo.
- **Parallel collection**: Run independent git commands in parallel to minimize wall-clock time.
- **Filter generated files**: Always separate generated/lock files from hand-written code. Generated files dominating the rankings is the most common failure mode — prevent it.
- **Interpret, don't just list**: Every section should contain narrative analysis, not just tables. The user can run the raw commands themselves — the value of this skill is the interpretation.
- **Evidence-based**: Do not speculate about causes (team changes, project shifts) without evidence from the commit data. Use hedging language ("this may indicate", "consistent with") for inferences.
- **Crisis command exit code**: `grep` returns exit code 1 when no lines match. This is not an error — it means zero crisis events. Handle this gracefully.
- **Respect --focus**: When set, file-level analysis (churn, bugs, risk map, ownership) scopes to the prefix. Contributor, velocity, and crisis analysis remain repo-wide.
- **Large output handling**: For repos with very long contributor lists or commit histories, truncate sensibly. Show top contributors, summarize the tail. For velocity, show the full monthly data but focus narrative on the analysis window.
