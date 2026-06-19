#!/bin/bash
# Installs skills into all detected AI clients. Idempotent — safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_info()    { echo "  → $*"; }
_ok()      { echo "  ✓ $*"; }
_warn()    { echo "  ! $*"; }

# --- OpenCode skill validation ---
# OpenCode requires YAML frontmatter with 'name' and 'description' in each .md skill file.
# Skills missing these fields are silently filtered out during loading.

_has_skill_frontmatter() {
    local file="$1"
    # Check for YAML frontmatter (--- on first line)
    if ! head -1 "$file" | grep -q '^---$'; then
        return 1
    fi
    # Check for 'name:' field in first 10 lines
    if ! head -10 "$file" | grep -q '^name:'; then
        return 1
    fi
    # Check for 'description:' field in first 10 lines
    if ! head -10 "$file" | grep -q '^description:'; then
        return 1
    fi
    return 0
}

_validate_opencode_skills() {
    local dir="$1"
    local namespace="$2"
    local missing=0
    local valid=0
    local missing_files=""

    for f in "$dir"*.md; do
        [ -f "$f" ] || continue
        if _has_skill_frontmatter "$f"; then
            valid=$((valid + 1))
        else
            missing=$((missing + 1))
            missing_files="$missing_files
    - $(basename "$f")"
        fi
    done

    if [ "$missing" -gt 0 ]; then
        _warn "OpenCode [$namespace]: $missing skill(s) missing YAML frontmatter (name + description)."
        echo "       These will be silently ignored by OpenCode. Fix them by adding:"
        echo "       ---"
        echo "       name: <skill-name>"
        echo "       description: What it does. Use when [triggers]."
        echo "       ---"
        echo "       Missing:"
        echo "$missing_files"
        return 1
    fi
    return 0
}

# --- Client detection ---

_has_claude=0   # Claude Code CLI + VS Code extension (shared ~/.claude/commands/)
_has_cursor=0
_has_opencode=0

# Claude Code / VS Code Claude extension — both use ~/.claude/commands/
command -v claude &>/dev/null || [ -d "$HOME/.claude" ] && _has_claude=1

if [ -d "$HOME/.cursor" ] \
    || [ -d "$HOME/.config/Cursor" ] \
    || [ -d "/Applications/Cursor.app" ] \
    || command -v cursor &>/dev/null; then
    _has_cursor=1
fi

_opencode_config="$HOME/.config/opencode/opencode.json"
if [ -f "$_opencode_config" ] \
    || [ -f "$HOME/.opencode/bin/opencode" ] \
    || command -v opencode &>/dev/null; then
    _has_opencode=1
fi

if [ "$_has_claude" = "0" ] && [ "$_has_cursor" = "0" ] && [ "$_has_opencode" = "0" ]; then
    _warn "No supported clients detected (Claude Code, VS Code, Cursor, OpenCode) — nothing installed"
    exit 0
fi

# --- Install ---

for dir in "$REPO_DIR"/*/; do
    [ -d "$dir" ] || continue
    namespace="$(basename "$dir")"

    # Claude Code + VS Code extension: ~/.claude/commands/<namespace>/<skill>.md → /namespace:skill
    if [ "$_has_claude" = "1" ]; then
        target="$HOME/.claude/commands/$namespace"
        mkdir -p "$target"
        count=0
        for f in "$dir"*.md; do
            [ -f "$f" ] || continue
            ln -sf "$f" "$target/$(basename "$f")"
            count=$((count + 1))
        done
        _ok "Claude Code / VS Code [$namespace]: $count skills → ~/.claude/commands/$namespace/"
    fi

    # Cursor: ~/.cursor/commands/<namespace>-<skill>.md → /<namespace>-<skill>
    if [ "$_has_cursor" = "1" ]; then
        target="$HOME/.cursor/commands"
        mkdir -p "$target"
        count=0
        for f in "$dir"*.md; do
            [ -f "$f" ] || continue
            ln -sf "$f" "$target/${namespace}-$(basename "$f")"
            count=$((count + 1))
        done
        _ok "Cursor       [$namespace]: $count skills → ~/.cursor/commands/ (prefix: ${namespace}-)"
    fi

    # OpenCode: validate and register each namespace directory in skills.paths
    if [ "$_has_opencode" = "1" ] && [ -f "$_opencode_config" ]; then
        # Validate skills have required frontmatter before registering
        if ! _validate_opencode_skills "$dir" "$namespace"; then
            _warn "OpenCode [$namespace]: skipping registration — fix the missing frontmatter above"
            continue
        fi

        if ! command -v jq &>/dev/null; then
            _warn "OpenCode: jq not found — skipping skills.paths registration (install jq and re-run)"
        else
            # Resolve symlink so we modify the real file, not the link target's parent
            real_config="$(realpath "$_opencode_config")"
            # Normalize path: remove trailing slash to avoid duplicate entries
            normalized_dir="${dir%/}"
            updated="$(jq --arg p "$normalized_dir" '
                .skills.paths = ((.skills.paths // []) + [$p] | unique)
            ' "$real_config")"
            echo "$updated" > "$real_config"
            _ok "OpenCode     [$namespace]: registered $normalized_dir in skills.paths"
        fi
    fi
done
