# Claude Code

Versioned Claude Code settings.

`bootstrap.sh --claude` can link these optional files:

- `claude/settings.json` to `~/.claude/settings.json`
- `claude/CLAUDE.md` to `~/.claude/CLAUDE.md`

Do not version credentials, cache, sessions, history, project state, or daemon files from `~/.claude`. Do not replace `~/.claude/skills` when it is managed as symlinks to globally installed skills in `~/.agents/skills`.
