# Codex

Versioned Codex configuration: global instructions (`AGENTS.md`) and skills.

`bootstrap.sh --codex` links (or copies, with `--copy`) `AGENTS.md` to `~/.codex/AGENTS.md`, and copies each directory in `codex/skills/` into `~/.codex/skills/`.

This intentionally uses copy instead of symlink so Codex can keep its internal `~/.codex/skills/.system` directory untouched.

To refresh a skill from the current machine into this repository:

```bash
rsync -a --delete --exclude='.DS_Store' ~/.codex/skills/reset-credits/ ~/dotfiles/codex/skills/reset-credits/
```
