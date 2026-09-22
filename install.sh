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

# --- Mirai skill install ---
# Mirai discovers skills at ~/.mirai/skills/<skill-name>/SKILL.md (user-level).
# Each skill lives in its own directory containing a single SKILL.md. Files
# already carry YAML frontmatter (name + description), matching Mirai's format.

_install_mirai_skills() {
    local dir="$1"
    local namespace="$2"
    local skills_dir="$HOME/.mirai/skills"
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

    _ok "Mirai        [$namespace]: $count skills → $skills_dir/ (as $namespace-<skill>/SKILL.md)"
}

# --- DeepSeek Harness skill install ---
# DSH scans a fixed rank order of skill roots. Two are user-level:
#   rank 400  user-dsh     $DSH_HOME/skills   — per harness home
#   rank 500  user-agents  ~/.agents/skills   — shared by every harness home
# We write rank 400, so which agent a skill reaches is decided by the DSH_HOME
# the installer runs under rather than by every home on the box at once. A
# machine serving two harnesses (say a human-facing one and a headless one) can
# then give skills to the first without loading the second's model catalog.
#
# Home resolution mirrors DSH's own: $DSH_HOME, else ~/.dsh. Install into a
# non-default home by setting it for the run:
#   DSH_HOME=~/.dsh-harness ./install.sh
#
# DSH accepts both <name>/SKILL.md bundles and flat <name>.md files. We write
# bundles, matching the OpenCode and Mirai branches — a bundle directory is also
# what DSH reports as `resourceBase`, so a skill that grows sibling files later
# can resolve them relatively without moving.
#
# Skill names must be kebab-case and are global within a root, which is why the
# namespace prefix is applied here as it is everywhere else.

_dsh_home() { echo "${DSH_HOME:-$HOME/.dsh}"; }

_install_dsh_skills() {
    local dir="$1"
    local namespace="$2"
    local skills_dir
    skills_dir="$(_dsh_home)/skills"
    local count=0

    mkdir -p "$skills_dir"

    for f in "$dir"*.md; do
        [ -f "$f" ] || continue
        skill_name="$(basename "$f" .md)"
        skill_slug="${namespace}-${skill_name}"
        target_dir="$skills_dir/$skill_slug"
        mkdir -p "$target_dir"
        # Copy (not symlink) to ensure the file is self-contained
        cp -f "$f" "$target_dir/SKILL.md"
        count=$((count + 1))
    done

    _ok "DSH          [$namespace]: $count skills → $skills_dir/ (as $namespace-<skill>/SKILL.md)"
}

# --- Client detection ---

_has_claude=0   # Claude Code CLI + VS Code extension (shared ~/.claude/commands/)
_has_cursor=0
_has_opencode=0
_has_mirai=0
_has_dsh=0

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

# Mirai — user-level skills live at ~/.mirai/skills/<skill>/SKILL.md
if [ -d "$HOME/.mirai" ] \
    || [ -d "$HOME/.mirai/skills" ] \
    || [ -d "/Applications/Mirai.app" ] \
    || command -v mirai &>/dev/null; then
    _has_mirai=1
fi

# DeepSeek Harness — an explicit DSH_HOME is itself the request to install there,
# so it counts as detection even when that home has not been created yet.
if [ -n "${DSH_HOME:-}" ] \
    || [ -d "$(_dsh_home)" ] \
    || command -v dsh &>/dev/null; then
    _has_dsh=1
fi

if [ "$_has_claude" = "0" ] && [ "$_has_cursor" = "0" ] && [ "$_has_opencode" = "0" ] \
    && [ "$_has_mirai" = "0" ] && [ "$_has_dsh" = "0" ]; then
    _warn "No supported clients detected (Claude Code, VS Code, Cursor, OpenCode, Mirai, DSH) — nothing installed"
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

    # Mirai: copy each skill as ~/.mirai/skills/<namespace>-<skill>/SKILL.md
    # Reuses OpenCode's frontmatter validation (Mirai requires name + description too).
    if [ "$_has_mirai" = "1" ]; then
        if ! _validate_opencode_skills "$dir" "$namespace"; then
            _warn "Mirai [$namespace]: skipping install — fix the missing frontmatter above"
            continue
        fi
        _install_mirai_skills "$dir" "$namespace"
    fi

    # DSH: copy each skill as $DSH_HOME/skills/<namespace>-<skill>/SKILL.md
    # Reuses OpenCode's frontmatter validation — DSH's local provider requires
    # name + description too, and drops a skill that parses without them.
    if [ "$_has_dsh" = "1" ]; then
        if ! _validate_opencode_skills "$dir" "$namespace"; then
            _warn "DSH [$namespace]: skipping install — fix the missing frontmatter above"
            continue
        fi
        _install_dsh_skills "$dir" "$namespace"
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
