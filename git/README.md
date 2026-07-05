# Git

Versioned Git defaults and global ignore rules.

`bootstrap.sh` links:

- `git/.gitconfig` to `~/.gitconfig`
- `git/.gitignore_global` to `~/.gitignore_global`

`git/.gitconfig` sets `core.excludesfile = ~/.gitignore_global`, which tells Git to apply the global ignore file to every repository on the machine.

Use `.gitignore_global` for machine-wide noise only: OS files, local editor state, logs, temporary files, and local environment files. Project-specific build outputs should usually stay in each repository's own `.gitignore`.

To configure manually without bootstrap:

```bash
git config --global core.excludesfile ~/.gitignore_global
```
