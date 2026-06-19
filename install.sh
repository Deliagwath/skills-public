#!/bin/bash
# Installs skills into all detected AI clients. Idempotent — safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_info()    { echo "  → $*"; }
_ok()      { echo "  ✓ $*"; }
_warn()    { echo "  ! $*"; }

# --- OpenCode skill validation ---
# OpenCode requires YAML frontmatter with 'name' and 'description' in each SKILL.md.
# Skills missing these fields are silently filtered out during loading.
#
# OpenCode loads skills from **/SKILL.md inside subdirectories:
#   ~/.config/opencode/skills/<skill-name>/SKILL.md
#   .opencode/skills/<skill-name>/SKILL.md
#   ~/.claude/skills/<skill-name>/SKILL.md
#   ~/.agents/skills/<skill-name>/SKILL.md
# The skills.paths config only works for directories containing subdirectories
# with SKILL.md files — NOT for flat directories of .md files.

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

_install_opencode_skills() {
    local dir="$1"
    local namespace="$2"
    local skills_dir="$HOME/.config/opencode/skills"
    local count=0

    mkdir -p "$skills_dir"

    for f in "$dir"*.md; do
        [ -f "$f" ] || continue
        skill_name="$(basename "$f" .md)"
        # Use namespace-skill prefix to avoid collisions
        skill_slug="${namespace}-${skill_name}"
        target_dir="$skills_dir/$skill_slug"
        mkdir -p "$target_dir"
        # Copy (not symlink) to ensure the file is self-contained
        cp -f "$f" "$target_dir/SKILL.md"
        count=$((count + 1))
    done

    _ok "OpenCode     [$namespace]: $count skills → $skills_dir/ (as $namespace-<skill>/SKILL.md)"
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
    || [ -d "$HOME/.config/opencode/skills" ] \
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

    # OpenCode: copy each skill as ~/.config/opencode/skills/<namespace>-<skill>/SKILL.md
    if [ "$_has_opencode" = "1" ]; then
        if ! _validate_opencode_skills "$dir" "$namespace"; then
            _warn "OpenCode [$namespace]: skipping install — fix the missing frontmatter above"
            continue
        fi
        _install_opencode_skills "$dir" "$namespace"
    fi
done

# --- Post-install cleanup ---
# Remove stale skills.paths entries that pointed to this repo (no longer needed
# since skills are now copied directly to ~/.config/opencode/skills/)
if [ "$_has_opencode" = "1" ] && [ -f "$_opencode_config" ] && command -v jq &>/dev/null; then
    real_config="$(realpath "$_opencode_config")"
    repo_prefix="$(dirname "$REPO_DIR")"
    updated="$(jq --arg prefix "$repo_prefix" '
        if .skills.paths then
            .skills.paths |= map(select(startswith($prefix) | not))
            | if (.skills.paths | length) == 0 then del(.skills.paths) else . end
        else . end
        | if (.skills | length) == 0 then del(.skills) else . end
    ' "$real_config")"
    if [ "$updated" != "$(cat "$real_config")" ]; then
        echo "$updated" > "$real_config"
        _info "Cleaned up stale skills.paths entries from config"
    fi
fi
