# Fonts

This directory contains the optional installer for the fonts used by the
dotfiles:

- Fira Code
- IBM Plex Mono
- Source Code Pro

Fonts are never installed by default, by `--all`, or by selecting the
Ghostty configuration. Install them only with explicit consent:

```bash
./bootstrap.sh --fonts
```

On Linux or macOS, the installer downloads the fonts and places them in the
current user's font directory. It does not require administrator access.

On Windows, run PowerShell as the current user:

```powershell
powershell -ExecutionPolicy Bypass -File .\fonts\install.ps1
```

Both installers prompt before downloading anything. The bootstrap passes
`--yes` only after `--fonts` or the fonts menu option was explicitly selected.
The downloads come from official release archives for each font project; the
source projects are licensed under the SIL Open Font License.

Restart applications that were open before installing the fonts.
