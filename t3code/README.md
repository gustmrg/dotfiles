# T3 Code

Versioned T3 Code themes.

`bootstrap.sh --t3code` installs these optional files:

- `t3code/themes/gusty-code.json` to `~/.t3/userdata/themes/gusty-code.json`, always copied, never linked

The theme is copied even in link mode so the same file also works on Windows. Bootstrap overwrites the local copy with the repo version and backs up the previous one under `~/.dotfiles-backup/<timestamp>/`, so the repo is the source of truth: edit the theme here, or port changes made in the app back into `t3code/themes/gusty-code.json` by hand.

`gusty-code.json` is the central theme for UI customizations: a dark palette with a light variant, plus a CSS block that spins the working indicator in the sidebar and flattens the UI by zeroing elevation shadows (focus rings are kept). Select it in T3 Code's Appearance settings after installing.

Only themes belong here. Do not version `client-settings.json`, `settings.json`, or anything else from `~/.t3`: they mix preferences with machine state and secrets references.
