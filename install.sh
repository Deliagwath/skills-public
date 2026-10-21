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

    for f in "$dir"*/SKILL.md; do
        [ -f "$f" ] || continue
        if _has_skill_frontmatter "$f"; then
            valid=$((valid + 1))
        else
            missing=$((missing + 1))
            missing_files="$missing_files
    - $(basename "$(dirname "$f")")/SKILL.md"
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

    for f in "$dir"*/SKILL.md; do
        [ -f "$f" ] || continue
        skill_name="$(basename "$(dirname "$f")")"
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

    for f in "$dir"*/SKILL.md; do
        [ -f "$f" ] || continue
        skill_name="$(basename "$(dirname "$f")")"
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
# DSH accepts both <name>/SKILL.md bundles and flat <name>.md files. We link
# each skill's bundle folder from this repo, so an edit here is live in DSH with
# no reinstall. The bundle directory is also what DSH reports as `resourceBase`,
# so a skill that grows sibling files can resolve them relatively.
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

    for f in "$dir"*/SKILL.md; do
        [ -f "$f" ] || continue
        skill_name="$(basename "$(dirname "$f")")"
        skill_slug="${namespace}-${skill_name}"
        target_dir="$skills_dir/$skill_slug"
        # Link the folder, so DSH reads the repo as it stands (DSH follows a
        # directory link in a skill root). A copy left by an older install is
        # replaced.
        [ -L "$target_dir" ] || rm -rf "$target_dir"
        ln -sfn "$(dirname "$f")" "$target_dir"
        count=$((count + 1))
    done

    _ok "DSH          [$namespace]: $count skills → $skills_dir/ (as $namespace-<skill>/ → repo folder)"
}

# --- Shipped scripts ---
# A namespace may carry a scripts/ folder (e.g. facilitated-waterfall/scripts/nav).
# Claude Code and Cursor link only SKILL.md, and OpenCode and Mirai copy it, so a
# skill can't find its scripts relative to itself. Instead every skill names one
# fixed path, linked here to the repo:
#   ~/.agent-skills/<namespace>/scripts/          the namespace's shared scripts (sp)
#   ~/.agent-skills/<namespace>/<skill>/scripts/  one skill's own (conventions/check-graph.py)

_link_dir() {
    local src="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    [ -L "$target" ] || rm -rf "$target"
    ln -sfn "$src" "$target"
}

