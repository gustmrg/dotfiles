# Shell

Versioned shell startup files.

`bootstrap.sh` installs `~/.zshrc` as a small local stub that sources `shell/.zshrc` from this repository (in both link and copy modes). Installers can append to `~/.zshrc` without dirtying the repo, and repo updates still apply on the next shell start. Keep machine-specific secrets, host-only paths, and private tokens out of the repo file; put them in the unversioned `~/.zshrc.local`, which this file sources last when present.

The shared configuration provides `dotsync [repository]` for explicit, fast-forward-only repository updates. It refuses to pull a dirty tree and reports failures instead of performing network operations during shell startup. After using `dotsync` in copy mode, rerun the repository's `bootstrap.sh` to apply the updated files.

`PNPM_HOME` is preserved when already configured. Otherwise, it defaults to `~/Library/pnpm` on macOS and `${XDG_DATA_HOME:-~/.local/share}/pnpm` on Linux; existing pnpm home and `bin` directories are added to `PATH` once.
