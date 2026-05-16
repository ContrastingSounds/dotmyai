#!/bin/sh
# Claude Code status line — mirrors the zsh PROMPT style from ~/.zshrc
# Line 1: blue cwd + yellow git branch + red unstaged + green staged markers
# Plus: model name and context usage

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Git branch and status
git_branch=""
git_status_markers=""
if git_br=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_branch="$git_br"
  # Check for staged changes (green +)
  if ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    git_status_markers="${git_status_markers}\033[32m+\033[0m"
  fi
  # Check for unstaged changes (red *)
  if ! git -C "$cwd" diff --quiet 2>/dev/null; then
    git_status_markers="${git_status_markers}\033[31m*\033[0m"
  fi
fi

# Build the line
printf "\033[34m%s\033[0m" "$short_cwd"

if [ -n "$git_branch" ]; then
  printf " \033[33m%s\033[0m" "$git_branch"
  if [ -n "$git_status_markers" ]; then
    printf " %b" "$git_status_markers"
  fi
fi

if [ -n "$model" ]; then
  printf "  \033[90m%s\033[0m" "$model"
fi

if [ -n "$used_pct" ]; then
  pct_int=$(printf '%.0f' "$used_pct")
  if [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ]; then
    # used tokens rounded to nearest 1k; derived from pct so it matches the %
    used_k=$(( (ctx_size * pct_int + 50000) / 100000 ))
    total_k=$(( ctx_size / 1000 ))
    printf " \033[90m[ctx used: %s%% · %dk/%dk]\033[0m" "$pct_int" "$used_k" "$total_k"
  else
    printf " \033[90m[ctx used: %s%%]\033[0m" "$pct_int"
  fi
fi

printf "\n"