_link_scripts() {
    local dir="${1%/}"
    local namespace="$2"
    local root="$HOME/.agent-skills/$namespace"
    local skills=() skill s

    if [ -d "$dir/scripts" ]; then
        _link_dir "$dir/scripts" "$root/scripts"
        _ok "Scripts      [$namespace]: ~/.agent-skills/$namespace/scripts/ → repo folder"
    fi
    for s in "$dir"/*/scripts; do
        [ -d "$s" ] && [ -f "$(dirname "$s")/SKILL.md" ] || continue
        skill="$(basename "$(dirname "$s")")"
        _link_dir "$s" "$root/$skill/scripts"
        skills+=("$skill")
    done
    [ ${#skills[@]} -eq 0 ] ||
        _ok "Scripts      [$namespace]: ~/.agent-skills/$namespace/<skill>/scripts/ for ${skills[*]}"
}

# --- Dependencies: Universal Ctags for nav ---
# nav works without it (grep fallback), so this asks and never insists. Apple's
# BSD /usr/bin/ctags can shadow a Homebrew install on PATH; nav finds the
# Universal binary itself, but other tools may not.

_is_uctags() { [ -x "$1" ] && "$1" --version 2>/dev/null | grep -q 'Universal Ctags'; }

_find_uctags() {
    local d n
    local IFS=:
    for d in $PATH /opt/homebrew/bin /usr/local/bin /home/linuxbrew/.linuxbrew/bin; do
        for n in ctags uctags universal-ctags; do
            _is_uctags "$d/$n" && { echo "$d/$n"; return 0; }
        done
    done
    return 1
}

_ctags_install_cmd() {
    if command -v brew &>/dev/null; then echo "brew install universal-ctags"
    elif command -v apt-get &>/dev/null; then echo "sudo apt-get install -y universal-ctags"
    elif command -v dnf &>/dev/null; then echo "sudo dnf install -y ctags"
    elif command -v pacman &>/dev/null; then echo "sudo pacman -S --needed ctags"
    fi
}

_ensure_uctags() {
    local found cmd reply
    if ! found="$(_find_uctags)"; then
        cmd="$(_ctags_install_cmd)"
        if [ -z "$cmd" ]; then
            _warn "Universal Ctags not found, and no known package manager (brew, apt, dnf, pacman)."
            echo "       nav will use its grep fallback. Install universal-ctags by hand for full strength."
            return 0
        fi
        if [ ! -t 0 ]; then
            _warn "Universal Ctags not found. nav will use its grep fallback."
            echo "       For full strength, run: $cmd"
            return 0
        fi
        printf '  ? nav works best with Universal Ctags. Run "%s" now? [y/N] ' "$cmd"
        read -r reply || reply=
        case "$reply" in
            y|Y|yes|YES) $cmd || { _warn "Install failed. nav will use its grep fallback."; return 0; } ;;
            *) _info "Skipped. nav will use its grep fallback."; return 0 ;;
        esac
        if ! found="$(_find_uctags)"; then
            _warn "Installed, but no ctags reporting Universal was found. nav will use its grep fallback."
            return 0
        fi
    fi
    _ok "Universal Ctags: $found"
    local first
    first="$(command -v ctags 2>/dev/null || true)"
    if [ -n "$first" ] && [ "$first" != "$found" ] && ! _is_uctags "$first"; then
        _warn "$first (not Universal) comes first on PATH. nav finds $found anyway;"
        echo "       for other tools, put $(dirname "$found") before $(dirname "$first") in PATH."
    fi
}

# --- Dependencies: mdq and yq for sp (Direction 004) ---
# Both optional: sp reads doc sections with mdq and checks frontmatter with
# mikefarah's yq, and falls back to awk without them, saying so in its header.
# Only mikefarah's yq counts: the Python yq that apt ships takes other arguments.

_is_mdq() { command -v mdq &>/dev/null && mdq --version &>/dev/null; }
_is_yq() { command -v yq &>/dev/null && yq --version 2>/dev/null | grep -q 'mikefarah'; }

_tool_install_cmd() { # _tool_install_cmd mdq|yq
    if command -v brew &>/dev/null; then echo "brew install $1"
    elif [ "$1" = yq ] && command -v snap &>/dev/null; then echo "sudo snap install yq"
    elif [ "$1" = mdq ] && command -v cargo &>/dev/null; then echo "cargo install --locked mdq"
    fi
}

_ensure_tool() { # _ensure_tool mdq|yq "<what sp uses it for>"
    local tool="$1" why="$2" cmd reply
    if "_is_$tool"; then _ok "$tool: $(command -v "$tool")"; return 0; fi
    cmd="$(_tool_install_cmd "$tool")"
    if [ -z "$cmd" ]; then
        _warn "$tool not found, and no known way to install it here. sp will use awk for $why."
        return 0
    fi
    if [ ! -t 0 ]; then
        _warn "$tool not found. sp will use awk for $why."
        echo "       For full strength, run: $cmd"
        return 0
    fi
    printf '  ? sp uses %s for %s. Run "%s" now? [y/N] ' "$tool" "$why" "$cmd"
    read -r reply || reply=
    case "$reply" in
        y|Y|yes|YES) $cmd || { _warn "Install failed. sp will use awk for $why."; return 0; } ;;
        *) _info "Skipped. sp will use awk for $why."; return 0 ;;
    esac
    if "_is_$tool"; then _ok "$tool: $(command -v "$tool")"
    else _warn "Installed, but no working $tool was found on PATH. sp will use awk for $why."
    fi
}

# --- Budget declaration for nav ---
# nav sizes what a session inherits against AGENT_CONTEXT_TOKENS, the client's raw
# context window. The window is per client, so this only reports; it never writes
# a client's config. Unset, nav reports sizes but never trims or flags the handbook.

_hint_budget() {
    if [ "$_has_claude" = "1" ] && ! grep -q '"AGENT_CONTEXT_TOKENS"' "$HOME/.claude/settings.json" 2>/dev/null; then
        _warn "Claude Code declares no AGENT_CONTEXT_TOKENS. nav's budget lines will read 'unset'."
        echo "       Add \"env\": {\"AGENT_CONTEXT_TOKENS\": \"<window>\"} to ~/.claude/settings.json."
    fi
    if [ -z "${AGENT_CONTEXT_TOKENS:-}" ]; then
        _info "Other clients (DSH, OpenCode, Mirai): set AGENT_CONTEXT_TOKENS to the model's window in their environment."
    fi
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

# Explicit targets (e.g. `./install.sh claude opencode dsh`) replace detection:
# only the named clients are installed, whether or not they were detected.
if [ "$#" -gt 0 ]; then
    _has_claude=0; _has_cursor=0; _has_opencode=0; _has_mirai=0; _has_dsh=0
    for t in "$@"; do
        case "$t" in
            claude)   _has_claude=1 ;;
            cursor)   _has_cursor=1 ;;
            opencode) _has_opencode=1 ;;
            mirai)    _has_mirai=1 ;;
            dsh)      _has_dsh=1 ;;
            *) _warn "Unknown target '$t' (expected: claude cursor opencode mirai dsh)"; exit 1 ;;
        esac
    done
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
    # Only directories holding <skill>/SKILL.md folders are namespaces (skips docs/ etc.)
    compgen -G "$dir*/SKILL.md" >/dev/null || continue

    _link_scripts "$dir" "$namespace"

    # Claude Code + VS Code extension: ~/.claude/commands/<namespace>/<skill>.md → /namespace:skill
    if [ "$_has_claude" = "1" ]; then
        target="$HOME/.claude/commands/$namespace"
        mkdir -p "$target"
        count=0
        for f in "$dir"*/SKILL.md; do
            [ -f "$f" ] || continue
            ln -sf "$f" "$target/$(basename "$(dirname "$f")").md"
            count=$((count + 1))
        done
        _ok "Claude Code / VS Code [$namespace]: $count skills → ~/.claude/commands/$namespace/"
    fi

    # Cursor: ~/.cursor/commands/<namespace>-<skill>.md → /<namespace>-<skill>
    if [ "$_has_cursor" = "1" ]; then
        target="$HOME/.cursor/commands"
        mkdir -p "$target"
        count=0
        for f in "$dir"*/SKILL.md; do
            [ -f "$f" ] || continue
            ln -sf "$f" "$target/${namespace}-$(basename "$(dirname "$f")").md"
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

    # DSH: link each skill folder as $DSH_HOME/skills/<namespace>-<skill>/
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

# --- Dependencies ---
if [ -d "$HOME/.agent-skills/facilitated-waterfall/scripts" ]; then
    _ensure_uctags
    _ensure_tool mdq "doc sections"
    _ensure_tool yq "frontmatter checks"
    _hint_budget
fi

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
