# OpenCode

Versioned OpenCode agents and settings.

`bootstrap.sh` can link these optional paths:

- `opencode/agents` to `~/.config/opencode/agents`
- `opencode/opencode.jsonc` to `~/.config/opencode/opencode.jsonc`

OpenCode skills are kept in `agents/skills` when they should be shared across tools. Do not version auth files, caches, logs, package installs, or sessions from `~/.config/opencode`.
