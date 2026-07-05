# Claude Code

Versioned Claude Code settings.

`bootstrap.sh --claude` can link this optional path:

- `claude/settings.json` to `~/.claude/settings.json`

Do not version credentials, cache, sessions, history, project state, or daemon files from `~/.claude`. Do not replace `~/.claude/skills` when it is managed as symlinks to globally installed skills in `~/.agents/skills`.
