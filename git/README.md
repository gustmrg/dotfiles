# Git

Versioned Git defaults and global ignore rules.

`bootstrap.sh` copies these files by default or links them with `--link`:

- `git/.gitconfig.dotfiles` to `~/.gitconfig.dotfiles`
- `git/.gitignore_global` to `~/.gitignore_global`

`bootstrap.sh` does not replace `~/.gitconfig`. That file is local to each machine and should keep machine-specific identity such as `user.email`.

Instead, bootstrap ensures `~/.gitconfig` includes the shared config:

```ini
[include]
	path = ~/.gitconfig.dotfiles
```

`git/.gitconfig.dotfiles` sets `core.excludesfile = ~/.gitignore_global`, which tells Git to apply the global ignore file to every repository on the machine.

Credential helpers are intentionally machine-local because their paths and storage backends vary across macOS and Linux. To configure GitHub CLI as the helper on a machine, run:

```bash
gh auth setup-git
```

You can instead retain the operating system's native credential helper in the machine-local `~/.gitconfig`.

Use `.gitignore_global` for machine-wide noise only: OS files, local editor state, logs, temporary files, and local environment files. Project-specific build outputs should usually stay in each repository's own `.gitignore`.

To configure manually without bootstrap:

```bash
git config --global core.excludesfile ~/.gitignore_global
git config --global --add include.path ~/.gitconfig.dotfiles
```
