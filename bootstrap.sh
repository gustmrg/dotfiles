#!/usr/bin/env bash
#
# bootstrap.sh - Set up dotfiles in the home directory
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/gustmrg/dotfiles/main/bootstrap.sh | bash
#   or
#   ./bootstrap.sh
#
# Default install mode creates symlinks so configs stay in sync with this
# repository on every git pull. Use --copy for one-time imports on machines
# where the repository will not remain.
#
# ~/.zshrc is an exception: it is always a small local stub that sources
# shell/.zshrc from this repository, so installers may append to it without
# dirtying the repo.

set -euo pipefail

REPO_URL="https://github.com/gustmrg/dotfiles.git"
BOOTSTRAP_URL="https://raw.githubusercontent.com/gustmrg/dotfiles/main/bootstrap.sh"
SCRIPT_REPO_DIR=""

if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    if git -C "$script_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        SCRIPT_REPO_DIR="$script_dir"
    fi
fi

if [ -z "${DOTFILES_DIR:-}" ]; then
    DOTFILES_DIR="${SCRIPT_REPO_DIR:-$HOME/dotfiles}"
fi

BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
INSTALL_MODE="link"

# Output colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}ℹ️${NC} $1"; }
ok()    { echo -e "${GREEN}✅${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠️${NC} $1"; }
err()   { echo -e "${RED}❌${NC} $1"; }

usage() {
    cat <<USAGE
🚀 Usage: ./bootstrap.sh [options]

Options:
  🧱 --minimal        Install only core shell and git files; do not prompt
  📋 --copy           Copy files/directories instead of creating symlinks
  🔗 --link           Create symlinks instead of copying files/directories (default)
  🌈 --all            Install every general-purpose optional config; do not prompt
  🤖 --opencode       Install all OpenCode optional configs
  🧠 --claude         Install Claude Code settings
  🛠️  --skills         Install global agent skills in ~/.agents/skills
  🧪 --codex          Copy Codex skills into ~/.codex/skills
  👻 --ghostty        Install the Ghostty terminal config
  🔤 --fonts          Install Fira Code, IBM Plex Mono, and Source Code Pro
  ❓ --help           Show this help

When run interactively with no option, the script asks which optional configs
to install. Enter multiple numbers separated by commas/spaces, or "all".

Existing files, directories, or symlinks are backed up under:
  ~/.dotfiles-backup/<timestamp>/

~/.zshrc is always installed as a local stub that sources shell/.zshrc from
this repository (independent of --link/--copy), so installers can append to it
without dirtying the repo.

Default mode is link so configs stay in sync with this repository on every
git pull (run 'dotsync' from an interactive Zsh shell). Use --copy for a
one-time import when the repository will not remain on the machine; re-run
bootstrap to apply future updates in copy mode.
USAGE
}

has_arg() {
    local needle="$1"
    shift
    for arg in "$@"; do
        [ "$arg" = "$needle" ] && return 0
    done
    return 1
}

add_entry() {
    ENTRIES+=("$1:$2")
}

backup_path() {
    local target="$1"
    local rel backup_target backup_parent

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        return
    fi

    rel="${target#$HOME/}"
    if [ "$rel" = "$target" ]; then
        rel="absolute${target}"
    fi

    backup_target="$BACKUP_DIR/$rel"
    backup_parent=$(dirname "$backup_target")
    mkdir -p "$backup_parent"
    mv "$target" "$backup_target"
    ok "💾 $target -> backed up to $backup_target"
}

paths_match() {
    local src="$1"
    local dst="$2"

    # Copy mode must replace symlinks even when they resolve to the same data.
    if [ -L "$dst" ]; then
        return 1
    fi

    if [ -f "$src" ] && [ -f "$dst" ]; then
        cmp -s "$src" "$dst"
    elif [ -d "$src" ] && [ -d "$dst" ]; then
        diff -qr --exclude=node_modules "$src" "$dst" >/dev/null 2>&1
    else
        return 1
    fi
}

