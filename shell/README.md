# Shell

Versioned shell startup files.

`bootstrap.sh` copies `shell/.zshrc` to `~/.zshrc` by default or links it with `--link`. Keep machine-specific secrets, host-only paths, and private tokens out of this file.

The shared configuration provides `dotsync [repository]` for explicit, fast-forward-only repository updates. It refuses to pull a dirty tree and reports failures instead of performing network operations during shell startup. After using `dotsync` in copy mode, rerun the repository's `bootstrap.sh` to apply the updated files.

`PNPM_HOME` is preserved when already configured. Otherwise, it defaults to `~/Library/pnpm` on macOS and `${XDG_DATA_HOME:-~/.local/share}/pnpm` on Linux; existing pnpm home and `bin` directories are added to `PATH` once.
