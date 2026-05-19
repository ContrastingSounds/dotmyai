# Git & Claude Code Sandbox

## SSH Does Not Work in the Sandbox

The Claude Code sandbox intercepts all outbound network traffic through local proxies. SSH-based git operations (`push`, `fetch`, `pull`, `ls-remote`) fail because the sandbox blocks every path SSH needs to authenticate:

1. **DNS** — raw DNS is blocked; resolution only works through the HTTP proxy
2. **`~/.ssh` directory** — filesystem deny rule prevents reading key files
3. **SSH agent socket** — sandbox blocks access to `SSH_AUTH_SOCK`

The sandbox injects these environment variables at session start:

```
GIT_SSH_COMMAND=ssh -o ProxyCommand='nc -X 5 -x localhost:<port> %h %p'
ALL_PROXY=socks5h://localhost:<port>
HTTP_PROXY=http://localhost:<port>
HTTPS_PROXY=http://localhost:<port>
```

The SOCKS proxy handles DNS for HTTP/HTTPS clients (via `socks5h://`), but SSH uses system DNS which is blocked. Even bypassing the proxy (`GIT_SSH_COMMAND=ssh`) doesn't help — DNS still fails, and key material is inaccessible.

### What Doesn't Work

| Approach | Result |
|---|---|
| `sandbox.excludedCommands` for git | Bypasses filesystem sandbox only, not network proxy |
| `allowUnsandboxedCommands: true` | Global escape hatch — any command can retry unsandboxed, not scoped to git |
| Unsetting `GIT_SSH_COMMAND` | DNS resolution still blocked |
| Overriding `HostName` in SSH | Connects but can't authenticate (no keys, no agent) |

### Solution: HTTPS via `insteadOf`

Rewrite SSH remote URLs to HTTPS at the git transport layer. HTTPS goes through the HTTP proxy, which handles DNS and is allowed by `network.allowedDomains`. Authentication is handled by `gh` as a credential helper.

```bash
# One-time setup (run outside the sandbox)

# Set gh as the git credential helper
gh auth setup-git

# Rewrite SSH URLs to HTTPS (add one per SSH host alias you use)
git config --global url."https://github.com/".insteadOf "git@github.com:"
git config --global url."https://github.com/".insteadOf "github.com-personal:"
```

Remotes still display as SSH in `git remote -v`, but git silently uses HTTPS. All sandbox protections remain in effect.

### To Revert

```bash
git config --global --unset-all url."https://github.com/".insteadOf
```

## SSH Host Aliases

This machine uses SSH host aliases in `~/.ssh/config` to manage multiple GitHub accounts:

- `github.com-personal` — maps to `github.com` with a specific identity file

Remote URLs use the alias (e.g., `github.com-personal:ContrastingSounds/repo.git`), which is why the `insteadOf` rule must match the alias, not just `git@github.com:`.
