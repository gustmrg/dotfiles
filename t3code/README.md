# T3 Code

Versioned T3 Code themes.

`bootstrap.sh --t3code` installs these optional files:

- `t3code/themes/gusty-code.json` to `$T3CODE_HOME/userdata/themes/gusty-code.json` (`~/.t3` when `T3CODE_HOME` is unset, the same rule the app uses), always copied, never linked

The theme is copied even in link mode so the same file also works on Windows. When the file changed and the `t3` CLI is available (on `PATH`, or at `$T3CODE_HOME/bin/t3`; `t3.cmd` on Windows), bootstrap also runs `t3 theme set gusty-code`. That is best effort: without the CLI, or if it fails, select Gusty Code in the Appearance settings. An unchanged theme is not re-selected, so re-running bootstrap does not override a theme chosen later in the app. Bootstrap overwrites the local copy with the repo version and backs up the previous one under `~/.dotfiles-backup/<timestamp>/`, so the repo is the source of truth: edit the theme here, or port changes made in the app back into `t3code/themes/gusty-code.json` by hand.

`gusty-code.json` is the central theme for UI customizations: the stock T3 Code palette (dark with a light variant), plus a CSS block that spins the working indicator in the sidebar and flattens the UI by zeroing elevation shadows (focus rings are kept). It also swaps the model picker and file attachment button in the composer footer. Select it in T3 Code's Appearance settings after installing.

Both variants use the stock T3 Code palette (dark and light), with only the CSS block customizing the UI. The palette is spelled out in full because a theme without `canvas` and the full role set inherits from the T3 Chat theme instead of T3 Code. The top-level `canvas` and `accent` must be hex (`#000`, `#346bf1`); the per-role values keep the stock oklch notation.

Only themes belong here. Do not version `client-settings.json`, `settings.json`, or anything else from `~/.t3`: they mix preferences with machine state and secrets references.
