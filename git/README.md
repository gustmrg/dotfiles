# Git

Versioned Git defaults and global ignore rules.

`bootstrap.sh` links:

- `git/.gitconfig.dotfiles` to `~/.gitconfig.dotfiles`
- `git/.gitignore_global` to `~/.gitignore_global`

`bootstrap.sh` does not replace `~/.gitconfig`. That file is local to each machine and should keep machine-specific identity such as `user.email`.

Instead, bootstrap ensures `~/.gitconfig` includes the shared config:

```ini
[include]
	path = ~/.gitconfig.dotfiles
```

`git/.gitconfig.dotfiles` sets `core.excludesfile = ~/.gitignore_global`, which tells Git to apply the global ignore file to every repository on the machine.

Use `.gitignore_global` for machine-wide noise only: OS files, local editor state, logs, temporary files, and local environment files. Project-specific build outputs should usually stay in each repository's own `.gitignore`.

To configure manually without bootstrap:

```bash
git config --global core.excludesfile ~/.gitignore_global
git config --global --add include.path ~/.gitconfig.dotfiles
```
