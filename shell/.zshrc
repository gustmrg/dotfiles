# Keep PATH entries unique while placing local user binaries first.
typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/bin" $path)

# uv writes this file when installed; keep startup quiet on machines without it.
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Preserve machine-specific pnpm configuration and provide portable defaults.
if [ -z "${PNPM_HOME:-}" ]; then
    case "$OSTYPE" in
        darwin*) export PNPM_HOME="$HOME/Library/pnpm" ;;
        *) export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm" ;;
    esac
fi

[ -d "$PNPM_HOME" ] && path=("$PNPM_HOME" $path)
[ -d "$PNPM_HOME/bin" ] && path=("$PNPM_HOME/bin" $path)

# Pull shared dotfiles explicitly without rewriting commits or hiding failures.
dotsync() {
    local repo="${1:-${DOTFILES_DIR:-$HOME/dotfiles}}"

    if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print -u2 -- "dotsync: $repo is not a Git repository"
        return 1
    fi

    if [ -n "$(git -C "$repo" status --porcelain)" ]; then
        print -u2 -- "dotsync: $repo has uncommitted changes; refusing to pull"
        return 1
    fi

    git -C "$repo" pull --ff-only || return

    if [ ! -L "$HOME/.zshrc" ]; then
        print -- "dotsync: copy mode detected; re-run $repo/bootstrap.sh to apply updates"
    fi
}
