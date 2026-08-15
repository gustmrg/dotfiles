# Git

Versioned Git defaults and global ignore rules.

`bootstrap.sh` copies these files by default or links them with `--link`:

- `git/.gitconfig.dotfiles` to `~/.gitconfig.dotfiles`
- `git/.gitignore_global` to `~/.gitignore_global`

`bootstrap.sh` does not replace `~/.gitconfig`. That file is local to each machine and should keep machine-specific identity such as `user.email`.

When `~/.gitconfig` does not exist, bootstrap creates only the shared include and prints a warning. Configure both identity fields per machine:

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

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

## Per-context overrides (work vs. personal)

The shared defaults apply to every repository on the machine. To override them for a specific context — for example, work clones that share branches and squash-merge PRs, where `pull.rebase = true` can replay already-published commits — use conditional includes in the machine-local `~/.gitconfig`, after the dotfiles include (later values win):

```ini
# Match by directory layout:
[includeIf "gitdir:~/work/**"]
	path = ~/.gitconfig-work

# Or match by remote URL (Git >= 2.36):
[includeIf "hasconfig:remote.*.url:git@github.com:mycompany/**"]
	path = ~/.gitconfig-work
```

Then put the overrides in `~/.gitconfig-work` — start from the template:

```bash
cp git/.gitconfig-work.example ~/.gitconfig-work
```

```ini
[user]
	email = you@company.com

[pull]
	# Never rewrite or merge shared branches silently; stop and decide manually.
	ff = only
```

This also keeps work identity (email) out of personal commits. Do not version `~/.gitconfig-work`; it is machine-local like `~/.gitconfig`.

Use `.gitignore_global` for machine-wide noise only: OS files, local editor state, and local environment files (`.env` secrets must never be committed anywhere). Logs, runtime directories, and build outputs should be ignored by each repository only when appropriate.

To configure manually without bootstrap:

```bash
git config --global core.excludesfile ~/.gitignore_global
git config --global --add include.path ~/.gitconfig.dotfiles
```
