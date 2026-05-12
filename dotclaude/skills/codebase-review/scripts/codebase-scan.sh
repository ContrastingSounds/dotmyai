#!/usr/bin/env bash
# Automated health scan for codebase review.
# Run from repo root. Outputs scan data to stdout for skill consumption.
# Tolerant of missing tools — reports what's missing and keeps going.

set -uo pipefail

if ! git rev-parse --show-toplevel &>/dev/null; then
    echo "Error: not a git repository" >&2
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
DATE=$(date +%Y-%m-%d)
cd "$REPO_ROOT"

detect_languages() {
    local langs=""
    [[ -f go.mod ]] && langs="$langs go"
    [[ -f pyproject.toml || -f setup.py || -f requirements.txt ]] && langs="$langs python"
    [[ -f package.json ]] && langs="$langs node"
    echo "$langs"
}

LANGUAGES=$(detect_languages)
check_tool() { command -v "$1" &>/dev/null; }

echo "# Codebase Scan: $REPO_NAME"
echo "Date: $DATE"
echo "Root: \`$REPO_ROOT\`"
echo "Detected languages:$LANGUAGES"

# --- Ownership ---
echo ""
echo "## Repo Ownership"
REMOTE=$(git remote get-url origin 2>/dev/null || echo "no remote configured")
echo "Remote: \`$REMOTE\`"
if echo "$REMOTE" | grep -qiE '(ContrastingSounds|jonwalls-dev|TheRillJon)'; then
    echo ""
    echo "**Owner: You** — check Linear for project and PRD."
else
    echo ""
    echo "**Owner: Third party** — check README and docs/ for context."
fi

# --- Size and shape ---
echo ""
echo "## Size and Shape"
if check_tool scc; then
    echo '```'
    scc . --no-cocomo 2>/dev/null || echo "(scc failed)"
    echo '```'
else
    echo "_scc not installed — \`brew install scc\`_"
fi

# --- Git archaeology ---
echo ""
echo "## Git Archaeology"

echo ""
echo "### Churn Hotspots (12 months)"
echo '```'
git log --format=format: --name-only --since="12.month" \
    | grep -v '^$' | sort | uniq -c | sort -nr | head -20 \
    || echo "(no git history)"
echo '```'

echo ""
echo "### Commit Cadence"
echo '```'
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c \
    || echo "(no commits)"
echo '```'

echo ""
echo "### Recent Commits"
echo '```'
git log --oneline -20 || echo "(no commits)"
echo '```'

# --- Dependency health ---
echo ""
echo "## Dependency Health"
if [[ -z "$LANGUAGES" ]]; then
    echo "_No recognised language markers found (go.mod, pyproject.toml, package.json)._"
fi

for lang in $LANGUAGES; do
    case $lang in
        go)
            echo ""
            echo "### Go"
            echo "**Outdated modules:**"
            echo '```'
            OUTDATED=$(go list -m -u all 2>/dev/null | grep '\[' || true)
            if [[ -n "$OUTDATED" ]]; then
                echo "$OUTDATED"
            else
                echo "all modules up to date"
            fi
            echo '```'
            if check_tool govulncheck; then
                echo ""
                echo "**Vulnerabilities:**"
                echo '```'
                govulncheck ./... 2>/dev/null || echo "(govulncheck failed)"
                echo '```'
            fi
            ;;
        python)
            echo ""
            echo "### Python"
            if check_tool pip-audit; then
                echo '```'
                pip-audit 2>/dev/null || echo "(pip-audit failed)"
                echo '```'
            else
                echo "_pip-audit not installed — \`uv tool install pip-audit\`_"
            fi
            ;;
        node)
            echo ""
            echo "### Node"
            echo '```'
            npm audit --audit-level=moderate 2>/dev/null || echo "(npm audit failed)"
            echo '```'
            ;;
    esac
done

# --- Cross-ecosystem vuln scan ---
echo ""
echo "## Vulnerability Scan"
if check_tool trivy; then
    echo '```'
    trivy fs . --severity HIGH,CRITICAL --quiet 2>/dev/null || echo "(trivy failed)"
    echo '```'
elif check_tool grype; then
    echo '```'
    grype dir:. --only-fixed 2>/dev/null || echo "(grype failed)"
    echo '```'
else
    echo "_Neither trivy nor grype installed._"
fi

# --- Secret detection ---
echo ""
echo "## Secret Detection"
if check_tool gitleaks; then
    echo '```'
    if gitleaks detect --no-banner --no-color 2>&1; then
        echo "No leaks found."
    fi
    echo '```'
else
    echo "_gitleaks not installed — \`brew install gitleaks\`_"
fi
