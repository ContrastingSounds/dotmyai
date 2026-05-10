#!/usr/bin/env bash
# Symlinks ~/.claude/{commands,skills,CLAUDE.md} to the git-tracked dotclaude/ dir.
# Safe to re-run: idempotent. Merges any files unique to ~/.claude into dotclaude/
# first so nothing is lost (git tracks the merged result).
set -euo pipefail

MYAI_DIR="$HOME/.myai"
CLAUDE_DIR="$HOME/.claude"
DOTCLAUDE_DIR="$MYAI_DIR/dotclaude"

# Copy files from target into src that don't already exist in src (union merge).
merge_dir() {
    local src="$1"
    local target="$2"

    if [ ! -d "$target" ] || [ -L "$target" ]; then
        return
    fi

    for file in "$target"/*; do
        [ -e "$file" ] || continue
        local basename
        basename=$(basename "$file")
        if [ ! -e "$src/$basename" ]; then
            echo "MERGE:  $file -> $src/$basename"
            cp -a "$file" "$src/$basename"
        fi
    done
}

# Idempotent symlink: skip if correct, replace if stale or a regular file/dir.
link() {
    local src="$1"
    local target="$2"

    if [ ! -e "$src" ]; then
        echo "SKIP:   source does not exist: $src"
        return
    fi

    if [ -L "$target" ]; then
        local current
        current=$(readlink "$target")
        if [ "$current" = "$src" ]; then
            echo "OK:     $target -> $src"
            return
        fi
        rm "$target"
    elif [ -e "$target" ]; then
        rm -rf "$target"
    fi

    ln -s "$src" "$target"
    echo "LINK:   $target -> $src"
}

echo "Installing dotclaude symlinks..."
echo ""

mkdir -p "$CLAUDE_DIR"
mkdir -p "$DOTCLAUDE_DIR"

# Merge any files from ~/.claude into dotclaude that don't already exist,
# so the result is the union of both. The repo tracks the merged state.
merge_dir "$DOTCLAUDE_DIR/commands" "$CLAUDE_DIR/commands"
merge_dir "$DOTCLAUDE_DIR/skills"   "$CLAUDE_DIR/skills"

# Replace with symlinks
link "$DOTCLAUDE_DIR/commands"  "$CLAUDE_DIR/commands"
link "$DOTCLAUDE_DIR/skills"    "$CLAUDE_DIR/skills"
link "$DOTCLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

echo ""
echo "Done. Run 'git status' in $MYAI_DIR to see any newly merged files."
