#!/usr/bin/env bash
set -euo pipefail

cmd_preflight() {
    local toplevel
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "ERROR=not a git repository"
        return 1
    }

    local git_dir git_common
    git_dir=$(git rev-parse --git-dir)
    git_common=$(git rev-parse --git-common-dir)

    if [ "$git_dir" != "$git_common" ]; then
        echo "ERROR=already inside a worktree"
        return 1
    fi

    git fetch origin --quiet 2>/dev/null || true

    echo "REPO=$(basename "$toplevel")"
    echo "STATUS=ok"
}

cmd_resolve() {
    local input="$1"

    # Pure digits -> GitHub PR
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        local pr_data
        pr_data=$(gh pr view "$input" --json headRefName,state,title --jq '[.headRefName, .state, .title] | @tsv' 2>/dev/null) || {
            echo "TYPE=pr"
            echo "ERROR=no PR #$input found"
            return 1
        }
        IFS=$'\t' read -r branch state title <<< "$pr_data"
        echo "TYPE=pr"
        echo "BRANCH=$branch"
        echo "PR_STATE=$state"
        echo "PR_TITLE=$title"
        return 0
    fi

    # Letters-digits -> Linear issue ID
    if [[ "$input" =~ ^[A-Za-z]+-[0-9]+$ ]]; then
        local issue_id
        issue_id=$(echo "$input" | tr '[:upper:]' '[:lower:]')
        local matches
        matches=$(git ls-remote --heads origin | grep -i "refs/heads/${issue_id}-" | sed 's|.*refs/heads/||' || true)

        echo "TYPE=issue"
        echo "ISSUE_ID=$issue_id"

        if [ -z "$matches" ]; then
            return 0
        fi

        local count
        count=$(echo "$matches" | wc -l | tr -d ' ')

        if [ "$count" -eq 1 ]; then
            echo "BRANCH=$matches"
        else
            echo "BRANCHES=$(echo "$matches" | tr '\n' '|' | sed 's/|$//')"
            echo "MULTIPLE=true"
        fi
        return 0
    fi

    # Ambiguous -> try git branch first (fast)
    local remote_match
    remote_match=$(git ls-remote --heads origin "$input" | sed 's|.*refs/heads/||' || true)

    if [ -n "$remote_match" ]; then
        echo "TYPE=branch"
        echo "BRANCH=$remote_match"
        return 0
    fi

    # No git match -> skill will try Linear
    echo "TYPE=unknown"
    echo "INPUT=$input"
}

cmd_create_worktree() {
    local branch="$1"
    local dir_suffix="$2"
    local mode="${3:---new}"

    local repo
    repo=$(basename "$(git rev-parse --show-toplevel)")
    local worktree_dir="../${repo}-${dir_suffix}"

    # Check if a worktree already exists for this branch
    local existing
    existing=$(git worktree list --porcelain | awk -v b="refs/heads/$branch" '
        /^worktree / { path = substr($0, 10) }
        $0 == "branch " b { print path }
    ')

    if [ -n "$existing" ]; then
        echo "WORKTREE_PATH=$existing"
        echo "STATUS=exists"
        return 0
    fi

    if [ -d "$worktree_dir" ]; then
        echo "ERROR=directory $worktree_dir already exists but is not a registered worktree for branch $branch"
        return 1
    fi

    if [ "$mode" = "--track" ]; then
        if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
            git worktree add "$worktree_dir" "$branch"
        else
            git worktree add "$worktree_dir" -b "$branch" "origin/$branch"
        fi
    else
        # Ensure staging exists
        if ! git ls-remote --heads origin staging 2>/dev/null | grep -q staging; then
            local default_branch
            default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")
            git branch staging "origin/$default_branch" 2>/dev/null || true
            git push -u origin staging
        fi
        git worktree add "$worktree_dir" -b "$branch" origin/staging
    fi

    local abs_path
    abs_path=$(cd "$worktree_dir" && pwd)
    echo "WORKTREE_PATH=$abs_path"
    echo "STATUS=created"
}

case "${1:-help}" in
    preflight)       cmd_preflight ;;
    resolve)         cmd_resolve "${2:?Usage: checkout-work.sh resolve <input>}" ;;
    create-worktree) cmd_create_worktree "${2:?branch}" "${3:?dir-suffix}" "${4:---new}" ;;
    *)
        echo "Usage: checkout-work.sh <preflight|resolve|create-worktree> [args]"
        exit 1
        ;;
esac
