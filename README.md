# Dotfiles

Personal editor and agent configuration files for reuse across machines.

## Contents

- `opencode/` - OpenCode agent configuration.
- `opencode/agents/learn.md` - Learn Mode agent that coaches through questions, hints, and review instead of taking over implementation.
- `vscode/` - VS Code and Cursor editor configuration assets.
- `vscode/anysphere.cursor-themes-0.0.2/` - Cursor theme extension files for VS Code-compatible editors.
- `vscode/README.md` - Manual installation notes for the bundled Cursor themes.

## OpenCode

The OpenCode configuration currently includes a custom `learn` agent:

- Uses read/search tools only.
- Avoids writing production code for the user.
- Focuses on coaching, debugging guidance, and code review.

To use it locally, place `opencode/agents/learn.md` in the agent configuration location expected by your OpenCode setup.

## VS Code

The VS Code directory archives the Cursor theme extension so the themes can be restored manually on a new machine. See `vscode/README.md` for the install steps and available theme names.

## Maintenance

- Keep machine-specific secrets and credentials out of this repository.
- Prefer adding small, documented configuration files over large generated editor state.
- Update the relevant directory README when adding new configuration areas.
