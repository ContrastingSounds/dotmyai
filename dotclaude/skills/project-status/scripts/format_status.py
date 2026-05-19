#!/usr/bin/env python3
"""Format Linear issues JSON into grouped markdown tables.

Reads a JSON array of Linear issues from stdin (as returned by the
Linear MCP list_issues tool). Outputs markdown tables grouped by
status, sorted by priority, with dependency annotations.

Usage:
    cat issues.json | python3 format_status.py
    python3 format_status.py < issues.json
    python3 format_status.py --section recently-closed < issues.json
    python3 format_status.py --section open < issues.json
"""

import json
import sys
from collections import defaultdict

PRIORITY_ORDER = {
    "Urgent": 0,
    "High": 1,
    "Medium": 2,
    "Low": 3,
    "No priority": 4,
}

STATUS_ORDER = ["In Progress", "Todo", "Backlog"]
CLOSED_STATUSES = {"Done", "Cancelled"}

HIGHLIGHT_PRIORITIES = {"Urgent", "High"}


def extract_id_number(identifier: str) -> int:
    parts = identifier.split("-")
    if len(parts) == 2 and parts[1].isdigit():
        return int(parts[1])
    return 0


def sort_key(issue: dict) -> tuple:
    priority_name = issue.get("priority", {}).get("name", "No priority")
    priority_rank = PRIORITY_ORDER.get(priority_name, 99)
    id_num = extract_id_number(issue.get("id", ""))
    return (priority_rank, id_num)


def format_table(issues: list[dict], all_issues_by_id: dict) -> str:
    if not issues:
        return "_None_\n"

    sorted_issues = sorted(issues, key=sort_key)
    lines = [
        "| ID | Priority | Project | Parent | Title |",
        "|---|---|---|---|---|",
    ]

    for issue in sorted_issues:
        issue_id = issue.get("id", "?")
        priority = issue.get("priority", {}).get("name", "?")
        project = issue.get("project", "?")
        parent_id = issue.get("parentId", "")
        title = issue.get("title", "?")

        if len(title) > 80:
            title = title[:77] + "..."

        if priority in HIGHLIGHT_PRIORITIES:
            priority = f"**{priority}**"
            issue_id = f"**{issue_id}**"

        parent_col = ""
        if parent_id:
            parent_status = ""
            if parent_id in all_issues_by_id:
                parent = all_issues_by_id[parent_id]
                parent_status_name = parent.get("status", "")
                if parent_status_name == "Done":
                    parent_status = " (done)"
                elif parent_status_name in ("In Progress", "Todo", "Backlog"):
                    parent_status = f" ({parent_status_name.lower()})"
            parent_col = f"{parent_id}{parent_status}"

        lines.append(f"| {issue_id} | {priority} | {project} | {parent_col} | {title} |")

    return "\n".join(lines) + "\n"


def detect_unblocked(backlog_issues: list[dict], done_ids: set) -> list[dict]:
    unblocked = []
    for issue in backlog_issues:
        parent_id = issue.get("parentId", "")
        if parent_id and parent_id in done_ids:
            unblocked.append(issue)
    return unblocked


def main():
    section_filter = None
    if "--section" in sys.argv:
        idx = sys.argv.index("--section")
        if idx + 1 < len(sys.argv):
            section_filter = sys.argv[idx + 1]

    raw = sys.stdin.read().strip()
    if not raw:
        print("_No issues provided._")
        return

    issues = json.loads(raw)
    if not isinstance(issues, list):
        print("_Expected a JSON array of issues._", file=sys.stderr)
        sys.exit(1)

    all_issues_by_id = {i.get("id", ""): i for i in issues}
    done_ids = {i.get("id", "") for i in issues if i.get("status") in CLOSED_STATUSES}

    grouped = defaultdict(list)
    for issue in issues:
        status = issue.get("status", "Unknown")
        grouped[status].append(issue)

    if section_filter == "recently-closed":
        done_issues = grouped.get("Done", [])
        cancelled_issues = grouped.get("Cancelled", [])
        if done_issues:
            print(f"### Recently Completed ({len(done_issues)} issues)\n")
            print(format_table(done_issues, all_issues_by_id))
        if cancelled_issues:
            print(f"### Recently Cancelled ({len(cancelled_issues)} issues)\n")
            print(format_table(cancelled_issues, all_issues_by_id))
        if not done_issues and not cancelled_issues:
            print("_No recently closed issues._\n")
        return

    if section_filter == "open":
        print("### Open Work\n")
        total = 0
        for status in STATUS_ORDER:
            status_issues = grouped.get(status, [])
            if not status_issues:
                continue
            total += len(status_issues)
            print(f"#### {status} ({len(status_issues)})\n")
            print(format_table(status_issues, all_issues_by_id))

        unblocked = detect_unblocked(
            grouped.get("Backlog", []) + grouped.get("Todo", []),
            done_ids,
        )
        if unblocked:
            print(f"#### Newly Unblocked ({len(unblocked)})\n")
            print("Issues whose parent was recently completed:\n")
            print(format_table(unblocked, all_issues_by_id))

        if total == 0:
            print("_No open issues._\n")
        return

    # Default: print all sections
    done_issues = grouped.get("Done", [])
    cancelled_issues = grouped.get("Cancelled", [])
    if done_issues:
        print(f"### Recently Completed ({len(done_issues)} issues)\n")
        print(format_table(done_issues, all_issues_by_id))
    if cancelled_issues:
        print(f"### Recently Cancelled ({len(cancelled_issues)} issues)\n")
        print(format_table(cancelled_issues, all_issues_by_id))

    has_open = False
    for status in STATUS_ORDER:
        status_issues = grouped.get(status, [])
        if not status_issues:
            continue
        has_open = True
        print(f"### {status} ({len(status_issues)})\n")
        print(format_table(status_issues, all_issues_by_id))

    if not has_open and not done_issues and not cancelled_issues:
        print("_No issues found._\n")

    unblocked = detect_unblocked(
        grouped.get("Backlog", []) + grouped.get("Todo", []),
        done_ids,
    )
    if unblocked:
        print(f"### Newly Unblocked ({len(unblocked)})\n")
        print("Issues whose parent was recently completed:\n")
        print(format_table(unblocked, all_issues_by_id))


if __name__ == "__main__":
    main()