copy_codex_skills() {
    local src_dir="codex/skills"
    local dst_dir="$HOME/.codex/skills"
    local skill skill_name

    if [ ! -d "$src_dir" ]; then
        warn "Source $DOTFILES_DIR/$src_dir was not found in the repo; skipping Codex skills"
        return
    fi

    mkdir -p "$dst_dir"

    for skill in "$src_dir"/*; do
        [ -d "$skill" ] || continue
        skill_name=$(basename "$skill")

        if [ "$skill_name" = ".system" ]; then
            warn "Ignoring Codex system skill: $skill_name"
            continue
        fi

        if paths_match "$skill" "$dst_dir/$skill_name"; then
            ok "🧠 $dst_dir/$skill_name -> already up to date"
            continue
        fi

        backup_path "$dst_dir/$skill_name"
        cp -R "$skill" "$dst_dir/$skill_name"
        ok "🧠 $dst_dir/$skill_name -> skill copied"
    done
}

link_entry() {
    local entry="$1"
    local src="${entry%%:*}"
    local dst="${entry#*:}"
    local dst_dir current_target src_abs

    dst="${dst/#\~/$HOME}"
    dst_dir=$(dirname "$dst")
    mkdir -p "$dst_dir"

    if [ -L "$dst" ]; then
        current_target=$(readlink "$dst")
        src_abs="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
        if [ "$current_target" = "$src_abs" ]; then
            ok "🔗 $dst -> already points to the repo"
        else
            warn "$dst -> points somewhere else ($current_target); backing up and replacing"
            backup_path "$dst"
            ln -s "$src_abs" "$dst"
            ok "🔗 $dst -> symlink created"
        fi
    elif [ -f "$dst" ] || [ -d "$dst" ]; then
        warn "$dst -> file/directory already exists; backing up and replacing"
        if [ ! -e "$src" ]; then
            warn "Source $DOTFILES_DIR/$src was not found in the repo; skipping"
            return
        fi
        backup_path "$dst"
        src_abs="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
        ln -s "$src_abs" "$dst"
        ok "🔗 $dst -> symlink created"
    else
        if [ ! -e "$src" ]; then
            warn "Source $DOTFILES_DIR/$src was not found in the repo; skipping"
            return
        fi
        src_abs="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
        ln -s "$src_abs" "$dst"
        ok "🔗 $dst -> symlink created"
    fi
}

copy_entry() {
    local entry="$1"
    local src="${entry%%:*}"
    local dst="${entry#*:}"
    local dst_dir

    dst="${dst/#\~/$HOME}"
    dst_dir=$(dirname "$dst")
    mkdir -p "$dst_dir"

    if [ ! -e "$src" ]; then
        warn "Source $DOTFILES_DIR/$src was not found in the repo; skipping"
        return
    fi

    if paths_match "$src" "$dst"; then
        ok "✅ $dst -> already up to date"
        return
    fi

    backup_path "$dst"
    cp -R "$src" "$dst"
    ok "📋 $dst -> copied"
}

apply_entry() {
    local entry="$1"

    if [ "$INSTALL_MODE" = "copy" ]; then
        copy_entry "$entry"
    else
        link_entry "$entry"
    fi
}

ensure_zshrc_stub() {
    local zshrc="$HOME/.zshrc"
    local repo_zshrc="$DOTFILES_DIR/shell/.zshrc"
    local begin_marker="# >>> dotfiles zshrc >>>"
    local end_marker="# <<< dotfiles zshrc <<<"
    local stub tmp

    if [ ! -f "$repo_zshrc" ]; then
        warn "Source $repo_zshrc was not found in the repo; skipping zshrc stub"
        return
    fi

    stub="$begin_marker
# Managed by $DOTFILES_DIR/bootstrap.sh - local additions below are safe.
[ -f \"$repo_zshrc\" ] && source \"$repo_zshrc\"
$end_marker"

    if [ -L "$zshrc" ]; then
        warn "$zshrc -> symlink found; backing up and replacing with local stub"
        backup_path "$zshrc"
    fi

    if [ -f "$zshrc" ]; then
        if grep -Fq "$begin_marker" "$zshrc"; then
            ok "🐚 $zshrc -> already sources the repo zshrc"
        else
            tmp=$(mktemp)
            printf '%s\n\n' "$stub" | cat - "$zshrc" > "$tmp"
            cat "$tmp" > "$zshrc"
            rm -f "$tmp"
            ok "🐚 $zshrc -> repo zshrc source block added at the top"
        fi
    else
        printf '%s\n' "$stub" > "$zshrc"
        ok "🐚 $zshrc -> stub created"
    fi
}

ensure_gitconfig_include() {
    local gitconfig="$HOME/.gitconfig"
    local include_path="$HOME/.gitconfig.dotfiles"

    if [ -L "$gitconfig" ]; then
        warn "$gitconfig -> symlink found; backing up and replacing with local Git config"
        backup_path "$gitconfig"
    fi

    if [ ! -e "$gitconfig" ]; then
        cat > "$gitconfig" <<GITCONFIG
[include]
	path = $include_path
GITCONFIG
        ok "🔧 $gitconfig -> local Git config created"
        warn "Git identity is not configured by bootstrap; set user.name and user.email per machine"
        return
    fi

    if git config --global --get-all include.path | grep -Fxq "$include_path"; then
        ok "🔧 $gitconfig -> already includes $include_path"
    else
        git config --global --add include.path "$include_path"
        ok "🔧 $gitconfig -> added include.path $include_path"
    fi
}

select_optional_links() {
    local selection=""

    SELECT_OPENCODE=false
    SELECT_CLAUDE=false
    SELECT_SHARED_SKILLS=false
    SELECT_CODEX_SKILLS=false
    SELECT_GHOSTTY=false
    SELECT_FONTS=false

    # Fonts are deliberately never included in --all or the interactive
    # "all" selection. They require an explicit --fonts or menu selection.
    if has_arg "--fonts" "$@"; then SELECT_FONTS=true; fi

    if has_arg "--minimal" "$@"; then
        return
    fi

    if has_arg "--all" "$@"; then
        SELECT_OPENCODE=true
        SELECT_CLAUDE=true
        SELECT_SHARED_SKILLS=true
        SELECT_CODEX_SKILLS=true
        SELECT_GHOSTTY=true
        return
    fi

    if has_arg "--opencode" "$@"; then SELECT_OPENCODE=true; fi
    if has_arg "--claude" "$@"; then SELECT_CLAUDE=true; fi
    if has_arg "--skills" "$@"; then SELECT_SHARED_SKILLS=true; fi
    if has_arg "--codex" "$@"; then SELECT_CODEX_SKILLS=true; fi
    if has_arg "--ghostty" "$@"; then SELECT_GHOSTTY=true; fi

    if [ "$SELECT_OPENCODE" = true ] || [ "$SELECT_CLAUDE" = true ] || [ "$SELECT_SHARED_SKILLS" = true ] || [ "$SELECT_CODEX_SKILLS" = true ] || [ "$SELECT_GHOSTTY" = true ] || [ "$SELECT_FONTS" = true ]; then
        return
    fi

    if [ ! -t 0 ]; then
        warn "No interactive terminal detected; using core files only. Use --all or specific flags for optional configs."
        return
    fi

    echo ""
    info "✨ Which optional configs do you want to set up?"
    echo "  1) 🤖 OpenCode agents and settings"
    echo "  2) 🧠 Claude Code settings"
    echo "  3) 🛠️  Global agent skills (~/.agents/skills)"
    echo "  4) 🧪 Codex skills (~/.codex/skills, copied without symlinks)"
    echo "  5) 👻 Ghostty terminal config"
    echo "  6) 🔤 Fonts (Fira Code, IBM Plex Mono, Source Code Pro)"
    echo ""
    read -r -p "Choose numbers separated by commas/spaces, all, or Enter to skip: " selection

    selection="$(printf '%s' "$selection" | tr '[:upper:]' '[:lower:]' | tr ',' ' ')"
    for item in $selection; do
        case "$item" in
            all)
                SELECT_OPENCODE=true
                SELECT_CLAUDE=true
                SELECT_SHARED_SKILLS=true
                SELECT_CODEX_SKILLS=true
                SELECT_GHOSTTY=true
                ;;
            1|opencode) SELECT_OPENCODE=true ;;
            2|claude) SELECT_CLAUDE=true ;;
            3|skills) SELECT_SHARED_SKILLS=true ;;
            4|codex) SELECT_CODEX_SKILLS=true ;;
            5|ghostty) SELECT_GHOSTTY=true ;;
            6|fonts) SELECT_FONTS=true ;;
            "") ;;
            *) warn "Unknown option: $item" ;;
        esac
    done
}

for arg in "$@"; do
    case "$arg" in
        --minimal|--copy|--link|--all|--opencode|--claude|--skills|--codex|--ghostty|--fonts) ;;
        --help) usage; exit 0 ;;
        *) err "Unknown option: $arg"; usage; exit 1 ;;
    esac
done

if has_arg "--copy" "$@" && has_arg "--link" "$@"; then
    err "Choose either --copy or --link, not both"
    usage
    exit 1
fi

if has_arg "--link" "$@"; then
    INSTALL_MODE="link"
fi

# 1. Clone the repo if needed
if [ ! -e "$DOTFILES_DIR" ]; then
    info "📥 Cloning dotfiles into $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
    ok "Repository cloned"
elif ! git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    err "$DOTFILES_DIR exists but is not a Git repository"
    err "Move it elsewhere or set DOTFILES_DIR to a dotfiles clone"
    exit 1
elif [ -n "$SCRIPT_REPO_DIR" ] && [ "$(cd "$DOTFILES_DIR" && pwd -P)" = "$SCRIPT_REPO_DIR" ]; then
    info "📍 Running from the local clone at $DOTFILES_DIR; skipping pull."
else
    if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]; then
        err "Repository at $DOTFILES_DIR has uncommitted changes; refusing to pull"
        exit 1
    fi
    info "🔄 Repository already exists at $DOTFILES_DIR; pulling updates..."
    git -C "$DOTFILES_DIR" pull --ff-only
    ok "Repository updated"
fi

cd "$DOTFILES_DIR"

# 2. Define entries
# Format: "repo_source:home_destination"
# "repo_source" is relative to $DOTFILES_DIR
ENTRIES=(
    "git/.gitconfig.dotfiles:$HOME/.gitconfig.dotfiles"
    "git/.gitignore_global:$HOME/.gitignore_global"
)

select_optional_links "$@"

if [ "$SELECT_OPENCODE" = true ]; then
    add_entry "opencode/agents" "$HOME/.config/opencode/agents"
    add_entry "opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
fi

if [ "$SELECT_CLAUDE" = true ]; then
    add_entry "claude/settings.json" "$HOME/.claude/settings.json"
fi

if [ "$SELECT_SHARED_SKILLS" = true ]; then
    add_entry "agents/skills" "$HOME/.agents/skills"
fi

if [ "$SELECT_GHOSTTY" = true ]; then
    add_entry "ghostty/config" "$HOME/.config/ghostty/config"
fi

# 3. Apply files
if [ "$INSTALL_MODE" = "copy" ]; then
    info "📋 Copying files and directories..."
else
    info "🔗 Creating symlinks..."
fi

for entry in "${ENTRIES[@]}"; do
    apply_entry "$entry"
done

ensure_zshrc_stub
ensure_gitconfig_include

if [ "$SELECT_CODEX_SKILLS" = true ]; then
    info "🧪 Copying Codex skills..."
    copy_codex_skills
fi

if [ "$SELECT_FONTS" = true ]; then
    if [ ! -f "$DOTFILES_DIR/fonts/install.sh" ]; then
        warn "Font installer was not found at $DOTFILES_DIR/fonts/install.sh; skipping"
    else
        info "🔤 Installing fonts (explicitly selected)..."
        bash "$DOTFILES_DIR/fonts/install.sh" --yes
    fi
fi

# 4. Create the repo .gitignore if missing
if [ ! -f "$DOTFILES_DIR/.gitignore" ]; then
    cat > "$DOTFILES_DIR/.gitignore" << 'GITIGNORE'
# Secrets - never commit
.env
auth.json

# Runtime state
sessions/
logs/
*.log

# System
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
GITIGNORE
    ok ".gitignore created"
fi

# 5. Final summary
echo ""
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  🎉 Bootstrap complete!                     ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo ""
if [ "$INSTALL_MODE" = "copy" ]; then
    echo "  📋 Copy mode was used. Copied configs no longer depend on this repository."
    echo "  🐚 ~/.zshrc still sources shell/.zshrc from the repository."
    echo "  🔄 Re-run bootstrap to import future repository updates."
else
    echo "  🔗 Link mode was used. Linked configs receive repository updates immediately."
    echo "  🔄 Run 'dotsync' from an interactive Zsh shell to pull safely."
    echo "  🧪 Re-run bootstrap when copied Codex skills need to be refreshed."
fi
echo ""
echo "  🆕 New machine? Run:"
echo "    curl -fsSL $BOOTSTRAP_URL | bash"
echo ""
echo "  ⚙️  Optional setup without prompts:"
echo "    ./bootstrap.sh --all"
echo "    ./bootstrap.sh --opencode --claude --skills --codex --ghostty"
echo "    ./bootstrap.sh --fonts"
echo "    ./bootstrap.sh --copy --all"
echo ""
echo "  📦 Install mode used:"
echo "    $INSTALL_MODE"
echo ""
echo "  💾 Backups were written under:"
echo "    $BACKUP_DIR"
echo ""
