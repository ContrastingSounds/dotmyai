# LOCAL

- Fav shell configs
- Essential env vars
- Rill Development
- Dotfiles for config version control

## zsh hell config

### general

```shell
# Bare git repo for selected dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

alias ll='eza -al'
alias ls='eza -al'
alias lsd='eza --only-dirs */'
alias lt='eza --tree'
alias fzf='fzf --preview "bat --color=always {}"'

# Essential repo locations
alias c='cd ~/GitHub/CustomerGitHub'      # Customer projects
alias k='cd ~/GitHub/KeyGitHub'           # Priority repos eg source code
alias r='cd ~/GitHub/RillGitHub'          # General internal rill repos
alias d='cd ~/GitHub/DemoGitHub'          # Demo code
alias p='cd ~/GitHub/PersonalGitHub'      # Personal repos

# CLI configuration
export CLICOLOR=1

# Load zsh colors
autoload -U colors && colors

# Load version control information
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' formats '%F{yellow} %b%f %F{red}%u%f%F{green}%c%f'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr ''
precmd() { vcs_info }

alias jupy='uv run --with jupyter jupyter notebook'
```

### rill convenience functions

```shell
# Rill
alias killrill='kill $(pgrep -f "rill start")'
alias rsdemo='rill start ~/DemoGitHub/rill-examples/rill-openrtb-prog-ads'

# ClickHouse
alias ch='/usr/local/bin/clickhouse client --prompt="CH"'

# DuckDB
get_schema()
get_sample()
```

## Env Vars

- Services
- Rill Internal Development
- Rill Demo Development

### Services

**~/.zshenv**
```shell
export OPENAI_API_KEY
export LINEAR_API_KEY
export LINEAR_API_KEY_PERSONAL
export CURSOR_API_KEY
export GEMINI_API_KEY
export GOOGLE_APPLICATION_CREDENTIALS
export SLACK_BOT_TOKEN
export STRAPI_API_TOKEN
```

### Rill Internal Development
**~/.zshrc**
```shell
export RILL_BARE_REPO="$HOME/GitHub/KeyGitHub/rill.git"
export RILL_WORKTREES="$HOME/GitHub/KeyGitHub/rill"
```

**~/.zshenv**
```shell
export PYRILL_TESTS_CI
```

### Rill Test/Demo Development
**~/.zshenv**
```shell
export RILL_ORG=rill-sandbox
export RILL_PROJECT=rill399-duckdb
export RILL_TEST_MONO_TOKEN
export RILL_TEST_MULTI_TOKEN
```

## Rill Development

###### Config references
- Documented in ~/rill-worktree-setup.md
- symlink to $RILL_WORKTREES/RILL-README.md for easy access during dev work

###### ~/.zshrc Git worktree helper

- **prw()** — Checkout a PR into a named worktree
```shell
prw 8664
```

- **frw()** — checkout a remote branch into a named worktree
```shell
frw feat-new-dashboard
```
- **frw()** — for existing branch

- **newb()** — create a new branch + worktree from latest main
```shell
newb feat-my-feature
```

###### ~/.zshrc DuckDB Convenience Functions
- **get_schema()** — get schema of a parquet file using DuckDB
- **get_sample()** — get a one row sample from a parquet file using DuckDB

## .dotfiles

Bare repo storing essential configuration files

- github.com/TheRillJon/dotfiles
