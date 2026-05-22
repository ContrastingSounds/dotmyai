#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") <repo-url> [options]

Clones a repo, rewrites commit authorship, and force-pushes.

Options:
  --old-name    NAME    Old author name to match (default: TheRillJon)
  --old-email   EMAIL   Old author email to match (default: jon.walls@rilldata.com)
  --new-name    NAME    New author name (default: ContrastingSounds)
  --new-email   EMAIL   New author email (default: jon@jonathanwalls.com)
  --dry-run             Show what would change without pushing
  --branch      BRANCH  Only rewrite a specific branch (default: all branches)
  -h, --help            Show this help

Examples:
  $(basename "$0") git@github.com-personal:jonwalls-dev/some-repo.git
  $(basename "$0") git@github.com-personal:jonwalls-dev/some-repo.git --dry-run
  $(basename "$0") https://github.com/jonwalls-dev/some-repo.git --old-email old@example.com --new-email new@example.com
EOF
  exit 1
}

[[ $# -lt 1 ]] && usage

REPO_URL="$1"
shift

OLD_NAME="TheRillJon"
OLD_EMAIL="jon.walls@rilldata.com"
NEW_NAME="ContrastingSounds"
NEW_EMAIL="jon@jonathanwalls.com"
DRY_RUN=false
BRANCH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --old-name)   OLD_NAME="$2";  shift 2 ;;
    --old-email)  OLD_EMAIL="$2"; shift 2 ;;
    --new-name)   NEW_NAME="$2";  shift 2 ;;
    --new-email)  NEW_EMAIL="$2"; shift 2 ;;
    --dry-run)    DRY_RUN=true;   shift ;;
    --branch)     BRANCH="$2";    shift 2 ;;
    -h|--help)    usage ;;
    *)            echo "Unknown option: $1"; usage ;;
  esac
done

REPO_NAME=$(basename "$REPO_URL" .git)
WORK_DIR=$(mktemp -d)/"$REPO_NAME"

echo "Cloning $REPO_URL into $WORK_DIR..."
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"

MATCH_COUNT=$(git log --all --format='%ae' | grep -c "^${OLD_EMAIL}$" || true)
if [[ "$MATCH_COUNT" -eq 0 ]]; then
  echo "No commits found with email '$OLD_EMAIL'. Nothing to do."
  rm -rf "$(dirname "$WORK_DIR")"
  exit 0
fi

echo "Found $MATCH_COUNT commit(s) authored by '$OLD_EMAIL'."

if $DRY_RUN; then
  echo ""
  echo "Commits that would be rewritten:"
  git log --all --format='%h %ae %s' | grep "$OLD_EMAIL"
  echo ""
  echo "Dry run — no changes made."
  rm -rf "$(dirname "$WORK_DIR")"
  exit 0
fi

FILTER_ARGS=(--force --commit-callback "
if commit.author_email == b'${OLD_EMAIL}':
    commit.author_name = b'${NEW_NAME}'
    commit.author_email = b'${NEW_EMAIL}'
if commit.committer_email == b'${OLD_EMAIL}':
    commit.committer_name = b'${NEW_NAME}'
    commit.committer_email = b'${NEW_EMAIL}'
")

if [[ -n "$BRANCH" ]]; then
  FILTER_ARGS+=(--refs "refs/heads/$BRANCH")
fi

echo "Rewriting commits..."
git filter-repo "${FILTER_ARGS[@]}"

git remote add origin "$REPO_URL"

if [[ -n "$BRANCH" ]]; then
  echo "Force-pushing branch '$BRANCH'..."
  git push --force origin "$BRANCH"
else
  echo "Force-pushing all branches..."
  git push --force origin --all
  git push --force origin --tags
fi

echo "Cleaning up..."
rm -rf "$(dirname "$WORK_DIR")"
echo "Done. $MATCH_COUNT commit(s) reauthored in $REPO_NAME."
