# Claude Code

Versioned Claude Code settings.

`bootstrap.sh --claude` installs these optional files:

- `claude/CLAUDE.md` to `~/.claude/CLAUDE.md`, linked (or copied with `--copy`)
- `claude/settings.json` to `~/.claude/settings.json`, always copied, never linked

Claude Code rewrites `settings.json` itself (`/config`, `/model`, theme), so it stays a local per-machine file. The repo version only seeds new machines: bootstrap never overwrites an existing local copy. To reseed, move `~/.claude/settings.json` away and re-run `./bootstrap.sh --claude`. Port changes worth sharing back into `claude/settings.json` by hand.

Do not version credentials, cache, sessions, history, project state, or daemon files from `~/.claude`. Do not replace `~/.claude/skills` when it is managed as symlinks to globally installed skills in `~/.agents/skills`.
