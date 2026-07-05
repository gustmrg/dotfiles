# Keep local user binaries first.
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# uv writes this file when installed; keep startup quiet on machines without it.
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Best-effort sync for shared dotfiles on interactive shells.
case $- in
    *i*) [ -d "$HOME/dotfiles/.git" ] && git -C "$HOME/dotfiles" pull --rebase --quiet 2>/dev/null ;;
esac
