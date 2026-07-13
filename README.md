# Dotfiles

Personal shell, Git, editor, and agent configuration files for reuse across machines.

## Install

On a new machine:

```bash
curl -fsSL https://raw.githubusercontent.com/gustmrg/dotfiles/main/bootstrap.sh | bash
```

Or from an existing clone:

```bash
./bootstrap.sh
```

The bootstrap script copies configuration files into the home directory by default. Existing files, directories, or symlinks are backed up before being replaced; unchanged copies are left in place.

Backups are written to:

```text
~/.dotfiles-backup/<timestamp>/
```

Flags are not mandatory. If you run `./bootstrap.sh` in a terminal, it asks which optional configs you want to install. Use flags when you want to skip the prompt, for example in a non-interactive setup:

```bash
./bootstrap.sh --minimal
./bootstrap.sh --copy --all
./bootstrap.sh --all
./bootstrap.sh --opencode --claude --skills --codex
```

By default, bootstrap copies files. Use `--link` when you want home-directory configs to remain connected to the repository and receive updates immediately after a Git pull.

Recommended modes:

```bash
# Keep the clone and apply future Git updates immediately.
./bootstrap.sh --link --all

# Import everything once, then allow removing ~/dotfiles safely.
./bootstrap.sh --all
```

## Importing On A Machine

1. Clone or bootstrap this repository. A directly executed `bootstrap.sh` uses the clone containing the script, even when it is not at `~/dotfiles`.

```bash
git clone https://github.com/gustmrg/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

2. Choose optional configs in the prompt. You can select multiple options with commas or spaces, such as `1,3` or `1 2 3`.

3. If a target file, directory, or symlink already exists, the script backs it up under `~/.dotfiles-backup/<timestamp>/` and then applies the repo version.

4. After installing OpenCode or Claude settings, restart those tools so they reload config files.

For unattended setup, use flags instead of the prompt:

```bash
./bootstrap.sh --minimal
./bootstrap.sh --opencode --skills
./bootstrap.sh --codex
./bootstrap.sh --all
./bootstrap.sh --copy --all
```

Use symlink mode when the repository will remain on the machine and should keep syncing via `git pull`. Use copy mode for temporary machines, agents, containers, or hosts where you want a one-time import.

In link mode, run `dotsync` from Zsh to safely fast-forward the repository. In copy mode, pulling only updates the repository; rerun `./bootstrap.sh` to apply the new files to your home directory.

If the repository path cannot be inferred, set it explicitly:

```bash
DOTFILES_DIR="$HOME/src/dotfiles" ./bootstrap.sh --link --all
dotsync "$HOME/src/dotfiles"
```

If you already used symlink mode but later want to remove this repository, first materialize the configs as real files:

```bash
./bootstrap.sh --copy --all
rm -rf ~/dotfiles
```

## Contents

- `opencode/` - OpenCode agents and settings.
- `claude/` - Claude Code settings.
- `codex/skills/` - Codex-specific skills copied into `~/.codex/skills`.
- `agents/skills/` - Skills shared by multiple agent tools via `~/.agents/skills`.
- `shell/` - Shell startup configuration copied or linked into the home directory.
- `git/` - Git user defaults, aliases, and global ignore rules.
- `ghostty/` - Ghostty terminal configuration.
- `pi/` - Pi Coding Agent-specific configuration notes and future links.
- `vscode/` - VS Code and Cursor editor configuration assets.
- `vscode/anysphere.cursor-themes-0.0.2/` - Cursor theme extension files for VS Code-compatible editors.

## VS Code

The VS Code directory archives the Cursor theme extension so the themes can be restored manually on a new machine. See `vscode/README.md` for the install steps and available theme names.

VS Code settings are intentionally not symlinked; use the editor's native Settings Sync for live settings, keybindings, and extension state.

## Maintenance

- Keep machine-specific secrets and credentials out of this repository.
- Configure GitHub authentication per machine. With GitHub CLI, run `gh auth setup-git`; native credential helpers are also supported.
- Prefer adding small, documented configuration files over large generated editor state.
- Update the relevant directory README when adding new configuration areas.
