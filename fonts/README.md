# Fonts

This directory contains the optional installer for the fonts used by the
dotfiles:

| Family | Version | Source project | License |
|---|---|---|---|
| Fira Code | 6.2 | [tonsky/FiraCode](https://github.com/tonsky/FiraCode) | SIL OFL 1.1 |
| IBM Plex Mono | @ibm/plex-mono@2.5.0 | [IBM/plex](https://github.com/IBM/plex) | SIL OFL 1.1 |
| Source Code Pro | 2.042R-u / 1.062R-i / 1.026R-vf | [adobe-fonts/source-code-pro](https://github.com/adobe-fonts/source-code-pro) | SIL OFL 1.1 |
| Iosevka | v34.8.1 (default family) | [be5invis/Iosevka](https://github.com/be5invis/Iosevka) | SIL OFL 1.1 |
| Geist Mono | v1.7.2 | [vercel/geist-font](https://github.com/vercel/geist-font) | SIL OFL 1.1 |
| JetBrains Mono | v2.304 | [JetBrains/JetBrainsMono](https://github.com/JetBrains/JetBrainsMono) | SIL OFL 1.1 |

The pinned versions and download URLs live in `sources.txt` (format:
`Family name|official release archive URL[|path filter]`). The optional
`path filter` limits installation to files whose archive path contains the
given substring — used for `Geist Mono` because Vercel's official archive
bundles the Geist, Geist Mono, and Geist Pixel families. Version notes:

- **Fira Code 6.2** is the latest upstream release (the bundled TTFs report
  internal version 6.002).
- **IBM Plex Mono** is pinned to
  [`@ibm/plex-mono@2.5.0`](https://github.com/IBM/plex/releases/tag/%40ibm/plex-mono%402.5.0),
  the latest static release. IBM restructured the `IBM/plex` releases into
  per-family npm-style tags (a variable-font build,
  `@ibm/plex-mono-variable@1.0.0`, also exists). Since `sources.txt` pins
  exact URLs, bootstrap installs this specific version — bump the pin when a
  newer release ships.
- **Source Code Pro 2.042R-u / 1.062R-i / 1.026R-vf** is the latest upstream
  release.
- **Iosevka v34.8.1** is the latest upstream release; the pin uses the
  official `PkgTTF-Iosevka` archive for the default Iosevka family (Iosevka
  ships many separate style variants, which are not installed).
- **Geist Mono v1.7.2** is the latest upstream release of
  [vercel/geist-font](https://github.com/vercel/geist-font).
- **JetBrains Mono v2.304** is the latest upstream release.

Fonts are never installed by default, by `--all`, or by selecting the
Ghostty configuration. Install them only with explicit consent:

```bash
./bootstrap.sh --fonts
```

`bootstrap.sh --fonts` always installs the whole set. To install only some
families, run the installer directly:

```bash
fonts/install.sh                              # interactive family selector
fonts/install.sh --only "Iosevka,Geist Mono"  # install a subset (explicit consent)
fonts/install.sh --yes                        # everything, no prompts
```

On Windows, the PowerShell installer accepts the same options:
`-Yes` installs everything, `-Only "JetBrains Mono"` installs a subset, and
running with neither shows the interactive selector.

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
