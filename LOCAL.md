# LOCAL

## Env Vars

- Services
- Rill Internal Development
- Rill Demo Development

### Services

**~/.zshenv**
```shell
export OPENAI_API_KEY
export LINEAR_API_KEY
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

#### Convenience functions for creating worktrees

###### References
- Documented in ~/rill-worktree-setup.md
- symlink to $RILL_WORKTREES/RILL-README.md for easy access during dev work

###### ~/.zshrc functions 
- **prw()** — for existing pull request
- **frw()** — for existing branch
- **newb()** — new branch

## .dotfiles

Bare repo storing essential configuration files

- github.com/TheRillJon/dotfiles
