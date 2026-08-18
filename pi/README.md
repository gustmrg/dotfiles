# Pi Coding Agent configuration

This directory contains the portable parts of the Pi Coding Agent configuration imported from `~/.pi/agent`:

- `extensions/` - personal Pi extensions
- `themes/` - custom Pi themes
- `settings.json` - default model, thinking level, theme, and package list
- `models-store.json` - cached model catalog
- `npm/` - package manifests for the configured Pi packages

Install the configuration on the current machine with:

```bash
./pi/install.sh
```

The installer copies the tracked configuration files and resources into `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}` rather than symlinking them. It also reinstalls the packages recorded in `npm/package-lock.json`; use `--skip-packages` to omit that step. npm may create its normal executable shims inside the generated `node_modules/` directory.

Machine-specific or sensitive Pi state is intentionally not tracked:

- `auth.json` contains provider credentials; authenticate separately with Pi's `/login` command.
- `sessions/` and `fff/` contain private, machine-local history and indexes.
- `trust.json` contains absolute paths and must be recreated on each machine.
- `npm/node_modules/` is generated and platform-specific; the installer recreates it from the lockfile.
